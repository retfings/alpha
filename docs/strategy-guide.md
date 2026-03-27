# 策略开发指南

**最后更新**: 2026-03-27

本文档介绍如何在量化回撤框架中开发和回测交易策略。

---

## 目录

- [策略开发入门](#策略开发入门)
- [Strategy 接口说明](#strategy-接口说明)
- [内置策略示例](#内置策略示例)
- [回测使用指南](#回测使用指南)

---

## 策略开发入门

### 策略开发流程

1. **理解策略接口** - 熟悉 `Strategy` 类型和回调函数
2. **编写策略逻辑** - 实现 `on_init` 和 `on_bar` 函数
3. **创建策略实例** - 使用 `Strategy` 结构体构造函数
4. **运行回测** - 使用回测引擎验证策略表现
5. **分析结果** - 查看回测报告，优化策略参数

### 策略文件组织

策略代码通常放置在 `src/strategy/builtins/` 目录下:

```
src/strategy/builtins/
├── ma_cross.mbt              # 均线交叉策略
├── momentum.mbt              # 动量策略
├── rsi_mean_reversion.mbt    # RSI 均值回归策略
└── moon.pkg                  # 包配置
```

### 最小策略示例

```moonbit
// 简单持有策略 (始终持有)
pub fn create_hold_strategy() -> @strategy.Strategy {
  @strategy.Strategy::{
    name: "Hold Strategy",
    on_init: fn(ctx) {
      io::println("策略初始化：始终持有")
    },
    on_bar: fn(kline, ctx, history) {
      // 始终返回持有信号
      @strategy.Signal::hold(kline.code, kline.close, kline.date)
    },
  }
}
```

---

## Strategy 接口说明

### 核心类型

#### Strategy 结构体

```moonbit
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (KLine, StrategyContext, Array[Float]) -> Signal
}
```

**字段说明**:
| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | String | 策略名称 |
| `on_init` | `(StrategyContext) -> Unit` | 初始化回调函数 |
| `on_bar` | `(KLine, StrategyContext, Array[Float]) -> Signal` | K 线数据回调函数 |

---

#### StrategyContext (策略上下文)

```moonbit
pub struct StrategyContext {
  capital : Float           // 当前总资金
  position : Float          // 当前持仓价值
  current_price : Float     // 当前价格
  last_signal : Signal?     // 上一个信号
}
```

**字段说明**:
| 字段 | 类型 | 说明 |
|------|------|------|
| `capital` | Float | 当前总资金 (现金 + 持仓) |
| `position` | Float | 当前持仓价值 |
| `current_price` | Float | 当前 K 线收盘价 |
| `last_signal` | Signal? | 上一个交易信号 |

---

#### Signal (交易信号)

```moonbit
pub struct Signal {
  stock : StockCode         // 股票代码
  action : Action           // 交易动作
  price : Float             // 信号价格
  timestamp : String        // 信号时间
  strength : Float          // 信号强度 (0.0 - 1.0)
}
```

---

#### Action (交易动作)

```moonbit
pub enum Action {
  Buy    // 买入
  Sell   // 卖出
  Hold   // 持有
} derive(Eq, Show, ToJson)
```

---

### 信号构造方法

```moonbit
// 创建买入信号
pub fn Signal::buy(
  stock : StockCode,
  price : Float,
  timestamp : String,
  strength : Float,
) -> Signal

// 创建卖出信号
pub fn Signal::sell(
  stock : StockCode,
  price : Float,
  timestamp : String,
  strength : Float,
) -> Signal

// 创建持有信号
pub fn Signal::hold(
  stock : StockCode,
  price : Float,
  timestamp : String,
) -> Signal
```

---

### 回调函数详解

#### on_init (初始化函数)

**签名**: `(StrategyContext) -> Unit`

**调用时机**: 回测开始前调用一次

**用途**:
- 打印策略信息
- 初始化内部状态
- 参数验证

**示例**:
```moonbit
on_init: fn(ctx) {
  io::println("策略初始化")
  io::println("初始资金：" + String::from_float(ctx.capital))
}
```

---

#### on_bar (K 线数据回调)

**签名**: `(KLine, StrategyContext, Array[Float]) -> Signal`

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `kline` | KLine | 当前 K 线数据 |
| `ctx` | StrategyContext | 策略上下文 |
| `history` | `Array[Float]` | 历史收盘价数组 |

**调用时机**: 每条新 K 线到来时调用

**返回值**: `Signal` - 交易信号

**示例**:
```moonbit
on_bar: fn(kline, ctx, history) {
  // 计算指标
  let ma5 = calculate_ma5(history)
  let ma20 = calculate_ma20(history)

  // 生成信号
  if ma5 > ma20 && ctx.position == 0.0 {
    Signal::buy(kline.code, kline.close, kline.date, 0.8)
  } else if ma5 < ma20 && ctx.position > 0.0 {
    Signal::sell(kline.code, kline.close, kline.date, 0.8)
  } else {
    Signal::hold(kline.code, kline.close, kline.date)
  }
}
```

---

## 内置策略示例

### 1. 均线交叉策略 (MA Cross)

**文件**: `src/strategy/builtins/ma_cross.mbt`

**策略逻辑**:
- 当短期均线上穿长期均线时买入
- 当短期均线下穿长期均线时卖出

**代码示例**:

```moonbit
pub fn create_ma_cross_strategy(
  short_period : Int,
  long_period : Int,
) -> @strategy.Strategy {
  @strategy.Strategy::{
    name: "MA Cross (\{short_period}/\{long_period})",
    on_init: fn(ctx) {
      io::println("均线交叉策略初始化")
      io::println("短周期：\{short_period}，长周期：\{long_period}")
    },
    on_bar: fn(kline, ctx, history) {
      if history.length() < long_period {
        return @strategy.Signal::hold(kline.code, kline.close, kline.date)
      }

      // 计算均线
      let short_ma = @indicator.sma(history, short_period)
      let long_ma = @indicator.sma(history, long_period)
      let prev_short_ma = @indicator.sma(history.take(history.length() - 1), short_period)
      let prev_long_ma = @indicator.sma(history.take(history.length() - 1), long_period)

      // 金叉买入
      if prev_short_ma <= prev_long_ma && short_ma > long_ma {
        return @strategy.Signal::buy(kline.code, kline.close, kline.date, 0.8)
      }

      // 死叉卖出
      if prev_short_ma >= prev_long_ma && short_ma < long_ma {
        return @strategy.Signal::sell(kline.code, kline.close, kline.date, 0.8)
      }

      @strategy.Signal::hold(kline.code, kline.close, kline.date)
    },
  }
}
```

**使用示例**:

```moonbit
// 创建 10/30 均线交叉策略
let strategy = create_ma_cross_strategy(10, 30)
```

---

### 2. 动量策略 (Momentum)

**文件**: `src/strategy/builtins/momentum.mbt`

**策略逻辑**:
- 计算 N 日动量 (收益率)
- 动量超过阈值时买入
- 动量低于阈值时卖出

**代码示例**:

```moonbit
pub fn create_momentum_strategy(
  lookback : Int,
  buy_threshold : Float,
  sell_threshold : Float,
) -> @strategy.Strategy {
  @strategy.Strategy::{
    name: "Momentum(\{lookback})",
    on_init: fn(ctx) {
      io::println("动量策略初始化")
      io::println("回看周期：\{lookback}")
      io::println("买入阈值：\{buy_threshold}")
      io::println("卖出阈值：\{sell_threshold}")
    },
    on_bar: fn(kline, ctx, history) {
      if history.length() < lookback + 1 {
        return @strategy.Signal::hold(kline.code, kline.close, kline.date)
      }

      // 计算动量 (N 日收益率)
      let prev_close = history[history.length() - lookback - 1]
      let current_close = history[history.length() - 1]
      let momentum = (current_close - prev_close) / prev_close

      // 动量超过阈值买入
      if momentum > buy_threshold && ctx.position == 0.0 {
        return @strategy.Signal::buy(kline.code, kline.close, kline.date, 0.7)
      }

      // 动量低于阈值卖出
      if momentum < sell_threshold && ctx.position > 0.0 {
        return @strategy.Signal::sell(kline.code, kline.close, kline.date, 0.7)
      }

      @strategy.Signal::hold(kline.code, kline.close, kline.date)
    },
  }
}
```

**使用示例**:

```moonbit
// 创建 20 日动量策略
let strategy = create_momentum_strategy(20, 0.05, -0.05)
```

---

### 3. RSI 均值回归策略

**文件**: `src/strategy/builtins/rsi_mean_reversion.mbt`

**策略逻辑**:
- RSI 低于超卖阈值时买入
- RSI 高于超买阈值时卖出

**代码示例**:

```moonbit
pub fn create_rsi_mean_reversion_strategy(
  rsi_period : Int,
  oversold : Float,
  overbought : Float,
) -> @strategy.Strategy {
  @strategy.Strategy::{
    name: "RSI Mean Reversion",
    on_init: fn(ctx) {
      io::println("RSI 均值回归策略初始化")
      io::println("RSI 周期：\{rsi_period}")
      io::println("超卖：\{oversold}，超买：\{overbought}")
    },
    on_bar: fn(kline, ctx, history) {
      if history.length() < rsi_period + 1 {
        return @strategy.Signal::hold(kline.code, kline.close, kline.date)
      }

      // 计算 RSI
      let rsi = @indicator.rsi(history, rsi_period)

      // 超卖买入
      if rsi < oversold && ctx.position == 0.0 {
        return @strategy.Signal::buy(kline.code, kline.close, kline.date, 0.6)
      }

      // 超买卖出
      if rsi > overbought && ctx.position > 0.0 {
        return @strategy.Signal::sell(kline.code, kline.close, kline.date, 0.6)
      }

      @strategy.Signal::hold(kline.code, kline.close, kline.date)
    },
  }
}
```

**使用示例**:

```moonbit
// 创建 RSI 均值回归策略 (14 日 RSI, 30/70 阈值)
let strategy = create_rsi_mean_reversion_strategy(14, 30.0, 70.0)
```

---

### 4. 自定义策略模板

```moonbit
// 自定义策略模板
pub fn create_custom_strategy(
  name : String,
  // 策略参数
) -> @strategy.Strategy {
  @strategy.Strategy::{
    name: name,
    on_init: fn(ctx) {
      // 初始化逻辑
      io::println("策略初始化：\{name}")
    },
    on_bar: fn(kline, ctx, history) {
      // 策略逻辑
      // 1. 计算指标
      // 2. 生成信号
      // 3. 返回 Signal
      @strategy.Signal::hold(kline.code, kline.close, kline.date)
    },
  }
}
```

---

## 回测使用指南

### CLI 回测

使用命令行运行回测:

```bash
# 设置环境变量运行回测
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2024-01-01 --end 2024-12-31" moon run cmd/main
```

**命令行参数**:
| 参数 | 说明 | 示例 |
|------|------|------|
| `--strategy` | 策略名称 | `ma_cross` |
| `--stock` | 股票代码 | `sh.600000` |
| `--start` | 开始日期 | `2024-01-01` |
| `--end` | 结束日期 | `2024-12-31` |
| `--capital` | 初始资金 | `100000` |
| `--commission` | 手续费率 | `0.0003` |

---

### MoonBit 代码回测

```moonbit
use src/data/loader
use src/strategy/builtins/ma_cross
use src/backtest/engine
use src/backtest/report

// 1. 加载数据
let klines = loader.load_klines_from_csv("data/sh_600000_2024.csv")

// 2. 创建策略
let strategy = ma_cross.create_ma_cross_strategy(10, 30)

// 3. 配置回测
let config = @strategy.BacktestConfig::{
  start_date: "2024-01-01",
  end_date: "2024-12-31",
  initial_capital: 100000.0,
  commission_rate: 0.0003,
  slippage: 0.001,
  benchmark: None,
}

// 4. 创建引擎
let engine = create_backtest_engine(config)

// 5. 运行回测
match klines {
  Ok(data) => {
    let result = run_backtest(engine, data, strategy)
    // 6. 打印结果
    print_backtest_result(result)
  }
  Err(e) => {
    io::println("加载数据失败：\{e}")
  }
}
```

---

### 回测结果解析

```moonbit
pub struct BacktestResult {
  initial_capital : Float       // 初始资金
  final_capital : Float         // 最终资金
  total_return : Float          // 总收益率
  max_drawdown : Float          // 最大回撤
  sharpe_ratio : Float          // 夏普比率
  total_trades : Int            // 交易次数
  equity_curve : Array[EquityPoint]  // 权益曲线
  trades : Array[Trade]         // 交易记录
  stats : BacktestStats         // 统计数据
}
```

**关键指标**:
| 指标 | 说明 | 计算方式 |
|------|------|----------|
| `total_return` | 总收益率 | (最终资金 - 初始资金) / 初始资金 |
| `max_drawdown` | 最大回撤 | 最大峰值到谷底的跌幅 |
| `sharpe_ratio` | 夏普比率 | 超额收益 / 收益波动率 |
| `total_trades` | 交易次数 | 买入 + 卖出次数 |

---

### 回测报告生成

```moonbit
use src/backtest/report

// 生成文本报告
let text_report = generate_text_report(result)
io::println(text_report)

// 生成 JSON 报告
let json_report = generate_json_report(result)
io::println(json_report)
```

**示例输出**:

```
===== 回测报告 =====
策略：MA Cross (10/30)
股票：sh.600000
期间：2024-01-01 ~ 2024-12-31

初始资金：100,000.00
最终资金：125,430.50
总收益率：25.43%

最大回撤：-8.52%
夏普比率：1.85
交易次数：24

年化收益率：25.43%
胜率：58.33%
盈亏比：1.85
```

---

## 策略开发最佳实践

### 1. 参数优化

```moonbit
// 使用网格搜索优化参数
fn optimize_ma_cross_params(
  klines : Array[KLine],
  short_range : Array[Int],
  long_range : Array[Int],
) -> (Int, Int, Float) {
  let mut best_short = 0
  let mut best_long = 0
  let mut best_return = -1.0

  for short in short_range {
    for long in long_range {
      if short >= long { continue }

      let strategy = create_ma_cross_strategy(short, long)
      let result = run_backtest(klines, strategy)

      if result.total_return > best_return {
        best_return = result.total_return
        best_short = short
        best_long = long
      }
    }
  }

  (best_short, best_long, best_return)
}
```

### 2. 避免未来函数

```moonbit
// 错误：使用了当前 K 线的收盘价做决策
on_bar: fn(kline, ctx, history) {
  // 这是未来函数！
  if kline.close > kline.high { ... }  // 不可能发生
}

// 正确：使用历史数据
on_bar: fn(kline, ctx, history) {
  // 使用已知的历史数据
  let ma = @indicator.sma(history, 20)
  if history[history.length() - 1] > ma { ... }
}
```

### 3. 处理数据不足

```moonbit
on_bar: fn(kline, ctx, history) {
  // 确保有足够的数据
  let required_bars = 30  // 策略需要的最少数据
  if history.length() < required_bars {
    return @strategy.Signal::hold(kline.code, kline.close, kline.date)
  }

  // 正常策略逻辑
  ...
}
```

### 4. 信号强度设置

```moonbit
// 根据信号置信度设置强度
fn calculate_signal_strength(
  momentum : Float,
  rsi : Float,
  ma_signal : Float,
) -> Float {
  let mut strength = 0.0

  // 多指标共振增强信号
  if momentum > 0.05 { strength = strength + 0.3 }
  if rsi < 30.0 { strength = strength + 0.3 }
  if ma_signal > 0.0 { strength = strength + 0.4 }

  // 限制在 0.0 - 1.0 范围
  Float::min(strength, 1.0)
}
```

---

## 常见问题

### Q: 如何选择策略参数？

A: 建议使用以下方法:
1. 网格搜索 - 尝试所有参数组合
2. 遗传算法 - 智能搜索参数空间
3. Walk-Forward 分析 - 样本内外验证

### Q: 策略回测表现好，实盘表现差？

A: 可能原因:
- 过拟合历史数据
- 未考虑交易成本
- 未考虑滑点影响
- 市场环境变化

### Q: 如何提高策略稳定性？

A: 建议:
1. 使用多参数组合
2. 分散投资多只股票
3. 加入风控规则
4. 定期进行 Walk-Forward 验证

---

## 参考资料

- [架构设计文档](architecture.md)
- [API 参考文档](api-reference.md)
- [Baostock API 文档](baostock-api.md)
