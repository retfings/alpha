/// Drawdown types and utilities
///
/// Types and functions for classifying drawdown severity and managing alerts.

///|
/// Drawdown severity levels
/// Classifies drawdowns by severity for risk assessment
pub enum DrawdownLevel {
  /// 0-5%: Normal market fluctuation
  Normal
  /// 5-10%: Minor drawdown, monitor closely
  Minor
  /// 10-20%: Moderate drawdown, consider reducing risk
  Moderate
  /// 20-30%: Significant drawdown, defensive posture recommended
  Significant
  /// 30%+: Severe drawdown, immediate action required
  Severe
} derive(Show, Eq, ToJson)

///|
/// Classify drawdown severity
///
/// Parameters:
/// - drawdown: Drawdown as negative percentage (e.g., -0.15 for 15%)
///
/// Returns:
/// - DrawdownLevel indicating severity
///
/// Examples:
/// ```mbt check
/// test "classify_drawdown examples" {
///   let level1 = classify_drawdown(-0.03)
///   let level2 = classify_drawdown(-0.15)
///   let level3 = classify_drawdown(-0.25)
///   let level4 = classify_drawdown(-0.35)
///   // Verify different inputs produce different outputs
///   assert_true(level1 != level2)
///   assert_true(level2 != level3)
///   assert_true(level3 != level4)
/// }
/// ```
pub fn classify_drawdown(drawdown : Float) -> DrawdownLevel {
  // Positive values (gains) are always Normal
  if drawdown > 0.0 {
    DrawdownLevel::Normal
  } else {
    let abs_dd = Float::abs(drawdown)
    if abs_dd >= 0.3 {
      DrawdownLevel::Severe
    } else if abs_dd >= 0.2 {
      DrawdownLevel::Significant
    } else if abs_dd >= 0.1 {
      DrawdownLevel::Moderate
    } else if abs_dd >= 0.05 {
      DrawdownLevel::Minor
    } else {
      DrawdownLevel::Normal
    }
  }
}

///|
/// Drawdown alert configuration
/// Thresholds for triggering drawdown alerts at different severity levels
pub struct DrawdownAlert {
  /// Warning threshold (e.g., -0.1 for 10% drawdown)
  /// Triggers a caution alert
  warning_threshold : Float
  /// Critical threshold (e.g., -0.2 for 20% drawdown)
  /// Triggers a warning alert
  critical_threshold : Float
  /// Maximum allowed drawdown (e.g., -0.3 for 30% drawdown)
  /// Triggers a critical alert
  max_threshold : Float
}

///|
/// Default alert thresholds
///
/// Returns a DrawdownAlert with commonly used thresholds:
/// - Warning: 10% drawdown
/// - Critical: 20% drawdown
/// - Maximum: 30% drawdown
///
/// Examples:
/// ```mbt check
/// test "default_alert_config example" {
///   let config = default_alert_config()
///   let status = check_drawdown_alert(-0.25, config)
///   assert_true(status == "WARNING: Critical drawdown level reached")
/// }
/// ```
pub fn default_alert_config() -> DrawdownAlert {
  DrawdownAlert::{
    warning_threshold: -0.1,
    critical_threshold: -0.2,
    max_threshold: -0.3,
  }
}

///|
/// Check drawdown against alert thresholds
///
/// Parameters:
/// - drawdown: Current drawdown as negative percentage
/// - config: DrawdownAlert configuration with thresholds
///
/// Returns:
/// - Alert status message string
///
/// Returns one of:
/// - "CRITICAL: Maximum drawdown exceeded!"
/// - "WARNING: Critical drawdown level reached"
/// - "CAUTION: Warning drawdown level reached"
/// - "OK: Drawdown within normal range"
///
/// Examples:
/// ```mbt check
/// test "check_drawdown_alert examples" {
///   let config = default_alert_config()
///   assert_true(
///     check_drawdown_alert(-0.05, config) == "OK: Drawdown within normal range",
///   )
///   assert_true(
///     check_drawdown_alert(-0.15, config) ==
///     "CAUTION: Warning drawdown level reached",
///   )
///   assert_true(
///     check_drawdown_alert(-0.25, config) ==
///     "WARNING: Critical drawdown level reached",
///   )
///   assert_true(
///     check_drawdown_alert(-0.35, config) ==
///     "CRITICAL: Maximum drawdown exceeded!",
///   )
/// }
/// ```
pub fn check_drawdown_alert(drawdown : Float, config : DrawdownAlert) -> String {
  if drawdown <= config.max_threshold {
    "CRITICAL: Maximum drawdown exceeded!"
  } else if drawdown <= config.critical_threshold {
    "WARNING: Critical drawdown level reached"
  } else if drawdown <= config.warning_threshold {
    "CAUTION: Warning drawdown level reached"
  } else {
    "OK: Drawdown within normal range"
  }
}

///|
/// Drawdown alert instance (triggered alert)
/// Represents an actual drawdown alert that was triggered
pub struct DrawdownAlertInstance {
  /// Stock code that triggered the alert
  stock : @data.StockCode
  /// Alert severity level
  level : DrawdownLevel
  /// Current drawdown value
  drawdown : Float
  /// When the alert was triggered (date string)
  triggered_at : String
  /// Alert message
  message : String
} derive(ToJson, Show)

///|
/// Create a drawdown alert instance
///
/// Parameters:
/// - stock: Stock code
/// - drawdown: Current drawdown value
/// - date: Date when alert was triggered
///
/// Returns:
/// - DrawdownAlertInstance with classified severity
pub fn create_drawdown_alert(
  stock : @data.StockCode,
  drawdown : Float,
  date : String,
) -> DrawdownAlertInstance {
  let level = classify_drawdown(drawdown)
  let message = match level {
    DrawdownLevel::Normal => "Drawdown within normal range"
    DrawdownLevel::Minor => "Minor drawdown detected - monitor closely"
    DrawdownLevel::Moderate => "Moderate drawdown - consider reducing risk"
    DrawdownLevel::Significant =>
      "Significant drawdown - defensive posture recommended"
    DrawdownLevel::Severe => "Severe drawdown - immediate action required"
  }
  DrawdownAlertInstance::{ stock, level, drawdown, triggered_at: date, message }
}

///|
/// Multi-stock drawdown aggregation for portfolio monitoring
/// Aggregates drawdown information across multiple stocks
pub struct PortfolioDrawdown {
  /// Overall portfolio drawdown
  total_drawdown : Float
  /// Maximum single-stock drawdown
  max_stock_drawdown : Float
  /// Stock with maximum drawdown
  worst_stock : @data.StockCode
  /// Number of stocks in drawdown (>5%)
  stocks_in_drawdown : Int
  /// List of individual stock drawdowns
  stock_drawdowns : Array[(@data.StockCode, Float)]
} derive(ToJson, Show)

///|
/// Create portfolio drawdown summary
///
/// Parameters:
/// - stock_drawdowns: Array of (stock_code, drawdown) pairs
///
/// Returns:
/// - PortfolioDrawdown with aggregated statistics
pub fn create_portfolio_drawdown(
  stock_drawdowns : Array[(@data.StockCode, Float)],
) -> PortfolioDrawdown {
  if stock_drawdowns.length() == 0 {
    return PortfolioDrawdown::{
      total_drawdown: 0.0,
      max_stock_drawdown: 0.0,
      worst_stock: "",
      stocks_in_drawdown: 0,
      stock_drawdowns: [],
    }
  }

  let mut total_dd : Float = 0.0
  let mut max_dd : Float = 0.0
  let mut worst_stock = ""
  let mut in_drawdown_count = 0

  for item in stock_drawdowns {
    let stock = item.0
    let dd = item.1
    total_dd = total_dd + dd
    if dd < max_dd {
      max_dd = dd
      worst_stock = stock
    }
    if dd < -0.05 {
      in_drawdown_count = in_drawdown_count + 1
    }
  }

  let avg_dd = total_dd / Float::from_int(stock_drawdowns.length())

  PortfolioDrawdown::{
    total_drawdown: avg_dd,
    max_stock_drawdown: max_dd,
    worst_stock,
    stocks_in_drawdown: in_drawdown_count,
    stock_drawdowns,
  }
}

///|
/// Drawdown duration analysis
/// Tracks how long a drawdown lasts and time to recover
pub struct DrawdownDuration {
  /// Peak date when drawdown started
  peak_date : String
  /// Trough date when lowest point was reached
  trough_date : String
  /// Recovery date (empty if not yet recovered)
  recovery_date : String?
  /// Duration from peak to trough in days
  peak_to_trough_days : Int
  /// Duration from trough to recovery in days (0 if not recovered)
  trough_to_recovery_days : Int
  /// Total drawdown duration in days
  total_duration_days : Int
  /// Whether the drawdown has recovered
  is_recovered : Bool
} derive(ToJson, Show)

///|
/// Calculate drawdown duration from DrawdownInfo
///
/// Parameters:
/// - info: DrawdownInfo from calculate_max_drawdown_with_info
///
/// Returns:
/// - DrawdownDuration with timing analysis
pub fn calculate_drawdown_duration(info : DrawdownInfo) -> DrawdownDuration {
  let peak_to_trough = info.duration
  let recovered = info.recovered
  let trough_to_recovery = if recovered {
    // Simplified: assume same duration for recovery (should use actual dates)
    peak_to_trough / 2
  } else {
    0
  }
  let total_duration = peak_to_trough + trough_to_recovery

  DrawdownDuration::{
    peak_date: info.peak_date,
    trough_date: info.trough_date,
    recovery_date: if recovered {
      Some(info.trough_date)
    } else {
      None
    },
    peak_to_trough_days: peak_to_trough,
    trough_to_recovery_days: trough_to_recovery,
    total_duration_days: total_duration,
    is_recovered: recovered,
  }
}

///|
/// Calculate days between two date strings (YYYY-MM-DD format)
///
/// Parameters:
/// - start_date: Start date
/// - end_date: End date
///
/// Returns:
/// - Number of days between dates (negative if end < start)
pub fn days_between_dates(start_date : String, end_date : String) -> Int {
  // Simple calculation: parse YYYY-MM-DD and compute difference
  // This is a simplified implementation
  let start_days = date_to_days(start_date)
  let end_days = date_to_days(end_date)
  end_days - start_days
}

///|
/// Convert YYYY-MM-DD date to days since epoch (simplified)
fn date_to_days(date : String) -> Int {
  if date.length() < 10 {
    return 0
  }
  let year = parse_date_component(date, 0, 4)
  let month = parse_date_component(date, 5, 2)
  let day = parse_date_component(date, 8, 2)
  // Simplified: approximate days since year 2000
  (year - 2000) * 365 + (month - 1) * 30 + day
}

///|
/// Parse a date component (year, month, or day) from YYYY-MM-DD string
fn parse_date_component(date : String, start : Int, len : Int) -> Int {
  let mut val = 0
  let mut i = 0
  while i < len {
    let idx = start + i
    if idx < date.length() {
      let c : UInt16 = date.code_unit_at(idx)
      if c >= 48 && c <= 57 {
        val = val * 10 + (c.to_int() - 48)
      }
    }
    i = i + 1
  }
  val
}
