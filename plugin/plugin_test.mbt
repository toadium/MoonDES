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
