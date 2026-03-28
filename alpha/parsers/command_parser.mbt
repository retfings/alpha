/// Command argument parsers

///|
/// Parse space-separated arguments into Array[String]
fn _parse_env_args(args_str : String) -> Array[String] {
  args_str
  .split(" ")
  .filter(fn(s) { s != "" })
  .map(fn(s) { s.to_string() })
  .to_array()
}

///|
/// CLI Commands
pub enum Command {
  Help
  Analyze(String, String) // stock, metric
  Backtest(String, String, String, String) // strategy, stock, start, end
  Serve(Int) // port
}

///|
/// Parse command line arguments
pub fn _parse_args(args : Array[String]) -> Command {
  if args.length() == 0 {
    return Command::Help
  }

  match args[0] {
    "help" => Command::Help
    "analyze" => _parse_analyze_args(args)
    "backtest" => _parse_backtest_args(args)
    "serve" => _parse_serve_args(args)
    _ => Command::Help
  }
}

///|
pub fn _parse_analyze_args(args : Array[String]) -> Command {
  let mut stock = ""
  let mut metric = "max_drawdown"

  let mut i = 1
  while i < args.length() {
    if args[i] == "--stock" && i + 1 < args.length() {
      stock = args[i + 1]
      i = i + 2
    } else if args[i] == "--metric" && i + 1 < args.length() {
      metric = args[i + 1]
      i = i + 2
    } else {
      i = i + 1
    }
  }

  Command::Analyze(stock, metric)
}

///|
pub fn _parse_backtest_args(args : Array[String]) -> Command {
  let mut strategy = "ma_cross"
  let mut stock = ""
  let mut start = ""
  let mut end = ""

  let mut i = 1
  while i < args.length() {
    if args[i] == "--strategy" && i + 1 < args.length() {
      strategy = args[i + 1]
      i = i + 2
    } else if args[i] == "--stock" && i + 1 < args.length() {
      stock = args[i + 1]
      i = i + 2
    } else if args[i] == "--start" && i + 1 < args.length() {
      start = args[i + 1]
      i = i + 2
    } else if args[i] == "--end" && i + 1 < args.length() {
      end = args[i + 1]
      i = i + 2
    } else {
      i = i + 1
    }
  }

  Command::Backtest(strategy, stock, start, end)
}

///|
pub fn _parse_serve_args(args : Array[String]) -> Command {
  let mut port : Int = 8080

  let mut i = 1
  while i < args.length() {
    if args[i] == "--port" && i + 1 < args.length() {
      port = @strconv.parse_int(args[i + 1]) catch { _ => 8080 }
      i = i + 2
    } else {
      i = i + 1
    }
  }

  Command::Serve(port)
}

///|
/// Get command from environment variables
/// MOONBIT_CMD = command name (analyze, backtest, monitor, report, serve, help)
/// MOONBIT_ARGS = space-separated arguments
pub fn _get_env_command() -> Command {
  match @ffi.getenv("MOONBIT_CMD") {
    None => Command::Help
    Some(cmd) => {
      let args_str = @ffi.getenv("MOONBIT_ARGS").unwrap_or("")
      let args = _parse_env_args(args_str)
      _parse_args([cmd] + args)
    }
  }
}
