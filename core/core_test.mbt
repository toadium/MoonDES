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

///|
test "remove_canceled on empty queue" {
  let q = @core.new_queue()
  q.remove_canceled()
  assert_true(q.is_empty())
}

///|
test "remove_canceled on single element" {
  let q = @core.new_queue()
  let e = @core.new_event(id=0, time=1.0, callback=fn() { () })
  q.push(e)
  q.remove_canceled()
  assert_eq(q.length(), 1)
}

///|
test "remove_canceled removes all canceled" {
  let q = @core.new_queue()
  let e1 = @core.new_event(id=0, time=1.0, callback=fn() { () })
  let e2 = @core.new_event(id=1, time=2.0, callback=fn() { () })
  let e3 = @core.new_event(id=2, time=3.0, callback=fn() { () })
  e1.cancel()
  e3.cancel()
  q.push(e1)
  q.push(e2)
  q.push(e3)
  q.remove_canceled()
  assert_eq(q.length(), 1)
  match q.pop() {
    Some(e) => inspect(e.time, content="2")
    None => fail("expected event")
  }
}

///|
test "remove_canceled preserves heap property" {
  let q = @core.new_queue()
  let e1 = @core.new_event(id=0, time=5.0, callback=fn() { () })
  let e2 = @core.new_event(id=1, time=1.0, callback=fn() { () })
  let e3 = @core.new_event(id=2, time=3.0, callback=fn() { () })
  let e4 = @core.new_event(id=3, time=7.0, callback=fn() { () })
  let e5 = @core.new_event(id=4, time=2.0, callback=fn() { () })
  e2.cancel()
  q.push(e1)
  q.push(e2)
  q.push(e3)
  q.push(e4)
  q.push(e5)
  q.remove_canceled()
  assert_eq(q.length(), 4)
  // 弹出顺序应为 time=2, 3, 5, 7
  match q.pop() {
    Some(e) => inspect(e.time, content="2")
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
  match q.pop() {
    Some(e) => inspect(e.time, content="7")
    None => fail("expected event")
  }
}

///|
test "empty env with until=0" {
  let env = @core.new_env(until=0.0)
  env.run()
  inspect(env.now(), content="0")
  inspect(env.is_finished(), content="true")
}

///|
test "zero duration event" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(env.schedule(time=0.0, callback=fn() { log.push("immediate") }))
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "immediate")
}

///|
test "negative priority orders first" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(
    env.schedule(time=1.0, priority=0, callback=fn() { log.push("normal") }),
  )
  ignore(
    env.schedule(time=1.0, priority=-1, callback=fn() { log.push("urgent") }),
  )
  ignore(env.schedule(time=1.0, priority=1, callback=fn() { log.push("low") }))
  env.run()
  assert_eq(log[0], "urgent")
  assert_eq(log[1], "normal")
  assert_eq(log[2], "low")
}

///|
test "multiple env instances run independently" {
  let env1 = @core.new_env(until=5.0)
  let env2 = @core.new_env(until=10.0)
  let log1 : Array[String] = []
  let log2 : Array[String] = []
  ignore(env1.schedule(time=3.0, callback=fn() { log1.push("env1@3") }))
  ignore(env2.schedule(time=7.0, callback=fn() { log2.push("env2@7") }))
  env1.run()
  env2.run()
  assert_eq(log1.length(), 1)
  assert_eq(log2.length(), 1)
  inspect(env1.now(), content="5")
  inspect(env2.now(), content="10")
}

///|
test "1000 events stress test" {
  let env = @core.new_env(until=1000.0)
  let mut count = 0
  for i in 0..<1000 {
    ignore(
      env.schedule(time=i.to_double(), callback=fn() { count = count + 1 }),
    )
  }
  env.run()
  assert_eq(count, 1000)
  inspect(env.now(), content="1000")
}

///|
test "snapshot and restore roundtrip" {
  let env = @core.new_env(until=20.0)
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  ignore(env.step())
  inspect(env.now(), content="5")
  let snap = env.snapshot()
  env.run()
  inspect(env.now(), content="20")
  env.restore(snap)
  inspect(env.now(), content="5")
}
