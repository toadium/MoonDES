///|
test "plugin manager register and notify" {
  let mgr = @plugin.new_manager()
  let mut step_count = 0
  let mut finished = false
  let cb : @plugin.PluginCallbacks = {
    on_step: fn(_env, _time) { step_count = step_count + 1 },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { finished = true },
  }
  mgr.register(cb)
  assert_eq(mgr.length(), 1)
  let env = @core.new_env(until=10.0)
  mgr.notify_step(env, 1.0)
  assert_eq(step_count, 1)
  mgr.notify_finish(env)
  assert_true(finished)
}

///|
test "attach plugin to env" {
  let env = @core.new_env(until=5.0)
  let mgr = @plugin.new_manager()
  let mut finished = false
  let cb : @plugin.PluginCallbacks = {
    on_step: fn(_env, _time) { () },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { finished = true },
  }
  mgr.register(cb)
  @plugin.attach(env, mgr)
  env.run()
  assert_true(finished)
}

///|
test "null callbacks do nothing" {
  let cb = @plugin.null_callbacks()
  let env = @core.new_env(until=1.0)
  (cb.on_step)(env, 0.0)
  (cb.on_finish)(env)
}

///|
test "plugin on_step called by engine" {
  let env = @core.new_env(until=10.0)
  let mgr = @plugin.new_manager()
  let step_times : Array[Double] = []
  let cb : @plugin.PluginCallbacks = {
    on_step: fn(_env, time) { step_times.push(time) },
    on_event: fn(_env, _event) { () },
    on_finish: fn(_env) { () },
  }
  mgr.register(cb)
  @plugin.attach(env, mgr)
  ignore(env.schedule(time=3.0, callback=fn() { () }))
  ignore(env.schedule(time=7.0, callback=fn() { () }))
  env.run()
  // on_step 应在 time=3 和 time=7 被调用
  assert_eq(step_times.length(), 2)
  inspect(step_times[0], content="3")
  inspect(step_times[1], content="7")
}

///|
test "plugin on_event called by engine" {
  let env = @core.new_env(until=10.0)
  let mgr = @plugin.new_manager()
  let event_count : Array[Int] = [0]
  let cb : @plugin.PluginCallbacks = {
    on_step: fn(_env, _time) { () },
    on_event: fn(_env, _event) { event_count[0] = event_count[0] + 1 },
    on_finish: fn(_env) { () },
  }
  mgr.register(cb)
  @plugin.attach(env, mgr)
  ignore(env.schedule(time=3.0, callback=fn() { () }))
  ignore(env.schedule(time=7.0, callback=fn() { () }))
  env.run()
  assert_eq(event_count[0], 2)
}

///|
test "plugin lifecycle order" {
  let env = @core.new_env(until=10.0)
  let mgr = @plugin.new_manager()
  let log : Array[String] = []
  let cb : @plugin.PluginCallbacks = {
    on_step: fn(_env, time) { log.push("step at \{time}") },
    on_event: fn(_env, _event) { log.push("event") },
    on_finish: fn(_env) { log.push("finish") },
  }
  mgr.register(cb)
  @plugin.attach(env, mgr)
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  env.run()
  // 顺序：step at 5, event, finish
  assert_eq(log.length(), 3)
  assert_eq(log[0], "step at 5")
  assert_eq(log[1], "event")
  assert_eq(log[2], "finish")
}
