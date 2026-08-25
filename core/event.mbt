///|
/// 事件优先级：数值越小优先级越高
pub type EventPriority = Int

///|
/// 事件 ID 类型，用于唯一标识事件
pub type EventId = Int

///|
/// 仿真进程 ID 类型
pub type ProcessId = Int

///|
/// 事件状态
pub(all) enum EventStatus {
  Pending
  Triggered
  Canceled
} derive(Debug, Eq)

///|
/// 仿真事件
///
/// 事件是离散事件仿真的基本调度单元，按 `(time, priority)` 排序：
/// 时间越小越早执行，同一时间下优先级数值越小越先执行。
pub(all) struct Event {
  id : EventId
  time : Double
  priority : EventPriority
  mut status : EventStatus
  callbacks : Array[() -> Unit]
}

///|
/// 事件排序比较：先按时间，再按优先级
fn event_compare(a : Event, b : Event) -> Int {
  if a.time < b.time {
    -1
  } else if a.time > b.time {
    1
  } else if a.priority < b.priority {
    -1
  } else if a.priority > b.priority {
    1
  } else {
    0
  }
}

///|
/// 创建新事件
pub fn new_event(
  id~ : EventId,
  time~ : Double,
  priority? : EventPriority = 0,
  callback~ : () -> Unit,
) -> Event {
  { id, time, priority, status: Pending, callbacks: [callback] }
}

///|
/// 向事件追加回调
pub fn Event::add_callback(self : Event, callback : () -> Unit) -> Unit {
  self.callbacks.push(callback)
}

///|
/// 触发事件：执行所有回调
pub fn Event::trigger(self : Event) -> Unit {
  if self.status is Pending {
    self.status = Triggered
    for cb in self.callbacks {
      cb()
    }
  }
}

///|
/// 取消事件
pub fn Event::cancel(self : Event) -> Unit {
  self.status = Canceled
}

///|
/// 事件是否仍待处理
pub fn Event::is_pending(self : Event) -> Bool {
  self.status is Pending
}
