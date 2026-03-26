/// RSI indicator tests

///|
test "rsi calculates correct values for uptrend" {
  // Simulate a strong uptrend
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(114.0),
    Float::from_double(116.0),
    Float::from_double(118.0),
    Float::from_double(120.0),
    Float::from_double(122.0),
    Float::from_double(124.0),
    Float::from_double(126.0),
    Float::from_double(128.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)

  // Should have same length as input
  assert_eq(rsi_values.length(), prices.length())

  // First 14 values should be zero (insufficient data)
  let mut i = 0
  while i < 14 {
    assert_eq(rsi_values[i], Float::from_double(0.0))
    i = i + 1
  }

  // RSI should be very high (strong uptrend = overbought)
  let last_rsi = rsi_values[rsi_values.length() - 1]
  assert_true(last_rsi > Float::from_double(70.0))
}

///|
test "rsi calculates correct values for downtrend" {
  // Simulate a strong downtrend
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(98.0),
    Float::from_double(96.0),
    Float::from_double(94.0),
    Float::from_double(92.0),
    Float::from_double(90.0),
    Float::from_double(88.0),
    Float::from_double(86.0),
    Float::from_double(84.0),
    Float::from_double(82.0),
    Float::from_double(80.0),
    Float::from_double(78.0),
    Float::from_double(76.0),
    Float::from_double(74.0),
    Float::from_double(72.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)

  // Should have same length as input
  assert_eq(rsi_values.length(), prices.length())

  // First 14 values should be zero
  let mut i = 0
  while i < 14 {
    assert_eq(rsi_values[i], Float::from_double(0.0))
    i = i + 1
  }

  // RSI should be very low (strong downtrend = oversold)
  let last_rsi = rsi_values[rsi_values.length() - 1]
  assert_true(last_rsi < Float::from_double(30.0))
}

///|
test "rsi returns zeros for insufficient data" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)

  // All values should be zero when data < period
  assert_eq(rsi_values.length(), 3)
  let mut i = 0
  while i < rsi_values.length() {
    assert_eq(rsi_values[i], Float::from_double(0.0))
    i = i + 1
  }
}

///|
test "rsi returns zeros for empty input" {
  let prices : Array[Float] = []

  let rsi_values = @indicator.rsi(prices, 14)

  assert_eq(rsi_values.length(), 0)
}

///|
test "rsi handles flat prices (no change)" {
  // All prices are the same - no gains or losses
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
    Float::from_double(100.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)

  // First 14 values should be zero
  let mut i = 0
  while i < 14 {
    assert_eq(rsi_values[i], Float::from_double(0.0))
    i = i + 1
  }

  // When avg_loss = 0, RSI should be 100
  let first_rsi = rsi_values[14]
  assert_eq(first_rsi, Float::from_double(100.0))
}

///|
test "rsi period boundary" {
  // Exactly at period boundary
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(101.0),
    Float::from_double(102.0),
    Float::from_double(103.0),
    Float::from_double(104.0),
    Float::from_double(105.0),
    Float::from_double(106.0),
    Float::from_double(107.0),
    Float::from_double(108.0),
    Float::from_double(109.0),
    Float::from_double(110.0),
    Float::from_double(111.0),
    Float::from_double(112.0),
    Float::from_double(113.0),
    Float::from_double(114.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)

  // Should have 15 values
  assert_eq(rsi_values.length(), 15)

  // First 14 should be zero
  assert_eq(rsi_values[13], Float::from_double(0.0))

  // 15th should be non-zero (first RSI calculation)
  assert_true(rsi_values[14] > Float::from_double(0.0))
}

///|
test "is_overbought detects overbought condition" {
  // RSI above 70 is overbought
  assert_true(
    @indicator.is_overbought(Float::from_double(71.0), Float::from_double(70.0)),
  )
  assert_true(
    @indicator.is_overbought(Float::from_double(80.0), Float::from_double(70.0)),
  )
  assert_true(
    @indicator.is_overbought(Float::from_double(90.0), Float::from_double(70.0)),
  )

  // RSI at or below 70 is not overbought
  assert_true(
    !@indicator.is_overbought(
      Float::from_double(70.0),
      Float::from_double(70.0),
    ),
  )
  assert_true(
    !@indicator.is_overbought(
      Float::from_double(50.0),
      Float::from_double(70.0),
    ),
  )
  assert_true(
    !@indicator.is_overbought(
      Float::from_double(30.0),
      Float::from_double(70.0),
    ),
  )
}

///|
test "is_oversold detects oversold condition" {
  // RSI below 30 is oversold
  assert_true(
    @indicator.is_oversold(Float::from_double(29.0), Float::from_double(30.0)),
  )
  assert_true(
    @indicator.is_oversold(Float::from_double(20.0), Float::from_double(30.0)),
  )
  assert_true(
    @indicator.is_oversold(Float::from_double(10.0), Float::from_double(30.0)),
  )

  // RSI at or above 30 is not oversold
  assert_true(
    !@indicator.is_oversold(Float::from_double(30.0), Float::from_double(30.0)),
  )
  assert_true(
    !@indicator.is_oversold(Float::from_double(50.0), Float::from_double(30.0)),
  )
  assert_true(
    !@indicator.is_oversold(Float::from_double(70.0), Float::from_double(30.0)),
  )
}

///|
test "rsi with period 2" {
  // Test with minimum practical period
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
  ]

  let rsi_values = @indicator.rsi(prices, 2)

  // Should have same length as input
  assert_eq(rsi_values.length(), 5)

  // First 2 values should be zero
  assert_eq(rsi_values[0], Float::from_double(0.0))
  assert_eq(rsi_values[1], Float::from_double(0.0))

  // Third value should be non-zero
  assert_true(rsi_values[2] > Float::from_double(0.0))
}

///|
test "rsi alternating gains and losses" {
  // Alternating up and down movements
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
    Float::from_double(100.0),
    Float::from_double(105.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)

  // RSI should oscillate around 50 (balanced market)
  let last_rsi = rsi_values[rsi_values.length() - 1]
  assert_true(last_rsi > Float::from_double(40.0))
  assert_true(last_rsi < Float::from_double(60.0))
}

///|
test "rsi range check (0-100)" {
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
  let result = @indicator.rsi(prices, 3)

  // All RSI values should be in 0-100 range
  let len = result.length()
  let mut i = 0
  while i < len {
    assert_true(result[i] >= Float::from_double(0.0))
    assert_true(result[i] <= Float::from_double(100.0))
    i = i + 1
  }
}

///|
test "rsi period equals array length" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
    Float::from_double(12.0),
    Float::from_double(13.0),
    Float::from_double(14.0),
  ]
  let result = @indicator.rsi(prices, 5)

  assert_eq(result.length(), 5)
  // All should be zero (period equals array length)
  let mut i = 0
  while i < 5 {
    assert_eq(result[i], Float::from_double(0.0))
    i = i + 1
  }
}

///|
test "rsi period zero edge case" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
    Float::from_double(12.0),
    Float::from_double(13.0),
    Float::from_double(14.0),
  ]
  let result = @indicator.rsi(prices, 0)

  // With period 0, all values should be zero
  assert_eq(result.length(), 5)
  assert_eq(result[0], Float::from_double(0.0))
  assert_eq(result[4], Float::from_double(0.0))
}

///|
test "rsi large price jump" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(10.0),
    Float::from_double(10.0),
    Float::from_double(10.0),
    Float::from_double(50.0),
    Float::from_double(50.0),
    Float::from_double(50.0),
    Float::from_double(50.0),
  ]
  let result = @indicator.rsi(prices, 3)

  assert_eq(result.length(), 8)
  // After large jump, RSI should spike
  assert_true(result[4] > Float::from_double(50.0))
}

///|
test "rsi gradual uptrend then decline" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
    Float::from_double(12.0),
    Float::from_double(13.0),
    Float::from_double(14.0),
    Float::from_double(13.0),
    Float::from_double(12.0),
    Float::from_double(11.0),
  ]
  let result = @indicator.rsi(prices, 3)

  // RSI should rise then fall
  assert_true(result[4] > result[7])
  assert_true(result[4] > Float::from_double(50.0))
  assert_true(result[7] < Float::from_double(50.0))
}

///|
test "rsi helper boundary conditions" {
  // Test is_overbought at boundary
  assert_true(
    !@indicator.is_overbought(Float::from_double(70.0), Float::from_double(70.0)),
  )
  assert_true(
    @indicator.is_overbought(Float::from_double(70.1), Float::from_double(70.0)),
  )
  assert_true(
    !@indicator.is_overbought(Float::from_double(69.9), Float::from_double(70.0)),
  )

  // Test is_oversold at boundary
  assert_true(
    !@indicator.is_oversold(Float::from_double(30.0), Float::from_double(30.0)),
  )
  assert_true(
    @indicator.is_oversold(Float::from_double(29.9), Float::from_double(30.0)),
  )
  assert_true(
    !@indicator.is_oversold(Float::from_double(30.1), Float::from_double(30.0)),
  )
}

///|
test "rsi different periods comparison" {
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

  let rsi_7 = @indicator.rsi(prices, 7)
  let rsi_14 = @indicator.rsi(prices, 14)

  assert_eq(rsi_7.length(), 20)
  assert_eq(rsi_14.length(), 20)

  // Shorter period should be more responsive
  assert_true(rsi_7[19] >= rsi_14[19])
}

///|
test "rsi single value" {
  let prices : Array[Float] = [Float::from_double(100.0)]
  let result = @indicator.rsi(prices, 2)
  assert_eq(result.length(), 1)
  assert_eq(result[0], Float::from_double(0.0))
}

///|
test "rsi snapshot test" {
  let prices : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
  ]
  let result = @indicator.rsi(prices, 3)
  assert_eq(result.length(), 8)
  inspect(result, content=(
    #|[0, 0, 0, 80, 87.5, 68.29268646240234, 80.88235473632812, 88.0184326171875]
  ))
}
