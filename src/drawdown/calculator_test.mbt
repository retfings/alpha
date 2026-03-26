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
