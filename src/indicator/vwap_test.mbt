/// VWAP (Volume-Weighted Average Price) indicator tests

///|
test "vwap - basic calculation" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.8, 10.0, 10.5, 1200.0, 12000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.5, 11.0, 10.3, 10.8, 800.0, 8500.0, 0.04,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.5, 11.0, 1500.0, 16000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.2, 1100.0, 12000.0, 0.055,
    ),
  ]

  let vwap_values = @indicator.vwap(klines)

  // Should have same length as input
  assert_eq(vwap_values.length(), 5)

  // First VWAP should be typical price of first kline
  // TP1 = (10.5 + 9.5 + 10.0) / 3 = 10.0
  // VWAP1 = (10.0 * 1000) / 1000 = 10.0
  assert_eq(vwap_values[0], 10.0)

  // VWAP should change as cumulative calculation progresses
  assert_true(vwap_values[1] > vwap_values[0])
}

///|
test "vwap - empty klines" {
  let klines : Array[@data.KLine] = []
  let vwap_values = @indicator.vwap(klines)
  assert_eq(vwap_values.length(), 0)
}

///|
test "vwap - single kline" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 10.5, 1000.0, 10000.0, 0.05,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)
  assert_eq(vwap_values.length(), 1)

  // VWAP should equal typical price for single kline
  // TP = (11.0 + 9.0 + 10.5) / 3 = 10.1666...
  assert_true(vwap_values[0] > 10.0)
  assert_true(vwap_values[0] < 10.5)
}

///|
test "vwap - constant price and volume" {
  // When price and volume are constant, VWAP should converge to that price
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.0, 10.0, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.0, 10.0, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.0, 10.0, 10.0, 10.0, 1000.0, 10000.0, 0.05,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)

  // All VWAP values should be 10.0 (constant price)
  assert_eq(vwap_values[0], 10.0)
  assert_eq(vwap_values[1], 10.0)
  assert_eq(vwap_values[2], 10.0)
}

///|
test "vwap - uptrend produces rising vwap" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 10.0, 10.3, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.3, 11.0, 10.3, 10.8, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.8, 11.5, 10.8, 11.3, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.3, 12.0, 11.3, 11.8, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.8, 12.5, 11.8, 12.3, 1000.0, 10000.0, 0.05,
    ),
  ]

  let vwap_values = @indicator.vwap(klines)

  // VWAP should rise in uptrend
  assert_true(vwap_values[4] > vwap_values[3])
  assert_true(vwap_values[3] > vwap_values[2])
  assert_true(vwap_values[2] > vwap_values[1])
  assert_true(vwap_values[1] > vwap_values[0])
}

///|
test "vwap - downtrend produces falling vwap" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 12.0, 12.5, 12.0, 12.3, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 12.3, 12.3, 11.5, 11.8, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.8, 11.8, 11.0, 11.3, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.3, 11.3, 10.5, 10.8, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 10.8, 10.8, 10.0, 10.3, 1000.0, 10000.0, 0.05,
    ),
  ]

  let vwap_values = @indicator.vwap(klines)

  // VWAP should fall in downtrend
  assert_true(vwap_values[4] < vwap_values[3])
  assert_true(vwap_values[3] < vwap_values[2])
  assert_true(vwap_values[2] < vwap_values[1])
  assert_true(vwap_values[1] < vwap_values[0])
}

///|
test "vwap - high volume bars have more influence" {
  // First bar: low price, low volume
  // Second bar: high price, high volume
  // VWAP should be closer to second bar's price
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.0, 10.0, 10.0, 100.0, 1000.0, 0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 20.0, 20.0, 20.0, 20.0, 10000.0, 200000.0, 0.5,
    ),
  ]

  let vwap_values = @indicator.vwap(klines)

  // VWAP should be much closer to 20.0 due to high volume
  assert_true(vwap_values[1] > 19.0)
  assert_true(vwap_values[1] < 20.0)
}

///|
test "vwap_with_reset - basic reset behavior" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.8, 10.0, 10.5, 1200.0, 12000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.5, 11.0, 10.3, 10.8, 800.0, 8500.0, 0.04,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.5, 11.0, 1500.0, 16000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.2, 1100.0, 12000.0, 0.055,
    ),
  ]

  // Reset every 3 periods
  let vwap_reset = @indicator.vwap_with_reset(klines, 3)
  let vwap_normal = @indicator.vwap(klines)

  // First 3 values should be same
  assert_eq(vwap_reset[0], vwap_normal[0])
  assert_eq(vwap_reset[1], vwap_normal[1])
  assert_eq(vwap_reset[2], vwap_normal[2])

  // 4th value should differ (reset happened)
  assert_true(vwap_reset[3] != vwap_normal[3])
}

///|
test "vwap_with_reset - reset at period boundary" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.0, 10.0, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.0, 10.0, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.0, 10.0, 10.0, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 20.0, 20.0, 20.0, 20.0, 1000.0, 20000.0, 0.1,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 20.0, 20.0, 20.0, 20.0, 1000.0, 20000.0, 0.1,
    ),
  ]

  // Reset every 3 periods
  let vwap_values = @indicator.vwap_with_reset(klines, 3)

  // After reset, VWAP should be based on new period only
  // Period 2 starts at index 3 with price 20.0
  assert_eq(vwap_values[3], 20.0)
}

///|
test "vwap_bands - basic calculation" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.8, 10.0, 10.5, 1200.0, 12000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.5, 11.0, 10.3, 10.8, 800.0, 8500.0, 0.04,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.5, 11.0, 1500.0, 16000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.2, 1100.0, 12000.0, 0.055,
    ),
  ]

  let (upper, vwap, lower) = @indicator.vwap_bands(klines, 3, 2.0)

  assert_eq(upper.length(), 5)
  assert_eq(vwap.length(), 5)
  assert_eq(lower.length(), 5)

  // First 2 values should be zero (insufficient data for period 3)
  assert_eq(upper[0], 0.0)
  assert_eq(upper[1], 0.0)
  assert_eq(lower[0], 0.0)
  assert_eq(lower[1], 0.0)

  // From index 2 onwards should have valid bands
  assert_true(upper[2] > 0.0)
  assert_true(lower[2] > 0.0)
}

///|
test "vwap_bands - band ordering (lower <= vwap <= upper)" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.8, 10.0, 10.5, 1200.0, 12000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.5, 11.0, 10.3, 10.8, 800.0, 8500.0, 0.04,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.5, 11.0, 1500.0, 16000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.2, 1100.0, 12000.0, 0.055,
    ),
  ]

  let (upper, vwap, lower) = @indicator.vwap_bands(klines, 3, 2.0)

  // Verify band ordering for valid values
  let mut i = 2
  while i < 5 {
    assert_true(lower[i] <= vwap[i])
    assert_true(vwap[i] <= upper[i])
    i = i + 1
  }
}

///|
test "vwap_bands - higher multiplier produces wider bands" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 10.0, 1000.0, 10000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.8, 10.0, 10.5, 1200.0, 12000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.5, 11.0, 10.3, 10.8, 800.0, 8500.0, 0.04,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.8, 11.2, 10.5, 11.0, 1500.0, 16000.0, 0.075,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 11.0, 11.5, 10.8, 11.2, 1100.0, 12000.0, 0.055,
    ),
  ]

  let (upper1, _, lower1) = @indicator.vwap_bands(klines, 3, 1.0)
  let (upper2, _, lower2) = @indicator.vwap_bands(klines, 3, 2.0)

  // Higher multiplier should produce wider bands
  let width1 = upper1[4] - lower1[4]
  let width2 = upper2[4] - lower2[4]
  assert_true(width2 > width1)
}

///|
test "is_above_vwap - price above" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 10.5, 1000.0, 10000.0, 0.05,
  )
  assert_true(@indicator.is_above_vwap(kline, 10.0))
  assert_true(@indicator.is_above_vwap(kline, 9.0))
}

///|
test "is_above_vwap - price at or below" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 10.5, 1000.0, 10000.0, 0.05,
  )
  assert_true(!@indicator.is_above_vwap(kline, 10.5))
  assert_true(!@indicator.is_above_vwap(kline, 11.0))
}

///|
test "is_below_vwap - price below" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 10.5, 1000.0, 10000.0, 0.05,
  )
  assert_true(@indicator.is_below_vwap(kline, 11.0))
  assert_true(@indicator.is_below_vwap(kline, 12.0))
}

///|
test "is_below_vwap - price at or above" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 10.5, 1000.0, 10000.0, 0.05,
  )
  assert_true(!@indicator.is_below_vwap(kline, 10.5))
  assert_true(!@indicator.is_below_vwap(kline, 10.0))
}

///|
test "vwap_deviation - positive deviation" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 110.0, 1000.0, 10000.0, 0.05,
  )
  let deviation = @indicator.vwap_deviation(kline, 100.0)
  // (110 - 100) / 100 * 100 = 10%
  assert_true(deviation > 9.0)
  assert_true(deviation < 11.0)
}

///|
test "vwap_deviation - negative deviation" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 90.0, 1000.0, 10000.0, 0.05,
  )
  let deviation = @indicator.vwap_deviation(kline, 100.0)
  // (90 - 100) / 100 * 100 = -10%
  assert_true(deviation < -9.0)
  assert_true(deviation > -11.0)
}

///|
test "vwap_deviation - zero vwap returns 0" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 100.0, 1000.0, 10000.0, 0.05,
  )
  let deviation = @indicator.vwap_deviation(kline, 0.0)
  assert_eq(deviation, 0.0)
}

///|
test "vwap_position - above vwap" {
  let kline = @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 110.0, 1000.0, 10000.0, 0.05)
  let pos = @indicator.vwap_position(kline, 100.0)
  assert_true(match pos { @indicator.VwapPosition::Above => true | _ => false })
}

///|
test "vwap_position - below vwap" {
  let kline = @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 90.0, 1000.0, 10000.0, 0.05)
  let pos = @indicator.vwap_position(kline, 100.0)
  assert_true(match pos { @indicator.VwapPosition::Below => true | _ => false })
}

///|
test "vwap_position - equal to vwap" {
  let kline = @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.0, 100.0, 1000.0, 10000.0, 0.05)
  let pos = @indicator.vwap_position(kline, 100.0)
  assert_true(match pos { @indicator.VwapPosition::Equal => true | _ => false })
}

///|
test "typical_price calculation" {
  // Typical price = (H + L + C) / 3
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 12.0, 8.0, 10.0, 1000.0, 10000.0, 0.05,
  )
  // TP = (12 + 8 + 10) / 3 = 10
  assert_eq(@indicator.typical_price(kline), 10.0)
}
