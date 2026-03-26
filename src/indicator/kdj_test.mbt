/// KDJ indicator tests

///|
test "kdj calculates correct values" {
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

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 3, 3, 3)

  // Verify we have correct number of values
  assert_eq(k_line.length(), klines.length())
  assert_eq(d_line.length(), klines.length())
  assert_eq(j_line.length(), klines.length())

  // First two values should be zero (leading zeros)
  assert_eq(k_line[0], Float::from_double(0.0))
  assert_eq(k_line[1], Float::from_double(0.0))

  // K values should be in 0-100 range (after leading zeros)
  let mut i = 2
  while i < k_line.length() {
    assert_true(k_line[i] >= Float::from_double(0.0))
    assert_true(k_line[i] <= Float::from_double(100.0))
    i = i + 1
  }
}

///|
test "kdj returns zeros for insufficient data" {
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

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)

  // All values should be zero when data < n_period
  assert_eq(k_line.length(), 1)
  assert_eq(d_line.length(), 1)
  assert_eq(j_line.length(), 1)
  assert_eq(k_line[0], Float::from_double(0.0))
}

///|
test "kdj j_line formula correct" {
  // J = 3*K - 2*D
  let klines = [
    @data.KLine::{
      code: "test",
      date: "2024-01-01",
      time: None,
      open: 100.0,
      high: 110.0,
      low: 90.0,
      close: 105.0,
      volume: 1000.0,
      amount: 100000.0,
      turn: 0.01,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-02",
      time: None,
      open: 105.0,
      high: 115.0,
      low: 100.0,
      close: 112.0,
      volume: 1200.0,
      amount: 120000.0,
      turn: 0.012,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-03",
      time: None,
      open: 112.0,
      high: 120.0,
      low: 108.0,
      close: 118.0,
      volume: 1100.0,
      amount: 110000.0,
      turn: 0.011,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-04",
      time: None,
      open: 118.0,
      high: 125.0,
      low: 115.0,
      close: 122.0,
      volume: 1300.0,
      amount: 130000.0,
      turn: 0.013,
    },
    @data.KLine::{
      code: "test",
      date: "2024-01-05",
      time: None,
      open: 122.0,
      high: 130.0,
      low: 118.0,
      close: 128.0,
      volume: 1400.0,
      amount: 140000.0,
      turn: 0.014,
    },
  ]

  let (k_line, d_line, j_line) = @indicator.kdj(klines, 2, 2, 2)

  // Verify J = 3*K - 2*D for non-zero values
  let three = Float::from_double(3.0)
  let two = Float::from_double(2.0)
  let mut i = 2
  while i < k_line.length() {
    let expected_j = three * k_line[i] - two * d_line[i]
    // Allow small floating point difference
    let diff = Float::abs(j_line[i] - expected_j)
    assert_true(diff < Float::from_double(0.0001))
    i = i + 1
  }
}

///|
test "kdj empty klines returns empty arrays" {
  let klines : Array[@data.KLine] = []
  let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)
  assert_eq(k_line.length(), 0)
  assert_eq(d_line.length(), 0)
  assert_eq(j_line.length(), 0)
}
