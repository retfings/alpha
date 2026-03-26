/// White-box tests for strategy module - test internal helpers

///|
test "create_strategy_engine - initial state" {
  let engine = create_strategy_engine(100000.0)
  assert_true(engine.capital == 100000.0)
  assert_true(engine.position == 0.0)
  assert_true(engine.last_price == 0.0)
  assert_true(engine.signals.length() == 0)
  assert_true(engine.results.length() == 0)
}

///|
test "create_strategy_engine - zero capital" {
  let engine = create_strategy_engine(0.0)
  assert_true(engine.capital == 0.0)
  assert_true(engine.position == 0.0)
}

///|
test "get_engine_stats - initial state" {
  let engine = create_strategy_engine(100000.0)
  let (capital, position, signal_count) = get_engine_stats(engine)
  assert_true(capital == 100000.0)
  assert_true(position == 0.0)
  assert_true(signal_count == 0)
}

///|
test "Action equality" {
  assert_true(Action::Buy == Action::Buy)
  assert_true(Action::Sell == Action::Sell)
  assert_true(Action::Hold == Action::Hold)
  assert_true(Action::Buy != Action::Sell)
  assert_true(Action::Buy != Action::Hold)
  assert_true(Action::Sell != Action::Hold)
}

///|
test "Action show" {
  assert_true(Action::Buy.to_string().contains("Buy"))
  assert_true(Action::Sell.to_string().contains("Sell"))
  assert_true(Action::Hold.to_string().contains("Hold"))
}

///|
test "default_backtest_config - values" {
  let config = default_backtest_config()
  assert_true(config.initial_capital == 100000.0)
  assert_true(config.commission_rate == 0.0003)
  assert_true(config.slippage == 0.001)
  assert_true(config.benchmark == None)
}

///|
test "Signal creation" {
  let signal = Signal::{
    stock: "sh.600000",
    action: Action::Buy,
    price: 10.5,
    timestamp: "2023-01-01",
    strength: 0.8,
  }
  assert_true(signal.price == 10.5)
  assert_true(signal.action == Action::Buy)
  assert_true(signal.strength == 0.8)
}

///|
test "StrategyContext creation" {
  let ctx = StrategyContext::{
    capital: 100000.0,
    position: 50000.0,
    current_price: 10.5,
    last_signal: None,
  }
  assert_true(ctx.capital == 100000.0)
  assert_true(ctx.position == 50000.0)
  assert_true(ctx.current_price == 10.5)
}

///|
test "StrategyContext with last signal" {
  let signal = Signal::{
    stock: "sh.600000",
    action: Action::Buy,
    price: 10.5,
    timestamp: "2023-01-01",
    strength: 0.8,
  }
  let ctx = StrategyContext::{
    capital: 100000.0,
    position: 50000.0,
    current_price: 10.5,
    last_signal: Some(signal),
  }
  match ctx.last_signal {
    Some(s) => {
      assert_true(s.price == 10.5)
      assert_true(s.action == Action::Buy)
    }
    None => fail("Expected Some signal")
  }
}

///|
test "StrategyResult creation" {
  let signal = Signal::{
    stock: "sh.600000",
    action: Action::Buy,
    price: 10.5,
    timestamp: "2023-01-01",
    strength: 0.8,
  }
  let result = StrategyResult::{
    signal,
    executed: true,
    exec_price: 10.5,
    exec_volume: 1000.0,
  }
  assert_true(result.executed)
  assert_true(result.exec_price == 10.5)
  assert_true(result.exec_volume == 1000.0)
}

///|
test "StrategyEngine - snapshot of internal state" {
  let engine = create_strategy_engine(100000.0)
  json_inspect(
    (
      engine.capital,
      engine.position,
      engine.last_price,
      engine.signals.length(),
      engine.results.length(),
    ),
  )
}

///|
test "process_bar - internal snapshot" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.8, 1000000.0, 10500000.0, 0.05,
  )

  let engine = create_strategy_engine(100000.0)
  let close_history : Array[Float] = [10.0, 10.2, 10.5, 10.8]

  let buy_strategy = Strategy::{
    name: "Always Buy",
    on_init: fn(_) {  },
    on_bar: fn(kline, ctx, _close_history) {
      Signal::{
        stock: kline.code,
        action: Action::Buy,
        price: kline.close,
        timestamp: kline.date,
        strength: 1.0,
      }
    },
  }

  let result = process_bar(engine, buy_strategy, kline, close_history)
  json_inspect(result)
}

///|
test "Signal - json inspection for all action types" {
  let base_price : Float = 100.0
  let signals = [
    Signal::{
      stock: "sh.600000",
      action: Action::Buy,
      price: base_price,
      timestamp: "2023-01-01",
      strength: 0.9,
    },
    Signal::{
      stock: "sh.600000",
      action: Action::Sell,
      price: base_price * Float::from_double(1.05),
      timestamp: "2023-01-02",
      strength: 0.7,
    },
    Signal::{
      stock: "sh.600000",
      action: Action::Hold,
      price: base_price * Float::from_double(1.03),
      timestamp: "2023-01-03",
      strength: 0.0,
    },
  ]
  json_inspect(signals)
}

///|
test "StrategyContext - various states snapshot" {
  let contexts = [
    StrategyContext::{
      capital: 100000.0,
      position: 0.0,
      current_price: 10.0,
      last_signal: None,
    },
    StrategyContext::{
      capital: 90000.0,
      position: 10000.0,
      current_price: 10.5,
      last_signal: None,
    },
  ]
  json_inspect(contexts)
}
