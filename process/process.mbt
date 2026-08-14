///|
/// 进程状态
pub(all) enum ProcessStatus {
  Created
  Running
  Suspended
  Terminated
} derive(Debug, Eq)

///|
/// 进程动作：描述进程的下一步行为
///
/// 进程行为函数返回 `ProcessAction` 与调度器交互，实现协程式挂起-恢复：
/// - `Done`：进程执行完毕
/// - `Timeout`：延时 `duration` 后执行 `next`，仿真时间推进
/// - `WaitEvent`：等待 `event` 触发后执行 `next`
/// - `Terminate`：立即终止进程
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=20.0)
///   let log : Array[String] = []
///   ignore(
///     process(env, name="timer", behavior=fn(_) {
///       log.push("start at \{env.now()}")
///       Timeout(duration=5.0, next=fn() {
///         log.push("resume at \{env.now()}")
///         Done
///       })
///     }),
///   )
///   env.run()
///   assert_eq(log[0], "start at 0")
///   assert_eq(log[1], "resume at 5")
/// }
/// ```
pub(all) enum ProcessAction {
  Done
  Timeout(duration~ : Double, next~ : () -> ProcessAction)
  WaitEvent(event~ : @core.Event, next~ : () -> ProcessAction)
  Terminate
}

///|
/// 进程行为函数类型
pub type ProcessBehavior = (Process) -> ProcessAction

///|
/// 仿真进程
///
/// 基于指令式协程调度。进程行为函数返回 `ProcessAction` 描述下一步行为，
/// 引擎根据动作调度恢复事件，在事件触发时执行 `next` 续延。
/// 不占用操作系统线程，支持上万并发进程。
pub(all) struct Process {
  id : @core.ProcessId
  name : String
  mut status : ProcessStatus
  behavior : ProcessBehavior
}

///|
/// 创建仿真进程并注册到环境
///
/// 进程在 `env.run()` 时按调度顺序执行其 behavior。
/// behavior 返回 `ProcessAction` 描述进程的下一步行为。
pub fn process(
  env : @core.SimulationEnv,
  name? : String = "",
  behavior~ : ProcessBehavior,
) -> Process {
  let id = env._alloc_process_id()
  let p : Process = { id, name, status: Created, behavior }
  // 在 time=0 调度进程启动
  ignore(env.schedule(time=0.0, callback=fn() { p._start(env) }))
  p
}

///|
/// 启动进程：执行 behavior 并处理返回的 action
fn Process::_start(self : Process, env : @core.SimulationEnv) -> Unit {
  self.status = Running
  self._run_action(env, (self.behavior)(self))
}

///|
/// 执行 action：根据动作类型调度恢复或终止
fn Process::_run_action(
  self : Process,
  env : @core.SimulationEnv,
  action : ProcessAction,
) -> Unit {
  match action {
    Done => self.status = Terminated
    Terminate => self.status = Terminated
    Timeout(duration~, next~) => {
      self.status = Suspended
      ignore(
        env.schedule(time=env.now() + duration, callback=fn() {
          self.status = Running
          self._run_action(env, next())
        }),
      )
    }
    WaitEvent(event~, next~) => {
      self.status = Suspended
      event.add_callback(fn() {
        self.status = Running
        self._run_action(env, next())
      })
    }
  }
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
