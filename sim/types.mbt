///|
/// sim/types.mbt — AAO工艺仿真引擎核心数据类型
/// 基于 ASM2d 活性污泥模型简化版 + 全流程水力模型
/// 设计规模: 10万吨/日 AAO工艺污水处理厂

///|
/// 水质指标 — 8项核心水质参数
/// 贯穿全流程(进水→各单元→出水)的水质状态
pub(all) struct WaterQuality {
  cod : Double       // 化学需氧量 (mg/L)
  bod5 : Double      // 五日生化需氧量 (mg/L)
  nh4_n : Double     // 氨氮 (mg/L)
  no3_n : Double     // 硝态氮 (mg/L)
  tn : Double        // 总氮 (mg/L)
  tp : Double        // 总磷 (mg/L)
  po4_p : Double     // 正磷酸盐 (mg/L)
  ss : Double        // 悬浮固体 (mg/L)
  mlss : Double      // 混合液悬浮固体 (mg/L, 反应池内)
  do_value : Double  // 溶解氧 (mg/L)
  temperature : Double // 水温 (°C)
  flow : Double      // 流量 (m³/h)
  ph : Double        // pH
  alkalinity : Double // 碱度 (mg/L as CaCO3)
} derive(Debug)

///|
/// AAO反应池配置 — 三区串联 + 动力学参数
pub(all) struct AAOConfig {
  // 反应池容积 (m³)
  anaerobic_volume : Double  // 厌氧区容积
  anoxic_volume : Double     // 缺氧区容积
  oxic_volume : Double       // 好氧区容积
  // 运行参数
  do_setpoint : Double           // 好氧区DO设定值 (mg/L)
  internal_recycle_ratio : Double // 内回流比 (Q_r/Q, 1~4)
  external_recycle_ratio : Double // 外回流比 (Q_r/Q, 0.5~1.5)
  srt : Double                   // 污泥龄 (d)
  mlss_target : Double           // 目标MLSS (mg/L)
  waste_sludge_flow : Double     // 剩余污泥排放量 (m³/d)
  // 动力学参数 (ASM2d 默认值, 20°C)
  mu_h : Double     // 异养菌最大比增长速率 (1/d)
  mu_a : Double     // 自养菌最大比增长速率 (1/d)
  k_s : Double      // COD半饱和常数 (mg/L)
  k_nh : Double     // 氨氮半饱和常数 (mg/L)
  k_oh : Double     // DO半饱和常数(异养) (mg/L)
  k_oa : Double     // DO半饱和常数(自养) (mg/L)
  k_no : Double     // 硝态氮半饱和常数 (mg/L)
  b_h : Double      // 异养菌衰减系数 (1/d)
  b_a : Double      // 自养菌衰减系数 (1/d)
  y_h : Double      // 异养菌产率系数
  y_a : Double      // 自养菌产率系数
  eta_g : Double    // 缺氧还原因子
  q_pp : Double     // 聚磷菌储磷速率 (1/d)
  y_po : Double     // 聚磷菌产率
  k_p : Double      // 磷半饱和常数 (mg/L)
  i_nxb : Double    // 微生物体内氮含量
  i_nxp : Double    // 微生物产物氮含量
  theta_h : Double  // 异养菌温度系数
  theta_a : Double  // 自养菌温度系数
} derive(Debug)

///|
/// 全厂配置 — 处理单元尺寸 + 设备参数
pub(all) struct PlantConfig {
  design_flow : Double  // 设计流量 (m³/d)
  screen_width : Double      // 格栅宽度
  grit_volume : Double       // 沉砂池容积
  primary_volume : Double    // 初沉池容积
  primary_area : Double      // 初沉池表面积
  aao : AAOConfig            // AAO反应池配置
  secondary_area : Double    // 二沉池表面积
  secondary_volume : Double  // 二沉池容积
  filter_volume : Double     // 深床滤池容积
  uv_dose : Double           // 紫外消毒剂量 (mJ/cm²)
  thickener_volume : Double  // 浓缩池容积
  dewater_capacity : Double  // 脱水机处理能力
  pac_dose : Double          // PAC投加量 (mg/L)
  carbon_dose : Double       // 外加碳源投加量 (mg/L)
} derive(Debug)

///|
/// 仿真状态 — 动态仿真的当前状态
pub(all) struct SimState {
  time : Double          // 仿真时间
  influent : WaterQuality  // 当前进水
  effluent : WaterQuality  // 当前出水
  reactor : WaterQuality   // 反应池内水质
  energy_total : Double    // 累计能耗
  cost_total : Double      // 累计成本
  running : Bool           // 是否运行中
  speed : Double           // 仿真倍速
  step_count : Int         // 步数
} derive(Debug)

///|
/// 仿真结果 — 一次稳态/动态仿真的完整输出
pub(all) struct SimResult {
  influent : WaterQuality     // 进水水质
  effluent : WaterQuality     // 出水水质
  after_screen : WaterQuality
  after_grit : WaterQuality
  after_primary : WaterQuality
  after_anaerobic : WaterQuality
  after_anoxic : WaterQuality
  after_oxic : WaterQuality
  after_secondary : WaterQuality
  after_filter : WaterQuality
  after_uv : WaterQuality
  removal_cod : Double   // COD去除率
  removal_nh4 : Double   // 氨氮去除率
  removal_tn : Double    // TN去除率
  removal_tp : Double    // TP去除率
  removal_ss : Double    // SS去除率
  energy_aeration : Double  // 曝气能耗
  energy_pumping : Double   // 提升能耗
  energy_mixing : Double    // 搅拌能耗
  energy_sludge : Double    // 污泥处理能耗
  energy_other : Double     // 其他能耗
  energy_total : Double     // 总能耗
  energy_per_m3 : Double    // 吨水电耗
  compliance : Bool         // 是否达标(一级A)
  flow_balance : Double     // 水量不平衡率
} derive(Debug)

///|
/// 负荷场景 — 12类典型进水负荷场景
pub(all) struct LoadScenario {
  id : Int
  name : String
  description : String
  category : String
  flow_factor : Double
  cod_factor : Double
  nh4_factor : Double
  tn_factor : Double
  tp_factor : Double
  temp_offset : Double
  duration : Double
} derive(Debug)

///|
/// 故障场景 — 26项典型生产故障
pub(all) struct FaultScenario {
  id : Int
  name : String
  category : String
  severity : String
  description : String
  affected_unit : String
  impact_cod : Double
  impact_nh4 : Double
  impact_tp : Double
} derive(Debug)

///|
/// 能耗分析结果
pub(all) struct EnergyAnalysis {
  aeration : Double
  pumping : Double
  mixing : Double
  sludge : Double
  chemical : Double
  other : Double
  total : Double
  per_m3 : Double
  cost_electricity : Double
  cost_chemical : Double
  cost_total : Double
  cost_per_m3 : Double
} derive(Debug)

// ============================================================================
// 数学辅助函数
// ============================================================================

///|
/// 幂运算 base^exp (仅支持整数指数的快速路径 + 小数指数的exp/ln近似)
pub fn pow_d(base : Double, exp : Double) -> Double {
  if base <= 0.0 {
    return 0.0
  }
  // 使用 2^(exp * log2(base)) = 2^(exp * ln(base)/ln(2))
  let ln_base = ln_d(base)
  let ln2 = 0.6931471805599453
  let x = exp * ln_base / ln2
  // 2^x = e^(x * ln2)
  exp_d(x * ln2)
}

///|
/// 自然指数 e^x
/// 对 x < -5 使用 1/e^(-x) 避免Taylor级数不收敛
pub fn exp_d(x : Double) -> Double {
  if x > 20.0 {
    let half = exp_d(x / 2.0)
    return half * half
  }
  if x < -20.0 {
    return 0.0
  }
  if x < -5.0 {
    let pos = exp_d(-x)
    if pos > 0.0 {
      return 1.0 / pos
    }
    return 0.0
  }
  // Taylor展开 for x in [-5, 20]
  let mut result = 1.0
  let mut term = 1.0
  for i in 1..<60 {
    term = term * x / i.to_double()
    result += term
    if term < 0.000000000000001 && term > -0.000000000000001 {
      break
    }
  }
  result
}

///|
/// 自然对数 ln(x) (x > 0)
pub fn ln_d(x : Double) -> Double {
  if x <= 0.0 {
    return -1000000000000000000000000000000.0
  }
  // 归约到 [0.5, 1.5) 通过乘除e
  let mut y = x
  let mut k = 0.0
  while y > 1.5 {
    y = y / 2.718281828459045
    k += 1.0
  }
  while y < 0.5 {
    y = y * 2.718281828459045
    k -= 1.0
  }
  // Taylor: ln(1+t) = t - t²/2 + t³/3 - ...
  let t = y - 1.0
  let mut result = 0.0
  let mut t_pow = t
  for i in 1..<50 {
    let term = t_pow / i.to_double()
    if i % 2 == 1 {
      result += term
    } else {
      result -= term
    }
    t_pow *= t
    if t_pow < 0.000000000000001 && t_pow > -0.000000000000001 {
      break
    }
  }
  result + k
}

///|
/// 绝对值
pub fn abs_d(x : Double) -> Double {
  if x < 0.0 { -x } else { x }
}

///|
/// 温度修正系数 (Arrhenius方程)
/// k_T = k_20 × θ^(T-20)
pub fn temp_correction(k20 : Double, theta : Double, temp : Double) -> Double {
  k20 * pow_d(theta, temp - 20.0)
}

///|
/// 限制值在范围内
pub fn clamp(val : Double, lo : Double, hi : Double) -> Double {
  if val < lo { lo }
  else if val > hi { hi }
  else { val }
}

///|
/// 最大值
pub fn max_d(a : Double, b : Double) -> Double {
  if a > b { a } else { b }
}

///|
/// 最小值
pub fn min_d(a : Double, b : Double) -> Double {
  if a < b { a } else { b }
}

// ============================================================================
// 默认值构造函数
// ============================================================================

///|
/// 默认进水水质 (10万吨/日典型城镇污水)
pub fn default_influent() -> WaterQuality {
  {
    cod: 280.0,
    bod5: 140.0,
    nh4_n: 35.0,
    no3_n: 0.5,
    tn: 45.0,
    tp: 6.0,
    po4_p: 4.5,
    ss: 200.0,
    mlss: 0.0,
    do_value: 0.0,
    temperature: 20.0,
    flow: 4167.0,
    ph: 7.2,
    alkalinity: 300.0,
  }
}

///|
/// 默认AAO配置 (ASM2d参数, 10万吨/日)
pub fn default_aao_config() -> AAOConfig {
  {
    anaerobic_volume: 2500.0,
    anoxic_volume: 8000.0,
    oxic_volume: 15000.0,
    do_setpoint: 2.5,
    internal_recycle_ratio: 6.0,
    external_recycle_ratio: 1.0,
    srt: 18.0,
    mlss_target: 4000.0,
    waste_sludge_flow: 350.0,
    mu_h: 6.0,
    mu_a: 1.2,
    k_s: 20.0,
    k_nh: 0.5,
    k_oh: 0.2,
    k_oa: 0.4,
    k_no: 0.5,
    b_h: 0.4,
    b_a: 0.15,
    y_h: 0.67,
    y_a: 0.24,
    eta_g: 0.9,
    q_pp: 5.0,
    y_po: 0.6,
    k_p: 0.2,
    i_nxb: 0.086,
    i_nxp: 0.06,
    theta_h: 1.07,
    theta_a: 1.11,
  }
}

///|
/// 默认全厂配置
pub fn default_plant_config() -> PlantConfig {
  {
    design_flow: 100000.0,
    screen_width: 2.0,
    grit_volume: 960.0,
    primary_volume: 1608.0,
    primary_area: 1608.0,
    aao: default_aao_config(),
    secondary_area: 4071.0,
    secondary_volume: 10177.0,
    filter_volume: 560.0,
    uv_dose: 20.0,
    thickener_volume: 1256.0,
    dewater_capacity: 500.0,
    pac_dose: 15.0,
    carbon_dose: 0.0,
  }
}

///|
/// 默认仿真状态
pub fn default_sim_state() -> SimState {
  {
    time: 0.0,
    influent: default_influent(),
    effluent: default_influent(),
    reactor: default_influent(),
    energy_total: 0.0,
    cost_total: 0.0,
    running: false,
    speed: 1.0,
    step_count: 0,
  }
}
