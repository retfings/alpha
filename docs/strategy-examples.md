# Strategy Examples

This document provides example strategies demonstrating how to use the MoonBit Drawdown Framework.

## Strategy Structure

All strategies follow a common structure:

```moonbit
pub fn create_strategy() -> @strategy.Strategy {
  Strategy::{
    name: "Strategy Name",
    on_init: fn(ctx) { /* initialization */ },
    on_bar: fn(kline, ctx) { /* signal generation */ },
  }
}
```

## Example 1: Moving Average Crossover Strategy

A classic trend-following strategy that generates signals when a fast moving average crosses a slow moving average.

```moonbit
/// Moving Average Crossover Strategy
///
/// Buy when fast MA crosses above slow MA
/// Sell when fast MA crosses below slow MA

pub fn create_ma_cross_strategy(
  fast_period : Int,
  slow_period : Int,
) -> @strategy.Strategy {

  // Store historical signals
  let mut prev_fast_ma = 0.0
  let mut prev_slow_ma = 0.0

  Strategy::{
    name: "MA Crossover (\\{fast_period}/\\{slow_period})",
    on_init: fn(ctx) {
      // Initialize strategy state
      prev_fast_ma = 0.0
      prev_slow_ma = 0.0
    },
    on_bar: fn(kline, ctx) {
      // Calculate moving averages (simplified - use indicator library in production)
      let fast_ma = kline.close  // Replace with actual MA calculation
      let slow_ma = kline.close  // Replace with actual MA calculation

      // Detect crossover
      let signal_action = if prev_fast_ma <= prev_slow_ma && fast_ma > slow_ma {
        // Bullish crossover - BUY
        @strategy.Action::Buy
      } else if prev_fast_ma >= prev_slow_ma && fast_ma < slow_ma {
        // Bearish crossover - SELL
        @strategy.Action::Sell
      } else {
        // No crossover - HOLD
        @strategy.Action::Hold
      }

      // Update previous values
      prev_fast_ma = fast_ma
      prev_slow_ma = slow_ma

      // Generate signal
      Signal::{
        stock: kline.code,
        action: signal_action,
        price: kline.close,
        timestamp: kline.date,
        strength: 0.8,  // Fixed strength for this example
      }
    },
  }
}

// Usage:
// let strategy = create_ma_cross_strategy(5, 20)  // 5-day and 20-day MA
```

### Running the MA Crossover Strategy

```bash
moon run cmd/main backtest \
  --strategy ma_cross \
  --stock sh.600000 \
  --start 2023-01-01 \
  --end 2023-12-31
```

## Example 2: Momentum Strategy

A momentum-based strategy that buys stocks with strong recent performance and sells when momentum weakens.

```moonbit
/// Momentum Strategy
///
/// Buy when price momentum exceeds threshold
/// Sell when momentum falls below threshold

pub fn create_momentum_strategy(
  lookback_period : Int,
  entry_threshold : Float,
  exit_threshold : Float,
) -> @strategy.Strategy {

  let mut momentum_value = 0.0
  let mut in_position = false

  Strategy::{
    name: "Momentum (\\{lookback_period}d)",
    on_init: fn(ctx) {
      momentum_value = 0.0
      in_position = false
    },
    on_bar: fn(kline, ctx) {
      // Calculate momentum (rate of change)
      // momentum = (current_price - price_n_days_ago) / price_n_days_ago
      momentum_value = calculate_momentum(kline, lookback_period)

      // Determine action based on momentum
      let signal_action = if momentum_value >= entry_threshold && !in_position {
        // Strong momentum - BUY
        in_position = true
        @strategy.Action::Buy
      } else if momentum_value <= exit_threshold && in_position {
        // Momentum weakened - SELL
        in_position = false
        @strategy.Action::Sell
      } else {
        // Hold current position
        @strategy.Action::Hold
      }

      Signal::{
        stock: kline.code,
        action: signal_action,
        price: kline.close,
        timestamp: kline.date,
        strength: normalize_momentum_strength(momentum_value),
      }
    },
  }
}

// Helper function: Calculate momentum
fn calculate_momentum(kline : @data.KLine, period : Int) -> Float {
  // In production, access historical data from context
  // This is a placeholder
  0.0
}

// Helper function: Normalize momentum to 0-1 strength
fn normalize_momentum_strength(momentum : Float) -> Float {
  let abs_momentum = Float::abs(momentum)
  if abs_momentum > 1.0 { 1.0 } else { abs_momentum }
}

// Usage:
// let strategy = create_momentum_strategy(20, 0.05, -0.03)
// - 20-day lookback
// - Enter when momentum > 5%
// - Exit when momentum < -3%
```

### Running the Momentum Strategy

```bash
moon run cmd/main backtest \
  --strategy momentum \
  --stock sz.000001 \
  --start 2023-01-01 \
  --end 2023-12-31
```

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
