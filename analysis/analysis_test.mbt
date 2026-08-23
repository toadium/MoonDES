///|
/// EventTimeline：创建后为空
test "timeline initial empty" {
  let tl = new_timeline()
  assert_eq(tl.length(), 0)
}

///|
/// EventTimeline：记录条目
test "timeline record entries" {
  let tl = new_timeline()
  tl.record(1.0, "event", "start", detail="proc_a")
  tl.record(2.0, "event", "end", detail="proc_a")
  tl.record(3.0, "resource", "acquire", detail="pump_1")
  assert_eq(tl.length(), 3)
}

///|
/// EventTimeline：按类别过滤
test "timeline filter by category" {
  let tl = new_timeline()
  tl.record(1.0, "event", "a")
  tl.record(2.0, "resource", "b")
  tl.record(3.0, "event", "c")
  tl.record(4.0, "sim", "d")
  let events = tl.filter_by_category("event")
  assert_eq(events.length(), 2)
  assert_eq(events[0].name, "a")
  assert_eq(events[1].name, "c")
}

///|
/// EventTimeline：按时间范围过滤
test "timeline filter by time range" {
  let tl = new_timeline()
  tl.record(1.0, "e", "a")
  tl.record(2.5, "e", "b")
  tl.record(3.0, "e", "c")
  tl.record(5.0, "e", "d")
  let filtered = tl.filter_by_time_range(2.0, 4.0)
  assert_eq(filtered.length(), 2)
  assert_eq(filtered[0].name, "b")
  assert_eq(filtered[1].name, "c")
}

///|
/// EventTimeline：按名称过滤
test "timeline filter by name" {
  let tl = new_timeline()
  tl.record(1.0, "e", "start")
  tl.record(2.0, "e", "end")
  tl.record(3.0, "e", "start")
  let starts = tl.filter_by_name("start")
  assert_eq(starts.length(), 2)
}

///|
/// EventTimeline：导出 JSON
test "timeline export json" {
  let tl = new_timeline()
  tl.record(1.0, "event", "start", detail="proc")
  let json = tl.export_json()
  assert_true(json.contains("\"time\":1"))
  assert_true(json.contains("\"category\":\"event\""))
  assert_true(json.contains("\"name\":\"start\""))
  assert_true(json.contains("\"detail\":\"proc\""))
}

///|
/// EventTimeline：导出文本
test "timeline export text" {
  let tl = new_timeline()
  tl.record(1.0, "event", "start")
  let text = tl.export_text()
  assert_true(text.contains("time"))
  assert_true(text.contains("event"))
  assert_true(text.contains("start"))
}

///|
/// EventTimeline：空时间线导出
test "timeline empty export" {
  let tl = new_timeline()
  let json = tl.export_json()
  assert_eq(json, "[]")
  let text = tl.export_text()
  assert_true(text.contains("time"))
}

///|
/// EventTimeline：clear 清空
test "timeline clear" {
  let tl = new_timeline()
  tl.record(1.0, "e", "a")
  tl.record(2.0, "e", "b")
  assert_eq(tl.length(), 2)
  tl.clear()
  assert_eq(tl.length(), 0)
}

///|
/// EventTimeline：插件模式自动记录
test "timeline as plugin" {
  let env = @core.new_env(until=10.0)
  let tl = new_timeline()
  let mgr = @plugin.new_manager()
  mgr.register(tl.as_plugin())
  @plugin.attach(env, mgr)
  ignore(env.schedule(time=2.0, callback=fn() { () }))
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  env.run()
  // 应记录：2 个 step + 2 个 event + 1 个 finish = 5
  assert_true(tl.length() >= 3)
  let sim_entries = tl.filter_by_category("sim")
  assert_true(sim_entries.length() >= 1)
}

///|
/// ResourceTracker：初始状态
test "resource tracker initial" {
  let tracker = new_resource_tracker()
  assert_eq(tracker.entry_count(), 0)
  assert_eq(tracker.pending_count(), 0)
}

///|
/// ResourceTracker：基本 acquire/release
test "resource tracker basic" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("pump_1", "proc_a", 1.0)
  assert_eq(tracker.pending_count(), 1)
  tracker.on_release("pump_1", 5.0)
  assert_eq(tracker.entry_count(), 1)
  assert_eq(tracker.pending_count(), 0)
  let entries = tracker.entries()
  assert_eq(entries[0].resource, "pump_1")
  assert_eq(entries[0].process, "proc_a")
  assert_eq(entries[0].start, 1.0)
  assert_eq(entries[0].end, 5.0)
}

///|
/// ResourceTracker：利用率计算
test "resource tracker utilization" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("pump_1", "proc_a", 1.0)
  tracker.on_release("pump_1", 5.0)
  // 占用 4/10 = 0.4
  let util = tracker.utilization("pump_1", 10.0)
  assert_eq(util, 0.4)
}

///|
/// ResourceTracker：多次占用累加利用率
test "resource tracker multi utilization" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 0.0)
  tracker.on_release("r1", 3.0)
  tracker.on_acquire("r1", "p2", 5.0)
  tracker.on_release("r1", 8.0)
  // 占用 3+3=6, 总 10, 利用率 0.6
  let util = tracker.utilization("r1", 10.0)
  assert_eq(util, 0.6)
}

///|
/// ResourceTracker：未释放不计算利用率
test "resource tracker unrelease" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 0.0)
  // 未 release，无 entry
  assert_eq(tracker.entry_count(), 0)
  let util = tracker.utilization("r1", 10.0)
  assert_eq(util, 0.0)
}

///|
/// ResourceTracker：利用率除零保护
test "resource tracker zero total time" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 0.0)
  tracker.on_release("r1", 5.0)
  let util = tracker.utilization("r1", 0.0)
  assert_eq(util, 0.0)
}

///|
/// ResourceTracker：按资源过滤条目
test "resource tracker entries for" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 0.0)
  tracker.on_release("r1", 1.0)
  tracker.on_acquire("r2", "p2", 0.0)
  tracker.on_release("r2", 2.0)
  tracker.on_acquire("r1", "p3", 3.0)
  tracker.on_release("r1", 4.0)
  let r1_entries = tracker.entries_for("r1")
  assert_eq(r1_entries.length(), 2)
  let r2_entries = tracker.entries_for("r2")
  assert_eq(r2_entries.length(), 1)
}

///|
/// ResourceTracker：平均利用率
test "resource tracker avg utilization" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 0.0)
  tracker.on_release("r1", 5.0)
  tracker.on_acquire("r2", "p2", 0.0)
  tracker.on_release("r2", 3.0)
  // r1: 5/10=0.5, r2: 3/10=0.3, avg=0.4
  let avg = tracker.avg_utilization(10.0)
  assert_eq(avg, 0.4)
}

///|
/// ResourceTracker：导出 JSON
test "resource tracker export json" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 1.0)
  tracker.on_release("r1", 3.0)
  let json = tracker.export_json()
  assert_true(json.contains("\"resource\":\"r1\""))
  assert_true(json.contains("\"process\":\"p1\""))
  assert_true(json.contains("\"start\":1"))
  assert_true(json.contains("\"end\":3"))
}

///|
/// ResourceTracker：导出文本
test "resource tracker export text" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 1.0)
  tracker.on_release("r1", 3.0)
  let text = tracker.export_text()
  assert_true(text.contains("r1"))
  assert_true(text.contains("p1"))
  assert_true(text.contains("duration"))
}

///|
/// ResourceTracker：release 未 acquire 忽略
test "resource tracker release without acquire" {
  let tracker = new_resource_tracker()
  tracker.on_release("r1", 5.0)
  assert_eq(tracker.entry_count(), 0)
}

///|
/// ResourceTracker：clear
test "resource tracker clear" {
  let tracker = new_resource_tracker()
  tracker.on_acquire("r1", "p1", 0.0)
  tracker.on_release("r1", 1.0)
  tracker.clear()
  assert_eq(tracker.entry_count(), 0)
  assert_eq(tracker.pending_count(), 0)
}

///|
/// SimulationReport：创建
test "report creation" {
  let report = new_report()
  assert_eq(report.timeline().length(), 0)
  assert_eq(report.tracker().entry_count(), 0)
}

///|
/// SimulationReport：生成文本报告
test "report generate text" {
  let env = @core.new_env(until=10.0)
  ignore(env.schedule(time=1.0, callback=fn() { () }))
  ignore(env.schedule(time=2.0, callback=fn() { () }))
  env.run()
  let report = new_report()
  let text = report.generate_text(env)
  assert_true(text.contains("MoonDES Simulation Report"))
  assert_true(text.contains("Summary"))
  assert_true(text.contains("Event count:"))
  assert_true(text.contains("End Report"))
}

///|
/// SimulationReport：生成 JSON 报告
test "report generate json" {
  let env = @core.new_env(until=10.0)
  ignore(env.schedule(time=1.0, callback=fn() { () }))
  env.run()
  let report = new_report()
  let json = report.generate_json(env)
  assert_true(json.contains("\"summary\""))
  assert_true(json.contains("\"time\""))
  assert_true(json.contains("\"event_count\""))
  assert_true(json.contains("\"timeline\""))
  assert_true(json.contains("\"resources\""))
}

///|
/// SimulationReport：带数据的报告
test "report with data" {
  let env = @core.new_env(until=20.0)
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  env.run()
  let tl = new_timeline()
  tl.record(1.0, "event", "start", detail="proc_a")
  tl.record(5.0, "event", "end", detail="proc_a")
  let tracker = new_resource_tracker()
  tracker.on_acquire("pump_1", "proc_a", 1.0)
  tracker.on_release("pump_1", 5.0)
  let report = new_report_with(timeline=tl, tracker~)
  let text = report.generate_text(env)
  assert_true(text.contains("Timeline"))
  assert_true(text.contains("Resource Allocation"))
  assert_true(text.contains("Utilization"))
  assert_true(text.contains("pump_1"))
  let json = report.generate_json(env)
  assert_true(json.contains("proc_a"))
  assert_true(json.contains("pump_1"))
}
