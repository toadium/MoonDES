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
pub(all) struct Snapshot {
  time : Double
  event_count : Int
}

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
pub fn run_experiment(config : ExpConfig) -> ExpResult {
  let env = @core.new_env(until=config.until)
  env.run()
  { config, final_time: env.now(), event_count: 0, metrics: Map([]) }
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
pub fn snapshot(env : @core.SimulationEnv) -> Snapshot {
  { time: env.now(), event_count: 0 }
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
