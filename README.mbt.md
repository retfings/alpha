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

```mbt check-disabled
///|
test "KLine basic usage" {
  // 创建日 K 线数据（使用 positional 参数）
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.3, 10.8, 1000000.0, 10800000.0, 0.05,
  )

  // 访问字段
  assert_true(kline.code == "sh.600000")
  assert_true(kline.close == 10.8)
  assert_true(kline.high >= kline.low)

  json_inspect(kline)
}
```

#### StockCode (股票代码)

股票代码使用字符串表示，格式为 `market.code`：

```mbt check-disabled
///|
test "StockCode format" {
  let sh_stock : @data.StockCode = "sh.600000" // 上海证券交易所
  let sz_stock : @data.StockCode = "sz.000001" // 深圳证券交易所

  // 验证格式
  assert_true(sh_stock.contains("."))
  assert_true(sz_stock.starts_with("sz."))

  json_inspect({ "shanghai": sh_stock, "shenzhen": sz_stock })
}
```

#### Signal (交易信号)

交易信号是策略引擎的核心输出：

```mbt check-disabled
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
  assert_true(buy_signal.action == @strategy.Action::Buy)
  assert_true(sell_signal.action == @strategy.Action::Sell)

  json_inspect({ "buy": buy_signal, "sell": sell_signal, "hold": hold_signal })
}
```

### 回撤计算

#### 计算最大回撤

```mbt check-disabled
///|
test "calculate_max_drawdown" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 115.0, 125.0, 110.0, 130.0]
  let max_dd = @drawdown.calculate_max_drawdown(values)
  assert_true(max_dd < 0.0)
  assert_true(max_dd > -0.20)
  inspect(max_dd)
}
```

#### 详细的回撤分析

```mbt check-disabled
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
      assert_true(info.peak > 0.0)
      assert_true(info.drawdown < 0.0)
      json_inspect(info)
    }
    None => fail("Expected drawdown info")
  }
}
```

#### 回撤统计

```mbt check-disabled
///|
test "get_drawdown_stats" {
  let values : Array[Float] = [
    100.0, 105.0, 110.0, 105.0, 115.0, 110.0, 120.0, 115.0, 125.0, 130.0,
  ]
  let stats = @drawdown.get_drawdown_stats(values)
  assert_true(stats.max_drawdown < 0.0)
  assert_true(stats.drawdown_count > 0)
  json_inspect(stats)
}
```

#### 查找主要回撤

```mbt check-disabled
///|
test "find_top_drawdowns" {
  let values : Array[Float] = [
    100.0, 120.0, 100.0, 130.0, 110.0, 140.0, 125.0, 150.0,
  ]
  let dates = [
    "2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05", "2023-01-06",
    "2023-01-07", "2023-01-08",
  ]

  let top_drawdowns = @drawdown.find_top_drawdowns(values, dates, 2)
  assert_true(top_drawdowns.length() <= 2)

  json_inspect(top_drawdowns)
}
```

### 投资组合管理

#### 创建投资组合

```mbt check-disabled
///|
test "create_portfolio" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  assert_true(portfolio.cash == 100000.0)
  assert_true(portfolio.position_count() == 0)
  json_inspect({
    "cash": portfolio.cash,
    "total_value": portfolio.total_value(),
  })
}
```

#### 买入操作

```mbt check-disabled
///|
test "Portfolio::buy" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let success = portfolio.buy("sh.600000", 1000.0, 50.0)
  assert_true(success)
  assert_true(portfolio.cash == 50000.0)

  let position = portfolio.get_position("sh.600000")
  match position {
    Some(pos) => {
      assert_true(pos.quantity == 1000.0)
      assert_true(pos.avg_cost == 50.0)
    }
    None => fail("Position should exist")
  }

  json_inspect({
    "cash": portfolio.cash,
    "position_value": portfolio.position_value(),
  })
}
```

#### 卖出操作

```mbt check-disabled
///|
test "Portfolio::sell" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 1000.0, 50.0))

  let success = portfolio.sell("sh.600000", 500.0, 55.0)
  assert_true(success)
  assert_true(portfolio.position_count() == 1)

  json_inspect({
    "cash": portfolio.cash,
    "remaining_position": portfolio.position_count(),
  })
}
```

#### 盈亏计算

```mbt check-disabled
///|
test "Portfolio P&L calculation" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 1000.0, 50.0))
  portfolio.update_prices(fn(stock) { 55.0 })

  let pnl = portfolio.total_pnl()
  let pnl_pct = portfolio.total_pnl_pct()

  assert_true(pnl > 0.0)
  assert_true(pnl_pct > 0.0)

  json_inspect({ "total_pnl": pnl, "total_pnl_pct": pnl_pct * 100.0 })
}
```

### 风险管理规则

#### 最大回撤规则

```mbt check-disabled
///|
test "max_drawdown_rule" {
  let rule = @risk.max_drawdown_rule(0.20)

  let result1 = rule.check_fn(-0.15, 0.0, 0.0)
  assert_true(result1.passed)

  let result2 = rule.check_fn(-0.25, 0.0, 0.0)
  assert_true(!result2.passed)
  assert_true(result2.action is @risk.RiskAction::StopTrading)

  json_inspect({ "normal": result1, "triggered": result2 })
}
```

#### 仓位限制规则

```mbt check-disabled
///|
test "position_limit_rule" {
  let rule = @risk.position_limit_rule(0.95)

  let result1 = rule.check_fn(0.0, 0.80, 0.0)
  assert_true(result1.passed)

  let result2 = rule.check_fn(0.0, 0.98, 0.0)
  assert_true(!result2.passed)

  json_inspect({ "normal": result1, "triggered": result2 })
}
```

#### 日损限制规则

```mbt check-disabled
///|
test "daily_loss_limit_rule" {
  let rule = @risk.daily_loss_limit_rule(0.05)

  let result1 = rule.check_fn(0.0, 0.0, -0.03)
  assert_true(result1.passed)

  let result2 = rule.check_fn(0.0, 0.0, -0.07)
  assert_true(!result2.passed)
  assert_true(result2.action is @risk.RiskAction::StopTrading)

  json_inspect({ "normal": result1, "triggered": result2 })
}
```

#### 规则组合

```mbt check-disabled
///|
test "rule combinators" {
  let and_rule = @risk.and_rules(
    @risk.max_drawdown_rule(0.20),
    @risk.daily_loss_limit_rule(0.05),
    "Drawdown AND Daily Loss",
  )

  let result1 = and_rule.check_fn(-0.10, 0.0, -0.03)
  assert_true(result1.passed)

  let result2 = and_rule.check_fn(-0.25, 0.0, -0.03)
  assert_true(!result2.passed)

  json_inspect({ "and_rule_passed": result1, "and_rule_failed": result2 })
}
```

### 技术指标

#### 简单移动平均 (SMA)

```mbt check-disabled
///|
test "sma calculation" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
    Float::from_double(12.0),
    Float::from_double(13.0),
    Float::from_double(14.0),
  ]
  let sma_values = @indicator.sma(prices, 3)
  // Last SMA value should be (12+13+14)/3 = 13.0
  let last_sma = sma_values[sma_values.length() - 1]
  assert_true(last_sma == Float::from_double(13.0))
  @json.inspect(sma_values)
}
```

#### 指数移动平均 (EMA)

```mbt check-disabled
///|
test "ema calculation" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
    Float::from_double(12.0),
    Float::from_double(13.0),
    Float::from_double(14.0),
  ]
  let ema_values = @indicator.ema(prices, 3)
  // Last EMA value should be between 12.0 and 14.0
  let last_ema = ema_values[ema_values.length() - 1]
  assert_true(last_ema > Float::from_double(12.0))
  assert_true(last_ema < Float::from_double(14.0))
  @json.inspect(ema_values)
}
```

#### 平均真实波幅 (ATR)

```mbt check-disabled
///|
test "atr calculation" {
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

  let atr = @indicator.atr(klines, 14)
  assert_true(atr > 0.0)
  inspect(atr)
}
```

#### 相对强弱指数 (RSI)

```mbt check-disabled
///|
test "rsi calculation" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(109.0),
    Float::from_double(110.0),
    Float::from_double(111.0),
    Float::from_double(112.0),
    Float::from_double(113.0),
    Float::from_double(114.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)
  let last_rsi = rsi_values[rsi_values.length() - 1]

  // RSI should be between 0 and 100
  assert_true(last_rsi > Float::from_double(0.0))
  assert_true(last_rsi < Float::from_double(100.0))

  // Check overbought/oversold helpers
  assert_true(!@indicator.is_overbought(last_rsi, Float::from_double(70.0)))
  assert_true(!@indicator.is_oversold(last_rsi, Float::from_double(30.0)))

  @json.inspect(rsi_values)
}
```

#### 平均趋向指数 (ADX)

```mbt check-disabled
///|
test "adx calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 11.3, 11.8, 11.1, 11.6, 1300.0, 13000.0, 0.062,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 11.6, 12.0, 11.4, 11.9, 1400.0, 14000.0, 0.065,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 11.9, 12.3, 11.7, 12.1, 1350.0, 13500.0, 0.063,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 12.1, 12.5, 11.9, 12.4, 1500.0, 15000.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 12.4, 12.8, 12.2, 12.6, 1450.0, 14500.0, 0.066,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 12.6, 13.0, 12.4, 12.8, 1600.0, 16000.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 12.8, 13.2, 12.6, 13.0, 1550.0, 15500.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 13.0, 13.4, 12.8, 13.2, 1700.0, 17000.0, 0.072,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 13.2, 13.6, 13.0, 13.4, 1650.0, 16500.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 13.4, 13.8, 13.2, 13.6, 1800.0, 18000.0, 0.075,
    ),
  ]

  let adx_values = @indicator.adx(klines, 14)
  let last_adx = adx_values[adx_values.length() - 1]

  // ADX should be non-negative
  assert_true(last_adx >= Float::from_double(0.0))

  // Check trend strength helper
  assert_true(!@indicator.is_strong_trend(last_adx, Float::from_double(25.0)))

  @json.inspect(adx_values)
}
```

#### 商品通道指数 (CCI)

```mbt check-disabled
///|
test "cci calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 11.3, 11.8, 11.1, 11.6, 1300.0, 13000.0, 0.062,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 11.6, 12.0, 11.4, 11.9, 1400.0, 14000.0, 0.065,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 11.9, 12.3, 11.7, 12.1, 1350.0, 13500.0, 0.063,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 12.1, 12.5, 11.9, 12.4, 1500.0, 15000.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 12.4, 12.8, 12.2, 12.6, 1450.0, 14500.0, 0.066,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 12.6, 13.0, 12.4, 12.8, 1600.0, 16000.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 12.8, 13.2, 12.6, 13.0, 1550.0, 15500.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 13.0, 13.4, 12.8, 13.2, 1700.0, 17000.0, 0.072,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 13.2, 13.6, 13.0, 13.4, 1650.0, 16500.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 13.4, 13.8, 13.2, 13.6, 1800.0, 18000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-16", 13.6, 14.0, 13.4, 13.8, 1750.0, 17500.0, 0.073,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-17", 13.8, 14.2, 13.6, 14.0, 1900.0, 19000.0, 0.078,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-18", 14.0, 14.4, 13.8, 14.2, 1850.0, 18500.0, 0.076,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-19", 14.2, 14.6, 14.0, 14.4, 2000.0, 20000.0, 0.08,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-20", 14.4, 14.8, 14.2, 14.6, 1950.0, 19500.0, 0.078,
    ),
  ]

  let cci_values = @indicator.cci(klines, 20)
  let last_cci = cci_values[cci_values.length() - 1]

  // CCI can range from -infinity to +infinity
  // Check that we got a valid value (not NaN or infinite)
  assert_true(last_cci > Float::from_double(-1000.0))
  assert_true(last_cci < Float::from_double(1000.0))

  @json.inspect(cci_values)
}
```

#### KDJ 随机指标

```mbt check-disabled
///|
test "kdj calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 11.3, 11.8, 11.1, 11.6, 1300.0, 13000.0, 0.062,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 11.6, 12.0, 11.4, 11.9, 1400.0, 14000.0, 0.065,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 11.9, 12.3, 11.7, 12.1, 1350.0, 13500.0, 0.063,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 12.1, 12.5, 11.9, 12.4, 1500.0, 15000.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 12.4, 12.8, 12.2, 12.6, 1450.0, 14500.0, 0.066,
    ),
  ]

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)
  let last_k = k_line[k_line.length() - 1]
  let last_d = d_line[d_line.length() - 1]
  let last_j = j_line[j_line.length() - 1]

  // K, D should be between 0 and 100
  assert_true(last_k >= Float::from_double(0.0))
  assert_true(last_k <= Float::from_double(100.0))
  assert_true(last_d >= Float::from_double(0.0))
  assert_true(last_d <= Float::from_double(100.0))

  // J can exceed 0-100 range (formula: J = 3*K - 2*D)
  assert_true(
    last_j ==
    Float::from_double(3.0) * last_k - Float::from_double(2.0) * last_d,
  )

  @json.inspect({ "k": k_line, "d": d_line, "j": j_line })
}
```

#### 威廉指标 (Williams %R)

```mbt check-disabled
///|
test "williams %r calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 11.3, 11.8, 11.1, 11.6, 1300.0, 13000.0, 0.062,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 11.6, 12.0, 11.4, 11.9, 1400.0, 14000.0, 0.065,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 11.9, 12.3, 11.7, 12.1, 1350.0, 13500.0, 0.063,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 12.1, 12.5, 11.9, 12.4, 1500.0, 15000.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 12.4, 12.8, 12.2, 12.6, 1450.0, 14500.0, 0.066,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 12.6, 13.0, 12.4, 12.8, 1600.0, 16000.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 12.8, 13.2, 12.6, 13.0, 1550.0, 15500.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 13.0, 13.4, 12.8, 13.2, 1700.0, 17000.0, 0.072,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 13.2, 13.6, 13.0, 13.4, 1650.0, 16500.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 13.4, 13.8, 13.2, 13.6, 1800.0, 18000.0, 0.075,
    ),
  ]

  let wr_values = @indicator.williams_r(klines, 14)
  let last_wr = wr_values[wr_values.length() - 1]

  // Williams %R should be between -100 and 0
  assert_true(last_wr >= Float::from_double(-100.0))
  assert_true(last_wr <= Float::from_double(0.0))

  @json.inspect(wr_values)
}
```

#### 能量潮指标 (OBV)

```mbt check-disabled
///|
test "obv calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
  ]

  let obv_values = @indicator.obv(klines)

  // OBV should be positive and increasing (since prices are rising)
  assert_true(obv_values.length() == klines.length())
  let mut i = 1
  while i < obv_values.length() {
    assert_true(obv_values[i] >= obv_values[i - 1])
    i = i + 1
  }

  @json.inspect(obv_values)
}
```

#### 布林带 (Bollinger Bands)

```mbt check-disabled
///|
test "bollinger bands calculation" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(109.0),
    Float::from_double(110.0),
    Float::from_double(111.0),
    Float::from_double(112.0),
    Float::from_double(113.0),
    Float::from_double(114.0),
    Float::from_double(115.0),
    Float::from_double(116.0),
    Float::from_double(117.0),
    Float::from_double(118.0),
    Float::from_double(119.0),
  ]

  let (upper, middle, lower) = @indicator.bollinger_bands(
    prices,
    20,
    Float::from_double(2.0),
  )

  // Upper band should be above middle band
  // Middle band should be above lower band
  let mut i = 0
  while i < upper.length() {
    assert_true(upper[i] >= middle[i])
    assert_true(middle[i] >= lower[i])
    i = i + 1
  }

  // Check %B helper function
  let percent_b = @indicator.bollinger_percent_b(
    Float::from_double(110.0),
    upper[upper.length() - 1],
    lower[lower.length() - 1],
  )
  assert_true(percent_b >= Float::from_double(0.0))
  assert_true(percent_b <= Float::from_double(1.0))

  @json.inspect({ "upper": upper, "middle": middle, "lower": lower })
}
```

#### 成交量加权平均价 (VWAP)

VWAP（Volume-Weighted Average Price）是成交量加权平均价，给出证券全天交易的平均价格（基于成交量和价格）。

**参数说明：**
- `klines`: K 线数据数组（需要包含成交量信息）

**公式：**
- 典型价格 (Typical Price) = (最高价 + 最低价 + 收盘价) / 3
- VWAP = Σ(典型价格 × 成交量) / Σ(成交量)

**解读：**
- 价格高于 VWAP：看涨（交易溢价）
- 价格低于 VWAP：看跌（交易折价）
- VWAP 可作为动态支撑/阻力位

```mbt check-disabled
///|
test "vwap calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
  ]

  // 计算 VWAP
  let vwap_values = @indicator.vwap(klines)

  // VWAP 值应该为正
  let mut i = 0
  while i < vwap_values.length() {
    assert_true(vwap_values[i] > Float::from_double(0.0))
    i = i + 1
  }

  // 检查价格与 VWAP 的关系
  let last_kline = klines[klines.length() - 1]
  let last_vwap = vwap_values[vwap_values.length() - 1]

  // 典型价格辅助函数
  let tp = @indicator.typical_price(last_kline)
  assert_true(tp > Float::from_double(0.0))

  // 检查价格位置
  assert_true(@indicator.is_above_vwap(last_kline, last_vwap) == false)
  assert_true(@indicator.is_below_vwap(last_kline, last_vwap) == false)

  // VWAP 偏离百分比
  let deviation = @indicator.vwap_deviation(last_kline, last_vwap)
  assert_true(deviation > Float::from_double(-100.0))
  assert_true(deviation < Float::from_double(100.0))

  // 获取价格相对位置枚举
  let position = @indicator.vwap_position(last_kline, last_vwap)
  // position : VwapPosition (Above | Below | Equal)

  json_inspect({
    "vwap": vwap_values,
    "typical_price": tp,
    "deviation": deviation,
    "position": position,
  })
}
```

**辅助函数：**

```mbt check-disabled
///|
test "vwap with reset and bands" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 11.3, 11.8, 11.1, 11.6, 1300.0, 13000.0, 0.062,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 11.6, 12.0, 11.4, 11.9, 1400.0, 14000.0, 0.065,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 11.9, 12.3, 11.7, 12.1, 1350.0, 13500.0, 0.063,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 12.1, 12.5, 11.9, 12.4, 1500.0, 15000.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 12.4, 12.8, 12.2, 12.6, 1450.0, 14500.0, 0.066,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 12.6, 13.0, 12.4, 12.8, 1600.0, 16000.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 12.8, 13.2, 12.6, 13.0, 1550.0, 15500.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 13.0, 13.4, 12.8, 13.2, 1700.0, 17000.0, 0.072,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 13.2, 13.6, 13.0, 13.4, 1650.0, 16500.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 13.4, 13.8, 13.2, 13.6, 1800.0, 18000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-16", 13.6, 14.0, 13.4, 13.8, 1750.0, 17500.0, 0.073,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-17", 13.8, 14.2, 13.6, 14.0, 1900.0, 19000.0, 0.078,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-18", 14.0, 14.4, 13.8, 14.2, 1850.0, 18500.0, 0.076,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-19", 14.2, 14.6, 14.0, 14.4, 2000.0, 20000.0, 0.08,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-20", 14.4, 14.8, 14.2, 14.6, 1950.0, 19500.0, 0.078,
    ),
  ]

  // 带周期重置的 VWAP（每 20 期重置）
  let vwap_reset = @indicator.vwap_with_reset(klines, 20)
  assert_true(vwap_reset.length() == klines.length())

  // VWAP 带宽指标（类似布林带）
  let (upper, vwap, lower) = @indicator.vwap_bands(klines, 10, Float::from_double(2.0))

  // 验证：上轨 >= VWAP >= 下轨
  let mut i = 0
  while i < vwap.length() {
    assert_true(upper[i] >= vwap[i])
    assert_true(vwap[i] >= lower[i])
    i = i + 1
  }

  json_inspect({
    "vwap_reset": vwap_reset,
    "upper_band": upper,
    "vwap": vwap,
    "lower_band": lower,
  })
}
```

#### 阿隆指标 (Aroon)

阿隆指标是一个趋势跟踪指标，通过测量新高和新低之间的时间来识别趋势方向。它由两条线组成：Aroon Up 和 Aroon Down。

**参数说明：**
- `klines`: K 线数据数组
- `period`: 回溯周期（通常 25 或 14）

**公式：**
- Aroon Up = ((周期 - 距离最高价天数) / 周期) × 100
- Aroon Down = ((周期 - 距离最低价天数) / 周期) × 100
- Aroon Oscillator = Aroon Up - Aroon Down

**解读：**
- Aroon Up > Aroon Down：上升趋势
- Aroon Down > Aroon Up：下降趋势
- 两者都低（< 50）：盘整/震荡市场
- 两者都高（> 70）：强劲趋势

```mbt check-disabled
///|
test "aroon calculation" {
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
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.6, 11.0, 1200.0, 12000.0, 0.058,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.3, 1150.0, 11500.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 11.3, 11.8, 11.1, 11.6, 1300.0, 13000.0, 0.062,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 11.6, 12.0, 11.4, 11.9, 1400.0, 14000.0, 0.065,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 11.9, 12.3, 11.7, 12.1, 1350.0, 13500.0, 0.063,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 12.1, 12.5, 11.9, 12.4, 1500.0, 15000.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 12.4, 12.8, 12.2, 12.6, 1450.0, 14500.0, 0.066,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 12.6, 13.0, 12.4, 12.8, 1600.0, 16000.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 12.8, 13.2, 12.6, 13.0, 1550.0, 15500.0, 0.068,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 13.0, 13.4, 12.8, 13.2, 1700.0, 17000.0, 0.072,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 13.2, 13.6, 13.0, 13.4, 1650.0, 16500.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 13.4, 13.8, 13.2, 13.6, 1800.0, 18000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-16", 13.6, 14.0, 13.4, 13.8, 1750.0, 17500.0, 0.073,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-17", 13.8, 14.2, 13.6, 14.0, 1900.0, 19000.0, 0.078,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-18", 14.0, 14.4, 13.8, 14.2, 1850.0, 18500.0, 0.076,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-19", 14.2, 14.6, 14.0, 14.4, 2000.0, 20000.0, 0.08,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-20", 14.4, 14.8, 14.2, 14.6, 1950.0, 19500.0, 0.078,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-21", 14.6, 15.0, 14.4, 14.8, 2100.0, 21000.0, 0.082,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-22", 14.8, 15.2, 14.6, 15.0, 2050.0, 20500.0, 0.08,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-23", 15.0, 15.4, 14.8, 15.2, 2200.0, 22000.0, 0.085,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-24", 15.2, 15.6, 15.0, 15.4, 2150.0, 21500.0, 0.083,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-25", 15.4, 15.8, 15.2, 15.6, 2300.0, 23000.0, 0.088,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-26", 15.6, 16.0, 15.4, 15.8, 2250.0, 22500.0, 0.086,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-27", 15.8, 16.2, 15.6, 16.0, 2400.0, 24000.0, 0.09,
    ),
  ]

  // 计算 Aroon（周期 25）
  let (aroon_up, aroon_down) = @indicator.aroon(klines, 25)

  // Aroon 值范围 0-100
  let mut i = 0
  while i < aroon_up.length() {
    assert_true(aroon_up[i] >= Float::from_double(0.0))
    assert_true(aroon_up[i] <= Float::from_double(100.0))
    assert_true(aroon_down[i] >= Float::from_double(0.0))
    assert_true(aroon_down[i] <= Float::from_double(100.0))
    i = i + 1
  }

  // Aroon Oscillator
  let oscillator = @indicator.aroon_oscillator(klines, 25)
  assert_true(oscillator[oscillator.length() - 1] >= Float::from_double(-100.0))
  assert_true(oscillator[oscillator.length() - 1] <= Float::from_double(100.0))

  // 趋势判断辅助函数
  let last_up = aroon_up[aroon_up.length() - 1]
  let last_down = aroon_down[aroon_down.length() - 1]

  assert_true(@indicator.is_aroon_uptrend(last_up, last_down) == true)
  assert_true(@indicator.is_aroon_downtrend(last_up, last_down) == false)

  // 获取趋势状态枚举
  let trend = @indicator.get_aroon_trend(last_up, last_down)
  // trend : AroonTrend (StrongUptrend | Uptrend | Neutral | Downtrend | StrongDowntrend | Consolidation)

  json_inspect({
    "aroon_up": aroon_up,
    "aroon_down": aroon_down,
    "oscillator": oscillator,
    "trend": trend,
  })
}
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
