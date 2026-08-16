///|
/// 仿真环境状态
pub(all) enum EnvStatus {
  Initialized
  Running
  Finished
} derive(Debug, Eq, ToJson)

///|
/// 从 JSON 反序列化 EnvStatus
pub impl FromJson for EnvStatus with fn from_json(json, path) {
  match json {
    Json::String(s) =>
      match s {
        "Initialized" => Initialized
        "Running" => Running
        "Finished" => Finished
        _ =>
          raise @json.JsonDecodeError::JsonDecodeError(
            (path, "unknown EnvStatus"),
          )
      }
    _ => raise @json.JsonDecodeError::JsonDecodeError((path, "expected string"))
  }
}

///|
/// 全局仿真环境
///
/// 管理虚拟仿真时钟、事件队列和主仿真循环。
/// 内核完全无全局可变共享状态，天然支持多实例并行仿真。
/// 支持插件钩子：on_step / on_event / on_finish，由 plugin::attach 设置。
pub(all) struct SimulationEnv {
  mut now : Double
  until : Double
  queue : EventQueue
  mut status : EnvStatus
  mut next_event_id : EventId
  mut next_process_id : ProcessId
  // 事件注册表：id -> Event
  events : Map[EventId, Event]
  // 插件钩子（由 plugin::attach 设置）
  mut on_step_hook : ((SimulationEnv, Double) -> Unit)?
  mut on_event_hook : ((SimulationEnv, Event) -> Unit)?
  mut on_finish_hook : ((SimulationEnv) -> Unit)?
}

///|
/// 创建仿真环境，指定仿真终止时间
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=100.0)
///   inspect(env.now(), content="0")
///   inspect(env.until, content="100")
/// }
/// ```
pub fn new_env(until~ : Double) -> SimulationEnv {
  {
    now: 0.0,
    until,
    queue: new_queue(),
    status: Initialized,
    next_event_id: 0,
    next_process_id: 0,
    events: Map([]),
    on_step_hook: None,
    on_event_hook: None,
    on_finish_hook: None,
  }
}

///|
/// 获取当前仿真时间
pub fn SimulationEnv::now(self : SimulationEnv) -> Double {
  self.now
}

///|
/// 仿真是否已结束
pub fn SimulationEnv::is_finished(self : SimulationEnv) -> Bool {
  self.status is Finished
}

///|
/// 分配新的事件 ID
pub fn SimulationEnv::_alloc_event_id(self : SimulationEnv) -> EventId {
  let id = self.next_event_id
  self.next_event_id = id + 1
  id
}

///|
/// 分配新的进程 ID
pub fn SimulationEnv::_alloc_process_id(self : SimulationEnv) -> ProcessId {
  let id = self.next_process_id
  self.next_process_id = id + 1
  id
}

///|
/// 调度一个事件在指定时间触发
///
/// 返回创建的事件对象，可用于后续等待或取消。
pub fn SimulationEnv::schedule(
  self : SimulationEnv,
  time~ : Double,
  priority? : EventPriority = 0,
  callback~ : () -> Unit,
) -> Event {
  let id = self._alloc_event_id()
  let event = new_event(id~, time~, priority~, callback~)
  self.events[id] = event
  self.queue.push(event)
  event
}

///|
/// 创建一个超时事件：在当前时间 + duration 后触发
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let ev = env.timeout(5.0)
///   inspect(ev.time, content="5")
///   inspect(ev.is_pending(), content="true")
/// }
/// ```
pub fn SimulationEnv::timeout(self : SimulationEnv, duration : Double) -> Event {
  self.schedule(time=self.now + duration, callback=() => ())
}

///|
/// 注册事件到环境（供外部创建的 Event 加入队列）
pub fn SimulationEnv::_register_event(
  self : SimulationEnv,
  event : Event,
) -> Unit {
  self.events[event.id] = event
  self.queue.push(event)
}

///|
/// 按事件 ID 查找事件
pub fn SimulationEnv::get_event(self : SimulationEnv, id : EventId) -> Event? {
  self.events.get(id)
}

///|
/// 设置 on_step 钩子（每个事件处理前调用）
pub fn SimulationEnv::_set_on_step_hook(
  self : SimulationEnv,
  hook : ((SimulationEnv, Double) -> Unit)?,
) -> Unit {
  self.on_step_hook = hook
}

///|
/// 设置 on_event 钩子（事件触发后调用）
pub fn SimulationEnv::_set_on_event_hook(
  self : SimulationEnv,
  hook : ((SimulationEnv, Event) -> Unit)?,
) -> Unit {
  self.on_event_hook = hook
}

///|
/// 设置 on_finish 钩子（仿真结束时调用）
pub fn SimulationEnv::_set_on_finish_hook(
  self : SimulationEnv,
  hook : ((SimulationEnv) -> Unit)?,
) -> Unit {
  self.on_finish_hook = hook
}

///|
/// 触发 on_step 钩子
fn SimulationEnv::_fire_on_step(self : SimulationEnv) -> Unit {
  match self.on_step_hook {
    Some(hook) => hook(self, self.now)
    None => ()
  }
}

///|
/// 触发 on_event 钩子
fn SimulationEnv::_fire_on_event(self : SimulationEnv, event : Event) -> Unit {
  match self.on_event_hook {
    Some(hook) => hook(self, event)
    None => ()
  }
}

///|
/// 触发 on_finish 钩子（仅一次）
fn SimulationEnv::_fire_on_finish(self : SimulationEnv) -> Unit {
  match self.on_finish_hook {
    Some(hook) => hook(self)
    None => ()
  }
}

///|
/// 结束仿真：调用 on_finish 钩子并设置状态（保证仅一次）
fn SimulationEnv::_finish(self : SimulationEnv) -> Unit {
  if !(self.status is Finished) {
    self._fire_on_finish()
    self.status = Finished
  }
}

///|
/// 主仿真循环：按时间顺序处理所有事件直到队列为空或到达终止时间
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let log : Array[String] = []
///   ignore(env.schedule(time=2.0, callback=fn() { log.push("A") }))
///   ignore(env.schedule(time=1.0, callback=fn() { log.push("B") }))
///   env.run()
///   assert_eq(log[0], "B")
///   assert_eq(log[1], "A")
/// }
/// ```
pub fn SimulationEnv::run(self : SimulationEnv) -> Unit {
  self.status = Running
  while !self.queue.is_empty() {
    match self.queue.pop() {
      Some(event) =>
        match event.status {
          Pending => {
            if event.time > self.until {
              self.now = self.until
              break
            }
            self.now = event.time
            self._fire_on_step()
            event.trigger()
            self._fire_on_event(event)
          }
          _ => continue
        }
      None => break
    }
  }
  if self.now != self.until {
    self.now = self.until
  }
  self._finish()
}

///|
/// 单步推进：处理下一个事件（用于调试和插件控制）
pub fn SimulationEnv::step(self : SimulationEnv) -> Bool {
  while !self.queue.is_empty() {
    match self.queue.pop() {
      Some(event) =>
        match event.status {
          Pending => {
            if event.time > self.until {
              self.now = self.until
              self._finish()
              return false
            }
            self.now = event.time
            self._fire_on_step()
            event.trigger()
            self._fire_on_event(event)
            return true
          }
          _ => continue
        }
      None => {
        self._finish()
        return false
      }
    }
  }
  self._finish()
  false
}

///|
/// 环境状态快照（用于断点回滚）
///
/// 捕获仿真环境的可变状态，可通过 `restore` 恢复。
/// 注意：仅恢复时钟、状态、ID 计数器，不恢复事件队列与回调。
pub(all) struct EnvSnapshot {
  now : Double
  status : EnvStatus
  next_event_id : EventId
  next_process_id : ProcessId
} derive(Debug, Eq, ToJson)

///|
/// 从 JSON 反序列化 EnvSnapshot
pub impl FromJson for EnvSnapshot with fn from_json(json, path) {
  match json {
    Json::Object(map) =>
      {
        now: @json.from_json(map["now"], path=path.add_key("now")),
        status: @json.from_json(map["status"], path=path.add_key("status")),
        next_event_id: @json.from_json(
          map["next_event_id"],
          path=path.add_key("next_event_id"),
        ),
        next_process_id: @json.from_json(
          map["next_process_id"],
          path=path.add_key("next_process_id"),
        ),
      }
    _ => raise @json.JsonDecodeError::JsonDecodeError((path, "expected object"))
  }
}

///|
/// 获取已注册的事件总数
pub fn SimulationEnv::event_count(self : SimulationEnv) -> Int {
  self.events.length()
}

///|
/// 捕获环境当前状态快照
pub fn SimulationEnv::snapshot(self : SimulationEnv) -> EnvSnapshot {
  {
    now: self.now,
    status: self.status,
    next_event_id: self.next_event_id,
    next_process_id: self.next_process_id,
  }
}

///|
/// 从快照恢复环境状态
///
/// 恢复时钟、状态、ID 计数器。事件队列与回调不恢复。
pub fn SimulationEnv::restore(self : SimulationEnv, snap : EnvSnapshot) -> Unit {
  self.now = snap.now
  self.status = snap.status
  self.next_event_id = snap.next_event_id
  self.next_process_id = snap.next_process_id
}
