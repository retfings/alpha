# Architecture Optimization and Feature Recommendations

**Date**: 2026-03-27
**Author**: Senior Engineer Review
**Based on**: Task #11 - Architecture Analysis and Optimization Proposal

---

## Executive Summary

This document provides architecture optimization recommendations and new feature proposals for the MoonBit quantitative drawdown framework. The project has achieved 85% completion with 437 passing tests and solid foundation across data, strategy, risk, and backtest modules.

---

## 1. Architecture Optimizations

### 1.1 High Priority (P0)

#### 1.1.1 Implement C FFI for File I/O

**Current Issue**: CSV loading and report saving rely on placeholder functions returning errors.

**Problem**:
```moonbit
// src/data/loader.mbt:88
pub fn load_klines_from_csv(path : String) -> Result[Array[KLine], String] {
  ignore(path)
  Err("C FFI not yet implemented - use parse_csv_content with string content instead")
}
```

**Recommendation**:
- Implement C FFI wrapper for file reading in `src/ffi/file.mbt`
- Expose `read_file(path: String) -> Result[String, String]`
- Expose `write_file(path: String, content: String) -> Result[Unit, String]`
- Update `loader.mbt` to use FFI for real file loading
- Update `report.mbt` to support saving reports to disk

**Effort**: 2-3 days
**Impact**: Unlocks core functionality (data loading, report persistence)

#### 1.1.2 Fix Unused Package Warnings

**Current Issue**: Multiple `moon.pkg` files import packages only used in blackbox tests.

**Affected Files**:
- `src/backtest/moon.pkg` - indicator import (used in integration tests)
- `src/strategy/moon.pkg` - indicator import
- `src/risk/moon.pkg` - drawdown import

**Recommendation**:
- Create separate `moon.test.pkg` files for test-specific imports (if MoonBit supports)
- Alternatively, add `// for blackbox tests` comments to document intent
- Or consolidate test imports in a dedicated test utilities package

**Effort**: 0.5 days
**Impact**: Cleaner builds, better code organization

### 1.2 Medium Priority (P1)

#### 1.2.1 Extract Common Test Utilities

**Current Issue**: Test setup code is duplicated across multiple test files.

**Example Duplications**:
- K-line sample data creation (appears in 10+ test files)
- Strategy mock creation
- Portfolio initialization patterns

**Recommendation**:
```moonbit
// src/test_utils/helpers.mbt
pub fn sample_klines() -> Array[KLine] { ... }
pub fn sample_portfolio(initial: Float) -> Portfolio { ... }
pub fn mock_strategy() -> Strategy { ... }
```

**Effort**: 1-2 days
**Impact**: Reduced test maintenance, faster test development

#### 1.2.2 Improve Error Handling Consistency

**Current Issue**: Mixed error handling patterns across modules.

**Examples**:
- Some functions return `Result[T, String]`
- Others return `Option[T]`
- Some use panics via `expect()`

**Recommendation**:
- Define standard error types per module in `types.mbt`
- Create error type hierarchy:
```moonbit
pub type DataError =
  | FileNotFound(String)
  | ParseError(String, Int)  // error, line number
  | InvalidFormat(String)

pub type StrategyError =
  | SignalError(String)
  | InitializationError(String)
```

**Effort**: 2-3 days
**Impact**: Better error messages, easier debugging

#### 1.2.3 Add Performance Benchmarks

**Current Issue**: No performance tracking for critical paths.

**Critical Paths**:
- CSV parsing for large files (1000+ rows)
- Indicator calculations on long time series
- Backtest engine loop performance

**Recommendation**:
```moonbit
// src/benchmarks/csv_bench.mbt
test_bench "parse_csv_1000_rows" {
  let csv = generate_sample_csv(1000)
  bench(fn() { parse_csv_content(csv) })
}
```

**Effort**: 1-2 days
**Impact**: Performance regression detection, optimization targets

### 1.3 Low Priority (P2)

#### 1.3.1 Consider Module Subdivision

**Current Issue**: Some modules are growing large.

**Example**: `src/risk/rules.mbt` has 400+ lines with 6+ rule types.

**Recommendation**:
```
src/risk/
├── rules/
│   ├── drawdown_rules.mbt
│   ├── position_rules.mbt
│   ├── exposure_rules.mbt
│   └── profit_rules.mbt
├── engine.mbt
└── types.mbt
```

**Effort**: 2-3 days
**Impact**: Better code organization, easier to find specific rules

#### 1.3.2 Add Caching Layer for Indicators

**Current Issue**: Indicators recalculate on every call.

**Recommendation**:
```moonbit
pub type CachedIndicator = {
  data: Array[Float],
  dirty: Bool,
  last_updated: Int64,
}

pub fn sma_cached(cache: CachedIndicator, prices: Array[Float], period: Int) -> CachedIndicator {
  if !cache.dirty { cache } else { ...recalculate... }
}
```

**Effort**: 2-3 days
**Impact**: Faster backtests, especially for multi-year data

---

## 2. New Feature Proposals

### 2.1 High Priority (P0)

#### 2.1.1 Multi-Stock Portfolio Backtesting

**Current State**: Backtest engine processes single stock at a time.

**Proposed Feature**:
```moonbit
pub type MultiStockBacktestConfig = {
  stocks: Array[StockCode],
  weights: Array[Float],  // allocation per stock
  rebalance_frequency: RebalanceFreq,
  ...
}

pub fn run_multi_stock_backtest(
  config: MultiStockBacktestConfig,
  strategy: Strategy,
  data: Map[StockCode, Array[KLine]],
) -> MultiStockBacktestResult { ... }
```

**Use Cases**:
- Test diversification strategies
- Analyze correlation effects on drawdown
- Optimize portfolio allocation

**Effort**: 3-5 days
**Impact**: More realistic backtesting, portfolio-level analysis

#### 2.1.2 Walk-Forward Analysis

**Current State**: Single backtest run over fixed period.

**Proposed Feature**:
```moonbit
pub type WalkForwardConfig = {
  train_periods: Int,      // e.g., 12 months
  test_periods: Int,       // e.g., 3 months
  step_periods: Int,       // e.g., 1 month step
  strategy_params: Map[String, Dynamic],
}

pub fn walk_forward_analysis(
  config: WalkForwardConfig,
  data: Array[KLine],
) -> Array[BacktestResult] { ... }
```

**Use Cases**:
- Strategy robustness testing
- Parameter stability analysis
- Overfitting detection

**Effort**: 2-3 days
**Impact**: Professional-grade strategy validation

### 2.2 Medium Priority (P1)

#### 2.2.1 Strategy Parameter Optimization

**Proposed Feature**:
```moonbit
pub type OptimizationResult = {
  best_params: Map[String, Float],
  best_score: Float,
  all_results: Array[(Map[String, Float], BacktestResult)],
}

pub fn grid_search_optimize(
  strategy: Strategy,
  param_grid: Map[String, Array[Float]],
  metric: (BacktestResult) -> Float,
  data: Array[KLine],
) -> OptimizationResult { ... }
```

**Use Cases**:
- Find optimal MA periods
- Optimize RSI thresholds
- Tune stop-loss levels

**Effort**: 3-4 days
**Impact**: Data-driven strategy tuning

#### 2.2.2 Monte Carlo Simulation

**Proposed Feature**:
```moonbit
pub type MonteCarloConfig = {
  simulations: Int,
  bootstrap: Bool,
  random_seed: Int?,
}

pub fn monte_carlo_analysis(
  config: MonteCarloConfig,
  trades: Array[Trade],
) -> MonteCarloResult {
  // Returns distribution of outcomes:
  // - Probability of ruin
  // - Confidence intervals for returns
  // - Worst-case scenarios
}
```

**Use Cases**:
- Strategy risk assessment
- Position sizing optimization
- Tail risk analysis

**Effort**: 2-3 days
**Impact**: Better risk understanding

#### 2.2.3 Market Regime Detection

**Proposed Feature**:
```moonbit
pub type MarketRegime = Bull | Bear | Sideways | Volatile

pub type RegimeDetector = {
  detect: (Array[KLine]) -> MarketRegime,
  confidence: () -> Float,
}

---

## 3. Performance Optimization Proposals

### 3.1 Replace Bubble Sort in find_top_drawdowns

**Current Issue**: O(n²) bubble sort in `src/drawdown/calculator.mbt:331-349`

**Proposed Fix**:
```moonbit
// Use selection-based approach for top-n (O(n log k) where k << n)
pub fn find_top_drawdowns_optimized(
  values : Array[Float],
  dates : Array[String],
  n : Int,
) -> Array[DrawdownInfo] {
  let all_drawdowns = find_all_drawdowns(values, dates)
  quick_select_top_n(all_drawdowns, n)  // O(n log n) instead of O(n²)
}
```

**Impact**: 10-100x faster for long equity curves (1000+ data points)

### 3.2 Sliding Window for SMA Calculation

**Current Issue**: `src/indicator/ma.mbt` recalculates full window sum each time - O(N*P) complexity

**Proposed Fix**:
```moonbit
pub fn sma_sliding_window(values : Array[Float], period : Int) -> Array[Float] {
  // Maintain running sum, subtract oldest value, add newest
  // Reduces complexity from O(N*P) to O(N)
}
```

**Impact**: 20x faster for typical period=20, scales linearly

### 3.3 Lazy Evaluation for Indicator Chains

**Current Issue**: Multiple indicator calls recalculate intermediate results

**Proposed Feature**:
```moonbit
pub type LazyIndicator = {
  compute: () -> Array[Float],
  cached_result: Array[Float]?,
}

pub fn compose_indicators(
  indicators : Array[LazyIndicator],
) -> LazyIndicator {
  // Only compute when result is actually needed
}
```

---

## 4. Code Quality Improvements

### 4.1 Remove Unused Fields

**Location**: `src/strategy/engine.mbt:8-17`

```moonbit
// Current:
pub(all) struct StrategyResult {
  signal : Signal
  executed : Bool      // Never read
  exec_price : Float   // Never used
  exec_volume : Float  // Never used
}

// Proposed:
pub(all) struct StrategyResult {
  signal : Signal
}
```

### 4.2 Extract Magic Numbers to Config

**Location**: `src/backtest/engine.mbt:146-150, 119`

```moonbit
// Add to BacktestConfig:
pub struct BacktestConfig {
  // ... existing fields ...
  max_position_ratio : Float    // default 0.95
  min_history_length : Int      // default 20
  lot_size : Float              // default 100.0
}
```

### 4.3 Standardize API Naming

**Location**: `src/portfolio/manager.mbt`

| Current | Proposed |
|---------|----------|
| `calculate_position_pnl()` | `total_pnl()` |
| `calculate_position_pnl_pct()` | `total_pnl_pct()` |
| `get_total_exposure()` | `exposure()` |
| `get_position_pnl(stock)` | `position_pnl(stock)` |
| `get_position_pnl_pct(stock)` | `position_pnl_pct(stock)` |

---

## 5. Implementation Priority

### Phase 1 (Immediate - 1 week)
- [ ] Implement C FFI for file I/O (Task #25, #31)
- [ ] Remove unused fields from StrategyResult
- [ ] Extract magic numbers to config constants

### Phase 2 (Short-term - 2 weeks)
- [ ] Optimize SMA with sliding window
- [ ] Replace bubble sort in find_top_drawdowns
- [ ] Implement Sortino ratio calculation
- [ ] Implement trade duration statistics

### Phase 3 (Medium-term - 1 month)
- [ ] Multi-stock backtesting support
- [ ] Walk-forward analysis framework
- [ ] Strategy parameter optimization
- [ ] Standardize portfolio API naming

### Phase 4 (Long-term - 2 months)
- [ ] Monte Carlo simulation
- [ ] Market regime detection
- [ ] Indicator caching layer
- [ ] Comprehensive benchmark suite

pub fn create_regime_detector(indicators: Array[Indicator]) -> RegimeDetector { ... }
```

**Use Cases**:
- Adapt strategy to market conditions
- Filter signals in unfavorable regimes
- Regime-specific performance analysis

**Effort**: 3-4 days
**Impact**: Smarter strategy adaptation

### 2.3 Low Priority (P2)

#### 2.3.1 Machine Learning Integration

**Proposed Feature**:
```moonbit
// Via FFI to Python/ML libraries
pub type MLModel = {
  predict: (Array[Feature]) -> Prediction,
  train: (Array[Feature], Array[Label]) -> Unit,
}

pub fn create_random_forest(params: MLParams) -> MLModel { ... }
```

**Use Cases**:
- ML-based signal generation
- Feature importance analysis
- Ensemble predictions

**Effort**: 5-10 days
**Impact**: Advanced prediction capabilities

#### 2.3.2 Real-Time Data Streaming

**Proposed Feature**:
```moonbit
pub type StreamHandler = {
  on_tick: (Tick) -> Signal,
  on_bar: (KLine) -> Signal,
}

pub fn start_streaming(
  handler: StreamHandler,
  symbols: Array[StockCode],
) -> StreamConnection { ... }
```

**Use Cases**:
- Live trading support
- Real-time risk monitoring
- Intraday strategy execution

**Effort**: 5-7 days
**Impact**: Production trading capability

#### 2.3.3 Advanced Order Types

**Current State**: Only market orders supported.

**Proposed Feature**:
```moonbit
pub type OrderType =
  | Market
  | Limit(Float)
  | StopLoss(Float)
  | StopLimit(Float, Float)
  | TrailingStop(Float)  // percentage

pub type Order = {
  stock: StockCode,
  order_type: OrderType,
  quantity: Float,
  side: Side,
  ...
}
```

**Use Cases**:
- More realistic backtesting
- Better execution control
- Advanced risk management

**Effort**: 3-4 days
**Impact**: Professional-grade order management

---

## 3. Technical Debt Summary

### Critical (Must Fix Before Production)

| Item | Severity | Effort | Description |
|------|----------|--------|-------------|
| C FFI for I/O | High | 2-3d | File operations not functional |
| Report persistence | High | 1d | Cannot save backtest results |
| CLI file loading bug | Medium | 0.5d | Command-line tool doesn't load data |

### Important (Should Fix)

| Item | Severity | Effort | Description |
|------|----------|--------|-------------|
| Unused package warnings | Low | 0.5d | Clean up moon.pkg imports |
| Test utility duplication | Low | 1-2d | Extract common helpers |
| Error type inconsistency | Medium | 2-3d | Standardize error handling |

### Optional (Nice to Have)

| Item | Effort | Description |
|------|--------|-------------|
| Performance benchmarks | 1-2d | Track critical path performance |
| Module subdivision | 2-3d | Split large modules |
| Indicator caching | 2-3d | Optimize repeated calculations |

---

## 4. Recommended Implementation Order

### Phase 1 - Foundation (Week 1-2)
1. Implement C FFI for file I/O (P0)
2. Fix CLI file loading (P0)
3. Add report persistence (P0)
4. Clean up unused imports (P1)

### Phase 2 - Enhancement (Week 3-4)
1. Extract test utilities (P1)
2. Standardize error types (P1)
3. Add performance benchmarks (P2)
4. Implement multi-stock backtesting (P0)

### Phase 3 - Advanced Features (Week 5-8)
1. Walk-forward analysis (P0)
2. Parameter optimization (P1)
3. Monte Carlo simulation (P1)
4. Market regime detection (P2)

### Phase 4 - Production Ready (Week 9-12)
1. Advanced order types (P2)
2. Real-time streaming (P2)
3. ML integration exploration (P2)
4. Comprehensive documentation

---

## 5. Conclusion

The MoonBit drawdown framework has a solid foundation with comprehensive test coverage (437 tests) and well-structured modules. The primary gaps are:

1. **Critical**: C FFI implementation for file I/O
2. **Important**: Multi-stock portfolio support
3. **Valuable**: Walk-forward analysis for strategy validation

Implementing the P0 recommendations would bring the framework to production-ready status for quantitative analysis and backtesting workflows.

---

**Next Steps**:
- Review priorities with team
- Create detailed task breakdowns for selected features
- Begin with C FFI implementation (Task #25)
