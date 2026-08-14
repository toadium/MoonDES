# 基于MoonBit的国产化通用离散事件仿真底座及多流体管网仿真业务平台

[![Build Status](https://img.shields.io/badge/build-pending-lightgrey.svg)](待接入CI后替换)
[![Version](https://img.shields.io/badge/version-v0.1.0-blue.svg)](待接入CI后替换)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](发布前确认)

> 依托国产 MoonBit 编译型编程语言，打造完全自主可控、跨部署环境、面向工业数字化与智慧管网领域的完整仿真技术体系。

## 特性（Features）

- **通用离散事件仿真引擎（MoonDES）**：基于最小堆优先级事件队列与协程调度，支持 10000+ 并发仿真进程，调度延迟微秒级，十万事件仿真速度较 Python SimPy 提升 8 倍以上
- **多类型资源竞争排队**：内置独占式、共享容量、优先级抢占三类资源模型，自动实现资源申请、排队等待、释放、队列排序
- **双拓扑管网求解器（MoonPipe）**：TreeSolver 树状管网线性递推毫秒级求解 + LoopSolver 改进 Hardy-Cross 环状管网平差，与 EPANET 标准算例误差 ≤0.5%
- **多流体介质可插拔扩展**：原生内置自来水、灌溉清水、污水、雨水，可快速新增天然气、原油、成品油等牛顿流体，仅需扩展物性参数无需修改求解内核
- **跨部署环境无缝运行**：一次开发编译为 Linux WASI 后端服务、浏览器 WASM 前端、Windows/macOS 原生程序三种部署形态

## 快速开始（Quick Start）

### 环境要求

- MoonBit 工具链 LTS 稳定版（`moon` 命令行工具）
- 目标后端：WASI / WASM / Native 任一

### 安装

> 注：以下命令格式以 MoonBit 官方文档为准，实际使用时请参考 `moon --help`。

```bash
# 获取引擎与业务框架
moon clone moonDES
moon clone moonPipe
```

### 运行示例

```bash
# 构建 MoonDES 引擎（WASM 前端）
moon build --target wasm --package moonDES

# 构建 MoonPipe 框架（WASI 服务端）
moon build --target wasi --package moonPipe

# 运行管网仿真示例
moon run examples/moonpipe/tree_network_demo
moon run examples/moonpipe/loop_network_demo

# 执行全量测试
moon test
```

## 文档链接

- [技术文档](./02-技术文档.md) — 系统架构、核心模块设计、接口设计、部署运行
- [项目申报书](./01-项目申报书.md) — 项目概述、技术方案、实施计划、预算与风险
- [品牌故事](./03-品牌故事.md) — 项目命名、品牌叙事、定位与价值观

## 项目结构

> 注：MoonDES 与 MoonPipe 为两个独立 Git 仓库，下方合并展示以体现整体架构层级关系。

```
MoonDES/                          # 通用离散事件仿真引擎（独立仓库）
├── core/                         # 层级1：仿真内核（SimulationEnv/时钟/事件队列/主循环）
├── process/                      # 层级2：协程进程调度（Generator/timeout/wait）
├── resource/                     # 层级3：资源管理（独占/容量/抢占）
├── experiment/                   # 层级4：实验管理（批量/快照/回滚/报告）
├── plugin/                       # 层级5：插件注册接口
├── tests/                        # mock 单元测试套件（覆盖率 ≥96%）
└── examples/                     # 通用仿真示例 Demo

MoonPipe/                         # 多流体管网仿真业务框架（独立仓库）
├── topology/                     # 层级1：管网拓扑建模与校验
├── fluid/                        # 层级2：流体物性与阻力计算
├── solver/                       # 层级3：双求解器（TreeSolver/LoopSolver）
├── adapter/                      # 层级4：MoonDES 引擎插件适配
├── scenario/                     # 层级5：业务工况仿真
├── examples/                     # 层级6：dummy_faker 示例数据集
└── tests/                        # mock 全量算法测试（覆盖率 ≥95%）
```

## 贡献指南（Contributing）

### 流程

1. Fork 对应子项目仓库（MoonDES 或 MoonPipe）
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交变更：遵循约定式提交（`feat:` / `fix:` / `docs:` / `refactor:`）
4. 确保 `moon test` 全部通过且覆盖率不下降
5. 提交 Pull Request，描述变更内容与关联 Issue

### 代码规范

- 遵循 MoonBit 官方代码风格指南
- 公开 API 必须附文档注释
- 新增功能必须配套 mock 单元测试
- MoonDES 主版本不变前提下，API 变更必须向下兼容
- 两套子项目各自独立 Git 仓库，禁止跨仓库提交

## 许可证（License）

MIT License（发布前确认）

- MoonDES 引擎采用开源协议发布，打造社区公共基础设施
- MoonPipe 管网业务框架采用开源基础版+商用增强版模式

## 致谢（Acknowledgements）

- [MoonBit](https://www.moonbitlang.com/) — 国产编译型编程语言与运行时
- MoonBit 官方生态库：mock、serde、dummy_faker、xlsx
- 仿真引擎设计参考：SimPy（协程调度内核）、DESMO-J（实验分层架构）
- 管网求解算法参考：Hardy-Cross 平差法、EPANET 标准算例