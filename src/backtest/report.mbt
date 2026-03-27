/// Backtest report generation

///|
/// Report format options
pub(all) enum ReportFormat {
  Html
  Text
} derive(Show)

///|
/// Report configuration
pub(all) struct ReportConfig {
  mut title : String
  mut author : String
  mut date : String
  mut format : ReportFormat
  mut include_equity_curve : Bool
  mut include_trades : Bool
  mut include_stats : Bool
}

///|
/// Default report configuration
pub fn default_report_config() -> ReportConfig {
  ReportConfig::{
    title: "Backtest Report",
    author: "",
    date: "",
    format: ReportFormat::Html,
    include_equity_curve: true,
    include_trades: true,
    include_stats: true,
  }
}

///|
/// Generate backtest report
pub fn generate_report(
  result : BacktestResult,
  config : ReportConfig,
) -> String {
  match config.format {
    ReportFormat::Html => generate_html_report(result, config)
    ReportFormat::Text => generate_text_report(result, config)
  }
}

///|
/// Generate HTML report
fn generate_html_report(
  result : BacktestResult,
  config : ReportConfig,
) -> String {
  let mut html = ""

  html = html + "<!DOCTYPE html>\n<html>\n<head>\n"
  html = html + "  <meta charset=\"UTF-8\">\n"
  html = html + "  <title>" + config.title + "</title>\n"
  html = html + "  <style>\n"
  html = html + "    body { font-family: Arial, sans-serif; margin: 20px; }\n"
  html = html + "    h1 { color: #333; }\n"
  html = html +
    "    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 20px 0; }\n"
  html = html +
    "    .stat-card { background: #f5f5f5; padding: 15px; border-radius: 5px; }\n"
  html = html +
    "    .stat-value { font-size: 24px; font-weight: bold; color: #2196F3; }\n"
  html = html + "    .stat-label { color: #666; font-size: 14px; }\n"
  html = html + "    .negative { color: #f44336; }\n"
  html = html + "    .positive { color: #4CAF50; }\n"
  html = html +
    "    table { border-collapse: collapse; width: 100%; margin: 20px 0; }\n"
  html = html +
    "    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n"
  html = html + "    th { background: #f5f5f5; }\n"
  html = html + "    tr:nth-child(even) { background: #fafafa; }\n"
  html = html + "  </style>\n"
  html = html + "</head>\n<body>\n"
  html = html + "  <h1>" + config.title + "</h1>\n"
  html = html + "  <p>Generated: " + config.date + "</p>\n"

  // Summary stats
  html = html + "  <h2>Performance Summary</h2>\n"
  html = html + "  <div class=\"stats\">\n"

  html = html + stat_card("Total Return", format_pct(result.stats.total_return))
  html = html + stat_card("Max Drawdown", format_pct(result.stats.max_drawdown))
  html = html +
    stat_card("Sharpe Ratio", Float::to_string(result.stats.sharpe_ratio))
  html = html +
    stat_card("Total Trades", Int::to_string(result.stats.total_trades))
  html = html + stat_card("Win Rate", format_pct(result.stats.win_rate))
  html = html +
    stat_card("Final Capital", Float::to_string(result.final_capital))

  html = html + "  </div>\n"

  // Equity curve chart placeholder
  if config.include_equity_curve {
    html = html + "  <h2>Equity Curve</h2>\n"
    html = html +
      "  <div id=\"equity-chart\" style=\"width: 100%; height: 400px; background: #eee;\">\n"
    html = html + "    Chart placeholder - integrate with Chart.js\n"
    html = html + "  </div>\n"
  }

  // Trade log
  if config.include_trades && result.trades.length() > 0 {
    html = html + "  <h2>Trade Log</h2>\n"
    html = html + "  <table>\n"
    html = html + "    <tr>\n"
    html = html + "      <th>Date</th>\n"
    html = html + "      <th>Action</th>\n"
    html = html + "      <th>Price</th>\n"
    html = html + "      <th>Quantity</th>\n"
    html = html + "      <th>Commission</th>\n"
    html = html + "    </tr>\n"

    for trade in result.trades {
      let action_class = match trade.action {
        @strategy.Action::Buy => "positive"
        @strategy.Action::Sell => "negative"
        @strategy.Action::Hold => ""
      }
      html = html + "    <tr>\n"
      html = html + "      <td>" + trade.timestamp + "</td>\n"
      html = html +
        "      <td class=\"" +
        action_class +
        "\">" +
        action_to_string(trade.action) +
        "</td>\n"
      html = html + "      <td>" + Float::to_string(trade.price) + "</td>\n"
      html = html + "      <td>" + Float::to_string(trade.quantity) + "</td>\n"
      html = html +
        "      <td>" +
        Float::to_string(trade.commission) +
        "</td>\n"
      html = html + "    </tr>\n"
    }

    html = html + "  </table>\n"
  }

  html = html + "</body>\n</html>\n"
  html
}

///|
/// Generate a stat card HTML snippet
fn stat_card(label : String, value : String) -> String {
  "    <div class=\"stat-card\">\n" +
  "      <div class=\"stat-value\">" +
  value +
  "</div>\n" +
  "      <div class=\"stat-label\">" +
  label +
  "</div>\n" +
  "    </div>\n"
}

///|
/// Generate text report
fn generate_text_report(
  result : BacktestResult,
  config : ReportConfig,
) -> String {
  let sep = "================================================================================\n"
  let mut text = sep
  text = text + "  " + config.title + "\n"
  text = text + sep
  text = text + "Generated: " + config.date + "\n\n"
  text = text + "PERFORMANCE SUMMARY\n"
  text = text + "-------------------\n"
  text = text +
    "  Total Return:    " +
    format_pct(result.stats.total_return) +
    "\n"
  text = text +
    "  Max Drawdown:    " +
    format_pct(result.stats.max_drawdown) +
    "\n"
  text = text +
    "  Sharpe Ratio:    " +
    Float::to_string(result.stats.sharpe_ratio) +
    "\n"
  text = text +
    "  Total Trades:    " +
    Int::to_string(result.stats.total_trades) +
    "\n"
  text = text + "  Win Rate:        " + format_pct(result.stats.win_rate) + "\n"
  text = text +
    "  Final Capital:   " +
    Float::to_string(result.final_capital) +
    "\n\n"

  // Trade log
  if config.include_trades && result.trades.length() > 0 {
    text = text + "TRADE LOG\n"
    text = text + "-----------\n"
    for trade in result.trades {
      text = text + "  " + trade.timestamp
      text = text + "  " + action_to_string(trade.action)
      text = text + "  Price: " + Float::to_string(trade.price)
      text = text + "  Qty: " + Float::to_string(trade.quantity)
      text = text + "  Comm: " + Float::to_string(trade.commission)
      text = text + "\n"
    }
    text = text + "\n"
  }

  text
}

///|
/// Format percentage
fn format_pct(value : Float) -> String {
  let pct = value * 100.0
  if pct < 0.0 {
    "-" + Float::to_string(Float::abs(pct)) + "%"
  } else {
    Float::to_string(pct) + "%"
  }
}

///|
/// Convert action to string
pub fn action_to_string(action : @strategy.Action) -> String {
  match action {
    @strategy.Action::Buy => "BUY"
    @strategy.Action::Sell => "SELL"
    @strategy.Action::Hold => "HOLD"
  }
}

///|
/// Print report to stdout
pub fn print_report(
  result : BacktestResult,
  _format? : ReportFormat = ReportFormat::Text,
) -> Unit {
  let config = default_report_config()
  let report = generate_report(result, config)
  println(report)
}

///|
/// Save report to file
///
/// Parameters:
/// - result: Backtest result to save
/// - path: File path to save to
/// - _format?: Report format (HTML or Text) - currently always generates text
///
/// Returns:
/// - Ok(()) on success
/// - Err(String) with error message on failure
pub fn save_report_to_file(
  result : BacktestResult,
  path : String,
  _format? : ReportFormat = ReportFormat::Html,
) -> Result[Unit, String] {
  // Generate report content
  let config = default_report_config()
  let report = generate_report(result, config)

  // Use FFI to write file
  let success = @ffi.write_file(path, report)
  if success {
    Ok(())
  } else {
    Err("Failed to write report to file: \{path}")
  }
}
