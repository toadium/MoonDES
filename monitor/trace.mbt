///|
/// Trace 事件阶段（Chrome Trace Event Format）
///
/// - Begin：持续时间事件开始
/// - End：持续时间事件结束
/// - Complete：完整持续时间事件（含 duration）
/// - Instant：瞬时事件
pub(all) enum TracePhase {
  Begin
  End
  Complete
  Instant
} derive(Debug, Eq)

///|
/// Trace 阶段转字符串
pub fn TracePhase::to_string(self : TracePhase) -> String {
  match self {
    Begin => "B"
    End => "E"
    Complete => "X"
    Instant => "i"
  }
}

///|
/// Trace 事件（Chrome Trace Event Format）
///
/// 时间戳单位为微秒（μs），与 Chrome tracing 格式一致。
pub(all) struct TraceEvent {
  name : String
  cat : String
  ph : TracePhase
  ts : Double
  dur : Double?
  pid : Int
  tid : Int
} derive(Debug, Eq)

///|
/// Trace 导出器
///
/// 收集 Chrome Trace Event 格式的事件，可导出为 JSON（chrome://tracing 兼容）
/// 或 CSV。可挂载为插件自动记录仿真步和事件。
///
/// # Example
/// ```mbt check
/// test {
///   let tracer = @monitor.new_tracer()
///   tracer.begin("setup", ts=0.0)
///   tracer.end("setup", ts=100.0)
///   tracer.complete("step", ts=200.0, dur=50.0)
///   assert_eq(tracer.length(), 3)
/// }
/// ```
pub(all) struct TraceExporter {
  events : Array[TraceEvent]
  mut next_pid : Int
  mut next_tid : Int
}

///|
/// 创建 Trace 导出器
pub fn new_tracer() -> TraceExporter {
  { events: [], next_pid: 0, next_tid: 0 }
}

///|
/// 分配新的进程 ID
pub fn TraceExporter::alloc_pid(self : TraceExporter) -> Int {
  let id = self.next_pid
  self.next_pid = id + 1
  id
}

///|
/// 分配新的线程 ID
pub fn TraceExporter::alloc_tid(self : TraceExporter) -> Int {
  let id = self.next_tid
  self.next_tid = id + 1
  id
}

///|
/// 设置下一个进程 ID 和线程 ID
pub fn TraceExporter::set_pid_tid(
  self : TraceExporter,
  pid~ : Int,
  tid~ : Int,
) -> Unit {
  self.next_pid = pid
  self.next_tid = tid
}

///|
/// 已收集的事件数
pub fn TraceExporter::length(self : TraceExporter) -> Int {
  self.events.length()
}

///|
/// 获取所有事件（只读视图）
pub fn TraceExporter::events(self : TraceExporter) -> Array[TraceEvent] {
  self.events
}

///|
/// 清空事件
pub fn TraceExporter::clear(self : TraceExporter) -> Unit {
  self.events.clear()
}

///|
/// 内部：添加事件
fn TraceExporter::_add(
  self : TraceExporter,
  name~ : String,
  cat~ : String,
  ph~ : TracePhase,
  ts~ : Double,
  dur~ : Double?,
  pid~ : Int,
  tid~ : Int,
) -> Unit {
  self.events.push({ name, cat, ph, ts, dur, pid, tid })
}

///|
/// 计算指定名称的事件数
pub fn TraceExporter::count_by_name(self : TraceExporter, name : String) -> Int {
  let mut n = 0
  for e in self.events {
    if e.name == name {
      n = n + 1
    }
  }
  n
}

///|
/// 计算指定类别的事件数
pub fn TraceExporter::count_by_category(
  self : TraceExporter,
  cat : String,
) -> Int {
  let mut n = 0
  for e in self.events {
    if e.cat == cat {
      n = n + 1
    }
  }
  n
}

///|
/// 添加 Begin 事件（持续时间事件开始）
pub fn TraceExporter::begin(
  self : TraceExporter,
  name : String,
  ts~ : Double,
  cat? : String = "default",
  pid? : Int = 0,
  tid? : Int = 0,
) -> Unit {
  self._add(name~, cat~, ph=Begin, ts~, dur=None, pid~, tid~)
}

///|
/// 添加 End 事件（持续时间事件结束）
pub fn TraceExporter::end(
  self : TraceExporter,
  name : String,
  ts~ : Double,
  cat? : String = "default",
  pid? : Int = 0,
  tid? : Int = 0,
) -> Unit {
  self._add(name~, cat~, ph=End, ts~, dur=None, pid~, tid~)
}

///|
/// 添加 Complete 事件（含 duration）
pub fn TraceExporter::complete(
  self : TraceExporter,
  name : String,
  ts~ : Double,
  dur~ : Double,
  cat? : String = "default",
  pid? : Int = 0,
  tid? : Int = 0,
) -> Unit {
  self._add(name~, cat~, ph=Complete, ts~, dur=Some(dur), pid~, tid~)
}

///|
/// 添加 Instant 事件（瞬时）
pub fn TraceExporter::instant(
  self : TraceExporter,
  name : String,
  ts~ : Double,
  cat? : String = "default",
  pid? : Int = 0,
  tid? : Int = 0,
) -> Unit {
  self._add(name~, cat~, ph=Instant, ts~, dur=None, pid~, tid~)
}

///|
/// 导出为 Chrome Trace JSON 格式
///
/// 格式：`{"traceEvents":[{...},{...},...]}`
/// 可直接加载到 chrome://tracing 可视化。
pub fn TraceExporter::export_json(self : TraceExporter) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\"traceEvents\":[")
  for i, e in self.events {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_char('{')
    buf.write_string("\"name\":")
    buf.write_string(@json.to_json(e.name).stringify())
    buf.write_string(",\"cat\":")
    buf.write_string(@json.to_json(e.cat).stringify())
    buf.write_string(",\"ph\":\"")
    buf.write_string(e.ph.to_string())
    buf.write_string("\",\"ts\":")
    buf.write_string(e.ts.to_string())
    buf.write_string(",\"pid\":")
    buf.write_string(e.pid.to_string())
    buf.write_string(",\"tid\":")
    buf.write_string(e.tid.to_string())
    match e.dur {
      Some(d) => {
        buf.write_string(",\"dur\":")
        buf.write_string(d.to_string())
      }
      None => ()
    }
    buf.write_char('}')
  }
  buf.write_string("]}")
  buf.to_string()
}

///|
/// 导出为 CSV 格式
///
/// 表头：`name,cat,ph,ts,dur,pid,tid`
/// dur 为空时输出空字符串。
pub fn TraceExporter::export_csv(self : TraceExporter) -> String {
  let buf = StringBuilder::new()
  buf.write_string("name,cat,ph,ts,dur,pid,tid\n")
  for e in self.events {
    buf.write_string(e.name)
    buf.write_char(',')
    buf.write_string(e.cat)
    buf.write_char(',')
    buf.write_string(e.ph.to_string())
    buf.write_char(',')
    buf.write_string(e.ts.to_string())
    buf.write_char(',')
    match e.dur {
      Some(d) => buf.write_string(d.to_string())
      None => ()
    }
    buf.write_char(',')
    buf.write_string(e.pid.to_string())
    buf.write_char(',')
    buf.write_string(e.tid.to_string())
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
/// 将 TraceExporter 挂载为插件
///
/// 自动记录：
/// - on_step：记录 Instant 事件（类别 "sim"，名称 "step"）
/// - on_event：记录 Complete 事件（类别 "event"，含事件 ID）
/// - on_finish：记录 Instant 事件（名称 "finish"）
pub fn TraceExporter::as_plugin(
  self : TraceExporter,
) -> @plugin.PluginCallbacks {
  {
    on_step: fn(_env, time) {
      self.instant("step", ts=time * 1000000.0, cat="sim")
    },
    on_event: fn(_env, event) {
      self.complete(
        "event_{event.id}",
        ts=event.time * 1000000.0,
        dur=0.0,
        cat="event",
      )
    },
    on_finish: fn(env) {
      self.instant("finish", ts=env.now() * 1000000.0, cat="sim")
    },
  }
}
