/// Handler for analyze command

///|
/// Run analysis command
pub fn _run_analyze(stock : String, metric : String) -> Unit {
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

  // Get data directory from config
  let data_dir = @cmd/main/config.get_data_dir()

  // Build file path from stock code (e.g., sh.600000 -> {data_dir}/sh_600000_*.csv)
  let stock_parts = stock.split(".")
  let stock_parts_arr = stock_parts.to_array()
  if stock_parts_arr.length() < 2 {
    println("Error: Invalid stock code format")
    return
  }
  let market = stock_parts_arr[0]
  let code = stock_parts_arr[1]

  // Try to find the data file by constructing path from stock code
  // File pattern: {data_dir}/{market}_{code}_*.csv (e.g., data/sh_600000_*.csv)
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
          found_file = Some(data_dir + "/" + file)
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
        if @ffi.file_exists(data_dir + "/" + candidate) {
          found_file = Some(data_dir + "/" + candidate)
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
      println("Expected file pattern: \{data_dir}/\{market}_\{code}_*.csv")
      println("")
      println("Hint: Set DATA_FILES environment variable with comma-separated")
      println("      file names available in the data/ directory.")
      println("      Example: DATA_FILES=\"sh_600000_*.csv,sh_600001_*.csv\"")
      println("")
      println("Config: You can set MOONBIT_DATA_DIR environment variable or")
      println("        create config.json with \"data_dir\" field to override.")
    }
  }
}
