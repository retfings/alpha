/// Williams %R indicator tests

///|
test "williams_r calculates correct values" {
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

  let wr_values = @indicator.williams_r(klines, 3)

  // Verify we have correct number of values
  assert_eq(wr_values.length(), klines.length())

  // First two values should be zero (leading zeros for period 3)
  assert_eq(wr_values[0], Float::from_double(0.0))
  assert_eq(wr_values[1], Float::from_double(0.0))

  // Williams %R should be in -100 to 0 range (after leading zeros)
  let mut i = 2
  while i < wr_values.length() {
    assert_true(wr_values[i] <= Float::from_double(0.0))
    assert_true(wr_values[i] >= Float::from_double(-100.0))
    i = i + 1
  }
}

///|
test "williams_r returns zeros for insufficient data" {
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

  let wr_values = @indicator.williams_r(klines, 5)

  // All values should be zero when data < period
  assert_eq(wr_values.length(), 1)
  assert_eq(wr_values[0], Float::from_double(0.0))
}

///|
test "williams_r formula verification" {
  // Test with known values
  // Williams %R = (Highest High - Close) / (Highest High - Lowest Low) * -100
  let klines = [
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 100.0,
      low: 80.0,
      close: 90.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-02",
      time: None,
      open: 90.0,
      high: 100.0,
      low: 80.0,
      close: 80.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
  ]

  let wr_values = @indicator.williams_r(klines, 2)

  // For period 2, second value:
  // Highest High = 100, Lowest Low = 80, Close = 80
  // WR = (100 - 80) / (100 - 80) * -100 = 20/20 * -100 = -100
  assert_eq(wr_values[1], Float::from_double(-100.0))
}

///|
test "williams_r empty klines returns empty array" {
  let klines : Array[@data.KLine] = []
  let wr_values = @indicator.williams_r(klines, 14)
  assert_eq(wr_values.length(), 0)
}
