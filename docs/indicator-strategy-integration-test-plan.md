# 指标库与策略引擎集成测试计划

## 概述

本文档定义了指标库（indicator）与策略引擎（strategy）之间的集成测试方案。测试聚焦于跨组件数据流、策略执行端到端流程，以及多个指标组合使用的场景。

## 组件架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Layer    │───▶│  Indicator Lib  │───▶│ Strategy Engine │
│   (KLine data)  │    │  (SMA, EMA,     │    │   (Signal Gen)  │
│                 │    │   RSI, MACD...) │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                      │                       │
         ▼                      ▼                       ▼
   KLine 数组            指标值数组              交易信号
```

## 可用指标列表

| 指标 | 函数名 | 返回值 | 说明 |
|------|--------|--------|------|
| SMA | `sma(values, period)` | `Array[Float]` | 简单移动平均 |
| EMA | `ema(values, period)` | `Array[Float]` | 指数移动平均 |
| MACD | `macd(values, fast, slow, signal)` | `(Array, Array, Array)` | MACD 三线 |
| RSI | `rsi(values, period)` | `Array[Float]` | 相对强弱指数 |
| Bollinger Bands | `bollinger_bands(values, period, std_dev)` | `(Array, Array, Array)` | 布林带 |
| ATR | `atr(klines, period)` | `Array[Float]` | 平均真实波幅 |
| KDJ | `kdj(klines, n, m1, m2)` | `(Array, Array, Array)` | KDJ 指标 |
| Williams %R | `williams_r(klines, period)` | `Array[Float]` | 威廉指标 |
| Aroon | `aroon(klines, period)` | `(Array, Array)` | 阿隆指标 |
| OBV | `obv(klines)` | `Array[Float]` | 能量潮 |
| CCI | `cci(klines, period)` | `Array[Float]` | 商品通道指数 |
| VWAP | `vwap(klines)` | `Array[Float]` | 成交量加权平均价 |
| ADX | `adx(klines, period)` | `Array[Float]` | 平均趋向指数 |

## 测试类别

### 1. 数据流测试 (Data Flow Tests)

验证从数据层到指标层的正确数据传递。

#### 1.1 基础数据流测试

```mbt
test "data-flow: KLine 到指标数据转换" {
  // 测试目标：验证 KLine 数据能正确转换为指标输入
  // 组件：data.KLine → indicator.sma/ema/rsi
  // 预期：指标计算结果正确，边界条件处理正常
}
```

#### 1.2 多指标并行计算测试

```mbt
test "data-flow: 多指标并行计算" {
  // 测试目标：同一数据集上同时计算多个指标
  // 组件：indicator.sma + indicator.ema + indicator.rsi
  // 预期：各指标独立计算，互不干扰
}
```

#### 1.3 指标链式调用测试

```mbt
test "data-flow: 指标链式调用 (MACD 使用 EMA)" {
  // 测试目标：验证依赖其他指标的复合指标
  // 组件：indicator.macd → indicator.ema
  // 预期：链式计算结果正确
}
```

### 2. 策略执行测试 (Strategy Execution Tests)

验证策略引擎正确使用指标生成信号。

#### 2.1 单指标策略测试

```mbt
test "strategy: SMA 交叉策略" {
  // 测试目标：基于单一 SMA 指标的趋势策略
  // 组件：indicator.sma → strategy.on_bar → Signal
  // 场景：价格上穿/下穿 SMA 时的信号生成
}
```

#### 2.2 双指标组合策略测试

```mbt
test "strategy: SMA+RSI 组合策略" {
  // 测试目标：趋势指标 + 震荡指标的组合
  // 组件：indicator.sma + indicator.rsi → strategy
  // 场景：SMA 确认趋势，RSI 选择入场点
}
```

#### 2.3 多指标复杂策略测试

```mbt
test "strategy: MACD+RSI+Bollinger 三指标策略" {
  // 测试目标：多指标共振策略
  // 组件：indicator.macd + indicator.rsi + indicator.bollinger_bands
  // 场景：三个指标同时发出信号时执行交易
}
```

### 3. 端到端集成测试 (End-to-End Tests)

验证完整的数据到信号流水线。

#### 3.1 完整回测流程测试

```mbt
test "e2e: 完整回测流程" {
  // 测试目标：数据加载 → 指标计算 → 策略执行 → 信号生成
  // 组件：data → indicator → strategy → backtest engine
  // 场景：模拟真实回测环境
}
```

#### 3.2 Walk-Forward 分析集成测试

```mbt
test "e2e: Walk-Forward 分析中的指标策略集成" {
  // 测试目标：WFA 引擎中的指标策略集成
  // 组件：backtest.walk_forward → indicator → strategy
  // 场景：多个样本内外周期的策略验证
}
```

### 4. 边界条件测试 (Edge Case Tests)

#### 4.1 数据不足边界

```mbt
test "edge: 指标计算数据不足" {
  // 测试目标：历史数据少于指标所需周期
  // 场景：SMA(20) 只有 10 个数据点
  // 预期：返回适当默认值或空数组
}
```

#### 4.2 极端价格数据

```mbt
test "edge: 极端价格数据 (零值/负值)" {
  // 测试目标：KLine 数据包含零值或异常值
  // 场景：close=0 或 close<0
  // 预期：指标计算不崩溃，返回合理结果
}
```

#### 4.3 信号强度边界

```mbt
test "edge: 信号强度边界值" {
  // 测试目标：strength 字段超出 [0,1] 范围
  // 场景：计算出的 strength > 1 或 < 0
  // 预期：正确截断到有效范围
}
```

## 测试实现清单

### 优先级 P0 (核心功能)

- [ ] `test "data-flow: KLine 到指标数据转换"`
- [ ] `test "data-flow: 多指标并行计算"`
- [ ] `test "strategy: SMA 交叉策略"`
- [ ] `test "strategy: SMA+RSI 组合策略"`
- [ ] `test "e2e: 完整回测流程"`
- [ ] `test "edge: 指标计算数据不足"`

### 优先级 P1 (重要功能)

- [ ] `test "data-flow: 指标链式调用"`
- [ ] `test "strategy: MACD+RSI+Bollinger 三指标策略"`
- [ ] `test "e2e: Walk-Forward 分析集成"`
- [ ] `test "edge: 极端价格数据"`
- [ ] `test "edge: 信号强度边界值"`

### 优先级 P2 (增强测试)

- [ ] `test "data-flow: 大数组性能测试"`
- [ ] `test "strategy: 内置策略 RSI Mean Reversion 集成"`
- [ ] `test "strategy: 自定义策略注册"`
- [ ] `test "edge: 空数据集处理"`
- [ ] `test "edge: 单条数据边界"`

## 测试代码示例

### 示例 1: SMA 交叉策略测试

```mbt
test "integration: SMA crossover strategy with real data flow" {
  // Setup: Create realistic price data
  let klines = [
    @data.KLine::daily("sh.600000", "2024-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.01),
    @data.KLine::daily("sh.600000", "2024-01-02", 10.2, 10.8, 10.0, 10.5, 1100000.0, 11550000.0, 0.011),
    // ... more klines
  ]

  // Extract close prices for indicator calculation
  let close_prices = klines.map(fn(k) { k.close })

  // Calculate indicators
  let sma_short = @indicator.sma(close_prices, 5)
  let sma_long = @indicator.sma(close_prices, 20)

  // Create strategy that uses the indicators
  let strategy = @strategy.Strategy::{
    name: "SMA Crossover",
    on_init: fn(_) { },
    on_bar: fn(kline, _ctx, close_history) {
      let fast_ma = @indicator.sma(close_history, 5)
      let slow_ma = @indicator.sma(close_history, 20)
      let len = close_history.length()

      // Generate signal based on crossover
      if fast_ma[len - 1] > slow_ma[len - 1] && fast_ma[len - 2] <= slow_ma[len - 2] {
        @strategy.Signal::buy(kline.code, kline.close, kline.date, 0.8)
      } else if fast_ma[len - 1] < slow_ma[len - 1] && fast_ma[len - 2] >= slow_ma[len - 2] {
        @strategy.Signal::sell(kline.code, kline.close, kline.date, 0.8)
      } else {
        @strategy.Signal::hold(kline.code, kline.close, kline.date)
      }
    },
  }

  // Execute strategy through engine
  let engine = @strategy.create_strategy_engine(100000.0)
  let result = @strategy.process_bar(engine, strategy, klines[24], close_prices)

  // Verify signal generation
  assert_true(result.signal.action == @strategy.Action::Buy)
  assert_true(result.signal.strength > 0.7)
}
```

### 示例 2: 多指标组合测试

```mbt
test "integration: Multi-indicator confluence strategy" {
  // Test scenario: Strategy requiring multiple indicators to agree

  let close_prices = [/* 50+ data points */]

  // Calculate multiple indicators
  let rsi = @indicator.rsi(close_prices, 14)
  let (bb_upper, bb_middle, bb_lower) = @indicator.bollinger_bands(close_prices, 20, 2.0)
  let (macd_line, signal_line, histogram) = @indicator.macd(close_prices, 12, 26, 9)

  // Strategy: Buy when RSI oversold AND price at lower band AND MACD bullish
  let len = close_prices.length()
  let is_oversold = rsi[len - 1] < 30.0
  let at_lower_band = close_prices[len - 1] <= bb_lower[len - 1]
  let macd_bullish = histogram[len - 1] > 0.0

  if is_oversold && at_lower_band && macd_bullish {
    // Strong buy signal - all three indicators agree
    assert_true(true) // Signal would be generated
  }

  // Verify indicators don't interfere with each other
  assert_true(rsi.length() == close_prices.length())
  assert_true(bb_upper.length() == close_prices.length())
  assert_true(macd_line.length() == close_prices.length())
}
```

## 测试运行命令

```bash
# 运行所有集成测试
moon test src/backtest/integration_test.mbt

# 运行特定测试类别
moon test -F 'data-flow:*'
moon test -F 'strategy:*'
moon test -F 'e2e:*'
moon test -F 'edge:*'

# 运行指标相关测试
moon test src/indicator/

# 运行策略相关测试
moon test src/strategy/
```

## 成功标准

1. **编译通过**: `moon check` 无错误
2. **单元测试**: 所有指标单元测试通过 (832 tests)
3. **集成测试**: 所有跨组件测试通过
4. **端到端测试**: 完整流程测试通过
5. **边界测试**: 所有边界条件测试通过

## 持续集成

将以下检查添加到 CI 流程：

```yaml
# .github/workflows/test.yml
- name: Run indicator tests
  run: moon test src/indicator/

- name: Run strategy tests
  run: moon test src/strategy/

- name: Run integration tests
  run: moon test src/backtest/integration_test.mbt

- name: Verify moon check
  run: moon check
```

## 维护说明

- 添加新指标时，必须添加相应的集成测试
- 策略引擎修改后，需重新运行所有集成测试
- 每次提交前运行 `moon check && moon test`
- 定期审查测试覆盖率，确保关键路径被覆盖
