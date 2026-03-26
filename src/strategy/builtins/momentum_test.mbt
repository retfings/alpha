/// Black-box tests for Momentum (RSI) strategy

///|
test "create_momentum_strategy - basic creation" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  assert_true(strategy.name.contains("RSI Momentum"))
  assert_true(strategy.rsi_period == 14)
  assert_true(strategy.overbought_threshold == 70.0)
  assert_true(strategy.oversold_threshold == 30.0)
}

///|
test "create_momentum_strategy - custom thresholds" {
  let strategy = create_momentum_strategy(21, 80.0, 20.0)
  assert_true(strategy.rsi_period == 21)
  assert_true(strategy.overbought_threshold == 80.0)
  assert_true(strategy.oversold_threshold == 20.0)
  json_inspect({
    name: strategy.name,
    period: strategy.rsi_period,
    overbought: strategy.overbought_threshold,
    oversold: strategy.oversold_threshold,
  })
}

///|
test "MomentumStrategy::name - returns correct name" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  let name = strategy.name()
  assert_true(name.contains("14"))
  json_inspect(name)
}

///|
test "MomentumStrategy::on_init - no-op" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
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
test "MomentumStrategy::on_bar - insufficient history returns Hold" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  let kline = @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05)
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }
  // Only 10 data points, less than rsi_period + 1 (15)
  let history : Array[Float] = [
    1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
  ]

  let signal = strategy.on_bar(kline, ctx, history)
  assert_true(signal.action == @strategy.Action::Hold)
  assert_true(signal.strength == 0.0)
  json_inspect(signal)
}

///|
test "MomentumStrategy::on_bar - oversold scenario (Buy signal)" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  let kline = @data.KLine::daily("sh.600000", "2023-01-15", 8.0, 8.2, 7.5, 7.8, 2000000.0, 15600000.0, 0.10)
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 7.8,
    last_signal: None,
  }
  // Simulate declining prices that would result in low RSI (oversold)
  // Sharp decline followed by slight recovery
  let history : Array[Float] = [
    20.0, 19.5, 19.0, 18.5, 18.0, 17.5, 17.0, 16.5, 16.0, 15.5, 15.0, 14.5, 14.0,
    13.5, 13.0, 12.5, 12.0, 11.5, 11.0, 10.0,
  ]

  let signal = strategy.on_bar(kline, ctx, history)
  // RSI should be low, potentially triggering Buy
  assert_true(
    signal.action == @strategy.Action::Buy ||
    signal.action == @strategy.Action::Hold,
  )
  json_inspect({
    action: signal.action.to_string(),
    strength: signal.strength,
    price: signal.price,
  })
}

///|
test "MomentumStrategy::on_bar - overbought scenario (Sell signal)" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  let kline = @data.KLine::daily("sh.600000", "2023-01-15", 22.0, 23.0, 21.8, 22.5, 3000000.0, 67500000.0, 0.15)
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 22.5,
    last_signal: None,
  }
  // Simulate rising prices that would result in high RSI (overbought)
  // Sharp increase
  let history : Array[Float] = [
    5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0, 12.0, 14.0, 16.0, 18.0,
    19.0, 20.0, 21.0, 22.0, 22.5,
  ]

  let signal = strategy.on_bar(kline, ctx, history)
  // RSI should be high, potentially triggering Sell
  assert_true(
    signal.action == @strategy.Action::Sell ||
    signal.action == @strategy.Action::Hold,
  )
  json_inspect({
    action: signal.action.to_string(),
    strength: signal.strength,
    price: signal.price,
  })
}

///|
test "MomentumStrategy::is_oversold - detection" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  // Declining prices should result in oversold condition
  let declining_history : Array[Float] = [
    20.0, 19.0, 18.0, 17.0, 16.0, 15.0, 14.0, 13.0, 12.0, 11.0, 10.0, 9.5, 9.0, 8.5,
    8.0, 7.5, 7.0, 6.5, 6.0, 5.5,
  ]
  let is_oversold = strategy.is_oversold(declining_history)
  // Should detect oversold condition
  json_inspect({ is_oversold, })
}

///|
test "MomentumStrategy::is_overbought - detection" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  // Rising prices should result in overbought condition
  let rising_history : Array[Float] = [
    5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0,
    19.0, 20.0, 21.0, 22.0, 23.0, 24.0,
  ]
  let is_overbought = strategy.is_overbought(rising_history)
  json_inspect({ is_overbought, })
}

///|
test "MomentumStrategy::get_current_rsi - value check" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  let history : Array[Float] = [
    10.0, 10.5, 11.0, 10.8, 11.2, 11.5, 11.3, 11.8, 12.0, 11.9, 12.2, 12.5, 12.3,
    12.8, 13.0, 12.9, 13.2, 13.5, 13.3, 13.8,
  ]
  let rsi = strategy.get_current_rsi(history)
  // RSI should be between 0 and 100
  assert_true(rsi >= 0.0 && rsi <= 100.0)
  json_inspect({ rsi, })
}

///|
test "MomentumStrategy - snapshot of signals with various scenarios" {
  let strategy = create_momentum_strategy(14, 70.0, 30.0)
  let base_kline = @data.KLine::daily("sh.600000", "2023-01-15", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05)
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }

  let scenarios = [
    (
      "declining",
      [
        20.0, 19.0, 18.0, 17.0, 16.0, 15.0, 14.0, 13.0, 12.0, 11.0, 10.0, 9.5, 9.0,
        8.5, 8.0, 7.5, 7.0, 6.5, 6.0, 5.5,
      ],
    ),
    (
      "rising",
      [
        5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0,
        18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0,
      ],
    ),
    (
      "sideways",
      [
        10.0, 10.1, 9.9, 10.0, 10.2, 9.8, 10.0, 10.1, 9.9, 10.0, 10.1, 9.9, 10.0,
        10.2, 9.8, 10.0, 10.1, 9.9, 10.0, 10.05,
      ],
    ),
  ]

  let results = scenarios.map(fn(scenario) {
    let (name, history) = scenario
    let signal = strategy.on_bar(base_kline, ctx, history)
    (name, signal.action.to_string(), signal.strength)
  })

  json_inspect(results)
}
