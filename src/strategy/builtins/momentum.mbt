/// Momentum Strategy based on RSI

///|
/// RSI Momentum Strategy state
pub struct MomentumStrategy {
  rsi_period : Int
  overbought_threshold : Float
  oversold_threshold : Float
  name : String
}

///|
/// Create a new momentum strategy
///
/// Parameters:
/// - rsi_period: RSI calculation period (typically 14)
/// - overbought_threshold: RSI level above which to sell (typically 70)
/// - oversold_threshold: RSI level below which to buy (typically 30)
pub fn create_momentum_strategy(
  rsi_period : Int,
  overbought_threshold : Float,
  oversold_threshold : Float,
) -> MomentumStrategy {
  MomentumStrategy::{
    rsi_period,
    overbought_threshold,
    oversold_threshold,
    name: "RSI Momentum (" + rsi_period.to_string() + ")",
  }
}

///|
/// Get strategy name
pub fn MomentumStrategy::name(self : MomentumStrategy) -> String {
  self.name
}

///|
/// Initialize strategy
pub fn MomentumStrategy::on_init(
  _self : MomentumStrategy,
  _ctx : @strategy.StrategyContext,
) -> Unit {
  // No initialization needed
}

///|
/// Process a single bar
///
/// Strategy logic:
/// - RSI < oversold_threshold: Buy signal (stock is oversold)
/// - RSI > overbought_threshold: Sell signal (stock is overbought)
/// - Otherwise: Hold
pub fn MomentumStrategy::on_bar(
  self : MomentumStrategy,
  kline : @data.KLine,
  _ctx : @strategy.StrategyContext,
  close_history : Array[Float],
) -> @strategy.Signal {
  if close_history.length() < self.rsi_period + 1 {
    return @strategy.Signal::hold(kline.code, kline.close, kline.date)
  }

  let rsi_values = @indicator.rsi(close_history, self.rsi_period)
  let current_rsi = rsi_values[rsi_values.length() - 1]

  let (action, strength) = if current_rsi < self.oversold_threshold {
    // Oversold - buy signal
    let strength = (self.oversold_threshold - current_rsi) /
      self.oversold_threshold
    (@strategy.Action::Buy, Float::min(strength, 1.0))
  } else if current_rsi > self.overbought_threshold {
    // Overbought - sell signal
    let strength = (current_rsi - self.overbought_threshold) /
      (Float::from_double(100.0) - self.overbought_threshold)
    (@strategy.Action::Sell, Float::min(strength, 1.0))
  } else {
    // Neutral zone - hold
    (@strategy.Action::Hold, 0.0)
  }

  @strategy.Signal::{
    stock: kline.code,
    action,
    price: kline.close,
    timestamp: kline.date,
    strength,
  }
}

///|
/// Get RSI value for analysis (helper function)
pub fn MomentumStrategy::get_current_rsi(
  self : MomentumStrategy,
  close_history : Array[Float],
) -> Float {
  if close_history.length() < self.rsi_period + 1 {
    Float::from_double(0.0)
  } else {
    let rsi_values = @indicator.rsi(close_history, self.rsi_period)
    rsi_values[rsi_values.length() - 1]
  }
}

///|
/// Check if stock is in oversold territory
pub fn MomentumStrategy::is_oversold(
  self : MomentumStrategy,
  close_history : Array[Float],
) -> Bool {
  let rsi = self.get_current_rsi(close_history)
  rsi < self.oversold_threshold
}

///|
/// Check if stock is in overbought territory
pub fn MomentumStrategy::is_overbought(
  self : MomentumStrategy,
  close_history : Array[Float],
) -> Bool {
  let rsi = self.get_current_rsi(close_history)
  rsi > self.overbought_threshold
}
