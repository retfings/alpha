# Strategy Configuration System - Design Proposal

**Date**: 2026-03-27
**Status**: Proposed
**Author**: AI Assistant

## Overview

This document proposes a strategy configuration system that enables parameterized backtesting and parameter optimization without code changes.

## Problem Statement

Currently, strategy parameters (like MA periods, RSI thresholds) are hardcoded in strategy implementations:

```moonbit
// src/strategy/builtins/ma_cross.mbt
pub fn create_ma_cross_strategy() -> Strategy {
  let fast_period = 10   // Hardcoded!
  let slow_period = 30   // Hardcoded!
  // ...
}
```

This creates several issues:
1. **No parameter optimization**: Cannot easily test different parameter combinations
2. **Code changes required**: Every parameter tweak needs recompilation
3. **No sensitivity analysis**: Cannot measure how parameters affect results
4. **Limited reproducibility**: Hard to track which parameters produced which results

## Proposed Solution

A strategy configuration system with three components:

### 1. StrategyConfig Type

```moonbit
/// Strategy parameter value types
pub enum ParamValue {
  Int(Int)
  Float(Float)
  String(String)
  Bool(Bool)
}

/// Strategy configuration
pub struct StrategyConfig {
  strategy_name : String
  parameters : Map[String, ParamValue]
}
```

### 2. Parameter Definitions

```moonbit
/// Parameter definition with constraints
pub struct ParamDef {
  name : String
  default : ParamValue
  min : ParamValue?
  max : ParamValue?
  description : String
}

// Example usage
pub fn ma_cross_param_defs() -> Array[ParamDef] {
  [
    int_param("fast_period", 10, Some(2), Some(50), Some(1), "Fast MA period"),
    int_param("slow_period", 30, Some(5), Some(200), Some(1), "Slow MA period"),
  ]
}
```

### 3. Parameter Scan Engine

```moonbit
/// Parameter range for scanning
pub enum ParamRange {
  IntRange { start : Int, end : Int, step : Int }
  DiscreteInt(Array[Int])
}

/// Scan configuration
pub struct ParameterScanConfig {
  base_config : StrategyConfig
  scan_params : Array[ScanParam]
}

/// Generate all parameter combinations
pub fn generate_param_combinations(config : ParameterScanConfig) -> Array[StrategyConfig]

/// Scan result
pub struct ScanResult {
  config : StrategyConfig
  total_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  // ...
}

/// Analyze scan results
pub fn analyze_scan_results(results : Array[ScanResult]) -> ScanSummary
```

## Usage Examples

### Basic Configuration

```moonbit
// Create strategy configuration
let config = create_strategy_config("ma_cross")
  .set_param("fast_period", ParamValue::Int(10))
  .set_param("slow_period", ParamValue::Int(30))

// Use in backtest
let strategy = strategy_from_config(config, klines)
let result = run_backtest(engine, klines, strategy)
```

### Parameter Scan

```moonbit
// Configure parameter scan
let scan_config = create_parameter_scan_config(
  create_strategy_config("ma_cross"),
  [
    scan_param("fast_period", int_range(5, 20, 5)),
    scan_param("slow_period", int_range(20, 60, 10)),
  ],
)

// Generate all combinations (produces 4 * 5 = 20 configs)
let configs = generate_param_combinations(scan_config)

// Run backtest for each configuration
let results = configs.map(fn(config) {
  let strategy = strategy_from_config(config, klines)
  let backtest_result = run_backtest(engine, klines, strategy)
  create_scan_result(config)
    .with_stats(
      backtest_result.total_return,
      backtest_result.max_drawdown,
      backtest_result.sharpe_ratio,
      // ...
    )
})

// Analyze results
let summary = analyze_scan_results(results)
io::println(format_scan_summary(summary))
```

### Output Example

```
========================================
Parameter Scan Summary Report
========================================

Overview:
  Total Combinations: 20
  Successful: 18
  Failed: 2

Best by Total Return:
  Return: 25.3%
  Config: fast_period=10, slow_period=30

Best by Sharpe Ratio:
  Sharpe: 1.85
  Config: fast_period=15, slow_period=40

Best by Drawdown:
  Max DD: -5.2%
  Config: fast_period=5, slow_period=50

Averages:
  Return: 12.5%
  Sharpe: 1.2
  Max DD: -12.3%

========================================
```

## Implementation Status

**Current State**: Design only - not yet implemented due to MoonBit type system limitations

The following limitations were encountered during initial implementation attempts:

1. **Map type inference**: MoonBit's Map type requires explicit type annotations in many contexts
2. **For loop limitations**: Tuple destructuring in for loops (`for (k, v) in map`) not supported
3. **Method syntax**: `mut self` pattern for mutable methods not supported
4. **Generic extension methods**: `fn Array[T]::method` syntax not supported

## Recommended Implementation Path

### Phase 1: Basic Configuration (Priority: High)

Implement core types without Maps:

```moonbit
/// Simpler approach using Array of tuples
pub struct StrategyConfig {
  strategy_name : String
  parameters : Array[(String, ParamValue)]
}
```

### Phase 2: Parameter Validation (Priority: Medium)

Add parameter definition and validation:

```moonbit
pub fn validate_config(config : StrategyConfig, defs : Array[ParamDef]) -> (Bool, Array[String])
```

### Phase 3: Parameter Scanning (Priority: Low)

Implement full parameter scanning once Phase 1 & 2 are stable.

## Benefits

1. **Reproducibility**: All parameters explicitly configured and logged
2. **Optimization**: Automated parameter search for optimal results
3. **Sensitivity Analysis**: Understand which parameters matter most
4. **Flexibility**: Test strategies without code changes
5. **Best Practices**: Enforces parameter bounds and validation

## Related Files

- `src/strategy/types.mbt` - Core strategy types
- `src/strategy/engine.mbt` - Strategy engine
- `src/strategy/builtins/` - Built-in strategies to be updated
- `docs/api-reference.md` - API documentation to be updated

## Future Enhancements

1. **JSON Configuration**: Load strategy configs from JSON files
2. **Walk-Forward Integration**: Parameter optimization with walk-forward validation
3. **Genetic Algorithm**: Automated parameter search using genetic algorithms
4. **Parameter Persistence**: Save/load optimal parameter sets

## References

- QuantConnect Parameter Optimization: https://www.quantconnect.com/learn
- Walk-Forward Analysis: https://en.wikipedia.org/wiki/Walk_forward_optimization
