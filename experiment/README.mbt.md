# experiment — 实验管理层

> MoonDES 层级4：批量仿真、参数遍历、快照回滚、结果统计。

## API 概览

| 符号 | 说明 |
|------|------|
| `ExpConfig` | 实验配置 |
| `ExpResult` | 实验结果 |
| `Snapshot` | 仿真快照 |
| `new_config(until=, seed=)` | 创建实验配置 |
| `run_experiment(config)` | 运行单次实验 |
| `batch_run(configs)` | 批量运行 |
| `param_sweep(base=, param_name=, values=)` | 参数遍历 |
| `snapshot(env)` | 保存快照 |
| `rollback(env, snap)` | 断点回滚 |

## 示例

```mbt check
///|
test {
  let cfg = new_config(until=10.0, seed=42)
  inspect(cfg.until, content="10")
  let result = run_experiment(cfg)
  inspect(result.final_time, content="10")
}
```

```mbt check
///|
test {
  let env = @core.new_env(until=10.0)
  ignore(env.schedule(time=5.0, callback=fn() { () }))
  let snap = snapshot(env)
  inspect(snap.time, content="0")
  inspect(snap.event_count, content="1")
}
```