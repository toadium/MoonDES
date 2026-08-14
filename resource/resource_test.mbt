///|
test "exclusive resource grants and releases" {
  let res = @resource.new_exclusive(name="pump")
  assert_true(res.is_available())
  let log : Array[String] = []
  let granted = res.request(pid=1, callback=fn() { log.push("acquired") })
  assert_true(granted)
  assert_eq(res.in_use_count(), 1)
  assert_false(res.is_available())
  res.release()
  assert_eq(res.in_use_count(), 0)
  assert_true(res.is_available())
  assert_eq(log.length(), 1)
}

///|
test "capacity resource allows multiple holders" {
  let res = @resource.new_capacity(name="channel", capacity=3)
  let r1 = res.request(pid=1, callback=fn() { () })
  let r2 = res.request(pid=2, callback=fn() { () })
  let r3 = res.request(pid=3, callback=fn() { () })
  assert_true(r1)
  assert_true(r2)
  assert_true(r3)
  assert_eq(res.in_use_count(), 3)
  assert_false(res.is_available())
  res.release()
  assert_eq(res.in_use_count(), 2)
  assert_true(res.is_available())
}

///|
test "resource queues when full" {
  let res = @resource.new_exclusive(name="lock")
  let log : Array[String] = []
  ignore(res.request(pid=1, callback=fn() { log.push("first") }))
  // 资源已满，第二个请求排队
  let queued = res.request(pid=2, priority=0, callback=fn() {
    log.push("second")
  })
  assert_false(queued)
  assert_eq(res.queue_length(), 1)
  // 释放后自动唤醒等待进程
  res.release()
  assert_eq(res.queue_length(), 0)
  assert_eq(log.length(), 2)
  assert_eq(log[0], "first")
  assert_eq(log[1], "second")
}

///|
test "priority queue ordering" {
  let res = @resource.new_exclusive(name="priority_lock")
  let log : Array[String] = []
  ignore(res.request(pid=1, callback=fn() { log.push("holder") }))
  // 低优先级先排队
  ignore(res.request(pid=2, priority=5, callback=fn() { log.push("low") }))
  // 高优先级后排队但应先唤醒
  ignore(res.request(pid=3, priority=1, callback=fn() { log.push("high") }))
  res.release()
  // 高优先级应先被唤醒
  assert_eq(log.length(), 2)
  assert_eq(log[0], "holder")
  assert_eq(log[1], "high")
}
