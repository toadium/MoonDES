# process — 协程进程调度层

> MoonDES 层级2：基于 ProcessAction 指令式 API 实现协程式挂起-恢复。

## API 概览

| 符号 | 说明 |
|------|------|
| `Process` | 仿真进程 |
| `ProcessAction` | 进程动作指令 |
| `ProcessBehavior` | 行为函数类型 |
| `ProcessStatus` | 进程状态 |
| `process(env, behavior=)` | 创建进程 |
| `Done` | 进程完成 |
| `Timeout(duration=, next=)` | 延时后执行 next |
| `WaitEvent(event=, next=)` | 等待事件后执行 next |
| `Terminate` | 立即终止 |

## 示例

```mbt check
///|
test {
  let env = @core.new_env(until=20.0)
  let log : Array[String] = []
  ignore(
    process(env, name="timer", behavior=fn(_) {
      log.push("start at \{env.now()}")
      Timeout(duration=5.0, next=fn() {
        log.push("resume at \{env.now()}")
        Done
      })
    }),
  )
  env.run()
  assert_eq(log[0], "start at 0")
  assert_eq(log[1], "resume at 5")
}
```