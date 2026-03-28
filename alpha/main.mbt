///|
/// Main entry point for the quantitative drawdown CLI
using @alpha/handlers {_run_analyze, _run_backtest, _run_serve, print_help}

///|
using @alpha/parsers {type Command, _get_env_command}

///|
/// Execute command
fn _execute_command(cmd : Command) -> Unit {
  match cmd {
    Command::Help => print_help()
    Command::Analyze(stock, metric) => _run_analyze(stock, metric)
    Command::Backtest(strategy, stock, start, end) =>
      _run_backtest(strategy, stock, start, end)
    Command::Serve(port) => _run_serve(port)
  }
}

///|
/// Main entry point
fn main {
  let cmd = _get_env_command()
  _execute_command(cmd)
}
