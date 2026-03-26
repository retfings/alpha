/// Black-box tests for drawdown calculator

///|
test "calculate_max_drawdown - basic case" {
  let values : Array[Float] = [
    100.0, 110.0, 120.0, 110.0, 100.0, 90.0, 95.0, 100.0,
  ]
  let max_dd = @drawdown.calculate_max_drawdown(values)
  // Peak=120, Trough=90, Drawdown = (90-120)/120 = -0.25
  inspect(max_dd, content="-0.25")
}

///|
test "calculate_max_drawdown - monotonic increase" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 130.0, 140.0]
  let max_dd = @drawdown.calculate_max_drawdown(values)
  inspect(max_dd, content="0")
}

///|
test "calculate_max_drawdown - empty array" {
  let values : Array[Float] = []
  let max_dd = @drawdown.calculate_max_drawdown(values)
  inspect(max_dd, content="0")
}

///|
test "calculate_current_drawdown - basic case" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 100.0]
  let current_dd = @drawdown.calculate_current_drawdown(values)
  // Peak=120, Current=100, Drawdown = (100-120)/120 = -0.1666...
  inspect(
    current_dd,
    content=(
      #|-0.1666666716337204
    ),
  )
}

///|
test "calculate_drawdown_series - basic case" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 100.0]
  let series = @drawdown.calculate_drawdown_series(values)
  inspect(
    series,
    content=(
      #|[0, 0, 0, -0.0833333358168602, -0.1666666716337204]
    ),
  )
}

///|
test "classify_drawdown - normal" {
  let level = @drawdown.classify_drawdown(-0.03)
  inspect(level, content="Normal")
}

///|
test "classify_drawdown - minor" {
  let level = @drawdown.classify_drawdown(-0.07)
  inspect(level, content="Minor")
}

///|
test "classify_drawdown - moderate" {
  let level = @drawdown.classify_drawdown(-0.15)
  inspect(level, content="Moderate")
}

///|
test "classify_drawdown - significant" {
  let level = @drawdown.classify_drawdown(-0.25)
  inspect(level, content="Significant")
}

///|
test "classify_drawdown - severe" {
  let level = @drawdown.classify_drawdown(-0.35)
  inspect(level, content="Severe")
}

///|
test "check_drawdown_alert - ok" {
  let config = @drawdown.default_alert_config()
  let result = @drawdown.check_drawdown_alert(-0.05, config)
  inspect(result, content="OK: Drawdown within normal range")
}

///|
test "check_drawdown_alert - warning" {
  let config = @drawdown.default_alert_config()
  let result = @drawdown.check_drawdown_alert(-0.12, config)
  inspect(result, content="CAUTION: Warning drawdown level reached")
}

///|
test "check_drawdown_alert - critical" {
  let config = @drawdown.default_alert_config()
  let result = @drawdown.check_drawdown_alert(-0.25, config)
  inspect(result, content="WARNING: Critical drawdown level reached")
}

///|
test "check_drawdown_alert - max exceeded" {
  let config = @drawdown.default_alert_config()
  let result = @drawdown.check_drawdown_alert(-0.35, config)
  inspect(result, content="CRITICAL: Maximum drawdown exceeded!")
}

///|
test "get_drawdown_stats - comprehensive" {
  let values : Array[Float] = [
    100.0, 110.0, 120.0, 110.0, 100.0, 90.0, 95.0, 100.0,
  ]
  let stats = @drawdown.get_drawdown_stats(values)
  inspect(
    stats,
    content=(
      #|{max_drawdown: -0.25, current_drawdown: -0.1666666716337204, avg_drawdown: -0.17499999701976776, drawdown_count: 5}
    ),
  )
}

///|
test "calculate_max_drawdown - single element" {
  let values : Array[Float] = [100.0]
  let max_dd = @drawdown.calculate_max_drawdown(values)
  assert_true(max_dd == 0.0)
}

///|
test "calculate_max_drawdown - two elements decline" {
  let values : Array[Float] = [100.0, 90.0]
  let max_dd = @drawdown.calculate_max_drawdown(values)
  assert_true(max_dd < -0.09 && max_dd > -0.11)
}

///|
test "calculate_max_drawdown - volatile market snapshot" {
  let values : Array[Float] = [
    100.0, 105.0, 102.0, 110.0, 108.0, 95.0, 100.0, 115.0, 112.0, 120.0,
  ]
  let max_dd = @drawdown.calculate_max_drawdown(values)
  // Peak=120, but lowest trough before that is 95 from peak 110
  // Actually peak is 120 at end, but drawdown is from earlier peak
  // Peak=110 (at index 3), Trough=95 (at index 5), DD = (95-110)/110 = -0.136
  assert_true(max_dd < -0.13 && max_dd > -0.14)
}

///|
test "calculate_current_drawdown - at peak" {
  let values : Array[Float] = [100.0, 110.0, 120.0]
  let current_dd = @drawdown.calculate_current_drawdown(values)
  assert_true(current_dd == 0.0)
}

///|
test "calculate_current_drawdown - empty array" {
  let values : Array[Float] = []
  let current_dd = @drawdown.calculate_current_drawdown(values)
  assert_true(current_dd == 0.0)
}

///|
test "calculate_drawdown_series - all zeros for increasing" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 130.0]
  let series = @drawdown.calculate_drawdown_series(values)
  assert_true(series.length() == 4)
  assert_true(series[0] == 0.0)
  assert_true(series[1] == 0.0)
  assert_true(series[2] == 0.0)
  assert_true(series[3] == 0.0)
}

///|
test "calculate_drawdown_series - empty array" {
  let series = @drawdown.calculate_drawdown_series([])
  assert_true(series.length() == 0)
}

///|
test "classify_drawdown - boundary at 5 percent" {
  let level1 = @drawdown.classify_drawdown(-0.05)
  let level2 = @drawdown.classify_drawdown(-0.0499)
  inspect(level1, content="Minor")
  inspect(level2, content="Normal")
}

///|
test "classify_drawdown - boundary at 10 percent" {
  let level1 = @drawdown.classify_drawdown(-0.10)
  let level2 = @drawdown.classify_drawdown(-0.0999)
  inspect(level1, content="Moderate")
  inspect(level2, content="Minor")
}

///|
test "classify_drawdown - boundary at 20 percent" {
  let level1 = @drawdown.classify_drawdown(-0.20)
  let level2 = @drawdown.classify_drawdown(-0.1999)
  inspect(level1, content="Significant")
  inspect(level2, content="Moderate")
}

///|
test "classify_drawdown - boundary at 30 percent" {
  let level1 = @drawdown.classify_drawdown(-0.30)
  let level2 = @drawdown.classify_drawdown(-0.2999)
  inspect(level1, content="Severe")
  inspect(level2, content="Significant")
}

///|
test "classify_drawdown - positive value" {
  let level = @drawdown.classify_drawdown(0.10)
  inspect(level, content="Normal")
}

///|
test "check_drawdown_alert - boundary tests" {
  let config = @drawdown.default_alert_config()
  // At warning threshold (-0.1)
  let result1 = @drawdown.check_drawdown_alert(-0.10, config)
  inspect(result1, content="CAUTION: Warning drawdown level reached")

  // At critical threshold (-0.2)
  let result2 = @drawdown.check_drawdown_alert(-0.20, config)
  inspect(result2, content="WARNING: Critical drawdown level reached")

  // At max threshold (-0.3)
  let result3 = @drawdown.check_drawdown_alert(-0.30, config)
  inspect(result3, content="CRITICAL: Maximum drawdown exceeded!")
}

///|
test "default_alert_config - values" {
  let config = @drawdown.default_alert_config()
  assert_true(config.warning_threshold == -0.1)
  assert_true(config.critical_threshold == -0.2)
  assert_true(config.max_threshold == -0.3)
}

///|
test "calculate_max_drawdown_detailed - basic case" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 100.0, 90.0, 95.0, 100.0]
  let dates : Array[String] = [
    "2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04",
    "2023-01-05", "2023-01-06", "2023-01-07", "2023-01-08",
  ]
  let result = @drawdown.calculate_max_drawdown_detailed(values, dates)
  match result {
    Some(info) => {
      assert_true(info.peak == 120.0)
      assert_true(info.trough == 90.0)
      assert_true(info.peak_date == "2023-01-03")
      assert_true(info.trough_date == "2023-01-06")
      assert_true(info.drawdown < -0.24 && info.drawdown > -0.26)
      assert_true(info.duration == 3)
      assert_true(info.recovered == false)
    }
    None => fail("Expected Some result")
  }
}

///|
test "calculate_max_drawdown_detailed - mismatched arrays" {
  let values : Array[Float] = [100.0, 110.0, 120.0]
  let dates : Array[String] = ["2023-01-01", "2023-01-02"]
  let result = @drawdown.calculate_max_drawdown_detailed(values, dates)
  assert_true(result == None)
}

///|
test "calculate_max_drawdown_detailed - empty arrays" {
  let result = @drawdown.calculate_max_drawdown_detailed([], [])
  assert_true(result == None)
}

///|
test "calculate_max_drawdown_detailed - recovered drawdown" {
  let values : Array[Float] = [100.0, 110.0, 120.0, 110.0, 100.0, 130.0]
  let dates : Array[String] = [
    "2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05",
    "2023-01-06",
  ]
  let result = @drawdown.calculate_max_drawdown_detailed(values, dates)
  match result {
    Some(info) => {
      assert_true(info.recovered == true)
      assert_true(info.peak == 120.0)
      assert_true(info.trough == 100.0)
    }
    None => fail("Expected Some result")
  }
}

///|
test "calculate_drawdown_from_klines - snapshot" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.0, 1000.0, 10000.0, 0.01),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.0, 11.0, 10.0, 11.0, 1100.0, 12100.0, 0.011),
    @data.KLine::daily("sh.600000", "2023-01-03", 11.0, 11.5, 10.5, 10.5, 1200.0, 12600.0, 0.012),
    @data.KLine::daily("sh.600000", "2023-01-04", 10.5, 11.0, 9.0, 9.0, 1300.0, 11700.0, 0.013),
  ]
  let max_dd = @drawdown.calculate_drawdown_from_klines(klines)
  // Peak=11.0, Trough=9.0, DD = (9-11)/11 = -0.1818...
  assert_true(max_dd < -0.18 && max_dd > -0.19)
}
