/// White-box tests for data module - test internal helpers

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
  let line = "2023-01-01, 10.5,11.0,10.2,10.8,1000000,10500000,0.05"
  match parse_kline_line(line) {
    None => assert_true(true)
    Some(_) => fail("Expected None")
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
    Some(kline) =>
      json_inspect(kline, content={
        "code": "",
        "date": "2023-01-01",
        "open": 10.5,
        "high": 11,
        "low": 10.199999809265137,
        "close": 10.800000190734863,
        "volume": 1000000,
        "amount": 10500000,
        "turn": 0.05000000447034836,
      })
    None => fail("Expected Some kline")
  }
}

///|
test "parse_kline_line - edge cases snapshot" {
  let edge_cases = [
    "2023-01-01,0,0,0,0,0,0,0", // All zeros
     "2023-01-01,0.001,0.002,0.0005,0.0015,1,100,0.0001", // Tiny values
     "2023-01-01,999999,1000000,999998,999999.5,999999999,999999999999,0.99", // Large values
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
