# MoonDES 迭代路线图 (Roadmap)

> **项目**：MoonDES — 通用离散事件仿真引擎
> **当前版本**：v0.3.0 (核心功能补全完成)
> **最后更新**：2026-08-15
> **对齐里程碑**：需求.md M1–M8（总周期 13 个月）

---

## 一、现状基线 (v0.3.0)

### 1.1 已完成

| 维度 | 状态 |
|------|------|
| 五层架构骨架 | core / process / resource / experiment / plugin 全部搭建 |
| 根包聚合入口 | 6 个便捷函数 (version / new_env / new_config / new_exclusive / process / new_plugin_manager) |
| 事件队列 | 最小堆实现，按 (time, priority) 排序，上浮/下沉完整，边界安全 |
| 仿真主循环 | SimulationEnv::run / step 可运行，集成插件钩子 |
| Process 协程 | ProcessAction 指令式 API，真正的挂起-恢复语义 |
| Resource 抢占 | Preemptive 资源高优先级抢占，on_preempt 回调 |
| Experiment | 真实 event_count 统计 + EnvSnapshot + rollback 断点回滚 |
| Plugin 集成 | on_step/on_event/on_finish 自动触发，全生命周期回调 |
| 示例工程 | hello_des / mm1_queue / resource_sharing 三个可执行示例 |
| 测试 | 45 个测试全部通过 (含 doc test) |
| 构建 | moon check 0 警告，moon test --target native 通过 |
| 文档注释 | 公共 API 100% 覆盖 /// 注释 |
| 工程基础设施 | README / .gitignore / LICENSE / CHANGELOG / CI / roadmap 齐全 |
| 规划文档 | 申报书 / 技术文档 / 品牌故事 / 审查报告 / 验证报告 齐全 |

### 1.2 已修复缺口

#### P0 — 工程基础设施（v0.2.0 全部修复 ✅）

| # | 问题 | 修复方式 |
|---|------|---------|
| P0-1 | `moon.mod` 的 readme 指向不存在的文件 | �3 创建 README.mbt.md（含 mbt check 示例）|
| P0-2 | 无 `.gitignore` | 添加 .gitignore 排除构建产物 |
| P0-3 | 源码未纳入 git | git add 全部源码，完整初始提交 |
| P0-4 | 无 LICENSE | 添加 Apache-2.0 全文 |
| P0-5 | repository 为空 | 填写 https://github.com/toadium/MoonDES |
| P0-6 | README 仅 1 行 | 替换为完整内容 |

#### P1 — 核心功能（v0.3.0 全部修复 ✅）

| # | 问题 | 修复方式 |
|---|------|---------|
| P1-1 | Process 协程语义未实现 | ProcessAction 指令式 API（Done/Timeout/WaitEvent/Terminate）|
| P1-2 | event_count 硬编码 0 | env.event_count() 统计真实事件数 |
| P1-3 | 无 rollback | EnvSnapshot + SimulationEnv::restore + experiment::rollback |
| P1-4 | 无序列化 | **推迟至 v0.5.0**（跨后端验证阶段） |
| P1-5 | Preemptive 未实现 | holder 字段 + on_preempt 回调 + 抢占逻辑 |
| P1-6 | Plugin 未集成主循环 | 钩子字段 + run/step 自动触发 + attach 设置钩子 |
| P1-7 | EventQueue 边界风险 | length < 2 显式提前返回 + 边界测试 |

#### P2 — 工程治理（部分修复，v0.4.0 继续）

| # | 问题 | 状态 |
|---|------|------|
| P2-1 | 无 CHANGELOG.md | ✅ v0.2.0 已修复 |
| P2-2 | 无 roadmap.md | ✅ v0.2.0 已修复 |
| P2-3 | 无 CI/CD | ✅ v0.2.0 已修复 |
| P2-4 | 无黑盒测试 (*_wbtest.mbt) | ⬜ v0.4.0 |
| P2-5 | 无独立文档测试文件 (*.mbt.md) | ⬜ v0.4.0 |
| P2-6 | 测试覆盖不均衡 | 🟡 v0.3.0 已改善（process 3→7, plugin 3→6, resource 4→7, experiment 4→6, core 9→13） |
| P2-7 | 需求文档依赖未引入 | ⬜ v0.5.0+（serde 推迟，mock 用内置断言替代） |

---

## 二、迭代版本规划

### 版本总览

```
v0.1.0          ──► v0.2.0  ──► v0.3.0  ──► v0.4.0  ──► v0.5.0  ──► v1.0.0  ──► v1.x
  Alpha 原型      ✅ 工程加固  ✅ 功能补全   测试完善      性能优化      正式发布      生态拓展
  M1-M2 完成      M2 收尾      M3 推进       M3 收尾       M3 强化       M4 达成       M5+ 衔接
```

---

### v0.2.0 — 工程基础设施加固 ✅

> **目标**：修复全部 P0 问题，使项目成为"合规的可发布开源项目"。
> **对应里程碑**：M2 收尾
> **状态**：已完成 (2026-08-15)

#### 任务清单

- [x] **T0.2.1** 创建 `README.mbt.md`（含 `mbt check` 可执行示例）
- [x] **T0.2.2** 更新 `README.md` 为完整内容（特性、快速开始、项目结构、贡献指南）
- [x] **T0.2.3** 添加 `.gitignore`（排除 `_build/`、`target/`、`.mooncakes/`、`.repos/`）
- [x] **T0.2.4** 添加 LICENSE 文件（Apache-2.0 全文）
- [x] **T0.2.5** 填写 `moon.mod` 的 `repository` 字段
- [x] **T0.2.6** 初始化 CHANGELOG.md，记录 v0.1.0 基线
- [x] **T0.2.7** `git add` 全部源码与文档，建立完整初始提交
- [x] **T0.2.8** 添加 GitHub Actions CI（check + test + info 一致性 + fmt 检查）

#### 验收结果

- `moon info` 无报错，`pkg.generated.mbti` 无非预期变化 ✅
- `git status` 干净 ✅
- CI 配置就绪 ✅
- LICENSE 与 moon.mod 声明一致 ✅

---

### v0.3.0 — 核心功能补全 ✅

> **目标**：修复全部 P1 问题，使五层模块达到需求文档描述的工程级能力。
> **对应里程碑**：M3 推进（进程、资源、实验模块全部完成）
> **状态**：已完成 (2026-08-15)

#### v0.3.0-alpha.1 — Process 协程语义 (P1-1) ✅

- [x] **T0.3.1** 调研 MoonBit Generator / async：**结论无 Generator，采用 ProcessAction 指令式 API**
- [x] **T0.3.2** 重构 `behavior` 类型为 `(Process) -> ProcessAction`
- [x] **T0.3.3** 实现 `Timeout(duration, next)` 真正挂起进程、延时后执行续延
- [x] **T0.3.4** 实现 `WaitEvent(event, next)` 挂起进程直到事件触发
- [x] **T0.3.5** 补充 process 测试 3→7：timeout 挂起恢复时序、多级 timeout 链、wait_event、Done、Terminate

#### v0.3.0-alpha.2 — Experiment 功能补全 (P1-2, P1-3) ✅

- [x] **T0.3.6** `run_experiment` / `snapshot` 统计真实 event_count
- [x] **T0.3.7** core 新增 `EnvSnapshot` + `SimulationEnv::snapshot` 捕获环境状态
- [x] **T0.3.8** 实现 `rollback(env, snapshot)` 断点回滚
- [ ] **T0.3.9** 引入 `serde` 序列化：**推迟至 v0.5.0**
- [x] **T0.3.10** 补充 experiment 测试 4→6：rollback 往返、event_count 统计、param_sweep 值验证

#### v0.3.0-alpha.3 — Resource Preemptive (P1-5) ✅

- [x] **T0.3.11** 实现 `Preemptive` 抢占逻辑：高优先级进程可中断低优先级
- [x] **T0.3.12** 被抢占进程 `on_preempt` 回调触发，请求重新入队，释放后恢复
- [x] **T0.3.13** 补充 resource 测试 4→7：抢占触发、同优先级排队、释放后恢复

#### v0.3.0-alpha.4 — Plugin 集成主循环 (P1-6) ✅

- [x] **T0.3.14** `run`/`step` 每步自动调用 `on_step_hook`
- [x] **T0.3.15** 事件触发后自动调用 `on_event_hook`
- [x] **T0.3.16** 仿真结束时调用 `on_finish_hook`（`_finish` 保证仅一次）
- [x] **T0.3.17** 补充 plugin 测试 3→6：on_step 自动调用、on_event 自动调用、生命周期顺序

#### v0.3.0-alpha.5 — EventQueue 修复 (P1-7) ✅

- [x] **T0.3.18** 修复 `remove_canceled` 边界：length < 2 显式提前返回
- [x] **T0.3.19** 补充 EventQueue 测试 4 个：空队列、单元素、全取消、混合取消后堆性质

#### 验收结果

- 全部 P1 问题修复（P1-4 序列化推迟）✅
- process timeout 后时间真正推进（`env.now() == 5.0`）✅
- experiment event_count 反映真实事件数 ✅
- Preemptive 资源抢占可观测 ✅
- Plugin on_step/on_event 被引擎自动触发 ✅
- `moon test` 45/45 通过 ✅

---

### v0.4.0 — 测试与文档完善

> **目标**：修复全部 P2 问题，达到需求文档要求的覆盖率 ≥96%。
> **对应里程碑**：M3 收尾（内部测试完毕）
> **预计周期**：2 周

#### 任务清单

- [ ] **T0.4.1** 为每个包添加黑盒测试 `*_wbtest.mbt`，验证公共 API 外部可见性
- [ ] **T0.4.2** 为根包便捷入口函数添加独立测试
- [ ] **T0.4.3** 为每个包创建 `README.mbt.md`，含 `mbt check` 可执行示例
- [ ] **T0.4.4** 引入 `moon coverage analyze`，识别未覆盖分支
- [ ] **T0.4.5** 补充边界测试：空环境、零时长、超大 until、负优先级、重复事件 ID
- [ ] **T0.4.6** 补充并发测试：多实例 SimulationEnv 独立运行、1000+ 事件压力测试
- [ ] **T0.4.7** 生成 API 文档（`moon doc`），检查文档可读性
- [ ] **T0.4.8** 更新 CHANGELOG.md

#### 验收标准

- 测试覆盖率 ≥96%（核心模块 core/process/resource 目标 100%）
- 黑盒测试通过，公共 API 表面验证完成
- 每个包有可运行的 README.mbt.md 示例
- `moon doc` 生成的 HTML 无缺失符号

---

### v0.5.0 — 性能优化与跨后端验证

> **目标**：达成需求文档性能指标，验证 WASI/WASM/Native 三后端，补齐序列化（P1-4）。
> **对应里程碑**：M3 强化
> **预计周期**：2 周

#### 任务清单

- [ ] **T0.5.1** 用 `moon run --profile --target native --release` 分析热点
- [ ] **T0.5.2** 优化 EventQueue：预分配容量、减少分支
- [ ] **T0.5.3** 优化 SimulationEnv::run：内联热路径、减少 Map 查找
- [ ] **T0.5.4** 编写基准测试：10000 并发进程、100000 事件调度
- [ ] **T0.5.5** 对比 SimPy 同场景性能，验证 ≥8 倍提升
- [ ] **T0.5.6** `moon check --target all` 验证三后端编译
- [ ] **T0.5.7** `moon test --target wasm-gc` / `--target wasi` 验证三后端测试
- [ ] **T0.5.8** 修复跨后端兼容问题（如 WASM 不支持的 API）
- [ ] **T0.5.9** 引入 `@json` 依赖，实现 ExpConfig / ExpResult / Snapshot 序列化（P1-4 补齐）

#### 验收标准

- 10000 并发进程调度延迟微秒级
- 十万事件仿真较 SimPy 提升 ≥8 倍
- `moon check --target all` 通过
- 三后端测试全部通过
- Snapshot 可序列化/反序列化往返

---

### v1.0.0 — 正式版发布

> **目标**：API 冻结，发布到 mooncakes，完成 M4。
> **对应里程碑**：M4（MoonDES v0.1 正式版发布、mbpkg 上架）
> **预计周期**：1 周

#### 任务清单

- [ ] **T1.0.1** API 审查：确认公共 API 稳定，标注 `#deprecated` 给旧别名
- [ ] **T1.0.2** 生成最终 `pkg.generated.mbti`，纳入版本控制
- [ ] **T1.0.3** 撰写发布说明 (RELEASE_NOTES_v1.0.0.md)
- [ ] **T1.0.4** `moon publish` 上架 mooncakes
- [ ] **T1.0.5** 更新 README 徽章（version / license / test coverage）
- [ ] **T1.0.6** 打 tag `v1.0.0`，创建 GitHub Release

#### 验收标准

- API 表面经审查冻结，后续 v1.x 保持向后兼容
- mooncakes 包可 `moon add moondes/moondes@1.0.0` 安装
- GitHub Release 附带 CHANGELOG

---

### v1.x — 生态拓展（对接 MoonPipe）

> **目标**：为 MoonPipe 及行业仿真框架提供稳定底座，孵化 MoonHeat/MoonHydro/MoonGrid。
> **对应里程碑**：M5–M8（MoonPipe 开发期）
> **策略**：语义化版本，次版本递增，补丁版本向下兼容

#### 规划方向

| 版本 | 主题 | 内容 |
|------|------|------|
| v1.1.0 | 随机数与统计 | RNG 抽象、分布采样、结果统计聚合 |
| v1.2.0 | 高级资源 | 资源池、可重入资源、资源组 |
| v1.3.0 | 监控与可观测 | 仿真日志、指标采集、trace 导出 |
| v1.4.0 | 分布式仿真 | 多环境并行、任务队列调度 |
| v2.0.0 | API 演进 | 如有破坏性变更，经充分评估后发布 |

---

## 三、里程碑对齐表

| 里程碑 | 需求.md 定义 | Roadmap 版本 | 状态 |
|--------|-------------|-------------|------|
| M1 | 整体架构、接口规范定稿 | v0.1.0 | ✅ 已完成 |
| M2 | 内核、事件队列、主仿真循环完成 | v0.1.0 + v0.2.0 | ✅ 已完成 |
| M3 | 进程、资源、实验模块全部完成，内部测试完毕 | v0.3.0 + v0.4.0 + v0.5.0 | 🟡 推进中（v0.3.0 完成，v0.4.0/v0.5.0 待做） |
| M4 | v0.1 正式版发布、mbpkg 上架 | v1.0.0 | ⬜ 未开始 |
| M5 | MoonPipe 拓扑建模、流体阻力组件 | v1.x 稳定底座 | ⬜ 未开始 |
| M6 | TreeSolver、LoopSolver 求解器 | v1.x 稳定底座 | ⬜ 未开始 |
| M7 | MoonPipe 与 MoonDES 插件对接 | v1.x 稳定底座 | ⬜ 未开始 |
| M8 | 全套示例、测试、文档定稿，正式发布 | v1.x 稳定底座 | ⬜ 未开始 |

---

## 四、版本管理规范

1. **语义化版本**：`主版本.次版本.补丁版本`
   - 补丁版本：bug 修复，API 不变
   - 次版本：新增功能，向后兼容
   - 主版本：破坏性变更，需上层适配

2. **API 稳定性承诺**：v1.x 期间公共 API 保持向后兼容；破坏性变更推迟到 v2.0，并提前在 CHANGELOG 标注 `#deprecated`。

3. **发布流程**：
   - 更新 CHANGELOG.md
   - `moon check` + `moon test --target all` + `moon info` 全绿
   - 打 tag、创建 Release、`moon publish`

4. **Git 工作流**：feature 分支开发 → PR 代码审查 → CI 绿色 → 合并 main → 发布

---

## 五、风险与应对

| 风险 | 应对 | 状态 |
|------|------|------|
| MoonBit 无 Generator，协程语义实现受阻 | v0.3.0 采用 ProcessAction 指令式 API（CPS 风格）替代 | ✅ 已解决 |
| mooncakes 发布流程变更 | 锁定 moon 工具链 LTS 版本，CI 中固定版本 | ⬜ 待验证 |
| 跨后端兼容问题（WASM 不支持某些 API） | v0.5.0 集中验证，必要时用 `#cfg` 条件编译 | ⬜ 待验证 |
| 测试覆盖率 96% 目标过高 | 优先核心模块 100%，外层模块逐步提升 | 🟡 v0.3.0 已改善 |
| 序列化依赖 @json 引入增加 core 耦合 | P1-4 推迟至 v0.5.0，仅在 experiment 包引入 | ⬜ 待实施 |

---

## 六、变更记录

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-08-15 | roadmap v1.0 | 初始制定，对齐需求.md M1-M8，识别 P0×6 + P1×7 + P2×#7 缺口 |
| 2026-08-15 | roadmap v1.1 | v0.2.0 + v0.3.0 完成：P0/P1 全部修复（P1-4 序列化推迟 v0.5.0），测试 27→45，标记任务状态 |
