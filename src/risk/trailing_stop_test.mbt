/// Black-box tests for Trailing Stop risk management

///|
test "create_trailing_stop - basic long position" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),  // entry_price
    Float::from_double(0.10),   // trail_pct (10%)
    true                        // is_long
  )
  assert_true(ts.stop_price > Float::from_double(89.0))
  assert_true(ts.stop_price < Float::from_double(91.0))
  assert_true(ts.trail_pct > Float::from_double(0.09))
  assert_true(ts.trail_pct < Float::from_double(0.11))
}

///|
test "create_trailing_stop - basic short position" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false  // is_long = false for short
  )
  // Short stop should be above entry (100 * 1.1 = 110)
  assert_true(ts.stop_price > Float::from_double(109.0))
  assert_true(ts.stop_price < Float::from_double(111.0))
}

///|
test "trailing_stop_long_update - price rise updates stop" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  // Price rises to 150
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  // Stop should be at 135 (150 * 0.9)
  assert_true(ts1.stop_price > Float::from_double(134.0))
  assert_true(ts1.stop_price < Float::from_double(136.0))
  // highest_price should be updated
  assert_true(ts1.highest_price > Float::from_double(149.0))
}

///|
test "trailing_stop_long_update - price fall does not reduce stop" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  // Price rises to 150 first
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  let initial_stop = ts1.stop_price
  // Price falls to 140 - stop should stay same
  let ts2 = @risk.trailing_stop_long_update(ts1, Float::from_double(140.0))
  assert_true(ts2.stop_price == initial_stop)
}

///|
test "trailing_stop_short_update - price fall updates stop" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  // Price falls to 80
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  // Stop should be at 88 (80 * 1.1)
  assert_true(ts1.stop_price > Float::from_double(87.0))
  assert_true(ts1.stop_price < Float::from_double(89.0))
  // lowest_price should be updated
  assert_true(ts1.lowest_price < Float::from_double(81.0))
}

///|
test "trailing_stop_short_update - price rise does not reduce stop" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  // Price falls to 80 first
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  let initial_stop = ts1.stop_price
  // Price rises to 85 - stop should stay same
  let ts2 = @risk.trailing_stop_short_update(ts1, Float::from_double(85.0))
  assert_true(ts2.stop_price == initial_stop)
}

///|
test "is_stopped_out - long position not stopped" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  // Price at 140, stop at 135 - not stopped
  assert_true(!@risk.is_stopped_out(ts1, Float::from_double(140.0), true))
}

///|
test "is_stopped_out - long position stopped" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  // Price falls to 130, stop at 135 - stopped!
  assert_true(@risk.is_stopped_out(ts1, Float::from_double(130.0), true))
}

///|
test "is_stopped_out - short position not stopped" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  // Price at 85, stop at 88 - not stopped
  assert_true(!@risk.is_stopped_out(ts1, Float::from_double(85.0), false))
}

///|
test "is_stopped_out - short position stopped" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  // Price rises to 90, stop at 88 - stopped!
  assert_true(@risk.is_stopped_out(ts1, Float::from_double(90.0), false))
}

///|
test "get_trailing_stop_status - long active" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  let status = @risk.get_trailing_stop_status(ts, Float::from_double(100.0), Float::from_double(100.0), true)
  assert_true(match status {
    @risk.TrailingStopStatus::Active => true
    _ => false
  })
}

///|
test "get_trailing_stop_status - long profitable" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  let status = @risk.get_trailing_stop_status(ts1, Float::from_double(100.0), Float::from_double(150.0), true)
  assert_true(match status {
    @risk.TrailingStopStatus::Profitable => true
    _ => false
  })
}

///|
test "get_trailing_stop_status - long triggered" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  // Price falls below stop
  let status = @risk.get_trailing_stop_status(ts1, Float::from_double(100.0), Float::from_double(130.0), true)
  assert_true(match status {
    @risk.TrailingStopStatus::Triggered => true
    _ => false
  })
}

///|
test "get_trailing_stop_status - short profitable" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  let status = @risk.get_trailing_stop_status(ts1, Float::from_double(100.0), Float::from_double(80.0), false)
  assert_true(match status {
    @risk.TrailingStopStatus::Profitable => true
    _ => false
  })
}

///|
test "get_trailing_stop_status - short at loss" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  let status = @risk.get_trailing_stop_status(ts, Float::from_double(100.0), Float::from_double(105.0), false)
  assert_true(match status {
    @risk.TrailingStopStatus::AtLoss => true
    _ => false
  })
}

///|
test "get_trailing_stop_status - short triggered" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  // Price rises above stop
  let status = @risk.get_trailing_stop_status(ts1, Float::from_double(100.0), Float::from_double(92.0), false)
  assert_true(match status {
    @risk.TrailingStopStatus::Triggered => true
    _ => false
  })
}

///|
test "trailing stop protects profits - long scenario" {
  // Complete scenario: enter long, price rises, then falls
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )

  // Price rises to 150
  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  // Stop should be at 135 (150 * 0.9)
  assert_true(ts1.stop_price > Float::from_double(134.0))
  assert_true(ts1.stop_price < Float::from_double(136.0))

  // Price falls to 140 - still above stop
  assert_true(!@risk.is_stopped_out(ts1, Float::from_double(140.0), true))

  // Price falls to 130 - stopped out!
  assert_true(@risk.is_stopped_out(ts1, Float::from_double(130.0), true))
}

///|
test "trailing stop protects profits - short scenario" {
  // Complete scenario: enter short, price falls, then rises
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )

  // Price falls to 80
  let ts1 = @risk.trailing_stop_short_update(ts, Float::from_double(80.0))
  // Stop should be at 88 (80 * 1.1)
  assert_true(ts1.stop_price > Float::from_double(87.0))
  assert_true(ts1.stop_price < Float::from_double(89.0))

  // Price rises to 85 - still below stop
  assert_true(!@risk.is_stopped_out(ts1, Float::from_double(85.0), false))

  // Price rises to 90 - stopped out!
  assert_true(@risk.is_stopped_out(ts1, Float::from_double(90.0), false))
}

///|
test "trailing_stop_long_update - initial stop price" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    true
  )
  // Initial stop should be at entry * (1 - trail_pct) = 100 * 0.9 = 90
  assert_true(ts.stop_price > Float::from_double(89.0))
  assert_true(ts.stop_price < Float::from_double(91.0))
}

///|
test "trailing_stop_short_update - initial stop price" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.10),
    false
  )
  // Initial stop should be at entry * (1 + trail_pct) = 100 * 1.1 = 110
  assert_true(ts.stop_price > Float::from_double(109.0))
  assert_true(ts.stop_price < Float::from_double(111.0))
}

///|
test "trailing stop - zero percent handled" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.0),  // Zero stop percent
    true
  )
  // With 0% stop, stop_price should equal entry
  assert_true(ts.stop_price > Float::from_double(99.0))
  assert_true(ts.stop_price < Float::from_double(101.0))
}

///|
test "trailing stop - large percent" {
  let ts = @risk.create_trailing_stop(
    Float::from_double(100.0),
    Float::from_double(0.50),  // 50% stop
    true
  )
  // Stop should be at 50 (100 * 0.5)
  assert_true(ts.stop_price > Float::from_double(49.0))
  assert_true(ts.stop_price < Float::from_double(51.0))
}

///|
test "get_trailing_stop_status - all enum variants" {
  let ts = @risk.create_trailing_stop(Float::from_double(100.0), Float::from_double(0.10), true)
  let s1 = @risk.get_trailing_stop_status(ts, Float::from_double(100.0), Float::from_double(100.0), true)
  assert_true(match s1 {
    @risk.TrailingStopStatus::Active => true
    _ => false
  })

  let ts1 = @risk.trailing_stop_long_update(ts, Float::from_double(150.0))
  let s2 = @risk.get_trailing_stop_status(ts1, Float::from_double(100.0), Float::from_double(150.0), true)
  assert_true(match s2 {
    @risk.TrailingStopStatus::Profitable => true
    _ => false
  })

  let s3 = @risk.get_trailing_stop_status(ts1, Float::from_double(100.0), Float::from_double(130.0), true)
  assert_true(match s3 {
    @risk.TrailingStopStatus::Triggered => true
    _ => false
  })

  let ts_short = @risk.create_trailing_stop(Float::from_double(100.0), Float::from_double(0.10), false)
  let s4 = @risk.get_trailing_stop_status(ts_short, Float::from_double(100.0), Float::from_double(105.0), false)
  assert_true(match s4 {
    @risk.TrailingStopStatus::AtLoss => true
    _ => false
  })
}
