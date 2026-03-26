# 架构改进建议书

**日期**: 2026-03-27
**任务**: #5 - 提出架构改进建议
**基于**: 代码库分析和代码质量审查结果

---

## 执行摘要

本文档提出 5 项架构层面的改进建议，旨在提升代码库的可维护性、可扩展性和性能。当前项目包含 9 个包、36 个源文件，已形成稳定的量化回测框架基础架构。

---

## 建议 1: 引入依赖注入模式 (Dependency Injection)

### 现状问题

当前模块间耦合度较高，难以进行单元测试和模块替换：

```moonbit
// backtest/engine.mbt - 直接依赖具体实现
let portfolio = @portfolio.create_portfolio(config.initial_capital)
let risk_engine = @risk.create_risk_engine()
```

### 建议方案

引入依赖注入模式，通过接口抽象降低耦合：

```moonbit
// 定义抽象接口
pub type PortfolioProvider = {
  create: (Float) -> Portfolio,
}

pub type RiskEngineProvider = {
  create: () -> RiskEngine,
}

// 回测引擎接受依赖
pub fn create_backtest_engine(
  config: BacktestConfig,
  portfolio_provider: PortfolioProvider,
  risk_engine_provider: RiskEngineProvider,
) -> BacktestEngine {
  let portfolio = portfolio_provider.create(config.initial_capital)
  let risk_engine = risk_engine_provider.create()
  // ...
}
```

### 收益

- **可测试性**: 可以使用 mock 实现进行单元测试
- **可扩展性**: 轻松替换不同的投资组合/风控引擎实现
- **可维护性**: 模块职责更清晰

### 实施优先级: P1 (高)
### 预计工作量: 2-3 天

---

## 建议 2: 统一错误处理机制

### 现状问题

错误处理不一致，混合使用 Result、Option 和错误消息字符串：

```moonbit
// data/loader.mbt - 返回 Result[T, String]
pub fn load_klines_from_csv(path: String) -> Result[Array[KLine], String>

// drawdown/calculator.mbt - 返回 Option
pub fn calculate_max_drawdown_detailed(...) -> DrawdownInfo?

// strategy/engine.mbt - 使用 Bool
pub fn Portfolio::buy(...) -> Bool
```

### 建议方案

定义统一的错误类型层次结构：

```moonbit
// src/core/error.mbt
pub type QuantError =
  | DataError(DataErrorKind, String)
  | StrategyError(StrategyErrorKind, String)
  | RiskError(RiskErrorKind, String)
  | BacktestError(BacktestErrorKind, String)

pub type DataErrorKind =
  | FileNotFound
  | ParseError
  | InvalidFormat
  | MissingColumn

pub type StrategyErrorKind =
  | SignalError
  | InitializationError
  | InsufficientData

pub type RiskErrorKind =
  | RuleViolation
  | ThresholdExceeded

pub type BacktestErrorKind =
  | ConfigurationError
  | ExecutionError
  | InsufficientCapital
```

### 收益

- **类型安全**: 编译器可以检查所有错误处理
- **可组合性**: 使用 Result 的组合子简化错误处理
- **可追溯性**: 错误包含来源和上下文信息

### 实施优先级: P1 (高)
### 预计工作量: 3-4 天

---

## 建议 3: 引入事件驱动架构

### 现状问题

当前回测引擎采用同步调用模式，难以扩展实时监控和通知功能：

```moonbit
// backtest/engine.mbt - 同步执行
for kline in klines {
  let signal = strategy.on_bar(kline, ctx, close_history)
  if risk_result.passed {
    execute_trade(signal)
  }
  record_equity(equity)
}
```

### 建议方案

引入事件总线模式，支持事件订阅和异步处理：

```moonbit
// src/core/event.mbt
pub type Event =
  | BarReceived(KLine)
  | SignalGenerated(Signal)
  | TradeExecuted(Trade)
  | RiskRuleTriggered(RiskResult)
  | DrawdownAlert(DrawdownInfo)

pub type EventBus = {
  mut subscribers: Map[EventType, Array[EventHandler]],
}

pub fn EventBus::subscribe(
  self: EventBus,
  event_type: EventType,
  handler: EventHandler,
) -> Unit

pub fn EventBus::publish(
  self: EventBus,
  event: Event,
) -> Unit
```

### 收益

- **可扩展性**: 轻松添加新的事件处理器（日志、通知、持久化）
- **松耦合**: 事件发布者和订阅者解耦
- **实时性**: 支持实时监控和告警

### 实施优先级: P2 (中)
### 预计工作量: 4-5 天

---

## 建议 4: 引入策略配置 DSL

### 现状问题

策略参数硬编码或通过复杂结构传递，不够直观：

```moonbit
// 当前方式
pub fn create_ma_cross_strategy(fast_period: Int, slow_period: Int) -> MaCrossStrategy {
  MaCrossStrategy::{
    fast_period,
    slow_period,
    name: "MA Crossover (" + fast_period.to_string() + "/" + slow_period.to_string() + ")",
  }
}
```

### 建议方案

引入领域特定语言 (DSL) 定义策略：

```moonbit
// 策略 DSL
pub type StrategyBuilder = {
  mut name: String,
  mut params: Map[String, Dynamic],
  mut indicators: Array[IndicatorConfig],
}

pub fn strategy(name: String) -> StrategyBuilder {
  StrategyBuilder::{ name, params: Map::new(), indicators: [] }
}

pub fn StrategyBuilder::param(
  self: StrategyBuilder,
  name: String,
  value: Dynamic,
) -> StrategyBuilder

pub fn StrategyBuilder::use_indicator(
  self: StrategyBuilder,
  name: String,
  params: Map[String, Dynamic],
) -> StrategyBuilder

pub fn StrategyBuilder::build(self: StrategyBuilder) -> Strategy

// 使用示例
let strategy = strategy("MA Crossover")
  .param("fast_period", 10)
  .param("slow_period", 30)
  .use_indicator("SMA", {"period": 10})
  .use_indicator("SMA", {"period": 30})
  .build()
```

### 收益

- **可读性**: 策略定义更接近自然语言
- **可配置性**: 参数集中管理，易于调整
- **可复用性**: 策略模板可复用

### 实施优先级: P2 (中)
### 预计工作量: 3-4 天

---

## 建议 5: 引入缓存层优化性能

### 现状问题

技术指标重复计算，回测长周期数据时性能低下：

```moonbit
// 每次调用都重新计算
let fast_ma = @indicator.sma(close_history, self.fast_period)
let slow_ma = @indicator.sma(close_history, self.slow_period)
```

### 建议方案

引入缓存层，支持增量计算：

```moonbit
// src/indicator/cache.mbt
pub type CachedIndicator = {
  name: String,
  params: Map[String, Dynamic],
  mut cache: Array[Float],
  mut dirty: Bool,
  mut last_updated: Int,
}

pub type IndicatorCache = {
  mut indicators: Map[String, CachedIndicator],
}

pub fn IndicatorCache::get_or_compute(
  self: IndicatorCache,
  name: String,
  params: Map[String, Dynamic],
  compute_fn: (Array[Float]) -> Array[Float],
  data: Array[Float],
) -> Array[Float]

// 增量更新
pub fn IndicatorCache::update(
  self: IndicatorCache,
  new_bar: KLine,
) -> Unit
```

### 收益

- **性能提升**: 避免重复计算，长周期回测可提升 10-100 倍
- **内存效率**: 只存储必要数据
- **透明性**: 缓存对调用者透明

### 实施优先级: P2 (中)
### 预计工作量: 4-5 天

---

## 架构优先级矩阵

| 建议 | 影响 | 工作量 | 优先级 |
|------|------|--------|--------|
| 依赖注入 | 高 | 中 | P0 |
| 统一错误处理 | 高 | 中 | P0 |
| 事件驱动架构 | 中 | 高 | P1 |
| 策略配置 DSL | 中 | 中 | P1 |
| 缓存层 | 中 | 高 | P1 |

---

## 实施路线图

### 第一阶段 (1-2 周) - 基础架构改进
- [ ] 实现依赖注入模式
- [ ] 定义统一错误类型
- [ ] 更新现有模块使用新模式

### 第二阶段 (2-3 周) - 功能增强
- [ ] 实现事件总线
- [ ] 开发策略配置 DSL
- [ ] 添加缓存层支持

### 第三阶段 (3-4 周) - 性能优化
- [ ] 基准测试和性能分析
- [ ] 优化热点路径
- [ ] 文档和示例更新

---

## 风险与缓解

### 风险 1: 架构变更影响范围大
**缓解**: 渐进式重构，保持向后兼容，充分测试

### 风险 2: 工作量超出预期
**缓解**: 优先级排序，先实施高影响力低工作量的建议

### 风险 3: 学习曲线
**缓解**: 提供详细文档和示例代码

---

*最后更新：2026-03-27*
*下一步：与团队讨论优先级，确定实施计划*
