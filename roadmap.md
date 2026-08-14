# MoonDES 迭代路线图 (Roadmap)

> **项目**：MoonDES — 通用离散事件仿真引擎
> **当前版本**：v0.1.0 (Alpha 早期原型)
> **最后更新**：2026-08-15
> **对齐里程碑**：需求.md M1–M8（总周期 13 个月）

---

## 一、现状基线 (v0.1.0 Alpha)

### 1.1 已完成

| 维度 | 状态 |
|------|------|
| 五层架构骨架 | core / process / resource / experiment / plugin 全部搭建 |
| 根包聚合入口 | 6 个便捷函数 (version / new_env / new_config / new_exclusive / process / new_plugin_manager) |
| 事件队列 | 最小堆实现，按 (time, priority) 排序，上浮/下沉完整 |
| 仿真主循环 | SimulationEnv::run / step 可运行 |
| 示例工程 | hello_des / mm1_queue / resource_sharing 三个可执行示例 |
| 测试 | 27 个测试全部通过 (23 内部 + 4 doc test) |
| 构建 | moon check 0 警告，moon test --target native 通过 |
| 文档注释 | 81 个公共 API 100% 覆盖 /// 注释 |
| 规划文档 | 申报书 / 技术文档 / 品牌故事 / 审查报告 / 验证报告 齐全 |

### 1.2 严重缺口（审查发现）

#### P0 — 工程基础设施缺失

| # | 问题 | 影响 |
|---|------|------|
| P0-1 | `moon.mod` 的 `readme = "README.mbt.md"` 指向不存在的文件 | 包发布/moon info 异常 |
| P0-2 | 根目录无 `.gitignore`，`_build/` 等构建产物污染 git | 仓库膨胀 |
| P0-3 | `git ls-files` 仅返回 README.md，几乎所有源码 untracked | 项目实质未纳入版本控制 |
| P0-4 | 无 LICENSE 文件（moon.mod 声明 Apache-2.0） | 法律合规风险 |
| P0-5 | `repository = ""` 未填写仓库地址 | mooncakes 发布受阻 |
| P0-6 | 根 README.md 仅 1 行标题，完整版在 docs/ 未启用 | 首页空白 |

#### P1 — 核心功能为占位/简化实现

| # | 问题 | 当前行为 | 期望行为 |
|---|------|---------|---------|
| P1-1 | **Process 协程语义未实现** | behavior 一次性执行完毕，timeout 仅设置状态不挂起 | 基于 Generator 挂起/恢复，timeout 后暂停执行 |
| P1-2 | **Experiment event_count 硬编码 0** | run_experiment / snapshot 返回 0 | 统计实际事件数 |
| P1-3 | **Experiment 无 rollback** | 缺失 | 保存快照 + 断点回滚 |
| P1-4 | **Experiment 无序列化** | 缺失 | serde 跨 WASI/WASM/Native |
| P1-5 | **Resource Preemptive 未实现** | request/release 无抢占逻辑 | 高优先级进程可抢占低优先级 |
| P1-6 | **Plugin 未集成主循环** | on_step/on_event 永不触发 | run/step 自动调用回调 |
| P1-7 | **EventQueue::remove_canceled 边界风险** | `0..<=start` 在 length<2 时异常 | 安全建堆 |

#### P2 — 工程治理缺口

| # | 问题 |
|---|------|
| P2-1 | 无 CHANGELOG.md |
| P2-2 | 无 roadmap.md（本文件即补齐） |
| P2-3 | 无 CI/CD（GitHub Actions / GitLab CI） |
| P2-4 | 无黑盒测试 (*_wbtest.mbt) |
| P2-5 | 无独立文档测试文件 (*.mbt.md) |
| P2-6 | 测试覆盖不均衡：process 仅 3 个，wait_event 未测试 |
| P2-7 | 需求文档依赖 (mock/serde/dummy_faker/xlsx) 均未引入 |

---

## 二、迭代版本规划

### 版本总览

```
v0.1.0 (当前)  ──► v0.2.0  ──► v0.3.0  ──► v0.4.0  ──► v0.5.0  ──► v1.0.0  ──► v1.x
  Alpha 原型      工程加固      功能补全      测试完善      性能优化      正式发布      生态拓展
  M1-M2 完成      M2 收尾       M3 推进       M3 收尾       M3 强化       M4 达成       M5+ 衔接
```

---

### v0.2.0 — 工程基础设施加固

> **目标**：修复全部 P0 问题，使项目成为"合规的可发布开源项目"。
> **对应里程碑**：M2 收尾
> **预计周期**：1 周

#### 任务清单

- [ ] **T0.2.1** 修复 `moon.mod` 的 readme 字段：创建 `README.mbt.md`（含 `mbt check` 可执行示例），符号链接 `README.md -> README.mbt.md`
- [ ] **T0.2.2** 用 `docs/项目文档/04-README.md` 内容替换根 README，补充特性列表、快速开始、项目结构、贡献指南
- [ ] **T0.2.3** 添加 `.gitignore`：排除 `_build/`、`target/`、`.mooncakes/`、`.repos/`、`*.log`
- [ ] **T0.2.4** 添加 LICENSE 文件（Apache-2.0 全文）
- [ ] **T0.2.5** 填写 `moon.mod` 的 `repository` 字段（GitHub 仓库地址）
- [ ] **T0.2.6** 初始化 CHANGELOG.md，记录 v0.1.0 基线
- [ ] **T0.2.7** `git add` 全部源码与文档，建立完整初始提交
- [ ] **T0.2.8** 添加 GitHub Actions CI：`moon check` + `moon test --target native` + `moon info` API 一致性检查

#### 验收标准

- `moon info` 无报错，`pkg.generated.mbti` 无非预期变化
- `git status` 干净（无 untracked 构建产物）
- CI 在 main 分支绿色通过
- LICENSE 与 moon.mod 声明一致

---

### v0.3.0 — 核心功能补全

> **目标**：修复全部 P1 问题，使五层模块达到需求文档描述的工程级能力。
> **对应里程碑**：M3 推进（进程、资源、实验模块全部完成）
> **预计周期**：4 周

#### v0.3.0-alpha.1 — Process 协程语义 (P1-1)

- [ ] **T0.3.1** 调研 MoonBit Generator / async 实现协程挂起的可行方案
- [ ] **T0.3.2** 重构 `Process::behavior` 为可挂起/恢复的协程执行模型
- [ ] **T0.3.3** 实现 `timeout` 真正挂起进程、调度恢复事件后继续执行
- [ ] **T0.3.4** 实现 `wait_event` 挂起进程直到指定事件触发
- [ ] **T0.3.5** 补充 process 测试：timeout 挂起恢复时序、wait_event 等待、多进程并发

#### v0.3.0-alpha.2 — Experiment 功能补全 (P1-2, P1-3, P1-4)

- [ ] **T0.3.6** `run_experiment` / `snapshot` 统计真实 event_count 与 final_time
- [ ] **T0.3.7** 实现 `Snapshot` 完整捕获 SimulationEnv 状态
- [ ] **T0.3.8** 实现 `rollback(env, snapshot)` 断点回滚
- [ ] **T0.3.9** 引入 `serde` 依赖，实现 SimulationEnv / Snapshot 序列化/反序列化
- [ ] **T0.3.10** 补充 experiment 测试：快照-回滚往返、序列化往返、批量实验指标正确性

#### v0.3.0-alpha.3 — Resource Preemptive (P1-5)

- [ ] **T0.3.11** 实现 `ResourceKind::Preemptive` 的抢占逻辑：高优先级进程可中断低优先级
- [ ] **T0.3.12** 被抢占进程挂起并重新入队，释放后恢复
- [ ] **T0.3.13** 补充 resource 测试：抢占触发、抢占恢复、优先级链

#### v0.3.0-alpha.4 — Plugin 集成主循环 (P1-6)

- [ ] **T0.3.14** `SimulationEnv::step` 每步自动调用 `notify_step`
- [ ] **T0.3.15** 事件触发时自动调用 `notify_event`
- [ ] **T0.3.16** `run` 结束时调用 `notify_finish`（当前已有，保留）
- [ ] **T0.3.17** 补充 plugin 测试：on_step 回调计数、on_event 回调匹配、全生命周期顺序

#### v0.3.0-alpha.5 — EventQueue 修复 (P1-7)

- [ ] **T0.3.18** 修复 `remove_canceled` 边界：length < 2 时直接返回
- [ ] **T0.3.19** 补充 EventQueue 测试：空队列、单元素、全取消、混合取消后堆性质

#### 验收标准

- 全部 P1 问题修复，`moon test` 通过
- process timeout 后时间真正推进（测试断言 `env.now() == 5.0`）
- experiment event_count 反映真实事件数
- Preemptive 资源抢占可观测
- Plugin on_step/on_event 被引擎自动触发

---

### v0.4.0 — 测试与文档完善

> **目标**：修复全部 P2 问题，达到需求文档要求的覆盖率 ≥96%。
> **对应里程碑**：M3 收尾（内部测试完毕）
> **预计周期**：2 周

#### 任务清单

- [ ] **T0.4.1** 为每个包添加黑盒测试 `*_wbtest.mbt`，验证公共 API 外部可见性
- [ ] **T0.4.2** 为根包便捷入口函数添加独立测试
- [ ] **T0.4.3** 为每个包创建 `README.mbt.md`，含 `mbt check` 可执行示例
- [ ] **T0.4.4** 引入 `moonbitlang/coverage` 或 `moon coverage analyze`，识别未覆盖分支
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

> **目标**：达成需求文档性能指标，验证 WASI/WASM/Native 三后端。
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

#### 验收标准

- 10000 并发进程调度延迟微秒级
- 十万事件仿真较 SimPy 提升 ≥8 倍
- `moon check --target all` 通过
- 三后端测试全部通过

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
| M1 | 整体架构、接口规范定稿 | v0.1.0 (已完成) | ✅ |
| M2 | 内核、事件队列、主仿真循环完成 | v0.1.0 + v0.2.0 (工程加固) | 🟡 进行中 |
| M3 | 进程、资源、实验模块全部完成，内部测试完毕 | v0.3.0 + v0.4.0 + v0.5.0 | ⬜ 未开始 |
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

| 风险 | 应对 |
|------|------|
| MoonBit Generator 尚不稳定，协程语义实现受阻 | v0.3.0-alpha.1 优先调研可行性；若不可行，退化为回调/状态机模型并标注限制 |
| mooncakes 发布流程变更 | 锁定 moon 工具链 LTS 版本，CI 中固定版本 |
| 跨后端兼容问题（WASM 不支持某些 API） | v0.5.0 集中验证，必要时用 `#cfg` 条件编译 |
| 测试覆盖率 96% 目标过高 | 优先核心模块 100%，外层模块逐步提升 |

---

## 六、变更记录

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-08-15 | roadmap v1.0 | 初始制定，对齐需求.md M1-M8，识别 P0×6 + P1×7 + P2×7 缺口 |