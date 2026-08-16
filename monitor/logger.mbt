///|
/// 日志级别
pub(all) enum LogLevel {
  Debug
  Info
  Warn
  Error
} derive(Debug, Eq)

///|
/// 日志级别转数值（用于比较）
fn LogLevel::_rank(self : LogLevel) -> Int {
  match self {
    Debug => 0
    Info => 1
    Warn => 2
    Error => 3
  }
}

///|
/// 日志级别转字符串
pub fn LogLevel::to_string(self : LogLevel) -> String {
  match self {
    Debug => "DEBUG"
    Info => "INFO"
    Warn => "WARN"
    Error => "ERROR"
  }
}

///|
/// 从字符串解析日志级别
pub fn LogLevel::from_string(s : String) -> LogLevel? {
  match s {
    "DEBUG" => Some(Debug)
    "INFO" => Some(Info)
    "WARN" => Some(Warn)
    "ERROR" => Some(Error)
    _ => None
  }
}

///|
/// 日志条目
///
/// 每条日志记录仿真时间、级别、消息和可选来源。
pub(all) struct LogEntry {
  time : Double
  level : LogLevel
  message : String
  source : String?
} derive(Debug, Eq)

///|
/// 仿真日志器
///
/// 提供分级日志（Debug/Info/Warn/Error），可挂载为插件自动记录仿真步。
/// 日志条目存于内存数组，也可通过 sink 回调实时输出。
///
/// # Example
/// ```mbt check
/// test {
///   let logger = @monitor.new_logger(min_level=@monitor.Info)
///   logger.info("仿真开始")
///   logger.warn("资源紧张")
///   assert_eq(logger.length(), 2)
/// }
/// ```
pub(all) struct SimLogger {
  mut min_level : LogLevel
  entries : Array[LogEntry]
  mut sink : ((LogEntry) -> Unit)?
}

///|
/// 创建仿真日志器
///
/// `min_level` 指定最低记录级别，低于此级别的日志被丢弃。
pub fn new_logger(min_level~ : LogLevel) -> SimLogger {
  { min_level, entries: [], sink: None }
}

///|
/// 设置日志输出回调（每条日志触发）
pub fn SimLogger::set_sink(
  self : SimLogger,
  sink : ((LogEntry) -> Unit)?,
) -> Unit {
  self.sink = sink
}

///|
/// 设置最低日志级别
pub fn SimLogger::set_level(self : SimLogger, level : LogLevel) -> Unit {
  self.min_level = level
}

///|
/// 计算日志级别是否达到记录阈值
pub fn SimLogger::should_log(self : SimLogger, level : LogLevel) -> Bool {
  level._rank() >= self.min_level._rank()
}

///|
/// 计算已记录的日志条目数
pub fn SimLogger::length(self : SimLogger) -> Int {
  self.entries.length()
}

///|
/// 获取所有日志条目（只读视图）
pub fn SimLogger::entries(self : SimLogger) -> Array[LogEntry] {
  self.entries
}

///|
/// 清空日志
pub fn SimLogger::clear(self : SimLogger) -> Unit {
  self.entries.clear()
}

///|
/// 计算指定级别的日志条目数
pub fn SimLogger::count_by_level(self : SimLogger, level : LogLevel) -> Int {
  let mut n = 0
  for e in self.entries {
    if e.level == level {
      n = n + 1
    }
  }
  n
}

///|
/// 内部：写入一条日志
fn SimLogger::_write(
  self : SimLogger,
  time~ : Double,
  level~ : LogLevel,
  message~ : String,
  source~ : String?,
) -> Unit {
  if self.should_log(level) {
    let entry : LogEntry = { time, level, message, source }
    self.entries.push(entry)
    match self.sink {
      Some(s) => s(entry)
      None => ()
    }
  }
}

///|
/// 通用日志方法
pub fn SimLogger::log(
  self : SimLogger,
  level : LogLevel,
  message : String,
  time? : Double = 0.0,
  source? : String? = None,
) -> Unit {
  self._write(time~, level~, message~, source~)
}

///|
/// Debug 级别日志
pub fn SimLogger::debug(
  self : SimLogger,
  message : String,
  time? : Double = 0.0,
  source? : String? = None,
) -> Unit {
  self._write(time~, level=Debug, message~, source~)
}

///|
/// Info 级别日志
pub fn SimLogger::info(
  self : SimLogger,
  message : String,
  time? : Double = 0.0,
  source? : String? = None,
) -> Unit {
  self._write(time~, level=Info, message~, source~)
}

///|
/// Warn 级别日志
pub fn SimLogger::warn(
  self : SimLogger,
  message : String,
  time? : Double = 0.0,
  source? : String? = None,
) -> Unit {
  self._write(time~, level=Warn, message~, source~)
}

///|
/// Error 级别日志
pub fn SimLogger::error(
  self : SimLogger,
  message : String,
  time? : Double = 0.0,
  source? : String? = None,
) -> Unit {
  self._write(time~, level=Error, message~, source~)
}

///|
/// 将日志条目格式化为单行字符串
///
/// 格式：`[TIME] LEVEL [SOURCE] MESSAGE`（source 省略时不含方括号）
pub fn LogEntry::format(self : LogEntry) -> String {
  let prefix = "[" + self.time.to_string() + "] " + self.level.to_string()
  match self.source {
    Some(src) => prefix + " [" + src + "] " + self.message
    None => prefix + " " + self.message
  }
}

///|
/// 将全部日志导出为文本（每行一条）
pub fn SimLogger::export_text(self : SimLogger) -> String {
  let buf = StringBuilder::new()
  for e in self.entries {
    buf.write_string(e.format())
    buf.write_char('\n')
  }
  buf.to_string()
}

///|
/// 将全部日志导出为 JSON 数组字符串
///
/// 格式：`[{"time":..., "level":..., "message":..., "source":...}, ...]`
pub fn SimLogger::export_json(self : SimLogger) -> String {
  let buf = StringBuilder::new()
  buf.write_char('[')
  for i, e in self.entries {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string("{\"time\":")
    buf.write_string(e.time.to_string())
    buf.write_string(",\"level\":\"")
    buf.write_string(e.level.to_string())
    buf.write_string("\",\"message\":")
    buf.write_string(@json.to_json(e.message).stringify())
    buf.write_string(",\"source\":")
    match e.source {
      Some(src) => buf.write_string(@json.to_json(src).stringify())
      None => buf.write_string("null")
    }
    buf.write_char('}')
  }
  buf.write_char(']')
  buf.to_string()
}

///|
/// 按级别过滤日志
pub fn SimLogger::filter_by_level(
  self : SimLogger,
  level : LogLevel,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  for e in self.entries {
    if e.level == level {
      result.push(e)
    }
  }
  result
}

///|
/// 按时间范围过滤日志 [start, end)
pub fn SimLogger::filter_by_time(
  self : SimLogger,
  start~ : Double,
  end~ : Double,
) -> Array[LogEntry] {
  let result : Array[LogEntry] = []
  for e in self.entries {
    if e.time >= start && e.time < end {
      result.push(e)
    }
  }
  result
}

///|
/// 将 SimLogger 挂载为插件
///
/// 返回 PluginCallbacks，注册到 PluginManager 后：
/// - on_step：每个事件处理前记录 Debug 日志（含当前时间）
/// - on_event：事件触发后记录 Info 日志（含事件 ID 和时间）
/// - on_finish：仿真结束时记录 Info 日志
pub fn SimLogger::as_plugin(self : SimLogger) -> @plugin.PluginCallbacks {
  {
    on_step: fn(_env, time) {
      self._write(time~, level=Debug, message="step", source=Some("monitor"))
    },
    on_event: fn(_env, event) {
      self._write(
        time=event.time,
        level=Info,
        message="event #{event.id} triggered",
        source=Some("monitor"),
      )
    },
    on_finish: fn(env) {
      self._write(
        time=env.now(),
        level=Info,
        message="simulation finished",
        source=Some("monitor"),
      )
    },
  }
}
