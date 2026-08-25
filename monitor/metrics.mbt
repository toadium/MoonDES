///|
/// 指标类型
pub(all) enum MetricKind {
  Counter
  Gauge
  Histogram
} derive(Debug, Eq)

///|
/// 指标快照条目
pub(all) struct MetricEntry {
  name : String
  kind : MetricKind
  value : Double
} derive(Debug, Eq)

///|
/// 直方图统计摘要
pub(all) struct HistogramSummary {
  count : Int
  sum : Double
  mean : Double
  min : Double
  max : Double
} derive(Debug, Eq)

///|
/// 指标采集器
///
/// 提供 Counter（累加）、Gauge（瞬时值）、Histogram（观测序列）三类指标。
/// 可挂载为插件自动采集仿真时间和事件计数。
///
/// # Example
/// ```mbt check
/// test {
///   let m = @monitor.new_metrics()
///   m.incr("events")
///   m.incr("events")
///   m.set_gauge("utilization", value=0.75)
///   m.observe("latency", value=12.0)
///   assert_eq(m.get_counter("events"), Some(2.0))
///   assert_eq(m.get_gauge("utilization"), Some(0.75))
/// }
/// ```
pub(all) struct MetricsCollector {
  counters : Map[String, Double]
  gauges : Map[String, Double]
  histograms : Map[String, Array[Double]]
}

///|
/// 创建指标采集器
pub fn new_metrics() -> MetricsCollector {
  { counters: Map([]), gauges: Map([]), histograms: Map([]) }
}

///|
/// Counter 递增（默认步长 1.0）
pub fn MetricsCollector::incr(
  self : MetricsCollector,
  name : String,
  by? : Double = 1.0,
) -> Unit {
  let cur = match self.counters.get(name) {
    Some(v) => v
    None => 0.0
  }
  self.counters[name] = cur + by
}

///|
/// 设置 Gauge 值
pub fn MetricsCollector::set_gauge(
  self : MetricsCollector,
  name : String,
  value~ : Double,
) -> Unit {
  self.gauges[name] = value
}

///|
/// Histogram 观测一次
pub fn MetricsCollector::observe(
  self : MetricsCollector,
  name : String,
  value~ : Double,
) -> Unit {
  match self.histograms.get(name) {
    Some(arr) => arr.push(value)
    None => self.histograms[name] = [value]
  }
}

///|
/// 获取 Counter 值
pub fn MetricsCollector::get_counter(
  self : MetricsCollector,
  name : String,
) -> Double? {
  self.counters.get(name)
}

///|
/// 获取 Gauge 值
pub fn MetricsCollector::get_gauge(
  self : MetricsCollector,
  name : String,
) -> Double? {
  self.gauges.get(name)
}

///|
/// 获取 Histogram 所有观测值
pub fn MetricsCollector::get_histogram(
  self : MetricsCollector,
  name : String,
) -> Array[Double]? {
  self.histograms.get(name)
}

///|
/// 获取 Counter 数量
pub fn MetricsCollector::counter_count(self : MetricsCollector) -> Int {
  self.counters.length()
}

///|
/// 获取 Gauge 数量
pub fn MetricsCollector::gauge_count(self : MetricsCollector) -> Int {
  self.gauges.length()
}

///|
/// 获取 Histogram 数量
pub fn MetricsCollector::histogram_count(self : MetricsCollector) -> Int {
  self.histograms.length()
}

///|
/// 计算 Histogram 统计摘要
pub fn MetricsCollector::histogram_summary(
  self : MetricsCollector,
  name : String,
) -> HistogramSummary? {
  match self.histograms.get(name) {
    Some(arr) =>
      if arr.length() == 0 {
        None
      } else {
        let mut sum = 0.0
        let mut mn = arr[0]
        let mut mx = arr[0]
        for v in arr {
          sum = sum + v
          if v < mn {
            mn = v
          }
          if v > mx {
            mx = v
          }
        }
        let n = arr.length()
        Some({ count: n, sum, mean: sum / n.to_double(), min: mn, max: mx })
      }
    None => None
  }
}

///|
/// 导出所有指标为快照列表
pub fn MetricsCollector::snapshot(
  self : MetricsCollector,
) -> Array[MetricEntry] {
  let result : Array[MetricEntry] = []
  for k, v in self.counters {
    result.push({ name: k, kind: Counter, value: v })
  }
  for k, v in self.gauges {
    result.push({ name: k, kind: Gauge, value: v })
  }
  for k, arr in self.histograms {
    let mut sum = 0.0
    for v in arr {
      sum = sum + v
    }
    result.push({ name: k, kind: Histogram, value: sum })
  }
  result
}

///|
/// 导出指标为 JSON 字符串
///
/// 格式：`{"counters":{...},"gauges":{...},"histograms":{...}}`
pub fn MetricsCollector::export_json(self : MetricsCollector) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\"counters\":{")
  let mut first = true
  for k, v in self.counters {
    if !first {
      buf.write_char(',')
    }
    first = false
    buf.write_string(@json.to_json(k).stringify())
    buf.write_char(':')
    buf.write_string(v.to_string())
  }
  buf.write_string("},\"gauges\":{")
  first = true
  for k, v in self.gauges {
    if !first {
      buf.write_char(',')
    }
    first = false
    buf.write_string(@json.to_json(k).stringify())
    buf.write_char(':')
    buf.write_string(v.to_string())
  }
  buf.write_string("},\"histograms\":{")
  first = true
  for k, arr in self.histograms {
    if !first {
      buf.write_char(',')
    }
    first = false
    buf.write_string(@json.to_json(k).stringify())
    buf.write_char(':')
    buf.write_char('[')
    for i, v in arr {
      if i > 0 {
        buf.write_char(',')
      }
      buf.write_string(v.to_string())
    }
    buf.write_char(']')
  }
  buf.write_string("}}")
  buf.to_string()
}

///|
/// 重置所有指标
pub fn MetricsCollector::reset(self : MetricsCollector) -> Unit {
  self.counters.clear()
  self.gauges.clear()
  self.histograms.clear()
}

///|
/// 将 MetricsCollector 挂载为插件
///
/// 自动采集：
/// - on_step：更新 `sim_time` Gauge 为当前仿真时间
/// - on_event：递增 `event_count` Counter
/// - on_finish：更新 `sim_time` Gauge 为最终时间
pub fn MetricsCollector::as_plugin(
  self : MetricsCollector,
) -> @plugin.PluginCallbacks {
  {
    on_step: fn(env, _time) { self.set_gauge("sim_time", value=env.now()) },
    on_event: fn(_env, _event) { self.incr("event_count") },
    on_finish: fn(env) {
      self.set_gauge("sim_time", value=env.now())
      self.set_gauge("final_time", value=env.now())
    },
  }
}
