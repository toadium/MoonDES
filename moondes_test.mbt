///|
test "root version returns correct string" {
  inspect(version(), content="2.4.0")
}

///|
test "root new_env convenience" {
  let env = new_env(until=10.0)
  inspect(env.now(), content="0")
  inspect(env.until, content="10")
}

///|
test "root new_config convenience" {
  let cfg = new_config(until=50.0, seed=42)
  inspect(cfg.until, content="50")
  inspect(cfg.seed, content="42")
}

///|
test "root new_exclusive convenience" {
  let res = new_exclusive(name="root_resource")
  inspect(res.is_available(), content="true")
}

///|
test "root new_plugin_manager convenience" {
  let mgr = new_plugin_manager()
  inspect(mgr.length(), content="0")
}

///|
test "root process convenience" {
  let env = new_env(until=10.0)
  let log : Array[String] = []
  ignore(
    process(env, name="root_proc", behavior=fn(_) {
      log.push("executed")
      @process.Done
    }),
  )
  env.run()
  assert_eq(log.length(), 1)
  assert_eq(log[0], "executed")
}

///|
test "root new_multi_env convenience" {
  let mgr = new_multi_env()
  inspect(mgr.count(), content="0")
}

///|
test "root new_task_scheduler convenience" {
  let sched = new_task_scheduler()
  inspect(sched.pending_count(), content="0")
}

///|
test "root new_aggregator convenience" {
  let agg = new_aggregator()
  inspect(agg.count(), content="0")
}

///|
test "root new_signal convenience" {
  let env = new_env(until=10.0)
  let sig = new_signal(env)
  inspect(sig.is_fired(), content="false")
  sig.fire()
  inspect(sig.is_fired(), content="true")
}

///|
test "root new_semaphore convenience" {
  let sem = new_semaphore(count=3)
  inspect(sem.available(), content="3")
}

///|
test "root new_barrier convenience" {
  let bar = new_barrier(n=2)
  inspect(bar.waiting_count(), content="0")
}

///|
test "root new_container convenience" {
  let tank = new_container(capacity=100.0)
  inspect(tank.level(), content="0")
  inspect(tank.capacity(), content="100")
}

///|
test "root any_of convenience" {
  let env = new_env(until=10.0)
  let s1 = new_signal(env)
  let s2 = new_signal(env)
  let any = any_of(env, [s1, s2])
  inspect(any.is_fired(), content="false")
  s1.fire()
  inspect(any.is_fired(), content="true")
}

///|
test "root all_of convenience" {
  let env = new_env(until=10.0)
  let s1 = new_signal(env)
  let s2 = new_signal(env)
  let all = all_of(env, [s1, s2])
  s1.fire()
  inspect(all.is_fired(), content="false")
  s2.fire()
  inspect(all.is_fired(), content="true")
}

///|
test "root new_timeline convenience" {
  let tl = new_timeline()
  inspect(tl.length(), content="0")
}

///|
test "root new_resource_tracker convenience" {
  let tracker = new_resource_tracker()
  inspect(tracker.entry_count(), content="0")
}

///|
test "root new_report convenience" {
  let env = new_env(until=10.0)
  env.run()
  let report = new_report()
  let text = report.generate_text(env)
  assert_true(text.length() > 0)
}

///|
test "root new_store convenience" {
  let store : @sync.Store[Int] = new_store()
  store.put(42)
  inspect(store.size(), content="1")
}

///|
test "root new_priority_store convenience" {
  let store : @sync.PriorityStore[String] = new_priority_store()
  store.put("hi", priority=1)
  inspect(store.size(), content="1")
}

///|
test "root new_link convenience" {
  let env = @core.new_env(until=10.0)
  let link = new_link(env, name="test", delay=1.0)
  inspect(link.name(), content="test")
}

///|
test "root new_router convenience" {
  let r = new_router(name="R1")
  inspect(r.name(), content="R1")
}

///|
test "root new_filter_store convenience" {
  let store : @sync.FilterStore[Int] = new_filter_store()
  store.put(42)
  let log : Array[Int] = []
  store.get(fn(_x) { true }, fn(item) { log.push(item) })
  assert_eq(log[0], 42)
}

///|
test "root new_state_machine convenience" {
  let sm = new_state_machine(initial="A", transitions=[
    @fsm.transition(from="A", to="B", on="go"),
  ])
  inspect(sm.current(), content="A")
  let ok = sm.fire("go")
  assert_true(ok)
  inspect(sm.current(), content="B")
}

///|
test "root new_event_bus convenience" {
  let bus = new_event_bus()
  let log : Array[String] = []
  let id = bus.subscribe("test", fn(data) { log.push(data) })
  assert_true(id > 0)
  let count = bus.publish("test", "hello")
  assert_eq(count, 1)
  assert_eq(log[0], "hello")
}
