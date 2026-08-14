///|
test "process creation and basic execution" {
  let env = @core.new_env(until=10.0)
  let log : Array[String] = []
  ignore(
    @process.process(env, name="worker", behavior=fn(_) {
      log.push("started at \{env.now()}")
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
    @process.process(env, name="timer", behavior=fn(p) {
      log.push("before timeout at \{env.now()}")
      p.timeout(env, 5.0)
      log.push("after timeout at \{env.now()}")
    }),
  )
  env.run()
  assert_eq(log.length(), 2)
  assert_eq(log[0], "before timeout at 0")
  assert_eq(log[1], "after timeout at 0")
}

///|
test "process terminate stops execution" {
  let env = @core.new_env(until=10.0)
  let p = @process.process(env, behavior=fn(proc) { proc.terminate() })
  env.run()
  assert_false(p.is_alive())
}
