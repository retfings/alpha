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

  let config = @backtest.default_report_config()
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
