///|
test "process creation and basic execution" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(
    @process.process(env, name="worker", behavior=fn(_) {
      log.push("started at \{env.now()}")
      @process.Done
    }),
  )
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "started at 0")
}

///|
test "process timeout suspends and resumes" {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  ignore(
    @process.process(env, name="timer", behavior=fn(_) {
      log.push("before timeout at \{env.now()}")
      @process.Timeout(duration=5.0, next=fn() {
        log.push("after timeout at \{env.now()}")
        @process.Done
      })
    }),
  )
  env.run()
  assert_eq(log.length(), 2)
  assert_eq(log[0], "before timeout at 0")
  assert_eq(log[1], "after timeout at 5")
}

///|
test "process multiple timeouts chain" {
  let env = @core.new_env(until=30.0)
  let log : Array[String] = []
  ignore(
    @process.process(env, behavior=fn(_) {
      log.push("step 1 at \{env.now()}")
      @process.Timeout(duration=3.0, next=fn() {
        log.push("step 2 at \{env.now()}")
        @process.Timeout(duration=7.0, next=fn() {
          log.push("step 3 at \{env.now()}")
          @process.Done
        })
      })
    }),
  )
  env.run()
  assert_eq(log.length(), 3)
  assert_eq(log[0], "step 1 at 0")
  assert_eq(log[1], "step 2 at 3")
  assert_eq(log[2], "step 3 at 10")
}

///|
test "process terminate stops execution" {
  let env = @core.new_env(until=10.0)
  let p = @process.process(env, behavior=fn(_) { @process.Terminate })
  env.run()
  assert_false(p.is_alive())
}

///|
test "process wait_event resumes on trigger" {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  // 先调度一个事件在 time=5 触发
  let ev = env.schedule(time=5.0, callback=fn() {
    log.push("event at \{env.now()}")
  })
  ignore(
    @process.process(env, behavior=fn(_) {
      log.push("before wait at \{env.now()}")
      @process.WaitEvent(event=ev, next=fn() {
        log.push("after wait at \{env.now()}")
        @process.Done
      })
    }),
  )
  env.run()
  assert_eq(log.length(), 3)
  assert_eq(log[0], "before wait at 0")
  assert_eq(log[1], "event at 5")
  assert_eq(log[2], "after wait at 5")
}

///|
test "process done completes immediately" {
  let env = @core.new_env(until=10.0)
  let p = @process.process(env, behavior=fn(_) { @process.Done })
  env.run()
  assert_false(p.is_alive())
}
