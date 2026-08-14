///|
/// 进程状态
pub(all) enum ProcessStatus {
  Created
  Running
  Suspended
  Terminated
} derive(Debug, Eq)

///|
/// 仿真进程
///
/// 基于事件回调实现协程式进程调度。进程通过 `timeout`、`wait_event` 等操作挂起，
/// 引擎在事件触发时恢复进程执行。不占用操作系统线程，支持上万并发进程。
pub(all) struct Process {
  id : @core.ProcessId
  name : String
  mut status : ProcessStatus
  // 进程行为函数：接收进程自身，返回 Unit
  behavior : (Process) -> Unit
}

///|
/// 创建仿真进程并注册到环境
///
/// 进程在 `env.run()` 时按调度顺序执行其 behavior。
pub fn process(
  env : @core.SimulationEnv,
  name? : String = "",
  behavior~ : (Process) -> Unit,
) -> Process {
  let id = env._alloc_process_id()
  let p : Process = { id, name, status: Created, behavior }
  // 在 time=0 调度进程启动
  ignore(env.schedule(time=0.0, callback=fn() { p._start() }))
  p
}

///|
/// 启动进程
fn Process::_start(self : Process) -> Unit {
  self.status = Running
  (self.behavior)(self)
  self.status = Terminated
}

///|
/// 进程延时等待：在当前仿真时间 + duration 后恢复
pub fn Process::timeout(
  self : Process,
  env : @core.SimulationEnv,
  duration : Double,
) -> Unit {
  self.status = Suspended
  ignore(
    env.schedule(time=env.now() + duration, callback=fn() {
      self.status = Running
    }),
  )
}

///|
/// 进程等待指定事件触发
pub fn Process::wait_event(
  self : Process,
  _env : @core.SimulationEnv,
  event : @core.Event,
) -> Unit {
  self.status = Suspended
  event.add_callback(fn() { self.status = Running })
}

///|
/// 进程终止
pub fn Process::terminate(self : Process) -> Unit {
  self.status = Terminated
}

///|
/// 进程是否存活
pub fn Process::is_alive(self : Process) -> Bool {
  !(self.status is Terminated)
}

///|
/// 获取进程 ID
pub fn Process::id(self : Process) -> @core.ProcessId {
  self.id
}

///|
/// 获取进程名称
pub fn Process::name(self : Process) -> String {
  self.name
}
