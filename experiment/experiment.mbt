///|
/// 仿真实验配置
pub(all) struct ExpConfig {
  until : Double
  seed : Int
  params : Map[String, Double]
} derive(Debug)

///|
/// 仿真实验结果
pub(all) struct ExpResult {
  config : ExpConfig
  final_time : Double
  event_count : Int
  metrics : Map[String, Double]
} derive(Debug)

///|
/// 仿真快照
///
/// 捕获仿真环境状态，可用于断点回滚。
pub(all) struct Snapshot {
  time : Double
  event_count : Int
  env_snapshot : @core.EnvSnapshot
} derive(Debug)

///|
/// 创建实验配置
pub fn new_config(until~ : Double, seed? : Int = 0) -> ExpConfig {
  { until, seed, params: Map([]) }
}

///|
/// 向配置添加参数
pub fn ExpConfig::set_param(
  self : ExpConfig,
  key : String,
  value~ : Double,
) -> Unit {
  self.params[key] = value
}

///|
/// 运行单次仿真实验
///
/// 创建仿真环境并运行至终止时间，返回实验结果。
/// `event_count` 为仿真过程中注册的事件总数。
pub fn run_experiment(config : ExpConfig) -> ExpResult {
  let env = @core.new_env(until=config.until)
  env.run()
  {
    config,
    final_time: env.now(),
    event_count: env.event_count(),
    metrics: Map([]),
  }
}

///|
/// 批量运行多个实验配置
pub fn batch_run(configs : Array[ExpConfig]) -> Array[ExpResult] {
  let results : Array[ExpResult] = []
  for cfg in configs {
    results.push(run_experiment(cfg))
  }
  results
}

///|
/// 保存仿真快照
///
/// 捕获当前仿真时间、事件数与环境内部状态，可用于 `rollback`。
pub fn snapshot(env : @core.SimulationEnv) -> Snapshot {
  {
    time: env.now(),
    event_count: env.event_count(),
    env_snapshot: env.snapshot(),
  }
}

///|
/// 断点回滚：从快照恢复环境状态
///
/// 恢复仿真时钟、环境状态、ID 计数器。
/// 注意：事件队列与回调不恢复，回滚后需重新调度后续事件。
pub fn rollback(env : @core.SimulationEnv, snap : Snapshot) -> Unit {
  env.restore(snap.env_snapshot)
}

///|
/// 参数遍历：生成一组参数变化的配置
pub fn param_sweep(
  base~ : ExpConfig,
  param_name~ : String,
  values~ : Array[Double],
) -> Array[ExpConfig] {
  let configs : Array[ExpConfig] = []
  for v in values {
    let cfg = new_config(until=base.until, seed=base.seed)
    cfg.set_param(param_name, value=v)
    for k, val in base.params {
      cfg.set_param(k, value=val)
    }
    configs.push(cfg)
  }
  configs
}
