///|
/// 分布式仿真任务
///
/// 一个任务描述一次独立的仿真运行配置及其优先级。
/// 任务调度器按优先级排序执行，优先级数值越小越先执行。
pub(all) struct SimTask {
  id : Int
  name : String
  config : @experiment.ExpConfig
  priority : Int
}

///|
/// 多环境管理器
///
/// 管理多个独立的 SimulationEnv 实例，支持批量创建、批量运行、
/// 结果收集。每个环境完全独立，无共享状态，天然支持并行仿真。
///
/// # Example
/// ```mbt check
/// test {
///   let mgr = @distributed.new_multi_env()
///   ignore(mgr.create_env(until=10.0))
///   ignore(mgr.create_env(until=20.0))
///   inspect(mgr.count(), content="2")
///   mgr.run_all()
///   inspect(mgr.all_finished(), content="true")
/// }
/// ```
pub(all) struct MultiEnv {
  envs : Array[@core.SimulationEnv]
}

///|
/// 创建多环境管理器
pub fn new_multi_env() -> MultiEnv {
  { envs: [] }
}

///|
/// 创建并注册一个新的仿真环境
pub fn MultiEnv::create_env(
  self : MultiEnv,
  until~ : Double,
) -> @core.SimulationEnv {
  let env = @core.new_env(until~)
  self.envs.push(env)
  env
}

///|
/// 注册一个已有的仿真环境
pub fn MultiEnv::add_env(self : MultiEnv, env : @core.SimulationEnv) -> Unit {
  self.envs.push(env)
}

///|
/// 获取环境数量
pub fn MultiEnv::count(self : MultiEnv) -> Int {
  self.envs.length()
}

///|
/// 按索引获取环境
pub fn MultiEnv::get_env(self : MultiEnv, index : Int) -> @core.SimulationEnv? {
  if index >= 0 && index < self.envs.length() {
    Some(self.envs[index])
  } else {
    None
  }
}

///|
/// 运行所有环境
pub fn MultiEnv::run_all(self : MultiEnv) -> Unit {
  for env in self.envs {
    env.run()
  }
}

///|
/// 检查所有环境是否都已结束
pub fn MultiEnv::all_finished(self : MultiEnv) -> Bool {
  for env in self.envs {
    if !env.is_finished() {
      return false
    }
  }
  true
}

///|
/// 收集所有环境的当前仿真时间
pub fn MultiEnv::collect_times(self : MultiEnv) -> Array[Double] {
  let times : Array[Double] = []
  for env in self.envs {
    times.push(env.now())
  }
  times
}

///|
/// 收集所有环境的事件计数
pub fn MultiEnv::collect_event_counts(self : MultiEnv) -> Array[Int] {
  let counts : Array[Int] = []
  for env in self.envs {
    counts.push(env.event_count())
  }
  counts
}

///|
/// 任务调度器
///
/// 管理仿真任务队列，按优先级排序执行。
/// 支持任务添加、优先级排序、批量执行、结果收集。
///
/// # Example
/// ```mbt check
/// test {
///   let sched = @distributed.new_task_scheduler()
///   let cfg = @experiment.new_config(until=10.0)
///   ignore(sched.submit(name="task_a", config=cfg, priority=2))
///   ignore(sched.submit(name="task_b", config=cfg, priority=1))
///   inspect(sched.pending_count(), content="2")
///   let results = sched.run_all()
///   inspect(results.length(), content="2")
/// }
/// ```
pub(all) struct TaskScheduler {
  tasks : Array[SimTask]
  mut next_task_id : Int
}

///|
/// 创建任务调度器
pub fn new_task_scheduler() -> TaskScheduler {
  { tasks: [], next_task_id: 0 }
}

///|
/// 提交一个仿真任务
///
/// 返回分配的任务 ID。优先级数值越小越先执行。
pub fn TaskScheduler::submit(
  self : TaskScheduler,
  name~ : String,
  config~ : @experiment.ExpConfig,
  priority? : Int = 0,
) -> Int {
  let id = self.next_task_id
  self.next_task_id = id + 1
  let task : SimTask = { id, name, config, priority }
  self._insert_sorted(task)
  id
}

///|
/// 按优先级插入任务队列（优先级数值小者排前）
fn TaskScheduler::_insert_sorted(self : TaskScheduler, task : SimTask) -> Unit {
  let mut idx = self.tasks.length()
  for i in 0..<self.tasks.length() {
    if task.priority < self.tasks[i].priority {
      idx = i
      break
    }
  }
  self.tasks.insert(idx, task)
}

///|
/// 待执行任务数
pub fn TaskScheduler::pending_count(self : TaskScheduler) -> Int {
  self.tasks.length()
}

///|
/// 执行所有待执行任务，返回实验结果数组
///
/// 任务按优先级顺序执行，执行完毕后任务队列清空。
pub fn TaskScheduler::run_all(
  self : TaskScheduler,
) -> Array[@experiment.ExpResult] {
  let results : Array[@experiment.ExpResult] = []
  for task in self.tasks {
    results.push(@experiment.run_experiment(task.config))
  }
  self.tasks.clear()
  results
}

///|
/// 执行所有任务并返回带任务信息的详细结果
///
/// 每个结果包含任务 ID、名称、优先级和实验结果。
pub fn TaskScheduler::run_all_detailed(
  self : TaskScheduler,
) -> Array[TaskResult] {
  let results : Array[TaskResult] = []
  for task in self.tasks {
    let exp_result = @experiment.run_experiment(task.config)
    results.push({ task_id: task.id, task_name: task.name, result: exp_result })
  }
  self.tasks.clear()
  results
}

///|
/// 任务执行结果（含任务元信息）
pub(all) struct TaskResult {
  task_id : Int
  task_name : String
  result : @experiment.ExpResult
}

///|
/// 获取任务队列快照（不执行，仅查看）
pub fn TaskScheduler::peek_tasks(self : TaskScheduler) -> Array[SimTask] {
  let copy : Array[SimTask] = []
  for t in self.tasks {
    copy.push(t)
  }
  copy
}

///|
/// 结果聚合器
///
/// 跨多次实验运行的结果进行统计聚合，计算均值、标准差、
/// 最小值、最大值等统计量。适用于蒙特卡洛仿真等场景。
///
/// # Example
/// ```mbt check
/// test {
///   let agg = @distributed.new_aggregator()
///   agg.add(10.0)
///   agg.add(20.0)
///   agg.add(30.0)
///   inspect(agg.count(), content="3")
///   inspect(agg.mean(), content="20")
/// }
/// ```
pub(all) struct ResultAggregator {
  values : Array[Double]
  // 命名指标：用于存储多维度结果
  metrics : Map[String, Array[Double]]
}

///|
/// 创建结果聚合器
pub fn new_aggregator() -> ResultAggregator {
  { values: [], metrics: Map([]) }
}

///|
/// 添加一个观测值
pub fn ResultAggregator::add(self : ResultAggregator, value : Double) -> Unit {
  self.values.push(value)
}

///|
/// 添加命名指标观测值
pub fn ResultAggregator::add_metric(
  self : ResultAggregator,
  name : String,
  value~ : Double,
) -> Unit {
  match self.metrics.get(name) {
    Some(arr) => arr.push(value)
    None => self.metrics[name] = [value]
  }
}

///|
/// 观测值数量
pub fn ResultAggregator::count(self : ResultAggregator) -> Int {
  self.values.length()
}

///|
/// 计算均值
pub fn ResultAggregator::mean(self : ResultAggregator) -> Double {
  @stats.mean(self.values)
}

///|
/// 计算标准差
pub fn ResultAggregator::stddev(self : ResultAggregator) -> Double {
  @stats.stddev(self.values)
}

///|
/// 计算最小值
pub fn ResultAggregator::min(self : ResultAggregator) -> Double {
  @stats.min(self.values)
}

///|
/// 计算最大值
pub fn ResultAggregator::max(self : ResultAggregator) -> Double {
  @stats.max(self.values)
}

///|
/// 计算总和
pub fn ResultAggregator::sum(self : ResultAggregator) -> Double {
  @stats.sum(self.values)
}

///|
/// 计算方差
pub fn ResultAggregator::variance(self : ResultAggregator) -> Double {
  @stats.variance(self.values)
}

///|
/// 生成完整统计摘要
pub fn ResultAggregator::summary(self : ResultAggregator) -> @stats.Summary {
  @stats.summary(self.values)
}

///|
/// 获取指定命名指标的所有观测值
pub fn ResultAggregator::get_metric(
  self : ResultAggregator,
  name : String,
) -> Array[Double]? {
  self.metrics.get(name)
}

///|
/// 计算指定命名指标的均值
pub fn ResultAggregator::metric_mean(
  self : ResultAggregator,
  name : String,
) -> Double? {
  match self.metrics.get(name) {
    Some(arr) => Some(@stats.mean(arr))
    None => None
  }
}

///|
/// 计算指定命名指标的标准差
pub fn ResultAggregator::metric_stddev(
  self : ResultAggregator,
  name : String,
) -> Double? {
  match self.metrics.get(name) {
    Some(arr) => Some(@stats.stddev(arr))
    None => None
  }
}

///|
/// 命名指标数量
pub fn ResultAggregator::metric_count(self : ResultAggregator) -> Int {
  self.metrics.length()
}

///|
/// 清空所有数据
pub fn ResultAggregator::clear(self : ResultAggregator) -> Unit {
  self.values.clear()
  self.metrics.clear()
}

///|
/// 从实验结果数组中提取 final_time 并添加为观测值
pub fn ResultAggregator::collect_final_times(
  self : ResultAggregator,
  results : Array[@experiment.ExpResult],
) -> Unit {
  for r in results {
    self.add(r.final_time)
  }
}

///|
/// 从实验结果数组中提取 event_count 并添加为命名指标
pub fn ResultAggregator::collect_event_counts(
  self : ResultAggregator,
  results : Array[@experiment.ExpResult],
) -> Unit {
  for r in results {
    self.add_metric("event_count", value=r.event_count.to_double())
  }
}
