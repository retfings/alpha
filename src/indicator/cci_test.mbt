/// CCI indicator tests

///|
test "cci calculates correct values" {
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

  let cci_values = @indicator.cci(klines, 3)

  // Verify we have correct number of values
  assert_eq(cci_values.length(), klines.length())

  // First two values should be zero (leading zeros for period 3)
  assert_eq(cci_values[0], Float::from_double(0.0))
  assert_eq(cci_values[1], Float::from_double(0.0))
}

///|
test "cci returns zeros for insufficient data" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  let cci_values = @indicator.cci(klines, 5)

  // All values should be zero when data < period
  assert_eq(cci_values.length(), 1)
  assert_eq(cci_values[0], Float::from_double(0.0))
}

///|
test "cci typical_price_calculation" {
  // Test that CCI uses typical price = (H + L + C) / 3
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 120.0, 80.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 120.0, 80.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 100.0, 120.0, 80.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  let cci_values = @indicator.cci(klines, 3)

  // When all typical prices are the same, CCI should be 0
  // (no deviation from mean)
  assert_eq(cci_values[2], Float::from_double(0.0))
}

///|
test "cci empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let cci_values = @indicator.cci(klines, 14)
  assert_eq(cci_values.length(), 0)
}
