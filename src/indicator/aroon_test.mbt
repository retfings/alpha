/// Black-box tests for Aroon indicator

///|
test "aroon - basic calculation" {
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 105.0, 115.0, 95.0, 110.0, 1000.0, 110000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 110.0, 120.0, 100.0, 115.0, 1000.0, 120000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 115.0, 125.0, 105.0, 120.0, 1000.0, 130000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 120.0, 130.0, 110.0, 125.0, 1000.0, 140000.0, 0.01),
  ]
  let (up, down) = @indicator.aroon(klines, 3)
  assert_true(up.length() == 5)
  assert_true(down.length() == 5)
  // First 2 should be zero (insufficient data)
  assert_true(up[0] == Float::from_double(0.0))
  assert_true(up[1] == Float::from_double(0.0))
  // In uptrend, Aroon Up should be high
  assert_true(up[4] > Float::from_double(50.0))
}

///|
test "aroon - uptrend detection" {
  // Consistent uptrend: higher highs each day
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 100.0, 110.0, 95.0, 105.0, 1000.0, 110000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 105.0, 115.0, 100.0, 110.0, 1000.0, 120000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 110.0, 120.0, 105.0, 115.0, 1000.0, 130000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 115.0, 125.0, 110.0, 120.0, 1000.0, 140000.0, 0.01),
  ]
  let (up, down) = @indicator.aroon(klines, 3)
  // In strong uptrend, Aroon Up should be 100 (newest high is the highest)
  assert_true(up[4] == Float::from_double(100.0))
}

///|
test "aroon - downtrend detection" {
  // Consistent downtrend: lower lows each day
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 125.0, 130.0, 120.0, 125.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 120.0, 125.0, 115.0, 120.0, 1000.0, 110000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 115.0, 120.0, 110.0, 115.0, 1000.0, 120000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 110.0, 115.0, 105.0, 110.0, 1000.0, 130000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 105.0, 110.0, 100.0, 105.0, 1000.0, 140000.0, 0.01),
  ]
  let (up, down) = @indicator.aroon(klines, 3)
  // In strong downtrend, Aroon Down should be 100 (newest low is the lowest)
  assert_true(down[4] == Float::from_double(100.0))
}

///|
test "aroon - insufficient data" {
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 105.0, 115.0, 95.0, 110.0, 1000.0, 110000.0, 0.01),
  ]
  let (up, down) = @indicator.aroon(klines, 5)
  assert_true(up.length() == 2)
  assert_true(down.length() == 2)
  assert_true(up[0] == Float::from_double(0.0))
  assert_true(up[1] == Float::from_double(0.0))
}

///|
test "aroon - empty klines" {
  let klines : Array[@data.KLine] = []
  let (up, down) = @indicator.aroon(klines, 14)
  assert_true(up.length() == 0)
  assert_true(down.length() == 0)
}

///|
test "aroon_oscillator - basic calculation" {
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 105.0, 115.0, 95.0, 110.0, 1000.0, 110000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 110.0, 120.0, 100.0, 115.0, 1000.0, 120000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 115.0, 125.0, 105.0, 120.0, 1000.0, 130000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 120.0, 130.0, 110.0, 125.0, 1000.0, 140000.0, 0.01),
  ]
  let osc = @indicator.aroon_oscillator(klines, 3)
  assert_true(osc.length() == 5)
  // In uptrend, oscillator should be positive
  assert_true(osc[4] > Float::from_double(0.0))
}

///|
test "aroon_oscillator - range check (-100 to +100)" {
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 105.0, 115.0, 95.0, 110.0, 1000.0, 110000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 110.0, 120.0, 100.0, 115.0, 1000.0, 120000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 115.0, 125.0, 105.0, 120.0, 1000.0, 130000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 120.0, 130.0, 110.0, 125.0, 1000.0, 140000.0, 0.01),
  ]
  let osc = @indicator.aroon_oscillator(klines, 3)
  let len = osc.length()
  let mut i = 0
  while i < len {
    assert_true(osc[i] >= Float::from_double(-100.0) && osc[i] <= Float::from_double(100.0))
    i = i + 1
  }
}

///|
test "is_aroon_uptrend - basic" {
  let up = Float::from_double(80.0)
  let down = Float::from_double(20.0)
  assert_true(@indicator.is_aroon_uptrend(up, down))
}

///|
test "is_aroon_uptrend - downtrend" {
  let up = Float::from_double(20.0)
  let down = Float::from_double(80.0)
  assert_false(@indicator.is_aroon_uptrend(up, down))
}

///|
test "is_aroon_downtrend - basic" {
  let up = Float::from_double(20.0)
  let down = Float::from_double(80.0)
  assert_true(@indicator.is_aroon_downtrend(up, down))
}

///|
test "is_aroon_downtrend - uptrend" {
  let up = Float::from_double(80.0)
  let down = Float::from_double(20.0)
  assert_false(@indicator.is_aroon_downtrend(up, down))
}

///|
test "is_aroon_strong_trend - strong uptrend" {
  let up = Float::from_double(100.0)
  let down = Float::from_double(0.0)
  assert_true(@indicator.is_aroon_strong_trend(up, down))
}

///|
test "is_aroon_strong_trend - strong downtrend" {
  let up = Float::from_double(0.0)
  let down = Float::from_double(100.0)
  assert_true(@indicator.is_aroon_strong_trend(up, down))
}

///|
test "is_aroon_strong_trend - weak trend" {
  let up = Float::from_double(60.0)
  let down = Float::from_double(40.0)
  assert_false(@indicator.is_aroon_strong_trend(up, down))
}

///|
test "is_aroon_consolidation - both low" {
  let up = Float::from_double(30.0)
  let down = Float::from_double(40.0)
  assert_true(@indicator.is_aroon_consolidation(up, down))
}

///|
test "is_aroon_consolidation - trending" {
  let up = Float::from_double(80.0)
  let down = Float::from_double(20.0)
  assert_false(@indicator.is_aroon_consolidation(up, down))
}

///|
test "get_aroon_trend - strong uptrend" {
  let up = Float::from_double(100.0)
  let down = Float::from_double(0.0)
  let trend = @indicator.get_aroon_trend(up, down)
  assert_true(match trend {
    @indicator.AroonTrend::StrongUptrend => true
    _ => false
  })
}

///|
test "get_aroon_trend - strong downtrend" {
  let up = Float::from_double(0.0)
  let down = Float::from_double(100.0)
  let trend = @indicator.get_aroon_trend(up, down)
  assert_true(match trend {
    @indicator.AroonTrend::StrongDowntrend => true
    _ => false
  })
}

///|
test "get_aroon_trend - consolidation" {
  let up = Float::from_double(30.0)
  let down = Float::from_double(40.0)
  let trend = @indicator.get_aroon_trend(up, down)
  assert_true(match trend {
    @indicator.AroonTrend::Consolidation => true
    _ => false
  })
}

///|
test "get_aroon_trend - uptrend" {
  let up = Float::from_double(70.0)
  let down = Float::from_double(30.0)
  let trend = @indicator.get_aroon_trend(up, down)
  assert_true(match trend {
    @indicator.AroonTrend::Uptrend => true
    _ => false
  })
}

///|
test "get_aroon_trend - downtrend" {
  let up = Float::from_double(30.0)
  let down = Float::from_double(70.0)
  let trend = @indicator.get_aroon_trend(up, down)
  assert_true(match trend {
    @indicator.AroonTrend::Downtrend => true
    _ => false
  })
}

///|
test "aroon - snapshot test" {
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 105.0, 115.0, 95.0, 110.0, 1000.0, 110000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 110.0, 120.0, 100.0, 115.0, 1000.0, 120000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 115.0, 125.0, 105.0, 120.0, 1000.0, 130000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 120.0, 130.0, 110.0, 125.0, 1000.0, 140000.0, 0.01),
    @data.KLine::daily("test", "2024-01-06", 125.0, 135.0, 115.0, 130.0, 1000.0, 150000.0, 0.01),
    @data.KLine::daily("test", "2024-01-07", 130.0, 140.0, 120.0, 135.0, 1000.0, 160000.0, 0.01),
  ]
  let (up, down) = @indicator.aroon(klines, 5)
  assert_true(up.length() == 7)
  assert_true(down.length() == 7)
  // Verify values are in valid range
  let mut i = 0
  while i < 7 {
    assert_true(up[i] >= Float::from_double(0.0) && up[i] <= Float::from_double(100.0))
    assert_true(down[i] >= Float::from_double(0.0) && down[i] <= Float::from_double(100.0))
    i = i + 1
  }
}

///|
test "aroon_oscillator - snapshot test" {
  let klines = [
    @data.KLine::daily("test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01),
    @data.KLine::daily("test", "2024-01-02", 100.0, 105.0, 95.0, 102.0, 1000.0, 102000.0, 0.01),
    @data.KLine::daily("test", "2024-01-03", 102.0, 108.0, 98.0, 105.0, 1000.0, 105000.0, 0.01),
    @data.KLine::daily("test", "2024-01-04", 105.0, 110.0, 100.0, 108.0, 1000.0, 108000.0, 0.01),
    @data.KLine::daily("test", "2024-01-05", 108.0, 112.0, 102.0, 110.0, 1000.0, 110000.0, 0.01),
  ]
  let osc = @indicator.aroon_oscillator(klines, 3)
  assert_true(osc.length() == 5)
  // Values should be in valid range
  let mut i = 0
  while i < 5 {
    assert_true(osc[i] >= Float::from_double(-100.0) && osc[i] <= Float::from_double(100.0))
    i = i + 1
  }
}
