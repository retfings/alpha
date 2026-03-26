# Strategy Examples

This document provides example strategies demonstrating how to use the MoonBit Drawdown Framework.

## Table of Contents

- [Strategy Structure](#strategy-structure)
- [Example 1: Moving Average Crossover](#example-1-moving-average-crossover-strategy)
- [Example 2: RSI Momentum](#example-2-rsi-momentum-strategy)
- [Example 3: Mean Reversion](#example-3-mean-reversion-strategy)
- [Example 4: Multi-Strategy Composite](#example-4-multi-strategy-composite)
- [Strategy Development Guidelines](#strategy-development-guidelines)

## Strategy Structure

All strategies follow a common structure using the `Strategy` record type:

```moonbit
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext, Array[Float]) -> Signal
}
```

### Strategy Context

The `StrategyContext` provides access to portfolio state:

```moonbit
pub struct StrategyContext {
  capital : Float       // Available capital
  position : Float      // Current position value
  current_price : Float // Current market price
  last_signal : Signal? // Previous signal (if any)
}
```

### Signal Generation

Strategies return `Signal` objects:

```moonbit
pub struct Signal {
  stock : StockCode
  action : Action  // Buy, Sell, or Hold
  price : Float
  timestamp : String
  strength : Float // 0.0 - 1.0
}
```

Signal helper functions:
- `Signal::buy(stock, price, timestamp, strength)` - Create buy signal
- `Signal::sell(stock, price, timestamp, strength)` - Create sell signal
- `Signal::hold(stock, price, timestamp)` - Create hold signal

---

## Example 1: Moving Average Crossover Strategy

A classic trend-following strategy that generates signals when a fast moving average crosses a slow moving average.

### Strategy Logic

- **Buy Signal**: Fast MA crosses above Slow MA (bullish crossover)
- **Sell Signal**: Fast MA crosses below Slow MA (bearish crossover)
- **Hold**: No crossover detected

### Implementation

The built-in MA Crossover strategy is available in `src/strategy/builtins/ma_cross.mbt`:

```moonbit
/// Moving Average Crossover Strategy
///
/// Buy when fast MA crosses above slow MA
/// Sell when fast MA crosses below slow MA

pub fn create_ma_cross_strategy(
  fast_period : Int,    // e.g., 5 for short-term
  slow_period : Int,    // e.g., 20 for long-term
) -> MaCrossStrategy {
  MaCrossStrategy::{
    fast_period,
    slow_period,
    name: "MA Crossover (" + fast_period.to_string() + "/" + slow_period.to_string() + ")",
  }
}
```

### Usage Example

```moonbit
// Create strategy with 10-day and 30-day moving averages
let strategy = @strategy.builtins.create_ma_cross_strategy(10, 30)

// Run backtest
let config = @strategy.default_backtest_config()
let engine = @backtest.create_backtest_engine(config)
let result = @backtest.run_backtest(engine, klines, strategy)
```

### Running from CLI

```bash
moon run cmd/main backtest \
  --strategy ma_cross \
  --stock sh.600000 \
  --start 2023-01-01 \
  --end 2023-12-31
```

### Tips

- **Parameter Selection**: Shorter periods (5-10) generate more signals but may produce false positives. Longer periods (20-50) are more reliable but slower to react.
- **Risk Management**: Always pair with risk rules like `max_drawdown_rule(0.20)` to limit losses.
- **Data Requirements**: Ensure at least `slow_period` bars of data for accurate calculations.

---

## Example 2: RSI Momentum Strategy

A momentum-based strategy using the Relative Strength Index (RSI) to identify overbought and oversold conditions.

### Strategy Logic

- **Buy Signal**: RSI drops below oversold threshold (typically 30)
- **Sell Signal**: RSI rises above overbought threshold (typically 70)
- **Hold**: RSI in neutral zone

### Implementation

The built-in Momentum strategy is available in `src/strategy/builtins/momentum.mbt`:

```moonbit
/// RSI Momentum Strategy
///
/// Buy when RSI indicates oversold conditions
/// Sell when RSI indicates overbought conditions

pub fn create_momentum_strategy(
  rsi_period : Int,           // Typically 14
  overbought_threshold : Float, // Typically 70.0
  oversold_threshold : Float,   // Typically 30.0
) -> MomentumStrategy {
  MomentumStrategy::{
    rsi_period,
    overbought_threshold,
    oversold_threshold,
    name: "RSI Momentum (" + rsi_period.to_string() + ")",
  }
}
```

### Usage Example

```moonbit
// Create strategy with standard 14-day RSI
let strategy = @strategy.builtins.create_momentum_strategy(
  14,       // RSI period
  70.0,     // Overbought threshold
  30.0,     // Oversold threshold
)

// Run backtest
let config = @strategy.default_backtest_config()
let engine = @backtest.create_backtest_engine(config)
let result = @backtest.run_backtest(engine, klines, strategy)
```

### Running from CLI

```bash
moon run cmd/main backtest \
  --strategy momentum \
  --stock sz.000001 \
  --start 2023-01-01 \
  --end 2023-12-31
```

### RSI Interpretation

| RSI Range | Condition | Action |
|-----------|-----------|--------|
| 0-30      | Oversold  | Consider buying |
| 30-70     | Neutral   | Hold |
| 70-100    | Overbought| Consider selling |

### Tips

- **Parameter Tuning**: Lower thresholds (20/80) produce fewer but stronger signals. Higher thresholds (35/65) produce more signals but may be less reliable.
- **Divergence**: Look for price making new highs while RSI fails to confirm - this can signal trend weakness.
- **Trend Context**: RSI works best in ranging markets. In strong trends, RSI can remain overbought/oversold for extended periods.

---

## Example 3: Mean Reversion Strategy

A contrarian strategy that buys when price deviates significantly below its mean and sells when it reverts.

```moonbit
/// Mean Reversion Strategy
///
/// Buy when price drops below lower band
/// Sell when price reverts to mean or exceeds upper band

pub fn create_mean_reversion_strategy(
  lookback_period : Int,
  std_dev_multiplier : Float,
) -> @strategy.Strategy {

  let mut upper_band = 0.0
  let mut lower_band = 0.0
  let mut mean = 0.0

  Strategy::{
    name: "Mean Reversion (\\{lookback_period}d, \\{std_dev_multiplier}σ)",
    on_init: fn(ctx) {
      upper_band = 0.0
      lower_band = 0.0
      mean = 0.0
    },
    on_bar: fn(kline, ctx) {
      // Calculate Bollinger Bands
      let bands = calculate_bollinger_bands(kline, lookback_period, std_dev_multiplier)
      mean = bands.mean
      upper_band = bands.upper
      lower_band = bands.lower

      // Determine action
      let signal_action = if kline.close < lower_band {
        // Price below lower band - BUY (oversold)
        @strategy.Action::Buy
      } else if kline.close > mean {
        // Price above mean - SELL (take profit)
        @strategy.Action::Sell
      } else {
        // Within bands - HOLD
        @strategy.Action::Hold
      }

      Signal::{
        stock: kline.code,
        action: signal_action,
        price: kline.close,
        timestamp: kline.date,
        strength: calculate_distance_from_mean(kline.close, mean, bands.std_dev),
      }
    },
  }
}

// Helper type for Bollinger Bands
struct BollingerBands {
  upper : Float
  mean : Float
  lower : Float
  std_dev : Float
}

// Helper function: Calculate Bollinger Bands
fn calculate_bollinger_bands(
  kline : @data.KLine,
  period : Int,
  multiplier : Float,
) -> BollingerBands {
  // In production, calculate from historical data
  BollingerBands::{
    upper: kline.close,
    mean: kline.close,
    lower: kline.close,
    std_dev: 0.0,
  }
}

// Helper function: Calculate distance from mean in standard deviations
fn calculate_distance_from_mean(price : Float, mean : Float, std_dev : Float) -> Float {
  if std_dev == 0.0 {
    0.5
  } else {
    let distance = Float::abs(price - mean) / std_dev
    if distance > 1.0 { 1.0 } else { distance }
  }
}

// Usage:
// let strategy = create_mean_reversion_strategy(20, 2.0)
// - 20-day lookback
// - 2 standard deviation bands
```

## Example 4: RSI Overbought/Oversold Strategy

Uses the Relative Strength Index (RSI) to identify overbought and oversold conditions.

```moonbit
/// RSI Strategy
///
/// Buy when RSI drops below oversold threshold
/// Sell when RSI rises above overbought threshold

pub fn create_rsi_strategy(
  rsi_period : Int,
  oversold_threshold : Float,
  overbought_threshold : Float,
) -> @strategy.Strategy {

  let mut rsi_value = 0.0
  let mut in_position = false

  Strategy::{
    name: "RSI (\\{rsi_period})",
    on_init: fn(ctx) {
      rsi_value = 0.0
      in_position = false
    },
    on_bar: fn(kline, ctx) {
      // Calculate RSI
      rsi_value = calculate_rsi(kline, rsi_period)

      // Determine action
      let signal_action = if rsi_value < oversold_threshold && !in_position {
        // Oversold - BUY
        in_position = true
        @strategy.Action::Buy
      } else if rsi_value > overbought_threshold && in_position {
        // Overbought - SELL
        in_position = false
        @strategy.Action::Sell
      } else {
        @strategy.Action::Hold
      }

      Signal::{
        stock: kline.code,
        action: signal_action,
        price: kline.close,
        timestamp: kline.date,
        strength: calculate_rsi_strength(rsi_value, oversold_threshold, overbought_threshold),
      }
    },
  }
}

// Helper function: Calculate RSI
fn calculate_rsi(kline : @data.KLine, period : Int) -> Float {
  // In production, calculate from historical price data
  // RSI = 100 - (100 / (1 + RS))
  // RS = Average gain / Average loss over period
  50.0  // Neutral RSI placeholder
}

// Helper function: Calculate signal strength based on RSI extremity
fn calculate_rsi_strength(
  rsi : Float,
  oversold : Float,
  overbought : Float,
) -> Float {
  if rsi < oversold {
    // More oversold = stronger buy signal
    (oversold - rsi) / oversold
  } else if rsi > overbought {
    // More overbought = stronger sell signal
    (rsi - overbought) / (100.0 - overbought)
  } else {
    0.5
  }
}

// Usage:
// let strategy = create_rsi_strategy(14, 30.0, 70.0)
// - 14-day RSI
// - Oversold below 30
// - Overbought above 70
```

## Example 5: Multi-Strategy Composite

Combine multiple strategies into a single composite strategy with weighted signals.

```moonbit
/// Composite Strategy
///
/// Combines signals from multiple strategies with weighted voting

pub fn create_composite_strategy(
  strategies : Array[@strategy.Strategy],
  weights : Array[Float],
) -> @strategy.Strategy {

  Strategy::{
    name: "Composite (\\{strategies.length()} strategies)",
    on_init: fn(ctx) {
      // Initialize all component strategies
      for (i, strat) in strategies.iter_enumerated() {
        strat.on_init(ctx)
      }
    },
    on_bar: fn(kline, ctx) {
      // Collect weighted signals from all strategies
      let mut buy_score = 0.0
      let mut sell_score = 0.0
      let mut total_weight = 0.0

      for (i, strat) in strategies.iter_enumerated() {
        let signal = strat.on_bar(kline, ctx)
        let weight = weights[i]
        total_weight = total_weight + weight

        match signal.action {
          @strategy.Action::Buy => buy_score = buy_score + weight
          @strategy.Action::Sell => sell_score = sell_score + weight
          @strategy.Action::Hold => ignore(())
        }
      }

      // Determine composite action
      let normalized_buy = buy_score / total_weight
      let normalized_sell = sell_score / total_weight

      let composite_action = if normalized_buy > 0.6 {
        @strategy.Action::Buy
      } else if normalized_sell > 0.6 {
        @strategy.Action::Sell
      } else {
        @strategy.Action::Hold
      }

      Signal::{
        stock: kline.code,
        action: composite_action,
        price: kline.close,
        timestamp: kline.date,
        strength: Float::max(normalized_buy, normalized_sell),
      }
    },
  }
}

// Usage:
// let ma_strategy = create_ma_cross_strategy(5, 20)
// let momentum_strategy = create_momentum_strategy(20, 0.05, -0.03)
// let rsi_strategy = create_rsi_strategy(14, 30.0, 70.0)
//
// let composite = create_composite_strategy(
//   [ma_strategy, momentum_strategy, rsi_strategy],
//   [0.4, 0.35, 0.25]  // Weights sum to 1.0
// )
```

## Strategy Development Guidelines

### Best Practices

1. **Always initialize state** in `on_init`
2. **Use StrategyContext** for accessing portfolio state
3. **Return consistent signal strength** values (0.0 - 1.0)
4. **Handle edge cases** (insufficient data, missing prices)
5. **Document parameters** and their effects

### Signal Strength Guidelines

| Strength | Interpretation |
|----------|----------------|
| 0.0 - 0.3 | Weak signal |
| 0.3 - 0.6 | Moderate signal |
| 0.6 - 0.8 | Strong signal |
| 0.8 - 1.0 | Very strong signal |

### Testing Your Strategy

Create tests alongside your strategy:

```moonbit
/// Test MA crossover strategy
@test fn test_ma_cross_buy_signal {
  let strategy = create_ma_cross_strategy(5, 20)
  let ctx = create_test_context()
  let kline = create_test_kline()

  let signal = strategy.on_bar(kline, ctx)
  assert_eq(signal.action, @strategy.Action::Buy)
}
```

### Integrating with Risk Controls

Always pair strategies with appropriate risk rules:

```moonbit
// Create strategy
let strategy = create_ma_cross_strategy(5, 20)

// Create risk engine with rules
let risk_engine = @risk.create_risk_engine()
risk_engine.add_rule(@risk.max_drawdown_rule(0.20))  // 20% max drawdown
risk_engine.add_rule(@risk.position_limit_rule(0.95)) // 95% max position

// Run backtest with risk controls
let result = @backtest.run_backtest_with_risk(strategy, data, config, risk_engine)
```

## See Also

- [User Guide](user-guide.md) - CLI usage and configuration
- [Architecture Documentation](architecture.md) - System architecture
- [API Reference](api-reference.md) - Complete API documentation
