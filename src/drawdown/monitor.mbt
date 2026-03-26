/// Drawdown monitoring and alerts
///
/// Provides real-time drawdown monitoring with configurable alert thresholds.

///|
/// Drawdown monitor state
/// Tracks peak value, current drawdown, and alert status
pub struct DrawdownMonitor {
  /// Highest value seen (peak)
  mut peak_value : Float
  /// Date of the peak
  mut peak_date : String
  /// Current portfolio value
  mut current_value : Float
  /// Current drawdown as negative percentage
  mut current_drawdown : Float
  /// Warning threshold (e.g., -0.1 for 10%)
  warning_threshold : Float
  /// Critical threshold (e.g., -0.2 for 20%)
  critical_threshold : Float
  /// Whether an alert is currently triggered
  mut alert_triggered : Bool
  /// Level of last alert ("WARNING", "CRITICAL", or "")
  mut last_alert_level : String
}

///|
/// Create a new drawdown monitor
///
/// Parameters:
/// - warning_threshold: Drawdown level for warning alerts (e.g., -0.1)
/// - critical_threshold: Drawdown level for critical alerts (e.g., -0.2)
///
/// Returns:
/// - Initialized DrawdownMonitor with zero values
///
/// Examples:
/// ```mbt check
/// test "create_monitor example" {
///   let monitor = create_monitor(-0.1, -0.2)
///   monitor.update(100000.0, "2023-01-01")
///   assert_true(monitor.peak_value == 100000.0)
/// }
/// ```
pub fn create_monitor(
  warning_threshold : Float,
  critical_threshold : Float,
) -> DrawdownMonitor {
  DrawdownMonitor::{
    peak_value: 0.0,
    peak_date: "",
    current_value: 0.0,
    current_drawdown: 0.0,
    warning_threshold,
    critical_threshold,
    alert_triggered: false,
    last_alert_level: "",
  }
}

///|
/// Update monitor with new value
///
/// Parameters:
/// - value: Current portfolio value
/// - date: Current date (YYYY-MM-DD format)
///
/// Behavior:
/// - Updates current value and drawdown
/// - Updates peak if value exceeds previous peak
/// - Checks alert thresholds and updates alert status
///
/// Examples:
/// ```mbt check
/// test "DrawdownMonitor::update example" {
///   let monitor = create_monitor(-0.1, -0.2)
///   monitor.update(100000.0, "2023-01-01") // Set initial value
///   monitor.update(95000.0, "2023-01-02") // 5% drawdown
///   monitor.update(80000.0, "2023-01-03") // 20% drawdown, critical alert
///   assert_true(monitor.alert_triggered)
///   assert_true(monitor.last_alert_level == "CRITICAL")
/// }
/// ```
pub fn DrawdownMonitor::update(
  self : DrawdownMonitor,
  value : Float,
  date : String,
) -> Unit {
  self.current_value = value

  if value > self.peak_value {
    self.peak_value = value
    self.peak_date = date
  }

  if self.peak_value > 0.0 {
    self.current_drawdown = (value - self.peak_value) / self.peak_value
  }

  // Check alerts
  if self.current_drawdown <= self.critical_threshold {
    self.alert_triggered = true
    self.last_alert_level = "CRITICAL"
  } else if self.current_drawdown <= self.warning_threshold {
    self.alert_triggered = true
    self.last_alert_level = "WARNING"
  } else {
    self.alert_triggered = false
    self.last_alert_level = ""
  }
}

///|
/// Get current drawdown percentage
///
/// Returns:
/// - Current drawdown as negative percentage (e.g., -0.15 for 15%)
///
/// Examples:
/// ```mbt check
/// test "DrawdownMonitor::get_drawdown example" {
///   let monitor = create_monitor(-0.1, -0.2)
///   monitor.update(100000.0, "2023-01-01")
///   monitor.update(90000.0, "2023-01-02")
///   let dd = monitor.get_drawdown()
///   assert_true(Float::abs(dd - -0.1) < 0.001)
/// }
/// ```
pub fn DrawdownMonitor::get_drawdown(self : DrawdownMonitor) -> Float {
  self.current_drawdown
}

///|
/// Get current drawdown info
///
/// Returns:
/// - DrawdownInfo with peak, trough, and drawdown details
pub fn DrawdownMonitor::get_info(self : DrawdownMonitor) -> DrawdownInfo {
  DrawdownInfo::{
    peak: self.peak_value,
    trough: self.current_value,
    peak_date: self.peak_date,
    trough_date: self.peak_date,
    drawdown: self.current_drawdown,
    duration: 0,
    recovered: self.current_value >= self.peak_value,
  }
}

///|
/// Check if alert is triggered
///
/// Returns:
/// - true if drawdown exceeds warning or critical threshold
/// - false if drawdown is within normal range
pub fn DrawdownMonitor::is_alert_triggered(self : DrawdownMonitor) -> Bool {
  self.alert_triggered
}

///|
/// Get last alert level
///
/// Returns:
/// - "WARNING" if warning threshold exceeded
/// - "CRITICAL" if critical threshold exceeded
/// - "" if no alert triggered
pub fn DrawdownMonitor::get_alert_level(self : DrawdownMonitor) -> String {
  self.last_alert_level
}

///|
/// Reset monitor state
///
/// Clears peak, drawdown, and alert status.
/// Call this when starting a new monitoring period or after a reset event.
pub fn DrawdownMonitor::reset(self : DrawdownMonitor) -> Unit {
  self.peak_value = 0.0
  self.peak_date = ""
  self.current_drawdown = 0.0
  self.alert_triggered = false
  self.last_alert_level = ""
}
