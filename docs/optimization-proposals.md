# 代码优化建议书

本文档记录了代码库分析中发现的优化机会，按优先级分类。

---

## 高优先级 - 性能优化

### 1.1 find_top_drawdowns 使用 O(n²) 冒泡排序

**位置**: `src/drawdown/calculator.mbt:331-349`

**问题**:
```moonbit
// 当前实现：冒泡排序 O(n²)
while ii < result_len - 1 {
  while jj < result_len - ii - 1 {
    if result[jj].drawdown > result[jj + 1].drawdown {
      let temp = result[jj]
      result[jj] = result[jj + 1]
      result[jj + 1] = temp
    }
    jj = jj + 1
  }
  ii = ii + 1
}
```

当回撤事件数量增加时，性能急剧下降。对于 100 个回撤事件，需要约 5000 次比较。

**建议**: 改用快速排序或选择排序，仅需 O(n log n) 复杂度。

**修复方案**:
```moonbit
// 使用选择排序找 top n（当 n 远小于总数时更高效）
fn quick_select(arr : Array[DrawdownInfo], n : Int) -> Array[DrawdownInfo] {
  // 实现选择算法找前 n 个最小值（最严重的回撤）
}
```

---

### 1.2 sma 函数重复计算

**位置**: `src/indicator/ma.mbt:21-34`

**问题**:
```moonbit
// 每次都重新计算整个窗口的和
while i < len {
  let mut sum : Float = Float::from_double(0.0)
  let mut j = i - period + 1
  while j <= i {
    sum = sum + values[j]
    j = j + 1
  }
  result.push(sum / Float::from_int(period))
  i = i + 1
}
```

对于长度为 N 的时间序列和周期 P，当前实现需要 O(N*P) 次加法。

**建议**: 使用滑动窗口累加：
```moonbit
pub fn sma_optimized(values : Array[Float], period : Int) -> Array[Float] {
  if values.length() < period || period <= 0 {
    return values.map(fn(_) { Float::from_double(0.0) })
  }

  let result : Array[Float] = []
  let len = values.length()
  let mut i = 0
  let mut window_sum : Float = 0.0

  // 计算第一个窗口的和
  while i < period {
    window_sum = window_sum + values[i]
    i = i + 1
  }
  result.push(window_sum / Float::from_int(period))

  // 滑动窗口：减去最旧值，加上新值
  while i < len {
    window_sum = window_sum - values[i - period] + values[i]
    result.push(window_sum / Float::from_int(period))
    i = i + 1
  }

  result
}
```

优化后复杂度从 O(N*P) 降至 O(N)。

---

## 中优先级 - 代码质量

### 2.1 未使用的结构体字段

**位置**: `src/strategy/engine.mbt:8-17`

**问题**:
```moonbit
pub(all) struct StrategyResult {
  signal : Signal
  executed : Bool      // 从未读取
  exec_price : Float   // 从未使用
  exec_volume : Float  // 从未使用
}
```

**建议**: 移除未使用字段，简化结构：
```moonbit
pub(all) struct StrategyResult {
  signal : Signal
}
```

---

### 2.2 魔法数字硬编码

**位置**: `src/backtest/engine.mbt:146-150, 119`

**问题**:
```moonbit
let available_cash = engine.portfolio.cash * 0.95  // 为什么是 95%？
if close_history.length() < 20 {                   // 为什么是 20 根 K 线？
```

**建议**: 提取为配置常量：
```moonbit
// 在 strategy/types.mbt 中
pub struct BacktestConfig {
  // ... existing fields ...
  max_position_ratio : Float  // 默认 0.95
  min_history_length : Int    // 默认 20
}

// 在 engine.mbt 中
let available_cash = engine.portfolio.cash * engine.config.max_position_ratio
if close_history.length() < engine.config.min_history_length {
  continue
}
```

---

### 2.3 风险规则参数语义不明确

**位置**: `src/risk/rules.mbt:159-182`

**问题**:
```moonbit
pub fn stop_loss_rule(stock : String, max_loss_pct : Float) -> RiskRule {
  RiskRule::{
    // ...
    check_fn: fn(_, _, position_pnl) {  // 第三个参数是什么？
      if position_pnl <= -max_loss_pct {
        // ...
      }
    }
  }
}
```

函数名暗示检查单个股票，但实际上第三个参数需要传入 position_pnl，调用者需要知道这个约定。

**建议**: 创建专门的组合层面检查函数：
```moonbit
pub fn check_portfolio_stop_loss(
  portfolio : @portfolio.Portfolio,
  max_loss_pct : Float,
) -> (@data.StockCode, RiskResult)? {
  for pos in portfolio.positions {
    let pnl_pct = pos.pnl_pct()
    if pnl_pct <= -max_loss_pct {
      return Some((pos.stock, /* RiskResult */))
    }
  }
  None
}
```

---

## 低优先级 - 架构改进

### 3.1 Portfolio 方法命名不一致

**位置**: `src/portfolio/manager.mbt`

**问题**:
- `calculate_position_pnl()` vs `get_position_pnl(stock)`
- `calculate_position_pnl_pct()` vs `get_position_pnl_pct(stock)`
- `get_total_exposure()` vs `position_value()`

**建议**: 统一命名约定：
- `total_pnl()` - 组合总盈亏
- `total_pnl_pct()` - 组合总盈亏百分比
- `position_pnl(stock)` - 单个股票盈亏
- `position_pnl_pct(stock)` - 单个股票盈亏百分比
- `exposure()` - 总敞口
- `position_value()` - 持仓市值

---

### 3.2 BacktestStats 未实现字段

**位置**: `src/backtest/types.mbt`

**问题**:
```moonbit
pub struct BacktestStats {
  // ...
  sortino_ratio : Float       // 始终为 0.0
  avg_trade_duration : Float  // 始终为 0.0
}
```

**建议**: 实现这些统计指标的计算：
- Sortino 比率：使用下行标准差代替总标准差
- 平均交易持续时间：跟踪买入到卖出的时间跨度

---

## 新功能建议

### 4.1 添加 Sortino 比率计算

**描述**: Sortino 比率使用下行标准差，更准确地衡量风险调整后收益。

**实现**:
```moonbit
fn calculate_sortino_ratio(returns : Array[Float], risk_free_rate : Float) -> Float {
  let excess_returns = returns.map(fn(r) { r - risk_free_rate })
  let downside_returns = excess_returns.filter(fn(r) { r < 0.0 })

  if downside_returns.length() == 0 {
    return 0.0
  }

  let avg_downside = average(downside_returns)
  let std_downside = std_dev(downside_returns)

  if std_downside == 0.0 {
    return 0.0
  }

  average(excess_returns) / std_downside * Float::sqrt(252.0)
}
```

---

### 4.2 添加交易持续时间统计

**描述**: 跟踪每笔交易的持续时间，计算平均值。

**实现**:
```moonbit
// 在 calculate_stats_core 中
let mut durations : Array[Int] = []
let mut buy_timestamps : Map[String, String] = Map::new()  // stock -> buy_date

for trade in trades {
  match trade.action {
    @strategy.Action::Buy => {
      buy_timestamps.set(trade.stock, trade.timestamp)
    }
    @strategy.Action::Sell => {
      match buy_timestamps.get(trade.stock) {
        Some(buy_date) => {
          let duration = calculate_days_between(buy_date, trade.timestamp)
          durations.push(duration)
        }
        None => ignore(())
      }
    }
    @strategy.Action::Hold => ignore(())
  }
}

let avg_duration = if durations.length() > 0 {
  Float::from_int(average(durations.map(fn(d) { Float::from_int(d) })))
} else {
  0.0
}
```

---

### 4.3 多策略比较工具

**描述**: 支持并行回测多个策略并比较结果。

**接口设计**:
```moonbit
pub struct StrategyComparison {
  strategies : Array[String]  // 策略名称
  results : Array[BacktestResult]
  winner : String             // 最优策略
  metrics : ComparisonMetrics
}

pub fn compare_strategies(
  klines : Array[@data.KLine],
  strategies : Array[Strategy],
  config : BacktestConfig,
) -> StrategyComparison {
  let results : Array[BacktestResult] = []
  for strategy in strategies {
    let engine = create_backtest_engine(config)
    results.push(run_backtest(engine, klines, strategy))
  }
  // 比较结果
}
```

---

## 测试覆盖率改进

### 5.1 需要补充测试的模块

根据文件分析，以下模块测试覆盖率不足：

| 模块 | 测试文件 | 缺失测试 |
|------|---------|---------|
| `indicator/ma.mbt` | `ma_test.mbt` | 边界条件、空输入、单元素 |
| `strategy/engine.mbt` | 无 | 策略引擎处理流程 |
| `portfolio/manager.mbt` | `portfolio_test.mbt` | `calculate_daily_pnl` |
| `risk/risk_test.mbt` | 有 | 风险引擎组合规则 |

---

## 修复记录

以下问题已在之前会话中修复：

- [x] 移除 ffi 依赖 (2026-03-xx)
- [x] 修复 substring 语法错误 (2026-03-xx)
- [x] 修复 integration test 断言 (2026-03-xx)
- [x] 移除未使用的 mut 变量 (2026-03-xx)
- [x] 简化 backtest engine 统计计算 (2026-03-xx)

---

## 行动计划

### 第一阶段（立即修复）
1. 移除 `StrategyResult` 未使用字段
2. 提取魔法数字为配置常量
3. 补充边界条件测试

### 第二阶段（性能优化）
1. 优化 `sma` 函数实现
2. 替换 `find_top_drawdowns` 冒泡排序
3. 实现 `calculate_sortino_ratio`

### 第三阶段（架构改进）
1. 统一 Portfolio API 命名
2. 实现交易持续时间统计
3. 创建多策略比较工具

---

*最后更新：2026-03-27*
