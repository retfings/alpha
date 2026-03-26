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

### 安装 MoonBit

```bash
moon up  # 安装/更新 MoonBit
```

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

## 核心 API 使用指南

### 数据类型

#### KLine (K 线数据)

K 线是量化交易的基础数据结构，包含 OHLCV（开高低收量）信息：

```mbt check
///|
test "KLine basic usage" {
  // 创建日 K 线数据
  let kline = @data.KLine::daily(
    code="sh.600000",
    date="2023-01-01",
    open=10.5,
    high=11.0,
    low=10.3,
    close=10.8,
    volume=1000000.0,
    amount=10800000.0,
    turn=0.05,
  )

  // 访问字段
  assert_true(kline.code == "sh.600000")
  assert_true(kline.close == 10.8)
  assert_true(kline.high >= kline.low)

  @json.inspect(kline)
}
```

#### StockCode (股票代码)

股票代码使用字符串表示，格式为 `market.code`：

```mbt check
///|
test "StockCode format" {
  let sh_stock : @data.StockCode = "sh.600000" // 上海证券交易所
  let sz_stock : @data.StockCode = "sz.000001" // 深圳证券交易所

  // 验证格式
  assert_true(sh_stock.contains("."))
  assert_true(sz_stock.starts_with("sz."))

  @json.inspect({ "shanghai": sh_stock, "shenzhen": sz_stock })
}
```

#### Signal (交易信号)

交易信号是策略引擎的核心输出：

```mbt check
///|
test "Signal creation" {
  // 创建买入信号
  let buy_signal = @strategy.Signal::buy("sh.600000", 10.5, "2023-01-01", 0.8)

  // 创建卖出信号
  let sell_signal = @strategy.Signal::sell("sh.600000", 11.0, "2023-01-15", 0.7)

  // 创建持有信号
  let hold_signal = @strategy.Signal::hold("sh.600000", 10.9, "2023-01-02")

  // 验证信号属性
  assert_true(buy_signal.strength > hold_signal.strength)
  assert_true(buy_signal.action == @strategy.Action.Buy)
  assert_true(sell_signal.action == @strategy.Action.Sell)

  @json.inspect({ "buy": buy_signal, "sell": sell_signal, "hold": hold_signal })
}
```

### 回撤计算

回撤（Drawdown）是衡量投资风险的重要指标，表示从峰值到谷底的跌幅。

#### 计算最大回撤

```mbt check
///|
test "calculate_max_drawdown" {
  // 模拟资产净值序列
  let values : Array[Float] = [
    100.0, // 初始值
     110.0, // 上涨 10%
     120.0, // 新高
     115.0, // 回撤
     125.0, // 新高
     110.0, // 大幅回撤
     130.0,
  ] // 恢复上涨

  let max_dd = @drawdown.calculate_max_drawdown(values)

  // 最大回撤应为从 125 到 110 的跌幅：(110-125)/125 = -0.12
  assert_true(max_dd < 0.0) // 回撤为负值
  assert_true(max_dd > -0.20) // 小于 20%

  inspect(max_dd)
}
```

#### 详细的回撤分析

```mbt check
///|
test "calculate_max_drawdown_detailed" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 125.0, 115.0, 130.0]
  let dates = [
    "2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05", "2023-01-06",
    "2023-01-07",
  ]

  let result = @drawdown.calculate_max_drawdown_detailed(values, dates)

  match result {
    Some(info) => {
      // 检查回撤信息完整性
      assert_true(info.peak > 0.0)
      assert_true(info.trough > 0.0)
      assert_true(info.drawdown < 0.0)
      assert_true(info.duration >= 0)

      @json.inspect(info)
    }
    None => fail("Expected drawdown info")
  }
}
```

#### 回撤统计

```mbt check
///|
test "get_drawdown_stats" {
  let values : Array[Float] = [
    100.0, 105.0, 110.0, 105.0, 115.0, 110.0, 120.0, 115.0, 125.0, 130.0,
  ]

  let stats = @drawdown.get_drawdown_stats(values)

  // 检查统计指标
  assert_true(stats.max_drawdown < 0.0)
  assert_true(stats.current_drawdown == 0.0) // 当前在峰值
  assert_true(stats.drawdown_count > 0)

  @json.inspect(stats)
}
```

#### 查找主要回撤

```mbt check
///|
test "find_top_drawdowns" {
  // 创建一个有明显回撤的序列
  let values : Array[Float] = [
    100.0, // 起点
     120.0, // 上涨 20%
     100.0, // 回撤 16.7%
     130.0, // 新高
     110.0, // 回撤 15.4%
     140.0, // 新高
     125.0, // 回撤 10.7%
     150.0, // 最终新高
  ]
  let dates = [
    "2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05", "2023-01-06",
    "2023-01-07", "2023-01-08",
  ]

  // 找出前 2 大回撤
  let top_drawdowns = @drawdown.find_top_drawdowns(values, dates, 2)

  assert_true(top_drawdowns.length() <= 2)

  // 回撤按严重程度排序（最严重的在前）
  if top_drawdowns.length() >= 2 {
    assert_true(top_drawdowns[0].drawdown <= top_drawdowns[1].drawdown)
  }

  @json.inspect(top_drawdowns)
}
```

### 投资组合管理

#### 创建投资组合

```mbt check
///|
test "create_portfolio" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  // 验证初始状态
  assert_true(portfolio.cash == 100000.0)
  assert_true(portfolio.initial_capital == 100000.0)
  assert_true(portfolio.position_count() == 0)

  @json.inspect({
    "cash": portfolio.cash,
    "total_value": portfolio.total_value(),
    "position_count": portfolio.position_count(),
  })
}
```

#### 买入操作

```mbt check
///|
test "Portfolio::buy" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  // 买入 1000 股，每股 50 元
  let success = portfolio.buy("sh.600000", 1000.0, 50.0)
  assert_true(success)

  // 验证持仓
  let position = portfolio.get_position("sh.600000")
  match position {
    Some(pos) => {
      assert_true(pos.quantity == 1000.0)
      assert_true(pos.avg_cost == 50.0)
    }
    None => fail("Position should exist")
  }

  // 验证现金变化
  assert_true(portfolio.cash == 50000.0)

  @json.inspect({
    "cash": portfolio.cash,
    "position_value": portfolio.position_value(),
    "total_value": portfolio.total_value(),
  })
}
```

#### 卖出操作

```mbt check
///|
test "Portfolio::sell" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  // 先买入
  ignore(portfolio.buy("sh.600000", 1000.0, 50.0))

  // 卖出 500 股，每股 55 元（盈利）
  let success = portfolio.sell("sh.600000", 500.0, 55.0)
  assert_true(success)

  // 验证剩余持仓
  let position = portfolio.get_position("sh.600000")
  match position {
    Some(pos) => assert_true(pos.quantity == 500.0)
    None => fail("Position should still exist")
  }

  // 验证现金增加
  assert_true(portfolio.cash == 50000.0 + 500.0 * 55.0)

  @json.inspect({
    "cash": portfolio.cash,
    "remaining_position": portfolio.position_count(),
  })
}
```

#### 盈亏计算

```mbt check
///|
test "Portfolio P&L calculation" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  // 买入并模拟价格上涨
  ignore(portfolio.buy("sh.600000", 1000.0, 50.0))

  // 更新当前价格到 55 元
  portfolio.update_prices(fn(stock) { 55.0 })

  // 计算盈亏
  let pnl = portfolio.total_pnl()
  let pnl_pct = portfolio.total_pnl_pct()

  // 验证盈亏
  assert_true(pnl > 0.0) // 盈利
  assert_true(pnl_pct > 0.0)

  @json.inspect({
    "total_pnl": pnl,
    "total_pnl_pct": pnl_pct * 100.0, // 转为百分比
    "position_pnl": portfolio.get_position_pnl("sh.600000"),
  })
}
```

### 风险管理规则

#### 最大回撤规则

当组合回撤超过阈值时停止交易：

```mbt check
///|
test "max_drawdown_rule" {
  let rule = @risk.max_drawdown_rule(0.20) // 20% 最大回撤

  // 测试正常情况（回撤 -15%）
  let result1 = rule.check_fn(-0.15, 0.0, 0.0)
  assert_true(result1.passed)

  // 测试触发情况（回撤 -25%）
  let result2 = rule.check_fn(-0.25, 0.0, 0.0)
  assert_true(!result2.passed)
  assert_true(result2.action is @risk.RiskAction.StopTrading)

  @json.inspect({ "normal": result1, "triggered": result2 })
}
```

#### 仓位限制规则

限制最大持仓比例：

```mbt check
///|
test "position_limit_rule" {
  let rule = @risk.position_limit_rule(0.95) // 95% 最大仓位

  // 测试正常情况（仓位 80%）
  let result1 = rule.check_fn(0.0, 0.80, 0.0)
  assert_true(result1.passed)

  // 测试触发情况（仓位 98%）
  let result2 = rule.check_fn(0.0, 0.98, 0.0)
  assert_true(!result2.passed)
  assert_true(result2.action is @risk.RiskAction.ReducePosition(_))

  @json.inspect({ "normal": result1, "triggered": result2 })
}
```

#### 日损限制规则

当单日亏损超过阈值时停止交易：

```mbt check
///|
test "daily_loss_limit_rule" {
  let rule = @risk.daily_loss_limit_rule(0.05) // 5% 日损限制

  // 测试正常情况（日亏 -3%）
  let result1 = rule.check_fn(0.0, 0.0, -0.03)
  assert_true(result1.passed)

  // 测试触发情况（日亏 -7%）
  let result2 = rule.check_fn(0.0, 0.0, -0.07)
  assert_true(!result2.passed)
  assert_true(result2.action is @risk.RiskAction.StopTrading)

  @json.inspect({ "normal": result1, "triggered": result2 })
}
```

#### 止损规则

针对单个持仓的止损规则：

```mbt check
///|
test "stop_loss_rule" {
  let rule = @risk.stop_loss_rule("sh.600000", 0.10) // 10% 止损

  // 测试正常情况（亏损 -5%）
  let result1 = rule.check_fn(0.0, 0.0, -0.05)
  assert_true(result1.passed)

  // 测试触发情况（亏损 -15%）
  let result2 = rule.check_fn(0.0, 0.0, -0.15)
  assert_true(!result2.passed)

  @json.inspect({ "normal": result1, "triggered": result2 })
}
```

#### 规则组合

使用逻辑组合多个风险规则：

```mbt check
///|
test "rule combinators" {
  // AND 组合：两个条件都必须满足
  let and_rule = @risk.and_rules(
    @risk.max_drawdown_rule(0.20),
    @risk.daily_loss_limit_rule(0.05),
    "Drawdown AND Daily Loss",
  )

  // 测试 AND 规则（都满足）
  let result1 = and_rule.check_fn(-0.10, 0.0, -0.03)
  assert_true(result1.passed)

  // 测试 AND 规则（一个不满足）
  let result2 = and_rule.check_fn(-0.25, 0.0, -0.03)
  assert_true(!result2.passed)

  // OR 组合：任一条件满足即可
  let or_rule = @risk.or_rules(
    @risk.max_drawdown_rule(0.25),
    @risk.daily_loss_limit_rule(0.10),
    "Drawdown OR Daily Loss",
  )

  @json.inspect({ "and_rule_passed": result1, "and_rule_failed": result2 })
}
```

### 技术指标

#### 简单移动平均 (SMA)

```mbt check
///|
test "sma calculation" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0]

  // 计算 3 期 SMA
  let sma = @indicator.sma(prices, 3)

  // SMA = (12 + 13 + 14) / 3 = 13.0
  assert_true(sma == 13.0)

  inspect(sma)
}
```

#### 指数移动平均 (EMA)

```mbt check
///|
test "ema calculation" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0]

  // 计算 3 期 EMA
  let ema = @indicator.ema(prices, 3)

  // EMA 对近期价格赋予更高权重
  assert_true(ema > 12.0) // 应该大于简单平均
  assert_true(ema < 14.0) // 应该小于最新价格

  inspect(ema)
}
```

#### 平均真实波幅 (ATR)

```mbt check
///|
test "atr calculation" {
  // 创建 K 线数据
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.2, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.2, 10.8, 10.0, 10.6, 1100.0, 11000.0, 0.055,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.6, 11.0, 10.4, 10.8, 1050.0, 10500.0, 0.052,
    ),
  ]

  // 计算 14 期 ATR
  let atr = @indicator.atr(klines, 14)

  // ATR 应该为正数
  assert_true(atr > 0.0)

  inspect(atr)
}
```

## CLI 使用指南

### 命令列表

```bash
# 显示帮助信息
moon run cmd/main help

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

### 环境变量配置

CLI 支持通过环境变量传递参数：

```bash
export MOONBIT_CMD="backtest"
export MOONBIT_ARGS="--strategy ma_cross --stock sh.600000"
moon run cmd/main
```

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

### 编写测试

```mbt check
///|
test "example test with inspect" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 115.0, 125.0]
  let max_dd = @drawdown.calculate_max_drawdown(values)

  // 使用 inspect 进行快照测试
  @json.inspect({ "values": values, "max_drawdown": max_dd })
}
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
- [策略示例](docs/strategy-examples.md) - 策略示例

## 项目状态

| 指标 | 当前状态 |
|------|----------|
| 测试覆盖率 | 85% |
| 编译错误 | 0 |
| 编译警告 | <40 |
| 模块数 | 9 |
| 源文件数 | 36 |
| 测试文件数 | 18 |

## 开发计划

### 阶段 1: 基础巩固 (第 1-2 周)
- [x] C FFI 集成
- [x] 测试覆盖率提升
- [ ] 减少编译警告

### 阶段 2: 性能优化 (第 3-4 周)
- [ ] 替换 O(n²) 排序为 O(n log n)
- [ ] SMA 滑动窗口优化
- [ ] Sortino 比率实现

### 阶段 3: 架构升级 (第 5-7 周)
- [ ] 依赖注入模式
- [ ] 统一错误处理
- [ ] 事件驱动架构

### 阶段 4: 功能扩展 (第 8-10 周)
- [ ] 多股票组合回测
- [ ] Walk-forward 分析
- [ ] 参数优化网格搜索

## 许可证

Apache License 2.0 - 详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request!

## 外部参考

- [MoonBit 官方文档](https://www.moonbitlang.com/)
- [MoonBit 核心库 API](https://www.moonbitlang.com/docs/core/)
- [MoonBit C FFI 指南](https://www.moonbitlang.com/guide/ffi/)
