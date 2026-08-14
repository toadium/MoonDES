# Changelog

本文件记录 MoonDES 所有版本的变更，遵循 [Keep a Changelog](https://keepachangelog.com/) 格式，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划变更（v0.2.0 — 工程基础设施加固）

#### Added
- 创建 `README.mbt.md`（含 `mbt check` 可执行示例），更新 `README.md` 为完整内容
- 添加 `.gitignore`（排除 `_build/`、`target/`、`.mooncakes/`、`.repos/` 等构建产物）
- 添加 `LICENSE`（Apache-2.0 全文）
- 初始化 `CHANGELOG.md`
- 添加 GitHub Actions CI 配置（`.github/workflows/ci.yml`）

#### Changed
- 填写 `moon.mod` 的 `repository` 字段为 `https://github.com/toadium/MoonDES`

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

### Known Issues
- Process 协程语义未真正实现：`timeout` 不挂起进程，`behavior` 一次性执行完毕
- Experiment `event_count` 硬编码为 0，无 `rollback`，无序列化
- Resource `Preemptive` 抢占逻辑未实现
- Plugin `on_step` / `on_event` 未集成到仿真主循环
- `moon.mod` 的 `readme` 字段指向不存在的 `README.mbt.md`（v0.2.0 修复）
- 无 `.gitignore`、无 `LICENSE` 文件、无 CI 配置（v0.2.0 修复）