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
///
/// 支持 `interrupt()` 中断挂起的进程，`on_complete()` 注册完成回调（join 语义）。
pub(all) struct Process {
  id : @core.ProcessId
  name : String
  mut status : ProcessStatus
  behavior : ProcessBehavior
  mut interrupted : Bool
  completion_callbacks : Array[() -> Unit]
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
  let p : Process = {
    id,
    name,
    status: Created,
    behavior,
    interrupted: false,
    completion_callbacks: [],
  }
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
    Done => self._terminate()
    Terminate => self._terminate()
    Timeout(duration~, next~) => {
      self.status = Suspended
      ignore(
        env.schedule(time=env.now() + duration, callback=fn() {
          if self.interrupted {
            self._terminate()
          } else {
            self.status = Running
            self._run_action(env, next())
          }
        }),
      )
    }
    WaitEvent(event~, next~) => {
      self.status = Suspended
      event.add_callback(fn() {
        if self.interrupted {
          self._terminate()
        } else {
          self.status = Running
          self._run_action(env, next())
        }
      })
    }
  }
}

///|
/// 内部：终止进程并触发完成回调
fn Process::_terminate(self : Process) -> Unit {
  self.status = Terminated
  for cb in self.completion_callbacks {
    cb()
  }
  self.completion_callbacks.clear()
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

///|
/// 获取进程状态
pub fn Process::status(self : Process) -> ProcessStatus {
  self.status
}

///|
/// 中断挂起的进程
///
/// 设置中断标志。进程下一次被调度恢复时，不再执行正常续延，
/// 而是直接终止并触发完成回调。对已终止的进程调用无效果。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=20.0)
///   let log : Array[String] = []
///   let p = @process.process(env, name="worker", behavior=fn(_) {
///     @process.Timeout(duration=10.0, next=fn() {
///       log.push("resumed")
///       @process.Done
///     })
///   })
///   ignore(
///     @process.process(env, name="interrupter", behavior=fn(_) {
///       p.interrupt()
///       log.push("interrupted")
///       @process.Done
///     }),
///   )
///   env.run()
///   assert_eq(log[0], "interrupted")
///   assert_false(p.is_alive())
/// }
/// ```
pub fn Process::interrupt(self : Process) -> Unit {
  if !(self.status is Terminated) {
    self.interrupted = true
  }
}

///|
/// 进程是否被中断
pub fn Process::is_interrupted(self : Process) -> Bool {
  self.interrupted
}

///|
/// 注册进程完成回调（join 语义）
///
/// 当进程执行完毕（Done/Terminate/中断）时调用 `callback`。
/// 若进程已完成，立即调用。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let log : Array[String] = []
///   let p = @process.process(env, name="worker", behavior=fn(_) {
///     @process.Timeout(duration=3.0, next=fn() { @process.Done })
///   })
///   p.on_complete(fn() { log.push("worker done") })
///   env.run()
///   assert_eq(log[0], "worker done")
/// }
/// ```
pub fn Process::on_complete(self : Process, callback : () -> Unit) -> Unit {
  if self.status is Terminated {
    callback()
  } else {
    self.completion_callbacks.push(callback)
  }
}
