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

///|
test "preemptive resource preempts lower priority" {
  let res = @resource.new_preemptive(name="channel")
  let log : Array[String] = []
  // 低优先级进程先获取资源
  let granted = res.request(
    pid=1,
    priority=5,
    callback=fn() { log.push("low acquired") },
    on_preempt=fn() { log.push("low preempted") },
  )
  assert_true(granted)
  assert_eq(log[0], "low acquired")
  // 高优先级进程抢占
  let preempted = res.request(
    pid=2,
    priority=1,
    callback=fn() { log.push("high acquired") },
    on_preempt=fn() { log.push("high preempted") },
  )
  assert_true(preempted)
  assert_eq(log[1], "low preempted")
  assert_eq(log[2], "high acquired")
  assert_eq(res.in_use_count(), 1)
  // 高优先级释放，低优先级重新获取
  res.release()
  assert_eq(log[3], "low acquired")
  assert_eq(res.in_use_count(), 1)
}

///|
test "preemptive resource queues when lower priority" {
  let res = @resource.new_preemptive(name="channel")
  let log : Array[String] = []
  // 高优先级先获取
  ignore(
    res.request(pid=1, priority=1, callback=fn() { log.push("high acquired") }),
  )
  // 低优先级请求，不能抢占，排队
  let queued = res.request(pid=2, priority=5, callback=fn() {
    log.push("low acquired")
  })
  assert_false(queued)
  assert_eq(res.queue_length(), 1)
  // 高优先级释放，低优先级获取
  res.release()
  assert_eq(log[1], "low acquired")
}

///|
test "preemptive resource non-preemptive when equal priority" {
  let res = @resource.new_preemptive(name="channel")
  let log : Array[String] = []
  // 优先级 1 持有
  ignore(res.request(pid=1, priority=1, callback=fn() { log.push("first") }))
  // 同优先级请求，排队而非抢占
  let queued = res.request(pid=2, priority=1, callback=fn() {
    log.push("second")
  })
  assert_false(queued)
  assert_eq(res.queue_length(), 1)
}
