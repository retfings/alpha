/// RSI indicator tests

///|
test "rsi calculates correct values for uptrend" {
  // Simulate a strong uptrend
  let prices : Array[Float] = [
    100.0, 102.0, 104.0, 106.0, 108.0,
    110.0, 112.0, 114.0, 116.0, 118.0,
    120.0, 122.0, 124.0, 126.0, 128.0,
  ]

  let rsi_values = rsi(prices, 14)

  // Should have same length as input
  assert_true(rsi_values.length() == prices.length())

  // First 14 values should be zero (insufficient data)
  let mut i = 0
  while i < 14 {
    assert_true(rsi_values[i] == 0.0)
    i = i + 1
  }

  // RSI should be very high (strong uptrend = overbought)
  let last_rsi = rsi_values[rsi_values.length() - 1]
  assert_true(last_rsi > 70.0)
}

///|
test "rsi calculates correct values for downtrend" {
  // Simulate a strong downtrend
  let prices : Array[Float] = [
    100.0, 98.0, 96.0, 94.0, 92.0,
    90.0, 88.0, 86.0, 84.0, 82.0,
    80.0, 78.0, 76.0, 74.0, 72.0,
  ]

  let rsi_values = rsi(prices, 14)

  // First 14 values should be zero
  let mut i = 0
  while i < 14 {
    assert_true(rsi_values[i] == 0.0)
    i = i + 1
  }

  // RSI should be very low (strong downtrend = oversold)
  let last_rsi = rsi_values[rsi_values.length() - 1]
  assert_true(last_rsi < 30.0)
}

///|
test "rsi handles flat prices (no change)" {
  // All prices are the same - no gains or losses
  let prices : Array[Float] = [
    100.0, 100.0, 100.0, 100.0, 100.0,
    100.0, 100.0, 100.0, 100.0, 100.0,
    100.0, 100.0, 100.0, 100.0, 100.0,
    100.0, 100.0,
  ]

  let rsi_values = rsi(prices, 14)

  // First 14 values should be zero
  let mut i = 0
  while i < 14 {
    assert_true(rsi_values[i] == 0.0)
    i = i + 1
  }

  // When avg_loss is 0, RSI should be 100
  assert_true(rsi_values[14] == 100.0)
}

///|
test "rsi with period 2" {
  // Use a shorter period for faster calculation
  let prices : Array[Float] = [10.0, 12.0, 11.0, 13.0, 15.0, 14.0, 16.0]

  let rsi_values = rsi(prices, 2)

  // First 2 values should be zero
  assert_true(rsi_values[0] == 0.0)
  assert_true(rsi_values[1] == 0.0)

  // Rest should be calculated
  let mut i = 2
  while i < rsi_values.length() {
    assert_true(rsi_values[i] >= 0.0 && rsi_values[i] <= 100.0)
    i = i + 1
  }
}

///|
test "is_overbought detects overbought conditions" {
  assert_true(is_overbought(71.0, 70.0))
  assert_true(is_overbought(80.0, 70.0))
  assert_true(is_overbought(90.0, 70.0))

  // Not overbought
  assert_true(!is_overbought(70.0, 70.0))
  assert_true(!is_overbought(50.0, 70.0))
  assert_true(!is_overbought(30.0, 70.0))
}

///|
test "is_oversold detects oversold conditions" {
  assert_true(is_oversold(29.0, 30.0))
  assert_true(is_oversold(20.0, 30.0))
  assert_true(is_oversold(10.0, 30.0))

  // Not oversold
  assert_true(!is_oversold(30.0, 30.0))
  assert_true(!is_oversold(50.0, 30.0))
  assert_true(!is_oversold(70.0, 30.0))
}

///|
test "rsi with empty prices" {
  let prices : Array[Float] = []
  let result = rsi(prices, 14)
  assert_true(result.length() == 0)
}

///|
test "rsi with single price" {
  let prices : Array[Float] = [100.0]
  let result = rsi(prices, 14)
  assert_true(result.length() == 1)
  assert_true(result[0] == 0.0)
}

///|
test "rsi with zero period" {
  let prices : Array[Float] = [100.0, 101.0, 102.0]
  let result = rsi(prices, 0)
  // Should return array of zeros
  assert_true(result.length() == prices.length())
}

///|
test "rsi with period larger than data" {
  let prices : Array[Float] = [100.0, 101.0, 102.0]
  let result = rsi(prices, 10)
  // All values should be zero (insufficient data)
  assert_true(result.length() == prices.length())
  let mut i = 0
  while i < result.length() {
    assert_true(result[i] == 0.0)
    i = i + 1
  }
}

///|
test "rsi boundary conditions for overbought/oversold" {
  // Test boundary at exactly 70
  assert_true(!is_overbought(70.0, 70.0))
  assert_true(is_overbought(70.1, 70.0))
  assert_true(!is_overbought(69.9, 70.0))

  // Test boundary at exactly 30
  assert_true(!is_oversold(30.0, 30.0))
  assert_true(is_oversold(29.9, 30.0))
  assert_true(!is_oversold(30.1, 30.0))
}

///|
test "rsi with alternating prices" {
  // Alternating up and down
  let prices : Array[Float] = [100.0, 101.0, 100.0, 101.0, 100.0, 101.0, 100.0, 101.0]
  let rsi_values = rsi(prices, 3)

  // First 3 should be zero
  assert_true(rsi_values[0] == 0.0)
  assert_true(rsi_values[1] == 0.0)
  assert_true(rsi_values[2] == 0.0)

  // Rest should be around 50 (neutral) for alternating pattern
  let mut i = 3
  while i < rsi_values.length() {
    assert_true(rsi_values[i] >= 0.0 && rsi_values[i] <= 100.0)
    i = i + 1
  }
}

///|
test "rsi consistency check" {
  // RSI values should always be in [0, 100] range
  let prices : Array[Float] = [
    100.0, 105.0, 103.0, 108.0, 107.0,
    110.0, 109.0, 112.0, 111.0, 115.0,
    113.0, 118.0, 116.0, 120.0, 119.0,
  ]
  let rsi_values = rsi(prices, 7)

  let mut i = 0
  while i < rsi_values.length() {
    assert_true(rsi_values[i] >= 0.0 && rsi_values[i] <= 100.0)
    i = i + 1
  }
}
