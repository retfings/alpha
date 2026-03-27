/// Handler for backtest command

///|
/// Run backtest command
pub fn _run_backtest(
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

  // Get data directory from config
  let data_dir = @alpha/config.get_data_dir()

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
          found_file = Some(data_dir + "/" + file)
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
        if @ffi.file_exists(data_dir + "/" + candidate) {
          found_file = Some(data_dir + "/" + candidate)
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
      println("Expected file pattern: \{data_dir}/\{market}_\{code}_*.csv")
      println("")
      println("Hint: Set DATA_FILES environment variable with comma-separated")
      println("      file names available in the data/ directory.")
      println("")
      println("Config: You can set MOONBIT_DATA_DIR environment variable or")
      println("        create config.json with \"data_dir\" field to override.")
    }
  }
}
