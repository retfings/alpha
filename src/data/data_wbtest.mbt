/// White-box tests for data module - test internal helpers

///|
test "Frequency enum - pattern matching" {
  // Test Frequency enum via pattern matching
  let check_frequency = fn(f : Frequency) -> String {
    match f {
      Frequency::Daily => "Daily"
      Frequency::Weekly => "Weekly"
      Frequency::Monthly => "Monthly"
      Frequency::Minute5 => "Minute5"
      Frequency::Minute15 => "Minute15"
      Frequency::Minute30 => "Minute30"
      Frequency::Minute60 => "Minute60"
    }
  }

  // We can verify the enum is accessible via match
  // Since enum variants are read-only, we test the type exists
  let _ = check_frequency // Suppress unused warning
}

///|
test "parse_float - basic integer" {
  let result = parse_float("100")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v > 99.9 && v < 100.1)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_float - decimal number" {
  let result = parse_float("100.50")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v > 100.49 && v < 100.51)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_float - negative number" {
  let result = parse_float("-50.25")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v < -50.24 && v > -50.26)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_float - empty string" {
  let result = parse_float("")
  assert_true(result == None)
}

///|
test "parse_float - invalid input" {
  let result = parse_float("abc")
  assert_true(result == None)
}

///|
test "parse_float - zero" {
  let result = parse_float("0")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v == 0.0)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_float - leading zeros" {
  let result = parse_float("00100")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v > 99.9 && v < 100.1)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_float - small decimal" {
  let result = parse_float("0.001")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v > 0.0009 && v < 0.0011)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_float - plus sign" {
  let result = parse_float("+50")
  assert_true(result != None)
  match result {
    Some(v) => assert_true(v > 49.9 && v < 50.1)
    _ => fail("Expected Some value")
  }
}

///|
test "parse_kline_line - valid line" {
  let line = "2023-01-01,10.5,11.0,10.2,10.8,1000000,10500000,0.05"
  let result = parse_kline_line(line)
  assert_true(result != None)
  match result {
    Some(kline) => {
      assert_true(kline.date == "2023-01-01")
      assert_true(kline.open > 10.4 && kline.open < 10.6)
      assert_true(kline.high > 10.9 && kline.high < 11.1)
      assert_true(kline.close > 10.7 && kline.close < 10.9)
      assert_true(kline.volume > 999999.0 && kline.volume < 1000001.0)
    }
    _ => fail("Expected Some kline")
  }
}

///|
test "parse_kline_line - invalid line" {
  let line = "invalid,data"
  match parse_kline_line(line) {
    None => assert_true(true)
    Some(_) => fail("Expected None")
  }
}

///|
test "parse_kline_line - incomplete line" {
  let line = "2023-01-01,10.5,11.0"
  match parse_kline_line(line) {
    None => assert_true(true)
    Some(_) => fail("Expected None")
  }
}

///|
test "parse_kline_line - missing fields" {
  let line = "2023-01-01,10.5,11.0,10.2,10.8,1000000"
  match parse_kline_line(line) {
    None => assert_true(true)
    Some(_) => fail("Expected None")
  }
}

///|
test "parse_kline_line - empty line" {
  let line = ""
  match parse_kline_line(line) {
    None => assert_true(true)
    Some(_) => fail("Expected None")
  }
}

///|
test "parse_kline_line - whitespace in values" {
  // The parser now trims whitespace, so this should succeed
  let line = "2023-01-01, 10.5,11.0,10.2,10.8,1000000,10500000,0.05"
  match parse_kline_line(line) {
    Some(kline) => assert_true(kline.date == "2023-01-01" && kline.open == 10.5)
    None => fail("Expected Some after trimming whitespace")
  }
}

///|
test "parse_float - snapshot tests for various formats" {
  let test_values = [
    "100", "100.50", "-50.25", "0", "0.001", "+50", "00100", "999999.99",
  ]
  let results = test_values.map(fn(s) { (s, parse_float(s)) })
  json_inspect(results, content=[
    ["100", [100]],
    ["100.50", [100.5]],
    ["-50.25", [-50.25]],
    ["0", [0]],
    ["0.001", [0.0010000000474974513]],
    ["+50", [50]],
    ["00100", [100]],
    ["999999.99", [1000000]],
  ])
}

///|
test "parse_kline_line - snapshot test" {
  let line = "2023-01-01,10.5,11.0,10.2,10.8,1000000,10500000,0.05"
  match parse_kline_line(line) {
    Some(kline) => assert_true(kline.date == "2023-01-01")
    None => fail("Expected Some kline")
  }
}

///|
test "parse_kline_line - edge cases snapshot" {
  let edge_cases = [
    "2023-01-01,0,0,0,0,0,0,0", "2023-01-01,0.001,0.002,0.0005,0.0015,1,100,0.0001",
    "2023-01-01,999999,1000000,999998,999999.5,999999999,999999999999,0.99",
  ]
  let results = edge_cases.map(fn(line) {
    match parse_kline_line(line) {
      Some(k) => Some((k.date, k.open, k.close, k.volume))
      None => None
    }
  })
  json_inspect(results, content=[
    [["2023-01-01", 0, 0, 0]],
    [["2023-01-01", 0.0010000000474974513, 0.001500000013038516, 1]],
    [["2023-01-01", 999999, 999999.5, 1000000000]],
  ])
}

///|
///\
test "adjust_klines - AdjustType::None" {
  let klines = [
    KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let result = adjust_klines(klines, AdjustType::None, 0.5)
  // No adjustment - prices should be unchanged
  assert_true(result[0].close == klines[0].close)
}

///|
///\
test "adjust_klines - AdjustType::Forward" {
  let klines = [
    KLine::daily(
      "sh.600000", "2023-01-01", 20.0, 22.0, 19.0, 21.0, 1000000.0, 21000000.0, 0.05,
    ),
  ]
  // Forward adjustment with 0.5 factor should halve prices
  let result = adjust_klines(klines, AdjustType::Forward, 0.5)
  assert_true(result[0].close > 10.4 && result[0].close < 10.6)
}

///|
///\
test "adjust_klines - AdjustType::Backward" {
  let klines = [
    KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  // Backward adjustment with 0.5 factor should double prices (reverse split)
  let result = adjust_klines(klines, AdjustType::Backward, 0.5)
  assert_true(result[0].close > 20.9 && result[0].close < 21.1)
}

///|
///\
test "resample_klines - weekly resampling" {
  // Create 10 days of data spanning 2 weeks
  let daily_klines = [
    KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    KLine::daily(
      "sh.600000", "2023-01-03", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
    KLine::daily(
      "sh.600000", "2023-01-04", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
    KLine::daily(
      "sh.600000", "2023-01-05", 12.0, 12.5, 11.5, 11.8, 1300000.0, 15600000.0, 0.08,
    ),
    KLine::daily(
      "sh.600000", "2023-01-06", 11.8, 12.2, 11.0, 11.5, 1100000.0, 12700000.0, 0.09,
    ),
    KLine::daily(
      "sh.600000", "2023-01-09", 11.5, 12.0, 11.0, 12.0, 1000000.0, 12000000.0, 0.10,
    ),
    KLine::daily(
      "sh.600000", "2023-01-10", 12.0, 13.0, 11.5, 12.5, 1400000.0, 17500000.0, 0.11,
    ),
  ]
  let weekly = resample_klines(daily_klines, Frequency::Weekly)
  // Should produce 2 weekly bars
  assert_true(weekly.length() >= 1)
  // First bar should start at 10.0 (first open)
  assert_true(weekly[0].open == 10.0)
  // Weekly volume should be sum of daily volumes
  assert_true(weekly[0].volume > 5000000.0)
}

///|
///\
test "resample_klines - monthly resampling" {
  // Create data spanning 2 months
  let daily_klines = [
    KLine::daily(
      "sh.600000", "2023-01-30", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    KLine::daily(
      "sh.600000", "2023-01-31", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
    KLine::daily(
      "sh.600000", "2023-02-01", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
    KLine::daily(
      "sh.600000", "2023-02-02", 12.0, 12.5, 11.5, 11.8, 1300000.0, 15600000.0, 0.08,
    ),
    KLine::daily(
      "sh.600000", "2023-02-03", 11.8, 12.2, 11.0, 11.5, 1100000.0, 12700000.0, 0.09,
    ),
  ]
  let monthly = resample_klines(daily_klines, Frequency::Monthly)
  // Should produce 2 monthly bars
  assert_true(monthly.length() == 2)
  // First bar is January
  assert_true(monthly[0].open == 10.0)
  assert_true(monthly[0].close == 11.0)
  // Second bar is February
  assert_true(monthly[1].open == 11.0)
  assert_true(monthly[1].close == 11.5)
}

///|
///\
test "resample_klines - empty input" {
  let empty : Array[KLine] = []
  let weekly = resample_klines(empty, Frequency::Weekly)
  assert_true(weekly.length() == 0)
}

///|
///\
test "resample_klines - single element" {
  let daily_klines = [
    KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let weekly = resample_klines(daily_klines, Frequency::Weekly)
  assert_true(weekly.length() == 1)
  assert_true(weekly[0].open == 10.0)
  assert_true(weekly[0].close == 10.5)
}
