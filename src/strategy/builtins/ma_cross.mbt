/// Moving Average Crossover Strategy

///|
/// MA Crossover Strategy state
pub struct MaCrossStrategy {
  fast_period : Int
  slow_period : Int
  name : String
}

///|
/// Create a new MA crossover strategy
pub fn create_ma_cross_strategy(
  fast_period : Int,
  slow_period : Int,
) -> MaCrossStrategy {
  MaCrossStrategy::{
    fast_period,
    slow_period,
    name: "MA Crossover (" +
    fast_period.to_string() +
    "/" +
    slow_period.to_string() +
    ")",
  }
}

///|
/// Get strategy name
pub fn MaCrossStrategy::name(self : MaCrossStrategy) -> String {
  self.name
}

///|
/// Initialize strategy
pub fn MaCrossStrategy::on_init(
  _self : MaCrossStrategy,
  _ctx : @strategy.StrategyContext,
) -> Unit {
  // No initialization needed
}

///|
/// Process a single bar
pub fn MaCrossStrategy::on_bar(
  self : MaCrossStrategy,
  kline : @data.KLine,
  _ctx : @strategy.StrategyContext,
  close_history : Array[Float],
) -> @strategy.Signal {
  if close_history.length() < self.slow_period {
    return @strategy.Signal::{
      stock: kline.code,
      action: @strategy.Action::Hold,
      price: kline.close,
      timestamp: kline.date,
      strength: 0.0,
    }
  }

  let fast_ma = @indicator.sma(close_history, self.fast_period)
  let slow_ma = @indicator.sma(close_history, self.slow_period)

  let current_fast = fast_ma[fast_ma.length() - 1]
  let current_slow = slow_ma[slow_ma.length() - 1]

  // Get previous values if available
  let prev_fast = if fast_ma.length() >= 2 {
    fast_ma[fast_ma.length() - 2]
  } else {
    0.0
  }
  let prev_slow = if slow_ma.length() >= 2 {
    slow_ma[slow_ma.length() - 2]
  } else {
    0.0
  }

  // Detect crossover
  let action = if prev_fast <= prev_slow && current_fast > current_slow {
    @strategy.Action::Buy
  } else if prev_fast >= prev_slow && current_fast < current_slow {
    @strategy.Action::Sell
  } else {
    @strategy.Action::Hold
  }

  let strength = if action != @strategy.Action::Hold {
    Float::abs(current_fast - current_slow) / current_slow
  } else {
    0.0
  }

  @strategy.Signal::{
    stock: kline.code,
    action,
    price: kline.close,
    timestamp: kline.date,
    strength: Float::min(strength, 1.0),
  }
}
