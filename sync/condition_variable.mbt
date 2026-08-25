///|
/// 条件变量
///
/// 经典同步原语，允许进程等待某个条件成立，其他进程在条件可能改变时通知。
/// - `wait(callback)` — 注册等待，条件不满足时挂起
/// - `notify_one()` — 唤醒一个等待者（FIFO）
/// - `notify_all()` — 唤醒所有等待者
///
/// 适用于：生产者-消费者条件检查、资源可用性等待、批量唤醒等场景。
///
/// # Example
/// ```mbt check
/// test {
///   let cv = @sync.new_condition_variable()
///   let log : Array[String] = []
///   cv.wait(fn() { log.push("woken") })
///   assert_eq(cv.waiter_count(), 1)
///   ignore(cv.notify_one())
///   assert_eq(cv.waiter_count(), 0)
///   assert_eq(log[0], "woken")
/// }
/// ```
pub(all) struct ConditionVariable {
  waiters : Array[() -> Unit]
}

///|
/// 创建条件变量
pub fn new_condition_variable() -> ConditionVariable {
  { waiters: [] }
}

///|
/// 等待条件成立
///
/// 注册 `callback`，在 `notify_one` 或 `notify_all` 时被调用。
/// 调用者通常在 callback 中重新检查条件，若仍不满足则再次 `wait`。
pub fn ConditionVariable::wait(
  self : ConditionVariable,
  callback : () -> Unit,
) -> Unit {
  self.waiters.push(callback)
}

///|
/// 唤醒一个等待者
///
/// 按 FIFO 顺序唤醒最早注册的等待者。
/// 无等待者时无操作。返回是否唤醒了某人。
pub fn ConditionVariable::notify_one(self : ConditionVariable) -> Bool {
  if self.waiters.length() > 0 {
    let cb = self.waiters.remove(0)
    cb()
    true
  } else {
    false
  }
}

///|
/// 唤醒所有等待者
///
/// 按 FIFO 顺序依次唤醒所有等待者。
/// 返回唤醒的等待者数量。
pub fn ConditionVariable::notify_all(self : ConditionVariable) -> Int {
  let count = self.waiters.length()
  while self.waiters.length() > 0 {
    let cb = self.waiters.remove(0)
    cb()
  }
  count
}

///|
/// 等待者数量
pub fn ConditionVariable::waiter_count(self : ConditionVariable) -> Int {
  self.waiters.length()
}

///|
/// 是否有等待者
pub fn ConditionVariable::has_waiters(self : ConditionVariable) -> Bool {
  self.waiters.length() > 0
}

///|
/// 清空所有等待者
///
/// 不调用任何回调，直接移除。返回被清除的等待者数量。
pub fn ConditionVariable::clear(self : ConditionVariable) -> Int {
  let count = self.waiters.length()
  self.waiters.clear()
  count
}
