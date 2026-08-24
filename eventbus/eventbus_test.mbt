// ===========================================================================
// EventBus — 事件总线测试
// ===========================================================================

///|
/// EventBus：基本发布订阅
test "eventbus basic pubsub" {
  let bus = new_event_bus()
  let log : Array[String] = []
  let id = bus.subscribe("sensor", fn(data) { log.push(data) })
  assert_true(id > 0)
  let count = bus.publish("sensor", "temperature=25")
  assert_eq(count, 1)
  assert_eq(log.length(), 1)
  assert_eq(log[0], "temperature=25")
}

///|
/// EventBus：多订阅者
test "eventbus multiple subscribers" {
  let bus = new_event_bus()
  let log1 : Array[String] = []
  let log2 : Array[String] = []
  ignore(bus.subscribe("event", fn(data) { log1.push(data) }))
  ignore(bus.subscribe("event", fn(data) { log2.push("got:\{data}") }))
  let count = bus.publish("event", "hello")
  assert_eq(count, 2)
  assert_eq(log1[0], "hello")
  assert_eq(log2[0], "got:hello")
  assert_eq(bus.subscriber_count("event"), 2)
}

///|
/// EventBus：取消订阅
test "eventbus unsubscribe" {
  let bus = new_event_bus()
  let log : Array[String] = []
  let id = bus.subscribe("topic", fn(data) { log.push(data) })
  assert_eq(bus.subscriber_count("topic"), 1)
  let ok = bus.unsubscribe("topic", id)
  assert_true(ok)
  assert_eq(bus.subscriber_count("topic"), 0)
  let count = bus.publish("topic", "test")
  assert_eq(count, 0)
  assert_eq(log.length(), 0)
}

///|
/// EventBus：取消订阅不存在的 ID
test "eventbus unsubscribe nonexistent" {
  let bus = new_event_bus()
  let ok = bus.unsubscribe("topic", 999)
  assert_false(ok)
}

///|
/// EventBus：无订阅者发布
test "eventbus publish no subscribers" {
  let bus = new_event_bus()
  let count = bus.publish("unknown", "data")
  assert_eq(count, 0)
}

///|
/// EventBus：多 topic 隔离
test "eventbus multiple topics" {
  let bus = new_event_bus()
  let log_a : Array[String] = []
  let log_b : Array[String] = []
  ignore(bus.subscribe("topicA", fn(data) { log_a.push(data) }))
  ignore(bus.subscribe("topicB", fn(data) { log_b.push(data) }))
  ignore(bus.publish("topicA", "forA"))
  ignore(bus.publish("topicB", "forB"))
  assert_eq(log_a[0], "forA")
  assert_eq(log_b[0], "forB")
  assert_eq(log_a.length(), 1)
  assert_eq(log_b.length(), 1)
}

///|
/// EventBus：clear 清空主题
test "eventbus clear topic" {
  let bus = new_event_bus()
  let log : Array[String] = []
  ignore(bus.subscribe("topic", fn(data) { log.push(data) }))
  ignore(bus.subscribe("topic", fn(data) { log.push(data) }))
  assert_eq(bus.subscriber_count("topic"), 2)
  bus.clear("topic")
  assert_eq(bus.subscriber_count("topic"), 0)
  let count = bus.publish("topic", "test")
  assert_eq(count, 0)
}

///|
/// EventBus：订阅 ID 唯一性
test "eventbus unique ids" {
  let bus = new_event_bus()
  let id1 = bus.subscribe("topic", fn(_data) { () })
  let id2 = bus.subscribe("topic", fn(_data) { () })
  let id3 = bus.subscribe("other", fn(_data) { () })
  assert_true(id1 != id2)
  assert_true(id2 != id3)
  assert_true(id1 != id3)
}

///|
/// EventBus：topics 列表
test "eventbus topics" {
  let bus = new_event_bus()
  ignore(bus.subscribe("alpha", fn(_data) { () }))
  ignore(bus.subscribe("beta", fn(_data) { () }))
  ignore(bus.subscribe("gamma", fn(_data) { () }))
  let ts = bus.topics()
  assert_eq(ts.length(), 3)
  assert_true(ts.contains("alpha"))
  assert_true(ts.contains("beta"))
  assert_true(ts.contains("gamma"))
}

///|
/// EventBus：total_subscribers
test "eventbus total_subscribers" {
  let bus = new_event_bus()
  ignore(bus.subscribe("a", fn(_data) { () }))
  ignore(bus.subscribe("a", fn(_data) { () }))
  ignore(bus.subscribe("b", fn(_data) { () }))
  assert_eq(bus.total_subscribers(), 3)
}

///|
/// EventBus：选择性取消订阅
test "eventbus selective unsubscribe" {
  let bus = new_event_bus()
  let log : Array[String] = []
  let id1 = bus.subscribe("topic", fn(data) { log.push("first:\{data}") })
  ignore(bus.subscribe("topic", fn(data) { log.push("second:\{data}") }))
  // 取消第一个
  ignore(bus.unsubscribe("topic", id1))
  assert_eq(bus.subscriber_count("topic"), 1)
  ignore(bus.publish("topic", "msg"))
  assert_eq(log.length(), 1)
  assert_eq(log[0], "second:msg")
}

///|
/// EventBus：多次发布
test "eventbus multiple publishes" {
  let bus = new_event_bus()
  let log : Array[String] = []
  ignore(bus.subscribe("topic", fn(data) { log.push(data) }))
  for i in 0..<5 {
    ignore(bus.publish("topic", "msg\{i}"))
  }
  assert_eq(log.length(), 5)
  assert_eq(log[0], "msg0")
  assert_eq(log[4], "msg4")
}
