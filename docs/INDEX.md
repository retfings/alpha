# 文档索引

本文档索引整理了 MoonBit 量化回测框架的所有文档资源。

## 核心文档

| 文档 | 描述 | 适用对象 |
|------|------|----------|
| [README](../README.md) | 项目概述和快速开始 | 新用户 |
| [快速入门](QUICKSTART.md) | 5 分钟快速开始指南 | 新用户 |
| [股票策略快速入门](stock-strategy-quickstart.md) | 股票策略系统 5 分钟上手 | 新用户 |
| [用户指南](user-guide.md) | 完整使用教程 | 所有用户 |
| [API 参考手册](MANUAL.md) | 完整 API 参考手册 | 开发者 |
| [API 参考](api-reference.md) | 核心模块 API 文档 | 开发者 |
| [HTTP API 端点](api-endpoints.md) | HTTP API 端点参考（含策略 API） | 开发者 |
| [架构设计](architecture.md) | 系统架构说明 | 开发者/架构师 |
| [股票策略架构](stock-strategy-architecture.md) | 股票策略系统架构 | 开发者/架构师 |
| [开发者指南](developer-guide.md) | 开发环境和规范 | 开发者 |
| [测试计划](test-plan.md) | 测试流程和示例 | 开发者/QA |
| [数据下载指南](data-download-guide.md) | Baostock 数据下载和管理 | 数据工程师 |

## 用户指南系列 (docs/user-guide/)

| 文档 | 描述 | 适用对象 |
|------|------|----------|
| [股票筛选器指南](user-guide/stock-screener-guide.md) | 股票筛选器完整使用教程 | 投资者 |
| [技术指标参考](user-guide/indicator-reference.md) | 技术指标计算和使用参考 | 量化分析师 |
| [交易模型指南](user-guide/trading-model-guide.md) | 策略定义和回测执行指南 | 策略开发者 |

## 开发者指南系列 (docs/dev-guide/)

| 文档 | 描述 | 适用对象 |
|------|------|----------|
| [系统架构设计](dev-guide/architecture.md) | 股票选择系统架构详解 | 开发者/架构师 |
| [API 参考文档](dev-guide/api-reference.md) | 内部 API 接口参考 | 开发者 |
| [添加新指标指南](dev-guide/adding-indicators.md) | 如何开发和注册新指标 | 开发者 |
| [测试指南](dev-guide/testing.md) | 测试编写和执行指南 | 开发者/QA |

## 开发和设计文档

| 文档 | 描述 | 状态 |
|------|------|------|
| [优化路线图](optimization-roadmap.md) | 开发和优化计划总览 | 持续更新 |
| [架构改进建议](architecture-improvements.md) | 5 项架构改进详细方案 | 待审查 |
| [架构优化提案](architecture-optimization-proposals.md) | 功能和架构建议 | 待审查 |
| [代码优化建议](optimization-proposals.md) | 性能和质量优化详情 | 部分完成 |
| [代码修复文档](code-fixes.md) | 修复记录汇总 | 持续更新 |

## Baostock 数据集成文档

| 文档 | 描述 | 状态 |
|------|------|------|
| [数据下载指南](data-download-guide.md) | 完整数据下载和管理指南 | 已完成 |
| [Baostock API 参考](baostock-api.md) | Baostock API 使用说明 | 已完成 |
| [数据格式说明](data-format.md) | CSV 数据和 KLine 结构 | 已完成 |
| [Baostock 集成项目文档](baostock-integration-project.md) | 集成项目和团队说明 | 已完成 |

## 报告和状态

| 文档 | 描述 | 日期 |
|------|------|------|
| [测试覆盖率报告](test-coverage-report.md) | 测试覆盖分析 | 2026-03-27 |
| [阶段进度审查](phase-progress-review.md) | 开发进度跟踪 | 2026-03-27 |
| [最终审查报告](final-review-report.md) | 项目最终审查 | 2026-03-27 |
| [项目状态报告](project-status-report.md) | 项目整体状态 | 2026-03-27 |

## 示例和教程

| 文档 | 描述 |
|------|------|
| [策略示例](strategy-examples.md) | 内置策略示例和用法 |

## 快速导航

### 按主题查找

#### 入门指南
1. [README](../README.md) - 项目简介和快速开始
2. [快速入门](QUICKSTART.md) - 5 分钟快速开始
3. [用户指南](user-guide.md) - 详细使用教程
4. [策略示例](strategy-examples.md) - 策略编写示例

#### 架构和设计
1. [架构设计](architecture.md) - 整体架构说明
2. [架构改进建议](architecture-improvements.md) - 架构优化方案
3. [架构优化提案](architecture-optimization-proposals.md) - 功能和架构建议

#### API 和开发
1. [API 参考手册](MANUAL.md) - 完整 API 参考手册
2. [API 参考](api-reference.md) - 核心 API 文档
3. [代码优化建议](optimization-proposals.md) - 代码质量改进
4. [代码修复文档](code-fixes.md) - 修复记录

#### 项目管理
1. [优化路线图](optimization-roadmap.md) - 开发计划总览
2. [测试覆盖率报告](test-coverage-report.md) - 测试覆盖分析
3. [阶段进度审查](phase-progress-review.md) - 进度跟踪

---

## 文档结构

```
docs/
├── INDEX.md                      # 文档索引（本文件）
├── QUICKSTART.md                 # 快速入门指南
├── stock-strategy-quickstart.md  # 股票策略快速入门
├── MANUAL.md                     # API 参考手册（完整版）
├── api-reference.md              # API 参考文档
├── api-endpoints.md              # HTTP API 端点参考
├── architecture.md               # 架构设计
├── stock-strategy-architecture.md # 股票策略架构
├── developer-guide.md            # 开发者指南
├── test-plan.md                  # 测试计划
├── data-download-guide.md        # 数据下载指南
├── baostock-api.md               # Baostock API 参考
├── baostock-integration-project.md # Baostock 集成项目
├── baostock-data-guide.md        # Baostock 数据指南
├── data-format.md                # 数据格式说明
├── architecture-improvements.md  # 架构改进建议
├── architecture-optimization-proposals.md  # 架构优化提案
├── code-fixes.md                 # 代码修复记录
├── optimization-proposals.md     # 代码优化建议
├── optimization-roadmap.md       # 优化路线图
├── phase-progress-review.md      # 阶段进度审查
├── project-status-report.md      # 项目状态报告
├── strategy-examples.md          # 策略示例
├── strategy-guide.md             # 策略指南
├── stock-strategy-guide.md       # 股票策略指南
├── test-coverage-report.md       # 测试覆盖率报告
├── user-guide.md                 # 用户指南
├── final-review-report.md        # 最终审查报告
├── frontend-backend-integration.md # 前后端集成
├── indicator-strategy-integration-test-plan.md # 指标策略集成测试
├── strategy-config-proposal.md   # 策略配置提案
├── strategy-design.md            # 策略设计
├── RELEASE_SUMMARY.md            # 发布摘要
├── PERFORMANCE_OPTIMIZATION_REVIEW.md # 性能优化审查
├── code-quality-review.md        # 代码质量审查
│
├── user-guide/                   # 用户指南系列
│   ├── stock-screener-guide.md   # 股票筛选器指南
│   ├── indicator-reference.md    # 技术指标参考
│   └── trading-model-guide.md    # 交易模型指南
│
└── dev-guide/                    # 开发者指南系列
    ├── architecture.md           # 系统架构设计
    ├── api-reference.md          # API 参考文档
    ├── adding-indicators.md      # 添加新指标指南
    └── testing.md                # 测试指南
```

---

## 文档更新记录

| 日期 | 文档 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-03-28 | INDEX.md | 添加股票选择系统文档系列索引 | doc-eng |
| 2026-03-28 | dev-guide/architecture.md | 新建股票选择系统架构设计文档 | doc-eng |
| 2026-03-28 | dev-guide/api-reference.md | 新建 API 参考文档 | doc-eng |
| 2026-03-28 | dev-guide/adding-indicators.md | 新建添加新指标指南 | doc-eng |
| 2026-03-28 | dev-guide/testing.md | 新建测试指南 | doc-eng |
| 2026-03-28 | user-guide/stock-screener-guide.md | 新建股票筛选器用户指南 | doc-eng |
| 2026-03-28 | user-guide/indicator-reference.md | 新建技术指标参考手册 | doc-eng |
| 2026-03-28 | user-guide/trading-model-guide.md | 新建交易模型指南 | doc-eng |
| 2026-03-27 | api-endpoints.md | 添加股票策略 API（筛选/行业/策略 CRUD） | doc-eng |
| 2026-03-27 | stock-strategy-quickstart.md | 新建股票策略快速入门指南 | doc-eng |
| 2026-03-27 | test-plan.md | 新建测试计划文档 | doc-eng |
| 2026-03-27 | INDEX.md | 添加快速入门和测试计划索引 | doc-eng |
| 2026-03-27 | INDEX.md | 添加数据下载指南索引 | data-eng |
| 2026-03-27 | data-download-guide.md | 新建完整数据下载指南 | data-eng |
| 2026-03-27 | script/download_data.md | 更新增强下载器文档 | data-eng |
| 2026-03-27 | script/enhanced_downloader.py | 添加财务数据和行业数据下载 | data-eng |
| 2026-03-27 | INDEX.md | 添加新文档索引 | doc-eng |
| 2026-03-27 | stock-strategy-architecture.md | 新建股票策略系统架构文档 | doc-eng |
| 2026-03-27 | developer-guide.md | 新建开发者指南 | doc-eng |
| 2026-03-27 | QUICKSTART.md | 创建快速入门指南 | doc-eng |
| 2026-03-27 | api-reference.md | 更新为中文版 API 文档 | doc-eng |
| 2026-03-27 | MANUAL.md | 创建完整 API 参考手册 | doc-eng |

---

*最后更新：2026-03-28*
*文档维护者：doc-eng, data-eng*
