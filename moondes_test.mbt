///|
test "root version returns correct string" {
  inspect(version(), content="1.1.0")
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
