/// OBV indicator tests

///|
test "obv calculates correct values" {
  // Create test K-line data with known price directions
  let klines = [
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 105.0,
      low: 95.0,
      close: 102.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-02",
      time: None,
      open: 102.0,
      high: 108.0,
      low: 100.0,
      close: 106.0,
      volume: 1200.0,
      amount: 120000.0,
      turn: 0.012,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-03",
      time: None,
      open: 106.0,
      high: 110.0,
      low: 104.0,
      close: 108.0,
      volume: 1100.0,
      amount: 110000.0,
      turn: 0.011,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-04",
      time: None,
      open: 108.0,
      high: 112.0,
      low: 106.0,
      close: 105.0,
      volume: 1300.0,
      amount: 130000.0,
      turn: 0.013,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-05",
      time: None,
      open: 105.0,
      high: 110.0,
      low: 103.0,
      close: 107.0,
      volume: 1400.0,
      amount: 140000.0,
      turn: 0.014,
    },
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
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 105.0,
      low: 95.0,
      close: 100.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-02",
      time: None,
      open: 99.0,
      high: 101.0,
      low: 97.0,
      close: 98.0,
      volume: 1200.0,
      amount: 120000.0,
      turn: 0.012,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-03",
      time: None,
      open: 97.0,
      high: 99.0,
      low: 95.0,
      close: 96.0,
      volume: 1100.0,
      amount: 110000.0,
      turn: 0.011,
    },
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
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 105.0,
      low: 95.0,
      close: 100.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-02",
      time: None,
      open: 100.0,
      high: 105.0,
      low: 95.0,
      close: 100.0,
      volume: 1200.0,
      amount: 120000.0,
      turn: 0.012,
    },
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
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 105.0,
      low: 95.0,
      close: 102.0,
      volume: 1500.0,
      amount: 150000.0,
      turn: 0.015,
    },
  ]

  let obv_values = @indicator.obv(klines)

  assert_eq(obv_values.length(), 1)
  assert_eq(obv_values[0], Float::from_double(1500.0))
}
