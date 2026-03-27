/// Handler for report command

///|
/// Run report command
pub fn _run_report(format : String) -> Unit {
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

  // Get data directory from config
  let data_dir = @cmd/main/config.get_data_dir()

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
          found_file = Some(data_dir + "/" + file)
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
            if @ffi.file_exists(data_dir + "/" + candidate) {
              found_file = Some(data_dir + "/" + candidate)
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
