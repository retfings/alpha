/// Handler for monitor command

///|
/// Run monitor command
pub fn _run_monitor(stock : String) -> Unit {
  if stock == "" {
    println("Error: --stock is required for monitor command")
    println("Usage: moon run cmd/main monitor --stock sh.600000")
    return
  }

  println("Starting real-time monitoring for: \{stock}")
  println("")

  // Get data directory from config
  let data_dir = @cmd/main/config.get_data_dir()

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
      println("Expected file pattern: \{data_dir}/\{market}_\{code}_*.csv")
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
