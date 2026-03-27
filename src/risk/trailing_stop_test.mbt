/// Trailing Stop risk management tests

///|
test "create_trailing_stop - long position" {
  let ts = @risk.create_trailing_stop(100.0, 0.05, true)
  assert_true(ts.stop_price > 94.0)
  assert_true(ts.stop_price < 96.0)
}

///|
test "create_trailing_stop - short position" {
  let ts = @risk.create_trailing_stop(100.0, 0.05, false)
  assert_true(ts.stop_price > 104.0)
  assert_true(ts.stop_price < 106.0)
}

///|
test "trailing_stop_long_update - price increases" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, true)
  let ts1 = @risk.trailing_stop_long_update(ts, 110.0)
  assert_eq(ts1.highest_price, 110.0)
  assert_true(ts1.stop_price > 98.0)
  assert_true(ts1.stop_price < 100.0)
}

///|
test "trailing_stop_long_update - stop_does_not_decrease" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, true)
  let ts1 = @risk.trailing_stop_long_update(ts, 110.0)
  let stop_after_rise = ts1.stop_price
  let ts2 = @risk.trailing_stop_long_update(ts1, 105.0)
  assert_eq(ts2.stop_price, stop_after_rise)
}

///|
test "trailing_stop_short_update - price decreases" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, false)
  let ts1 = @risk.trailing_stop_short_update(ts, 90.0)
  assert_eq(ts1.lowest_price, 90.0)
  assert_true(ts1.stop_price > 98.0)
}

///|
test "trailing_stop_short_update - stop_does_not_increase" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, false)
  let ts1 = @risk.trailing_stop_short_update(ts, 90.0)
  let stop_after_fall = ts1.stop_price
  let ts2 = @risk.trailing_stop_short_update(ts1, 95.0)
  assert_eq(ts2.stop_price, stop_after_fall)
}

///|
test "is_stopped_out - long position" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, true)
  assert_true(!@risk.is_stopped_out(ts, 95.0, true))
  assert_true(@risk.is_stopped_out(ts, 89.0, true))
}

///|
test "is_stopped_out - short position" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, false)
  assert_true(!@risk.is_stopped_out(ts, 105.0, false))
  assert_true(@risk.is_stopped_out(ts, 111.0, false))
}

///|
test "atr_trailing_stop - long" {
  let stop = @risk.atr_trailing_stop(100.0, 90.0, 5.0, 2.0, true)
  assert_eq(stop, 90.0)
}

///|
test "atr_trailing_stop - short" {
  let stop = @risk.atr_trailing_stop(110.0, 100.0, 5.0, 2.0, false)
  assert_eq(stop, 110.0)
}

///|
test "create_atr_trailing_stop - long" {
  let ts = @risk.create_atr_trailing_stop(100.0, 3.0, 2.0, true)
  assert_true(ts.stop_price > 93.0)
  assert_true(ts.stop_price < 95.0)
}

///|
test "create_atr_trailing_stop - short" {
  let ts = @risk.create_atr_trailing_stop(100.0, 3.0, 2.0, false)
  assert_true(ts.stop_price > 105.0)
  assert_true(ts.stop_price < 107.0)
}

///|
test "trailing_stop_distance - long profitable" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, true)
  let ts1 = @risk.trailing_stop_long_update(ts, 120.0)
  let distance = @risk.trailing_stop_distance(ts1, 120.0)
  assert_true(distance > 0.09)
  assert_true(distance < 0.11)
}

///|
test "trailing_stop_profit_lock - long" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, true)
  let ts1 = @risk.trailing_stop_long_update(ts, 150.0)
  assert_true(ts1.stop_price > 134.0)
  assert_true(ts1.stop_price < 136.0)
  assert_true(!@risk.is_stopped_out(ts1, 140.0, true))
  assert_true(@risk.is_stopped_out(ts1, 130.0, true))
}

///|
test "trailing_stop_profit_lock - short" {
  let ts = @risk.create_trailing_stop(100.0, 0.10, false)
  let ts1 = @risk.trailing_stop_short_update(ts, 70.0)
  assert_true(ts1.stop_price > 76.0)
  assert_true(ts1.stop_price < 78.0)
  assert_true(!@risk.is_stopped_out(ts1, 75.0, false))
  assert_true(@risk.is_stopped_out(ts1, 80.0, false))
}

///|
test "trail_percentage_comparison" {
  let ts_tight = @risk.create_trailing_stop(100.0, 0.05, true)
  let ts_loose = @risk.create_trailing_stop(100.0, 0.20, true)
  assert_true(ts_tight.stop_price > ts_loose.stop_price)
}
