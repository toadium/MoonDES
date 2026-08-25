// ===========================================================================
// ConditionVariable — 条件变量测试
// ===========================================================================

///|
/// ConditionVariable：基本 wait + notify_one
test "cv basic wait notify_one" {
  let cv = new_condition_variable()
  let log : Array[String] = []
  cv.wait(fn() { log.push("woken") })
  assert_eq(cv.waiter_count(), 1)
  let ok = cv.notify_one()
  assert_true(ok)
  assert_eq(cv.waiter_count(), 0)
  assert_eq(log[0], "woken")
}

///|
/// ConditionVariable：notify_all 唤醒全部
test "cv notify_all" {
  let cv = new_condition_variable()
  let log : Array[Int] = []
  cv.wait(fn() { log.push(1) })
  cv.wait(fn() { log.push(2) })
  cv.wait(fn() { log.push(3) })
  assert_eq(cv.waiter_count(), 3)
  let count = cv.notify_all()
  assert_eq(count, 3)
  assert_eq(cv.waiter_count(), 0)
  assert_eq(log.length(), 3)
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(log[2], 3)
}

///|
/// ConditionVariable：无等待者时通知
test "cv notify no waiters" {
  let cv = new_condition_variable()
  let ok = cv.notify_one()
  assert_false(ok)
  let count = cv.notify_all()
  assert_eq(count, 0)
}

///|
/// ConditionVariable：多等待者 FIFO 唤醒
test "cv fifo order" {
  let cv = new_condition_variable()
  let log : Array[String] = []
  cv.wait(fn() { log.push("first") })
  cv.wait(fn() { log.push("second") })
  cv.wait(fn() { log.push("third") })
  ignore(cv.notify_one())
  assert_eq(log[0], "first")
  assert_eq(log.length(), 1)
  ignore(cv.notify_one())
  assert_eq(log[1], "second")
  assert_eq(log.length(), 2)
  ignore(cv.notify_one())
  assert_eq(log[2], "third")
  assert_eq(log.length(), 3)
}

///|
/// ConditionVariable：waiter_count 和 has_waiters
test "cv waiter_count" {
  let cv = new_condition_variable()
  assert_false(cv.has_waiters())
  assert_eq(cv.waiter_count(), 0)
  cv.wait(fn() { () })
  assert_true(cv.has_waiters())
  assert_eq(cv.waiter_count(), 1)
  cv.wait(fn() { () })
  assert_eq(cv.waiter_count(), 2)
  ignore(cv.notify_one())
  assert_eq(cv.waiter_count(), 1)
  ignore(cv.notify_all())
  assert_eq(cv.waiter_count(), 0)
  assert_false(cv.has_waiters())
}

///|
/// ConditionVariable：clear 清空
test "cv clear" {
  let cv = new_condition_variable()
  cv.wait(fn() { () })
  cv.wait(fn() { () })
  assert_eq(cv.waiter_count(), 2)
  let cleared = cv.clear()
  assert_eq(cleared, 2)
  assert_eq(cv.waiter_count(), 0)
}

///|
/// ConditionVariable：notify_one 后再 wait
test "cv notify then wait" {
  let cv = new_condition_variable()
  let log : Array[String] = []
  cv.wait(fn() { log.push("a") })
  ignore(cv.notify_one())
  cv.wait(fn() { log.push("b") })
  ignore(cv.notify_one())
  assert_eq(log[0], "a")
  assert_eq(log[1], "b")
}

///|
/// ConditionVariable：交替 wait 和 notify
test "cv interleaved" {
  let cv = new_condition_variable()
  let log : Array[Int] = []
  cv.wait(fn() { log.push(1) })
  ignore(cv.notify_one())
  cv.wait(fn() { log.push(2) })
  cv.wait(fn() { log.push(3) })
  ignore(cv.notify_one())
  assert_eq(log.length(), 2)
  assert_eq(log[0], 1)
  assert_eq(log[1], 2)
  assert_eq(cv.waiter_count(), 1)
}
