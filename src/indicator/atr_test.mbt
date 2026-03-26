/// ATR indicator tests

///|
test "atr calculates correct values" {
  // Create test K-line data with known ranges
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

  let atr_values = @indicator.atr(klines, 3)

  // Verify we have correct number of values
  assert_eq(atr_values.length(), klines.length())

  // First two values should be zero (leading zeros for period 3)
  assert_eq(atr_values[0], Float::from_double(0.0))
  assert_eq(atr_values[1], Float::from_double(0.0))

  // Third value onwards should be non-zero
  assert_true(atr_values[2] > Float::from_double(0.0))
}

///|
test "atr returns zeros for insufficient data" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  let atr_values = @indicator.atr(klines, 5)

  // All values should be zero when data < period
  assert_eq(atr_values.length(), 1)
  assert_eq(atr_values[0], Float::from_double(0.0))
}

///|
test "true_range calculates correctly" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 105.0, 115.0, 100.0, 112.0, 1200.0, 120000.0, 0.012,
    ),
  ]

  let tr_values = @indicator.true_range(klines)

  assert_eq(tr_values.length(), 2)

  // First TR = High - Low = 110 - 90 = 20
  assert_eq(tr_values[0], Float::from_double(20.0))

  // Second TR = max(High-Low, |High-PrevClose|, |Low-PrevClose|)
  // = max(15, |115-105|, |100-105|) = max(15, 10, 5) = 15
  assert_eq(tr_values[1], Float::from_double(15.0))
}

///|
test "atr empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let atr_values = @indicator.atr(klines, 14)
  assert_eq(atr_values.length(), 0)
}
