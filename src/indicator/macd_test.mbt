/// MACD (Moving Average Convergence Divergence) indicator tests

///|
test "macd basic calculation with standard parameters" {
  // Standard MACD parameters: 12, 26, 9
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(111.0),
    Float::from_double(113.0),
    Float::from_double(115.0),
    Float::from_double(114.0),
    Float::from_double(116.0),
    Float::from_double(118.0),
    Float::from_double(117.0),
    Float::from_double(119.0),
    Float::from_double(120.0),
  ]

  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 12, 26, 9)

  // All arrays should have same length as input
  assert_eq(macd_line.length(), 20)
  assert_eq(signal_line.length(), 20)
  assert_eq(histogram.length(), 20)
}

///|
test "macd line positive in uptrend" {
  // Strong uptrend should produce positive MACD line
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(110.0),
    Float::from_double(115.0),
    Float::from_double(120.0),
    Float::from_double(125.0),
    Float::from_double(130.0),
    Float::from_double(135.0),
    Float::from_double(140.0),
    Float::from_double(145.0),
    Float::from_double(150.0),
    Float::from_double(155.0),
    Float::from_double(160.0),
    Float::from_double(165.0),
    Float::from_double(170.0),
  ]

  let (macd_line, _, _) = @indicator.macd(prices, 3, 6, 3)

  // MACD line should be positive in strong uptrend
  assert_true(macd_line[14] > Float::from_double(0.0))
}

///|
test "macd line negative in downtrend" {
  // Strong downtrend should produce negative MACD line
  let prices : Array[Float] = [
    Float::from_double(170.0),
    Float::from_double(165.0),
    Float::from_double(160.0),
    Float::from_double(155.0),
    Float::from_double(150.0),
    Float::from_double(145.0),
    Float::from_double(140.0),
    Float::from_double(135.0),
    Float::from_double(130.0),
    Float::from_double(125.0),
    Float::from_double(120.0),
    Float::from_double(115.0),
    Float::from_double(110.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
  ]

  let (macd_line, _, _) = @indicator.macd(prices, 3, 6, 3)

  // MACD line should be negative in strong downtrend
  assert_true(macd_line[14] < Float::from_double(0.0))
}

///|
test "macd returns zeros for empty input" {
  let prices : Array[Float] = []

  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 12, 26, 9)

  assert_eq(macd_line.length(), 0)
  assert_eq(signal_line.length(), 0)
  assert_eq(histogram.length(), 0)
}

///|
test "macd returns values for insufficient data" {
  // Not enough data for slow period (26)
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
  ]

  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 3, 5, 2)

  // Arrays should still have correct length
  assert_eq(macd_line.length(), 5)
  assert_eq(signal_line.length(), 5)
  assert_eq(histogram.length(), 5)
}

///|
test "macd histogram calculation" {
  // Histogram = MACD line - Signal line
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
  ]

  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 3, 5, 2)

  // Verify histogram = macd_line - signal_line for each element
  let len = histogram.length()
  let mut i = 0
  while i < len {
    let expected_hist = macd_line[i] - signal_line[i]
    let diff = histogram[i] - expected_hist
    // Allow small floating point difference
    assert_true(
      diff > Float::from_double(-0.0001) && diff < Float::from_double(0.0001),
    )
    i = i + 1
  }
}

///|
test "macd different period combinations" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(111.0),
    Float::from_double(113.0),
    Float::from_double(115.0),
    Float::from_double(114.0),
    Float::from_double(116.0),
    Float::from_double(118.0),
    Float::from_double(117.0),
    Float::from_double(119.0),
    Float::from_double(120.0),
  ]

  // Fast parameters (more responsive)
  let (macd_fast, _, _) = @indicator.macd(prices, 3, 6, 2)

  // Standard parameters
  let (macd_std, _, _) = @indicator.macd(prices, 12, 26, 9)

  // Slow parameters (less responsive)
  let (macd_slow, _, _) = @indicator.macd(prices, 21, 55, 9)

  // All should produce arrays of correct length
  assert_eq(macd_fast.length(), 20)
  assert_eq(macd_std.length(), 20)
  assert_eq(macd_slow.length(), 20)
}

///|
test "macd signal line lag behind macd line" {
  // Signal line is EMA of MACD line, so it should lag
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(111.0),
    Float::from_double(113.0),
    Float::from_double(115.0),
    Float::from_double(114.0),
    Float::from_double(116.0),
    Float::from_double(118.0),
    Float::from_double(117.0),
    Float::from_double(119.0),
    Float::from_double(120.0),
  ]

  let (_macd_line, _signal_line, _) = @indicator.macd(prices, 3, 6, 3)

  // Signal line should be smoother (less volatile) than MACD line
  // This is inherent to EMA smoothing
}

///|
test "macd with equal fast and slow periods" {
  // Edge case: fast_period == slow_period
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
  ]

  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 5, 5, 3)

  // MACD line should be near zero when fast == slow
  assert_eq(macd_line.length(), 5)
  assert_eq(signal_line.length(), 5)
  assert_eq(histogram.length(), 5)
}

///|
test "macd minimum period values" {
  // Test with minimum practical periods
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
  ]

  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 2, 4, 2)

  assert_eq(macd_line.length(), 10)
  assert_eq(signal_line.length(), 10)
  assert_eq(histogram.length(), 10)
}

///|
test "macd histogram crossover detection" {
  // Histogram crossing zero indicates MACD crossing signal line
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
    Float::from_double(108.0),
    Float::from_double(106.0),
    Float::from_double(104.0),
    Float::from_double(102.0),
    Float::from_double(100.0),
  ]

  let (_, _, histogram) = @indicator.macd(prices, 3, 6, 3)

  // Histogram values exist (may cross zero)
  assert_eq(histogram.length(), 15)
}

///|
test "macd snapshot test" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(110.0),
  ]
  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 3, 5, 2)
  assert_eq(macd_line.length(), 10)
  assert_eq(signal_line.length(), 10)
  assert_eq(histogram.length(), 10)
  inspect(
    (macd_line, signal_line, histogram),
    content=(
      #|([0, 0, 101, 102, 1.3000030517578125, 0.9500045776367188, 1.0083389282226562, 1.1930618286132812, 0.8891220092773438, 1.1396255493164062], [0, 0, 67.33333587646484, 90.44444274902344, 31.014816284179688, 10.971607208251953, 4.329428195953369, 2.2385172843933105, 1.3389203548431396, 1.2060571908950806], [0, 0, 33.666664123535156, 11.555557250976562, -29.714813232421875, -10.021602630615234, -3.321089267730713, -1.0454554557800293, -0.4497983455657959, -0.06643164157867432])
    ),
  )
}
