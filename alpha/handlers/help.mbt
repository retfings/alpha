/// Handler for help command

///|
/// Print help message
pub fn print_help() -> Unit {
  println("moonbit-drawdown - Quantitative Drawdown Analysis Tool")
  println("")
  println("USAGE:")
  println("    MOONBIT_CMD=<command> MOONBIT_ARGS=\"<args>\" moon run alpha")
  println("")
  println("COMMANDS:")
  println("    analyze    Analyze stock/portfolio drawdown")
  println("    backtest   Run strategy backtest on historical data")
  println("    serve      Start HTTP API server")
  println("    help       Show this help message")
  println("")
  println("OPTIONS:")
  println("    --stock <code>     Stock code (e.g., sh.600000)")
  println("    --strategy <name>  Strategy name (e.g., ma_cross, momentum)")
  println("    --start <date>     Start date (YYYY-MM-DD)")
  println("    --end <date>       End date (YYYY-MM-DD)")
  println("    --metric <name>    Metric to analyze (e.g., max_drawdown)")
  println("    --port <number>    Server port (default: 8080)")
  println("")
  println("EXAMPLES:")
  println(
    "    MOONBIT_CMD=analyze MOONBIT_ARGS=\"--stock sh.600000 --metric max_drawdown\" moon run alpha",
  )
  println(
    "    MOONBIT_CMD=backtest MOONBIT_ARGS=\"--strategy ma_cross --stock sh.600000 --start 2026-01-01 --end 2026-03-28\" moon run alpha",
  )
  println("    MOONBIT_CMD=serve MOONBIT_ARGS=\"--port 8080\" moon run alpha")
  println("")
  println("ENVIRONMENT VARIABLES:")
  println("    MOONBIT_CMD  - Command name (analyze, backtest, serve)")
  println("    MOONBIT_ARGS - Space-separated command arguments")
  println("")
  println("FULL EXAMPLES:")
  println(
    "    MOONBIT_CMD=analyze MOONBIT_ARGS=\"--stock sh.600000\" moon run alpha",
  )
  println(
    "    MOONBIT_CMD=backtest MOONBIT_ARGS=\"--strategy ma_cross --stock sh.600000\" moon run alpha",
  )
}
