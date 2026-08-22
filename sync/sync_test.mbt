///|
/// 信号事件基本操作：创建后未触发
test "signal event initial state" {
  let env = @core.new_env(until=10.0)
  let sig = new_signal(env)
  assert_false(sig.is_fired())
}

///|
/// 信号事件：fire 后触发回调
test "signal event fire triggers callback" {
  let env = @core.new_env(until=10.0)
  let sig = new_signal(env)
  let log : Array[String] = []
  sig.wait(fn() { log.push("fired") })
  assert_eq(log.length(), 0)
  sig.fire()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "fired")
  assert_true(sig.is_fired())
}

///|
/// 信号事件：fire 后 wait 立即执行
test "signal event wait after fire" {
  let env = @core.new_env(until=10.0)
  let sig = new_signal(env)
  sig.fire()
  let log : Array[String] = []
  sig.wait(fn() { log.push("late") })
  assert_eq(log.length(), 1)
}

///|
/// 信号事件：多次 fire 仅触发一次
test "signal event double fire" {
  let env = @core.new_env(until=10.0)
  let sig = new_signal(env)
  let mut n = 0
  sig.wait(fn() { n = n + 1 })
  sig.fire()
  sig.fire()
  assert_eq(n, 1)
}

///|
/// 信号事件：多个等待者
test "signal event multiple waiters" {
  let env = @core.new_env(until=10.0)
  let sig = new_signal(env)
  let log : Array[String] = []
  sig.wait(fn() { log.push("a") })
  sig.wait(fn() { log.push("b") })
  sig.wait(fn() { log.push("c") })
  sig.fire()
  assert_eq(log.length(), 3)
  assert_eq(log[0], "a")
  assert_eq(log[1], "b")
  assert_eq(log[2], "c")
}

///|
/// any_of：任意一个触发即触发结果
test "any_of fires on first signal" {
  let env = @core.new_env(until=10.0)
  let s1 = new_signal(env)
  let s2 = new_signal(env)
  let s3 = new_signal(env)
  let any = any_of(env, [s1, s2, s3])
  let log : Array[String] = []
  any.wait(fn() { log.push("any") })
  assert_false(any.is_fired())
  s2.fire()
  assert_true(any.is_fired())
  assert_eq(log.length(), 1)
}

///|
/// any_of：第一个触发
test "any_of fires on first position" {
  let env = @core.new_env(until=10.0)
  let s1 = new_signal(env)
  let s2 = new_signal(env)
  let any = any_of(env, [s1, s2])
  s1.fire()
  assert_true(any.is_fired())
}

///|
/// any_of：空数组不触发
test "any_of empty does not fire" {
  let env = @core.new_env(until=10.0)
  let any = any_of(env, [])
  assert_false(any.is_fired())
}

///|
/// all_of：全部触发才触发结果
test "all_of fires on all signals" {
  let env = @core.new_env(until=10.0)
  let s1 = new_signal(env)
  let s2 = new_signal(env)
  let s3 = new_signal(env)
  let all = all_of(env, [s1, s2, s3])
  let log : Array[String] = []
  all.wait(fn() { log.push("all") })
  s1.fire()
  assert_false(all.is_fired())
  s2.fire()
  assert_false(all.is_fired())
  s3.fire()
  assert_true(all.is_fired())
  assert_eq(log.length(), 1)
}

///|
/// all_of：单个信号
test "all_of single signal" {
  let env = @core.new_env(until=10.0)
  let s1 = new_signal(env)
  let all = all_of(env, [s1])
  assert_false(all.is_fired())
  s1.fire()
  assert_true(all.is_fired())
}

///|
/// all_of：空数组立即触发
test "all_of empty fires immediately" {
  let env = @core.new_env(until=10.0)
  let all = all_of(env, [])
  assert_true(all.is_fired())
}

///|
/// Semaphore：基本 acquire/release
test "semaphore basic acquire release" {
  let sem = new_semaphore(count=2)
  let log : Array[String] = []
  assert_eq(sem.available(), 2)
  sem.acquire(fn() { log.push("a") })
  assert_eq(sem.available(), 1)
  sem.acquire(fn() { log.push("b") })
  assert_eq(sem.available(), 0)
  assert_eq(log.length(), 2)
}

///|
/// Semaphore：许可耗尽后阻塞
test "semaphore blocks when exhausted" {
  let sem = new_semaphore(count=1)
  let log : Array[String] = []
  sem.acquire(fn() { log.push("first") })
  sem.acquire(fn() { log.push("second") }) // 阻塞
  assert_eq(log.length(), 1)
  assert_eq(sem.queue_length(), 1)
  sem.release()
  assert_eq(log.length(), 2)
  assert_eq(log[1], "second")
}

///|
/// Semaphore：release 无等待者时增加许可
test "semaphore release increments count" {
  let sem = new_semaphore(count=1)
  sem.acquire(fn() { () })
  assert_eq(sem.available(), 0)
  sem.release()
  assert_eq(sem.available(), 1)
}

///|
/// Semaphore：初始许可为 0
test "semaphore zero initial" {
  let sem = new_semaphore(count=0)
  let log : Array[String] = []
  sem.acquire(fn() { log.push("a") }) // 阻塞
  assert_eq(log.length(), 0)
  sem.release()
  assert_eq(log.length(), 1)
}

///|
/// Semaphore：多次 acquire/release 交替
test "semaphore alternating" {
  let sem = new_semaphore(count=2)
  let log : Array[String] = []
  sem.acquire(fn() { log.push("1") })
  sem.acquire(fn() { log.push("2") })
  sem.acquire(fn() { log.push("3") }) // 阻塞
  sem.acquire(fn() { log.push("4") }) // 阻塞
  assert_eq(log.length(), 2)
  sem.release()
  assert_eq(log.length(), 3)
  sem.release()
  assert_eq(log.length(), 4)
}

///|
/// Barrier：未到齐时阻塞
test "barrier blocks until full" {
  let bar = new_barrier(n=3)
  let log : Array[Int] = []
  bar.wait(fn() { log.push(1) })
  assert_eq(log.length(), 0)
  bar.wait(fn() { log.push(2) })
  assert_eq(log.length(), 0)
  bar.wait(fn() { log.push(3) })
  assert_eq(log.length(), 3)
}

///|
/// Barrier：n=1 立即通过
test "barrier n1 immediate" {
  let bar = new_barrier(n=1)
  let log : Array[String] = []
  bar.wait(fn() { log.push("pass") })
  assert_eq(log.length(), 1)
}

///|
/// Barrier：到齐后重置
test "barrier resets after release" {
  let bar = new_barrier(n=2)
  let log : Array[String] = []
  bar.wait(fn() { log.push("a") })
  bar.wait(fn() { log.push("b") })
  assert_true(bar.is_reset())
  // 第二轮
  bar.wait(fn() { log.push("c") })
  assert_eq(log.length(), 2)
  bar.wait(fn() { log.push("d") })
  assert_eq(log.length(), 4)
}

///|
/// Barrier：waiting_count 追踪
test "barrier waiting count" {
  let bar = new_barrier(n=3)
  assert_eq(bar.waiting_count(), 0)
  bar.wait(fn() { () })
  assert_eq(bar.waiting_count(), 1)
  bar.wait(fn() { () })
  assert_eq(bar.waiting_count(), 2)
  bar.wait(fn() { () })
  assert_eq(bar.waiting_count(), 0) // 释放后重置
}

///|
/// Container：基本 put/get
test "container basic put get" {
  let tank = new_container(capacity=100.0)
  tank.put(30.0, fn() { () })
  assert_eq(tank.level(), 30.0)
  tank.get(10.0, fn() { () })
  assert_eq(tank.level(), 20.0)
  assert_false(tank.is_full())
  assert_false(tank.is_empty())
}

///|
/// Container：满时阻塞 put
test "container blocks put when full" {
  let tank = new_container(capacity=50.0)
  let log : Array[String] = []
  tank.put(50.0, fn() { log.push("first") })
  assert_true(tank.is_full())
  tank.put(10.0, fn() { log.push("second") }) // 阻塞
  assert_eq(log.length(), 1)
  assert_eq(tank.put_queue_length(), 1)
  // 取出后唤醒等待的 put
  tank.get(10.0, fn() { () })
  assert_eq(log.length(), 2)
  assert_eq(log[1], "second")
}

///|
/// Container：空时阻塞 get
test "container blocks get when empty" {
  let tank = new_container(capacity=100.0)
  let log : Array[String] = []
  tank.get(10.0, fn() { log.push("got") }) // 阻塞
  assert_eq(log.length(), 0)
  assert_eq(tank.get_queue_length(), 1)
  // 注入后唤醒等待的 get
  tank.put(20.0, fn() { () })
  assert_eq(log.length(), 1)
  assert_eq(tank.level(), 10.0)
}

///|
/// Container：初始液位
test "container with initial level" {
  let tank = new_container_with(capacity=100.0, initial=40.0)
  assert_eq(tank.level(), 40.0)
  tank.get(40.0, fn() { () })
  assert_true(tank.is_empty())
}

///|
/// Container：put 后唤醒多个 get
test "container put wakes multiple get" {
  let tank = new_container(capacity=100.0)
  let log : Array[Int] = []
  tank.get(10.0, fn() { log.push(1) })
  tank.get(20.0, fn() { log.push(2) })
  assert_eq(log.length(), 0)
  tank.put(50.0, fn() { () })
  assert_eq(log.length(), 2)
  assert_eq(tank.level(), 20.0)
}

///|
/// Container：get 后唤醒 put
test "container get wakes put" {
  let tank = new_container_with(capacity=50.0, initial=50.0)
  let log : Array[String] = []
  tank.put(20.0, fn() { log.push("put") }) // 阻塞
  assert_eq(log.length(), 0)
  tank.get(20.0, fn() { () })
  assert_eq(log.length(), 1)
  assert_eq(tank.level(), 50.0)
}

///|
/// Container：is_empty / is_full
test "container empty and full" {
  let tank = new_container(capacity=100.0)
  assert_true(tank.is_empty())
  tank.put(100.0, fn() { () })
  assert_true(tank.is_full())
  assert_eq(tank.capacity(), 100.0)
}
