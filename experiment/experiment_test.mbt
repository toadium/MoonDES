///|
test "run_experiment executes simulation" {
  let cfg = @experiment.new_config(until=10.0, seed=42)
  let result = @experiment.run_experiment(cfg)
  inspect(result.final_time, content="10")
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
  env.run()
  let snap = @experiment.snapshot(env)
  inspect(snap.time, content="10")
}

///|
test "param_sweep generates configs" {
  let base = @experiment.new_config(until=100.0)
  let configs = @experiment.param_sweep(base~, param_name="load", values=[
    0.5, 1.0, 1.5,
  ])
  assert_eq(configs.length(), 3)
}
