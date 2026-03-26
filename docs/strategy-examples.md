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

A contrarian strategy using Bollinger Bands to identify when price deviates significantly from its mean.

### Strategy Logic

- **Buy Signal**: Price drops below lower Bollinger Band (oversold)
- **Sell Signal**: Price touches or crosses above middle band (mean reversion)
- **Hold**: Price within bands

### Implementation

```moonbit
/// Mean Reversion Strategy using Bollinger Bands
///
/// Buy when price drops below lower band (oversold)
/// Sell when price reverts to mean (middle band)

pub fn create_mean_reversion_strategy(
  lookback_period : Int,     // Typically 20
  std_dev_multiplier : Float, // Typically 2.0
) -> @strategy.Strategy {
  Strategy::{
    name: "Mean Reversion Bollinger (" + lookback_period.to_string() + ")",
    on_init: fn(ctx) {
      // No initialization needed
    },
    on_bar: fn(kline, ctx, close_history) {
      if close_history.length() < lookback_period {
        return @strategy.Signal::hold(kline.code, kline.close, kline.date)
      }

      // Calculate Bollinger Bands
      let (upper, middle, lower) = @indicator.bollinger_bands(
        close_history, lookback_period, std_dev_multiplier
      )

      let current_price = kline.close
      let current_upper = upper[upper.length() - 1]
      let current_middle = middle[middle.length() - 1]
      let current_lower = lower[lower.length() - 1]

      // Determine action
      let (action, strength) = if current_price < current_lower {
        // Price below lower band - oversold, BUY
        (@strategy.Action::Buy, 0.8)
      } else if current_price > current_middle {
        // Price above mean - take profit, SELL
        (@strategy.Action::Sell, 0.6)
      } else {
        // Within bands - HOLD
        (@strategy.Action::Hold, 0.0)
      }

      @strategy.Signal::{
        stock: kline.code,
        action: action,
        price: current_price,
        timestamp: kline.date,
        strength: strength,
      }
    },
  }
}
```

### Usage Example

```moonbit
// Create strategy with 20-day Bollinger Bands, 2 std dev
let strategy = create_mean_reversion_strategy(20, 2.0)

// Run backtest
let config = @strategy.default_backtest_config()
let engine = @backtest.create_backtest_engine(config)
let result = @backtest.run_backtest(engine, klines, strategy)
```

### Bollinger Bands Interpretation

| Price Position | Signal | Interpretation |
|----------------|--------|----------------|
| Below Lower Band | Buy | Oversold, likely to rebound |
| Above Middle Band | Sell | Overbought, take profits |
| Between Bands | Hold | Normal fluctuation |

### Tips

- **Band Width**: Narrow bands indicate low volatility (potential breakout). Wide bands indicate high volatility.
- **Squeeze**: When bands contract tightly, a significant price move often follows.
- **Trend Confirmation**: In strong trends, price can "walk the band" - stay near upper/lower band for extended periods.

---

## Example 4: Multi-Strategy Composite

Combine multiple strategies into a single composite strategy with weighted voting for more robust signals.

### Strategy Logic

- Collect signals from multiple component strategies
- Apply weights to each signal based on confidence
- Generate composite action based on weighted voting

### Implementation

```moonbit
/// Composite Strategy
///
/// Combines signals from multiple strategies with weighted voting

pub fn create_composite_strategy(
  strategies : Array[@strategy.Strategy],
  weights : Array[Float],  // Should sum to 1.0
) -> @strategy.Strategy {
  Strategy::{
    name: "Composite (" + strategies.length().to_string() + " strategies)",
    on_init: fn(ctx) {
      // Initialize all component strategies
      for strat in strategies {
        strat.on_init(ctx)
      }
    },
    on_bar: fn(kline, ctx, close_history) {
      var buy_score = 0.0
      var sell_score = 0.0
      var total_weight = 0.0

      for (i, strat) in strategies.iter_enumerated() {
        let signal = strat.on_bar(kline, ctx, close_history)
        let weight = weights[i]
        total_weight = total_weight + weight

        match signal.action {
          @strategy.Action::Buy => buy_score = buy_score + weight * signal.strength
          @strategy.Action::Sell => sell_score = sell_score + weight * signal.strength
          @strategy.Action::Hold => ()
        }
      }

      // Determine composite action
      let composite_action = if buy_score > 0.6 {
        @strategy.Action::Buy
      } else if sell_score > 0.6 {
        @strategy.Action::Sell
      } else {
        @strategy.Action::Hold
      }

      @strategy.Signal::{
        stock: kline.code,
        action: composite_action,
        price: kline.close,
        timestamp: kline.date,
        strength: Float::max(buy_score, sell_score),
      }
    },
  }
}
```

### Usage Example

```moonbit
// Create component strategies
let ma_strategy = @strategy.builtins.create_ma_cross_strategy(10, 30)
let momentum_strategy = @strategy.builtins.create_momentum_strategy(14, 70.0, 30.0)

// Create composite with equal weights
let composite = create_composite_strategy(
  [ma_strategy, momentum_strategy],
  [0.5, 0.5]  // Equal weighting
)

// Run backtest
let config = @strategy.default_backtest_config()
let engine = @backtest.create_backtest_engine(config)
let result = @backtest.run_backtest(engine, klines, composite)
```

### Benefits of Composite Strategies

| Benefit | Description |
|---------|-------------|
| Diversification | Reduces reliance on any single strategy |
| Smoother Equity | Multiple uncorrelated strategies reduce volatility |
| Robustness | Less prone to overfitting |

### Tips

- **Weight Optimization**: Start with equal weights, then adjust based on historical performance.
- **Correlation**: Combine strategies with low correlation for best diversification benefits.
- **Rebalancing**: Consider periodic weight rebalancing based on recent performance.

---

## Strategy Development Guidelines

### Best Practices

1. **Always initialize state** in `on_init` if your strategy maintains internal state
2. **Use StrategyContext** for accessing portfolio state (capital, position, etc.)
3. **Return consistent signal strength** values between 0.0 and 1.0
4. **Handle edge cases** like insufficient data or missing prices
5. **Document parameters** and their expected ranges
6. **Test with various market conditions** (bull, bear, sideways)

### Signal Strength Guidelines

| Strength | Interpretation | When to Use |
|----------|----------------|-------------|
| 0.0 - 0.3 | Weak signal | Low confidence, borderline conditions |
| 0.3 - 0.6 | Moderate signal | Standard signal conditions met |
| 0.6 - 0.8 | Strong signal | Multiple indicators confirm |
| 0.8 - 1.0 | Very strong signal | Extreme conditions, high conviction |

### Testing Your Strategy

Create unit tests for your strategy:

```moonbit
@test fn test_ma_cross_buy_signal {
  let strategy = @strategy.builtins.create_ma_cross_strategy(5, 20)
  let klines = create_test_klines()  // Create test data with crossover
  let ctx = create_test_context()
  let close_history = klines.map(fn(k) { k.close })

  let signal = strategy.on_bar(klines.last(), ctx, close_history)
  assert_eq(signal.action, @strategy.Action::Buy)
  assert_true(signal.strength > 0.0)
}
```

### Integrating with Risk Controls

Always pair strategies with appropriate risk rules:

```moonbit
// Create strategy
let strategy = @strategy.builtins.create_ma_cross_strategy(10, 30)

// Create backtest engine with risk management
let config = @strategy.default_backtest_config()
let mut engine = @backtest.create_backtest_engine(config)

// Add risk rules
engine.risk_engine.add_rule(@risk.max_drawdown_rule(0.20))     // 20% max DD
engine.risk_engine.add_rule(@risk.position_limit_rule(0.95))    // 95% max position
engine.risk_engine.add_rule(@risk.daily_loss_limit_rule(0.05))  // 5% daily loss

// Run backtest with risk controls
let result = @backtest.run_backtest(engine, klines, strategy)
```

### Common Pitfalls to Avoid

| Pitfall | Description | Solution |
|---------|-------------|----------|
| Look-ahead Bias | Using future data in signal generation | Only use data available at signal time |
| Overfitting | Too closely fitted to historical data | Test on out-of-sample data |
| Ignoring Costs | Not including commission/slippage | Use realistic cost assumptions |
| Survivorship Bias | Testing only on surviving stocks | Include delisted stocks in tests |
| Data Snooping | Testing too many parameters | Use walk-forward analysis |

---

## See Also

- [User Guide](user-guide.md) - CLI usage and configuration
- [Architecture Documentation](architecture.md) - System architecture
- [API Reference](api-reference.md) - Complete API documentation
