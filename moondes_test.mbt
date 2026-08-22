///|
test "root version returns correct string" {
  inspect(version(), content="1.5.0")
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
