/// Main entry point for the quantitative drawdown CLI

///|
/// CLI Commands
pub enum Command {
  Help
  Analyze(String, String) // stock, metric
  Backtest(String, String, String, String) // strategy, stock, start, end
  Report(String) // output
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
  let mut strategy = ""
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
fn parse_report_args(args : Array[String]) -> Command {
  let mut output = "report.html"

  let mut i = 1
  while i < args.length() {
    if args[i] == "--output" && i + 1 < args.length() {
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
  println("    analyze         Analyze stock/portfolio drawdown")
  println("    backtest        Run strategy backtest")
  println("    report          Generate analysis report")
  println("    list-strategies List available strategies")
  println("    help            Show this help message")
  println("")
  println("EXAMPLES:")
  println(
    "    moon run cmd/main analyze --stock sh.600000 --metric max_drawdown",
  )
  println(
    "    moon run cmd/main backtest --strategy ma_cross --stock sh.600000",
  )
  println("    moon run cmd/main list-strategies")
}

///|
/// Print available strategies
fn print_strategies() -> Unit {
  println("Available Strategies:")
  println("  (No strategies implemented yet)")
  println("")
  println("Coming soon:")
  println("  - ma_cross: Moving Average Crossover")
  println("  - momentum: Momentum Strategy")
  println("  - mean_reversion: Mean Reversion Strategy")
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

  // Demo output - will be replaced with actual data loading
  println("Note: Data loading requires C FFI implementation")
  println("Please use the Python script to download data first:")
  println("  python script/download_data.py --stocks \{stock}")
}

///|
/// Run backtest command
fn run_backtest(
  strategy : String,
  stock : String,
  start : String,
  end : String,
) -> Unit {
  if strategy == "" || stock == "" {
    println("Error: --strategy and --stock are required for backtest command")
    println(
      "Usage: moon run cmd/main backtest --strategy ma_cross --stock sh.600000",
    )
    return
  }

  println("Running backtest:")
  println("  Strategy: \{strategy}")
  println("  Stock: \{stock}")
  println("  Period: \{start} to \{end}")
  println("")
  println("Note: Backtest engine is under development")
}

///|
/// Run report command
fn run_report(output : String) -> Unit {
  println("Generating report: \{output}")
  println("")
  println("Note: Report generation is under development")
}

///|
/// Main entry point
fn main {
  // Simple demo - just print help for now
  // Full CLI arg parsing requires C FFI or external runtime
  print_help()
  println("")
  println("Note: Full CLI argument parsing requires C FFI implementation.")
  println("This is a placeholder demonstrating the framework structure.")
}
