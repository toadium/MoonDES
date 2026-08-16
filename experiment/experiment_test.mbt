///|
test "run_experiment executes simulation" {
  let cfg = @experiment.new_config(until=10.0, seed=42)
  let result = @experiment.run_experiment(cfg)
  inspect(result.final_time, content="10")
  inspect(result.event_count, content="0")
}

///|
test "run_experiment counts events" {
  let cfg = @experiment.new_config(until=10.0)
  let result = @experiment.run_experiment(cfg)
  // 无额外事件调度，event_count 为 0
  inspect(result.event_count, content="0")
}

///|
test "batch_run executes multiple configs" {
  let cfgs = [
    @experiment.new_config(until=5.0),
    @experiment.new_config(until=10.0),
    @experiment.new_config(until=15.0),
  ]
  let results = @experiment.batch_run(cfgs)
  assert_eq(results.length(), 3)
  inspect(results[0].final_time, content="5")
  inspect(results[1].final_time, content="10")
  inspect(results[2].final_time, content="15")
}

///|
test "snapshot captures env state" {
  let env = @core.new_env(until=10.0)
  ignore(env.schedule(time=3.0, callback=fn() { () }))
  let snap_before = @experiment.snapshot(env)
  inspect(snap_before.time, content="0")
  inspect(snap_before.event_count, content="1")
  env.run()
  let snap = @experiment.snapshot(env)
  inspect(snap.time, content="10")
  inspect(snap.event_count, content="1")
}

///|
test "rollback restores env state" {
  let env = @core.new_env(until=20.0)
  // 调度一个事件在 time=5 触发
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  // 运行到 time=5
  ignore(env.step())
  inspect(env.now(), content="5")
  // 保存快照
  let snap = @experiment.snapshot(env)
  // 继续运行到结束
  env.run()
  inspect(env.now(), content="20")
  // 回滚到快照
  @experiment.rollback(env, snap)
  inspect(env.now(), content="5")
}

///|
test "param_sweep generates configs" {
  let base = @experiment.new_config(until=100.0)
  let configs = @experiment.param_sweep(base~, param_name="load", values=[
    0.5, 1.0, 1.5,
  ])
  assert_eq(configs.length(), 3)
  inspect(configs[0].params["load"], content="0.5")
  inspect(configs[1].params["load"], content="1")
  inspect(configs[2].params["load"], content="1.5")
}

///|
test "ExpConfig serialization roundtrip" {
  let cfg = @experiment.new_config(until=100.0, seed=42)
  cfg.set_param("load", value=0.8)
  cfg.set_param("arrival_rate", value=10.0)
  let json_str = cfg.to_json_string()
  let cfg2 = @experiment.ExpConfig::from_json_string(json_str)
  inspect(cfg2.until, content="100")
  inspect(cfg2.seed, content="42")
  inspect(cfg2.params["load"], content="0.8")
  inspect(cfg2.params["arrival_rate"], content="10")
}

///|
test "ExpResult serialization roundtrip" {
  let cfg = @experiment.new_config(until=50.0, seed=7)
  let result = @experiment.run_experiment(cfg)
  let json_str = result.to_json_string()
  let result2 = @experiment.ExpResult::from_json_string(json_str)
  inspect(result2.final_time, content="50")
  inspect(result2.event_count, content="0")
  inspect(result2.config.until, content="50")
  inspect(result2.config.seed, content="7")
}

///|
test "Snapshot serialization roundtrip" {
  let env = @core.new_env(until=20.0)
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  let snap = @experiment.snapshot(env)
  let json_str = snap.to_json_string()
  let snap2 = @experiment.Snapshot::from_json_string(json_str)
  inspect(snap2.time, content="0")
  inspect(snap2.event_count, content="1")
  inspect(snap2.env_snapshot.now, content="0")
}

///|
test "EnvStatus serialization" {
  let env = @core.new_env(until=10.0)
  let snap = @experiment.snapshot(env)
  let json_str = snap.to_json_string()
  // JSON 字符串应包含 "Initialized"
  assert_true(json_str.contains("Initialized"))
  env.run()
  let snap2 = @experiment.snapshot(env)
  let json_str2 = snap2.to_json_string()
  assert_true(json_str2.contains("Finished"))
}
