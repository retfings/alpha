/// Black-box tests for Bollinger Bands indicator

///|
test "bollinger_bands - basic calculation" {
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0,
  ]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  assert_true(upper.length() == 9)
  assert_true(middle.length() == 9)
  assert_true(lower.length() == 9)
  // Upper > Middle > Lower
  assert_true(upper[8] > middle[8])
  assert_true(middle[8] > lower[8])
}

///|
test "bollinger_bands - band width increases with volatility" {
  // Low volatility
  let prices_low_vol : Array[Float] = [10.0, 10.1, 10.0, 10.1, 10.0, 10.1, 10.0]
  // High volatility
  let prices_high_vol : Array[Float] = [
    10.0, 15.0, 10.0, 15.0, 10.0, 15.0, 10.0,
  ]
  let (upper1, _, lower1) = bollinger_bands(prices_low_vol, 5, 2.0)
  let (upper2, _, lower2) = bollinger_bands(prices_high_vol, 5, 2.0)
  // Band width for high vol should be larger
  let width1 = upper1[6] - lower1[6]
  let width2 = upper2[6] - lower2[6]
  assert_true(width2 > width1)
}

///|
test "bollinger_bands - insufficient data" {
  let prices : Array[Float] = [10.0, 11.0, 12.0]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  assert_true(upper.length() == 3)
  assert_true(middle.length() == 3)
  assert_true(lower.length() == 3)
  assert_true(upper[0] == 0.0)
}

///|
test "bollinger_bands - empty array" {
  let prices : Array[Float] = []
  let (upper, middle, lower) = bollinger_bands(prices, 20, 2.0)
  assert_true(upper.length() == 0)
  assert_true(middle.length() == 0)
  assert_true(lower.length() == 0)
}

///|
test "bollinger_bands - band ordering (lower <= middle <= upper)" {
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0,
    23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0,
  ]
  let (upper, middle, lower) = bollinger_bands(prices, 10, 2.0)
  assert_true(middle.length() == 20)
  assert_true(upper.length() == 20)
  assert_true(lower.length() == 20)
  // Verify band ordering for all valid values
  let mut i = 9 // Start from first valid value
  while i < 20 {
    assert_true(lower[i] <= middle[i])
    assert_true(middle[i] <= upper[i])
    i = i + 1
  }
}

///|
test "bollinger_bands - constant prices" {
  // With constant prices, std dev should be 0, so all bands equal the price
  let prices : Array[Float] = [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  // All non-zero values should equal 10.0 (no volatility)
  assert_true(middle[4] == 10.0)
  assert_true(upper[4] == 10.0)
  assert_true(lower[4] == 10.0)
}

///|
test "bollinger_bands_default - uses default parameters" {
  // Generate 20 prices to have enough data for default period=20
  let prices : Array[Float] = [
    100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0, 110.0,
    111.0, 112.0, 113.0, 114.0, 115.0, 116.0, 117.0, 118.0, 119.0,
  ]
  let (upper, middle, lower) = bollinger_bands_default(prices)
  assert_true(upper.length() == 20)
  assert_true(middle.length() == 20)
  assert_true(lower.length() == 20)
  // First 19 should be zero (not enough data for period=20)
  assert_true(middle[18] == 0.0)
  // Last one should have valid values
  assert_true(middle[19] > 0.0)
}

///|
test "bollinger_percent_b - single value calculation" {
  let percent_b = bollinger_percent_b(
    Float::from_double(105.0),
    Float::from_double(110.0),
    Float::from_double(90.0),
  )
  assert_true(
    percent_b > Float::from_double(0.74) && percent_b < Float::from_double(0.76),
  )
}

///|
test "bollinger_percent_b - price at bands" {
  let upper = Float::from_double(110.0)
  let lower = Float::from_double(90.0)
  assert_true(
    bollinger_percent_b(lower, upper, lower) == Float::from_double(0.0),
  )
  assert_true(
    bollinger_percent_b(upper, upper, lower) == Float::from_double(1.0),
  )
  let middle = (upper + lower) / Float::from_double(2.0)
  let b = bollinger_percent_b(middle, upper, lower)
  assert_true(b > Float::from_double(0.49) && b < Float::from_double(0.51))
}

///|
test "bollinger_percent_b - price outside bands" {
  let upper = Float::from_double(110.0)
  let lower = Float::from_double(90.0)
  assert_true(
    bollinger_percent_b(Float::from_double(115.0), upper, lower) >
    Float::from_double(1.0),
  )
  assert_true(
    bollinger_percent_b(Float::from_double(85.0), upper, lower) <
    Float::from_double(0.0),
  )
}

///|
test "bollinger_percent_b - zero band width" {
  let percent_b = bollinger_percent_b(
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
  )
  assert_true(percent_b == Float::from_double(0.0))
}

///|
test "percent_b - array version basic" {
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0,
  ]
  let (upper, _, lower) = bollinger_bands(prices, 5, 2.0)
  let percent_b_values = percent_b(prices, upper, lower)
  assert_true(percent_b_values.length() == 9)
  // %B should generally be in 0-1 range for prices within bands
  let mut i = 4
  while i < 9 {
    // Prices are trending up, so %B should be in upper half
    assert_true(percent_b_values[i] >= 0.0 && percent_b_values[i] <= 1.5)
    i = i + 1
  }
}

///|
test "percent_b - array version with price spike" {
  // When there's a price spike, %B will be high (near or at 1.0)
  // The bands adapt to volatility, so %B shows relative position
  let prices : Array[Float] = [50.0, 50.0, 50.0, 50.0, 80.0]
  let (upper, _, lower) = bollinger_bands(prices, 3, 2.0)
  let percent_b_values = percent_b(prices, upper, lower)
  // %B should be high for the spike price (near upper band)
  // %B = 1 means price is at upper band
  assert_true(percent_b_values[4] >= 0.8)
}

///|
test "bollinger_band_width - single value calculation" {
  let width = bollinger_band_width(
    Float::from_double(110.0),
    Float::from_double(90.0),
    Float::from_double(100.0),
  )
  assert_true(
    width > Float::from_double(0.19) && width < Float::from_double(0.21),
  )
}

///|
test "bollinger_band_width - zero middle" {
  let width = bollinger_band_width(
    Float::from_double(110.0),
    Float::from_double(90.0),
    Float::from_double(0.0),
  )
  assert_true(width == Float::from_double(0.0))
}

///|
test "bollinger_band_width - narrow vs wide bands" {
  let narrow_width = bollinger_band_width(
    Float::from_double(101.0),
    Float::from_double(99.0),
    Float::from_double(100.0),
  )
  let wide_width = bollinger_band_width(
    Float::from_double(120.0),
    Float::from_double(80.0),
    Float::from_double(100.0),
  )
  assert_true(wide_width > narrow_width)
}

///|
test "bandwidth - array version basic" {
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0,
  ]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  let bandwidth_values = bandwidth(upper, middle, lower)
  assert_true(bandwidth_values.length() == 9)
  // Bandwidth should be positive for valid values
  let mut i = 4
  while i < 9 {
    assert_true(bandwidth_values[i] > 0.0)
    i = i + 1
  }
}

///|
test "bandwidth - array version volatility changes" {
  // Start with low volatility, then increase
  let prices : Array[Float] = [
    10.0, 10.1, 10.0, 10.1, 10.0, 15.0, 5.0, 15.0, 5.0,
  ]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  let bandwidth_values = bandwidth(upper, middle, lower)
  // Bandwidth should increase as volatility increases
  // Compare bandwidth at index 4 (low vol) vs index 8 (high vol)
  assert_true(bandwidth_values[8] > bandwidth_values[4])
}

///|
test "is_bollinger_squeeze - detects narrow bands" {
  // Narrow bands: width = 0.02 (2%)
  assert_true(is_bollinger_squeeze(101.0, 99.0, 100.0, 0.1))
  // Wide bands: width = 0.4 (40%)
  assert_false(is_bollinger_squeeze(120.0, 80.0, 100.0, 0.1))
}

///|
test "is_bollinger_squeeze - threshold sensitivity" {
  // Same bands, different thresholds
  // width = 0.2 (20%)
  assert_false(is_bollinger_squeeze(110.0, 90.0, 100.0, 0.1))
  assert_true(is_bollinger_squeeze(110.0, 90.0, 100.0, 0.3))
}

///|
test "is_above_upper_band - price position" {
  assert_true(is_above_upper_band(110.5, 110.0))
  assert_false(is_above_upper_band(109.5, 110.0))
  assert_false(is_above_upper_band(110.0, 110.0))
}

///|
test "is_below_lower_band - price position" {
  assert_true(is_below_lower_band(89.5, 90.0))
  assert_false(is_below_lower_band(90.5, 90.0))
  assert_false(is_below_lower_band(90.0, 90.0))
}

///|
test "bollinger_position - above upper" {
  let pos = bollinger_position(115.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos {
      BollingerPosition::AboveUpper => true
      _ => false
    },
  )
}

///|
test "bollinger_position - above middle" {
  let pos = bollinger_position(105.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos {
      BollingerPosition::AboveMiddle => true
      _ => false
    },
  )
}

///|
test "bollinger_position - below middle" {
  let pos = bollinger_position(95.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos {
      BollingerPosition::BelowMiddle => true
      _ => false
    },
  )
}

///|
test "bollinger_position - below lower" {
  let pos = bollinger_position(85.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos {
      BollingerPosition::BelowLower => true
      _ => false
    },
  )
}

///|
test "bollinger_position - boundary cases" {
  // Price exactly at upper band
  let pos1 = bollinger_position(110.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos1 {
      BollingerPosition::AboveMiddle => true
      _ => false
    },
  )
  // Price exactly at middle band
  let pos2 = bollinger_position(100.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos2 {
      BollingerPosition::AboveMiddle => true
      _ => false
    },
  )
  // Price exactly at lower band
  let pos3 = bollinger_position(90.0, 110.0, 100.0, 90.0)
  assert_true(
    match pos3 {
      BollingerPosition::BelowMiddle => true
      _ => false
    },
  )
}

///|
test "bollinger_bands - snapshot test" {
  let prices : Array[Float] = [
    50.0, 52.0, 48.0, 51.0, 53.0, 49.0, 52.0, 54.0, 50.0, 55.0,
  ]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  assert_true(upper.length() == 10)
  assert_true(middle.length() == 10)
  assert_true(lower.length() == 10)
  // Verify band ordering for valid values
  let mut i = 4
  while i < 10 {
    assert_true(upper[i] >= middle[i])
    assert_true(middle[i] >= lower[i])
    i = i + 1
  }
}

///|
test "bollinger_percent_b - snapshot test" {
  let prices : Array[Float] = [
    50.0, 52.0, 48.0, 51.0, 53.0, 49.0, 52.0, 54.0, 50.0, 55.0,
  ]
  let (upper, _, lower) = bollinger_bands(prices, 5, 2.0)
  let percent_b_values = percent_b(prices, upper, lower)
  assert_true(percent_b_values.length() == 10)
  // %B values should be in reasonable range
  let mut i = 4
  while i < 10 {
    assert_true(percent_b_values[i] >= -0.5 && percent_b_values[i] <= 1.5)
    i = i + 1
  }
}

///|
test "bandwidth - snapshot test" {
  let prices : Array[Float] = [
    100.0, 101.0, 99.0, 102.0, 98.0, 103.0, 97.0, 104.0, 96.0, 105.0,
  ]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  let bandwidth_values = bandwidth(upper, middle, lower)
  assert_true(bandwidth_values.length() == 10)
  // Bandwidth should be positive for valid values
  let mut i = 4
  while i < 10 {
    assert_true(bandwidth_values[i] > 0.0 && bandwidth_values[i] < 1.0)
    i = i + 1
  }
}
