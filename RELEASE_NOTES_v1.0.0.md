# MoonDES v1.0.0 发布说明

**发布日期**：2026-08-15
**版本**：1.0.0（正式版）
**许可证**：Apache-2.0

---

## 简介

MoonDES 是一个基于 MoonBit 构建的通用离散事件仿真引擎，提供进程调度、资源管理、实验管理和插件扩展等完整能力。本版本是首个正式发布版，API 已冻结，后续 v1.x 保持向后兼容。

---

## 核心特性

### 五层模块化架构

| 层 | 包 | 职责 |
|---|---|---|
| 仿真内核 | `core` | 仿真环境、事件队列、主循环 |
| 进程调度 | `process` | ProcessAction 指令式协程 |
| 资源管理 | `resource` | Exclusive / Capacity / Preemptive 三类资源 |
| 实验管理 | `experiment` | 配置、批量运行、快照回滚、序列化 |
| 插件扩展 | `plugin` | on_step / on_event / on_finish 生命周期钩子 |

### 关键能力

- **ProcessAction 指令式协程**：`Done` / `Timeout` / `WaitEvent` / `Terminate`，真正的挂起-恢复语义
- **Preemptive 资源抢占**：高优先级进程可中断低优先级持有者，`on_preempt` 回调
- **快照与回滚**：`EnvSnapshot` + `rollback` 断点回滚
- **JSON 序列化**：`ExpConfig` / `ExpResult` / `Snapshot` 支持 `to_json_string` / `from_json_string` 往返
- **插件自动集成**：`run` / `step` 自动触发 `on_step` / `on_event` / `on_finish`
- **三后端兼容**：native / wasm-gc / wasm 全部通过编译和测试

---

## 性能基准

```
Benchmark 1: Event Scheduling (100000 events)    — OK
Benchmark 2: Process Scheduling (10000 processes) — OK
Benchmark 3: M/M/1 Queue (10000 customers)        — OK
```

---

## 测试

- **70 个测试**全部通过（三后端：native / wasm-gc / wasm）
- `moon check` 0 警告
- `moon fmt` 通过
- `moon info` API 接口已生成

---

## 快速开始

```moonbit
let env = @core.new_env(until=100.0)
ignore(env.schedule(time=10.0, callback=fn() { println("Hello, MoonDES!") }))
env.run()
```

---

## 安装

```bash
moon add moondes/moondes@1.0.0
```

---

## 变更摘要

- v0.1.0：五层架构骨架 + 27 个测试
- v0.2.0：工程基础设施加固（README / LICENSE / CI / CHANGELOG）
- v0.3.0：核心功能补全（ProcessAction / Preemptive / Plugin 集成 / rollback）
- v0.4.0：测试与文档完善（66 个测试 + 包级 README）
- v0.5.0：性能优化 + 三后端验证 + JSON 序列化
- v1.0.0：API 冻结，正式发布

---

## 已知限制

- MoonBit 无 Generator，协程采用 ProcessAction 指令式 API（CPS 风格）
- `moon run --profile` 需要 macOS Instruments，Windows/Linux 暂不可用
- SimPy 性能对比待后续验证

---

## 后续规划

- v1.1.0：随机数与统计（RNG 抽象、分布采样）
- v1.2.0：高级资源（资源池、可重入资源）
- v1.3.0：监控与可观测（仿真日志、指标采集）
- v1.4.0：分布式仿真（多环境并行）