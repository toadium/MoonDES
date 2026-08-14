///|
test "new_env creates environment with correct initial state" {
  let env = @core.new_env(until=100.0)
  inspect(env.now(), content="0")
  inspect(env.until, content="100")
  inspect(env.is_finished(), content="false")
}

///|
test "timeout creates event at correct time" {
  let env = @core.new_env(until=10.0)
  let ev = env.timeout(5.0)
  inspect(ev.time, content="5")
  inspect(ev.is_pending(), content="true")
}

///|
test "schedule orders events by time" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(env.schedule(time=3.0, callback=fn() { log.push("late") }))
  ignore(env.schedule(time=1.0, callback=fn() { log.push("early") }))
  ignore(env.schedule(time=2.0, callback=fn() { log.push("mid") }))
  env.run()
  assert_eq(log.length(), 3)
  assert_eq(log[0], "early")
  assert_eq(log[1], "mid")
  assert_eq(log[2], "late")
}

///|
test "schedule orders by priority when time is equal" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(env.schedule(time=1.0, priority=2, callback=fn() { log.push("low") }))
  ignore(env.schedule(time=1.0, priority=0, callback=fn() { log.push("high") }))
  ignore(env.schedule(time=1.0, priority=1, callback=fn() { log.push("mid") }))
  env.run()
  assert_eq(log.length(), 3)
  assert_eq(log[0], "high")
  assert_eq(log[1], "mid")
  assert_eq(log[2], "low")
}

///|
test "run stops at until time" {
  let env = @core.new_env(until=5.0)
  let log : Array[String] = []
  ignore(env.schedule(time=10.0, callback=fn() { log.push("beyond") }))
  ignore(env.schedule(time=3.0, callback=fn() { log.push("within") }))
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "within")
  inspect(env.now(), content="5")
}

///|
test "event cancel prevents callback execution" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  let ev = env.schedule(time=2.0, callback=fn() { log.push("executed") })
  ev.cancel()
  ignore(env.schedule(time=1.0, callback=fn() { log.push("first") }))
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "first")
}

///|
test "step processes one event at a time" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(env.schedule(time=1.0, callback=fn() { log.push("A") }))
  ignore(env.schedule(time=2.0, callback=fn() { log.push("B") }))
  let s1 = env.step()
  assert_true(s1)
  assert_eq(log.length(), 1)
  assert_eq(log[0], "A")
  let s2 = env.step()
  assert_true(s2)
  assert_eq(log.length(), 2)
  assert_eq(log[1], "B")
  let s3 = env.step()
  assert_false(s3)
}

///|
test "event queue maintains heap property" {
  let q = @core.new_queue()
  assert_true(q.is_empty())
  let e1 = @core.new_event(id=1, time=5.0, callback=fn() { () })
  let e2 = @core.new_event(id=2, time=1.0, callback=fn() { () })
  let e3 = @core.new_event(id=3, time=3.0, callback=fn() { () })
  q.push(e1)
  q.push(e2)
  q.push(e3)
  assert_eq(q.length(), 3)
  // 弹出顺序应为 time=1, 3, 5
  match q.pop() {
    Some(e) => inspect(e.time, content="1")
    None => fail("expected event")
  }
  match q.pop() {
    Some(e) => inspect(e.time, content="3")
    None => fail("expected event")
  }
  match q.pop() {
    Some(e) => inspect(e.time, content="5")
    None => fail("expected event")
  }
  assert_true(q.is_empty())
}

///|
test "event add_callback appends multiple callbacks" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  let ev = env.schedule(time=1.0, callback=fn() { log.push("first") })
  ev.add_callback(fn() { log.push("second") })
  env.run()
  assert_eq(log.length(), 2)
  assert_eq(log[0], "first")
  assert_eq(log[1], "second")
}
