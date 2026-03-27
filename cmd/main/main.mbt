///|
/// Main entry point for the quantitative drawdown CLI
using @cmd/main/handlers {
  _run_analyze,
  _run_backtest,
  _run_monitor,
  _run_report,
  _run_serve,
  print_help,
  _print_strategies,
}

///|
using @cmd/main/parsers {type Command, _get_env_command}

///|
/// Execute command
fn _execute_command(cmd : Command) -> Unit {
  match cmd {
    Command::Help => print_help()
    Command::Analyze(stock, metric) => _run_analyze(stock, metric)
    Command::Backtest(strategy, stock, start, end) =>
      _run_backtest(strategy, stock, start, end)
    Command::Monitor(stock) => _run_monitor(stock)
    Command::Report(format) => _run_report(format)
    Command::ListStrategies => _print_strategies()
    Command::Serve(port) => _run_serve(port)
  }
}

///|
/// Main entry point
fn main {
  let cmd = _get_env_command()
  _execute_command(cmd)
}
