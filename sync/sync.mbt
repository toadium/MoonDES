///|
/// 信号事件
///
/// 不绑定仿真时间的可触发事件，用于进程间同步。
/// 与 `core::Event` 不同，信号事件不进入事件队列，
/// 而是通过 `fire()` 手动触发。等待者通过 `wait()` 注册回调，
/// 若信号已触发则立即执行回调，否则延迟到 `fire()` 时执行。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let sig = new_signal(env)
///   let log : Array[String] = []
///   sig.wait(fn() { log.push("triggered") })
///   inspect(sig.is_fired(), content="false")
///   sig.fire()
///   inspect(sig.is_fired(), content="true")
///   assert_eq(log.length(), 1)
/// }
/// ```
pub(all) struct SignalEvent {
  event : @core.Event
  mut fired : Bool
}

///|
/// 创建信号事件
///
/// 信号事件不进入事件队列，需手动 `fire()` 触发。
pub fn new_signal(env : @core.SimulationEnv) -> SignalEvent {
  let id = env._alloc_event_id()
  let event = @core.new_event(id~, time=env.now(), callback=fn() { () })
  { event, fired: false }
}

///|
/// 触发信号事件
///
/// 执行所有已注册的等待回调。多次调用仅第一次有效。
pub fn SignalEvent::fire(self : SignalEvent) -> Unit {
  if !self.fired {
    self.fired = true
    self.event.trigger()
  }
}

///|
/// 信号事件是否已触发
pub fn SignalEvent::is_fired(self : SignalEvent) -> Bool {
  self.fired
}

///|
/// 等待信号事件触发
///
/// 若信号已触发，立即执行 `callback`；否则注册到回调列表，
/// 在 `fire()` 时执行。这是进程同步的基础原语。
pub fn SignalEvent::wait(self : SignalEvent, callback : () -> Unit) -> Unit {
  if self.fired {
    callback()
  } else {
    self.event.add_callback(callback)
  }
}

///|
/// 获取底层 Event（用于 ProcessAction::WaitEvent）
///
/// 注意：如果信号已触发，底层 Event 状态为 Triggered，
/// 此时 WaitEvent 不会恢复进程。应使用 `wait()` 代替。
pub fn SignalEvent::as_event(self : SignalEvent) -> @core.Event {
  self.event
}

///|
/// 条件组合：等待任意信号触发
///
/// 创建一个新的信号事件，当 `signals` 中任意一个触发时，
/// 结果信号也触发。适用于"等待多个资源中任意一个可用"的场景。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let s1 = new_signal(env)
///   let s2 = new_signal(env)
///   let s3 = new_signal(env)
///   let any = any_of(env, [s1, s2, s3])
///   let log : Array[String] = []
///   any.wait(fn() { log.push("one fired") })
///   s2.fire()
///   assert_eq(log.length(), 1)
///   inspect(any.is_fired(), content="true")
/// }
/// ```
pub fn any_of(
  env : @core.SimulationEnv,
  signals : Array[SignalEvent],
) -> SignalEvent {
  let result = new_signal(env)
  for sig in signals {
    sig.wait(fn() { result.fire() })
  }
  result
}

///|
/// 条件组合：等待全部信号触发
///
/// 创建一个新的信号事件，当 `signals` 中所有信号都触发时，
/// 结果信号才触发。适用于"等待所有前置条件就绪"的场景。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   let s1 = new_signal(env)
///   let s2 = new_signal(env)
///   let s3 = new_signal(env)
///   let all = all_of(env, [s1, s2, s3])
///   let log : Array[String] = []
///   all.wait(fn() { log.push("all fired") })
///   s1.fire()
///   inspect(all.is_fired(), content="false")
///   s2.fire()
///   inspect(all.is_fired(), content="false")
///   s3.fire()
///   inspect(all.is_fired(), content="true")
///   assert_eq(log.length(), 1)
/// }
/// ```
pub fn all_of(
  env : @core.SimulationEnv,
  signals : Array[SignalEvent],
) -> SignalEvent {
  let result = new_signal(env)
  let total = signals.length()
  if total == 0 {
    result.fire()
    return result
  }
  let mut triggered = 0
  for sig in signals {
    sig.wait(fn() {
      triggered = triggered + 1
      if triggered >= total {
        result.fire()
      }
    })
  }
  result
}

///|
/// 计数信号量
///
/// 控制对 N 个共享资源的访问。`acquire` 获取一个许可，
/// `release` 释放一个许可。当许可数为 0 时，`acquire` 阻塞等待。
///
/// 与 `resource::Capacity` 的区别：Semaphore 是同步原语，
/// 不绑定具体资源实体，仅控制并发数。
///
/// # Example
/// ```mbt check
/// test {
///   let sem = new_semaphore(count=2)
///   let log : Array[String] = []
///   inspect(sem.available(), content="2")
///   sem.acquire(fn() { log.push("a") })
///   sem.acquire(fn() { log.push("b") })
///   inspect(sem.available(), content="0")
///   sem.acquire(fn() { log.push("c") }) // 阻塞
///   inspect(log.length(), content="2")
///   sem.release() // 唤醒 c
///   assert_eq(log.length(), 3)
/// }
/// ```
pub(all) struct Semaphore {
  mut count : Int
  waiters : Array[() -> Unit]
}

///|
/// 创建计数信号量
pub fn new_semaphore(count~ : Int) -> Semaphore {
  { count, waiters: [] }
}

///|
/// 获取许可
///
/// 若有可用许可，立即执行 `callback`；否则加入等待队列，
/// 在 `release()` 时唤醒。
pub fn Semaphore::acquire(self : Semaphore, callback : () -> Unit) -> Unit {
  if self.count > 0 {
    self.count = self.count - 1
    callback()
  } else {
    self.waiters.push(callback)
  }
}

///|
/// 释放许可
///
/// 若有等待者，直接唤醒队首等待者（许可数不变）；
/// 否则许可数 +1。
pub fn Semaphore::release(self : Semaphore) -> Unit {
  if self.waiters.length() > 0 {
    let waiter = self.waiters.remove(0)
    waiter()
  } else {
    self.count = self.count + 1
  }
}

///|
/// 当前可用许可数
pub fn Semaphore::available(self : Semaphore) -> Int {
  self.count
}

///|
/// 等待队列长度
pub fn Semaphore::queue_length(self : Semaphore) -> Int {
  self.waiters.length()
}

///|
/// 进程同步屏障
///
/// N 个进程到达屏障后全部阻塞，直到最后一个到达时，
/// 所有进程同时释放。适用于"等待所有参与者就绪后统一推进"的场景。
///
/// # Example
/// ```mbt check
/// test {
///   let bar = new_barrier(n=3)
///   let log : Array[Int] = []
///   bar.wait(fn() { log.push(1) })
///   inspect(log.length(), content="0")
///   bar.wait(fn() { log.push(2) })
///   inspect(log.length(), content="0")
///   bar.wait(fn() { log.push(3) })
///   assert_eq(log.length(), 3)
/// }
/// ```
pub(all) struct Barrier {
  n : Int
  mut waiting : Int
  waiters : Array[() -> Unit]
}

///|
/// 创建同步屏障
///
/// `n` 为需要等待的进程数。
pub fn new_barrier(n~ : Int) -> Barrier {
  { n, waiting: 0, waiters: [] }
}

///|
/// 到达屏障并等待
///
/// 若未到齐，阻塞等待；若已到齐（第 n 个到达），释放所有等待者。
pub fn Barrier::wait(self : Barrier, callback : () -> Unit) -> Unit {
  self.waiting = self.waiting + 1
  if self.waiting >= self.n {
    // 全部到齐，释放所有等待者
    self.waiting = 0
    let saved = self.waiters.copy()
    self.waiters.clear()
    callback()
    for w in saved {
      w()
    }
  } else {
    self.waiters.push(callback)
  }
}

///|
/// 当前等待数
pub fn Barrier::waiting_count(self : Barrier) -> Int {
  self.waiting
}

///|
/// 屏障是否已重置（无等待者）
pub fn Barrier::is_reset(self : Barrier) -> Bool {
  self.waiting == 0
}

///|
/// 连续资源容器
///
/// 模拟液位、储量等连续资源。具有 `level`（当前量）和 `capacity`（最大容量）。
/// `put` 注入量，`get` 取出量。当容器满时 `put` 阻塞，空时 `get` 阻塞。
///
/// 与 `resource::Resource` 的区别：Resource 是离散的（占用/释放），
/// Container 是连续的（注入/取出任意量）。
///
/// # Example
/// ```mbt check
/// test {
///   let tank = new_container(capacity=100.0)
///   tank.put(30.0, fn() { () })
///   inspect(tank.level(), content="30")
///   tank.get(10.0, fn() { () })
///   inspect(tank.level(), content="20")
///   inspect(tank.is_full(), content="false")
/// }
/// ```
pub(all) struct Container {
  mut level : Double
  capacity : Double
  // 等待放入的队列：(amount, callback)
  put_waiters : Array[ContainerWaiter]
  // 等待取出的队列：(amount, callback)
  get_waiters : Array[ContainerWaiter]
}

///|
/// 容器等待请求
pub(all) struct ContainerWaiter {
  amount : Double
  callback : () -> Unit
}

///|
/// 创建连续资源容器
///
/// 初始液位为 0。
pub fn new_container(capacity~ : Double) -> Container {
  { level: 0.0, capacity, put_waiters: [], get_waiters: [] }
}

///|
/// 创建连续资源容器（指定初始液位）
pub fn new_container_with(capacity~ : Double, initial~ : Double) -> Container {
  { level: initial, capacity, put_waiters: [], get_waiters: [] }
}

///|
/// 向容器注入量
///
/// 若容器有足够空间，立即注入并执行 `callback`；否则阻塞等待。
pub fn Container::put(
  self : Container,
  amount : Double,
  callback : () -> Unit,
) -> Unit {
  if self.level + amount <= self.capacity {
    self.level = self.level + amount
    callback()
    self._try_drain_get()
  } else {
    self.put_waiters.push({ amount, callback })
  }
}

///|
/// 从容器取出量
///
/// 若容器有足够量，立即取出并执行 `callback`；否则阻塞等待。
pub fn Container::get(
  self : Container,
  amount : Double,
  callback : () -> Unit,
) -> Unit {
  if self.level >= amount {
    self.level = self.level - amount
    callback()
    self._try_drain_put()
  } else {
    self.get_waiters.push({ amount, callback })
  }
}

///|
/// 尝试唤醒等待取出的请求
fn Container::_try_drain_get(self : Container) -> Unit {
  let mut continue_drain = true
  while continue_drain && self.get_waiters.length() > 0 {
    let waiter = self.get_waiters[0]
    if self.level >= waiter.amount {
      ignore(self.get_waiters.remove(0))
      self.level = self.level - waiter.amount
      (waiter.callback)()
    } else {
      continue_drain = false
    }
  }
}

///|
/// 尝试唤醒等待放入的请求
fn Container::_try_drain_put(self : Container) -> Unit {
  let mut continue_drain = true
  while continue_drain && self.put_waiters.length() > 0 {
    let waiter = self.put_waiters[0]
    if self.level + waiter.amount <= self.capacity {
      ignore(self.put_waiters.remove(0))
      self.level = self.level + waiter.amount
      (waiter.callback)()
    } else {
      continue_drain = false
    }
  }
}

///|
/// 当前液位
pub fn Container::level(self : Container) -> Double {
  self.level
}

///|
/// 容器容量
pub fn Container::capacity(self : Container) -> Double {
  self.capacity
}

///|
/// 容器是否已满
pub fn Container::is_full(self : Container) -> Bool {
  self.level >= self.capacity
}

///|
/// 容器是否为空
pub fn Container::is_empty(self : Container) -> Bool {
  self.level <= 0.0
}

///|
/// 等待放入的请求数
pub fn Container::put_queue_length(self : Container) -> Int {
  self.put_waiters.length()
}

///|
/// 等待取出的请求数
pub fn Container::get_queue_length(self : Container) -> Int {
  self.get_waiters.length()
}
