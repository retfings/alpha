/// Drawdown types and utilities

///|
/// Drawdown severity levels
pub enum DrawdownLevel {
  /// 0-5%: Normal fluctuation
  Normal
  /// 5-10%: Minor drawdown
  Minor
  /// 10-20%: Moderate drawdown
  Moderate
  /// 20-30%: Significant drawdown
  Significant
  /// 30%+: Severe drawdown
  Severe
}

///|
/// Classify drawdown severity
pub fn classify_drawdown(drawdown : Float) -> DrawdownLevel {
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

///|
/// Drawdown alert configuration
pub struct DrawdownAlert {
  /// Warning threshold (e.g., -0.1 for 10%)
  warning_threshold : Float
  /// Critical threshold (e.g., -0.2 for 20%)
  critical_threshold : Float
  /// Maximum allowed drawdown (e.g., -0.3 for 30%)
  max_threshold : Float
}

///|
/// Default alert thresholds
pub fn default_alert_config() -> DrawdownAlert {
  DrawdownAlert::{
    warning_threshold: -0.1,
    critical_threshold: -0.2,
    max_threshold: -0.3,
  }
}

///|
/// Check drawdown against alert thresholds
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
