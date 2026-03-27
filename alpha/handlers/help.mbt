/// Handler for help command and strategy listing

///|
/// Print help message
pub fn print_help() -> Unit {
  println("moonbit-drawdown - Quantitative Drawdown Analysis Tool")
  println("")
  println("USAGE:")
  println("    MOONBIT_CMD=<command> MOONBIT_ARGS=\"<args>\" moon run cmd/main")
  println("")
  println("COMMANDS:")
  println("    analyze           Analyze stock/portfolio drawdown")
  println("    backtest          Run strategy backtest on historical data")
  println("    monitor           Real-time drawdown monitoring mode")
  println("    report            Generate backtest/analysis report")
  println("    list-strategies   List all available trading strategies")
  println("    serve             Start HTTP API server")
  println("    help              Show this help message")
  println("")
  println("USAGE:")
  println("    MOONBIT_CMD=<command> MOONBIT_ARGS=\"<args>\" moon run cmd/main")
  println("")
  println("OPTIONS:")
  println("    --stock <code>     Stock code (e.g., sh.600000)")
  println("    --strategy <name>  Strategy name (e.g., ma_cross, momentum)")
  println("    --start <date>     Start date (YYYY-MM-DD)")
  println("    --end <date>       End date (YYYY-MM-DD)")
  println("    --metric <name>    Metric to analyze (e.g., max_drawdown)")
  println("    --format <fmt>     Report format (text, html, json)")
  println("    --port <number>    Server port (default: 8080)")
  println("")
  println("EXAMPLES:")
  println(
    "    MOONBIT_CMD=analyze MOONBIT_ARGS=\"--stock sh.600000 --metric max_drawdown\" moon run cmd/main",
  )
  println(
    "    MOONBIT_CMD=backtest MOONBIT_ARGS=\"--strategy ma_cross --stock sh.600000 --start 2024-01-01 --end 2024-12-31\" moon run cmd/main",
  )
  println(
    "    MOONBIT_CMD=monitor MOONBIT_ARGS=\"--stock sh.600000\" moon run cmd/main",
  )
  println(
    "    MOONBIT_CMD=report MOONBIT_ARGS=\"--format html\" moon run cmd/main",
  )
  println("    MOONBIT_CMD=list-strategies moon run cmd/main")
  println(
    "    MOONBIT_CMD=serve MOONBIT_ARGS=\"--port 8080\" moon run cmd/main",
  )
  println("")
  println("ENVIRONMENT VARIABLES:")
  println(
    "    MOONBIT_CMD  - Command name (analyze, backtest, monitor, report, list-strategies, serve)",
  )
  println("    MOONBIT_ARGS - Space-separated command arguments")
  println("")
  println("FULL EXAMPLES:")
  println(
    "    MOONBIT_CMD=analyze MOONBIT_ARGS=\"--stock sh.600000\" moon run cmd/main",
  )
  println(
    "    MOONBIT_CMD=backtest MOONBIT_ARGS=\"--strategy ma_cross --stock sh.600000\" moon run cmd/main",
  )
  println(
    "    MOONBIT_CMD=report MOONBIT_ARGS=\"--format html\" moon run cmd/main",
  )
}

///|
/// Print available strategies
pub fn _print_strategies() -> Unit {
  println("Available Strategies:")
  println("")
  println("  1. ma_cross")
  println("     Moving Average Crossover Strategy")
  println("     - Generates signals when fast MA crosses slow MA")
  println("     - Parameters: fast_period, slow_period")
  println("     - Best for: trending markets")
  println("")
  println("  2. momentum")
  println("     Momentum-based trading strategy")
  println("     - Uses rate of change and historical patterns")
  println("     - Parameters: lookback_period, threshold")
  println("     - Best for: mean reversion markets")
  println("")
  println("  3. rsi_mean_reversion")
  println("     RSI-based mean reversion strategy")
  println("     - Trades when RSI reaches extreme levels")
  println("     - Parameters: rsi_period, oversold, overbought")
  println("     - Best for: range-bound markets")
  println("")
  println("Use --strategy <name> to select a strategy for backtest")
  println("Use moon run cmd/main backtest --help for more details")
}
