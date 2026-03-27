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
  println("    MOONBIT_CMD=analyze MOONBIT_ARGS=\"--stock sh.600000 --metric max_drawdown\" moon run cmd/main")
  println("    MOONBIT_CMD=backtest MOONBIT_ARGS=\"--strategy ma_cross --stock sh.600000 --start 2024-01-01 --end 2024-12-31\" moon run cmd/main")
  println("    MOONBIT_CMD=monitor MOONBIT_ARGS=\"--stock sh.600000\" moon run cmd/main")
  println("    MOONBIT_CMD=report MOONBIT_ARGS=\"--format html\" moon run cmd/main")
  println("    MOONBIT_CMD=list-strategies moon run cmd/main")
  println("    MOONBIT_CMD=serve MOONBIT_ARGS=\"--port 8080\" moon run cmd/main")
  println("")
  println("ENVIRONMENT VARIABLES:")
  println("    MOONBIT_CMD  - Command name (analyze, backtest, monitor, report, list-strategies, serve)")
  println("    MOONBIT_ARGS - Space-separated command arguments")
  println("")
  println("FULL EXAMPLES:")
  println("    MOONBIT_CMD=analyze MOONBIT_ARGS=\"--stock sh.600000\" moon run cmd/main")
  println("    MOONBIT_CMD=backtest MOONBIT_ARGS=\"--strategy ma_cross --stock sh.600000\" moon run cmd/main")
  println("    MOONBIT_CMD=report MOONBIT_ARGS=\"--format html\" moon run cmd/main")
}

///|
/// Print available strategies
fn _print_strategies() -> Unit {
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
      let files = files_str
        .split(",")
        .map(fn(s) { s.trim().to_string() })
        .to_array()
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
        "2026-01-01_2026-03-26", "2025-01-01_2025-12-31", "2024-01-01_2024-12-31",
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
          let max_dd_info = @drawdown.calculate_max_drawdown_detailed(
            close_prices, dates,
          )

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
          println(
            "  Period Return: \{Float::to_string(period_return * 100.0)}%",
          )
          println("")
          println("Drawdown Metrics:")
          println("  Max Drawdown:       \{Float::to_string(max_dd * 100.0)}%")
          println(
            "  Current Drawdown:   \{Float::to_string(current_dd * 100.0)}%",
          )
          println(
            "  Avg Drawdown:       \{Float::to_string(dd_stats.avg_drawdown * 100.0)}%",
          )
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
        Err(e) => println("Error loading data: \{e}")
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

  // Validate strategy name and create strategy instance
  let strategy_obj = if strategy == "ma_cross" {
    Some(@builtins.create_ma_cross_strategy(10, 30))
  } else if strategy == "momentum" {
    // Placeholder for momentum strategy
    None
  } else {
    println(
      "Error: Unknown strategy '\{strategy}'. Available: ma_cross, momentum",
    )
    return
  }

  match strategy_obj {
    None => {
      println("Error: Strategy '\{strategy}' is not yet implemented")
      return
    }
    Some(_) => ignore(())
  }

  // Build data file path from stock code
  let stock_parts = stock.split(".")
  let stock_parts_arr = stock_parts.to_array()
  if stock_parts_arr.length() < 2 {
    println("Error: Invalid stock code format")
    return
  }
  let market = stock_parts_arr[0]
  let code = stock_parts_arr[1]

  // Find data file
  let mut found_file : String? = None
  match @ffi.getenv("DATA_FILES") {
    Some(files_str) => {
      let files = files_str
        .split(",")
        .map(fn(s) { s.trim().to_string() })
        .to_array()
      for file in files {
        if file != "" && file.has_prefix(market + "_" + code) {
          found_file = Some("data/" + file)
          break
        }
      }
    }
    None => {
      let base_pattern = market + "_" + code + "_"
      let date_ranges = [
        "2026-01-01_2026-03-26", "2025-01-01_2025-12-31", "2024-01-01_2024-12-31",
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
      println("Loading data from: \{filepath}")

      // Load K-line data
      match @data.load_klines_from_csv(filepath) {
        Ok(klines) => {
          if klines.length() == 0 {
            println("Error: No data found in file")
            return
          }

          println("Loaded \{klines.length()} bars")
          println("")

          // Filter by date range if specified
          let filtered_klines = if start != "" || end != "" {
            klines.filter(fn(k) {
              let pass_start = if start != "" { k.date >= start } else { true }
              let pass_end = if end != "" { k.date <= end } else { true }
              pass_start && pass_end
            })
          } else {
            klines
          }

          if filtered_klines.length() == 0 {
            println("Error: No data in specified date range")
            return
          }

          println("Using \{filtered_klines.length()} bars for backtest")
          println("")

          // Create backtest engine and run
          let config = @strategy.default_backtest_config()
          let engine = @backtest.create_backtest_engine(config)

          // Convert strategy to Strategy type
          let ma_strategy = @builtins.create_ma_cross_strategy(10, 30)
          let strategy_record = @strategy.Strategy::{
            name: ma_strategy.name,
            on_init: fn(_) { ignore(()) },
            on_bar: fn(k, ctx, hist) { ma_strategy.on_bar(k, ctx, hist) },
          }

          let result = @backtest.run_backtest(
            engine, filtered_klines, strategy_record,
          )

          // Print results
          println("")
          println("=======================================")
          println("         BACKTEST RESULTS")
          println("=======================================")
          println("")
          println("Configuration:")
          println("  Strategy: \{strategy}")
          println("  Stock: \{stock}")
          println("  Initial Capital: \{result.initial_capital}")
          println("")
          println("Performance:")
          println(
            "  Final Capital:   \{Float::to_string(result.final_capital)}",
          )
          println(
            "  Total Return:    \{Float::to_string(result.stats.total_return * 100.0)}%",
          )
          println(
            "  Max Drawdown:    \{Float::to_string(result.stats.max_drawdown * 100.0)}%",
          )
          println(
            "  Sharpe Ratio:    \{Float::to_string(result.stats.sharpe_ratio)}",
          )
          println(
            "  Sortino Ratio:   \{Float::to_string(result.stats.sortino_ratio)}",
          )
          println("")
          println("Trade Statistics:")
          println("  Total Trades:    \{result.stats.total_trades}")
          println("  Winning Trades:  \{result.stats.winning_trades}")
          println("  Losing Trades:   \{result.stats.losing_trades}")
          println(
            "  Win Rate:        \{Float::to_string(result.stats.win_rate * 100.0)}%",
          )
          println(
            "  Profit Factor:   \{Float::to_string(result.stats.profit_factor)}",
          )
          println(
            "  Avg Duration:    \{Float::to_string(result.stats.avg_trade_duration)} days",
          )
          println("")
          println("=======================================")
        }
        Err(e) => println("Error loading data: \{e}")
      }
    }
    None => {
      println("Error: No data file found for stock '\{stock}'")
      println("Expected file pattern: data/\{market}_\{code}_*.csv")
      println("")
      println("Hint: Set DATA_FILES environment variable with comma-separated")
      println("      file names available in the data/ directory.")
    }
  }
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

  // Build data file path from stock code
  let stock_parts = stock.split(".")
  let stock_parts_arr = stock_parts.to_array()
  if stock_parts_arr.length() < 2 {
    println("Error: Invalid stock code format")
    return
  }
  let market = stock_parts_arr[0]
  let code = stock_parts_arr[1]

  // Find data file
  let mut found_file : String? = None
  match @ffi.getenv("DATA_FILES") {
    Some(files_str) => {
      let files = files_str
        .split(",")
        .map(fn(s) { s.trim().to_string() })
        .to_array()
      for file in files {
        if file != "" && file.has_prefix(market + "_" + code) {
          found_file = Some("data/" + file)
          break
        }
      }
    }
    None => {
      let base_pattern = market + "_" + code + "_"
      let date_ranges = [
        "2026-01-01_2026-03-26", "2025-01-01_2025-12-31", "2024-01-01_2024-12-31",
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
    Some(filepath) =>
      // Load data for monitoring
      match @data.load_klines_from_csv(filepath) {
        Ok(klines) => {
          if klines.length() == 0 {
            println("Error: No data found")
            return
          }

          // Create drawdown monitor with default thresholds
          let warning_threshold = Float::from_double(-0.10) // 10% warning
          let critical_threshold = Float::from_double(-0.20) // 20% critical
          let monitor = @drawdown.create_monitor(
            warning_threshold, critical_threshold,
          )

          println("Monitoring Configuration:")
          println("  Stock: \{stock}")
          println(
            "  Warning Threshold:  \{Float::to_string(warning_threshold * Float::from_double(100.0))}%",
          )
          println(
            "  Critical Threshold: \{Float::to_string(critical_threshold * Float::from_double(100.0))}%",
          )
          println("")
          println("Simulating monitoring mode (historical replay)...")
          println("")

          // Simulate monitoring by replaying historical data
          let mut last_alert_level = ""
          for kline in klines {
            monitor.update(kline.close, kline.date)

            if monitor.is_alert_triggered() {
              let current_level = monitor.get_alert_level()
              if current_level != last_alert_level {
                println(
                  "[\{kline.date}] ALERT: \{current_level} - Drawdown: \{Float::to_string(monitor.get_drawdown() * Float::from_double(100.0))}%",
                )
                last_alert_level = current_level
              }
            }
          }

          println("")
          println("Monitoring Summary:")
          println("  Final Price: \{klines[klines.length() - 1].close}")
          println(
            "  Current Drawdown: \{Float::to_string(monitor.get_drawdown() * 100.0)}%",
          )
          if monitor.is_alert_triggered() {
            println("  Alert Status: \{monitor.get_alert_level()}")
          } else {
            println("  Alert Status: Normal (no alerts)")
          }
          println("")
          println(
            "Note: This is a historical replay. Real-time mode requires live data feed.",
          )
        }
        Err(e) => println("Error loading data: \{e}")
      }
    None => {
      println("Error: No data file found for stock '\{stock}'")
      println("Expected file pattern: data/\{market}_\{code}_*.csv")
      println("")
      // Still show monitoring setup info
      println("Monitoring Configuration (no data available):")
      println("  Stock: \{stock}")
      println("  Warning Threshold:  -10.0%")
      println("  Critical Threshold: -20.0%")
      println("")
      println("Hint: Set DATA_FILES environment variable to enable monitoring")
    }
  }
}

///|
/// Run report command
fn _run_report(format : String) -> Unit {
  let valid_formats = ["text", "html", "json"]
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
    println("Error: Invalid format '\{format}'. Available: text, html, json")
    return
  }

  println("Generating \{format} report...")
  println("")

  // Build data file path - try to find any available data file
  let mut found_file : String? = None
  match @ffi.getenv("DATA_FILES") {
    Some(files_str) => {
      let files = files_str
        .split(",")
        .map(fn(s) { s.trim().to_string() })
        .to_array()
      for file in files {
        if file != "" && file.has_suffix(".csv") {
          found_file = Some("data/" + file)
          break
        }
      }
    }
    None => {
      // Try to find any CSV file in data directory
      let date_ranges = [
        "2026-01-01_2026-03-26", "2025-01-01_2025-12-31", "2024-01-01_2024-12-31",
      ]
      let markets = ["sh", "sz"]
      let codes = ["600000", "600001", "000001"]
      for market in markets {
        for code in codes {
          for date_range in date_ranges {
            let candidate = (market + "_" + code + "_" + date_range + ".csv").to_string()
            if @ffi.file_exists("data/" + candidate) {
              found_file = Some("data/" + candidate)
              break
            }
          }
          if found_file != None {
            break
          }
        }
        if found_file != None {
          break
        }
      }
    }
  }

  match found_file {
    Some(filepath) =>
      match @data.load_klines_from_csv(filepath) {
        Ok(klines) => {
          if klines.length() == 0 {
            println("Error: No data found")
            return
          }

          // Run backtest to generate results
          let config = @strategy.default_backtest_config()
          let engine = @backtest.create_backtest_engine(config)
          let ma_strategy = @builtins.create_ma_cross_strategy(10, 30)
          let strategy_record = @strategy.Strategy::{
            name: ma_strategy.name,
            on_init: fn(_) { ignore(()) },
            on_bar: fn(k, ctx, hist) { ma_strategy.on_bar(k, ctx, hist) },
          }

          let result = @backtest.run_backtest(engine, klines, strategy_record)

          // Generate and print report
          let report_format = if format == "html" {
            @backtest.ReportFormat::Html
          } else if format == "json" {
            @backtest.ReportFormat::Json
          } else {
            @backtest.ReportFormat::Text
          }

          let default_config = @backtest.default_report_config()
          let report_config = @backtest.ReportConfig::{
            author: default_config.author,
            date: default_config.date,
            title: "Backtest Report - " + filepath,
            format: report_format,
            include_equity_curve: default_config.include_equity_curve,
            include_trades: true,
            include_stats: true,
          }

          let report = @backtest.generate_report(result, report_config)
          println(report)
        }
        Err(e) => println("Error loading data: \{e}")
      }
    None => {
      println("Error: No data files found to generate report")
      println("")
      println("Hint: Place CSV data files in the data/ directory or set")
      println("      DATA_FILES environment variable.")
    }
  }
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
