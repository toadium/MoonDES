///|
/// 时间线条目
///
/// 记录仿真过程中一个事件的结构化信息。
pub(all) struct TimelineEntry {
  time : Double
  category : String
  name : String
  detail : String
} derive(Debug, Eq)

///|
/// 事件时间线
///
/// 按时间顺序记录仿真过程中的所有事件，支持按类别和时间范围过滤，
/// 可导出为 JSON 或格式化文本表格。可作为插件挂载到仿真环境自动记录。
///
/// # Example
/// ```mbt check
/// test {
///   let tl = new_timeline()
///   tl.record(1.0, "event", "start", detail="proc_a")
///   tl.record(2.0, "event", "end", detail="proc_a")
///   inspect(tl.length(), content="2")
/// }
/// ```
pub(all) struct EventTimeline {
  entries : Array[TimelineEntry]
}

///|
/// 创建事件时间线
pub fn new_timeline() -> EventTimeline {
  { entries: [] }
}

///|
/// 记录一条时间线条目
pub fn EventTimeline::record(
  self : EventTimeline,
  time : Double,
  category : String,
  name : String,
  detail? : String = "",
) -> Unit {
  self.entries.push({ time, category, name, detail })
}

///|
/// 条目数量
pub fn EventTimeline::length(self : EventTimeline) -> Int {
  self.entries.length()
}

///|
/// 获取所有条目
pub fn EventTimeline::entries(self : EventTimeline) -> Array[TimelineEntry] {
  self.entries
}

///|
/// 按类别过滤
pub fn EventTimeline::filter_by_category(
  self : EventTimeline,
  category : String,
) -> Array[TimelineEntry] {
  let result : Array[TimelineEntry] = []
  for e in self.entries {
    if e.category == category {
      result.push(e)
    }
  }
  result
}

///|
/// 按时间范围过滤
pub fn EventTimeline::filter_by_time_range(
  self : EventTimeline,
  start : Double,
  end : Double,
) -> Array[TimelineEntry] {
  let result : Array[TimelineEntry] = []
  for e in self.entries {
    if e.time >= start && e.time <= end {
      result.push(e)
    }
  }
  result
}

///|
/// 按名称过滤
pub fn EventTimeline::filter_by_name(
  self : EventTimeline,
  name : String,
) -> Array[TimelineEntry] {
  let result : Array[TimelineEntry] = []
  for e in self.entries {
    if e.name == name {
      result.push(e)
    }
  }
  result
}

///|
/// 导出为 JSON 格式
pub fn EventTimeline::export_json(self : EventTimeline) -> String {
  let buf = StringBuilder::new()
  buf.write_char('[')
  for i, e in self.entries {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_char('{')
    buf.write_string("\"time\":")
    buf.write_string(e.time.to_string())
    buf.write_string(",\"category\":")
    buf.write_string(@json.to_json(e.category).stringify())
    buf.write_string(",\"name\":")
    buf.write_string(@json.to_json(e.name).stringify())
    buf.write_string(",\"detail\":")
    buf.write_string(@json.to_json(e.detail).stringify())
    buf.write_char('}')
  }
  buf.write_char(']')
  buf.to_string()
}

///|
/// 导出为格式化文本表格
///
/// 格式：`time | category | name | detail`
pub fn EventTimeline::export_text(self : EventTimeline) -> String {
  let buf = StringBuilder::new()
  buf.write_string("time\tcategory\tname\tdetail\n")
  for e in self.entries {
    buf.write_string(e.time.to_string())
    buf.write_char('\t')
    buf.write_string(e.category)
    buf.write_char('\t')
    buf.write_string(e.name)
    buf.write_char('\t')
    buf.write_string(e.detail)
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
/// 将 EventTimeline 挂载为插件
///
/// 自动记录：
/// - on_step：记录 "step" 事件（类别 "sim"）
/// - on_event：记录事件触发（类别 "event"，名称 "event_{id}"）
/// - on_finish：记录仿真结束（类别 "sim"，名称 "finish"）
pub fn EventTimeline::as_plugin(
  self : EventTimeline,
) -> @plugin.PluginCallbacks {
  {
    on_step: fn(_env, time) { self.record(time, "sim", "step") },
    on_event: fn(_env, event) {
      self.record(event.time, "event", "event_{event.id}")
    },
    on_finish: fn(env) { self.record(env.now(), "sim", "finish") },
  }
}

///|
/// 清空所有条目
pub fn EventTimeline::clear(self : EventTimeline) -> Unit {
  self.entries.clear()
}

// ---------------------------------------------------------------------------
// ResourceTracker — 资源分配追踪与甘特图
// ---------------------------------------------------------------------------

///|
/// 甘特图条目：资源占用区间
///
/// 记录一个资源被某进程从 `start` 到 `end` 占用。
pub(all) struct GanttEntry {
  resource : String
  process : String
  start : Double
  end : Double
} derive(Debug, Eq)

///|
/// 资源分配追踪器
///
/// 记录资源被获取和释放的时间，生成甘特图数据，
/// 计算资源利用率。适用于资源调度分析。
///
/// # Example
/// ```mbt check
/// test {
///   let tracker = new_resource_tracker()
///   tracker.on_acquire("pump_1", "proc_a", 1.0)
///   tracker.on_release("pump_1", 5.0)
///   inspect(tracker.entry_count(), content="1")
///   inspect(tracker.utilization("pump_1", 10.0), content="0.4")
/// }
/// ```
pub(all) struct ResourceTracker {
  entries : Array[GanttEntry]
  // 待完成的分配：resource -> (process, start_time)
  pending : Map[String, (String, Double)]
}

///|
/// 创建资源追踪器
pub fn new_resource_tracker() -> ResourceTracker {
  { entries: [], pending: Map([]) }
}

///|
/// 记录资源获取
///
/// 标记资源 `resource` 在 `time` 时刻被 `process` 获取。
/// 需与 `on_release` 配对使用。
pub fn ResourceTracker::on_acquire(
  self : ResourceTracker,
  resource : String,
  process : String,
  time : Double,
) -> Unit {
  self.pending[resource] = (process, time)
}

///|
/// 记录资源释放
///
/// 完成当前分配，生成甘特图条目。若资源未被获取则忽略。
pub fn ResourceTracker::on_release(
  self : ResourceTracker,
  resource : String,
  time : Double,
) -> Unit {
  match self.pending.get(resource) {
    Some((process, start)) => {
      self.entries.push({ resource, process, start, end: time })
      ignore(self.pending.remove(resource))
    }
    None => ()
  }
}

///|
/// 甘特图条目数
pub fn ResourceTracker::entry_count(self : ResourceTracker) -> Int {
  self.entries.length()
}

///|
/// 获取所有甘特图条目
pub fn ResourceTracker::entries(self : ResourceTracker) -> Array[GanttEntry] {
  self.entries
}

///|
/// 计算指定资源的利用率
///
/// 利用率 = 占用总时长 / 总仿真时长
pub fn ResourceTracker::utilization(
  self : ResourceTracker,
  resource : String,
  total_time : Double,
) -> Double {
  if total_time <= 0.0 {
    return 0.0
  }
  let mut busy = 0.0
  for e in self.entries {
    if e.resource == resource {
      busy = busy + (e.end - e.start)
    }
  }
  busy / total_time
}

///|
/// 计算所有资源的平均利用率
pub fn ResourceTracker::avg_utilization(
  self : ResourceTracker,
  total_time : Double,
) -> Double {
  if total_time <= 0.0 || self.entries.length() == 0 {
    return 0.0
  }
  // 收集所有资源名
  let resources : Array[String] = []
  for e in self.entries {
    let mut found = false
    for r in resources {
      if r == e.resource {
        found = true
        break
      }
    }
    if !found {
      resources.push(e.resource)
    }
  }
  if resources.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for r in resources {
    total = total + self.utilization(r, total_time)
  }
  total / resources.length().to_double()
}

///|
/// 获取指定资源的所有甘特图条目
pub fn ResourceTracker::entries_for(
  self : ResourceTracker,
  resource : String,
) -> Array[GanttEntry] {
  let result : Array[GanttEntry] = []
  for e in self.entries {
    if e.resource == resource {
      result.push(e)
    }
  }
  result
}

///|
/// 当前未释放的资源数
pub fn ResourceTracker::pending_count(self : ResourceTracker) -> Int {
  self.pending.length()
}

///|
/// 导出为 JSON 格式
pub fn ResourceTracker::export_json(self : ResourceTracker) -> String {
  let buf = StringBuilder::new()
  buf.write_char('[')
  for i, e in self.entries {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_char('{')
    buf.write_string("\"resource\":")
    buf.write_string(@json.to_json(e.resource).stringify())
    buf.write_string(",\"process\":")
    buf.write_string(@json.to_json(e.process).stringify())
    buf.write_string(",\"start\":")
    buf.write_string(e.start.to_string())
    buf.write_string(",\"end\":")
    buf.write_string(e.end.to_string())
    buf.write_char('}')
  }
  buf.write_char(']')
  buf.to_string()
}

///|
/// 导出为文本格式（ASCII 甘特图）
///
/// 格式：`resource | process | start - end (duration)`
pub fn ResourceTracker::export_text(self : ResourceTracker) -> String {
  let buf = StringBuilder::new()
  buf.write_string("resource\tprocess\tstart\tend\tduration\n")
  for e in self.entries {
    buf.write_string(e.resource)
    buf.write_char('\t')
    buf.write_string(e.process)
    buf.write_char('\t')
    buf.write_string(e.start.to_string())
    buf.write_char('\t')
    buf.write_string(e.end.to_string())
    buf.write_char('\t')
    buf.write_string((e.end - e.start).to_string())
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
/// 清空所有数据
pub fn ResourceTracker::clear(self : ResourceTracker) -> Unit {
  self.entries.clear()
  self.pending.clear()
}

// ---------------------------------------------------------------------------
// SimulationReport — 综合报告生成器
// ---------------------------------------------------------------------------

///|
/// 仿真综合报告生成器
///
/// 整合仿真环境统计、事件时间线、资源追踪数据，
/// 生成文本或 JSON 格式的综合分析报告。
///
/// # Example
/// ```mbt check
/// test {
///   let env = @core.new_env(until=10.0)
///   ignore(env.schedule(time=1.0, callback=fn() { () }))
///   ignore(env.schedule(time=2.0, callback=fn() { () }))
///   env.run()
///   let report = new_report()
///   let text = report.generate_text(env)
///   assert_true(text.length() > 0)
/// }
/// ```
pub(all) struct SimulationReport {
  timeline : EventTimeline
  tracker : ResourceTracker
}

///|
/// 创建仿真报告生成器
pub fn new_report() -> SimulationReport {
  { timeline: new_timeline(), tracker: new_resource_tracker() }
}

///|
/// 创建仿真报告生成器（带已有时间线和追踪器）
pub fn new_report_with(
  timeline~ : EventTimeline,
  tracker~ : ResourceTracker,
) -> SimulationReport {
  { timeline, tracker }
}

///|
/// 获取时间线
pub fn SimulationReport::timeline(self : SimulationReport) -> EventTimeline {
  self.timeline
}

///|
/// 获取资源追踪器
pub fn SimulationReport::tracker(self : SimulationReport) -> ResourceTracker {
  self.tracker
}

///|
/// 生成文本格式综合报告
///
/// 包含：仿真概要（时间/事件数/状态）、时间线条目、资源利用率
pub fn SimulationReport::generate_text(
  self : SimulationReport,
  env : @core.SimulationEnv,
) -> String {
  let buf = StringBuilder::new()
  // 报告头
  buf.write_string("=== MoonDES Simulation Report ===\n")
  buf.write_string("\n")
  // 仿真概要
  buf.write_string("--- Summary ---\n")
  buf.write_string("Simulation time: ")
  buf.write_string(env.now().to_string())
  buf.write_char('\n')
  buf.write_string("Event count: ")
  buf.write_string(env.event_count().to_string())
  buf.write_char('\n')
  buf.write_string("Status: ")
  buf.write_string(if env.is_finished() { "Finished" } else { "Running" })
  buf.write_char('\n')
  // 时间线
  buf.write_string("\n--- Timeline (")
  buf.write_string(self.timeline.length().to_string())
  buf.write_string(" entries) ---\n")
  if self.timeline.length() > 0 {
    buf.write_string(self.timeline.export_text())
  }
  // 资源追踪
  buf.write_string("\n--- Resource Allocation (")
  buf.write_string(self.tracker.entry_count().to_string())
  buf.write_string(" entries) ---\n")
  if self.tracker.entry_count() > 0 {
    buf.write_string(self.tracker.export_text())
    // 利用率
    buf.write_string("\n--- Utilization ---\n")
    let resources : Array[String] = []
    for e in self.tracker.entries {
      let mut found = false
      for r in resources {
        if r == e.resource {
          found = true
          break
        }
      }
      if !found {
        resources.push(e.resource)
      }
    }
    for r in resources {
      let util = self.tracker.utilization(r, env.now())
      buf.write_string(r)
      buf.write_string(": ")
      buf.write_string(util.to_string())
      buf.write_char('\n')
    }
  }
  buf.write_string("\n=== End Report ===\n")
  buf.to_string()
}

///|
/// 生成 JSON 格式综合报告
pub fn SimulationReport::generate_json(
  self : SimulationReport,
  env : @core.SimulationEnv,
) -> String {
  let buf = StringBuilder::new()
  buf.write_char('{')
  // summary
  buf.write_string("\"summary\":{")
  buf.write_string("\"time\":")
  buf.write_string(env.now().to_string())
  buf.write_string(",\"event_count\":")
  buf.write_string(env.event_count().to_string())
  buf.write_string(",\"finished\":")
  buf.write_string(if env.is_finished() { "true" } else { "false" })
  buf.write_char('}')
  // timeline
  buf.write_string(",\"timeline\":")
  buf.write_string(self.timeline.export_json())
  // resources
  buf.write_string(",\"resources\":")
  buf.write_string(self.tracker.export_json())
  buf.write_char('}')
  buf.to_string()
}
