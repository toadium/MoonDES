# Changelog

本文件记录 MoonDES 所有版本的变更，遵循 [Keep a Changelog](https://keepachangelog.com/) 格式，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划变更（v0.4.0 — 测试与文档完善）

- 为每个包添加黑盒测试 `*_wbtest.mbt`
- 为每个包创建 `README.mbt.md`（含 `mbt check` 可执行示例）
- 覆盖率分析，目标 ≥96%
- 边界测试与并发压力测试

## [0.3.0] - 2026-08-15

### 核心功能补全（修复 P1-1 ~ P1-7）

#### Process — ProcessAction 指令式协程语义 (P1-1)

- **Breaking**：`behavior` 类型从 `(Process) -> Unit` 改为 `(Process) -> ProcessAction`
- 新增 `ProcessAction` 枚举：`Done` /- `Timeout(duration, next)`：挂起进程，延时后执行 `next` 续延
  - `WaitEvent(event, next)`：挂起进程，事件触发后执行 `next` 续延
  - `Done` / `Terminate`：进程结束
- 新增 `ProcessBehavior` 类型别名
- 测试 3 → 7 个

#### Experiment — event_count 统计 + rollback (P1-2, P1-3)

- `run_experiment` / `snapshot` 统计真实 `event_count`（`env.event_count()`）
- core 新增 `EnvSnapshot` + `SimulationEnv::snapshot` / `restore` / `event_count`
- experiment 新增 `rollback(env, snapshot)` 断点回滚
- `Snapshot` 新增 `env_snapshot` 字段
- 测试 4 → 6 个

#### Resource — Preemptive 抢占 (P1-5)

- `Resource` 新增 `holder` 字段记录当前持有者
- `ResourceRequest` 新增 `on_preempt` 回调（被抢占时调用）
- `request` 新增 `on_preempt` 可选参数
- Preemptive 资源：高优先级请求抢占低优先级持有者，被抢占者重新入队
- 测试 4 → 7 个

#### Plugin — 集成主循环 (P1-6)

- `SimulationEnv` 新增 `on_step_hook` / `on_event_hook` / `on_finish_hook` 钩子字段
- core 新增 `_set_on_step_hook` / `_set_on_event_hook` / `_set_on_finish_hook` setter
- `run` / `step` 自动触发 `on_step`（事件处理前）、`on_event`（触发后）、`on_finish`（结束）
- `_finish` 保证 `on_finish` 仅调用一次
- `plugin::attach` 改为设置钩子（替代旧的调度结束事件方案）
- 测试 3 → 6 个

#### EventQueue — 边界修复 (P1-7)

- `remove_canceled` 添加 `length < 2` 显式提前返回
- 补充 4 个边界测试

### 验证

- `moon check` 通过，0 警告
- `moon test --target native` 45/45 通过
- `moon fmt` 通过
- `moon info` API 变更已记录

## [0.2.0] - 2026-08-15

### 工程基础设施加固（修复 P0-1 ~ P0-6）

#### Added
- 创建 `README.mbt.md`（含 `mbt check` 可执行示例），更新 `README.md` 为完整内容
- 添加 `.gitignore`（排除 `_build/`、`target/`、`.mooncakes/`、`.repos/` 等构建产物）
- 添加 `LICENSE`（Apache-2.0 全文）
- 初始化 `CHANGELOG.md`
- 添加 GitHub Actions CI 配置（`.github/workflows/ci.yml`）
- 添加 `roadmap.md` 迭代路线图

#### Changed
- 填写 `moon.mod` 的 `repository` 字段为 `https://github.com/toadium/MoonDES`
- 纳入全部源码至版本控制（50 文件，3749 行）

## [0.1.0] - 2026-08-14

### Added
- 五层模块化架构骨架：`core` / `process` / `resource` / `experiment` / `plugin`
- 根包聚合入口：`version` / `new_env` / `new_config` / `new_exclusive` / `process` / `new_plugin_manager`
- **core 层**：`SimulationEnv` 仿真环境、`EventQueue` 最小堆事件队列、`Event` 事件定义、主仿真循环 `run` / `step`
- **process 层**：`Process` 进程定义、`timeout` / `wait_event` / `terminate`
- **resource 层**：`Resource` 三类资源模型（`Exclusive` / `Capacity` / `Preemptive`）、`request` / `release` / 排队
- **experiment 层**：`ExpConfig` / `ExpResult` / `Snapshot`、`run_experiment` / `batch_run` / `param_sweep`
- **plugin 层**：`PluginManager` / `PluginCallbacks`、`register` / `notify_step` / `notify_event` / `notify_finish` / `attach`
- 三个可执行示例：`hello_des` / `mm1_queue` / `resource_sharing`
- 27 个单元测试（23 内部 + 4 doc test），全部通过
- 81 个公共 API，文档注释覆盖率 100%
- 项目规划文档：申报书、技术文档、品牌故事、审查报告、验证报告、一致性检查报告
