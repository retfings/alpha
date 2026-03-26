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
  json_inspect({
    name: strategy.name,
    fast: strategy.fast_period,
    slow: strategy.slow_period,
  })
}

///|
test "MaCrossStrategy::name - returns correct name" {
  let strategy = create_ma_cross_strategy(5, 20)
  let name = strategy.name()
  assert_true(name.contains("5"))
  assert_true(name.contains("20"))
  json_inspect(name)
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
  // on_init should not fail
  strategy.on_init(ctx)
  assert_true(true)
}

///|
test "MaCrossStrategy::on_bar - insufficient history returns Hold" {
  let strategy = create_ma_cross_strategy(5, 20)
  let kline = @data.KLine::{
    code: "sh.600000",
    date: "2023-01-01",
    time: None,
    open: 10.0,
    high: 10.5,
    low: 9.8,
    close: 10.2,
    volume: 1000000.0,
    amount: 10200000.0,
    turn: 0.05,
  }
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }
  // Only 10 data points, less than slow_period (20)
  let history : Array[Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

  let signal = strategy.on_bar(kline, ctx, history)
  assert_true(signal.action == @strategy.Action::Hold)
  assert_true(signal.strength == 0.0)
  json_inspect(signal)
}

///|
test "MaCrossStrategy::on_bar - golden cross detection" {
  let strategy = create_ma_cross_strategy(3, 5)
  let kline = @data.KLine::{
    code: "sh.600000",
    date: "2023-01-10",
    time: None,
    open: 12.0,
    high: 12.5,
    low: 11.8,
    close: 12.3,
    volume: 1000000.0,
    amount: 12300000.0,
    turn: 0.05,
  }
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 12.3,
    last_signal: None,
  }
  // Uptrend: fast MA should cross above slow MA
  // Prices: 1,2,3,4,5,6,7,8,9,10 - rising trend
  let history : Array[Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // After a sustained uptrend, fast MA should be above slow MA
  // The crossover from below should trigger a Buy
  assert_true(signal.action == @strategy.Action::Buy || signal.action == @strategy.Action::Hold)
  json_inspect({
    action: signal.action.to_string(),
    strength: signal.strength,
    price: signal.price,
  })
}

///|
test "MaCrossStrategy::on_bar - death cross detection" {
  let strategy = create_ma_cross_strategy(3, 5)
  let kline = @data.KLine::{
    code: "sh.600000",
    date: "2023-01-10",
    time: None,
    open: 8.0,
    high: 8.2,
    low: 7.5,
    close: 7.8,
    volume: 1000000.0,
    amount: 7800000.0,
    turn: 0.05,
  }
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 7.8,
    last_signal: None,
  }
  // Downtrend: fast MA should cross below slow MA
  // Prices: 10,9,8,7,6,5,4,3,2,1 - falling trend
  let history : Array[Float] = [10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0]

  let signal = strategy.on_bar(kline, ctx, history)
  // After a sustained downtrend, fast MA should be below slow MA
  // The crossover from above should trigger a Sell
  assert_true(signal.action == @strategy.Action::Sell || signal.action == @strategy.Action::Hold)
  json_inspect({
    action: signal.action.to_string(),
    strength: signal.strength,
    price: signal.price,
  })
}

///|
test "MaCrossStrategy::on_bar - snapshot of signal with various histories" {
  let strategy = create_ma_cross_strategy(3, 5)
  let base_kline = @data.KLine::{
    code: "sh.600000",
    date: "2023-01-10",
    time: None,
    open: 10.0,
    high: 10.5,
    low: 9.8,
    close: 10.2,
    volume: 1000000.0,
    amount: 10200000.0,
    turn: 0.05,
  }
  let ctx = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.2,
    last_signal: None,
  }

  let scenarios = [
    ("uptrend", [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]),
    ("downtrend", [10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0]),
    ("sideways", [5.0, 5.1, 4.9, 5.0, 5.2, 4.8, 5.0, 5.1, 4.9, 5.0]),
  ]

  let results = scenarios.map(fn(scenario) {
    let (name, history) = scenario
    let signal = strategy.on_bar(base_kline, ctx, history)
    (name, signal.action.to_string(), signal.strength)
  })

  json_inspect(results)
}
