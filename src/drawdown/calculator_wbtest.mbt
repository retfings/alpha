/// White-box tests for drawdown module - test internal helpers and detailed behavior

///|
test "calculate_max_drawdown - empty array" {
  let values : Array[Float] = []
  let max_dd = calculate_max_drawdown(values)
  assert_true(max_dd == 0.0)
}

///|
test "calculate_max_drawdown - single element" {
  let values : Array[Float] = [100.0]
  let max_dd = calculate_max_drawdown(values)
  assert_true(max_dd == 0.0)
}

///|
test "calculate_max_drawdown - monotonic increase" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 130.0, 140.0]
  let max_dd = calculate_max_drawdown(values)
  assert_true(max_dd == 0.0)
}

///|
test "calculate_max_drawdown - monotonic decrease" {
  let values : Array[Float] = [100.0, 90.0, 80.0, 70.0, 60.0]
  let max_dd = calculate_max_drawdown(values)
  // Peak=100, Trough=60, Drawdown = (60-100)/100 = -0.4
  assert_true(max_dd == -0.4)
}

///|
test "calculate_max_drawdown - basic case" {
  let values : Array[Float] = [
    100.0, 110.0, 120.0, 110.0, 100.0, 90.0, 95.0, 100.0,
  ]
  let max_dd = calculate_max_drawdown(values)
  // Peak=120, Trough=90, Drawdown = (90-120)/120 = -0.25
  assert_true(Float::abs(max_dd - -0.25) < 0.0001)
}

///|
test "calculate_max_drawdown - multiple peaks" {
  let values : Array[Float] = [100.0, 120.0, 100.0, 130.0, 110.0, 140.0, 120.0]
  let max_dd = calculate_max_drawdown(values)
  // Peak=140, Trough=120, Drawdown = (120-140)/140 = -0.1428...
  // But the deepest is Peak=130, Trough=110 = (110-130)/130 = -0.1538...
  // Actually: Peak=120, Trough=100 = (100-120)/120 = -0.1666...
  assert_true(max_dd < -0.15 && max_dd > -0.18)
}

///|
test "calculate_max_drawdown_detailed - basic case" {
  let values : Array[Float] = [
    100.0, 110.0, 120.0, 110.0, 100.0, 90.0, 95.0, 100.0,
  ]
  let dates : Array[String] = [
    "2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04", "2024-01-05", "2024-01-06",
    "2024-01-07", "2024-01-08",
  ]
  let result = calculate_max_drawdown_detailed(values, dates)
  match result {
    Some(info) => {
      assert_true(info.peak == 120.0)
      assert_true(info.peak_date == "2024-01-03")
      assert_true(info.trough == 90.0)
      assert_true(info.trough_date == "2024-01-06")
      assert_true(Float::abs(info.drawdown - -0.25) < 0.0001)
      assert_true(info.duration == 3)
      assert_true(info.recovered == false)
    }
    None => fail("Expected Some result")
  }
}

///|
test "calculate_max_drawdown_detailed - empty array" {
  let values : Array[Float] = []
  let dates : Array[String] = []
  let result = calculate_max_drawdown_detailed(values, dates)
  assert_true(result == None)
}

///|
test "calculate_max_drawdown_detailed - length mismatch" {
  let values : Array[Float] = [100.0, 110.0, 120.0]
  let dates : Array[String] = ["2024-01-01", "2024-01-02"]
  let result = calculate_max_drawdown_detailed(values, dates)
  assert_true(result == None)
}

///|
test "calculate_max_drawdown_detailed - recovered" {
  let values : Array[Float] = [100.0, 120.0, 90.0, 130.0]
  let dates : Array[String] = [
    "2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04",
  ]
  let result = calculate_max_drawdown_detailed(values, dates)
  match result {
    Some(info) =>
      // Peak=120, Trough=90, but final value 130 > peak 120, so recovered
      assert_true(info.recovered == true)
    None => fail("Expected Some result")
  }
}

///|
test "calculate_drawdown_series - empty array" {
  let values : Array[Float] = []
  let series = calculate_drawdown_series(values)
  assert_true(series.length() == 0)
}

///|
test "calculate_drawdown_series - basic case" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 100.0]
  let series = calculate_drawdown_series(values)
  assert_true(series.length() == 5)
  assert_true(series[0] == 0.0)
  assert_true(series[1] == 0.0)
  assert_true(series[2] == 0.0)
  assert_true(series[3] < -0.08 && series[3] > -0.09)
  assert_true(series[4] < -0.16 && series[4] > -0.17)
}

///|
test "calculate_current_drawdown - empty array" {
  let values : Array[Float] = []
  let current_dd = calculate_current_drawdown(values)
  assert_true(current_dd == 0.0)
}

///|
test "calculate_current_drawdown - basic case" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 100.0]
  let current_dd = calculate_current_drawdown(values)
  // Peak=120, Current=100, Drawdown = (100-120)/120 = -0.1666...
  assert_true(current_dd < -0.16 && current_dd > -0.17)
}

///|
test "calculate_current_drawdown - at peak" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 130.0]
  let current_dd = calculate_current_drawdown(values)
  assert_true(current_dd == 0.0)
}

///|
test "get_drawdown_stats - basic case" {
  let values : Array[Float] = [
    100.0, 110.0, 120.0, 110.0, 100.0, 90.0, 95.0, 100.0,
  ]
  let stats = get_drawdown_stats(values)
  assert_true(Float::abs(stats.max_drawdown - -0.25) < 0.0001)
  assert_true(stats.drawdown_count > 0)
  assert_true(stats.avg_drawdown < 0.0)
}

///|
test "get_drawdown_stats - no drawdown" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 130.0, 140.0]
  let stats = get_drawdown_stats(values)
  assert_true(stats.max_drawdown == 0.0)
  assert_true(stats.current_drawdown == 0.0)
  assert_true(stats.drawdown_count == 0)
  assert_true(stats.avg_drawdown == 0.0)
}

///|
test "classify_drawdown - zero" {
  let level = classify_drawdown(0.0)
  assert_true(level.to_string().contains("Normal"))
}

///|
test "classify_drawdown - positive (gain)" {
  let level = classify_drawdown(0.1)
  // Positive values are classified as Normal (gains, not drawdowns)
  assert_true(level.to_string().contains("Normal"))
}

///|
test "classify_drawdown - boundary normal" {
  let level = classify_drawdown(-0.049)
  assert_true(level.to_string().contains("Normal"))
}

///|
test "classify_drawdown - boundary minor" {
  let level = classify_drawdown(-0.05)
  assert_true(level.to_string().contains("Minor"))
}

///|
test "classify_drawdown - boundary moderate" {
  let level = classify_drawdown(-0.1)
  assert_true(level.to_string().contains("Moderate"))
}

///|
test "classify_drawdown - boundary significant" {
  let level = classify_drawdown(-0.2)
  assert_true(level.to_string().contains("Significant"))
}

///|
test "classify_drawdown - boundary severe" {
  let level = classify_drawdown(-0.3)
  assert_true(level.to_string().contains("Severe"))
}

///|
test "DrawdownAlert creation" {
  let alert = DrawdownAlert::{
    warning_threshold: -0.05,
    critical_threshold: -0.15,
    max_threshold: -0.25,
  }
  assert_true(alert.warning_threshold == -0.05)
  assert_true(alert.critical_threshold == -0.15)
  assert_true(alert.max_threshold == -0.25)
}

///|
test "default_alert_config - values" {
  let config = default_alert_config()
  assert_true(config.warning_threshold == -0.1)
  assert_true(config.critical_threshold == -0.2)
  assert_true(config.max_threshold == -0.3)
}

///|
test "check_drawdown_alert - positive value" {
  let config = default_alert_config()
  let result = check_drawdown_alert(0.05, config)
  assert_true(result == "OK: Drawdown within normal range")
}

///|
test "check_drawdown_alert - exact warning threshold" {
  let config = default_alert_config()
  let result = check_drawdown_alert(-0.1, config)
  assert_true(result == "CAUTION: Warning drawdown level reached")
}

///|
test "check_drawdown_alert - exact critical threshold" {
  let config = default_alert_config()
  let result = check_drawdown_alert(-0.2, config)
  assert_true(result == "WARNING: Critical drawdown level reached")
}

///|
test "check_drawdown_alert - exact max threshold" {
  let config = default_alert_config()
  let result = check_drawdown_alert(-0.3, config)
  assert_true(result == "CRITICAL: Maximum drawdown exceeded!")
}

///|
test "DrawdownMonitor creation" {
  let monitor = create_monitor(-0.1, -0.2)
  assert_true(monitor.peak_value == 0.0)
  assert_true(monitor.peak_date == "")
  assert_true(monitor.current_value == 0.0)
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.warning_threshold == -0.1)
  assert_true(monitor.critical_threshold == -0.2)
  assert_true(monitor.alert_triggered == false)
  assert_true(monitor.last_alert_level == "")
}

///|
test "DrawdownMonitor update - basic" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  assert_true(monitor.peak_value == 100.0)
  assert_true(monitor.peak_date == "2024-01-01")
  assert_true(monitor.current_value == 100.0)
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.alert_triggered == false)
}

///|
test "DrawdownMonitor update - peak and decline" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(120.0, "2024-01-02")
  monitor.update(100.0, "2024-01-03")
  assert_true(monitor.peak_value == 120.0)
  assert_true(monitor.peak_date == "2024-01-02")
  assert_true(monitor.current_value == 100.0)
  assert_true(monitor.current_drawdown < -0.16)
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "WARNING")
}

///|
test "DrawdownMonitor update - critical level" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(100.0, "2024-01-02")
  monitor.update(75.0, "2024-01-03")
  // Drawdown = (75-100)/100 = -0.25, which is below -0.2 (critical)
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "CRITICAL")
}

///|
test "DrawdownMonitor get_drawdown" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(90.0, "2024-01-02")
  let dd = monitor.get_drawdown()
  assert_true(dd == -0.1)
}

///|
test "DrawdownMonitor get_info" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(90.0, "2024-01-02")
  let info = monitor.get_info()
  assert_true(info.peak == 100.0)
  assert_true(info.trough == 90.0)
  assert_true(info.peak_date == "2024-01-01")
  assert_true(Float::abs(info.drawdown - -0.1) < 0.0001)
}

///|
test "DrawdownMonitor is_alert_triggered - false" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(95.0, "2024-01-02")
  // Drawdown = -0.05, above warning threshold
  assert_true(monitor.is_alert_triggered() == false)
}

///|
test "DrawdownMonitor is_alert_triggered - true" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(85.0, "2024-01-02")
  // Drawdown = -0.15, below warning threshold
  assert_true(monitor.is_alert_triggered() == true)
}

///|
test "DrawdownMonitor get_alert_level" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(70.0, "2024-01-02")
  // Drawdown = -0.3, critical level
  assert_true(monitor.get_alert_level() == "CRITICAL")
}

///|
test "DrawdownMonitor reset" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(70.0, "2024-01-02")
  monitor.reset()
  assert_true(monitor.peak_value == 0.0)
  assert_true(monitor.peak_date == "")
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.alert_triggered == false)
  assert_true(monitor.last_alert_level == "")
}

///|
test "DrawdownMonitor recovery" {
  let monitor = create_monitor(-0.1, -0.2)
  monitor.update(100.0, "2024-01-01")
  monitor.update(80.0, "2024-01-02")
  monitor.update(110.0, "2024-01-03")
  // New peak at 110, drawdown should be 0
  assert_true(monitor.peak_value == 110.0)
  assert_true(monitor.peak_date == "2024-01-03")
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.alert_triggered == false)
}

///|
test "DrawdownLevel Show derive" {
  assert_true(DrawdownLevel::Normal.to_string().contains("Normal"))
  assert_true(DrawdownLevel::Minor.to_string().contains("Minor"))
  assert_true(DrawdownLevel::Moderate.to_string().contains("Moderate"))
  assert_true(DrawdownLevel::Significant.to_string().contains("Significant"))
  assert_true(DrawdownLevel::Severe.to_string().contains("Severe"))
}
