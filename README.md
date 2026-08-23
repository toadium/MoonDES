# MoonDES

[![CI](https://github.com/toadium/MoonDES/actions/workflows/ci.yml/badge.svg)](https://github.com/toadium/MoonDES/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-1.7.0-blue.svg)](https://github.com/toadium/MoonDES/releases)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](./LICENSE)
[![Tests](https://img.shields.io/badge/tests-255%20passed-brightgreen.svg)](https://github.com/toadium/MoonDES/actions/workflows/ci.yml)
[![Backends](https://img.shields.io/badge/backends-native%20%7C%20wasm--gc%20%7C%20wasm-blue.svg)](https://github.com/toadium/MoonDES)

> 通用离散事件仿真引擎，基于国产 MoonBit 编译型语言构建。

MoonDES 提供十一层模块化架构的离散事件仿真能力，对标 Python SimPy 与 Java DESMO-J，面向工业数字化、智慧管网、生产调度等工程仿真场景。

## 特性

- **最小堆优先级事件队列**：按 `(time, priority)` 排序，保证时序正确性
- **协程进程调度**：进程可 `timeout` / `wait_event` / `request_resource`，挂起恢复不占用线程
- **三类资源模型**：独占式 `Exclusive` / 共享容量 `Capacity` / 优先级抢占 `Preemptive`
- **高级资源**：资源池 `ResourcePool` / 可重入资源 `ReentrantResource` / 资源组 `ResourceGroup`
- **实验管理**：批量仿真、参数遍历、快照保存、断点回滚、结果统计
- **插件扩展接口**：标准化 `on_step` / `on_event` / `on_finish` 生命周期回调
- **随机数采样**：均匀 / 指数 / 正态（Box-Muller）/ 泊松 / 伯努利 / 离散均匀六种分布
- **统计聚合**：均值 / 方差 / 标准差 / 直方图 / 协方差 / 相关系数
- **监控可观测**：分级日志 `SimLogger` / 指标采集 `MetricsCollector` / Chrome Trace 导出 `TraceExporter`
- **分布式仿真**：多环境管理 `MultiEnv` / 任务调度 `TaskScheduler` / 结果聚合 `ResultAggregator`
- **进程同步原语**：信号事件 `SignalEvent` / 条件组合 `any_of`/`all_of` / 信号量 `Semaphore` / 屏障 `Barrier` / 连续容器 `Container` / 物品仓库 `Store[T]` / 优先级仓库 `PriorityStore[T]`
- **仿真分析与报告**：事件时间线 `EventTimeline` / 资源追踪 `ResourceTracker` / 综合报告 `SimulationReport`
- **多实例并行**：仿真环境无全局共享状态，天然支持并行仿真
- **跨后端**：一次开发，编译为 Native / WASI / WASM 三种部署形态

## 快速开始

### 环境要求

- MoonBit 工具链（`moon` 命令行工具）

### 安装

```bash
moon add walkzzz/moondes
```

### 最小示例

```moonbit
let env = @moondes.new_env(until=10.0)
ignore(env.schedule(time=2.0, callback=fn() { println("event@2.0") }))
env.run()
```

### 运行示例工程

```bash
moon run examples/hello_des        # 最简事件调度
moon run examples/mm1_queue        # M/M/1 排队系统
moon run examples/resource_sharing # 实验管理与插件
moon run examples/benchmark        # 性能基准测试
```

## 项目结构

```
MoonDES/
├── core/          # 层级1：仿真内核（SimulationEnv / EventQueue / Event）
├── process/       # 层级2：协程进程调度（Process / timeout / wait_event）
├── resource/      # 层级3：资源管理（Exclusive / Capacity / Preemptive / Pool / Reentrant / Group）
├── experiment/    # 层级4：实验管理（ExpConfig / ExpResult / Snapshot）
├── plugin/        # 层级5：插件接口（PluginManager / PluginCallbacks）
├── random/        # 层级6：随机数采样（uniform / exponential / normal / poisson / bernoulli / randint）
├── stats/         # 层级7：统计聚合（sum / mean / variance / stddev / histogram / correlation）
├── monitor/       # 层级8：监控可观测（SimLogger / MetricsCollector / TraceExporter）
├── distributed/   # 层级9：分布式仿真（MultiEnv / TaskScheduler / ResultAggregator）
├── sync/          # 层级10：进程同步原语（SignalEvent / Semaphore / Barrier / Container）
├── analysis/      # 层级11：仿真分析与报告（EventTimeline / ResourceTracker / SimulationReport）
├── examples/      # 可执行示例
│   ├── hello_des/
│   ├── mm1_queue/
│   ├── resource_sharing/
│   └── benchmark/
└── docs/          # 项目文档
```

### 依赖层级

```
core (无依赖) ← process / resource / experiment / plugin / random / stats / monitor / distributed / sync / analysis
```

所有上层包仅依赖 `core`，无循环依赖。

## API 概览

| 便捷入口 | 说明 |
|---------|------|
| `new_env(until=)` | 创建仿真环境 |
| `process(env, behavior=)` | 创建仿真进程 |
| `new_exclusive(name=)` | 创建独占式资源 |
| `new_config(until=, seed=)` | 创建实验配置 |
| `new_plugin_manager()` | 创建插件管理器 |
| `new_rng()` | 创建随机数生成器 |
| `summary(data)` | 计算统计摘要 |
| `new_logger(min_level=)` | 创建仿真日志器 |
| `new_metrics()` | 创建指标采集器 |
| `new_tracer()` | 创建 Trace 导出器 |
| `new_multi_env()` | 创建多环境管理器 |
| `new_task_scheduler()` | 创建任务调度器 |
| `new_aggregator()` | 创建结果聚合器 |
| `new_signal()` | 创建信号事件 |
| `new_semaphore()` | 创建计数信号量 |
| `new_barrier()` | 创建同步屏障 |
| `new_container()` | 创建连续资源容器 |
| `any_of()` | 条件组合：等待任意信号 |
| `all_of()` | 条件组合：等待全部信号 |
| `new_store[T]()` | 创建 FIFO 物品仓库 |
| `new_priority_store[T]()` | 创建优先级物品仓库 |
| `new_timeline()` | 创建事件时间线 |
| `new_resource_tracker()` | 创建资源追踪器 |
| `new_report()` | 创建仿真报告生成器 |
| `version()` | 引擎版本号 |

## 测试

```bash
moon check              # 类型检查
moon test --target native  # 运行测试
moon info               # 生成 API 接口文件
```

## 贡献指南

1. Fork 仓库并创建特性分支：`git checkout -b feature/your-feature`
2. 遵循约定式提交：`feat:` / `fix:` / `docs:` / `refactor:`
3. 确保 `moon check` 与 `moon test` 全部通过
4. 公开 API 必须附 `///` 文档注释
5. 新增功能必须配套单元测试
6. 提交 Pull Request

## 路线图

详见 [roadmap.md](./roadmap.md)。

## 许可证

[Apache-2.0](./LICENSE)

## 致谢

- [MoonBit](https://www.moonbitlang.com/) — 国产编译型编程语言
- 仿真引擎设计参考：SimPy（协程调度内核）、DESMO-J（实验分层架构）
