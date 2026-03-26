/// KDJ indicator tests

///|
test "kdj calculates correct values" {
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

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 3, 3, 3)

  // Verify we have correct number of values
  assert_eq(k_line.length(), klines.length())
  assert_eq(d_line.length(), klines.length())
  assert_eq(j_line.length(), klines.length())

  // First two values should be zero (leading zeros)
  assert_eq(k_line[0], Float::from_double(0.0))
  assert_eq(k_line[1], Float::from_double(0.0))

  // K values should be in 0-100 range (after leading zeros)
  let mut i = 2
  while i < k_line.length() {
    assert_true(k_line[i] >= Float::from_double(0.0))
    assert_true(k_line[i] <= Float::from_double(100.0))
    i = i + 1
  }
}

///|
test "kdj returns zeros for insufficient data" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1000.0, 100000.0, 0.01,
    ),
  ]

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)

  // All values should be zero when data < n_period
  assert_eq(k_line.length(), 1)
  assert_eq(d_line.length(), 1)
  assert_eq(j_line.length(), 1)
  assert_eq(k_line[0], Float::from_double(0.0))
}

///|
test "kdj j_line formula correct" {
  // J = 3*K - 2*D
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 110.0, 90.0, 105.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 105.0, 115.0, 100.0, 112.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 112.0, 120.0, 108.0, 118.0, 1100.0, 110000.0, 0.011,
    ),
    @data.KLine::daily(
      "test", "2024-01-04", 118.0, 125.0, 115.0, 122.0, 1300.0, 130000.0, 0.013,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 122.0, 130.0, 118.0, 128.0, 1400.0, 140000.0, 0.014,
    ),
  ]

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 2, 2, 2)

  // Verify J = 3*K - 2*D for non-zero values
  let three = Float::from_double(3.0)
  let two = Float::from_double(2.0)
  let mut i = 2
  while i < k_line.length() {
    let expected_j = three * k_line[i] - two * d_line[i]
    // Allow small floating point difference
    let diff = Float::abs(j_line[i] - expected_j)
    assert_true(diff < Float::from_double(0.0001))
    i = i + 1
  }
}

///|
test "kdj empty klines returns empty arrays" {
  let klines : Array[@data.KLine] = []
  let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)
  assert_eq(k_line.length(), 0)
  assert_eq(d_line.length(), 0)
  assert_eq(j_line.length(), 0)
}
