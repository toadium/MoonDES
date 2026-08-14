# resource — 资源管理层

> MoonDES 层级3：独占/容量/抢占三类资源模型。

## API 概览

| 符号 | 说明 |
|------|------|
| `Resource` | 通用资源 |
| `ResourceKind` | 资源类型（Exclusive / Capacity / Preemptive） |
| `ResourceRequest` | 资源申请请求 |
| `new_exclusive(name=)` | 创建独占式资源 |
| `new_capacity(name=, capacity=)` | 创建共享容量资源 |
| `new_preemptive(name=)` | 创建抢占式资源 |
| `Resource::request(pid=, callback=, on_preempt=)` | 请求资源 |
| `Resource::release()` | 释放资源 |
| `Resource::is_available()` | 资源是否可用 |

## 示例

```mbt check
///|
test {
  let res = new_exclusive(name="lock")
  inspect(res.is_available(), content="true")
  let granted = res.request(pid=1, callback=fn() { () })
  inspect(granted, content="true")
  inspect(res.is_available(), content="false")
  res.release()
  inspect(res.is_available(), content="true")
}
```

```mbt check
///|
test {
  let res = new_preemptive(name="channel")
  let log : Array[String] = []
  ignore(
    res.request(pid=1, priority=5, callback=fn() { log.push("low") }, on_preempt=fn() {
      log.push("preempted")
    }),
  )
  ignore(res.request(pid=2, priority=1, callback=fn() { log.push("high") }))
  assert_eq(log[1], "preempted")
  assert_eq(log[2], "high")
}
```