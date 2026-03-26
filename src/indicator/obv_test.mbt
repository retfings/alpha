/// OBV indicator tests

///|
test "obv calculates correct values" {
  // Create test K-line data with known price directions
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
      "test", "2024-01-04", 108.0, 112.0, 106.0, 105.0, 1300.0, 130000.0, 0.013,
    ),
    @data.KLine::daily(
      "test", "2024-01-05", 105.0, 110.0, 103.0, 107.0, 1400.0, 140000.0, 0.014,
    ),
  ]

  let obv_values = @indicator.obv(klines)

  // Verify we have correct number of values
  assert_eq(obv_values.length(), klines.length())

  // First OBV = first volume = 1000
  assert_eq(obv_values[0], Float::from_double(1000.0))

  // Second close (106) > first close (102), so OBV = 1000 + 1200 = 2200
  assert_eq(obv_values[1], Float::from_double(2200.0))

  // Third close (108) > second close (106), so OBV = 2200 + 1100 = 3300
  assert_eq(obv_values[2], Float::from_double(3300.0))

  // Fourth close (105) < third close (108), so OBV = 3300 - 1300 = 2000
  assert_eq(obv_values[3], Float::from_double(2000.0))

  // Fifth close (107) > fourth close (105), so OBV = 2000 + 1400 = 3400
  assert_eq(obv_values[4], Float::from_double(3400.0))
}

///|
test "obv handles down days" {
  // Create test data with consecutive down days
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 99.0, 101.0, 97.0, 98.0, 1200.0, 120000.0, 0.012,
    ),
    @data.KLine::daily(
      "test", "2024-01-03", 97.0, 99.0, 95.0, 96.0, 1100.0, 110000.0, 0.011,
    ),
  ]

  let obv_values = @indicator.obv(klines)

  // First OBV = 1000
  assert_eq(obv_values[0], Float::from_double(1000.0))

  // Second close (98) < first close (100), so OBV = 1000 - 1200 = -200
  assert_eq(obv_values[1], Float::from_double(-200.0))

  // Third close (96) < second close (98), so OBV = -200 - 1100 = -1300
  assert_eq(obv_values[2], Float::from_double(-1300.0))
}

///|
test "obv handles equal close prices" {
  // Create test data with equal close prices
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 100.0, 1000.0, 100000.0, 0.01,
    ),
    @data.KLine::daily(
      "test", "2024-01-02", 100.0, 105.0, 95.0, 100.0, 1200.0, 120000.0, 0.012,
    ),
  ]

  let obv_values = @indicator.obv(klines)

  // First OBV = 1000
  assert_eq(obv_values[0], Float::from_double(1000.0))

  // Second close == first close, so OBV doesn't change = 1000
  assert_eq(obv_values[1], Float::from_double(1000.0))
}

///|
test "obv empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let obv_values = @indicator.obv(klines)
  assert_eq(obv_values.length(), 0)
}

///|
test "obv single kline returns single value" {
  let klines = [
    @data.KLine::daily(
      "test", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 1500.0, 150000.0, 0.015,
    ),
  ]

  let obv_values = @indicator.obv(klines)

  assert_eq(obv_values.length(), 1)
  assert_eq(obv_values[0], Float::from_double(1500.0))
}
