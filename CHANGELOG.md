# Changelog

本文件记录 MoonDES 所有版本的变更，遵循 [Keep a Changelog](https://keepachangelog.com/) 格式，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划变更（v2.0.0 — API 演进）

- 如有破坏性变更，经充分评估后发布

## [1.8.0] - 2026-08-23

### 进程增强与经典示例

#### Added
- `Process::interrupt()` — 中断挂起的进程，下次恢复时终止而非继续
- `Process::is_interrupted()` — 查询中断状态
- `Process::on_complete(callback)` — 注册完成回调（join 语义），进程终止时触发
- `Process::status()` — 查询进程状态
- 经典示例 `dining_philosophers`：5 位哲学家就餐（Semaphore）
- 经典示例 `producer_consumer`：生产者-消费者（Store[T]）
- 11 个新测试（interrupt/join/status）

#### 验证

- `moon test` 266/266 全通过，零警告

## [1.7.0] - 2026-08-23

### Store & PriorityStore — 完成 SimPy 等价同步原语全集

#### Added
- 在 `sync` 包中新增 `Store[T]`：泛型 FIFO 物品仓库
  - `put(item)` 投递物品，有等待消费者时直接投递
  - `get(callback)` 取出物品，仓库空时阻塞等待
  - `size()` / `is_empty()` / `consumer_count()` / `clear()`
- 在 `sync` 包中新增 `PriorityStore[T]`：泛型优先级物品仓库
  - `put(item, priority)` 按优先级排序存储（数值越小越先取出）
  - `get(callback)` 取出最高优先级物品
  - `PriorityItem[T]` 数据结构
  - `size()` / `is_empty()` / `consumer_count()` / `clear()`
- 根包新增便捷入口 `new_store[T]()` / `new_priority_store[T]()`
- 19 个新测试（sync 包）+ 2 个根包便捷入口测试
- 完成 SimPy 等价同步原语全集：SignalEvent / any_of / all_of / Semaphore / Barrier / Container / Store / PriorityStore

#### 验证

- `moon test --target wasm` 255/255 全通过
- `moon check` 零警告
- `moon fmt` 格式一致
- `moon info` API 接口已更新

## [1.6.0] - 2026-08-23

### 仿真分析与报告

#### Added
- 新增 `analysis` 包：仿真结果分析与报告生成
  - `EventTimeline`：结构化事件时间线，支持 `record`/`filter_by_category`/`filter_by_time_range`/`filter_by_name`/`export_json`/`export_text`/`as_plugin`
  - `ResourceTracker`：资源分配追踪器，`on_acquire`/`on_release` 生成甘特图数据，`utilization`/`avg_utilization` 利用率计算，`export_json`/`export_text` 导出
  - `SimulationReport`：综合报告生成器，整合环境统计 + 时间线 + 资源数据，`generate_text` 文本报告 + `generate_json` JSON 报告
  - `TimelineEntry`/`GanttEntry`：数据结构
- 根包新增便捷入口 `new_timeline` / `new_resource_tracker` / `new_report`
- 29 个新测试（analysis 包）+ 3 个根包便捷入口测试
- 更新架构描述从"十层"到"十一层"（新增 analysis）

#### 验证

- `moon test --target wasm` 234/234 全通过
- `moon check` 零警告
- `moon fmt` 格式一致
- `moon info` API 接口已更新

## [1.5.0] - 2026-08-23

### 进程同步原语

#### Added
- 新增 `sync` 包：进程同步原语，对标 SimPy 的 Events/Conditions/Containers
  - `SignalEvent`：手动触发事件，不绑定仿真时间，支持 `fire`/`wait`/`is_fired`，已触发后 `wait` 立即执行
  - `any_of`：条件组合，等待任意信号触发即触发结果（适用于"等待多个资源中任意一个可用"）
  - `all_of`：条件组合，等待全部信号触发才触发结果（适用于"等待所有前置条件就绪"）
  - `Semaphore`：计数信号量，`acquire`/`release`，许可耗尽时阻塞等待
  - `Barrier`：进程同步屏障，N 个进程到达后统一释放，自动重置支持多轮使用
  - `Container`：连续资源容器，`put`/`get` 操作，满时阻塞生产者、空时阻塞消费者，自动唤醒级联等待
  - `ContainerWaiter`：容器等待请求结构
- 根包新增便捷入口 `new_signal` / `new_semaphore` / `new_barrier` / `new_container` / `any_of` / `all_of`
- 33 个新测试（sync 包）+ 6 个根包便捷入口测试
- 更新架构描述从"九层"到"十层"（新增 sync）

#### 验证

- `moon test --target wasm` 202/202 全通过
- `moon test --target wasm-gc` 202/202 全通过
- `moon check` 零警告
- `moon fmt` 格式一致
- `moon info` API 接口已更新

## [1.4.0] - 2026-08-22

### 分布式仿真

#### Added
- 新增 `distributed` 包：分布式仿真支持
  - `MultiEnv`：多环境管理器，批量创建/注册/运行多个独立 SimulationEnv，收集时间和事件计数
  - `TaskScheduler`：任务调度器，按优先级排序执行仿真任务，支持 `submit`/`run_all`/`run_all_detailed`/`peek_tasks`
  - `ResultAggregator`：结果聚合器，跨多次实验运行结果统计聚合（均值/标准差/最小/最大/方差），支持命名指标
  - `SimTask`/`TaskResult`：任务和结果数据结构
- 根包新增便捷入口 `new_multi_env` / `new_task_scheduler` / `new_aggregator`
- 22 个新测试（distributed 包）+ 3 个根包便捷入口测试
- 修复 `moon.mod` 版本号不一致（0.8.0 → 1.4.0）
- 修复 README.mbt.md 版本徽章过期（0.1.0 → 1.4.0）
- 修复安装命令错误（`moon add moondes/moondes` → `moon add walkzzz/moondes`）
- 更新架构描述从"五层"到"九层"（新增 random/stats/monitor/distributed）

#### 验证

- `moon test --target wasm` 163/163 全通过
- `moon test --target wasm-gc` 163/163 全通过
- `moon check --target all` 三后端编译通过
- `moon fmt` 格式一致
- `moon info` API 接口已更新

## [1.3.0] - 2026-08-16

### 监控与可观测

#### Added
- `SimLogger`：分级日志（Debug/Info/Warn/Error），支持 `set_sink` 实时输出回调、`filter_by_level`/`filter_by_time` 过滤、`export_text`/`export_json` 导出
- `MetricsCollector`：指标采集器，Counter（累加）/Gauge（瞬时值）/Histogram（观测序列），支持 `histogram_summary` 统计摘要、`snapshot` 快照、`export_json` 导出
- `TraceExporter`：Chrome Trace Event 格式导出器，支持 `begin`/`end`/`complete`/`instant` 四类事件、`export_json`（chrome://tracing 兼容）/`export_csv` 导出
- 三组件均支持 `as_plugin()` 挂载为 `PluginCallbacks`，自动采集仿真步、事件、结束数据
- 根包便捷入口 `new_logger` / `new_metrics` / `new_tracer`
- 28 个新测试
- `monitor/README.mbt.md` 文档

#### 验证

- `moon test --target all` 138/138 全通过（三后端）
- `moon check` 0 警告

## [1.2.0] - 2026-08-16

### 高级资源

#### Added
- `ResourcePool`：多同类资源池，自动分配空闲槽位，`request`/`release`/`available_count`/`holder_slot`
- `ReentrantResource`：可重入资源，同进程多次获取（计数累加），对应次数释放，`hold_count_of`/`is_free`
- `ResourceGroup`：资源组，原子批量获取/释放（任一不可用则全部不获取），`request_all`/`release_all`/`acquired_count`
- 8 个新测试

#### 验证

- `moon test --target all` 106/106 全通过（三后端）
- `moon check` 0 警告

- 资源池、可重入资源、资源组

## [1.1.0] - 2026-08-16

### 随机数与统计

#### Added
- 新增 `random` 包：基于标准库 ChaCha8 的分布采样
  - `uniform` / `exponential` / `normal`（Box-Muller）/ `poisson`（Knuth）/ `bernoulli` / `randint`
- 新增 `stats` 包：统计聚合
  - `sum` / `mean` / `variance` / `stddev` / `min` / `max` / `histogram` / `summary` / `covariance` / `correlation`
- 根包新增便捷入口 `new_rng` / `summary`
- 15 个新测试（random 6 + stats 9）
- README.mbt.md（random + stats）

#### Changed
- 版本号更新为 1.1.0
- 根包导入新增 `random` / `stats` / `moonbitlang/core/random`

#### 验证

- `moon test --target all` 90/90 全通过（三后端）
- `moon check` 0 警告

## [1.0.0] - 2026-08-15

### 正式版发布（API 冻结）

#### Added
- 撰写发布说明 `RELEASE_NOTES_v1.0.0.md`
- README 徽章更新：version 1.0.0 / tests 70 / backends native|wasm-gc|wasm

#### Changed
- `moon.mod` 版本号从 `0.1.0` 更新为 `1.0.0`

#### API 审查结论

- 公共 API 经审查冻结，后续 v1.x 保持向后兼容
- 无需要标注 `#deprecated` 的旧别名
- 五层模块公共 API 表面：
  - **core**：SimulationEnv / EventQueue / Event / EnvSnapshot / EnvStatus
  - **process**：Process / ProcessAction / ProcessStatus
  - **resource**：Resource / ResourceRequest / ResourceKind
  - **experiment**：ExpConfig / ExpResult / Snapshot（含序列化）
  - **plugin**：PluginManager / PluginCallbacks

#### 验证

- `moon check` 通过，0 警告
- `moon test --target all` 70/70 全通过（三后端）
- `moon fmt` 通过
- `moon info` API 接口已生成并纳入版本控制

## [0.5.0] - 2026-08-15

### 性能优化与跨后端验证（修复 P1-4 序列化补齐）

#### Added
- 引入 `@json` 依赖（core + experiment 包），实现序列化/反序列化
- `ExpConfig` / `ExpResult` / `Snapshot` derive(ToJson) + impl FromJson
- `EnvSnapshot` / `EnvStatus` derive(ToJson) + impl FromJson
- 便捷函数 `to_json_string` / `from_json_string`（ExpConfig / ExpResult / Snapshot）
- `EventQueue::new_queue_with_capacity` 预分配容量构造函数
- 基准测试示例 `examples/benchmark`：100000 事件调度 + 10000 并发进程 + M/M/1 排队
- 4 个序列化往返测试

#### Changed
- `EventQueue::pop` 用 `Array::pop()` 代替 `Array::remove(n-1)`（O(1) 移除末尾）
- `EventQueue::_sift_down` 用 `for ;;` 代替 `while true`
- `SimulationEnv::run` 合并双分支时间校正为单 `!=` 判断

#### 验证

- `moon check --target all` 三后端编译通过（native / wasm-gc / wasm）
- `moon test --target all` 70/70 全通过（三后端）
- 基准测试：100000 事件 + 10000 进程正确调度
- 序列化往返测试通过

## [0.4.0] - 2026-08-15

### 测试与文档完善（修复 P2-1 ~ P2-6）

#### Added
- 为 5 个子包（core / process / resource / experiment / plugin）创建 `README.mbt.md`，含 `mbt check` 可执行示例
- 为根包创建 `README.mbt.md`，含 `mbt check` 可执行示例
- 新增 `moondes_test.mbt` 根包便捷入口测试（6 个）
- 补充边界测试：空环境、零时长、负优先级、多实例独立运行
- 补充压力测试：1000 事件调度
- 补充快照-回滚往返测试

#### Changed
- 测试数 45 → 66，全部通过
- `moon coverage analyze` 完成：42 行未覆盖，均为边界 None 分支 / peek-pop 空队列 / 示例 main

### 验证

- `moon check` 通过，0 警告
- `moon test --target native` 66/66 通过
- `moon fmt` 通过
- `moon info` API 无非预期变化

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
