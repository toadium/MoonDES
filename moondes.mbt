///|
/// MoonDES 通用离散事件仿真引擎
///
/// 基于 MoonBit 构建的通用离散事件仿真底座，提供九层模块化架构：
/// - Core 仿真内核层：事件队列、仿真环境、主循环
/// - Process 协程进程调度层：进程创建、延时、等待
/// - Resource 资源管理层：独占/容量/抢占三类资源
/// - Experiment 实验管理层：批量仿真、快照、参数遍历
/// - Plugin 插件接口层：标准化扩展接口
/// - Random 随机数层：分布采样（均匀/指数/正态/泊松）
/// - Stats 统计层：均值/方差/直方图/相关系数
/// - Monitor 监控层：仿真日志、指标采集、trace 导出
/// - Distributed 分布式仿真层：多环境管理、任务调度、结果聚合
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let log : Array[String] = []
///   ignore(env.schedule(time=2.0, callback=fn() { log.push("hello") }))
///   env.run()
///   assert_eq(log.length(), 1)
/// }
/// ```
pub fn version() -> String {
  "1.4.0"
}

///|
/// 创建仿真环境（便捷入口，转发至 core 层）
pub fn new_env(until~ : Double) -> @core.SimulationEnv {
  @core.new_env(until~)
}

///|
/// 创建实验配置（便捷入口，转发至 experiment 层）
pub fn new_config(until~ : Double, seed? : Int = 0) -> @experiment.ExpConfig {
  @experiment.new_config(until~, seed~)
}

///|
/// 创建独占式资源（便捷入口，转发至 resource 层）
pub fn new_exclusive(name~ : String) -> @resource.Resource {
  @resource.new_exclusive(name~)
}

///|
/// 创建进程（便捷入口，转发至 process 层）
///
/// behavior 返回 `ProcessAction` 描述进程的下一步行为：
/// - `Done`：进程完成
/// - `Timeout(duration=, next=)`：延时后执行 next
/// - `WaitEvent(event=, next=)`：等待事件后执行 next
/// - `Terminate`：立即终止
pub fn process(
  env : @core.SimulationEnv,
  name? : String = "anonymous",
  behavior~ : (@process.Process) -> @process.ProcessAction,
) -> @process.Process {
  @process.process(env, name~, behavior~)
}

///|
/// 创建插件管理器（便捷入口，转发至 plugin 层）
pub fn new_plugin_manager() -> @plugin.PluginManager {
  @plugin.new_manager()
}

///|
/// 创建随机数生成器（便捷入口，转发至 random 层）
pub fn new_rng() -> @rand.Rand {
  @random.new_rng()
}

///|
/// 统计摘要（便捷入口，转发至 stats 层）
pub fn summary(data : Array[Double]) -> @stats.Summary {
  @stats.summary(data)
}

///|
/// 创建仿真日志器（便捷入口，转发至 monitor 层）
pub fn new_logger(min_level~ : @monitor.LogLevel) -> @monitor.SimLogger {
  @monitor.new_logger(min_level~)
}

///|
/// 创建指标采集器（便捷入口，转发至 monitor 层）
pub fn new_metrics() -> @monitor.MetricsCollector {
  @monitor.new_metrics()
}

///|
/// 创建 Trace 导出器（便捷入口，转发至 monitor 层）
pub fn new_tracer() -> @monitor.TraceExporter {
  @monitor.new_tracer()
}

///|
/// 创建多环境管理器（便捷入口，转发至 distributed 层）
pub fn new_multi_env() -> @distributed.MultiEnv {
  @distributed.new_multi_env()
}

///|
/// 创建任务调度器（便捷入口，转发至 distributed 层）
pub fn new_task_scheduler() -> @distributed.TaskScheduler {
  @distributed.new_task_scheduler()
}

///|
/// 创建结果聚合器（便捷入口，转发至 distributed 层）
pub fn new_aggregator() -> @distributed.ResultAggregator {
  @distributed.new_aggregator()
}
