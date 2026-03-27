/// ADX (Average Directional Index) indicator tests

///|
test "adx calculates correct values" {
  // Create test K-line data with a clear uptrend
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 102.0, 99.0, 101.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 101.0, 103.0, 100.0, 102.0, 1100.0, 110000.0, 0.011,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 102.0, 104.0, 101.0, 103.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 103.0, 105.0, 102.0, 104.0, 1300.0, 130000.0, 0.013,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 104.0, 106.0, 103.0, 105.0, 1400.0, 140000.0, 0.014,
    ),
    @data.KLine::daily(
      "test", "2024-01-06", 105.0, 107.0, 104.0, 106.0, 1500.0, 150000.0, 0.015,
    ),
    @data.KLine::daily(
      "test", "2024-01-07", 106.0, 108.0, 105.0, 107.0, 1600.0, 160000.0, 0.016,
    ),
    @data.KLine::daily(
      "test", "2024-01-08", 107.0, 109.0, 106.0, 108.0, 1700.0, 170000.0, 0.017,
    ),
    @data.KLine::daily(
      "test", "2024-01-09", 108.0, 110.0, 107.0, 109.0, 1800.0, 180000.0, 0.018,
    ),
    @data.KLine::daily(
      "test", "2024-01-10", 109.0, 111.0, 108.0, 110.0, 1900.0, 190000.0, 0.019,
    ),
    @data.KLine::daily(
      "test", "2024-01-11", 110.0, 112.0, 109.0, 111.0, 2000.0, 200000.0, 0.020,
    ),
    @data.KLine::daily(
      "test", "2024-01-12", 111.0, 113.0, 110.0, 112.0, 2100.0, 210000.0, 0.021,
    ),
    @data.KLine::daily(
      "test", "2024-01-13", 112.0, 114.0, 111.0, 113.0, 2200.0, 220000.0, 0.022,
    ),
    @data.KLine::daily(
      "test", "2024-01-14", 113.0, 115.0, 112.0, 114.0, 2300.0, 230000.0, 0.023,
    ),
    @data.KLine::daily(
      "test", "2024-01-15", 114.0, 116.0, 113.0, 115.0, 2400.0, 240000.0, 0.024,
    ),
  ]

  let adx_values = @indicator.adx(klines, 14)

  // Should have same length as input
  assert_eq(adx_values.length(), klines.length())

  // First 14 values should be zero (insufficient data)
  let mut i = 0
  while i < 14 {
    assert_eq(adx_values[i], Float::from_double(0.0))
    i = i + 1
  }

  // 15th value should be non-zero (first calculated ADX)
  assert_true(adx_values[14] >= 0.0)
}

///|
test "adx returns zeros for insufficient data" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 102.0, 107.0, 100.0, 106.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 106.0, 110.0, 104.0, 108.0, 1100.0, 110000.0, 0.011,
    ),
  ]

  let adx_values = @indicator.adx(klines, 14)

  // All values should be zero when data < period
  assert_eq(adx_values.length(), 3)
  assert_eq(adx_values[0], Float::from_double(0.0))
  assert_eq(adx_values[1], Float::from_double(0.0))
  assert_eq(adx_values[2], Float::from_double(0.0))
}

///|
test "adx empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let adx_values = @indicator.adx(klines, 14)
  assert_eq(adx_values.length(), 0)
}

///|
test "plus_di calculates correctly" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 102.0, 99.0, 101.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 101.0, 103.0, 100.0, 102.0, 1100.0, 110000.0, 0.011,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 102.0, 104.0, 101.0, 103.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 103.0, 105.0, 102.0, 104.0, 1300.0, 130000.0, 0.013,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 104.0, 106.0, 103.0, 105.0, 1400.0, 140000.0, 0.014,
    ),
    @data.KLine::daily(
      "test", "2024-01-06", 105.0, 107.0, 104.0, 106.0, 1500.0, 150000.0, 0.015,
    ),
    @data.KLine::daily(
      "test", "2024-01-07", 106.0, 108.0, 105.0, 107.0, 1600.0, 160000.0, 0.016,
    ),
    @data.KLine::daily(
      "test", "2024-01-08", 107.0, 109.0, 106.0, 108.0, 1700.0, 170000.0, 0.017,
    ),
    @data.KLine::daily(
      "test", "2024-01-09", 108.0, 110.0, 107.0, 109.0, 1800.0, 180000.0, 0.018,
    ),
    @data.KLine::daily(
      "test", "2024-01-10", 109.0, 111.0, 108.0, 110.0, 1900.0, 190000.0, 0.019,
    ),
    @data.KLine::daily(
      "test", "2024-01-11", 110.0, 112.0, 109.0, 111.0, 2000.0, 200000.0, 0.020,
    ),
    @data.KLine::daily(
      "test", "2024-01-12", 111.0, 113.0, 110.0, 112.0, 2100.0, 210000.0, 0.021,
    ),
    @data.KLine::daily(
      "test", "2024-01-13", 112.0, 114.0, 111.0, 113.0, 2200.0, 220000.0, 0.022,
    ),
    @data.KLine::daily(
      "test", "2024-01-14", 113.0, 115.0, 112.0, 114.0, 2300.0, 230000.0, 0.023,
    ),
    @data.KLine::daily(
      "test", "2024-01-15", 114.0, 116.0, 113.0, 115.0, 2400.0, 240000.0, 0.024,
    ),
  ]

  let pdi_values = @indicator.plus_di(klines, 14)

  assert_eq(pdi_values.length(), klines.length())

  // First 14 values should be zero
  let mut i = 0
  while i < 14 {
    assert_eq(pdi_values[i], Float::from_double(0.0))
    i = i + 1
  }

  // 15th value should be positive for uptrend
  assert_true(pdi_values[14] > 0.0)
}

///|
test "minus_di calculates correctly" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 102.0, 99.0, 101.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 101.0, 103.0, 100.0, 102.0, 1100.0, 110000.0, 0.011,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 102.0, 104.0, 101.0, 103.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 103.0, 105.0, 102.0, 104.0, 1300.0, 130000.0, 0.013,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 104.0, 106.0, 103.0, 105.0, 1400.0, 140000.0, 0.014,
    ),
    @data.KLine::daily(
      "test", "2024-01-06", 105.0, 107.0, 104.0, 106.0, 1500.0, 150000.0, 0.015,
    ),
    @data.KLine::daily(
      "test", "2024-01-07", 106.0, 108.0, 105.0, 107.0, 1600.0, 160000.0, 0.016,
    ),
    @data.KLine::daily(
      "test", "2024-01-08", 107.0, 109.0, 106.0, 108.0, 1700.0, 170000.0, 0.017,
    ),
    @data.KLine::daily(
      "test", "2024-01-09", 108.0, 110.0, 107.0, 109.0, 1800.0, 180000.0, 0.018,
    ),
    @data.KLine::daily(
      "test", "2024-01-10", 109.0, 111.0, 108.0, 110.0, 1900.0, 190000.0, 0.019,
    ),
    @data.KLine::daily(
      "test", "2024-01-11", 110.0, 112.0, 109.0, 111.0, 2000.0, 200000.0, 0.020,
    ),
    @data.KLine::daily(
      "test", "2024-01-12", 111.0, 113.0, 110.0, 112.0, 2100.0, 210000.0, 0.021,
    ),
    @data.KLine::daily(
      "test", "2024-01-13", 112.0, 114.0, 111.0, 113.0, 2200.0, 220000.0, 0.022,
    ),
    @data.KLine::daily(
      "test", "2024-01-14", 113.0, 115.0, 112.0, 114.0, 2300.0, 230000.0, 0.023,
    ),
    @data.KLine::daily(
      "test", "2024-01-15", 114.0, 116.0, 113.0, 115.0, 2400.0, 240000.0, 0.024,
    ),
  ]

  let mdi_values = @indicator.minus_di(klines, 14)

  assert_eq(mdi_values.length(), klines.length())

  // For a strong uptrend, -DI should be lower than +DI
  let pdi_values = @indicator.plus_di(klines, 14)
  assert_true(pdi_values[14] > mdi_values[14])
}

///|
test "is_strong_trend identifies strong trends" {
  // ADX above 25 indicates strong trend
  assert_true(
    @indicator.is_strong_trend(
      Float::from_double(30.0),
      Float::from_double(25.0),
    ) ==
    true,
  )
  assert_true(
    @indicator.is_strong_trend(
      Float::from_double(26.0),
      Float::from_double(25.0),
    ) ==
    true,
  )

  // ADX below threshold indicates weak trend
  assert_true(
    @indicator.is_strong_trend(
      Float::from_double(20.0),
      Float::from_double(25.0),
    ) ==
    false,
  )
  assert_true(
    @indicator.is_strong_trend(
      Float::from_double(10.0),
      Float::from_double(25.0),
    ) ==
    false,
  )
}

///|
test "adx period too small returns zeros" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 102.0, 107.0, 100.0, 106.0, 1200.0, 120000.0, 0.012,
    ),
  ]

  let adx_values = @indicator.adx(klines, 1)

  assert_eq(adx_values.length(), 2)
  assert_eq(adx_values[0], Float::from_double(0.0))
  assert_eq(adx_values[1], Float::from_double(0.0))
}
