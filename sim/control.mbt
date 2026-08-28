///|
/// sim/control.mbt — 自动控制系统模型
/// PID控制器: DO控制(鼓风机)、MLSS控制(排泥)、SRT管理、回流控制
/// 基于反馈控制原理, 实现工艺参数自动调节

///|
/// PID控制器参数
pub(all) struct PIDConfig {
  kp : Double   // 比例系数
  ki : Double   // 积分系数
  kd : Double   // 微分系数
  setpoint : Double  // 设定值
  output_min : Double  // 输出下限
  output_max : Double  // 输出上限
} derive(Debug)

///|
/// 控制器状态 — 保存积分项和上次误差
pub(all) struct ControllerState {
  integral : Double   // 积分累积
  prev_error : Double  // 上次误差
  output : Double      // 当前输出
} derive(Debug)

///|
/// 控制动作 — 记算PID输出
pub fn pid_step(pid : PIDConfig, state : ControllerState, measured : Double, dt : Double) -> (Double, ControllerState) {
  let error = pid.setpoint - measured
  let new_integral = state.integral + error * dt
  let derivative = if dt > 0.0 { (error - state.prev_error) / dt } else { 0.0 }
  let raw_output = pid.kp * error + pid.ki * new_integral + pid.kd * derivative
  let output = clamp(raw_output, pid.output_min, pid.output_max)
  // 积分抗饱和
  let saturated_integral = if raw_output != output { state.integral } else { new_integral }
  (output, { integral: saturated_integral, prev_error: error, output })
}

///|
/// 默认DO控制器 — 目标DO=2.0mg/L, 输出=鼓风机频率(20-50Hz)
pub fn do_controller(do_setpoint : Double) -> PIDConfig {
  { kp: 8.0, ki: 0.5, kd: 2.0, setpoint: do_setpoint, output_min: 20.0, output_max: 50.0 }
}

///|
/// 默认MLSS控制器 — 目标MLSS=3500mg/L, 输出=排泥量(100-800 m³/d)
pub fn mlss_controller(mlss_target : Double) -> PIDConfig {
  { kp: 0.05, ki: 0.001, kd: 0.01, setpoint: mlss_target, output_min: 100.0, output_max: 800.0 }
}

///|
/// 默认SRT控制器 — 目标SRT=15d, 输出=排泥量修正系数(0.5-2.0)
pub fn srt_controller(srt_target : Double) -> PIDConfig {
  { kp: 0.1, ki: 0.01, kd: 0.05, setpoint: srt_target, output_min: 0.5, output_max: 2.0 }
}

///|
/// 默认回流控制器 — 目标回流比=1.0, 输出=回流泵频率(20-50Hz)
pub fn recycle_controller(recycle_target : Double) -> PIDConfig {
  { kp: 5.0, ki: 0.2, kd: 1.0, setpoint: recycle_target, output_min: 20.0, output_max: 50.0 }
}

///|
/// 控制系统 — 聚合所有控制器
pub(all) struct ControlSystem {
  do_pid : PIDConfig
  mlss_pid : PIDConfig
  srt_pid : PIDConfig
  recycle_pid : PIDConfig
  do_state : ControllerState
  mlss_state : ControllerState
  srt_state : ControllerState
  recycle_state : ControllerState
} derive(Debug)

///|
/// 默认控制系统
pub fn default_control_system(cfg : AAOConfig) -> ControlSystem {
  {
    do_pid: do_controller(cfg.do_setpoint),
    mlss_pid: mlss_controller(cfg.mlss_target),
    srt_pid: srt_controller(cfg.srt),
    recycle_pid: recycle_controller(cfg.external_recycle_ratio),
    do_state: { integral: 0.0, prev_error: 0.0, output: 35.0 },
    mlss_state: { integral: 0.0, prev_error: 0.0, output: 400.0 },
    srt_state: { integral: 0.0, prev_error: 0.0, output: 1.0 },
    recycle_state: { integral: 0.0, prev_error: 0.0, output: 35.0 },
  }
}

///|
/// 控制动作结果
pub(all) struct ControlAction {
  blower_freq : Double       // 鼓风机频率 (Hz)
  waste_sludge_flow : Double  // 排泥量 (m³/d)
  srt_correction : Double     // SRT修正系数
  recycle_pump_freq : Double  // 回流泵频率 (Hz)
  do_error : Double           // DO偏差
  mlss_error : Double         // MLSS偏差
} derive(Debug)

///|
/// 执行控制循环 — 根据测量值计算控制动作
pub fn control_loop(cs : ControlSystem, measured_do : Double, measured_mlss : Double, measured_srt : Double, measured_recycle : Double, dt : Double) -> (ControlAction, ControlSystem) {
  let (blower_freq, new_do_state) = pid_step(cs.do_pid, cs.do_state, measured_do, dt)
  let (waste_flow, new_mlss_state) = pid_step(cs.mlss_pid, cs.mlss_state, measured_mlss, dt)
  let (srt_corr, new_srt_state) = pid_step(cs.srt_pid, cs.srt_state, measured_srt, dt)
  let (recycle_freq, new_recycle_state) = pid_step(cs.recycle_pid, cs.recycle_state, measured_recycle, dt)
  let action = {
    blower_freq,
    waste_sludge_flow: waste_flow,
    srt_correction: srt_corr,
    recycle_pump_freq: recycle_freq,
    do_error: cs.do_pid.setpoint - measured_do,
    mlss_error: cs.mlss_pid.setpoint - measured_mlss,
  }
  let new_cs = {
    ..cs,
    do_state: new_do_state,
    mlss_state: new_mlss_state,
    srt_state: new_srt_state,
    recycle_state: new_recycle_state,
  }
  (action, new_cs)
}

///|
/// 根据控制动作更新AAO配置
pub fn apply_control(cfg : AAOConfig, action : ControlAction) -> AAOConfig {
  let do_adjusted = cfg.do_setpoint + action.do_error * 0.1
  let mlss_adjusted = cfg.mlss_target + action.mlss_error * 0.05
  {
    ..cfg,
    do_setpoint: clamp(do_adjusted, 0.5, 5.0),
    mlss_target: clamp(mlss_adjusted, 2000.0, 6000.0),
    waste_sludge_flow: action.waste_sludge_flow,
  }
}

///|
/// 控制系统JSON导出
pub fn control_action_json(action : ControlAction) -> String {
  "{\"blower_freq\":\{action.blower_freq},\"waste_sludge_flow\":\{action.waste_sludge_flow},\"srt_correction\":\{action.srt_correction},\"recycle_pump_freq\":\{action.recycle_pump_freq},\"do_error\":\{action.do_error},\"mlss_error\":\{action.mlss_error}}"
}

///|
/// 估算当前SRT — 基于MLSS和排泥量
pub fn estimate_srt(mlss : Double, reactor_volume : Double, waste_flow : Double) -> Double {
  let mass = mlss * reactor_volume / 1000.0
  if waste_flow > 0.0 { mass / (waste_flow * mlss / 1000.0) } else { 999.0 }
}

///|
/// 控制系统健康度 — 评估控制品质
pub fn control_health(action : ControlAction) -> Double {
  let do_score = 100.0 - abs_d(action.do_error) * 10.0
  let mlss_score = 100.0 - abs_d(action.mlss_error) * 0.01
  clamp((do_score + mlss_score) / 2.0, 0.0, 100.0)
}
