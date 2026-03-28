# 测试指南

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [测试概述](#测试概述)
2. [单元测试](#单元测试)
3. [集成测试](#集成测试)
4. [回测测试](#回测测试)
5. [前端测试](#前端测试)
6. [测试工具](#测试工具)
7. [最佳实践](#最佳实践)

---

## 测试概述

### 测试类型

本系统采用多层级测试策略：

| 测试类型 | 目的 | 位置 |
|----------|------|------|
| 单元测试 | 测试单个函数/模块 | `src/*/*_test.mbt` |
| 白盒测试 | 测试内部逻辑 | `src/*/*_wbtest.mbt` |
| 集成测试 | 测试模块间交互 | `src/*/integration_test.mbt` |
| 回测测试 | 验证策略回测结果 | `src/backtest/*_test.mbt` |
| 前端测试 | 测试 Web 界面功能 | `www/*_test.js` |

### 测试命令

```bash
# 运行所有测试
moon test

# 运行特定目录测试
moon test src/indicator

# 运行单个测试文件
moon test src/indicator/rsi_test.mbt

# 更新快照测试
moon test --update

# 使用过滤器运行测试
moon test -F "test_rsi"

# 显示详细输出
moon test --verbose
```

### 测试文件命名

| 类型 | 命名模式 | 示例 |
|------|----------|------|
| 黑盒测试 | `*_test.mbt` | `rsi_test.mbt` |
| 白盒测试 | `*_wbtest.mbt` | `bollinger_wbtest.mbt` |
| 集成测试 | `integration_test.mbt` | `integration_test.mbt` |

---

## 单元测试

### 测试结构

```mbt
/// 测试模块

use src/indicator/rsi  // 被测试模块

/// 测试用例
@test fn test_rsi_normal {
  // 准备测试数据
  let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0]

  // 执行测试
  let result = rsi(prices, 14)

  // 断言结果
  assert_eq(result.length(), prices.length())
}
```

### 断言函数

| 断言 | 说明 | 示例 |
|------|------|------|
| `assert_eq` | 相等断言 | `assert_eq(a, b)` |
| `assert_true` | 真值断言 | `assert_true(x > 0)` |
| `assert_false` | 假值断言 | `assert_false(x < 0)` |
| `assert_float_eq` | 浮点相等 | `assert_float_eq(a, b, 0.0001)` |
| `assert_neq` | 不等断言 | `assert_neq(a, b)` |

### 测试示例：指标测试

```mbt
/// RSI 指标测试

use src/indicator/rsi

/// 测试正常 RSI 计算
@test fn test_rsi_calculation {
  let prices = [
    100.0, 102.0, 101.0, 103.0, 105.0,
    104.0, 106.0, 108.0, 107.0, 109.0,
    110.0, 112.0, 111.0, 113.0, 115.0,
    114.0, 116.0, 118.0, 117.0, 119.0
  ]

  let result = rsi(prices, 14)

  // 验证长度
  assert_eq(result.length(), prices.length())

  // 验证前导零 (前 14 个值应为 0)
  let mut i = 0
  while i < 14 {
    assert_eq(result[i], 0.0)
    i = i + 1
  }

  // 验证第一个非零值在有效范围内
  let first_value = result[14]
  assert_true(first_value >= 0.0 && first_value <= 100.0)
}

/// 测试数据不足情况
@test fn test_rsi_insufficient_data {
  let prices = [100.0, 102.0, 101.0]
  let result = rsi(prices, 14)

  // 应该返回全零数组
  assert_eq(result.length(), prices.length())
  assert_true(result.all(fn(x) { x == 0.0 }))
}

/// 测试 RSI 范围
@test fn test_rsi_range {
  // 创建持续上涨的价格序列 (RSI 应接近 100)
  let bullish_prices = [100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0,
                        110.0, 111.0, 112.0, 113.0, 114.0, 115.0, 116.0, 117.0, 118.0, 119.0]
  let bullish_rsi = rsi(bullish_prices, 14)
  let last_bullish = bullish_rsi[bullish_rsi.length() - 1]

  // 持续上涨时 RSI 应接近 100
  assert_true(last_bullish > 70.0)

  // 创建持续下跌的价格序列 (RSI 应接近 0)
  let bearish_prices = [120.0, 119.0, 118.0, 117.0, 116.0, 115.0, 114.0, 113.0, 112.0, 111.0,
                        110.0, 109.0, 108.0, 107.0, 106.0, 105.0, 104.0, 103.0, 102.0, 101.0]
  let bearish_rsi = rsi(bearish_prices, 14)
  let last_bearish = bearish_rsi[bearish_rsi.length() - 1]

  // 持续下跌时 RSI 应接近 0
  assert_true(last_bearish < 30.0)
}

/// 测试辅助函数
@test fn test_is_overbought {
  assert_true(is_overbought(75.0, 70.0))
  assert_true(is_overbought(80.0, 70.0))
  assert_false(is_overbought(65.0, 70.0))
  assert_false(is_overbought(70.0, 70.0))  // 等于阈值
}

@test fn test_is_oversold {
  assert_true(is_oversold(25.0, 30.0))
  assert_true(is_oversold(20.0, 30.0))
  assert_false(is_oversold(35.0, 30.0))
  assert_false(is_oversold(30.0, 30.0))  // 等于阈值
}
```

### 测试示例：策略测试

```mbt
/// 均线交叉策略测试

use src/strategy/builtins/ma_cross
use src/strategy/types
use src/data/types

/// 测试金叉信号
@test fn test_ma_cross_golden_cross {
  // 创建价格上涨序列 (快均线上穿慢均线)
  let prices = [100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0,
                115.0, 120.0, 125.0, 130.0, 135.0]  // 突然大幅上涨

  let klines = prices.map_indexed(fn(price, i) {
    KLine::{
      code: StockCode::from_string("sh.600000"),
      date: "2023-01-" + (i + 1).to_string(),
      open: price,
      high: price + 1.0,
      low: price - 1.0,
      close: price,
      volume: 1000000.0,
      amount: 1000000.0 * price,
      turn: 0.01
    }
  })

  let strategy = create_ma_cross_strategy(5, 10)
  let ctx = StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: prices[prices.length() - 1],
    last_signal: None
  }

  let close_history = prices
  let signal = strategy.on_bar(klines[klines.length() - 1], ctx, close_history)

  // 验证信号类型
  assert_eq(signal.action, Action::Buy)
  // 验证信号强度
  assert_true(signal.strength > 0.5)
}

/// 测试死叉信号
@test fn test_ma_cross_death_cross {
  // 创建价格下跌序列
  let prices = [135.0, 134.0, 133.0, 132.0, 131.0, 130.0, 129.0, 128.0, 127.0, 126.0,
                120.0, 115.0, 110.0, 105.0, 100.0]  // 突然大幅下跌

  let strategy = create_ma_cross_strategy(5, 10)

  // ... 类似金叉测试 ...
}

/// 测试持仓状态
@test fn test_strategy_with_position {
  let strategy = create_ma_cross_strategy(5, 10)
  let ctx = StrategyContext::{
    capital: 50000.0,
    position: 50000.0,  // 已有持仓
    current_price: 100.0,
    last_signal: Some(Signal::buy(...))
  }

  // 测试策略在持仓情况下的行为
}
```

---

## 白盒测试

白盒测试用于测试模块内部逻辑，可以访问私有函数。

### 测试结构

```mbt
/// 白盒测试文件

use src/indicator/bollinger  // 使用内部模块

/// 测试内部函数
@test fn test_bollinger_internal_calculation {
  // 可以访问私有函数和内部状态
  let result = internal_helper_function(...)
  assert_eq(result, expected)
}
```

### 白盒测试示例

```mbt
/// Bollinger Bands 白盒测试

use src/indicator/bollinger

/// 测试标准差计算
@test fn test_standard_deviation_calculation {
  let prices = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0]
  let period = 8

  // 测试内部标准差计算逻辑
  let mean = 5.0  // 预期均值
  let expected_std = 2.0  // 预期标准差

  // 访问内部计算
  let actual_std = calculate_std(prices, period)
  assert_float_eq(actual_std, expected_std, 0.0001)
}

/// 测试边界情况处理
@test fn test_band_width_calculation_edge_case {
  // 测试带宽为零的情况
  let upper = 100.0
  let lower = 100.0
  let middle = 100.0

  let width = bollinger_band_width(upper, lower, middle)
  assert_eq(width, 0.0)
}
```

---

## 集成测试

集成测试验证多个模块间的交互。

### 测试结构

```mbt
/// 集成测试

use src/indicator/*
use src/strategy/*
use src/backtest/*

/// 测试指标与策略集成
@test fn test_indicator_strategy_integration {
  // 1. 计算指标
  let rsi_values = rsi(prices, 14)

  // 2. 策略使用指标生成信号
  let strategy = create_rsi_strategy()
  let signal = strategy.on_bar(...)

  // 3. 验证信号正确性
  assert_eq(signal.action, Action::Buy)
}
```

### 集成测试示例

```mbt
/// 回测集成测试

use src/backtest/engine
use src/backtest/types
use src/strategy/builtins/ma_cross
use src/data/loader

/// 测试完整回测流程
@test fn test_full_backtest_workflow {
  // 1. 加载数据
  let klines = load_test_klines("test_data.csv")

  // 2. 创建策略
  let strategy = create_ma_cross_strategy(10, 30)

  // 3. 配置回测
  let config = BacktestConfig::{
    start_date: "2023-01-01",
    end_date: "2023-12-31",
    initial_capital: 100000.0,
    commission_rate: 0.0003,
    slippage: 0.001,
    benchmark: None
  }

  // 4. 执行回测
  let engine = create_backtest_engine(config)
  let result = run_backtest(engine, klines, strategy)

  // 5. 验证结果
  assert_true(result.final_capital > 0.0)
  assert_true(result.total_trades > 0)
  assert_true(result.equity_curve.length() > 0)
}

/// 测试风控与策略集成
@test fn test_risk_strategy_integration {
  let strategy = create_aggressive_strategy()
  let config = default_backtest_config()
  let mut engine = create_backtest_engine(config)

  // 添加风控规则
  engine.risk_engine.add_rule(max_drawdown_rule(0.20))
  engine.risk_engine.add_rule(position_limit_rule(0.95))

  // 执行回测
  let result = run_backtest(engine, klines, strategy)

  // 验证风控生效
  assert_true(result.max_drawdown <= 0.20)
}
```

---

## 回测测试

### 测试策略回测

```mbt
/// 策略回测测试

use src/backtest/*
use src/strategy/builtins/*

/// 测试 MA 交叉策略回测
@test fn test_ma_cross_backtest {
  let klines = load_test_klines("trending_market.csv")
  let strategy = create_ma_cross_strategy(10, 30)
  let config = default_backtest_config()

  let engine = create_backtest_engine(config)
  let result = run_backtest(engine, klines, strategy)

  // 在趋势市场中，MA 交叉策略应该盈利
  assert_true(result.total_return > 0.0)

  // 验证交易执行
  assert_true(result.total_trades >= 2)  // 至少一次买入和卖出
}

/// 测试震荡市场中的策略
@test fn test_strategy_in_choppy_market {
  let klines = load_test_klines("choppy_market.csv")
  let strategy = create_ma_cross_strategy(10, 30)
  let config = default_backtest_config()

  let engine = create_backtest_engine(config)
  let result = run_backtest(engine, klines, strategy)

  // 在震荡市场中，MA 交叉策略可能亏损
  // 但回撤应该在可控范围内
  assert_true(result.max_drawdown < 0.30)
}
```

### 快照测试

```mbt
/// 快照测试 - 验证回测结果稳定性

use src/backtest/*

@test fn test_backtest_snapshot {
  let klines = load_test_klines("standard_test.csv")
  let strategy = create_ma_cross_strategy(10, 30)
  let config = default_backtest_config()

  let engine = create_backtest_engine(config)
  let result = run_backtest(engine, klines, strategy)

  // 快照断言 - 与保存的预期结果比较
  assert_snapshot(result, "ma_cross_standard_result")
}

// 运行以下命令更新快照:
// moon test --update
```

---

## 前端测试

### JavaScript 单元测试

```javascript
// www/api_test.js

import { API } from './api.js';

// 测试 API 客户端
describe('API Client', () => {
  test('getStocks returns array', async () => {
    const stocks = await API.getStocks();
    expect(Array.isArray(stocks)).toBe(true);
  });

  test('getKlines with invalid code throws error', async () => {
    await expect(API.getKlines('invalid_code'))
      .rejects
      .toThrow('Invalid stock code');
  });

  test('runBacktest sends correct payload', async () => {
    const config = {
      stock_code: 'sh.600000',
      strategy: 'ma_cross',
      start_date: '2023-01-01',
      end_date: '2023-12-31'
    };

    const result = await API.runBacktest(config);
    expect(result.status).toBe('success');
  });
});

// 测试筛选器组件
describe('StockScreener', () => {
  test('applies fundamental filters correctly', () => {
    const stocks = [
      { code: 'sh.600000', pe_ratio: 5, roe: 0.15 },
      { code: 'sh.600001', pe_ratio: 25, roe: 0.10 }
    ];

    const filtered = StockScreener.applyFilters(stocks, {
      max_pe: 20,
      min_roe: 0.12
    });

    expect(filtered.length).toBe(1);
    expect(filtered[0].code).toBe('sh.600000');
  });

  test('combines multiple filters with AND logic', () => {
    // 测试多条件组合
  });
});
```

### 运行前端测试

```bash
# 使用 Jest
npx jest www/*_test.js

# 使用 Vitest
npx vitest run
```

---

## 测试工具

### 测试数据生成

```mbt
/// 测试工具模块

/// 生成测试 K 线数据
pub fn create_test_klines(
  count : Int,
  start_price : Float,
  volatility : Float,
) -> Array[KLine] {
  let klines : Array[KLine] = []
  let mut price = start_price
  let mut i = 0

  while i < count {
    let change = (Random.float() - 0.5) * volatility * price
    price = price + change

    klines.push(KLine::{
      code: StockCode::from_string("sh.600000"),
      date: "2023-01-" + (i + 1).to_string(),
      open: price,
      high: price * 1.02,
      low: price * 0.98,
      close: price,
      volume: 1000000.0,
      amount: 1000000.0 * price,
      turn: 0.01
    })

    i = i + 1
  }

  klines
}

/// 生成上涨趋势数据
pub fn create_bullish_klines(count : Int) -> Array[KLine] {
  create_test_klines_with_trend(count, 100.0, 0.02, 0.015)  // 上涨趋势
}

/// 生成下跌趋势数据
pub fn create_bearish_klines(count : Int) -> Array[KLine] {
  create_test_klines_with_trend(count, 100.0, 0.02, -0.015)  // 下跌趋势
}

/// 生成震荡数据
pub fn create_choppy_klines(count : Int) -> Array[KLine] {
  create_test_klines(count, 100.0, 0.03)  // 高波动无趋势
}
```

### 测试辅助函数

```mbt
/// 浮点数比较辅助函数
pub fn assert_float_eq(
  actual : Float,
  expected : Float,
  tolerance : Float,
) -> Unit {
  let diff = Float::abs(actual - expected)
  if diff > tolerance {
    panic("Float assertion failed: " +
          actual.to_string() + " != " + expected.to_string() +
          " (diff: " + diff.to_string() + ")")
  }
}

/// 数组内容比较
pub fn assert_arrays_eq(
  actual : Array[Float],
  expected : Array[Float],
  tolerance : Float,
) -> Unit {
  if actual.length() != expected.length() {
    panic("Array length mismatch: " +
          actual.length().to_string() + " != " + expected.length().to_string())
  }

  let mut i = 0
  while i < actual.length() {
    assert_float_eq(actual[i], expected[i], tolerance)
    i = i + 1
  }
}
```

---

## 最佳实践

### 测试设计原则

1. **FIRST 原则**:
   - **F**ast: 测试要快速执行
   - **I**ndependent: 测试相互独立
   - **R**epeatable: 可重复执行
   - **S**elf-validating: 自动验证结果
   - **T**imely: 及时编写

2. **AAA 模式**:
   ```mbt
   @test fn test_example {
     // Arrange - 准备数据
     let input = [100.0, 102.0, 101.0]

     // Act - 执行操作
     let result = my_function(input)

     // Assert - 断言结果
     assert_eq(result.length(), 3)
   }
   ```

3. **测试覆盖**:
   - 正常路径
   - 边界情况
   - 错误处理
   - 性能敏感路径

### 测试数据管理

1. **使用固定种子**:
   ```mbt
   Random.set_seed(42)  // 固定随机种子
   ```

2. **隔离测试数据**:
   ```mbt
   @test fn test_isolated {
     let data = create_fresh_data()  // 每次创建新数据
     // ...
   }
   ```

3. **清理测试资源**:
   ```mbt
   @test fn test_with_cleanup {
     let temp_file = create_temp_file()
     // ... 测试 ...
     delete_file(temp_file)  // 清理
   }
   ```

### 测试维护

1. **有意义的测试名称**:
   ```mbt
   // 好
   @test fn test_rsi_returns_values_in_range_0_to_100

   // 不好
   @test fn test_rsi_1
   ```

2. **单一职责**:
   ```mbt
   // 好：每个测试验证一件事
   @test fn test_rsi_length
   @test fn test_rsi_range
   @test fn test_rsi_leading_zeros

   // 不好：一个测试验证太多
   @test fn test_rsi_everything
   ```

3. **避免测试间的依赖**:
   ```mbt
   // 好：独立测试
   @test fn test_step_1 { ... }
   @test fn test_step_2 { ... }

   // 不好：依赖顺序
   @test fn test_all {
     step_1()
     step_2()  // 依赖 step_1
   }
   ```

---

## 常见问题

### Q1: 如何处理浮点数精度问题？

**答**: 使用容差比较：

```mbt
assert_float_eq(actual, expected, 0.0001)
```

### Q2: 测试随机性怎么办？

**答**: 使用固定随机种子：

```mbt
Random.set_seed(42)
let result = random_function()  // 现在可重复
```

### Q3: 如何测试耗时操作？

**答**: 使用超时断言：

```mbt
@test fn test_performance {
  let start = now()
  let result = slow_function()
  let elapsed = now() - start
  assert_true(elapsed < 1000)  // 小于 1 秒
}
```

### Q4: 如何组织大量测试？

**答**: 使用测试套件：

```mbt
/// RSI 测试套件
mod rsi_tests {
  @test fn test_calculation { ... }
  @test fn test_range { ... }
  @test fn test_boundary { ... }
}
```

### Q5: 测试失败如何调试？

**答**: 添加详细输出：

```mbt
@test fn test_debug {
  let result = my_function(input)
  println("Input: " + input.to_string())
  println("Result: " + result.to_string())
  println("Expected: " + expected.to_string())
  assert_eq(result, expected)
}
```

---

## 测试检查清单

在提交代码前：

- [ ] 所有单元测试通过
- [ ] 所有集成测试通过
- [ ] 新增代码有对应测试
- [ ] 边界情况已测试
- [ ] 测试名称清晰描述意图
- [ ] 没有测试间的依赖
- [ ] 快照测试已更新 (如需要)
- [ ] 测试覆盖率满足要求

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
