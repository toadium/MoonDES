# MoonDES

[![CI](https://github.com/toadium/MoonDES/actions/workflows/ci.yml/badge.svg)](https://github.com/toadium/MoonDES/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-2.8.0-blue.svg)](https://github.com/toadium/MoonDES/releases)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](./LICENSE)
[![Tests](https://img.shields.io/badge/tests-395%20passed-brightgreen.svg)](https://github.com/toadium/MoonDES/actions/workflows/ci.yml)
[![Backends](https://img.shields.io/badge/backends-native%20%7C%20wasm--gc%20%7C%20wasm-blue.svg)](https://github.com/toadium/MoonDES)

> 通用离散事件仿真引擎，基于国产 MoonBit 编译型语言构建。

MoonDES 提供十七层模块化架构的离散事件仿真能力，对标 Python SimPy 与 Java DESMO-J，面向工业数字化、智慧管网、生产调度等工程仿真场景。

## 特性

- **最小堆优先级事件队列**：按 `(time, priority)` 排序，保证时序正确性
- **协程进程调度**：进程可 `timeout` / `wait_event` / `request_resource`，挂起恢复不占用线程；支持 `interrupt()` 中断和 `on_complete()` join 语义
- **三类资源模型**：独占式 `Exclusive` / 共享容量 `Capacity` / 优先级抢占 `Preemptive`
- **高级资源**：资源池 `ResourcePool` / 可重入资源 `ReentrantResource` / 资源组 `ResourceGroup`
- **实验管理**：批量仿真、参数遍历、快照保存、断点回滚、结果统计
- **插件扩展接口**：标准化 `on_step` / `on_event` / `on_finish` 生命周期回调
- **随机数采样**：均匀 / 指数 / 正态（Box-Muller）/ 泊松 / 伯努利 / 离散均匀六种分布
- **统计聚合**：均值 / 方差 / 标准差 / 直方图 / 协方差 / 相关系数
- **监控可观测**：分级日志 `SimLogger` / 指标采集 `MetricsCollector` / Chrome Trace 导出 `TraceExporter`
- **分布式仿真**：多环境管理 `MultiEnv` / 任务调度 `TaskScheduler` / 结果聚合 `ResultAggregator`
- **进程同步原语**：信号事件 `SignalEvent` / 条件组合 `any_of`/`all_of` / 信号量 `Semaphore` / 屏障 `Barrier` / 连续容器 `Container` / 物品仓库 `Store[T]` / 优先级仓库 `PriorityStore[T]` / 过滤仓库 `FilterStore[T]`
- **仿真分析与报告**：事件时间线 `EventTimeline` / 资源追踪 `ResourceTracker` / 综合报告 `SimulationReport`
- **网络仿真**：数据包 `Packet` / 延迟链路 `Link` / 双向通道 `Channel` / 路由转发 `Router`
- **有限状态机**：状态 `State` / 转换 `Transition` / 状态机 `StateMachine`（on_enter/on_exit 回调、guard 条件、历史轨迹）
- **事件总线**：发布订阅 `EventBus`（subscribe/publish/unsubscribe，topic 隔离，解耦通信）
- **定时器**：周期触发 `Timer`（start/stop，自重调度，有限次/无限次）
- **序列化**：仿真快照 `SimulationSnapshot`（to_json/summary，进程/FSM/统计状态捕获）
- **流水线**：多阶段处理 `Pipeline`（add_stage/瓶颈分析/总处理时间）
- **性能基准**：事件吞吐量 / 进程扩展性 / 资源竞争 / 同步原语规模
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
moon run examples/hello_des              # 最简事件调度
moon run examples/mm1_queue              # M/M/1 排队系统
moon run examples/resource_sharing       # 实验管理与插件
moon run examples/benchmark              # 性能基准测试
moon run examples/dining_philosophers    # 哲学家就餐（Semaphore）
moon run examples/producer_consumer      # 生产者-消费者（Store[T]）
moon run examples/network_simulation    # 3 节点网络仿真（Link/Router）
moon run examples/monte_carlo_pi        # Monte Carlo 估算 PI（Random+Stats）
moon run examples/mmc_queue             # M/M/c 多服务台队列（Resource+Random+Stats）
moon run examples/factory_machine       # 工厂设备状态机（FSM+Process+Random）
moon run examples/sensor_network       # 传感器网络（EventBus+Process+Random）
moon run examples/traffic_system       # 交通系统（FSM+EventBus+Timer+Stats）
moon run examples/elevator_dispatch    # 电梯调度（FSM+ProcessGroup+EventBus+Stats）
moon run examples/hospital_er         # 医院急诊（FSM+Resource+EventBus+Stats）
moon run examples/water_treatment     # 自来水厂（Pipeline+Resource+FSM+EventBus+Timer+Stats）
moon run examples/sewage_treatment    # 污水处理厂（Pipeline+Resource+FSM+EventBus+Stats）
```

## 项目结构

```
MoonDES/
├── core/          # 层级1：仿真内核（SimulationEnv / EventQueue / Event）
├── process/       # 层级2：协程进程调度（Process / timeout / wait_event / interrupt / on_complete）
├── resource/      # 层级3：资源管理（Exclusive / Capacity / Preemptive / Pool / Reentrant / Group）
├── experiment/    # 层级4：实验管理（ExpConfig / ExpResult / Snapshot）
├── plugin/        # 层级5：插件接口（PluginManager / PluginCallbacks）
├── random/        # 层级6：随机数采样（uniform / exponential / normal / poisson / bernoulli / randint）
├── stats/         # 层级7：统计聚合（sum / mean / variance / stddev / histogram / correlation）
├── monitor/       # 层级8：监控可观测（SimLogger / MetricsCollector / TraceExporter）
├── distributed/   # 层级9：分布式仿真（MultiEnv / TaskScheduler / ResultAggregator）
├── sync/          # 层级10：进程同步原语（SignalEvent / Semaphore / Barrier / Container / Store[T] / PriorityStore[T]）
├── analysis/      # 层级11：仿真分析与报告（EventTimeline / ResourceTracker / SimulationReport）
├── network/       # 层级12：网络仿真（Packet / Link / Channel / Router）
├── fsm/           # 层级13：有限状态机（State / Transition / StateMachine）
├── eventbus/      # 层级14：事件总线（EventBus 发布订阅）
├── timer/          # 层级15：定时器（Timer 周期触发）
├── serialize/     # 层级16：序列化（SimulationSnapshot 快照）
├── pipeline/      # 层级17：流水线（Pipeline 多阶段处理）
├── bench/         # 性能基准测试套件
├── examples/      # 可执行示例
│   ├── hello_des/
│   ├── mm1_queue/
│   ├── resource_sharing/
│   ├── benchmark/
│   ├── dining_philosophers/
│   ├── producer_consumer/
│   ├── network_simulation/
│   ├── monte_carlo_pi/
│   ├── mmc_queue/
│   ├── factory_machine/
│   ├── sensor_network/
│   ├── traffic_system/
│   ├── elevator_dispatch/
│   ├── hospital_er/
│   ├── water_treatment/
│   └── sewage_treatment/
└── docs/          # 项目文档
```

### 依赖关系

```
core (无依赖) ← process / resource / experiment / plugin / random / stats / monitor / distributed / sync / analysis
```

## API 概览

| 函数 / 类型 | 说明 |
|---|---|
| `new_env(until)` | 创建仿真环境 |
| `env.schedule(time, callback)` | 调度事件 |
| `env.run()` / `env.step()` | 运行 / 单步推进 |
| `env.now()` / `env.event_count()` | 当前时间 / 事件计数 |
| `process(env, name, behavior)` | 创建进程 |
| `Process::interrupt()` | 中断挂起进程 |
| `Process::on_complete(cb)` | 注册完成回调（join） |
| `new_exclusive` / `new_capacity` / `new_preemptive` | 创建资源 |
| `new_signal` / `any_of` / `all_of` | 信号事件与条件组合 |
| `new_semaphore` / `new_barrier` / `new_container` | 同步原语 |
| `new_store[T]()` / `new_priority_store[T]()` / `new_filter_store[T]()` | 物品仓库 |
| `new_timeline()` / `new_resource_tracker()` / `new_report()` | 分析与报告 |
| `new_link` / `new_channel` / `new_router` | 网络仿真 |
| `new_state_machine` / `transition` / `StateMachine::fire` | 有限状态机 |
| `new_event_bus` / `EventBus::subscribe` / `EventBus::publish` | 事件总线 |
| `new_timer` / `Timer::start` / `Timer::stop` | 定时器 |
| `new_snapshot` / `SimulationSnapshot::to_json` | 序列化 |
| `new_pipeline` / `Pipeline::add_stage` / `Pipeline::bottleneck` | 流水线 |
| `new_condition_variable` / `ConditionVariable::notify_all` | 条件变量 |
| `version()` | 引擎版本号 |

## SimPy 能力对照

| SimPy | MoonDES | 状态 |
|---|---|---|
| `Environment` | `SimulationEnv` | ✅ |
| `Process` | `Process` | ✅ |
| `process.interrupt()` | `Process::interrupt()` | ✅ |
| `Resource` | `Exclusive` / `Capacity` / `Preemptive` | ✅ |
| `Container` | `Container` | ✅ |
| `Store` | `Store[T]` | ✅ |
| `PriorityStore` | `PriorityStore[T]` | ✅ |
| `FilterStore` | `FilterStore[T]` | ✅ |
| `Event` | `SignalEvent` | ✅ |
| `AnyOf` / `AllOf` | `any_of` / `all_of` | ✅ |
| `Semaphore` | `Semaphore` | ✅ |
| `Condition` / `Barrier` | `Barrier` | ✅ |

## 开发

```bash
moon check          # 类型检查
moon test           # 运行测试（394 个）
moon fmt            # 格式化
moon info           # 更新接口文件
```

## 许可证

Apache-2.0
