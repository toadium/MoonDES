///|
test "multi_env basic creation" {
  let mgr = @distributed.new_multi_env()
  inspect(mgr.count(), content="0")
  ignore(mgr.create_env(until=10.0))
  ignore(mgr.create_env(until=20.0))
  inspect(mgr.count(), content="2")
}

///|
test "multi_env add existing env" {
  let mgr = @distributed.new_multi_env()
  let env = @core.new_env(until=5.0)
  mgr.add_env(env)
  inspect(mgr.count(), content="1")
}

///|
test "multi_env run_all" {
  let mgr = @distributed.new_multi_env()
  let env1 = mgr.create_env(until=10.0)
  let env2 = mgr.create_env(until=20.0)
  ignore(env1.schedule(time=5.0, callback=fn() { () }))
  ignore(env2.schedule(time=15.0, callback=fn() { () }))
  mgr.run_all()
  assert_true(mgr.all_finished())
  let times = mgr.collect_times()
  inspect(times[0], content="10")
  inspect(times[1], content="20")
}

///|
test "multi_env collect event counts" {
  let mgr = @distributed.new_multi_env()
  let env1 = mgr.create_env(until=10.0)
  let env2 = mgr.create_env(until=10.0)
  ignore(env1.schedule(time=1.0, callback=fn() { () }))
  ignore(env1.schedule(time=2.0, callback=fn() { () }))
  ignore(env2.schedule(time=3.0, callback=fn() { () }))
  mgr.run_all()
  let counts = mgr.collect_event_counts()
  inspect(counts[0], content="2")
  inspect(counts[1], content="1")
}

///|
test "multi_env get_env by index" {
  let mgr = @distributed.new_multi_env()
  ignore(mgr.create_env(until=10.0))
  ignore(mgr.create_env(until=20.0))
  match mgr.get_env(0) {
    Some(env) => inspect(env.until, content="10")
    None => fail("expected env")
  }
  match mgr.get_env(1) {
    Some(env) => inspect(env.until, content="20")
    None => fail("expected env")
  }
  match mgr.get_env(2) {
    Some(_) => fail("expected None")
    None => ()
  }
}

///|
test "multi_env independent execution" {
  let mgr = @distributed.new_multi_env()
  let log1 : Array[String] = []
  let log2 : Array[String] = []
  let env1 = mgr.create_env(until=10.0)
  let env2 = mgr.create_env(until=20.0)
  ignore(env1.schedule(time=3.0, callback=fn() { log1.push("env1") }))
  ignore(env2.schedule(time=7.0, callback=fn() { log2.push("env2") }))
  mgr.run_all()
  assert_eq(log1.length(), 1)
  assert_eq(log2.length(), 1)
}

///|
test "task scheduler basic" {
  let sched = @distributed.new_task_scheduler()
  inspect(sched.pending_count(), content="0")
  let cfg = @experiment.new_config(until=10.0)
  let id = sched.submit(name="task_a", config=cfg)
  inspect(id, content="0")
  inspect(sched.pending_count(), content="1")
}

///|
test "task scheduler priority ordering" {
  let sched = @distributed.new_task_scheduler()
  let cfg = @experiment.new_config(until=10.0)
  ignore(sched.submit(name="low", config=cfg, priority=5))
  ignore(sched.submit(name="high", config=cfg, priority=1))
  ignore(sched.submit(name="mid", config=cfg, priority=3))
  let tasks = sched.peek_tasks()
  inspect(tasks[0].name, content="high")
  inspect(tasks[1].name, content="mid")
  inspect(tasks[2].name, content="low")
}

///|
test "task scheduler run_all" {
  let sched = @distributed.new_task_scheduler()
  let cfg1 = @experiment.new_config(until=5.0)
  let cfg2 = @experiment.new_config(until=10.0)
  let cfg3 = @experiment.new_config(until=15.0)
  ignore(sched.submit(name="t1", config=cfg1))
  ignore(sched.submit(name="t2", config=cfg2))
  ignore(sched.submit(name="t3", config=cfg3))
  let results = sched.run_all()
  assert_eq(results.length(), 3)
  inspect(results[0].final_time, content="5")
  inspect(results[1].final_time, content="10")
  inspect(results[2].final_time, content="15")
  // 任务队列执行后清空
  inspect(sched.pending_count(), content="0")
}

///|
test "task scheduler run_all_detailed" {
  let sched = @distributed.new_task_scheduler()
  let cfg = @experiment.new_config(until=10.0)
  ignore(sched.submit(name="task_a", config=cfg, priority=2))
  ignore(sched.submit(name="task_b", config=cfg, priority=1))
  let detailed = sched.run_all_detailed()
  assert_eq(detailed.length(), 2)
  // task_b 优先级更高，应先执行
  inspect(detailed[0].task_name, content="task_b")
  inspect(detailed[1].task_name, content="task_a")
}

///|
test "task scheduler peek_tasks does not consume" {
  let sched = @distributed.new_task_scheduler()
  let cfg = @experiment.new_config(until=10.0)
  ignore(sched.submit(name="task", config=cfg))
  let _ = sched.peek_tasks()
  inspect(sched.pending_count(), content="1")
}

///|
test "result aggregator basic" {
  let agg = @distributed.new_aggregator()
  agg.add(10.0)
  agg.add(20.0)
  agg.add(30.0)
  inspect(agg.count(), content="3")
  inspect(agg.sum(), content="60")
  inspect(agg.mean(), content="20")
  inspect(agg.min(), content="10")
  inspect(agg.max(), content="30")
}

///|
test "result aggregator variance and stddev" {
  let agg = @distributed.new_aggregator()
  agg.add(1.0)
  agg.add(2.0)
  agg.add(3.0)
  agg.add(4.0)
  agg.add(5.0)
  inspect(agg.variance(), content="2.5")
  let s = agg.stddev()
  assert_true(s > 1.58 && s < 1.59)
}

///|
test "result aggregator summary" {
  let agg = @distributed.new_aggregator()
  agg.add(1.0)
  agg.add(2.0)
  agg.add(3.0)
  let s = agg.summary()
  inspect(s.count, content="3")
  inspect(s.mean, content="2")
  inspect(s.sum, content="6")
}

///|
test "result aggregator named metrics" {
  let agg = @distributed.new_aggregator()
  agg.add_metric("latency", value=10.0)
  agg.add_metric("latency", value=20.0)
  agg.add_metric("latency", value=30.0)
  agg.add_metric("throughput", value=100.0)
  agg.add_metric("throughput", value=200.0)
  inspect(agg.metric_count(), content="2")
  match agg.metric_mean("latency") {
    Some(v) => inspect(v, content="20")
    None => fail("expected mean")
  }
  match agg.metric_mean("throughput") {
    Some(v) => inspect(v, content="150")
    None => fail("expected mean")
  }
  match agg.metric_mean("nonexistent") {
    Some(_) => fail("expected None")
    None => ()
  }
}

///|
test "result aggregator metric_stddev" {
  let agg = @distributed.new_aggregator()
  agg.add_metric("x", value=1.0)
  agg.add_metric("x", value=2.0)
  agg.add_metric("x", value=3.0)
  match agg.metric_stddev("x") {
    Some(v) => assert_true(v > 0.8 && v < 1.1)
    None => fail("expected stddev")
  }
}

///|
test "result aggregator clear" {
  let agg = @distributed.new_aggregator()
  agg.add(1.0)
  agg.add(2.0)
  agg.add_metric("x", value=1.0)
  agg.clear()
  inspect(agg.count(), content="0")
  inspect(agg.metric_count(), content="0")
}

///|
test "result aggregator collect from experiment results" {
  let cfgs = [
    @experiment.new_config(until=10.0),
    @experiment.new_config(until=20.0),
    @experiment.new_config(until=30.0),
  ]
  let results = @experiment.batch_run(cfgs)
  let agg = @distributed.new_aggregator()
  agg.collect_final_times(results)
  inspect(agg.count(), content="3")
  inspect(agg.mean(), content="20")
  agg.collect_event_counts(results)
  inspect(agg.metric_count(), content="1")
}

///|
test "distributed simulation end-to-end" {
  // 端到端：创建任务调度器，提交多个参数遍历配置，执行，聚合结果
  let sched = @distributed.new_task_scheduler()
  let base = @experiment.new_config(until=100.0, seed=42)
  let configs = @experiment.param_sweep(base~, param_name="load", values=[
    0.5, 1.0, 1.5, 2.0,
  ])
  for i, cfg in configs {
    ignore(sched.submit(name="run_\{i}", config=cfg, priority=i))
  }
  inspect(sched.pending_count(), content="4")
  let results = sched.run_all()
  assert_eq(results.length(), 4)
  let agg = @distributed.new_aggregator()
  agg.collect_final_times(results)
  // 所有配置的 until 都是 100.0
  inspect(agg.mean(), content="100")
  inspect(agg.min(), content="100")
  inspect(agg.max(), content="100")
}
