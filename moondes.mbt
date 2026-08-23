///|
/// MoonDES 通用离散事件仿真引擎
///
/// 基于 MoonBit 构建的通用离散事件仿真底座，提供十一层模块化架构：
/// - Core 仿真内核层：事件队列、仿真环境、主循环
/// - Process 协程进程调度层：进程创建、延时、等待
/// - Resource 资源管理层：独占/容量/抢占三类资源
/// - Experiment 实验管理层：批量仿真、快照、参数遍历
/// - Plugin 插件接口层：标准化扩展接口
/// - Random 随机数层：分布采样（均匀/指数/正态/泊松）
/// - Stats 统计层：均值/方差/直方图/相关系数
/// - Monitor 监控层：仿真日志、指标采集、trace 导出
/// - Distributed 分布式仿真层：多环境管理、任务调度、结果聚合
/// - Sync 进程同步原语层：信号事件、条件组合、信号量、屏障、容器
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
  "2.1.0"
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

///|
/// 创建信号事件（便捷入口，转发至 sync 层）
pub fn new_signal(env : @core.SimulationEnv) -> @sync.SignalEvent {
  @sync.new_signal(env)
}

///|
/// 创建计数信号量（便捷入口，转发至 sync 层）
pub fn new_semaphore(count~ : Int) -> @sync.Semaphore {
  @sync.new_semaphore(count~)
}

///|
/// 创建同步屏障（便捷入口，转发至 sync 层）
pub fn new_barrier(n~ : Int) -> @sync.Barrier {
  @sync.new_barrier(n~)
}

///|
/// 创建连续资源容器（便捷入口，转发至 sync 层）
pub fn new_container(capacity~ : Double) -> @sync.Container {
  @sync.new_container(capacity~)
}

///|
/// 条件组合：等待任意信号触发（便捷入口，转发至 sync 层）
pub fn any_of(
  env : @core.SimulationEnv,
  signals : Array[@sync.SignalEvent],
) -> @sync.SignalEvent {
  @sync.any_of(env, signals)
}

///|
/// 条件组合：等待全部信号触发（便捷入口，转发至 sync 层）
pub fn all_of(
  env : @core.SimulationEnv,
  signals : Array[@sync.SignalEvent],
) -> @sync.SignalEvent {
  @sync.all_of(env, signals)
}

///|
/// 创建事件时间线（便捷入口，转发至 analysis 层）
pub fn new_timeline() -> @analysis.EventTimeline {
  @analysis.new_timeline()
}

///|
/// 创建资源追踪器（便捷入口，转发至 analysis 层）
pub fn new_resource_tracker() -> @analysis.ResourceTracker {
  @analysis.new_resource_tracker()
}

///|
/// 创建仿真报告生成器（便捷入口，转发至 analysis 层）
pub fn new_report() -> @analysis.SimulationReport {
  @analysis.new_report()
}

///|
/// 创建 FIFO 物品仓库（便捷入口，转发至 sync 层）
pub fn[T] new_store() -> @sync.Store[T] {
  @sync.new_store()
}

///|
/// 创建优先级物品仓库（便捷入口，转发至 sync 层）
pub fn[T] new_priority_store() -> @sync.PriorityStore[T] {
  @sync.new_priority_store()
}

///|
/// 创建单向延迟链路（便捷入口，转发至 network 层）
pub fn new_link(
  env : @core.SimulationEnv,
  name~ : String,
  delay~ : Double,
) -> @network.Link {
  @network.new_link(env, name~, delay~)
}

///|
/// 创建双向通道（便捷入口，转发至 network 层）
pub fn new_channel(
  env : @core.SimulationEnv,
  name~ : String,
  delay~ : Double,
) -> @network.Channel {
  @network.new_channel(env, name~, delay~)
}

///|
/// 创建路由器（便捷入口，转发至 network 层）
pub fn new_router(name~ : String) -> @network.Router {
  @network.new_router(name~)
}
