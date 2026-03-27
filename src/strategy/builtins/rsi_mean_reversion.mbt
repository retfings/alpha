/// RSI Mean Reversion Strategy
///
/// A contrarian strategy that buys when RSI is oversold and sells when RSI is overbought,
/// betting on mean reversion.

///|
/// RSI Mean Reversion Strategy state
pub struct RsiMeanReversionStrategy {
  rsi_period : Int
  oversold_threshold : Float
  overbought_threshold : Float
  name : String
}

///|
/// Create a new RSI Mean Reversion strategy
///
/// Parameters:
/// - rsi_period: RSI calculation period (typically 14)
/// - oversold_threshold: RSI level considered oversold (typically 30)
/// - overbought_threshold: RSI level considered overbought (typically 70)
pub fn create_rsi_mean_reversion_strategy(
  rsi_period : Int,
  oversold_threshold : Float,
  overbought_threshold : Float,
) -> RsiMeanReversionStrategy {
  RsiMeanReversionStrategy::{
    rsi_period,
    oversold_threshold,
    overbought_threshold,
    name: "RSI Mean Reversion (" +
    rsi_period.to_string() +
    ", " +
    oversold_threshold.to_string() +
    "/" +
    overbought_threshold.to_string() +
    ")",
  }
}

///|
/// Get strategy name
pub fn RsiMeanReversionStrategy::name(self : RsiMeanReversionStrategy) -> String {
  self.name
}

///|
/// Initialize strategy
pub fn RsiMeanReversionStrategy::on_init(
  _self : RsiMeanReversionStrategy,
  _ctx : @strategy.StrategyContext,
) -> Unit {
  // No initialization needed
}

///|
/// Process a single bar
///
/// Logic:
/// - Buy when RSI crosses below oversold threshold (potential reversal up)
/// - Sell when RSI crosses above overbought threshold (potential reversal down)
/// - Hold otherwise
pub fn RsiMeanReversionStrategy::on_bar(
  self : RsiMeanReversionStrategy,
  kline : @data.KLine,
  _ctx : @strategy.StrategyContext,
  close_history : Array[Float],
) -> @strategy.Signal {
  // Need enough history for RSI calculation
  if close_history.length() < self.rsi_period + 1 {
    return @strategy.Signal::{
      stock: kline.code,
      action: @strategy.Action::Hold,
      price: kline.close,
      timestamp: kline.date,
      strength: 0.0,
    }
  }

  let rsi_values = @indicator.rsi(close_history, self.rsi_period)
  let current_rsi = rsi_values[rsi_values.length() - 1]

  // Get previous RSI if available
  let prev_rsi = if rsi_values.length() >= 2 {
    rsi_values[rsi_values.length() - 2]
  } else {
    0.0
  }

  // Determine action based on RSI levels and crossovers
  let action = if prev_rsi >= self.oversold_threshold and current_rsi < self.oversold_threshold
  {
    // RSI crossed below oversold - potential buy signal
    @strategy.Action::Buy
  } else if prev_rsi <= self.overbought_threshold
    and current_rsi > self.overbought_threshold
  {
    // RSI crossed above overbought - potential sell signal
    @strategy.Action::Sell
  } else {
    @strategy.Action::Hold
  }

  // Calculate signal strength based on how far RSI is from threshold
  let strength = if action == @strategy.Action::Buy {
    (self.oversold_threshold - current_rsi) / self.oversold_threshold
  } else if action == @strategy.Action::Sell {
    (current_rsi - self.overbought_threshold) /
    (100.0 - self.overbought_threshold)
  } else {
    0.0
  }

  @strategy.Signal::{
    stock: kline.code,
    action,
    price: kline.close,
    timestamp: kline.date,
    strength: Float::min(Float::abs(strength), 1.0),
  }
}

///|
/// Aggressive RSI Mean Reversion variant
/// Uses tighter thresholds (20/80) for stronger signals
pub fn create_rsi_mean_reversion_aggressive() -> RsiMeanReversionStrategy {
  create_rsi_mean_reversion_strategy(14, 20.0, 80.0)
}

///|
/// Conservative RSI Mean Reversion variant
/// Uses wider thresholds (25/75) for more frequent signals
pub fn create_rsi_mean_reversion_conservative() -> RsiMeanReversionStrategy {
  create_rsi_mean_reversion_strategy(14, 25.0, 75.0)
}

///|
/// Standard RSI Mean Reversion variant
/// Uses classic thresholds (30/70)
pub fn create_rsi_mean_reversion_standard() -> RsiMeanReversionStrategy {
  create_rsi_mean_reversion_strategy(14, 30.0, 70.0)
}
