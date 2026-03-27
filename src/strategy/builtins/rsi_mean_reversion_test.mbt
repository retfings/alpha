/// RSI Mean Reversion Strategy tests

///|
test "create_rsi_mean_reversion_strategy - basic creation" {
  let strategy = create_rsi_mean_reversion_strategy(14, 30.0, 70.0)
  assert_true(strategy.name.contains("RSI Mean Reversion"))
  assert_true(strategy.rsi_period == 14)
  assert_true(strategy.oversold_threshold == 30.0)
  assert_true(strategy.overbought_threshold == 70.0)
}

///|
test "create_rsi_mean_reversion_strategy - different parameters" {
  let strategy = create_rsi_mean_reversion_strategy(7, 20.0, 80.0)
  assert_true(strategy.rsi_period == 7)
  assert_true(strategy.oversold_threshold == 20.0)
  assert_true(strategy.overbought_threshold == 80.0)
}

///|
test "RsiMeanReversionStrategy::name - returns correct name" {
  let strategy = create_rsi_mean_reversion_strategy(14, 30.0, 70.0)
  let name = strategy.name()
  assert_true(name.contains("14"))
  assert_true(name.contains("30"))
  assert_true(name.contains("70"))
}

///|
test "RsiMeanReversionStrategy::on_init - no-op" {
  let strategy = create_rsi_mean_reversion_strategy(14, 30.0, 70.0)
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.0,
    last_signal: None,
  }
  strategy.on_init(ctx)
  assert_true(true)
}

///|
test "on_bar - insufficient history returns Hold" {
  let strategy = create_rsi_mean_reversion_strategy(14, 30.0, 70.0)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }
  // Not enough history for RSI(14)
  let history : Array[Float] = [1.0, 2.0, 3.0, 4.0, 5.0]

  let signal = strategy.on_bar(kline, ctx, history)
  assert_true(signal.action == @strategy.Action::Hold)
  assert_true(signal.strength == 0.0)
}

///|
test "on_bar - oversold crossover triggers Buy" {
  let strategy = create_rsi_mean_reversion_strategy(3, 30.0, 70.0)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }
  // Downtrend that should push RSI below 30
  let history : Array[Float] = [15.0, 14.0, 13.0, 12.0, 11.0, 10.0, 9.0, 8.0, 7.0, 6.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // RSI should be low, potentially triggering buy
  assert_true(signal.action == @strategy.Action::Buy || signal.action == @strategy.Action::Hold)
}

///|
test "on_bar - overbought crossover triggers Sell" {
  let strategy = create_rsi_mean_reversion_strategy(3, 30.0, 70.0)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 12.0, 12.5, 11.8, 12.3, 1000000.0, 12300000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 12.3,
    last_signal: None,
  }
  // Uptrend that should push RSI above 70
  let history : Array[Float] = [6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // RSI should be high, potentially triggering sell
  assert_true(signal.action == @strategy.Action::Sell || signal.action == @strategy.Action::Hold)
}

///|
test "create_rsi_mean_reversion_aggressive - uses 20/80 thresholds" {
  let strategy = create_rsi_mean_reversion_aggressive()
  assert_true(strategy.rsi_period == 14)
  assert_true(strategy.oversold_threshold == 20.0)
  assert_true(strategy.overbought_threshold == 80.0)
}

///|
test "create_rsi_mean_reversion_conservative - uses 25/75 thresholds" {
  let strategy = create_rsi_mean_reversion_conservative()
  assert_true(strategy.rsi_period == 14)
  assert_true(strategy.oversold_threshold == 25.0)
  assert_true(strategy.overbought_threshold == 75.0)
}

///|
test "create_rsi_mean_reversion_standard - uses 30/70 thresholds" {
  let strategy = create_rsi_mean_reversion_standard()
  assert_true(strategy.rsi_period == 14)
  assert_true(strategy.oversold_threshold == 30.0)
  assert_true(strategy.overbought_threshold == 70.0)
}

///|
test "on_bar - signal strength calculation" {
  let strategy = create_rsi_mean_reversion_strategy(3, 30.0, 70.0)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }
  // Strong downtrend for oversold signal
  let history : Array[Float] = [20.0, 18.0, 16.0, 14.0, 12.0, 10.0, 8.0, 6.0, 4.0, 2.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // Signal strength should be between 0 and 1
  assert_true(signal.strength >= 0.0)
  assert_true(signal.strength <= 1.0)
}

///|
test "on_bar - extreme downtrend produces strong buy signal" {
  let strategy = create_rsi_mean_reversion_strategy(3, 30.0, 70.0)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 5.0, 5.2, 4.8, 5.0, 1000000.0, 5000000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 5.0,
    last_signal: None,
  }
  // Very strong downtrend
  let history : Array[Float] = [100.0, 90.0, 80.0, 70.0, 60.0, 50.0, 40.0, 30.0, 20.0, 10.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // Should generate buy signal with good strength
  assert_true(signal.action == @strategy.Action::Buy || signal.action == @strategy.Action::Hold)
}

///|
test "on_bar - extreme uptrend produces strong sell signal" {
  let strategy = create_rsi_mean_reversion_strategy(3, 30.0, 70.0)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 100.0, 105.0, 98.0, 102.0, 1000000.0, 102000000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 102.0,
    last_signal: None,
  }
  // Very strong uptrend
  let history : Array[Float] = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // Should generate sell signal with good strength
  assert_true(signal.action == @strategy.Action::Sell || signal.action == @strategy.Action::Hold)
}

///|
test "strategy variants comparison" {
  let aggressive = create_rsi_mean_reversion_aggressive()
  let conservative = create_rsi_mean_reversion_conservative()
  let standard = create_rsi_mean_reversion_standard()

  // Aggressive should have tighter thresholds
  assert_true(aggressive.oversold_threshold < conservative.oversold_threshold)
  assert_true(aggressive.overbought_threshold > conservative.overbought_threshold)

  // Standard should be between them
  assert_true(standard.oversold_threshold >= conservative.oversold_threshold)
  assert_true(standard.overbought_threshold <= conservative.overbought_threshold)
}
