# 交易模型指南

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [交易模型概述](#交易模型概述)
2. [策略定义](#策略定义)
3. [信号生成](#信号生成)
4. [回测执行](#回测执行)
5. [内置策略](#内置策略)
6. [自定义策略开发](#自定义策略开发)
7. [风险管理](#风险管理)
8. [实战示例](#实战示例)

---

## 交易模型概述

### 什么是交易模型

交易模型是一套系统化的规则，用于定义何时买入、何时卖出以及持仓管理。本系统支持基于技术指标、财务指标和价格形态的多种交易模型。

### 核心组件

```
┌─────────────────────────────────────────────────────────────┐
│                      交易模型架构                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │   策略层    │ → │   信号层    │ → │   执行层        │   │
│  │  Strategy   │   │   Signal    │   │   Engine        │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
│         │                                   │                │
│         ▼                                   ▼                │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │   指标层    │   │   风控层    │   │   组合层        │   │
│  │  Indicator  │   │   Risk      │   │   Portfolio     │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 交易模型工作流程

```
1. 数据加载 → 2. 指标计算 → 3. 策略判断 → 4. 信号生成
                                              ↓
8. 结果分析 ← 7. 绩效统计 ← 6. 交易执行 ← 5. 风控检查
```

### 模型类型

| 类型 | 说明 | 适用场景 |
|------|------|----------|
| 趋势跟踪 | 跟随市场趋势交易 | 强趋势市场 |
| 均值回归 | 价格回归均值时交易 | 震荡市场 |
| 动量策略 | 追逐强势股票 | 成长股投资 |
| 套利策略 | 利用价格差异 | 配对交易 |

---

## 策略定义

### Strategy 结构

策略是交易模型的核心，定义了交易逻辑。

```mbt
pub struct Strategy {
  name : String                                    // 策略名称
  on_init : (StrategyContext) -> Unit              // 初始化函数
  on_bar : (KLine, StrategyContext, Array[Float]) -> Signal  // K 线处理函数
}
```

### StrategyContext 结构

策略上下文提供执行时的状态信息。

```mbt
pub struct StrategyContext {
  capital : Float        // 可用资金
  position : Float       // 当前持仓价值
  current_price : Float  // 当前价格
  last_signal : Signal?  // 上一个信号
}
```

### Signal 结构

交易信号包含完整的交易指令。

```mbt
pub struct Signal {
  stock : StockCode     // 股票代码
  action : Action       // 交易动作 (Buy/Sell/Hold)
  price : Float         // 交易价格
  timestamp : String    // 时间戳
  strength : Float      // 信号强度 (0.0-1.0)
}
```

### Action 枚举

```mbt
pub enum Action {
  Buy    // 买入
  Sell   // 卖出
  Hold   // 持有
}
```

### 策略定义示例

**均线交叉策略**:

```mbt
pub fn create_ma_cross_strategy(
  fast_period : Int,
  slow_period : Int,
) -> Strategy {
  Strategy::{
    name: "MA Cross (" + fast_period.to_string() + "/" + slow_period.to_string() + ")",
    on_init: fn(ctx) {
      println("策略初始化：可用资金 = " + ctx.capital.to_string())
    },
    on_bar: fn(kline, ctx, close_history) {
      // 检查数据是否足够
      if close_history.length() < slow_period {
        return Signal::hold(kline.code, kline.close, kline.date)
      }

      // 计算均线
      let fast_ma = sma(close_history, fast_period)
      let slow_ma = sma(close_history, slow_period)

      let current_fast = fast_ma[fast_ma.length() - 1]
      let current_slow = slow_ma[slow_ma.length() - 1]
      let prev_fast = fast_ma[fast_ma.length() - 2]
      let prev_slow = slow_ma[slow_ma.length() - 2]

      // 检测金叉
      if current_fast > current_slow && prev_fast <= prev_slow {
        return Signal::buy(kline.code, kline.close, kline.date, 0.8)
      }

      // 检测死叉
      if current_fast < current_slow && prev_fast >= prev_slow {
        return Signal::sell(kline.code, kline.close, kline.date, 0.8)
      }

      Signal::hold(kline.code, kline.close, kline.date)
    }
  }
}
```

---

## 信号生成

### 信号类型

#### 买入信号 (Buy)

**创建买入信号**:
```mbt
Signal::buy(
  stock = kline.code,
  price = kline.close,
  timestamp = kline.date,
  strength = 0.8  // 80% 置信度
)
```

**买入信号条件示例**:
- 均线上穿 (金叉)
- RSI 超卖反弹
- 突破阻力位
- 成交量放大

#### 卖出信号 (Sell)

**创建卖出信号**:
```mbt
Signal::sell(
  stock = kline.code,
  price = kline.close,
  timestamp = kline.date,
  strength = 0.7  // 70% 置信度
)
```

**卖出信号条件示例**:
- 均线下穿 (死叉)
- RSI 超买
- 跌破支撑位
- 止损触发

#### 持有信号 (Hold)

**创建持有信号**:
```mbt
Signal::hold(
  stock = kline.code,
  price = kline.close,
  timestamp = kline.date
)
```

**持有信号条件**:
- 无明确交易机会
- 等待更好入场点
- 持仓观察期

### 信号强度

信号强度表示策略对信号的置信度，范围 0.0-1.0。

| 强度范围 | 说明 | 使用场景 |
|----------|------|----------|
| 0.0-0.3 | 弱信号 | 边缘条件，低置信度 |
| 0.3-0.6 | 中等信号 | 标准条件满足 |
| 0.6-0.8 | 强信号 | 多指标确认 |
| 0.8-1.0 | 极强信号 | 极端条件，高置信度 |

### 信号生成示例

**多指标确认的买入信号**:

```mbt
fn generate_signal(kline, ctx, close_history, highs, lows, volumes) -> Signal {
  // 计算多个指标
  let rsi_vals = rsi(close_history, 14)
  let (upper, middle, lower) = bollinger_bands(close_history, 20, 2.0)
  let macd_result = macd(close_history, 12, 26, 9)

  let current_rsi = rsi_vals[rsi_vals.length() - 1]
  let current_price = kline.close
  let current_lower = lower[lower.length() - 1]

  var signal_strength = 0.0

  // 条件 1: RSI 超卖
  if current_rsi < 30.0 {
    signal_strength = signal_strength + 0.3
  }

  // 条件 2: 价格跌破下轨
  if current_price < current_lower {
    signal_strength = signal_strength + 0.3
  }

  // 条件 3: MACD 金叉
  if bullish_crossover(macd_result, macd_result.macd_line.length() - 1) {
    signal_strength = signal_strength + 0.4
  }

  // 生成信号
  if signal_strength >= 0.7 {
    Signal::buy(kline.code, kline.close, kline.date, signal_strength)
  } else {
    Signal::hold(kline.code, kline.close, kline.date)
  }
}
```

---

## 回测执行

### 回测配置

**BacktestConfig 结构**:

```mbt
pub struct BacktestConfig {
  start_date : String       // 开始日期
  end_date : String         // 结束日期
  initial_capital : Float   // 初始资金
  commission_rate : Float   // 手续费率
  slippage : Float          // 滑点
  benchmark : StockCode?    // 基准股票
}
```

**创建回测配置**:

```mbt
let config = BacktestConfig::{
  start_date: "2023-01-01",
  end_date: "2023-12-31",
  initial_capital: 100000.0,
  commission_rate: 0.0003,  // 万分之三
  slippage: 0.001,          // 0.1% 滑点
  benchmark: None
}
```

**使用默认配置**:

```mbt
let config = default_backtest_config()
```

### 回测引擎

**创建回测引擎**:

```mbt
let engine = create_backtest_engine(config)
```

**添加风控规则**:

```mbt
// 最大回撤规则
engine.risk_engine.add_rule(max_drawdown_rule(0.20))  // 20% 最大回撤

// 仓位限制规则
engine.risk_engine.add_rule(position_limit_rule(0.95))  // 95% 最大仓位

// 日损限制规则
engine.risk_engine.add_rule(daily_loss_limit_rule(0.05))  // 5% 日损限制
```

### 执行回测

**运行回测**:

```mbt
let klines = load_klines_from_csv("data/sh.600000.csv")
let strategy = create_ma_cross_strategy(10, 30)

let result = run_backtest(engine, klines, strategy)
```

### 回测结果

**BacktestResult 结构**:

```mbt
pub struct BacktestResult {
  initial_capital : Float       // 初始资金
  final_capital : Float         // 最终资金
  total_return : Float          // 总收益率
  max_drawdown : Float          // 最大回撤
  sharpe_ratio : Float          // 夏普比率
  total_trades : Int            // 总交易数
  win_rate : Float              // 胜率
  profit_factor : Float         // 盈亏比
  annual_return : Float         // 年化收益率
  sortino_ratio : Float         // 索提诺比率
  trades : Array[Trade]         // 交易记录
  equity_curve : Array[EquityPoint]  // 权益曲线
}
```

**分析回测结果**:

```mbt
println("总收益率：" + (result.total_return * 100).to_string() + "%")
println("最大回撤：" + (result.max_drawdown * 100).to_string() + "%")
println("夏普比率：" + result.sharpe_ratio.to_string())
println("胜率：" + (result.win_rate * 100).to_string() + "%")
println("总交易数：" + result.total_trades.to_string())
```

### 结果指标解释

| 指标 | 计算公式 | 说明 |
|------|----------|------|
| 总收益率 | (最终资金 - 初始资金) / 初始资金 | 整体盈利比例 |
| 年化收益率 | (1 + 总收益率)^(252/交易日数) - 1 | 年化收益 |
| 最大回撤 | 最大峰值到谷底的跌幅 | 风险控制指标 |
| 夏普比率 | (年化收益 - 无风险利率) / 收益波动率 | 风险调整收益 |
| 胜率 | 盈利交易数 / 总交易数 | 信号准确度 |
| 盈亏比 | 平均盈利 / 平均亏损 | 盈利质量 |

---

## 内置策略

系统提供多种内置策略，可直接使用。

### 均线交叉策略 (MA Cross)

**策略 ID**: `ma_cross`

**策略逻辑**:
- 快均线上穿慢均线 → 买入
- 快均线下穿慢均线 → 卖出

**参数**:
| 参数 | 默认值 | 说明 |
|------|--------|------|
| `fast_period` | 10 | 快均线周期 |
| `slow_period` | 30 | 慢均线周期 |

**CLI 使用**:
```bash
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000" moon run cmd/main
```

### 动量策略 (Momentum)

**策略 ID**: `momentum`

**策略逻辑**:
- RSI 低于超卖阈值 → 买入
- RSI 高于超买阈值 → 卖出

**参数**:
| 参数 | 默认值 | 说明 |
|------|--------|------|
| `rsi_period` | 14 | RSI 周期 |
| `overbought` | 70 | 超买阈值 |
| `oversold` | 30 | 超卖阈值 |

**CLI 使用**:
```bash
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy momentum --stock sz.000001" moon run cmd/main
```

### RSI 均值回归策略

**策略 ID**: `rsi_mean_reversion`

**策略逻辑**:
- RSI 超卖时买入，期待回归均值
- RSI 回归 50 中轴时卖出

**参数**:
| 参数 | 默认值 | 说明 |
|------|--------|------|
| `rsi_period` | 14 | RSI 周期 |
| `oversold` | 30 | 超卖阈值 |

**CLI 使用**:
```bash
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy rsi_mean_reversion --stock sh.600000" moon run cmd/main
```

---

## 自定义策略开发

### 策略开发步骤

#### 步骤 1: 创建策略文件

在 `src/strategy/builtins/` 目录下创建新文件，例如 `my_strategy.mbt`:

```mbt
/// 我的自定义策略

use src/data/types
use src/strategy/types
use src/indicator/ma
use src/indicator/rsi
```

#### 步骤 2: 定义策略参数

```mbt
pub struct MyStrategy {
  name : String
  ma_period : Int
  rsi_period : Int
  rsi_oversold : Float
  rsi_overbought : Float
}
```

#### 步骤 3: 实现策略逻辑

```mbt
pub fn create_my_strategy(
  ma_period : Int,
  rsi_period : Int,
  rsi_oversold : Float,
  rsi_overbought : Float,
) -> Strategy {
  Strategy::{
    name: "My Custom Strategy",
    on_init: fn(ctx) {
      println("策略初始化")
    },
    on_bar: fn(kline, ctx, close_history) {
      // 实现交易逻辑
      if close_history.length() < ma_period {
        return Signal::hold(kline.code, kline.close, kline.date)
      }

      // 计算指标
      let ma_values = sma(close_history, ma_period)
      let rsi_values = rsi(close_history, rsi_period)

      let current_ma = ma_values[ma_values.length() - 1]
      let current_rsi = rsi_values[rsi_values.length() - 1]
      let current_price = kline.close

      // 买入条件：价格在均线上方且 RSI 超卖
      if current_price > current_ma && current_rsi < rsi_oversold {
        return Signal::buy(kline.code, kline.close, kline.date, 0.7)
      }

      // 卖出条件：RSI 超买
      if current_rsi > rsi_overbought {
        return Signal::sell(kline.code, kline.close, kline.date, 0.7)
      }

      Signal::hold(kline.code, kline.close, kline.date)
    }
  }
}
```

#### 步骤 4: 注册策略

在策略注册表中添加新策略:

```mbt
pub fn get_builtin_strategies() -> Map[String, Strategy] {
  let mut strategies = Map::empty()
  strategies.set("my_strategy", create_my_strategy(20, 14, 30.0, 70.0))
  strategies
}
```

### 策略测试

**编写单元测试**:

```mbt
@test fn test_my_strategy_buy_signal {
  let strategy = create_my_strategy(20, 14, 30.0, 70.0)
  let klines = create_test_klines()  // 创建测试数据
  let ctx = create_test_context()
  let close_history = klines.map(fn(k) { k.close })

  let signal = strategy.on_bar(klines[klines.length() - 1], ctx, close_history)

  // 断言信号类型
  assert_eq(signal.action, Action::Buy)
  // 断言信号强度
  assert_true(signal.strength > 0.6)
}
```

**运行测试**:
```bash
moon test my_strategy_test
```

---

## 风险管理

### 风控规则类型

#### 最大回撤规则

限制组合从峰值的最大回撤。

```mbt
max_drawdown_rule(threshold: Float) -> RiskRule
// threshold: 最大回撤阈值，如 0.20 表示 20%
```

**使用示例**:
```mbt
engine.risk_engine.add_rule(max_drawdown_rule(0.20))
// 当回撤超过 20% 时，停止交易
```

#### 仓位限制规则

限制单个股票或总仓位上限。

```mbt
position_limit_rule(max_ratio: Float) -> RiskRule
// max_ratio: 最大仓位比例，如 0.95 表示 95%
```

**使用示例**:
```mbt
engine.risk_engine.add_rule(position_limit_rule(0.95))
// 始终保持至少 5% 现金
```

#### 止损规则

当亏损达到阈值时自动平仓。

```mbt
stop_loss_rule(threshold: Float) -> RiskRule
// threshold: 止损阈值，如 0.05 表示 5%
```

**使用示例**:
```mbt
engine.risk_engine.add_rule(stop_loss_rule(0.05))
// 单笔交易亏损 5% 时止损
```

#### 日损限制规则

限制单日最大亏损。

```mbt
daily_loss_limit_rule(threshold: Float) -> RiskRule
// threshold: 日损阈值，如 0.05 表示 5%
```

**使用示例**:
```mbt
engine.risk_engine.add_rule(daily_loss_limit_rule(0.05))
// 单日亏损超过 5% 时停止交易
```

#### 集中度过高规则

限制单一股票持仓占比。

```mbt
concentration_limit_rule(max_ratio: Float) -> RiskRule
// max_ratio: 单一股票最大占比
```

**使用示例**:
```mbt
engine.risk_engine.add_rule(concentration_limit_rule(0.30))
// 单一股票不超过 30% 仓位
```

### 风控引擎配置

**完整风控配置示例**:

```mbt
let config = default_backtest_config()
let mut engine = create_backtest_engine(config)

// 组合级风控
engine.risk_engine.add_rule(max_drawdown_rule(0.20))      // 最大回撤 20%
engine.risk_engine.add_rule(position_limit_rule(0.95))    // 最大仓位 95%

// 交易级风控
engine.risk_engine.add_rule(stop_loss_rule(0.08))         // 止损 8%
engine.risk_engine.add_rule(daily_loss_limit_rule(0.05))  // 日损 5%

// 持仓级风控
engine.risk_engine.add_rule(concentration_limit_rule(0.25))  // 单一股票 25%
```

### 风控检查流程

```
交易信号 → 风控检查 → 通过则执行
            ↓
       不通过则拒绝
```

**风控拒绝示例**:
```mbt
// 策略生成买入信号
let signal = strategy.on_bar(kline, ctx, history)

// 风控检查
if !risk_engine.check(signal, portfolio) {
  println("风控拒绝交易：" + signal.action.to_string())
  // 不执行交易
}
```

---

## 实战示例

### 示例 1: 双均线趋势策略

**策略描述**: 使用 10 日和 30 日双均线捕捉趋势。

**完整代码**:

```mbt
pub fn create_double_ma_trend_strategy() -> Strategy {
  let fast_period = 10
  let slow_period = 30

  Strategy::{
    name: "Double MA Trend",
    on_init: fn(ctx) {
      println("双均线趋势策略启动")
    },
    on_bar: fn(kline, ctx, close_history) {
      if close_history.length() < slow_period {
        return Signal::hold(kline.code, kline.close, kline.date)
      }

      let fast_ma = sma(close_history, fast_period)
      let slow_ma = sma(close_history, slow_period)

      let curr_fast = fast_ma[fast_ma.length() - 1]
      let curr_slow = slow_ma[slow_ma.length() - 1]
      let prev_fast = fast_ma[fast_ma.length() - 2]
      let prev_slow = slow_ma[slow_ma.length() - 2]

      // 金叉买入
      if curr_fast > curr_slow && prev_fast <= prev_slow {
        println("金叉信号：" + kline.code.to_string())
        return Signal::buy(kline.code, kline.close, kline.date, 0.8)
      }

      // 死叉卖出
      if curr_fast < curr_slow && prev_fast >= prev_slow {
        println("死叉信号：" + kline.code.to_string())
        return Signal::sell(kline.code, kline.close, kline.date, 0.8)
      }

      Signal::hold(kline.code, kline.close, kline.date)
    }
  }
}
```

**回测执行**:

```mbt
let strategy = create_double_ma_trend_strategy()
let config = BacktestConfig::{
  start_date: "2023-01-01",
  end_date: "2023-12-31",
  initial_capital: 100000.0,
  commission_rate: 0.0003,
  slippage: 0.001,
  benchmark: None
}

let mut engine = create_backtest_engine(config)
engine.risk_engine.add_rule(max_drawdown_rule(0.15))

let klines = load_klines("data/sh.600000.csv")
let result = run_backtest(engine, klines, strategy)

print_backtest_result(result)
```

### 示例 2: RSI 超卖反弹策略

**策略描述**: 在 RSI 超卖时买入，回归均值时卖出。

**完整代码**:

```mbt
pub fn create_rsi_oversold_bounce_strategy() -> Strategy {
  let rsi_period = 14
  let oversold_threshold = 30.0
  let exit_threshold = 50.0

  Strategy::{
    name: "RSI Oversold Bounce",
    on_init: fn(ctx) {
      println("RSI 超卖反弹策略启动")
    },
    on_bar: fn(kline, ctx, close_history) {
      if close_history.length() < rsi_period {
        return Signal::hold(kline.code, kline.close, kline.date)
      }

      let rsi_values = rsi(close_history, rsi_period)
      let current_rsi = rsi_values[rsi_values.length() - 1]
      let prev_rsi = rsi_values[rsi_values.length() - 2]

      // 超卖买入
      if current_rsi < oversold_threshold {
        return Signal::buy(kline.code, kline.close, kline.date, 0.7)
      }

      // 回归均值卖出 (仅在有持仓时)
      if ctx.position > 0.0 && current_rsi > exit_threshold {
        return Signal::sell(kline.code, kline.close, kline.date, 0.6)
      }

      Signal::hold(kline.code, kline.close, kline.date)
    }
  }
}
```

### 示例 3: 多策略组合

**策略描述**: 组合均线和 RSI 策略，通过加权投票生成信号。

**完整代码**:

```mbt
pub fn create_multi_strategy_portfolio() -> Strategy {
  let ma_strategy = create_double_ma_trend_strategy()
  let rsi_strategy = create_rsi_oversold_bounce_strategy()

  let ma_weight = 0.6
  let rsi_weight = 0.4

  Strategy::{
    name: "Multi-Strategy Portfolio",
    on_init: fn(ctx) {
      ma_strategy.on_init(ctx)
      rsi_strategy.on_init(ctx)
    },
    on_bar: fn(kline, ctx, close_history) {
      let ma_signal = ma_strategy.on_bar(kline, ctx, close_history)
      let rsi_signal = rsi_strategy.on_bar(kline, ctx, close_history)

      var buy_score = 0.0
      var sell_score = 0.0

      // 计算加权得分
      match ma_signal.action {
        Action::Buy => buy_score = buy_score + ma_weight * ma_signal.strength
        Action::Sell => sell_score = sell_score + ma_weight * ma_signal.strength
        _ => ()
      }

      match rsi_signal.action {
        Action::Buy => buy_score = buy_score + rsi_weight * rsi_signal.strength
        Action::Sell => sell_score = sell_score + rsi_weight * rsi_signal.strength
        _ => ()
      }

      // 根据得分生成信号
      if buy_score > 0.6 {
        Signal::buy(kline.code, kline.close, kline.date, buy_score)
      } else if sell_score > 0.6 {
        Signal::sell(kline.code, kline.close, kline.date, sell_score)
      } else {
        Signal::hold(kline.code, kline.close, kline.date)
      }
    }
  }
}
```

---

## 附录

### A. 策略开发最佳实践

1. **保持简单**: 避免过度复杂的逻辑
2. **充分测试**: 在不同市场条件下测试
3. **风控优先**: 始终配置适当的风控规则
4. **记录日志**: 便于调试和分析
5. **文档完整**: 说明策略逻辑和参数

### B. 常用参数参考

| 策略类型 | 参数 | 短期 | 中期 | 长期 |
|----------|------|------|------|------|
| 均线 | 周期 | 5-10 | 20-50 | 100-200 |
| RSI | 周期 | 7-10 | 14 | 21-30 |
| MACD | 参数 | 6,13,5 | 12,26,9 | 24,52,18 |
| 布林带 | 周期 | 10 | 20 | 50 |

### C. 性能评估标准

| 指标 | 优秀 | 良好 | 一般 |
|------|------|------|------|
| 年化收益 | >20% | 10-20% | <10% |
| 最大回撤 | <10% | 10-20% | >20% |
| 夏普比率 | >2 | 1-2 | <1 |
| 胜率 | >60% | 50-60% | <50% |

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
