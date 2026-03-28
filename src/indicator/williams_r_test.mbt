/// Williams %R indicator tests

///|
test "williams_r calculates correct values" {
  // Create test K-line data
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 102.0, 108.0, 100.0, 106.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 106.0, 110.0, 104.0, 108.0, 1100.0, 110000.0, 0.011,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 108.0, 112.0, 106.0, 110.0, 1300.0, 130000.0, 0.013,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 110.0, 115.0, 108.0, 112.0, 1400.0, 140000.0, 0.014,
    ),
  ]

  let wr_values = @indicator.williams_r(klines, 3)

  // Verify we have correct number of values
  assert_eq(wr_values.length(), klines.length())

  // First two values should be zero (leading zeros for period 3)
  assert_eq(wr_values[0], Float::from_double(0.0))
  assert_eq(wr_values[1], Float::from_double(0.0))

  // Williams %R should be in -100 to 0 range (after leading zeros)
  let mut i = 2
  while i < wr_values.length() {
    assert_true(wr_values[i] <= Float::from_double(0.0))
    assert_true(wr_values[i] >= Float::from_double(-100.0))
    i = i + 1
  }
}

///|
test "williams_r returns zeros for insufficient data" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  let wr_values = @indicator.williams_r(klines, 5)

  // All values should be zero when data < period
  assert_eq(wr_values.length(), 1)
  assert_eq(wr_values[0], Float::from_double(0.0))
}

///|
test "williams_r formula verification" {
  // Test with known values
  // Williams %R = (Highest High - Close) / (Highest High - Lowest Low) * -100
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 100.0, 80.0, 90.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 90.0, 100.0, 80.0, 80.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  let wr_values = @indicator.williams_r(klines, 2)

  // For period 2, second value:
  // Highest High = 100, Lowest Low = 80, Close = 80
  // WR = (100 - 80) / (100 - 80) * -100 = 20/20 * -100 = -100
  assert_eq(wr_values[1], Float::from_double(-100.0))
}

///|
test "williams_r empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let wr_values = @indicator.williams_r(klines, 14)
  assert_eq(wr_values.length(), 0)
}
