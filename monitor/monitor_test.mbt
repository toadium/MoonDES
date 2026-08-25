///|
test "logger basic recording" {
  let logger = @monitor.new_logger(min_level=@monitor.Debug)
  logger.debug("debug msg")
  logger.info("info msg")
  logger.warn("warn msg")
  logger.error("error msg")
  assert_eq(logger.length(), 4)
}

///|
test "logger level filtering" {
  let logger = @monitor.new_logger(min_level=@monitor.Warn)
  logger.debug("debug msg")
  logger.info("info msg")
  logger.warn("warn msg")
  logger.error("error msg")
  assert_eq(logger.length(), 2)
  assert_eq(logger.count_by_level(@monitor.Warn), 1)
  assert_eq(logger.count_by_level(@monitor.Error), 1)
}

///|
test "logger sink callback" {
  let collected : Array[@monitor.LogEntry] = []
  let logger = @monitor.new_logger(min_level=@monitor.Info)
  logger.set_sink(Some(fn(e) { collected.push(e) }))
  logger.info("hello")
  logger.warn("world")
  assert_eq(collected.length(), 2)
  assert_eq(collected[0].message, "hello")
}

///|
test "logger with time and source" {
  let logger = @monitor.new_logger(min_level=@monitor.Debug)
  logger.info("msg1", time=1.5, source=Some("src1"))
  logger.warn("msg2", time=2.5, source=Some("src2"))
  let entries = logger.entries()
  assert_eq(entries[0].time, 1.5)
  assert_eq(entries[1].time, 2.5)
  assert_eq(entries[0].source, Some("src1"))
}

///|
test "logger filter by level" {
  let logger = @monitor.new_logger(min_level=@monitor.Debug)
  logger.debug("d")
  logger.info("i")
  logger.warn("w")
  logger.error("e")
  let warns = logger.filter_by_level(@monitor.Warn)
  assert_eq(warns.length(), 1)
  assert_eq(warns[0].message, "w")
}

///|
test "logger filter by time" {
  let logger = @monitor.new_logger(min_level=@monitor.Debug)
  logger.info("a", time=1.0)
  logger.info("b", time=2.0)
  logger.info("c", time=3.0)
  let mid = logger.filter_by_time(start=1.5, end=3.0)
  assert_eq(mid.length(), 1)
  assert_eq(mid[0].message, "b")
}

///|
test "logger export text" {
  let logger = @monitor.new_logger(min_level=@monitor.Info)
  logger.info("hello", time=1.0)
  let text = logger.export_text()
  assert_true(text.contains("hello"))
  assert_true(text.contains("INFO"))
}

///|
test "logger export json" {
  let logger = @monitor.new_logger(min_level=@monitor.Info)
  logger.info("hello", time=1.0)
  let json = logger.export_json()
  assert_true(json.contains("hello"))
  assert_true(json.contains("INFO"))
}

///|
test "logger as plugin integration" {
  let env = @core.new_env(until=10.0)
  let pm = @plugin.new_manager()
  let logger = @monitor.new_logger(min_level=@monitor.Debug)
  pm.register(logger.as_plugin())
  @plugin.attach(env, pm)
  ignore(env.schedule(time=2.0, callback=fn() { () }))
  env.run()
  let entries = logger.entries()
  assert_true(entries.length() > 0)
}

///|
test "logger clear" {
  let logger = @monitor.new_logger(min_level=@monitor.Debug)
  logger.info("a")
  logger.info("b")
  assert_eq(logger.length(), 2)
  logger.clear()
  assert_eq(logger.length(), 0)
}

///|
test "logger level from_string" {
  assert_eq(@monitor.LogLevel::from_string("DEBUG"), Some(@monitor.Debug))
  assert_eq(@monitor.LogLevel::from_string("INFO"), Some(@monitor.Info))
  assert_eq(@monitor.LogLevel::from_string("WARN"), Some(@monitor.Warn))
  assert_eq(@monitor.LogLevel::from_string("ERROR"), Some(@monitor.Error))
  assert_eq(@monitor.LogLevel::from_string("XXX"), None)
}

///|
test "metrics counter" {
  let m = @monitor.new_metrics()
  m.incr("events")
  m.incr("events")
  m.incr("events", by=5.0)
  assert_eq(m.get_counter("events"), Some(7.0))
  assert_eq(m.get_counter("nonexistent"), None)
  assert_eq(m.counter_count(), 1)
}

///|
test "metrics gauge" {
  let m = @monitor.new_metrics()
  m.set_gauge("temperature", value=25.5)
  m.set_gauge("pressure", value=101.3)
  assert_eq(m.get_gauge("temperature"), Some(25.5))
  assert_eq(m.get_gauge("pressure"), Some(101.3))
  assert_eq(m.gauge_count(), 2)
}

///|
test "metrics histogram" {
  let m = @monitor.new_metrics()
  m.observe("latency", value=10.0)
  m.observe("latency", value=20.0)
  m.observe("latency", value=30.0)
  match m.histogram_summary("latency") {
    Some(s) => {
      assert_eq(s.count, 3)
      assert_eq(s.sum, 60.0)
      assert_eq(s.mean, 20.0)
      assert_eq(s.min, 10.0)
      assert_eq(s.max, 30.0)
    }
    None => assert_true(false)
  }
}

///|
test "metrics snapshot" {
  let m = @monitor.new_metrics()
  m.incr("c1")
  m.set_gauge("g1", value=1.0)
  m.observe("h1", value=5.0)
  let snap = m.snapshot()
  assert_eq(snap.length(), 3)
}

///|
test "metrics export json" {
  let m = @monitor.new_metrics()
  m.incr("events")
  m.set_gauge("util", value=0.5)
  let json = m.export_json()
  assert_true(json.contains("counters"))
  assert_true(json.contains("gauges"))
  assert_true(json.contains("histograms"))
}

///|
test "metrics reset" {
  let m = @monitor.new_metrics()
  m.incr("a")
  m.set_gauge("b", value=1.0)
  m.observe("c", value=1.0)
  m.reset()
  assert_eq(m.counter_count(), 0)
  assert_eq(m.gauge_count(), 0)
  assert_eq(m.histogram_count(), 0)
}

///|
test "metrics as plugin integration" {
  let env = @core.new_env(until=10.0)
  let pm = @plugin.new_manager()
  let m = @monitor.new_metrics()
  pm.register(m.as_plugin())
  @plugin.attach(env, pm)
  ignore(env.schedule(time=2.0, callback=fn() { () }))
  ignore(env.schedule(time=4.0, callback=fn() { () }))
  env.run()
  match m.get_counter("event_count") {
    Some(v) => assert_eq(v, 2.0)
    None => assert_true(false)
  }
}

///|
test "tracer basic events" {
  let tracer = @monitor.new_tracer()
  tracer.begin("setup", ts=0.0)
  tracer.end("setup", ts=100.0)
  tracer.complete("step", ts=200.0, dur=50.0)
  tracer.instant("mark", ts=300.0)
  assert_eq(tracer.length(), 4)
}

///|
test "tracer count by name and category" {
  let tracer = @monitor.new_tracer()
  tracer.begin("a", ts=0.0, cat="cat1")
  tracer.begin("a", ts=10.0, cat="cat1")
  tracer.begin("b", ts=20.0, cat="cat2")
  assert_eq(tracer.count_by_name("a"), 2)
  assert_eq(tracer.count_by_name("b"), 1)
  assert_eq(tracer.count_by_category("cat1"), 2)
  assert_eq(tracer.count_by_category("cat2"), 1)
}

///|
test "tracer export json" {
  let tracer = @monitor.new_tracer()
  tracer.begin("setup", ts=0.0)
  tracer.end("setup", ts=100.0)
  let json = tracer.export_json()
  assert_true(json.contains("traceEvents"))
  assert_true(json.contains("setup"))
  assert_true(json.contains("\"ph\":\"B\""))
  assert_true(json.contains("\"ph\":\"E\""))
}

///|
test "tracer export csv" {
  let tracer = @monitor.new_tracer()
  tracer.complete("step", ts=100.0, dur=50.0)
  let csv = tracer.export_csv()
  assert_true(csv.contains("name,cat,ph,ts,dur,pid,tid"))
  assert_true(csv.contains("step"))
  assert_true(csv.contains("X"))
}

///|
test "tracer as plugin integration" {
  let env = @core.new_env(until=10.0)
  let pm = @plugin.new_manager()
  let tracer = @monitor.new_tracer()
  pm.register(tracer.as_plugin())
  @plugin.attach(env, pm)
  ignore(env.schedule(time=2.0, callback=fn() { () }))
  env.run()
  assert_true(tracer.length() > 0)
}

///|
test "tracer pid tid allocation" {
  let tracer = @monitor.new_tracer()
  let pid1 = tracer.alloc_pid()
  let pid2 = tracer.alloc_pid()
  let tid1 = tracer.alloc_tid()
  assert_eq(pid1, 0)
  assert_eq(pid2, 1)
  assert_eq(tid1, 0)
}

///|
test "tracer clear" {
  let tracer = @monitor.new_tracer()
  tracer.begin("a", ts=0.0)
  tracer.end("a", ts=1.0)
  assert_eq(tracer.length(), 2)
  tracer.clear()
  assert_eq(tracer.length(), 0)
}
