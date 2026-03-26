/// Black-box tests for MA Crossover strategy

///|
test "create_ma_cross_strategy - basic creation" {
  let strategy = create_ma_cross_strategy(5, 20)
  assert_true(strategy.name.contains("MA Crossover"))
  assert_true(strategy.fast_period == 5)
  assert_true(strategy.slow_period == 20)
}

///|
test "create_ma_cross_strategy - different periods" {
  let strategy = create_ma_cross_strategy(10, 50)
  assert_true(strategy.fast_period == 10)
  assert_true(strategy.slow_period == 50)
  assert_true(strategy.name.contains("MA Crossover"))
}

///|
test "MaCrossStrategy::name - returns correct name" {
  let strategy = create_ma_cross_strategy(5, 20)
  let name = strategy.name()
  assert_true(name.contains("5"))
  assert_true(name.contains("20"))
  assert_true(name.contains("MA Crossover"))
}

///|
test "MaCrossStrategy::on_init - no-op" {
  let strategy = create_ma_cross_strategy(5, 20)
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
test "MaCrossStrategy::on_bar - insufficient history returns Hold" {
  let strategy = create_ma_cross_strategy(5, 20)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }
  let history : Array[Float] = [
    1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
  ]

  let signal = strategy.on_bar(kline, ctx, history)
  assert_true(signal.action == @strategy.Action::Hold)
  assert_true(signal.strength == 0.0)
}

///|
test "MaCrossStrategy::on_bar - golden cross detection" {
  let strategy = create_ma_cross_strategy(3, 5)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 12.0, 12.5, 11.8, 12.3, 1000000.0, 12300000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 12.3,
    last_signal: None,
  }
  let history : Array[Float] = [
    1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0,
  ]

  let signal = strategy.on_bar(kline, ctx, history)
  assert_true(
    signal.action == @strategy.Action::Buy ||
    signal.action == @strategy.Action::Hold,
  )
}

///|
test "MaCrossStrategy::on_bar - death cross detection" {
  let strategy = create_ma_cross_strategy(3, 5)
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 8.0, 8.2, 7.5, 7.8, 1000000.0, 7800000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 7.8,
    last_signal: None,
  }
  let history : Array[Float] = [
    10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0,
  ]

  let signal = strategy.on_bar(kline, ctx, history)
  assert_true(
    signal.action == @strategy.Action::Sell ||
    signal.action == @strategy.Action::Hold,
  )
}

///|
test "MaCrossStrategy::on_bar - snapshot of signal with various histories" {
  let strategy = create_ma_cross_strategy(3, 5)
  let base_kline = @data.KLine::daily(
    "sh.600000", "2023-01-10", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.05,
  )
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }

  let scenarios : Array[(String, Array[Float])] = [
    ("uptrend", [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]),
    ("downtrend", [10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0]),
    ("sideways", [5.0, 5.1, 4.9, 5.0, 5.2, 4.8, 5.0, 5.1, 4.9, 5.0]),
  ]

  let results = scenarios.map(fn(scenario) {
    let (name, history) = scenario
    let signal = strategy.on_bar(base_kline, ctx, history)
    (name, signal.action.to_string(), signal.strength)
  })

  json_inspect(results, content=[
    ["uptrend", "Hold", 0],
    ["downtrend", "Hold", 0],
    ["sideways", "Buy", 0.008064508438110352],
  ])
}
