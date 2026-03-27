# MoonBit 量化回测框架

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![MoonBit](https://img.shields.io/badge/MoonBit-latest-green.svg)](https://www.moonbitlang.com/)
[![Test Coverage](https://img.shields.io/badge/coverage-85%25-yellowgreen.svg)](docs/test-coverage-report.md)

使用 MoonBit 语言开发的类型安全量化交易回测框架。

## 特性

- **类型安全**: 利用 MoonBit 的类型系统确保策略和回测逻辑的正确性
- **高性能**: 优化的指标计算和回测引擎
- **可扩展**: 模块化架构，易于添加新的策略和指标
- **实时风控**: 内置多种风险管理规则（最大回撤、仓位限制、止损等）
- **详细报告**: 生成 HTML/Text 格式的回测报告

## 快速开始



### 构建项目

```bash
moon check    # 类型检查（快速）
moon build    # 构建项目
moon run cmd/main  # 运行 CLI
```

### 运行测试

```bash
moon test            # 运行所有测试
moon test --update   # 更新快照测试
moon test -F "glob"  # 运行匹配的测试
```

### 格式化代码

```bash
moon fmt    # 格式化所有代码
moon info   # 生成公共接口文件
```


## CLI 使用指南

### 命令列表

```bash
# 显示帮助信息
moon run cmd/main help

# 启动 HTTP 服务器
moon run cmd/main serve              # 默认端口 8080
moon run cmd/main serve --port 3000  # 自定义端口

# 分析个股回撤
moon run cmd/main analyze --stock sh.600000 --metric max_drawdown

# 运行策略回测
moon run cmd/main backtest --strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31

# 实时监控模式
moon run cmd/main monitor --stock sh.600000

# 生成分析报告
moon run cmd/main report --format html

# 列出可用策略
moon run cmd/main list-strategies
```

### serve 命令详解

`serve` 命令启动 HTTP API 服务器，提供 RESTful API 访问：

```bash
# 使用默认端口 (8080) 启动
moon run cmd/main serve

# 指定端口启动
moon run cmd/main serve --port 3000
```

启动后，可以通过 HTTP API 访问：

| 端点 | 描述 |
|------|------|
| `GET /api/stocks` | 获取股票列表 |
| `GET /api/stocks/:code/klines` | 获取 K 线数据 |
| `POST /api/backtest` | 运行回测 |
| `GET /api/drawdown/:code` | 计算个股回撤 |

## 测试指南

### 运行测试

```bash
# 运行所有测试
moon test

# 运行特定目录的测试
moon test src/drawdown

# 运行匹配的测试
moon test -F "*drawdown*"

# 更新快照测试
moon test --update
```

## 项目结构

```
alpha/
├── cmd/main/           # CLI 入口点
├── src/                # 核心业务逻辑
│   ├── data/           # 数据层 (KLine 类型，CSV 加载器)
│   ├── strategy/       # 策略引擎和内置策略
│   ├── drawdown/       # 回撤计算核心
│   ├── risk/           # 风险管理规则引擎
│   ├── portfolio/      # 投资组合和持仓管理
│   ├── indicator/      # 技术指标 (MA, RSI, MACD 等)
│   └── backtest/       # 回测引擎和报告生成
├── server/             # HTTP API 服务器
├── www/                # Web 前端
├── data/               # CSV 股票数据
├── script/             # Python 工具脚本
└── docs/               # 文档
```

## 文档

### 核心文档

- [文档索引](docs/INDEX.md) - 完整文档导航
- [快速入门](docs/QUICKSTART.md) - 5 分钟快速开始
- [用户指南](docs/user-guide.md) - 使用教程
- [API 参考](docs/api-reference.md) - API 文档
- [架构设计](docs/architecture.md) - 架构说明

### 开发文档

- [优化路线图](docs/optimization-roadmap.md) - 开发和优化计划
- [代码修复文档](docs/code-fixes.md) - 修复记录
- [测试覆盖率报告](docs/test-coverage-report.md) - 测试分析

## 项目状态

| 指标 | 当前状态 |
|------|----------|
| 测试覆盖率 | 85% |
| 编译错误 | 0 |
| 编译警告 | <40 |

## 开发计划

### 阶段 1: 基础巩固 (第 1-2 周)
- [x] C FFI 集成
- [x] 测试覆盖率提升
- [ ] 减少编译警告

### 阶段 2: 性能优化 (第 3-4 周)
- [ ] 替换 O(n²) 排序为 O(n log n)
- [ ] SMA 滑动窗口优化

### 阶段 3: 架构升级 (第 5-7 周)
- [ ] 依赖注入模式
- [ ] 统一错误处理

### 阶段 4: 功能扩展 (第 8-10 周)
- [ ] 多股票组合回测
- [ ] Walk-forward 分析

## 许可证

Apache License 2.0 - 详见 [LICENSE](LICENSE) 文件。

## 外部参考

- [MoonBit 官方文档](https://www.moonbitlang.com/)
- [MoonBit 核心库 API](https://www.moonbitlang.com/docs/core/)
- [MoonBit C FFI 指南](https://www.moonbitlang.com/guide/ffi/)
