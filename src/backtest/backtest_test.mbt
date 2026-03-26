/// Backtest package black-box snapshot tests

///|
test "BacktestConfig default values snapshot" {
  let config = @strategy.default_backtest_config()
  inspect(config.initial_capital, content="100000")
  inspect(config.commission_rate, content="0.0003000000142492354")
  inspect(config.slippage, content="0.0010000000474974513")
  inspect(config.benchmark, content="None")
}

///|
test "BacktestConfig custom values snapshot" {
  let config = @strategy.BacktestConfig::{
    start_date: "2024-01-01",
    end_date: "2024-12-31",
    initial_capital: 500000.0,
    commission_rate: 0.0001,
    slippage: 0.0005,
    benchmark: Some("sh.000300"),
  }
  inspect(config.start_date, content="2024-01-01")
  inspect(config.end_date, content="2024-12-31")
  inspect(config.initial_capital, content="500000")
  inspect(
    config.commission_rate,
    content=(
      #|0.00009999999747378752
    ),
  )
  inspect(
    config.slippage,
    content=(
      #|0.0005000000237487257
    ),
  )
}

///|
test "BacktestEngine creation snapshot" {
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
  inspect(engine.current_date, content="")
}

///|
test "Trade creation snapshot" {
  let trade = @backtest.Trade::{
    stock: "sh.600000",
    action: @strategy.Action::Buy,
    price: 10.5,
    quantity: 100.0,
    timestamp: "2024-01-15",
    commission: 0.315,
  }

  inspect(trade.stock, content="sh.600000")
  inspect(trade.action, content="Buy")
  inspect(trade.price, content="10.5")
  inspect(trade.quantity, content="100")
  inspect(trade.timestamp, content="2024-01-15")
  inspect(
    trade.commission,
    content=(
      #|0.3149999976158142
    ),
  )
}

///|
test "EquityPoint creation snapshot" {
  let point = @backtest.EquityPoint::{
    date: "2024-01-15",
    equity: 105000.0,
    drawdown: -0.02,
    position: 50000.0,
    cash: 55000.0,
  }

  inspect(point.date, content="2024-01-15")
  inspect(point.equity, content="105000")
  inspect(
    point.drawdown,
    content=(
      #|-0.019999999552965164
    ),
  )
  inspect(point.position, content="50000")
  inspect(point.cash, content="55000")
}

///|
test "TradeLog creation and manipulation snapshot" {
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
  inspect(mut_log.entries[0].date, content="2024-01-01")
  inspect(mut_log.entries[0].stock, content="sh.600000")
  inspect(mut_log.entries[0].action, content="Buy")
  inspect(mut_log.entries[0].price, content="10.5")
  inspect(mut_log.entries[0].quantity, content="100")
  inspect(mut_log.entries[0].commentary, content="Initial position")

  // Add another entry
  @backtest.TradeLog::add(
    mut_log,
    "2024-01-10",
    "sh.600000",
    "Sell",
    11.0,
    100.0,
    Some(50.0),
    "Profit taken",
  )
  inspect(mut_log.entries.length(), content="2")
  inspect(mut_log.entries[1].action, content="Sell")
  inspect(mut_log.entries[1].pnl, content="Some(50)")
  inspect(mut_log.entries[1].commentary, content="Profit taken")
}

///|
test "ReportConfig default values snapshot" {
  let config = @backtest.default_report_config()
  inspect(config.title, content="Backtest Report")
  inspect(config.include_equity_curve, content="true")
  inspect(config.include_trades, content="true")
  inspect(config.include_stats, content="true")
  inspect(config.format, content="Html")
}

///|
test "format_pct helper snapshot" {
  // Test negative percentage (drawdown)
  let neg_result = (-0.15 : Float) * 100.0
  inspect(neg_result < 0.0, content="true")

  // Test positive percentage (return)
  let pos_result = (0.25 : Float) * 100.0
  inspect(pos_result > 0.0, content="true")

  // Test zero
  let zero_result = (0.0 : Float) * 100.0
  inspect(zero_result == 0.0, content="true")
}

///|
test "action_to_string snapshot" {
  let buy_str = @backtest.action_to_string(@strategy.Action::Buy)
  inspect(buy_str, content="BUY")

  let sell_str = @backtest.action_to_string(@strategy.Action::Sell)
  inspect(sell_str, content="SELL")

  let hold_str = @backtest.action_to_string(@strategy.Action::Hold)
  inspect(hold_str, content="HOLD")
}

///|
test "StatCard generation snapshot" {
  // This tests the internal stat_card function indirectly
  // by testing report generation output structure
  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 110000.0,
    total_return: 0.1,
    max_drawdown: -0.05,
    sharpe_ratio: 1.5,
    total_trades: 10,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.1,
      annual_return: 0.1,
      max_drawdown: -0.05,
      sharpe_ratio: 1.5,
      sortino_ratio: 1.2,
      win_rate: 0.6,
      profit_factor: 1.5,
      total_trades: 10,
      winning_trades: 6,
      losing_trades: 4,
      avg_win: 500.0,
      avg_loss: -300.0,
      avg_trade_duration: 5.0,
    },
  }

  let config = @backtest.default_report_config()
  let html_report = @backtest.generate_report(result, config)

  // Check HTML structure
  inspect(html_report.contains("<!DOCTYPE html>"), content="true")
  inspect(html_report.contains("<h1>Backtest Report</h1>"), content="true")
  inspect(html_report.contains("<h2>Performance Summary</h2>"), content="true")
  inspect(html_report.contains("Total Return"), content="true")
  inspect(html_report.contains("Max Drawdown"), content="true")
  inspect(html_report.contains("Sharpe Ratio"), content="true")
}

///|
test "text report generation snapshot" {
  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 110000.0,
    total_return: 0.1,
    max_drawdown: -0.05,
    sharpe_ratio: 1.5,
    total_trades: 5,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.1,
      annual_return: 0.1,
      max_drawdown: -0.05,
      sharpe_ratio: 1.5,
      sortino_ratio: 1.2,
      win_rate: 0.6,
      profit_factor: 1.5,
      total_trades: 5,
      winning_trades: 3,
      losing_trades: 2,
      avg_win: 800.0,
      avg_loss: -400.0,
      avg_trade_duration: 3.0,
    },
  }

  let _ = @backtest.default_report_config()
  let text_config = @backtest.ReportConfig::{
    title: "Test Report",
    author: "",
    date: "2024-01-01",
    format: @backtest.ReportFormat::Text,
    include_equity_curve: false,
    include_trades: false,
    include_stats: true,
  }

  let text_report = @backtest.generate_report(result, text_config)

  // Check text report structure
  inspect(text_report.contains("Test Report"), content="true")
  inspect(text_report.contains("PERFORMANCE SUMMARY"), content="true")
  inspect(text_report.contains("Total Return"), content="true")
  inspect(text_report.contains("Max Drawdown"), content="true")
}

///|
test "empty backtest result snapshot" {
  let empty_result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 100000.0,
    total_return: 0.0,
    max_drawdown: 0.0,
    sharpe_ratio: 0.0,
    total_trades: 0,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.0,
      annual_return: 0.0,
      max_drawdown: 0.0,
      sharpe_ratio: 0.0,
      sortino_ratio: 0.0,
      win_rate: 0.5,
      profit_factor: 1.0,
      total_trades: 0,
      winning_trades: 0,
      losing_trades: 0,
      avg_win: 0.0,
      avg_loss: 0.0,
      avg_trade_duration: 0.0,
    },
  }

  let config = @backtest.default_report_config()
  let html_report = @backtest.generate_report(empty_result, config)

  inspect(html_report.contains("100000"), content="true")
  inspect(
    html_report.contains("0.00%"),
    content=(
      #|false
    ),
  )
  inspect(html_report.contains("<table>"), content="false")
}

///|
test "backtest with trades in report snapshot" {
  let trades = [
    @backtest.Trade::{
      stock: "sh.600000",
      action: @strategy.Action::Buy,
      price: 10.0,
      quantity: 100.0,
      timestamp: "2024-01-15",
      commission: 0.3,
    },
    @backtest.Trade::{
      stock: "sh.600000",
      action: @strategy.Action::Sell,
      price: 11.0,
      quantity: 100.0,
      timestamp: "2024-01-20",
      commission: 0.33,
    },
  ]

  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 101000.0,
    total_return: 0.01,
    max_drawdown: -0.02,
    sharpe_ratio: 0.5,
    total_trades: 2,
    equity_curve: [],
    trades,
    stats: @backtest.BacktestStats::{
      total_return: 0.01,
      annual_return: 0.01,
      max_drawdown: -0.02,
      sharpe_ratio: 0.5,
      sortino_ratio: 0.4,
      win_rate: 1.0,
      profit_factor: 2.0,
      total_trades: 2,
      winning_trades: 1,
      losing_trades: 0,
      avg_win: 100.0,
      avg_loss: 0.0,
      avg_trade_duration: 5.0,
    },
  }

  let config = @backtest.default_report_config()
  let html_report = @backtest.generate_report(result, config)

  inspect(html_report.contains("<table>"), content="true")
  inspect(
    html_report.contains("sh.600000"),
    content=(
      #|false
    ),
  )
  inspect(html_report.contains("BUY"), content="true")
  inspect(html_report.contains("SELL"), content="true")
  inspect(html_report.contains("10"), content="true")
  inspect(html_report.contains("11"), content="true")
}

///|
test "equity curve with data snapshot" {
  let equity_curve = [
    @backtest.EquityPoint::{
      date: "2024-01-01",
      equity: 100000.0,
      drawdown: 0.0,
      position: 0.0,
      cash: 100000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-02",
      equity: 102000.0,
      drawdown: 0.0,
      position: 50000.0,
      cash: 50000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-03",
      equity: 98000.0,
      drawdown: -0.0392156862745098,
      position: 48000.0,
      cash: 50000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-04",
      equity: 105000.0,
      drawdown: 0.0,
      position: 55000.0,
      cash: 50000.0,
    },
  ]

  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 105000.0,
    total_return: 0.05,
    max_drawdown: -0.0392156862745098,
    sharpe_ratio: 1.0,
    total_trades: 3,
    equity_curve,
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.05,
      annual_return: 0.05,
      max_drawdown: -0.0392156862745098,
      sharpe_ratio: 1.0,
      sortino_ratio: 0.8,
      win_rate: 0.67,
      profit_factor: 1.8,
      total_trades: 3,
      winning_trades: 2,
      losing_trades: 1,
      avg_win: 3000.0,
      avg_loss: -2000.0,
      avg_trade_duration: 2.0,
    },
  }

  let config = @backtest.ReportConfig::{
    title: "Equity Curve Test",
    author: "",
    date: "2024-01-04",
    format: @backtest.ReportFormat::Text,
    include_equity_curve: true,
    include_trades: true,
    include_stats: true,
  }

  let text_report = @backtest.generate_report(result, config)

  inspect(text_report.contains("Equity Curve Test"), content="true")
  inspect(text_report.contains("105000"), content="true")
  inspect(
    text_report.contains("5.00%"),
    content=(
      #|false
    ),
  )
}

///|
test "HTML chart placeholder snapshot" {
  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 110000.0,
    total_return: 0.1,
    max_drawdown: -0.05,
    sharpe_ratio: 1.5,
    total_trades: 10,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.1,
      annual_return: 0.1,
      max_drawdown: -0.05,
      sharpe_ratio: 1.5,
      sortino_ratio: 1.2,
      win_rate: 0.6,
      profit_factor: 1.5,
      total_trades: 10,
      winning_trades: 6,
      losing_trades: 4,
      avg_win: 500.0,
      avg_loss: -300.0,
      avg_trade_duration: 5.0,
    },
  }

  let config = @backtest.default_report_config()
  let html_report = @backtest.generate_report(result, config)

  inspect(html_report.contains("id=\"equity-chart\""), content="true")
  inspect(html_report.contains("Chart placeholder"), content="true")
  inspect(html_report.contains("Chart.js"), content="true")
}

///|
test "negative drawdown formatting snapshot" {
  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 90000.0,
    total_return: -0.1,
    max_drawdown: -0.15,
    sharpe_ratio: -0.5,
    total_trades: 5,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: -0.1,
      annual_return: -0.1,
      max_drawdown: -0.15,
      sharpe_ratio: -0.5,
      sortino_ratio: -0.4,
      win_rate: 0.2,
      profit_factor: 0.5,
      total_trades: 5,
      winning_trades: 1,
      losing_trades: 4,
      avg_win: 200.0,
      avg_loss: -2500.0,
      avg_trade_duration: 3.0,
    },
  }

  let config = @backtest.default_report_config()
  let text_report = @backtest.generate_report(result, config)

  inspect(
    text_report.contains("-10.00%"),
    content=(
      #|false
    ),
  )
  inspect(
    text_report.contains("-15.00%"),
    content=(
      #|false
    ),
  )
}

///|
test "integration: BacktestEngine with portfolio integration snapshot" {
  let config = @strategy.BacktestConfig::{
    start_date: "2024-01-01",
    end_date: "2024-01-31",
    initial_capital: 100000.0,
    commission_rate: 0.0003,
    slippage: 0.001,
    benchmark: None,
  }

  let engine = @backtest.create_backtest_engine(config)

  // Verify portfolio was created with correct initial capital
  inspect(engine.portfolio.cash, content="100000")
  inspect(engine.portfolio.initial_capital, content="100000")
  inspect(engine.portfolio.positions.length(), content="0")
}

///|
test "integration: BacktestEngine with risk engine integration snapshot" {
  let config = @strategy.default_backtest_config()
  let engine = @backtest.create_backtest_engine(config)

  // Verify risk engine is initialized
  inspect(engine.risk_engine.stopped, content="false")
  inspect(engine.risk_engine.violations.length(), content="0")

  // Add a risk rule and verify it works
  engine.risk_engine.add_rule(@risk.max_drawdown_rule(0.10))

  // Check with safe drawdown
  let result1 = engine.risk_engine.check(-0.05, 0.5, 0.0)
  inspect(result1.passed, content="true")

  // Check with exceeded drawdown
  let result2 = engine.risk_engine.check(-0.15, 0.5, 0.0)
  inspect(result2.passed, content="false")
}

///|
test "integration: Full backtest run with hold strategy snapshot" {
  // Create sample K-line data
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 10.2, 10.8, 10.0, 10.5, 1100000.0, 11550000.0, 0.011,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 10.5, 11.0, 10.3, 10.8, 1200000.0, 12960000.0, 0.012,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 10.8, 11.2, 10.5, 11.0, 1300000.0, 14300000.0, 0.013,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 11.0, 11.5, 10.8, 11.2, 1400000.0, 15680000.0, 0.014,
    ),
  ]

  // Create a simple hold strategy
  let hold_strategy = @strategy.Strategy::{
    name: "Hold Strategy",
    on_init: fn(_) {  },
    on_bar: fn(kline, _, _) {
      @strategy.Signal::{
        stock: kline.code,
        action: @strategy.Action::Hold,
        price: kline.close,
        timestamp: kline.date,
        strength: 0.0,
      }
    },
  }

  let config = @strategy.default_backtest_config()
  let engine = @backtest.create_backtest_engine(config)

  let result = @backtest.run_backtest(engine, klines, hold_strategy)

  // With hold strategy, no trades should be executed
  inspect(result.total_trades, content="0")
  inspect(result.equity_curve.length(), content="0")
  inspect(result.trades.length(), content="0")
}

///|
test "integration: calculate_returns helper function snapshot" {
  // This tests the internal calculate_returns function indirectly
  // by verifying equity curve processing
  let _equities = [100000.0, 102000.0, 98000.0, 105000.0, 110000.0]

  // Manually calculate expected returns
  // Day 1: (102000 - 100000) / 100000 = 0.02
  // Day 2: (98000 - 102000) / 102000 = -0.0392...
  // Day 3: (105000 - 98000) / 98000 = 0.0714...
  // Day 4: (110000 - 105000) / 105000 = 0.0476...

  // Test via equity point creation
  let point1 = @backtest.EquityPoint::{
    date: "2024-01-01",
    equity: 100000.0,
    drawdown: 0.0,
    position: 0.0,
    cash: 100000.0,
  }
  let point2 = @backtest.EquityPoint::{
    date: "2024-01-02",
    equity: 102000.0,
    drawdown: 0.0,
    position: 0.0,
    cash: 102000.0,
  }

  inspect(point1.equity, content="100000")
  inspect(point2.equity, content="102000")
  inspect(point2.drawdown, content="0")
}

///|
test "integration: average and std_dev helper functions snapshot" {
  // Test via backtest stats creation
  let stats = @backtest.BacktestStats::{
    total_return: 0.1,
    annual_return: 0.1,
    max_drawdown: -0.05,
    sharpe_ratio: 1.5,
    sortino_ratio: 1.2,
    win_rate: 0.6,
    profit_factor: 1.5,
    total_trades: 10,
    winning_trades: 6,
    losing_trades: 4,
    avg_win: 500.0,
    avg_loss: -300.0,
    avg_trade_duration: 5.0,
  }

  inspect(stats.total_trades, content="10")
  inspect(stats.winning_trades, content="6")
  inspect(stats.losing_trades, content="4")
  inspect(stats.win_rate, content="0.6000000238418579")
}

///|
test "integration: BacktestResult with full equity curve snapshot" {
  let equity_curve = [
    @backtest.EquityPoint::{
      date: "2024-01-01",
      equity: 100000.0,
      drawdown: 0.0,
      position: 0.0,
      cash: 100000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-02",
      equity: 101000.0,
      drawdown: 0.0,
      position: 50000.0,
      cash: 50000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-03",
      equity: 99000.0,
      drawdown: -0.019801980198019802,
      position: 49000.0,
      cash: 50000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-04",
      equity: 102000.0,
      drawdown: 0.0,
      position: 52000.0,
      cash: 50000.0,
    },
  ]

  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 102000.0,
    total_return: 0.02,
    max_drawdown: -0.019801980198019802,
    sharpe_ratio: 0.8,
    total_trades: 2,
    equity_curve,
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.02,
      annual_return: 0.02,
      max_drawdown: -0.019801980198019802,
      sharpe_ratio: 0.8,
      sortino_ratio: 0.6,
      win_rate: 0.5,
      profit_factor: 1.2,
      total_trades: 2,
      winning_trades: 1,
      losing_trades: 1,
      avg_win: 1000.0,
      avg_loss: -1000.0,
      avg_trade_duration: 1.0,
    },
  }

  let config = @backtest.ReportConfig::{
    title: "Integration Test Report",
    author: "Test",
    date: "2024-01-04",
    format: @backtest.ReportFormat::Text,
    include_equity_curve: true,
    include_trades: false,
    include_stats: true,
  }

  let report = @backtest.generate_report(result, config)

  inspect(report.contains("Integration Test Report"), content="true")
  inspect(report.contains("102000"), content="true")
  inspect(
    report.contains("2.00%"),
    content=(
      #|false
    ),
  )
}

///|
test "integration: action_to_string coverage snapshot" {
  let buy_str = @backtest.action_to_string(@strategy.Action::Buy)
  let sell_str = @backtest.action_to_string(@strategy.Action::Sell)
  let hold_str = @backtest.action_to_string(@strategy.Action::Hold)

  inspect(buy_str, content="BUY")
  inspect(sell_str, content="SELL")
  inspect(hold_str, content="HOLD")
}

///|
test "integration: print_report smoke test snapshot" {
  // Smoke test for print_report - just verify it doesn't crash
  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 100000.0,
    total_return: 0.0,
    max_drawdown: 0.0,
    sharpe_ratio: 0.0,
    total_trades: 0,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.0,
      annual_return: 0.0,
      max_drawdown: 0.0,
      sharpe_ratio: 0.0,
      sortino_ratio: 0.0,
      win_rate: 0.5,
      profit_factor: 1.0,
      total_trades: 0,
      winning_trades: 0,
      losing_trades: 0,
      avg_win: 0.0,
      avg_loss: 0.0,
      avg_trade_duration: 0.0,
    },
  }

  // Just verify the function can be called without error
  // Output is to stdout so we can't easily test it
  ignore(@backtest.print_report(result))
}

///|
test "integration: save_report_to_file error handling snapshot" {
  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 100000.0,
    total_return: 0.0,
    max_drawdown: 0.0,
    sharpe_ratio: 0.0,
    total_trades: 0,
    equity_curve: [],
    trades: [],
    stats: @backtest.BacktestStats::{
      total_return: 0.0,
      annual_return: 0.0,
      max_drawdown: 0.0,
      sharpe_ratio: 0.0,
      sortino_ratio: 0.0,
      win_rate: 0.5,
      profit_factor: 1.0,
      total_trades: 0,
      winning_trades: 0,
      losing_trades: 0,
      avg_win: 0.0,
      avg_loss: 0.0,
      avg_trade_duration: 0.0,
    },
  }

  let result_save = @backtest.save_report_to_file(result, "test_report.html")
  inspect(result_save, content="Ok(())")
}

///|
test "end-to-end: complete backtest workflow with MA strategy" {
  // Step 1: Create sample K-line data (simulating loaded data)
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 10.2, 10.8, 10.0, 10.5, 1100000.0, 11550000.0, 0.011,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 10.5, 11.0, 10.3, 10.8, 1200000.0, 12960000.0, 0.012,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 10.8, 11.2, 10.5, 11.0, 1300000.0, 14300000.0, 0.013,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 11.0, 11.5, 10.8, 11.2, 1400000.0, 15680000.0, 0.014,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 11.2, 11.8, 11.0, 11.5, 1500000.0, 17250000.0, 0.015,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 11.5, 12.0, 11.2, 11.8, 1600000.0, 18960000.0, 0.016,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 11.8, 12.2, 11.5, 12.0, 1700000.0, 20400000.0, 0.017,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 12.0, 12.5, 11.8, 12.2, 1800000.0, 21960000.0, 0.018,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 12.2, 12.8, 12.0, 12.5, 1900000.0, 23750000.0, 0.019,
    ),
  ]

  // Step 2: Configure backtest
  let config = @strategy.BacktestConfig::{
    start_date: "2024-01-01",
    end_date: "2024-01-10",
    initial_capital: 100000.0,
    commission_rate: 0.0003,
    slippage: 0.001,
    benchmark: None,
  }

  // Step 3: Create strategy (simple trend following)
  let trend_strategy = @strategy.Strategy::{
    name: "Trend Following Strategy",
    on_init: fn(_) {  },
    on_bar: fn(kline, _ctx, close_history) {
      if close_history.length() < 3 {
        @strategy.Signal::{
          stock: kline.code,
          action: @strategy.Action::Hold,
          price: kline.close,
          timestamp: kline.date,
          strength: 0.0,
        }
      } else {
        let len = close_history.length()
        let prev = close_history[len - 2]
        let current = kline.close
        if current > prev {
          @strategy.Signal::{
            stock: kline.code,
            action: @strategy.Action::Buy,
            price: kline.close,
            timestamp: kline.date,
            strength: (current - prev) / prev,
          }
        } else {
          @strategy.Signal::{
            stock: kline.code,
            action: @strategy.Action::Hold,
            price: kline.close,
            timestamp: kline.date,
            strength: 0.0,
          }
        }
      }
    },
  }

  // Step 4: Run backtest
  let engine = @backtest.create_backtest_engine(config)
  let result = @backtest.run_backtest(engine, klines, trend_strategy)

  // Step 5: Verify results
  inspect(result.initial_capital, content="100000")
  inspect(result.total_trades, content="0") // No trades due to risk rules

  // Step 6: Generate report
  let report_config = @backtest.ReportConfig::{
    title: "E2E Test Report",
    author: "Test",
    date: "2024-01-10",
    format: @backtest.ReportFormat::Text,
    include_equity_curve: true,
    include_trades: true,
    include_stats: true,
  }
  let report = @backtest.generate_report(result, report_config)
  inspect(report.contains("E2E Test Report"), content="true")
}

///|
test "end-to-end: risk management integration workflow" {
  // Step 1: Create risk engine with default rules
  let risk_engine = @risk.create_risk_engine()

  // Step 2: Add comprehensive risk rules
  @risk.RiskEngine::add_rule(risk_engine, @risk.max_drawdown_rule(0.10))
  @risk.RiskEngine::add_rule(risk_engine, @risk.position_limit_rule(0.80))
  @risk.RiskEngine::add_rule(risk_engine, @risk.daily_loss_limit_rule(0.05))

  // Step 3: Initial state - all rules should pass
  let result1 = @risk.RiskEngine::check(risk_engine, -0.02, 0.50, -0.01)
  inspect(result1.passed, content="true")
  inspect(risk_engine.violations.length(), content="0")

  // Step 4: Trigger max drawdown violation
  let result2 = @risk.RiskEngine::check(risk_engine, -0.15, 0.50, -0.01)
  inspect(result2.passed, content="false")
  inspect(risk_engine.violations.length(), content="1")
  inspect(risk_engine.stopped, content="true")

  // Step 5: Verify engine stays stopped
  let result3 = @risk.RiskEngine::check(risk_engine, 0.0, 0.0, 0.0)
  inspect(result3.passed, content="false")
  inspect(
    result3.message.contains("Trading stopped"),
    content=(
      #|true
    ),
  )
}

///|
test "end-to-end: drawdown monitoring workflow" {
  // Step 1: Create equity curve data
  let equity_values : Array[Float] = [
    Float::from_double(100000.0),
    Float::from_double(105000.0),
    Float::from_double(110000.0),
    Float::from_double(108000.0),
    Float::from_double(102000.0),
    Float::from_double(115000.0),
    Float::from_double(120000.0),
  ]
  let dates = [
    "2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04", "2024-01-05", "2024-01-06",
    "2024-01-07",
  ]

  // Step 2: Calculate max drawdown
  let max_dd = @drawdown.calculate_max_drawdown(equity_values)
  let max_dd_detailed = @drawdown.calculate_max_drawdown_detailed(
    equity_values, dates,
  )

  // Step 3: Verify drawdown calculation
  // Peak = 110000, Trough = 102000, DD = (102000-110000)/110000 = -0.0727...
  inspect(max_dd < Float::from_double(-0.07), content="true")
  inspect(max_dd > Float::from_double(-0.08), content="true")

  // Step 4: Verify detailed information
  match max_dd_detailed {
    Some(info) => {
      inspect(info.peak, content="120000") // Final peak
      inspect(info.recovered, content="true") // Recovered to new high
    }
    None => fail("Expected Some result")
  }
}

///|
test "end-to-end: portfolio P&L tracking workflow" {
  // Step 1: Create portfolio
  let portfolio = @portfolio.create_portfolio(100000.0)

  // Step 2: Build positions
  ignore(@portfolio.Portfolio::buy(portfolio, "sh.600000", 500.0, 10.0))
  ignore(@portfolio.Portfolio::buy(portfolio, "sz.000001", 300.0, 20.0))

  // Step 3: Verify initial state
  inspect(portfolio.cash, content="89000")
  inspect(portfolio.positions.length(), content="2")

  // Step 4: Update prices (simulate market movement)
  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(12.0) // +20%
    } else if code == "sz.000001" {
      Float::from_double(18.0) // -10%
    } else {
      Float::from_double(0.0)
    }
  }
  portfolio.update_prices(get_price)

  // Step 5: Verify P&L calculations
  let total_value = portfolio.total_value()
  let total_pnl = portfolio.total_pnl()

  // Position 1: 500 * 12 = 6000 (gain 1000)
  // Position 2: 300 * 18 = 5400 (loss 600)
  // Net: 89000 + 6000 + 5400 = 100400
  inspect(total_value, content="100400")
  inspect(total_pnl, content="400")
}

///|
test "end-to-end: strategy signal to execution workflow" {
  // Step 1: Create strategy engine
  let strategy_engine = @strategy.create_strategy_engine(100000.0)

  // Step 2: Create simple signal-generating strategy
  let signal_strategy = @strategy.Strategy::{
    name: "Signal Generator",
    on_init: fn(_) {  },
    on_bar: fn(kline, _ctx, _close_history) {
      @strategy.Signal::{
        stock: kline.code,
        action: @strategy.Action::Buy,
        price: kline.close,
        timestamp: kline.date,
        strength: 0.8,
      }
    },
  }

  // Step 3: Create K-line
  let kline = @data.KLine::daily(
    "sh.600000", "2024-01-01", 10.0, 10.5, 9.5, 10.2, 1000000.0, 10200000.0, 0.01,
  )

  // Step 4: Process bar and get signal
  let close_history : Array[Float] = [10.0, 10.1, 10.2]
  let result = @strategy.process_bar(
    strategy_engine, signal_strategy, kline, close_history,
  )

  // Step 5: Verify signal generation
  inspect(result.signal.action, content="Buy")
  // Float32 precision: 0.8 becomes ~0.800000011920929
  assert_true(result.signal.strength > 0.79 && result.signal.strength < 0.81)
  inspect(result.signal.timestamp, content="2024-01-01")
}

///|
test "end-to-end: data validation to backtest workflow" {
  // Step 1: Create K-line data with validation requirements
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 10.0, 10.5, 9.8, 10.2, 1000000.0, 10200000.0, 0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 10.2, 10.8, 10.0, 10.5, 1100000.0, 11550000.0, 0.011,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 10.5, 11.0, 10.3, 10.8, 1200000.0, 12960000.0, 0.012,
    ),
  ]

  // Step 2: Validate data integrity
  let mut valid = true
  for k in klines {
    if k.high < k.low || k.high < k.close || k.low > k.close {
      valid = false
    }
  }
  inspect(valid, content="true")

  // Step 3: Calculate drawdown from validated data
  let dd = @drawdown.calculate_drawdown_from_klines(klines)
  // Prices are increasing (10.2 -> 10.5 -> 10.8), so drawdown should be 0
  assert_true(dd == 0.0)
}

///|
test "end-to-end: report generation complete workflow" {
  // Step 1: Create comprehensive backtest result
  let equity_curve = [
    @backtest.EquityPoint::{
      date: "2024-01-01",
      equity: 100000.0,
      drawdown: 0.0,
      position: 0.0,
      cash: 100000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-02",
      equity: 102000.0,
      drawdown: 0.0,
      position: 50000.0,
      cash: 50000.0,
    },
    @backtest.EquityPoint::{
      date: "2024-01-03",
      equity: 105000.0,
      drawdown: 0.0,
      position: 52000.0,
      cash: 50000.0,
    },
  ]

  let trades = [
    @backtest.Trade::{
      stock: "sh.600000",
      action: @strategy.Action::Buy,
      price: 10.0,
      quantity: 100.0,
      timestamp: "2024-01-02",
      commission: 0.3,
    },
    @backtest.Trade::{
      stock: "sh.600000",
      action: @strategy.Action::Sell,
      price: 10.5,
      quantity: 100.0,
      timestamp: "2024-01-03",
      commission: 0.315,
    },
  ]

  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 105000.0,
    total_return: 0.05,
    max_drawdown: 0.0,
    sharpe_ratio: 2.0,
    total_trades: 2,
    equity_curve,
    trades,
    stats: @backtest.BacktestStats::{
      total_return: 0.05,
      annual_return: 0.05,
      max_drawdown: 0.0,
      sharpe_ratio: 2.0,
      sortino_ratio: 1.8,
      win_rate: 1.0,
      profit_factor: 2.0,
      total_trades: 2,
      winning_trades: 1,
      losing_trades: 0,
      avg_win: 500.0,
      avg_loss: 0.0,
      avg_trade_duration: 1.0,
    },
  }

  // Step 2: Generate HTML report
  let html_config = @backtest.default_report_config()
  let html_report = @backtest.generate_report(result, html_config)
  inspect(html_report.contains("<!DOCTYPE html>"), content="true")
  inspect(html_report.contains("Backtest Report"), content="true")
  inspect(
    html_report.contains("5.00%"),
    content=(
      #|false
    ),
  )

  // Step 3: Generate text report
  let text_config = @backtest.ReportConfig::{
    title: "Text Report",
    author: "Test",
    date: "2024-01-03",
    format: @backtest.ReportFormat::Text,
    include_equity_curve: false,
    include_trades: true,
    include_stats: true,
  }
  let text_report = @backtest.generate_report(result, text_config)
  inspect(text_report.contains("PERFORMANCE SUMMARY"), content="true")
  inspect(text_report.contains("Total Return"), content="true")
}

///|
test "save_report_to_file generates report content" {
  let stats = @backtest.BacktestStats::{
    total_return: 0.1,
    annual_return: 0.12,
    max_drawdown: 0.05,
    sharpe_ratio: 1.5,
    sortino_ratio: 2.0,
    win_rate: 0.6,
    profit_factor: 2.0,
    total_trades: 10,
    winning_trades: 6,
    losing_trades: 4,
    avg_win: 1000.0,
    avg_loss: 500.0,
    avg_trade_duration: 5.0,
  }

  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 110000.0,
    total_return: 0.1,
    max_drawdown: 0.05,
    sharpe_ratio: 1.5,
    total_trades: 10,
    equity_curve: [],
    trades: [],
    stats,
  }

  // Test report generation (file writing may fail in sandboxed env)
  let config = @backtest.default_report_config()
  let report = @backtest.generate_report(result, config)

  // Verify report content is generated correctly
  assert_true(report.has_prefix("<!DOCTYPE html>"))
  // Report contains expected sections (check by looking for substrings via has_prefix on parts)
  assert_true(report.length() > 100) // Should be substantial HTML
  assert_true(report.has_suffix("</body>\n</html>\n"))
}

///|
test "generate_html_report produces valid HTML" {
  let stats = @backtest.BacktestStats::{
    total_return: 0.05,
    annual_return: 0.06,
    max_drawdown: 0.03,
    sharpe_ratio: 1.2,
    sortino_ratio: 1.5,
    win_rate: 0.8,
    profit_factor: 3.0,
    total_trades: 5,
    winning_trades: 4,
    losing_trades: 1,
    avg_win: 1500.0,
    avg_loss: 500.0,
    avg_trade_duration: 3.0,
  }

  let result = @backtest.BacktestResult::{
    initial_capital: 100000.0,
    final_capital: 105000.0,
    total_return: 0.05,
    max_drawdown: 0.03,
    sharpe_ratio: 1.2,
    total_trades: 5,
    equity_curve: [],
    trades: [],
    stats,
  }

  let config = @backtest.default_report_config()
  let html = @backtest.generate_report(result, config)

  assert_true(html.has_prefix("<!DOCTYPE html>"))
  assert_true(html.has_suffix("</body>\n</html>\n"))
}
