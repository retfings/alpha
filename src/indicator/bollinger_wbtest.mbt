/// Whitebox tests for Bollinger Bands - testing internal implementation details

///|
test "bollinger_bands - internal SMA calculation verified" {
  // Verify the internal SMA calculation is correct
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(20.0),
    Float::from_double(30.0),
    Float::from_double(40.0),
    Float::from_double(50.0),
  ]
  let (_upper, middle, _lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(2.0),
  )

  // At index 2, SMA of [10, 20, 30] = 20
  assert_true(
    middle[2] > Float::from_double(19.9) && middle[2] < Float::from_double(20.1),
  )
  // At index 3, SMA of [20, 30, 40] = 30
  assert_true(
    middle[3] > Float::from_double(29.9) && middle[3] < Float::from_double(30.1),
  )
  // At index 4, SMA of [30, 40, 50] = 40
  assert_true(
    middle[4] > Float::from_double(39.9) && middle[4] < Float::from_double(40.1),
  )
}

///|
test "bollinger_bands - internal std dev calculation" {
  // Verify standard deviation calculation with known values
  // For prices [10, 20, 30], mean = 20, variance = ((10-20)^2 + (20-20)^2 + (30-20)^2) / 3 = 200/3 = 66.67
  // std = sqrt(66.67) = 8.165
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(20.0),
    Float::from_double(30.0),
  ]
  let (upper, _middle, lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(1.0),
  )

  // With multiplier=1, upper = mean + std = 20 + 8.165 = 28.165
  // lower = mean - std = 20 - 8.165 = 11.835
  assert_true(
    upper[2] > Float::from_double(28.0) && upper[2] < Float::from_double(28.5),
  )
  assert_true(
    lower[2] > Float::from_double(11.5) && lower[2] < Float::from_double(12.0),
  )
}

///|
test "bollinger_bands - zero handling for period boundary" {
  // Verify exact period boundary - first valid value at index (period-1)
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(20.0),
    Float::from_double(30.0),
  ]
  let (upper, middle, lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(2.0),
  )

  // First two should be zero
  assert_eq(upper[0], Float::from_double(0.0))
  assert_eq(middle[0], Float::from_double(0.0))
  assert_eq(lower[0], Float::from_double(0.0))
  assert_eq(upper[1], Float::from_double(0.0))
  assert_eq(middle[1], Float::from_double(0.0))
  assert_eq(lower[1], Float::from_double(0.0))

  // Index 2 should be first valid
  assert_true(middle[2] > Float::from_double(0.0))
}

///|
test "bollinger_percent_b - edge case: zero band width" {
  // When upper == lower, %B should return 0
  let result = bollinger_percent_b(
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
  )
  assert_eq(result, Float::from_double(0.0))
}

///|
test "bollinger_percent_b - negative band width handling" {
  // Test behavior when lower > upper (shouldn't happen, but verify robustness)
  let result = bollinger_percent_b(
    Float::from_double(95.0),
    Float::from_double(90.0), // upper
    Float::from_double(100.0), // lower (greater than upper)
  )
  // %B = (95 - 100) / (90 - 100) = -5 / -10 = 0.5
  assert_true(
    result > Float::from_double(0.4) && result < Float::from_double(0.6),
  )
}

///|
test "bollinger_band_width - precision test" {
  // Test band width calculation precision
  let upper = Float::from_double(100.5)
  let lower = Float::from_double(99.5)
  let middle = Float::from_double(100.0)

  let width = bollinger_band_width(upper, lower, middle)

  // (100.5 - 99.5) / 100 = 0.01
  assert_true(
    width > Float::from_double(0.009) && width < Float::from_double(0.011),
  )
}

///|
test "is_bollinger_squeeze - threshold boundary" {
  // Test exact threshold boundary
  let width_exactly_10pct_upper = Float::from_double(110.0)
  let width_exactly_10pct_lower = Float::from_double(90.0)
  let middle = Float::from_double(100.0)

  // Band width = 0.20 (20%), threshold = 0.10, should NOT be squeeze
  assert_true(
    !is_bollinger_squeeze(
      width_exactly_10pct_upper,
      width_exactly_10pct_lower,
      middle,
      Float::from_double(0.10),
    ),
  )

  // With threshold = 0.25, should be squeeze
  assert_true(
    is_bollinger_squeeze(
      width_exactly_10pct_upper,
      width_exactly_10pct_lower,
      middle,
      Float::from_double(0.25),
    ),
  )
}

///|
test "is_above_upper_band - boundary equality" {
  // When price == upper, should return false (strictly greater)
  assert_true(
    !is_above_upper_band(Float::from_double(100.0), Float::from_double(100.0)),
  )

  // Even tiny amount above should return true
  assert_true(
    is_above_upper_band(Float::from_double(100.01), Float::from_double(100.0)),
  )
}

///|
test "is_below_lower_band - boundary equality" {
  // When price == lower, should return false (strictly less)
  assert_true(
    !is_below_lower_band(Float::from_double(100.0), Float::from_double(100.0)),
  )

  // Even tiny amount below should return true
  assert_true(
    is_below_lower_band(Float::from_double(99.99), Float::from_double(100.0)),
  )
}

///|
test "bollinger_position - all enum variants" {
  let upper = Float::from_double(110.0)
  let middle = Float::from_double(100.0)
  let lower = Float::from_double(90.0)

  // AboveUpper
  assert_true(
    match bollinger_position(Float::from_double(115.0), upper, middle, lower) {
      BollingerPosition::AboveUpper => true
      _ => false
    },
  )

  // AboveMiddle (price > middle and price <= upper)
  assert_true(
    match bollinger_position(Float::from_double(105.0), upper, middle, lower) {
      BollingerPosition::AboveMiddle => true
      _ => false
    },
  )

  // BelowMiddle (price > lower and price <= middle)
  assert_true(
    match bollinger_position(Float::from_double(95.0), upper, middle, lower) {
      BollingerPosition::BelowMiddle => true
      _ => false
    },
  )

  // BelowLower (price <= lower)
  assert_true(
    match bollinger_position(Float::from_double(85.0), upper, middle, lower) {
      BollingerPosition::BelowLower => true
      _ => false
    },
  )
}

///|
test "bollinger_position - exact boundaries" {
  let upper = Float::from_double(110.0)
  let middle = Float::from_double(100.0)
  let lower = Float::from_double(90.0)

  // Price exactly at upper -> AboveMiddle (since price >= middle and price > upper is false)
  // Actually, looking at the code: if price > upper -> AboveUpper, else if price >= middle -> AboveMiddle
  // So at exactly upper (110), price > upper is false, but price >= middle is true -> AboveMiddle
  assert_true(
    match bollinger_position(upper, upper, middle, lower) {
      BollingerPosition::AboveMiddle => true
      _ => false
    },
  )

  // Price exactly at middle -> AboveMiddle
  assert_true(
    match bollinger_position(middle, upper, middle, lower) {
      BollingerPosition::AboveMiddle => true
      _ => false
    },
  )

  // Price exactly at lower -> BelowMiddle
  assert_true(
    match bollinger_position(lower, upper, middle, lower) {
      BollingerPosition::BelowMiddle => true
      _ => false
    },
  )
}

///|
test "bandwidth - array calculation verified" {
  let upper : Array[Float] = [
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(114.0),
  ]
  let middle : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(101.0),
    Float::from_double(102.0),
  ]
  let lower : Array[Float] = [
    Float::from_double(90.0),
    Float::from_double(90.0),
    Float::from_double(90.0),
  ]

  let widths = bandwidth(upper, middle, lower)

  assert_eq(widths.length(), 3)
  // width[0] = (110 - 90) / 100 = 0.20
  assert_true(
    widths[0] > Float::from_double(0.19) && widths[0] < Float::from_double(0.21),
  )
  // width[1] = (112 - 90) / 101 = 0.218
  assert_true(
    widths[1] > Float::from_double(0.21) && widths[1] < Float::from_double(0.23),
  )
  // width[2] = (114 - 90) / 102 = 0.235
  assert_true(
    widths[2] > Float::from_double(0.23) && widths[2] < Float::from_double(0.24),
  )
}

///|
test "bandwidth - zero middle values" {
  let upper : Array[Float] = [
    Float::from_double(110.0),
    Float::from_double(112.0),
  ]
  let middle : Array[Float] = [
    Float::from_double(0.0),
    Float::from_double(100.0),
  ]
  let lower : Array[Float] = [
    Float::from_double(90.0),
    Float::from_double(90.0),
  ]

  let widths = bandwidth(upper, middle, lower)

  assert_eq(widths.length(), 2)
  // width[0] should be 0 due to zero middle
  assert_eq(widths[0], Float::from_double(0.0))
  // width[1] should be normal
  assert_true(widths[1] > Float::from_double(0.0))
}

///|
test "percent_b - array calculation" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(110.0),
  ]
  let upper : Array[Float] = [
    Float::from_double(120.0),
    Float::from_double(120.0),
    Float::from_double(120.0),
  ]
  let lower : Array[Float] = [
    Float::from_double(80.0),
    Float::from_double(80.0),
    Float::from_double(80.0),
  ]

  let percent_b_values = percent_b(prices, upper, lower)

  assert_eq(percent_b_values.length(), 3)
  // %B[0] = (100 - 80) / (120 - 80) = 0.50
  assert_true(
    percent_b_values[0] > Float::from_double(0.49) &&
    percent_b_values[0] < Float::from_double(0.51),
  )
  // %B[1] = (105 - 80) / (120 - 80) = 0.625
  assert_true(
    percent_b_values[1] > Float::from_double(0.62) &&
    percent_b_values[1] < Float::from_double(0.63),
  )
  // %B[2] = (110 - 80) / (120 - 80) = 0.75
  assert_true(
    percent_b_values[2] > Float::from_double(0.74) &&
    percent_b_values[2] < Float::from_double(0.76),
  )
}

///|
test "percent_b - array with zero band width" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(105.0),
  ]
  let upper : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(120.0),
  ]
  let lower : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(80.0),
  ]

  let percent_b_values = percent_b(prices, upper, lower)

  // %B[0] should be 0 due to zero band width
  assert_eq(percent_b_values[0], Float::from_double(0.0))
  // %B[1] should be normal
  assert_true(percent_b_values[1] > Float::from_double(0.0))
}

///|
test "bollinger_bands - floating point precision" {
  // Test with values that might cause floating point issues
  let prices : Array[Float] = [
    Float::from_double(0.1),
    Float::from_double(0.2),
    Float::from_double(0.3),
    Float::from_double(0.4),
    Float::from_double(0.5),
  ]
  let (upper, middle, lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(2.0),
  )

  // Just verify no NaN or infinity
  assert_true(middle[2] > Float::from_double(0.0))
  assert_true(upper[2] > Float::from_double(0.0))
  assert_true(lower[2] > Float::from_double(0.0))
}

///|
test "bollinger_bands - large values" {
  // Test with very large price values
  let prices : Array[Float] = [
    Float::from_double(1000000.0),
    Float::from_double(1000000.0),
    Float::from_double(1000000.0),
    Float::from_double(1000000.0),
    Float::from_double(1000000.0),
  ]
  let (upper, middle, lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(2.0),
  )

  // With constant prices, all bands should equal the price
  assert_eq(middle[2], Float::from_double(1000000.0))
  assert_eq(upper[2], Float::from_double(1000000.0))
  assert_eq(lower[2], Float::from_double(1000000.0))
}

///|
test "bollinger_bands_default - delegates correctly" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
  ]

  let (upper1, middle1, lower1) = bollinger_bands_default(prices)
  let (upper2, middle2, lower2) = bollinger_bands(
    prices,
    20,
    Float::from_double(2.0),
  )

  // Should produce same results (both use period=20, multiplier=2.0)
  assert_eq(upper1.length(), upper2.length())
  assert_eq(middle1.length(), middle2.length())
  assert_eq(lower1.length(), lower2.length())
}

///|
test "bollinger_bands - monotonic price sequence" {
  // Strictly increasing prices
  let prices : Array[Float] = [
    Float::from_double(1.0),
    Float::from_double(2.0),
    Float::from_double(3.0),
    Float::from_double(4.0),
    Float::from_double(5.0),
  ]
  let (_upper, middle, _lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(2.0),
  )

  // Middle band should be monotonically increasing
  assert_true(middle[3] > middle[2])
  assert_true(middle[4] > middle[3])
}

///|
test "bollinger_bands - alternating price sequence" {
  // Alternating prices: up, down, up, down
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(90.0),
    Float::from_double(110.0),
    Float::from_double(80.0),
    Float::from_double(120.0),
  ]
  let (upper, middle, lower) = bollinger_bands(
    prices,
    3,
    Float::from_double(2.0),
  )

  // Bands should still maintain proper ordering
  let mut i = 2
  while i < 5 {
    assert_true(upper[i] >= middle[i])
    assert_true(middle[i] >= lower[i])
    i = i + 1
  }
}
