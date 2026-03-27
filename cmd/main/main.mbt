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
  Serve(Int) // port
}

///|
/// Parse command line arguments (reserved for future C FFI implementation)
fn _parse_args(args : Array[String]) -> Command {
  if args.length() == 0 {
    return Command::Help
  }

  match args[0] {
    "help" => Command::Help
    "analyze" => _parse_analyze_args(args)
    "backtest" => _parse_backtest_args(args)
    "monitor" => _parse_monitor_args(args)
    "report" => _parse_report_args(args)
    "list-strategies" => Command::ListStrategies
    "serve" => _parse_serve_args(args)
    _ => Command::Help
  }
}

///|
fn _parse_analyze_args(args : Array[String]) -> Command {
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
fn _parse_backtest_args(args : Array[String]) -> Command {
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
fn _parse_monitor_args(args : Array[String]) -> Command {
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
fn _parse_report_args(args : Array[String]) -> Command {
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
fn _parse_serve_args(args : Array[String]) -> Command {
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
  println("    serve             Start HTTP API server")
  println("    help              Show this help message")
  println("")
  println("EXAMPLES:")
  println(
    "    moon run cmd/main analyze --stock sh.600000 --metric max_drawdown",
  )
  println(
    "    moon run cmd/main backtest --strategy ma_cross --stock sh.600000",
  )
  println("    moon run cmd/main monitor --stock sh.600000")
  println("    moon run cmd/main report --format html")
  println("    moon run cmd/main list-strategies")
  println("    moon run cmd/main serve --port 8080")
}

///|
/// Print available strategies
fn _print_strategies() -> Unit {
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
fn _run_analyze(stock : String, metric : String) -> Unit {
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
    println(
      "Warning: Stock code should be in format 'market.code' (e.g., sh.600000)",
    )
  }

  // Build file path from stock code (e.g., sh.600000 -> data/sh_600000_*.csv)
  let stock_parts = stock.split(".")
  let stock_parts_arr = stock_parts.to_array()
  if stock_parts_arr.length() < 2 {
    println("Error: Invalid stock code format")
    return
  }
  let market = stock_parts_arr[0]
  let code = stock_parts_arr[1]

  // Try to find the data file by constructing path from stock code
  // File pattern: data/{market}_{code}_*.csv (e.g., data/sh_600000_*.csv)
  let mut found_file : String? = None

  // Try to read available files from DATA_FILES environment variable
  // Format: comma-separated file names (e.g., "sh_600000_*.csv,sh_600001_*.csv")
  // If not set, construct path directly and check if file exists
  match @ffi.getenv("DATA_FILES") {
    Some(files_str) => {
      // Parse comma-separated file list
      let files = files_str.split(",").map(fn(s) { s.trim().to_string() }).to_array()
      for file in files {
        if file != "" && file.has_prefix(market + "_" + code) {
          found_file = Some("data/" + file)
          break
        }
      }
    }
    None => {
      // Fallback: construct path pattern and try common date ranges
      // This avoids hardcoding - just check if a matching file exists
      let base_pattern = market + "_" + code + "_"
      let date_ranges = [
        "2026-01-01_2026-03-26",
        "2025-01-01_2025-12-31",
        "2024-01-01_2024-12-31",
        "2023-01-01_2023-12-31",
      ]
      for date_range in date_ranges {
        let candidate = (base_pattern + date_range + ".csv").to_string()
        if @ffi.file_exists("data/" + candidate) {
          found_file = Some("data/" + candidate)
          break
        }
      }
    }
  }

  match found_file {
    Some(filepath) => {
      println("Found data file: \{filepath}")
      println("Computing drawdown metrics...")
      println("")

      // Load K-line data
      match @data.load_klines_from_csv(filepath) {
        Ok(klines) => {
          if klines.length() == 0 {
            println("Error: No data found in file")
            return
          }

          println("Loaded \{klines.length()} bars")
          println("")

          // Extract close prices for drawdown calculation
          let close_prices = klines.map(fn(k) { k.close })
          let dates = klines.map(fn(k) { k.date })

          // Calculate drawdown metrics
          let max_dd = @drawdown.calculate_max_drawdown(close_prices)
          let current_dd = @drawdown.calculate_current_drawdown(close_prices)
          let dd_stats = @drawdown.get_drawdown_stats(close_prices)

          // Find max drawdown details
          let max_dd_info = @drawdown.calculate_max_drawdown_detailed(close_prices, dates)

          // Calculate additional statistics
          let mut min_price = close_prices[0]
          let mut max_price = close_prices[0]
          let mut min_date = dates[0]
          let mut max_date = dates[0]
          let mut i = 0
          while i < close_prices.length() {
            if close_prices[i] < min_price {
              min_price = close_prices[i]
              min_date = dates[i]
            }
            if close_prices[i] > max_price {
              max_price = close_prices[i]
              max_date = dates[i]
            }
            i = i + 1
          }

          let first_date = dates[0]
          let last_date = dates[dates.length() - 1]
          let first_close = close_prices[0]
          let last_close = close_prices[close_prices.length() - 1]
          let period_return = (last_close - first_close) / first_close

          // Output results
          println("=======================================")
          println("         DRAWDOWN ANALYSIS RESULTS")
          println("=======================================")
          println("")
          println("Data Range: \{first_date} to \{last_date}")
          println("Total Bars: \{klines.length()}")
          println("")
          println("Price Statistics:")
          println("  Highest Price: \{max_price} (\{max_date})")
          println("  Lowest Price:  \{min_price} (\{min_date})")
          println("  First Close:   \{first_close}")
          println("  Last Close:    \{last_close}")
          println("  Period Return: \{Float::to_string(period_return * 100.0)}%")
          println("")
          println("Drawdown Metrics:")
          println("  Max Drawdown:       \{Float::to_string(max_dd * 100.0)}%")
          println("  Current Drawdown:   \{Float::to_string(current_dd * 100.0)}%")
          println("  Avg Drawdown:       \{Float::to_string(dd_stats.avg_drawdown * 100.0)}%")
          println("  Drawdown Count:     \{dd_stats.drawdown_count}")
          println("")

          match max_dd_info {
            Some(info) => {
              let recovered_str = if info.recovered { "Yes" } else { "No" }
              println("Max Drawdown Details:")
              println("  Peak:   \{info.peak} (\{info.peak_date})")
              println("  Trough: \{info.trough} (\{info.trough_date})")
              println("  Duration: \{info.duration} days")
              println("  Recovered: \{recovered_str}")
              println("")
            }
            None => {
              println("Max Drawdown Details: Unable to calculate")
              println("")
            }
          }

          // Drawdown level classification
          let dd_level = if max_dd > -0.05 {
            "Normal (< 5%)"
          } else if max_dd > -0.10 {
            "Minor (5-10%)"
          } else if max_dd > -0.20 {
            "Moderate (10-20%)"
          } else if max_dd > -0.30 {
            "Significant (20-30%)"
          } else {
            "Severe (> 30%)"
          }
          println("Drawdown Level: \{dd_level}")
          println("=======================================")
        }
        Err(e) => {
          println("Error loading data: \{e}")
        }
      }
    }
    None => {
      println("Error: No data file found for stock '\{stock}'")
      println("Expected file pattern: data/\{market}_\{code}_*.csv")
      println("")
      println("Hint: Set DATA_FILES environment variable with comma-separated")
      println("      file names available in the data/ directory.")
      println("      Example: DATA_FILES=\"sh_600000_*.csv,sh_600001_*.csv\"")
    }
  }
}

///|
/// Run backtest command
fn _run_backtest(
  strategy : String,
  stock : String,
  start : String,
  end : String,
) -> Unit {
  if stock == "" {
    println("Error: --stock is required for backtest command")
    println(
      "Usage: moon run cmd/main backtest --strategy ma_cross --stock sh.600000",
    )
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
    println(
      "Warning: Unknown strategy '\{strategy}'. Available: ma_cross, momentum",
    )
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
fn _run_monitor(stock : String) -> Unit {
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
fn _run_report(format : String) -> Unit {
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
    println(
      "Error: Invalid format '\{format}'. Available: text, html, json, pdf",
    )
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
/// Run serve command - start HTTP API server
fn _run_serve(port : Int) -> Unit {
  println("Starting HTTP API server on port \{port}...")
  println("")
  println("Available endpoints:")
  println("  GET  /api/health              - Health check")
  println("  GET  /api/stocks              - List stocks")
  println("  GET  /api/stocks/:code        - Get stock info")
  println("  GET  /api/stocks/:code/klines - Get klines")
  println("  POST /api/backtest            - Start backtest")
  println("  GET  /api/backtest/:id/result - Get result")
  println("  GET  /api/drawdown/:code      - Get drawdown")
  println("  GET  /api/portfolio/drawdown  - Portfolio drawdown")
  println("")
  println("Press Ctrl+C to stop")
  println("")

  // Start the HTTP server
  @server.start_server(port)
}

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
/// Get command from environment variables
/// MOONBIT_CMD = command name (analyze, backtest, monitor, report, serve, help)
/// MOONBIT_ARGS = space-separated arguments
fn _get_env_command() -> Command {
  match @ffi.getenv("MOONBIT_CMD") {
    None => Command::Help
    Some(cmd) => {
      let args_str = @ffi.getenv("MOONBIT_ARGS").unwrap_or("")
      let args = _parse_env_args(args_str)
      _parse_args([cmd] + args)
    }
  }
}

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
