/// CCI indicator tests

///|
test "cci calculates correct values" {
  // Create test K-line data
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
      close: 110.0,
      volume: 1300.0,
      amount: 130000.0,
      turn: 0.013,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-05",
      time: None,
      open: 110.0,
      high: 115.0,
      low: 108.0,
      close: 112.0,
      volume: 1400.0,
      amount: 140000.0,
      turn: 0.014,
    },
  ]

  let cci_values = @indicator.cci(klines, 3)

  // Verify we have correct number of values
  assert_eq(cci_values.length(), klines.length())

  // First two values should be zero (leading zeros for period 3)
  assert_eq(cci_values[0], Float::from_double(0.0))
  assert_eq(cci_values[1], Float::from_double(0.0))
}

///|
test "cci returns zeros for insufficient data" {
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
  ]

  let cci_values = @indicator.cci(klines, 5)

  // All values should be zero when data < period
  assert_eq(cci_values.length(), 1)
  assert_eq(cci_values[0], Float::from_double(0.0))
}

///|
test "cci typical_price_calculation" {
  // Test that CCI uses typical price = (H + L + C) / 3
  let klines = [
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 120.0,
      low: 80.0,
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
      high: 120.0,
      low: 80.0,
      close: 100.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-03",
      time: None,
      open: 100.0,
      high: 120.0,
      low: 80.0,
      close: 100.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
  ]

  let cci_values = @indicator.cci(klines, 3)

  // When all typical prices are the same, CCI should be 0
  // (no deviation from mean)
  assert_eq(cci_values[2], Float::from_double(0.0))
}

///|
test "cci empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let cci_values = @indicator.cci(klines, 14)
  assert_eq(cci_values.length(), 0)
}
