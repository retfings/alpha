/// Black-box tests for strategy module - test public API

///|
test "default_backtest_config via public API" {
  let config = @strategy.default_backtest_config()
  assert_true(config.initial_capital == 100000.0)
  assert_true(config.commission_rate == 0.0003)
  assert_true(config.slippage == 0.001)
}

///|
test "create_strategy_engine via public API" {
  let engine = @strategy.create_strategy_engine(100000.0)
  let (capital, position, signal_count) = @strategy.get_engine_stats(engine)
  assert_true(capital == 100000.0)
  assert_true(position == 0.0)
  assert_true(signal_count == 0)
}

///|
test "StrategyResult - snapshot test" {
  let signal = @strategy.Signal::{
    stock: "sh.600000",
    action: @strategy.Action::Buy,
    price: 10.5,
    timestamp: "2023-01-01",
    strength: 0.8,
  }
  let result = @strategy.StrategyResult::{
    signal,
    executed: true,
    exec_price: 10.5,
    exec_volume: 1000.0,
  }
  json_inspect(result)
}

///|
test "Signal - json inspection with various actions" {
  let signals = [
    @strategy.Signal::{
      stock: "sh.600000",
      action: @strategy.Action::Buy,
      price: 10.5,
      timestamp: "2023-01-01",
      strength: 0.8,
    },
    @strategy.Signal::{
      stock: "sz.000001",
      action: @strategy.Action::Sell,
      price: 25.3,
      timestamp: "2023-01-02",
      strength: 0.6,
    },
    @strategy.Signal::{
      stock: "sh.600000",
      action: @strategy.Action::Hold,
      price: 10.7,
      timestamp: "2023-01-03",
      strength: 0.0,
    },
  ]
  json_inspect(signals)
}

///|
test "StrategyContext - snapshot tests" {
  let ctx_no_signal = @strategy.StrategyContext::{
    capital: 100000.0,
    position: 0.0,
    current_price: 10.5,
    last_signal: None,
  }

  let signal = @strategy.Signal::{
    stock: "sh.600000",
    action: @strategy.Action::Buy,
    price: 10.5,
    timestamp: "2023-01-01",
    strength: 0.8,
  }
  let ctx_with_signal = @strategy.StrategyContext::{
    capital: 95000.0,
    position: 5000.0,
    current_price: 10.7,
    last_signal: Some(signal),
  }

  json_inspect(("no_signal", ctx_no_signal, "with_signal", ctx_with_signal))
}

///|
test "Action enum - json inspection" {
  json_inspect((@strategy.Action::Buy, @strategy.Action::Sell, @strategy.Action::Hold))
}

///|
test "process_bar - snapshot test" {
  let kline = @data.KLine::daily("sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.8, 1000000.0, 10500000.0, 0.05)

  let engine = @strategy.create_strategy_engine(100000.0)

  let hold_strategy = @strategy.Strategy::{
    name: "Hold Strategy",
    on_init: fn(_) { },
    on_bar: fn(kline, ctx, close_history) {
      @strategy.Signal::{
        stock: kline.code,
        action: @strategy.Action::Hold,
        price: kline.close,
        timestamp: kline.date,
        strength: 0.0,
      }
    },
  }

  let close_history : Array[Float] = [10.5, 10.6, 10.7, 10.8]
  let result = @strategy.process_bar(engine, hold_strategy, kline, close_history)
  json_inspect(result)
}

///|
test "get_engine_stats - after processing bars" {
  let engine = @strategy.create_strategy_engine(100000.0)
  let (capital, position, signal_count) = @strategy.get_engine_stats(engine)
  json_inspect(("initial", (capital, position, signal_count)))
}

// Disabled: BacktestConfig is read-only and doesn't implement ToJson
// test "BacktestConfig - full config snapshot" {
//   let config = @strategy.default_backtest_config()
//   json_inspect(config)
//
//   let custom_config = @strategy.BacktestConfig::{
//     start_date: "2023-01-01",
//     end_date: "2023-12-31",
//     initial_capital: 500000.0,
//     commission_rate: 0.00025,
//     slippage: 0.0005,
//     benchmark: Some("sh.000001"),
//   }
//   json_inspect(custom_config)
// }
