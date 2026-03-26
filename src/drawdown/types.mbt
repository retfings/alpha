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
} derive(Show, Eq)

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
