# core — 仿真内核层

> MoonDES 层级1：提供仿真环境、事件队列、主仿真循环。

## API 概览

| 符号 | 说明 |
|------|------|
| `SimulationEnv` | 全局仿真环境 |
| `EventQueue` | 最小堆优先级事件队列 |
| `Event` | 仿真事件 |
| `EnvSnapshot` | 环境状态快照 |
| `new_env(until=)` | 创建仿真环境 |
| `new_queue()` | 创建空事件队列 |
| `new_event(id=, time=, callback=)` | 创建事件 |
| `SimulationEnv::run()` | 主仿真循环 |
| `SimulationEnv::step()` | 单步推进 |
| `SimulationEnv::schedule(time=, callback=)` | 调度事件 |
| `SimulationEnv::event_count()` | 已注册事件数 |
| `SimulationEnv::snapshot()` | 捕获状态快照 |
| `SimulationEnv::restore(snap)` | 从快照恢复 |

## 示例

```mbt check
///|
test {
  let env = new_env(until=10.0)
  inspect(env.now(), content="0")
  let log : Array[String] = []
  ignore(env.schedule(time=3.0, callback=fn() { log.push("A") }))
  ignore(env.schedule(time=1.0, callback=fn() { log.push("B") }))
  env.run()
  assert_eq(log[0], "B")
  assert_eq(log[1], "A")
  inspect(env.event_count(), content="2")
}
```

```mbt check
///|
test {
  let q = new_queue()
  inspect(q.is_empty(), content="true")
  let e = new_event(id=0, time=1.0, callback=fn() { () })
  q.push(e)
  inspect(q.length(), content="1")
}
```