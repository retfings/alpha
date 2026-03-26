/// Black-box tests for drawdown monitor module

///|
test "create_monitor - initial state" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  assert_true(monitor.peak_value == 0.0)
  assert_true(monitor.peak_date == "")
  assert_true(monitor.current_value == 0.0)
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.alert_triggered == false)
  assert_true(monitor.last_alert_level == "")
}

///|
test "DrawdownMonitor::update - first value sets peak" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  assert_true(monitor.peak_value == 100000.0)
  assert_true(monitor.peak_date == "2023-01-01")
  assert_true(monitor.current_value == 100000.0)
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.alert_triggered == false)
}

///|
test "DrawdownMonitor::update - value decline triggers drawdown" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(95000.0, "2023-01-02")
  assert_true(monitor.peak_value == 100000.0)
  assert_true(monitor.current_value == 95000.0)
  assert_true(
    monitor.current_drawdown < -0.04 && monitor.current_drawdown > -0.06,
  )
}

///|
test "DrawdownMonitor::update - value increase updates peak" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(110000.0, "2023-01-02")
  assert_true(monitor.peak_value == 110000.0)
  assert_true(monitor.peak_date == "2023-01-02")
  assert_true(monitor.current_value == 110000.0)
  assert_true(monitor.current_drawdown == 0.0)
}

///|
test "DrawdownMonitor::update - warning alert triggered" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(88000.0, "2023-01-02") // 12% drawdown
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "WARNING")
}

///|
test "DrawdownMonitor::update - critical alert triggered" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(75000.0, "2023-01-02") // 25% drawdown
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "CRITICAL")
}

///|
test "DrawdownMonitor::update - alert status changes with recovery" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(88000.0, "2023-01-02") // Warning triggered (12% drawdown)
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "WARNING")

  monitor.update(92000.0, "2023-01-03") // 8% drawdown, above warning threshold (-0.08 > -0.1)
  assert_true(monitor.alert_triggered == false) // Alert cleared
  assert_true(monitor.last_alert_level == "")
}

///|
test "DrawdownMonitor::update - full recovery resets alert" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(88000.0, "2023-01-02") // Warning triggered
  monitor.update(105000.0, "2023-01-03") // New peak
  assert_true(monitor.alert_triggered == false)
  assert_true(monitor.last_alert_level == "")
  assert_true(monitor.peak_value == 105000.0)
}

///|
test "DrawdownMonitor::get_drawdown - accurate calculation" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(90000.0, "2023-01-02")
  let dd = monitor.get_drawdown()
  assert_true(dd < -0.09 && dd > -0.11)
}

///|
test "DrawdownMonitor::get_drawdown - empty state" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  let dd = monitor.get_drawdown()
  assert_true(dd == 0.0)
}

///|
test "DrawdownMonitor::get_info - returns valid info" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(90000.0, "2023-01-02")
  let info = monitor.get_info()
  assert_true(info.peak == 100000.0)
  assert_true(info.trough == 90000.0)
  assert_true(info.peak_date == "2023-01-01")
  assert_true(info.drawdown < -0.09 && info.drawdown > -0.11)
}

///|
test "DrawdownMonitor::is_alert_triggered - no alert initially" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  assert_true(monitor.is_alert_triggered() == false)
}

///|
test "DrawdownMonitor::is_alert_triggered - alert after decline" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(85000.0, "2023-01-02")
  assert_true(monitor.is_alert_triggered() == true)
}

///|
test "DrawdownMonitor::get_alert_level - empty initially" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  assert_true(monitor.get_alert_level() == "")
}

///|
test "DrawdownMonitor::get_alert_level - warning level" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(88000.0, "2023-01-02")
  assert_true(monitor.get_alert_level() == "WARNING")
}

///|
test "DrawdownMonitor::get_alert_level - critical level" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(75000.0, "2023-01-02")
  assert_true(monitor.get_alert_level() == "CRITICAL")
}

///|
test "DrawdownMonitor::reset - clears all state" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(75000.0, "2023-01-02") // Critical alert
  monitor.reset()
  assert_true(monitor.peak_value == 0.0)
  assert_true(monitor.peak_date == "")
  assert_true(monitor.current_drawdown == 0.0)
  assert_true(monitor.alert_triggered == false)
  assert_true(monitor.last_alert_level == "")
}

///|
test "DrawdownMonitor::reset - allows fresh start" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(75000.0, "2023-01-02")
  monitor.reset()
  monitor.update(50000.0, "2023-02-01")
  assert_true(monitor.peak_value == 50000.0)
  assert_true(monitor.peak_date == "2023-02-01")
}

///|
test "DrawdownMonitor - boundary: exactly at warning threshold" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(90000.0, "2023-01-02") // Exactly 10% drawdown
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "WARNING")
}

///|
test "DrawdownMonitor - boundary: exactly at critical threshold" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(80000.0, "2023-01-02") // Exactly 20% drawdown
  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "CRITICAL")
}

///|
test "DrawdownMonitor - gradual decline with multiple updates" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(98000.0, "2023-01-02") // 2%
  monitor.update(95000.0, "2023-01-03") // 5%
  monitor.update(92000.0, "2023-01-04") // 8%
  monitor.update(89000.0, "2023-01-05") // 11% - warning
  monitor.update(78000.0, "2023-01-06") // 22% - critical

  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "CRITICAL")
  assert_true(monitor.peak_date == "2023-01-01")
}

///|
test "DrawdownMonitor - volatile market with new peak" {
  let monitor = @drawdown.create_monitor(-0.1, -0.2)
  monitor.update(100000.0, "2023-01-01")
  monitor.update(95000.0, "2023-01-02") // -5%
  monitor.update(105000.0, "2023-01-03") // New peak
  monitor.update(100000.0, "2023-01-04") // -4.76% from new peak

  assert_true(monitor.peak_value == 105000.0)
  assert_true(monitor.peak_date == "2023-01-03")
  assert_true(monitor.alert_triggered == false)
}

///|
test "DrawdownMonitor - custom thresholds" {
  let monitor = @drawdown.create_monitor(-0.05, -0.15) // Stricter thresholds
  monitor.update(100000.0, "2023-01-01")
  monitor.update(93000.0, "2023-01-02") // 7% - should trigger warning with custom threshold

  assert_true(monitor.alert_triggered == true)
  assert_true(monitor.last_alert_level == "WARNING")
}
