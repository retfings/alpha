# Code Quality Review Report

**Date**: 2026-03-27
**Reviewer**: MoonBit Code Quality Review

## Executive Summary

This review analyzed the MoonBit quantitative drawdown framework codebase following the [MoonBit Refactoring Guide](../.claude/skills/moonbit-refactoring/SKILL.md). The codebase demonstrates good overall structure with clear module separation and comprehensive test coverage (470 passing tests). However, several improvement opportunities were identified.

**Overall Assessment**: Production-ready with recommended improvements

---

## 1. Architecture Review

### Package Structure

```
src/
├── data/          # Data layer (~650 lines)
├── strategy/      # Strategy engine (~328 lines)
├── drawdown/      # Drawdown calculation (~371 lines)
├── risk/          # Risk management (~489 lines)
├── portfolio/     # Portfolio management (~405 lines)
├── indicator/     # Technical indicators (~546 lines) ⚠️
└── backtest/      # Backtest engine (~465 lines)
```

**Findings**:
- Most packages are within the recommended <10k lines guideline
- `indicator/ma.mbt` (546 lines) exceeds the recommended <200-300 lines per file
- No cyclic dependencies detected - good acyclic design

### Recommendation: Split indicator module

The `indicator/ma.mbt` file should be split by indicator category:

```
src/indicator/
├── ma.mbt         # SMA, EMA (moving averages)
├── rsi.mbt        # RSI oscillator
├── macd.mbt       # MACD indicator
├── bollinger.mbt  # Bollinger Bands
├── atr.mbt        # Average True Range
├── kdj.mbt        # KDJ Stochastic
├── cci.mbt        # Commodity Channel Index
├── williams.mbt   # Williams %R
└── obv.mbt        # On-Balance Volume
```

---

## 2. Public API Design Issues

### 2.1 Unused Public Types (Remove or Make Private)

| Type | Location | Issue |
|------|----------|-------|
| `StrategyInfo` | `strategy/types.mbt:41` | Never constructed |
| `AdjustedKLine` | `data/types.mbt:90` | Never constructed |
| `OHLCV` | `data/types.mbt:114` | Never constructed |
| `Frequency` variants | `data/types.mbt:13-26` | Only `Daily` potentially used |
| `AdjustType` variants | `normalizer.mbt:10-17` | Never used |

**Recommendation**: Remove these from public API or move to `internal/` package.

### 2.2 Function Naming Inconsistency

**Current style**: Mix of `calculate_*` and direct names

```mbt
// Inconsistent naming
calculate_max_drawdown()     // "calculate_" prefix
calculate_drawdown_series()  // "calculate_" prefix
calculate_current_drawdown() // "calculate_" prefix
get_drawdown_stats()         // "get_" prefix
find_top_drawdowns()         // No prefix
```

**Recommendation**: Use MoonBit idiomatic method style:

```mbt
// After refactoring
values.max_drawdown()
values.drawdown_series()
values.current_drawdown()
values.drawdown_stats()
values.top_drawdowns(n)
```

---

## 3. Code Quality Issues

### 3.1 Loop Style Improvements

**Issue**: Many `while` loops can be simplified to range loops.

**Example from `ma.mbt:24-28`**:

```mbt
// Before
let mut i = 0
while i < period {
  window_sum = window_sum + values[i]
  i = i + 1
}
```

**After** (using range loop):

```mbt
for i in 0..<period {
  window_sum = window_sum + values[i]
}
```

**Files affected**:
- `ma.mbt`: 8 while loops can be range loops
- `calculator.mbt`: 6 while loops can be range loops
- `rules.mbt`: Similar patterns

### 3.2 Repeated Code Patterns

**Issue**: Float constant initialization repeated across files:

```mbt
let zero = Float::from_double(0.0)
let one = Float::from_double(1.0)
let hundred = Float::from_double(100.0)
```

**Found in**: `ma.mbt`, `calculator.mbt`, `rules.mbt`

**Recommendation**: Create utility module:

```mbt
// src/utils/float_consts.mbt
pub const ZERO : Float = 0.0
pub const ONE : Float = 1.0
pub const HUNDRED : Float = 100.0
```

### 3.3 Manual Array Slicing

**Issue**: Manual array copying instead of using built-in methods:

```mbt
// From calculator.mbt:331-370
let result : Array[DrawdownInfo] = []
for dd in drawdowns {
  result.push(dd)
}
// ... then manual truncation
```

**Recommendation**: Use array methods when available:

```mbt
let top_n = drawdowns.sort_by(fn(a, b) => a.drawdown - b.drawdown).take(n)
```

---

## 4. Efficiency Analysis

### 4.1 Algorithm Complexity

| Function | Current | Optimal | Notes |
|----------|---------|---------|-------|
| `calculate_max_drawdown` | O(n) | O(n) | Good |
| `find_top_drawdowns` | O(n*k) | O(n*log(n)) | Could use heap |
| `sma` | O(n) | O(n) | Good, uses sliding window |
| `bollinger_bands` | O(n*p) | O(n) | Recalculates std each time |

**Priority fix**: `bollinger_bands` can use incremental standard deviation calculation.

### 4.2 Memory Allocations

**Issue**: Repeated array allocations in loops:

```mbt
// From ma.mbt:121-122
let gains : Array[Float] = []
let losses : Array[Float] = []
```

**Recommendation**: Pre-allocate when size is known:

```mbt
let gains = Array::new_with_capacity(values.length() - 1)
```

---

## 5. Documentation Quality

### 5.1 Doc Examples Coverage

| Module | Functions | With Examples | Coverage |
|--------|-----------|---------------|----------|
| `indicator/ma.mbt` | 9 | 0 | 0% |
| `drawdown/calculator.mbt` | 7 | 1 | 14% |
| `risk/rules.mbt` | 6 | 3 | 50% |
| `portfolio/manager.mbt` | 14 | 7 | 50% |

**Recommendation**: Add `/// Examples:` sections to all public APIs with `mbt check-disabled` blocks.

### 5.2 Missing Loop Invariants

**Issue**: Complex algorithms lack Dafny-style specifications:

```mbt
// From calculator.mbt:find_top_drawdowns
while i < len {
  // Missing: invariant: 0 <= i <= len
  // Missing: reasoning about peak tracking
  ...
}
```

**Recommendation**: Add loop invariants for verification-critical code.

---

## 6. Test Coverage Gaps

Based on the review, the following areas need additional tests:

1. **Edge cases for indicators**:
   - Empty input arrays
   - Single element arrays
   - All identical values

2. **Boundary conditions**:
   - Zero values in percentage calculations
   - Negative values where unexpected

3. **Integration tests**:
   - Multi-indicator confluence (partially covered)
   - Risk rule interactions

---

## 7. Recommended Refactoring Priority

### P0 - Critical (Fix Immediately)
1. Remove unused public types from API
2. Fix `bollinger_bands` efficiency issue

### P1 - High (Next Sprint)
1. Split `indicator/ma.mbt` into focused modules
2. Convert `calculate_*` functions to methods
3. Add doc examples to all public APIs

### P2 - Medium (Future)
1. Replace while loops with range loops
2. Extract Float constants utility
3. Add loop invariants to complex algorithms

### P3 - Low (Nice to Have)
1. Optimize `find_top_drawdowns` with heap
2. Improve HTML report generation

---

## Appendix: Files Reviewed

| File | Lines | Issues Found | Priority |
|------|-------|--------------|----------|
| `src/indicator/ma.mbt` | 546 | File too large, no doc examples | P1 |
| `src/drawdown/calculator.mbt` | 371 | Method conversion needed | P1 |
| `src/backtest/report.mbt` | 274 | String concatenation verbose | P3 |
| `src/strategy/types.mbt` | 103 | Unused public type | P0 |
| `src/data/types.mbt` | 200+ | Unused types | P0 |
| `src/risk/rules.mbt` | 489 | Good documentation | - |
| `src/portfolio/manager.mbt` | 405 | Good method style | - |

---

*Report generated as part of Task #3: Code Quality Review*
