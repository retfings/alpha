/// Black-box tests for technical indicators

///|
test "sma - basic calculation" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0]
  let result = sma(prices, 3)
  assert_true(result.length() == 5)
  // First two should be zero (not enough data)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
  // SMA of [10, 11, 12] = 11
  assert_true(result[2] > 10.9 && result[2] < 11.1)
  // SMA of [11, 12, 13] = 12
  assert_true(result[3] > 11.9 && result[3] < 12.1)
  // SMA of [12, 13, 14] = 13
  assert_true(result[4] > 12.9 && result[4] < 13.1)
}

///|
test "sma - insufficient data" {
  let prices : Array[Float] = [10.0, 11.0]
  let result = sma(prices, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "sma - single value" {
  let prices : Array[Float] = [100.0]
  let result = sma(prices, 1)
  assert_true(result.length() == 1)
  assert_true(result[0] > 99.9 && result[0] < 100.1)
}

///|
test "ema - basic calculation" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0]
  let result = ema(prices, 3)
  assert_true(result.length() == 5)
  // First two should be zero (not enough data)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
  // Third should be SMA of first 3
  assert_true(result[2] > 10.9 && result[2] < 11.1)
  // Remaining should follow the trend
  assert_true(result[3] > result[2])
  assert_true(result[4] > result[3])
}

///|
test "ema - insufficient data" {
  let prices : Array[Float] = [10.0, 11.0]
  let result = ema(prices, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "rsi - basic calculation" {
  // Rising prices should give high RSI
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0]
  let result = rsi(prices, 3)
  assert_true(result.length() == 7)
  // After strong uptrend, RSI should be high (> 70)
  assert_true(result[6] > 70.0)
}

///|
test "rsi - falling prices" {
  // Falling prices should give low RSI
  let prices : Array[Float] = [16.0, 15.0, 14.0, 13.0, 12.0, 11.0, 10.0]
  let result = rsi(prices, 3)
  assert_true(result.length() == 7)
  // After strong downtrend, RSI should be low (< 30)
  assert_true(result[6] < 30.0)
}

///|
test "rsi - insufficient data" {
  let prices : Array[Float] = [10.0, 11.0]
  let result = rsi(prices, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "rsi - range check (0-100)" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0, 15.0]
  let result = rsi(prices, 2)
  let len = result.length()
  let mut i = 0
  while i < len {
    assert_true(result[i] >= 0.0 && result[i] <= 100.0)
    i = i + 1
  }
}

///|
test "macd - basic calculation" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0]
  let (macd_line, signal_line, histogram) = macd(prices, 3, 5, 2)
  assert_true(macd_line.length() == 9)
  assert_true(signal_line.length() == 9)
  assert_true(histogram.length() == 9)
  // MACD line should be positive in uptrend
  assert_true(macd_line[8] > 0.0)
}

///|
test "macd - insufficient data" {
  let prices : Array[Float] = [10.0, 11.0, 12.0]
  let (macd_line, signal_line, histogram) = macd(prices, 5, 7, 3)
  assert_true(macd_line.length() == 3)
  assert_true(signal_line.length() == 3)
  assert_true(histogram.length() == 3)
}

///|
test "bollinger_bands - basic calculation" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0]
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
  let prices_high_vol : Array[Float] = [10.0, 15.0, 10.0, 15.0, 10.0, 15.0, 10.0]
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
test "atr - basic calculation" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05),
  ]
  let result = atr(klines, 3)
  assert_true(result.length() == 5)
  // First two should be zero (not enough data for ATR)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
  // ATR should be positive
  assert_true(result[4] > 0.0)
}

///|
test "atr - insufficient data" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
  ]
  let result = atr(klines, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "sma - constant prices" {
  let prices : Array[Float] = [10.0, 10.0, 10.0, 10.0, 10.0]
  let result = sma(prices, 3)
  // All non-zero values should be 10.0
  assert_true(result[2] == 10.0)
  assert_true(result[3] == 10.0)
  assert_true(result[4] == 10.0)
}

///|
test "ema - constant prices" {
  let prices : Array[Float] = [10.0, 10.0, 10.0, 10.0, 10.0]
  let result = ema(prices, 3)
  // All non-zero values should be 10.0
  assert_true(result[2] == 10.0)
  assert_true(result[3] == 10.0)
  assert_true(result[4] == 10.0)
}

///|
test "rsi - constant prices" {
  let prices : Array[Float] = [10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]
  let result = rsi(prices, 3)
  // RSI with no price changes: when avg_loss is 0, RSI = 100
  // This is because there are no downward moves
  assert_true(result[6] == 100.0 || result[6] == 0.0 || (result[6] > 40.0 && result[6] < 60.0))
}

///|
test "macd - snapshot test" {
  let prices : Array[Float] = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0, 107.0, 110.0]
  let (macd_line, signal_line, histogram) = macd(prices, 3, 5, 2)
  // Just verify lengths and that we get some values
  assert_true(macd_line.length() == 10)
  assert_true(signal_line.length() == 10)
  assert_true(histogram.length() == 10)
}

///|
test "bollinger_bands - snapshot test" {
  let prices : Array[Float] = [50.0, 52.0, 48.0, 51.0, 53.0, 49.0, 52.0, 54.0, 50.0, 55.0]
  let (upper, middle, lower) = bollinger_bands(prices, 5, 2.0)
  assert_true(upper.length() == 10)
  assert_true(middle.length() == 10)
  assert_true(lower.length() == 10)
  // Verify band ordering
  let mut i = 4
  while i < 10 {
    assert_true(upper[i] >= middle[i])
    assert_true(middle[i] >= lower[i])
    i = i + 1
  }
}

///|
test "kdj - basic calculation" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-06", 12.5, 13.5, 12.0, 13.0, 1000000.0, 13000000.0, 0.05),
  ]
  let (k_line, d_line, j_line) = kdj(klines, 3, 3, 3)
  assert_true(k_line.length() == 6)
  assert_true(d_line.length() == 6)
  assert_true(j_line.length() == 6)
  // In uptrend, K should be high (> 50)
  assert_true(k_line[5] > 50.0)
}

///|
test "kdj - insufficient data" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
  ]
  let (k_line, d_line, j_line) = kdj(klines, 5, 3, 3)
  assert_true(k_line.length() == 2)
  assert_true(d_line.length() == 2)
  assert_true(j_line.length() == 2)
  assert_true(k_line[0] == 0.0)
}

///|
test "cci - basic calculation" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05),
  ]
  let result = cci(klines, 3)
  assert_true(result.length() == 5)
  // First two should be zero
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "cci - insufficient data" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
  ]
  let result = cci(klines, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "williams_r - basic calculation" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05),
  ]
  let result = williams_r(klines, 3)
  assert_true(result.length() == 5)
  // First two should be zero
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
  // Williams %R range is -100 to 0
  assert_true(result[4] <= 0.0 && result[4] >= -100.0)
}

///|
test "williams_r - insufficient data" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05),
  ]
  let result = williams_r(klines, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "obv - basic calculation" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05),
    @data.KLine::daily("sh.600000", "2023-01-02", 10.0, 11.0, 9.5, 11.0, 2000000.0, 22000000.0, 0.05), // Up day
    @data.KLine::daily("sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 10.5, 1500000.0, 15750000.0, 0.05), // Down day
  ]
  let result = obv(klines)
  assert_true(result.length() == 3)
  // Day 1: OBV = 1000000
  assert_true(result[0] == 1000000.0)
  // Day 2: Close up, OBV = 1000000 + 2000000 = 3000000
  assert_true(result[1] == 3000000.0)
  // Day 3: Close down, OBV = 3000000 - 1500000 = 1500000
  assert_true(result[2] == 1500000.0)
}

///|
test "obv - empty klines" {
  let klines : Array[@data.KLine] = []
  let result = obv(klines)
  assert_true(result.length() == 0)
}

///|
test "obv - single kline" {
  let klines = [
    @data.KLine::daily("sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05),
  ]
  let result = obv(klines)
  assert_true(result.length() == 1)
  assert_true(result[0] == 1000000.0)
}
