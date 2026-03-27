/// Black-box tests for VWAP (Volume-Weighted Average Price) indicator

///|
test "vwap - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 110.0, 90.0, 105.0, 2000.0, 210000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 105.0, 115.0, 95.0, 110.0, 1500.0, 165000.0, 0.01,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)

  assert_eq(vwap_values.length(), 3)

  // First VWAP = typical price of first bar
  // TP1 = (110 + 90 + 100) / 3 = 100
  assert_true(
    vwap_values[0] > Float::from_double(99.0) &&
    vwap_values[0] < Float::from_double(101.0),
  )

  // Second VWAP = (TP1*V1 + TP2*V2) / (V1 + V2)
  // TP2 = (110 + 90 + 105) / 3 = 101.67
  // VWAP = (100*1000 + 101.67*2000) / 3000 = 101.11
  assert_true(vwap_values[1] > Float::from_double(100.0))
}

///|
test "vwap - empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let vwap_values = @indicator.vwap(klines)
  assert_eq(vwap_values.length(), 0)
}

///|
test "vwap - single kline" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)
  assert_eq(vwap_values.length(), 1)
  // VWAP = typical price = (110 + 90 + 105) / 3 = 101.67
  assert_true(
    vwap_values[0] > Float::from_double(100.0) &&
    vwap_values[0] < Float::from_double(103.0),
  )
}

///|
test "vwap - cumulative calculation" {
  // VWAP should accumulate throughout the day
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)

  // With constant typical price and volume, VWAP should remain constant
  let mut i = 0
  while i < vwap_values.length() {
    assert_true(
      vwap_values[i] > Float::from_double(99.0) &&
      vwap_values[i] < Float::from_double(101.0),
    )
    i = i + 1
  }
}

///|
test "vwap - price above vwap" {
  // When prices rise, VWAP should lag behind
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 102.0, 98.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 99.0, 103.0, 1000.0, 103000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 103.0, 108.0, 102.0, 106.0, 1000.0, 106000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 106.0, 111.0, 105.0, 109.0, 1000.0, 109000.0, 0.01,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)

  // Last close should be above VWAP in uptrend
  assert_true(klines[3].close > vwap_values[3])
}

///|
test "vwap - price below vwap" {
  // When prices fall, VWAP should be above current price
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 108.0, 112.0, 106.0, 110.0, 1000.0, 110000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 107.0, 110.0, 105.0, 107.0, 1000.0, 107000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 104.0, 107.0, 102.0, 104.0, 1000.0, 104000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 101.0, 104.0, 99.0, 101.0, 1000.0, 101000.0, 0.01,
    ),
  ]
  let vwap_values = @indicator.vwap(klines)

  // Last close should be below VWAP in downtrend
  assert_true(klines[3].close < vwap_values[3])
}

///|
test "vwap_with_reset - basic reset" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  // Reset every 2 periods
  let vwap_values = @indicator.vwap_with_reset(klines, 2)

  assert_eq(vwap_values.length(), 5)

  // VWAP should reset at index 2 and 4
  // At reset points, VWAP should equal typical price of that bar
  assert_true(vwap_values[0] > Float::from_double(99.0))
  assert_true(vwap_values[2] > Float::from_double(99.0))
  assert_true(vwap_values[4] > Float::from_double(99.0))
}

///|
test "vwap_with_reset - empty klines" {
  let klines : Array[@data.KLine] = []
  let vwap_values = @indicator.vwap_with_reset(klines, 20)
  assert_eq(vwap_values.length(), 0)
}

///|
test "vwap_with_reset - period larger than data" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 105.0, 1000.0, 105000.0, 0.01,
    ),
  ]
  let vwap_values = @indicator.vwap_with_reset(klines, 10)

  // Should calculate normally without reset
  assert_eq(vwap_values.length(), 2)
  assert_true(vwap_values[1] > vwap_values[0])
}

///|
test "vwap_bands - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 101.0, 1000.0, 101000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 105.0, 95.0, 102.0, 1000.0, 102000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 100.0, 105.0, 95.0, 103.0, 1000.0, 103000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 100.0, 105.0, 95.0, 104.0, 1000.0, 104000.0, 0.01,
    ),
  ]

  let (upper, vwap, lower) = @indicator.vwap_bands(
    klines,
    3,
    Float::from_double(2.0),
  )

  assert_eq(upper.length(), 5)
  assert_eq(vwap.length(), 5)
  assert_eq(lower.length(), 5)

  // First 2 values should be zero (insufficient data for period 3)
  assert_eq(upper[0], Float::from_double(0.0))
  assert_eq(upper[1], Float::from_double(0.0))

  // From index 2 onwards should have valid values
  assert_true(upper[2] > Float::from_double(0.0))
  assert_true(lower[2] > Float::from_double(0.0))
}

///|
test "vwap_bands - band ordering" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 110.0, 90.0, 102.0, 1000.0, 102000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 110.0, 90.0, 104.0, 1000.0, 104000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 100.0, 110.0, 90.0, 106.0, 1000.0, 106000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 100.0, 110.0, 90.0, 108.0, 1000.0, 108000.0, 0.01,
    ),
  ]

  let (upper, vwap, lower) = @indicator.vwap_bands(
    klines,
    3,
    Float::from_double(2.0),
  )

  // Verify upper >= vwap >= lower for valid values
  let mut i = 2
  while i < 5 {
    assert_true(upper[i] >= vwap[i])
    assert_true(vwap[i] >= lower[i])
    i = i + 1
  }
}

///|
test "vwap_bands - empty klines" {
  let klines : Array[@data.KLine] = []
  let (upper, vwap, lower) = @indicator.vwap_bands(
    klines,
    20,
    Float::from_double(2.0),
  )

  assert_eq(upper.length(), 0)
  assert_eq(vwap.length(), 0)
  assert_eq(lower.length(), 0)
}

///|
test "vwap_bands - multiplier effect" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 110.0, 90.0, 102.0, 1000.0, 102000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 110.0, 90.0, 104.0, 1000.0, 104000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 100.0, 110.0, 90.0, 106.0, 1000.0, 106000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 100.0, 110.0, 90.0, 108.0, 1000.0, 108000.0, 0.01,
    ),
  ]

  let (upper1, vwap1, lower1) = @indicator.vwap_bands(
    klines,
    3,
    Float::from_double(1.0),
  )
  let (upper2, vwap2, lower2) = @indicator.vwap_bands(
    klines,
    3,
    Float::from_double(2.0),
  )

  // VWAP should be same regardless of multiplier
  assert_eq(vwap1[4], vwap2[4])

  // Higher multiplier should produce wider bands
  let width1 = upper1[4] - lower1[4]
  let width2 = upper2[4] - lower2[4]
  assert_true(width2 > width1)
}

///|
test "is_above_vwap - price above" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01,
  )
  let vwap = Float::from_double(100.0)
  assert_true(@indicator.is_above_vwap(kline, vwap))
}

///|
test "is_above_vwap - price at or below" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
  )
  assert_true(!@indicator.is_above_vwap(kline, Float::from_double(100.0)))
  assert_true(!@indicator.is_above_vwap(kline, Float::from_double(105.0)))
}

///|
test "is_below_vwap - price below" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 95.0, 1000.0, 100000.0, 0.01,
  )
  let vwap = Float::from_double(100.0)
  assert_true(@indicator.is_below_vwap(kline, vwap))
}

///|
test "is_below_vwap - price at or above" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
  )
  assert_true(!@indicator.is_below_vwap(kline, Float::from_double(100.0)))
  assert_true(!@indicator.is_below_vwap(kline, Float::from_double(95.0)))
}

///|
test "vwap_deviation - positive deviation" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 110.0, 1000.0, 100000.0, 0.01,
  )
  let vwap = Float::from_double(100.0)
  let dev = @indicator.vwap_deviation(kline, vwap)
  // (110 - 100) / 100 * 100 = 10%
  assert_true(dev > Float::from_double(9.0) && dev < Float::from_double(11.0))
}

///|
test "vwap_deviation - negative deviation" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 90.0, 1000.0, 100000.0, 0.01,
  )
  let vwap = Float::from_double(100.0)
  let dev = @indicator.vwap_deviation(kline, vwap)
  // (90 - 100) / 100 * 100 = -10%
  assert_true(dev < Float::from_double(-9.0) && dev > Float::from_double(-11.0))
}

///|
test "vwap_deviation - zero vwap returns 0" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
  )
  let dev = @indicator.vwap_deviation(kline, Float::from_double(0.0))
  assert_eq(dev, Float::from_double(0.0))
}

///|
test "vwap_position - above vwap" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01,
  )
  let pos = @indicator.vwap_position(kline, Float::from_double(100.0))
  assert_true(
    match pos {
      @indicator.VwapPosition::Above => true
      _ => false
    },
  )
}

///|
test "vwap_position - below vwap" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 95.0, 1000.0, 100000.0, 0.01,
  )
  let pos = @indicator.vwap_position(kline, Float::from_double(100.0))
  assert_true(
    match pos {
      @indicator.VwapPosition::Below => true
      _ => false
    },
  )
}

///|
test "vwap_position - equal to vwap" {
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 110.0, 90.0, 100.0, 1000.0, 100000.0, 0.01,
  )
  let pos = @indicator.vwap_position(kline, Float::from_double(100.0))
  assert_true(
    match pos {
      @indicator.VwapPosition::Equal => true
      _ => false
    },
  )
}

///|
test "typical price calculation - consistent formula" {
  // Verify typical price = (high + low + close) / 3
  let kline = @data.KLine::daily(
    "test", "2024-01-01", 100.0, 120.0, 80.0, 100.0, 1000.0, 100000.0, 0.01,
  )
  // TP = (120 + 80 + 100) / 3 = 100
  let tp = (kline.high + kline.low + kline.close) / Float::from_double(3.0)
  assert_true(tp > Float::from_double(99.0) && tp < Float::from_double(101.0))
}

///|
test "vwap - volume weighted calculation" {
  // Higher volume bars should have more influence on VWAP
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 100.0, 10000.0, 0.01,
    ), // Low vol, TP=100
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 110.0, 10000.0, 1100000.0, 0.01,
    ), // High vol, TP=103.33
  ]
  let vwap_values = @indicator.vwap(klines)

  // VWAP should be closer to second bar's typical price due to higher volume
  // TP1 = (105+95+100)/3 = 100, V1 = 100
  // TP2 = (105+95+110)/3 = 103.33, V2 = 10000
  // VWAP = (100*100 + 103.33*10000) / (100 + 10000) = 103.32
  assert_true(vwap_values[1] > Float::from_double(103.0))
}

///|
test "vwap_bands - snapshot test" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 101.0, 1000.0, 101000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 105.0, 95.0, 102.0, 1000.0, 102000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 100.0, 105.0, 95.0, 103.0, 1000.0, 103000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 100.0, 105.0, 95.0, 104.0, 1000.0, 104000.0, 0.01,
    ),
  ]

  let (upper, vwap, lower) = @indicator.vwap_bands(
    klines,
    3,
    Float::from_double(2.0),
  )

  assert_eq(upper.length(), 5)
  assert_eq(vwap.length(), 5)
  assert_eq(lower.length(), 5)
}
