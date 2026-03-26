/// Drawdown monitoring and alerts

///|
/// Drawdown monitor state
pub struct DrawdownMonitor {
  mut peak_value : Float
  mut peak_date : String
  mut current_value : Float
  mut current_drawdown : Float
  warning_threshold : Float
  critical_threshold : Float
  mut alert_triggered : Bool
  mut last_alert_level : String
}

///|
/// Create a new drawdown monitor
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
pub fn DrawdownMonitor::get_drawdown(self : DrawdownMonitor) -> Float {
  self.current_drawdown
}

///|
/// Get current drawdown info
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
pub fn DrawdownMonitor::is_alert_triggered(self : DrawdownMonitor) -> Bool {
  self.alert_triggered
}

///|
/// Get last alert level
pub fn DrawdownMonitor::get_alert_level(self : DrawdownMonitor) -> String {
  self.last_alert_level
}

///|
/// Reset monitor state
pub fn DrawdownMonitor::reset(self : DrawdownMonitor) -> Unit {
  self.peak_value = 0.0
  self.peak_date = ""
  self.current_drawdown = 0.0
  self.alert_triggered = false
  self.last_alert_level = ""
}
