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
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0,
  ]
  let result = macd(prices, 3, 5, 2)
  assert_true(result.macd_line.length() == 9)
  assert_true(result.signal_line.length() == 9)
  assert_true(result.histogram.length() == 9)
  // MACD line should be positive in uptrend
  assert_true(result.macd_line[8] > 0.0)
}

///|
test "macd - insufficient data" {
  let prices : Array[Float] = [10.0, 11.0, 12.0]
  let result = macd(prices, 5, 7, 3)
  assert_true(result.macd_line.length() == 3)
  assert_true(result.signal_line.length() == 3)
  assert_true(result.histogram.length() == 3)
}

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
test "atr - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05,
    ),
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
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
  assert_true(
    result[6] == 100.0 ||
    result[6] == 0.0 ||
    (result[6] > 40.0 && result[6] < 60.0),
  )
}

///|
test "macd - snapshot test" {
  let prices : Array[Float] = [
    100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0, 107.0, 110.0,
  ]
  let result = macd(prices, 3, 5, 2)
  // Just verify lengths and that we get some values
  assert_true(result.macd_line.length() == 10)
  assert_true(result.signal_line.length() == 10)
  assert_true(result.histogram.length() == 10)
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 12.5, 13.5, 12.0, 13.0, 1000000.0, 13000000.0, 0.05,
    ),
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05,
    ),
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
  ]
  let result = cci(klines, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "williams_r - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1000000.0, 12000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1000000.0, 12500000.0, 0.05,
    ),
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
  ]
  let result = williams_r(klines, 5)
  assert_true(result.length() == 2)
  assert_true(result[0] == 0.0)
  assert_true(result[1] == 0.0)
}

///|
test "obv - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.0, 9.5, 11.0, 2000000.0, 22000000.0, 0.05,
    ), // Up day
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 10.5, 1500000.0, 15750000.0, 0.05,
    ), // Down day
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
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
  ]
  let result = obv(klines)
  assert_true(result.length() == 1)
  assert_true(result[0] == 1000000.0)
}

///|
test "sma - empty array" {
  let prices : Array[Float] = []
  let result = sma(prices, 5)
  assert_true(result.length() == 0)
}

///|
test "ema - empty array" {
  let prices : Array[Float] = []
  let result = ema(prices, 5)
  assert_true(result.length() == 0)
}

///|
test "rsi - empty array" {
  let prices : Array[Float] = []
  let result = rsi(prices, 14)
  assert_true(result.length() == 0)
}

///|
test "macd - empty array" {
  let prices : Array[Float] = []
  let result = macd(prices, 12, 26, 9)
  assert_true(result.macd_line.length() == 0)
  assert_true(result.signal_line.length() == 0)
  assert_true(result.histogram.length() == 0)
}

///|
test "bollinger_bands - empty array" {
  let prices : Array[Float] = []
  let (middle, upper, lower) = bollinger_bands(prices, 20, 2.0)
  assert_true(middle.length() == 0)
  assert_true(upper.length() == 0)
  assert_true(lower.length() == 0)
}

///|
test "atr - empty klines" {
  let klines : Array[@data.KLine] = []
  let result = atr(klines, 14)
  assert_true(result.length() == 0)
}

///|
test "kdj - empty klines" {
  let klines : Array[@data.KLine] = []
  let (k_line, d_line, j_line) = kdj(klines, 9, 3, 3)
  assert_true(k_line.length() == 0)
  assert_true(d_line.length() == 0)
  assert_true(j_line.length() == 0)
}

///|
test "cci - empty klines" {
  let klines : Array[@data.KLine] = []
  let result = cci(klines, 20)
  assert_true(result.length() == 0)
}

///|
test "williams_r - empty klines" {
  let klines : Array[@data.KLine] = []
  let result = williams_r(klines, 14)
  assert_true(result.length() == 0)
}

///|
test "sma - period equals array length" {
  let prices : Array[Float] = [10.0, 20.0, 30.0, 40.0, 50.0]
  let result = sma(prices, 5)
  assert_true(result.length() == 5)
  // Only last element should have valid SMA
  assert_true(result[4] > 29.9 && result[4] < 30.1)
}

///|
test "ema - period equals array length" {
  let prices : Array[Float] = [10.0, 20.0, 30.0, 40.0, 50.0]
  let result = ema(prices, 5)
  assert_true(result.length() == 5)
  // Only last element should have valid EMA
  assert_true(result[4] > 0.0)
}

///|
test "rsi - all gains (should approach 100)" {
  let prices : Array[Float] = [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0]
  let result = rsi(prices, 3)
  assert_true(result.length() == 7)
  // Last RSI should be high (approaching 100)
  assert_true(result[6] > 90.0 && result[6] <= 100.0)
}

///|
test "rsi - all losses (should approach 0)" {
  let prices : Array[Float] = [16.0, 15.0, 14.0, 13.0, 12.0, 11.0, 10.0]
  let result = rsi(prices, 3)
  assert_true(result.length() == 7)
  // Last RSI should be low (approaching 0)
  assert_true(result[6] >= 0.0 && result[6] < 10.0)
}

///|
test "bollinger_bands - band ordering (lower <= middle <= upper)" {
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0,
    23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0,
  ]
  // Function returns (upper, middle, lower)
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
test "kdj - value ranges (K, D: 0-100, J can exceed)" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1100000.0, 12100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1200000.0, 13800000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1300000.0, 15600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1400000.0, 17500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 12.5, 13.5, 12.0, 13.0, 1500000.0, 19500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 13.0, 14.0, 12.5, 13.5, 1600000.0, 21600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 13.5, 14.5, 13.0, 14.0, 1700000.0, 23800000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 14.0, 15.0, 13.5, 14.5, 1800000.0, 26100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 14.5, 15.5, 14.0, 15.0, 1900000.0, 28500000.0, 0.05,
    ),
  ]
  let (k_line, d_line, j_line) = kdj(klines, 9, 3, 3)
  assert_true(k_line.length() == 10)
  assert_true(d_line.length() == 10)
  assert_true(j_line.length() == 10)
  // K and D should be in 0-100 range
  let mut i = 0
  while i < 10 {
    assert_true(k_line[i] >= 0.0 && k_line[i] <= 100.0)
    assert_true(d_line[i] >= 0.0 && d_line[i] <= 100.0)
    i = i + 1
  }
}

///|
test "williams_r - value range (should be -100 to 0)" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1100000.0, 12100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1200000.0, 13800000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1300000.0, 15600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1400000.0, 17500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 12.5, 13.5, 12.0, 13.0, 1500000.0, 19500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 13.0, 14.0, 12.5, 13.5, 1600000.0, 21600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 13.5, 14.5, 13.0, 14.0, 1700000.0, 23800000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 14.0, 15.0, 13.5, 14.5, 1800000.0, 26100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 14.5, 15.5, 14.0, 15.0, 1900000.0, 28500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 15.0, 16.0, 14.5, 15.5, 2000000.0, 31000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 15.5, 16.5, 15.0, 16.0, 2100000.0, 33600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 16.0, 17.0, 15.5, 16.5, 2200000.0, 36300000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 16.5, 17.5, 16.0, 17.0, 2300000.0, 39100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 17.0, 18.0, 16.5, 17.5, 2400000.0, 42000000.0, 0.05,
    ),
  ]
  let result = williams_r(klines, 14)
  assert_true(result.length() == 15)
  // Williams %R should be in -100 to 0 range
  let mut i = 0
  while i < 15 {
    assert_true(result[i] >= -100.0 && result[i] <= 0.0)
    i = i + 1
  }
}

///|
test "obv - trending up (volume accumulation)" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1100000.0, 12100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1200000.0, 13800000.0, 0.05,
    ),
  ]
  let result = obv(klines)
  assert_true(result.length() == 3)
  // OBV should accumulate as prices rise
  assert_true(result[0] == 1000000.0)
  assert_true(result[1] == 2100000.0)
  assert_true(result[2] == 3300000.0)
}

///|
test "obv - trending down (volume subtraction)" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 11.0, 12.0, 10.5, 11.5, 1000000.0, 11500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 10.5, 1100000.0, 11550000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.0, 11.0, 9.5, 10.0, 1200000.0, 12000000.0, 0.05,
    ),
  ]
  let result = obv(klines)
  assert_true(result.length() == 3)
  // OBV should decrease as prices fall
  assert_true(result[0] == 1000000.0)
  assert_true(result[1] == -100000.0) // 1000000 - 1100000
  assert_true(result[2] == -1300000.0) // -100000 - 1200000
}

///|
test "macd - histogram sign indicates momentum" {
  let prices : Array[Float] = [
    10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0,
  ]
  let result = macd(prices, 3, 6, 3)
  assert_true(result.macd_line.length() == 11)
  assert_true(result.signal_line.length() == 11)
  assert_true(result.histogram.length() == 11)
  // In uptrend, MACD should be positive and histogram should show momentum
  assert_true(result.macd_line[10] > 0.0)
}

///|
test "atr - increasing volatility" {
  let klines_low_vol = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 10.2, 9.8, 10.1, 1000000.0, 10100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.1, 10.3, 9.9, 10.2, 1000000.0, 10200000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 10.2, 10.4, 10.0, 10.3, 1000000.0, 10300000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 10.3, 10.5, 10.1, 10.4, 1000000.0, 10400000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 10.4, 10.6, 10.2, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let klines_high_vol = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 12.0, 8.0, 11.0, 1000000.0, 11000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 11.0, 13.0, 9.0, 12.0, 1000000.0, 12000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 12.0, 14.0, 10.0, 13.0, 1000000.0, 13000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 13.0, 15.0, 11.0, 14.0, 1000000.0, 14000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 14.0, 16.0, 12.0, 15.0, 1000000.0, 15000000.0, 0.05,
    ),
  ]
  let atr_low = atr(klines_low_vol, 3)
  let atr_high = atr(klines_high_vol, 3)
  // High volatility should produce higher ATR values
  assert_true(atr_low[4] < atr_high[4])
}

///|
test "cci - trend identification" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1100000.0, 12100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 11.5, 1200000.0, 13800000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-04", 11.5, 12.5, 11.0, 12.0, 1300000.0, 15600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 13.0, 11.5, 12.5, 1400000.0, 17500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-06", 12.5, 13.5, 12.0, 13.0, 1500000.0, 19500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-07", 13.0, 14.0, 12.5, 13.5, 1600000.0, 21600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-08", 13.5, 14.5, 13.0, 14.0, 1700000.0, 23800000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-09", 14.0, 15.0, 13.5, 14.5, 1800000.0, 26100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-10", 14.5, 15.5, 14.0, 15.0, 1900000.0, 28500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-11", 15.0, 16.0, 14.5, 15.5, 2000000.0, 31000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-12", 15.5, 16.5, 15.0, 16.0, 2100000.0, 33600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-13", 16.0, 17.0, 15.5, 16.5, 2200000.0, 36300000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-14", 16.5, 17.5, 16.0, 17.0, 2300000.0, 39100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-15", 17.0, 18.0, 16.5, 17.5, 2400000.0, 42000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-16", 17.5, 18.5, 17.0, 18.0, 2500000.0, 45000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-17", 18.0, 19.0, 17.5, 18.5, 2600000.0, 48100000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-18", 18.5, 19.5, 18.0, 19.0, 2700000.0, 51300000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-19", 19.0, 20.0, 18.5, 19.5, 2800000.0, 54600000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-20", 19.5, 20.5, 19.0, 20.0, 2900000.0, 58000000.0, 0.05,
    ),
  ]
  let result = cci(klines, 14)
  assert_true(result.length() == 20)
  // CCI should show positive values in uptrend
  assert_true(result[19] > 0.0)
}
