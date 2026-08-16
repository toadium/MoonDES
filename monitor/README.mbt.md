# Monitor — 监控与可观测

> MoonDES 监控与可观测层，提供仿真日志、指标采集和 trace 导出。

## 概览

| 组件 | 说明 |
|------|------|
| `SimLogger` | 分级日志（Debug/Info/Warn/Error），可挂载为插件 |
| `MetricsCollector` | 指标采集（Counter/Gauge/Histogram），可挂载为插件 |
| `TraceExporter` | Chrome Trace Event 格式导出（JSON/CSV），可挂载为插件 |

## 快速开始

### 仿真日志

```mbt check
///|
test {
  let logger = @monitor.new_logger(min_level=@monitor.Info)
  logger.info("仿真开始")
  logger.warn("资源紧张")
  assert_eq(logger.length(), 2)
}
```

### 指标采集

```mbt check
///|
test {
  let m = @monitor.new_metrics()
  m.incr("events")
  m.set_gauge("utilization", value=0.75)
  m.observe("latency", value=12.0)
  assert_eq(m.get_counter("events"), Some(1.0))
}
```

### Trace 导出

```mbt check
///|
test {
  let tracer = @monitor.new_tracer()
  tracer.begin("setup", ts=0.0)
  tracer.end("setup", ts=100.0)
  tracer.complete("step", ts=200.0, dur=50.0)
  assert_eq(tracer.length(), 3)
}
```

### 插件集成

```mbt check
///|
test {
  let env = @core.new_env(until=10.0)
  let pm = @plugin.new_manager()
  let logger = @monitor.new_logger(min_level=@monitor.Info)
  let metrics = @monitor.new_metrics()
  let tracer = @monitor.new_tracer()
  pm.register(logger.as_plugin())
  pm.register(metrics.as_plugin())
  pm.register(tracer.as_plugin())
  @plugin.attach(env, pm)
  ignore(env.schedule(time=2.0, callback=fn() { () }))
  env.run()
  assert_true(logger.length() > 0)
  assert_true(metrics.get_counter("event_count") is Some(_))
  assert_true(tracer.length() > 0)
}
```

## API 参考

### LogLevel

```moonbit nocheck
pub enum LogLevel { Debug | Info | Warn | Error }
```

### SimLogger

| 方法 | 说明 |
|------|------|
| `new_logger(min_level~)` | 创建日志器 |
| `debug/info/warn/error(msg, time?, source?)` | 分级日志 |
| `set_sink(callback)` | 设置实时输出回调 |
| `set_level(level)` | 动态调整级别 |
| `filter_by_level(level)` | 按级别过滤 |
| `filter_by_time(start~, end~)` | 按时间过滤 |
| `export_text()` | 导出为文本 |
| `export_json()` | 导出为 JSON 数组 |
| `as_plugin()` | 挂载为插件 |

### MetricsCollector

| 方法 | 说明 |
|------|------|
| `new_metrics()` | 创建采集器 |
| `incr(name, by?)` | Counter 递增 |
| `set_gauge(name, value~)` | 设置 Gauge |
| `observe(name, value~)` | Histogram 观测 |
| `get_counter/get_gauge/get_histogram(name)` | 获取值 |
| `histogram_summary(name)` | Histogram 统计摘要 |
| `snapshot()` | 导出快照 |
| `export_json()` | 导出为 JSON |
| `as_plugin()` | 挂载为插件 |

### TraceExporter

| 方法 | 说明 |
|------|------|
| `new_tracer()` | 创建导出器 |
| `begin/end(name, ts~, cat?, pid?, tid?)` | 持续时间事件 |
| `complete(name, ts~, dur~, cat?, pid?, tid?)` | 完整事件 |
| `instant(name, ts~, cat?, pid?, tid?)` | 瞬时事件 |
| `export_json()` | Chrome Trace JSON |
| `export_csv()` | CSV 格式 |
| `as_plugin()` | 挂载为插件 |

## 插件自动采集

挂载为插件后，三个组件自动采集：

| 钩子 | SimLogger | MetricsCollector | TraceExporter |
|------|-----------|------------------|---------------|
| `on_step` | Debug 日志 | `sim_time` Gauge | Instant 事件 |
| `on_event` | Info 日志 | `event_count` Counter | Complete 事件 |
| `on_finish` | Info 日志 | `final_time` Gauge | Instant 事件 |