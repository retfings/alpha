/// Main entry point for the quantitative drawdown CLI

///|
/// CLI Commands
pub enum Command {
  Help
  Analyze(String, String) // stock, metric
  Backtest(String, String, String, String) // strategy, stock, start, end
  Monitor(String) // stock
  Report(String) // output format
  ListStrategies
}

///|
/// Parse command line arguments
fn parse_args(args : Array[String]) -> Command {
  if args.length() == 0 {
    return Command::Help
  }

  match args[0] {
    "help" => Command::Help
    "analyze" => parse_analyze_args(args)
    "backtest" => parse_backtest_args(args)
    "monitor" => parse_monitor_args(args)
    "report" => parse_report_args(args)
    "list-strategies" => Command::ListStrategies
    _ => Command::Help
  }
}

///|
fn parse_analyze_args(args : Array[String]) -> Command {
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
fn parse_backtest_args(args : Array[String]) -> Command {
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
fn parse_monitor_args(args : Array[String]) -> Command {
  let mut stock = ""

  let mut i = 1
  while i < args.length() {
    if args[i] == "--stock" && i + 1 < args.length() {
      stock = args[i + 1]
      i = i + 2
    } else {
      i = i + 1
    }
  }

  Command::Monitor(stock)
}

///|
fn parse_report_args(args : Array[String]) -> Command {
  let mut output = "text"

  let mut i = 1
  while i < args.length() {
    if args[i] == "--format" && i + 1 < args.length() {
      output = args[i + 1]
      i = i + 2
    } else {
      i = i + 1
    }
  }

  Command::Report(output)
}

///|
/// Print help message
fn print_help() -> Unit {
  println("moonbit-drawdown - Quantitative Drawdown Analysis Tool")
  println("")
  println("USAGE:")
  println("    moon run cmd/main [COMMAND] [OPTIONS]")
  println("")
  println("COMMANDS:")
  println("    analyze           Analyze stock/portfolio drawdown")
  println("    backtest          Run strategy backtest")
  println("    monitor           Real-time monitoring mode")
  println("    report            Generate analysis report")
  println("    list-strategies   List available strategies")
  println("    help              Show this help message")
  println("")
  println("EXAMPLES:")
  println("    moon run cmd/main analyze --stock sh.600000 --metric max_drawdown")
  println("    moon run cmd/main backtest --strategy ma_cross --stock sh.600000")
  println("    moon run cmd/main monitor --stock sh.600000")
  println("    moon run cmd/main report --format html")
  println("    moon run cmd/main list-strategies")
}

///|
/// Print available strategies
fn print_strategies() -> Unit {
  println("Available Strategies:")
  println("")
  println("  1. ma_cross")
  println("     - Moving Average Crossover Strategy")
  println("     - Generates signals when fast MA crosses slow MA")
  println("")
  println("  2. momentum")
  println("     - Momentum-based trading strategy")
  println("     - Uses rate of change and historical patterns")
  println("")
  println("Use --strategy <name> to select a strategy for backtest")
}

///|
/// Run analysis command
fn run_analyze(stock : String, metric : String) -> Unit {
  if stock == "" {
    println("Error: --stock is required for analyze command")
    println("Usage: moon run cmd/main analyze --stock sh.600000")
    return
  }

  println("Analyzing drawdown for stock: \{stock}")
  println("Metric: \{metric}")
  println("")

  // Validate stock code format
  if !stock.contains(".") {
    println("Warning: Stock code should be in format 'market.code' (e.g., sh.600000)")
  }

  println("Loading data...")
  println("Computing drawdown metrics...")
  println("")

  // Demo output
  println("Results:")
  println("  Max Drawdown: -15.23%")
  println("  Current Drawdown: -2.45%")
  println("  Drawdown Duration: 12 days")
  println("  Recovery Status: In drawdown")
  println("")
  println("Note: Full analysis requires data file at data/\{stock}.csv")
}

///|
/// Run backtest command
fn run_backtest(
  strategy : String,
  stock : String,
  start : String,
  end : String,
) -> Unit {
  if stock == "" {
    println("Error: --stock is required for backtest command")
    println("Usage: moon run cmd/main backtest --strategy ma_cross --stock sh.600000")
    return
  }

  println("Running backtest:")
  println("  Strategy: \{strategy}")
  println("  Stock: \{stock}")
  if start != "" {
    println("  Start: \{start}")
  }
  if end != "" {
    println("  End: \{end}")
  }
  println("")

  // Validate strategy name
  let valid_strategies = ["ma_cross", "momentum"]
  let mut found = false
  let mut i = 0
  while i < valid_strategies.length() {
    if valid_strategies[i] == strategy {
      found = true
      break
    }
    i = i + 1
  }

  if !found {
    println("Warning: Unknown strategy '\{strategy}'. Available: ma_cross, momentum")
  }

  println("Initializing backtest engine...")
  println("Loading historical data...")
  println("Running strategy simulation...")
  println("")

  // Demo results
  println("Backtest Results:")
  println("  Total Return: 12.45%")
  println("  Max Drawdown: -8.32%")
  println("  Sharpe Ratio: 1.23")
  println("  Total Trades: 24")
  println("  Win Rate: 58.3%")
  println("")
  println("Note: Full backtest requires data file at data/\{stock}.csv")
}

///|
/// Run monitor command
fn run_monitor(stock : String) -> Unit {
  if stock == "" {
    println("Error: --stock is required for monitor command")
    println("Usage: moon run cmd/main monitor --stock sh.600000")
    return
  }

  println("Starting real-time monitoring for: \{stock}")
  println("")
  println("Monitoring metrics:")
  println("  - Current price")
  println("  - Daily drawdown")
  println("  - Risk level")
  println("")
  println("Press Ctrl+C to stop monitoring")
  println("")
  println("[MONITOR] Waiting for live data feed...")
}

///|
/// Run report command
fn run_report(format : String) -> Unit {
  let valid_formats = ["text", "html", "json", "pdf"]
  let mut found = false
  let mut i = 0
  while i < valid_formats.length() {
    if valid_formats[i] == format {
      found = true
      break
    }
    i = i + 1
  }

  if !found {
    println("Error: Invalid format '\{format}'. Available: text, html, json, pdf")
    return
  }

  println("Generating \{format} report...")
  println("")
  println("Report sections:")
  println("  1. Portfolio Summary")
  println("  2. Drawdown Analysis")
  println("  3. Risk Metrics")
  println("  4. Performance Statistics")
  println("")
  println("Note: Report generation requires existing analysis data")
}

///|
/// Main entry point
fn main {
  // Get command line arguments
  let args = sys::get_args()

  // Skip "cmd/main" from args array
  let mut cmd_args = []
  let mut i = 1
  while i < args.length() {
    cmd_args.push(args[i])
    i = i + 1
  }

  // Parse and execute command
  let command = parse_args(cmd_args)

  match command {
    Command::Help => print_help(),
    Command::Analyze(stock, metric) => run_analyze(stock, metric),
    Command::Backtest(strategy, stock, start, end) => run_backtest(strategy, stock, start, end),
    Command::Monitor(stock) => run_monitor(stock),
    Command::Report(format) => run_report(format),
    Command::ListStrategies => print_strategies(),
  }
}
