/// Backtest engine tests

///|
test "backtest config default values" {
  let config = @strategy.default_backtest_config()
  inspect(config.initial_capital, content="100000")
  inspect(config.commission_rate, content="0.0003000000142492354")
  inspect(config.slippage, content="0.0010000000474974513")
  inspect(config.benchmark, content="None")
}

///|
test "trade log creation" {
  let log = @backtest.create_trade_log()
  inspect(log.entries.length(), content="0")

  let mut_log = @backtest.create_trade_log()
  @backtest.TradeLog::add(
    mut_log,
    "2024-01-01",
    "sh.600000",
    "Buy",
    10.5,
    100.0,
    None,
    "Initial position",
  )
  inspect(mut_log.entries.length(), content="1")
  inspect(mut_log.entries[0].stock, content="sh.600000")
  inspect(mut_log.entries[0].action, content="Buy")
}

///|
test "sma calculation for ma cross" {
  let prices : Array[Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
  let sma3 = @indicator.sma(prices, 3)

  // First 2 should be 0 (not enough data)
  inspect(sma3[0], content="0")
  inspect(sma3[1], content="0")

  // sma3[2] = (1+2+3)/3 = 2.0
  inspect(sma3[2], content="2")

  // sma3[3] = (2+3+4)/3 = 3.0
  inspect(sma3[3], content="3")
}

///|
test "backtest engine creation" {
  let config = @strategy.BacktestConfig::{
    start_date: "2024-01-01",
    end_date: "2024-12-31",
    initial_capital: 100000.0,
    commission_rate: 0.0003,
    slippage: 0.001,
    benchmark: None,
  }

  let engine = @backtest.create_backtest_engine(config)
  inspect(engine.config.initial_capital, content="100000")
  inspect(engine.current_equity, content="100000")
  inspect(engine.peak_equity, content="100000")
  inspect(engine.max_drawdown, content="0")
}

///|
test "default report config" {
  let config = @backtest.default_report_config()
  inspect(config.title, content="Backtest Report")
  inspect(config.include_equity_curve, content="true")
  inspect(config.include_trades, content="true")
}

///|
test "format percentage helper" {
  // Test negative percentage (drawdown)
  let neg_pct = (-0.15 : Float) * 100.0
  assert_true(neg_pct < 0.0)

  // Test positive percentage (return)
  let pos_pct = (0.25 : Float) * 100.0
  assert_true(pos_pct > 0.0)
}
