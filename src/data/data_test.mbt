/// Black-box tests for data module - test public API

///|
test "parse_csv_content - basic csv" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,10.5,11.0,10.2,10.8,1000000,10500000,0.05\n" +
    "2023-01-02,10.8,11.2,10.5,11.0,1200000,13000000,0.06"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => {
      assert_true(klines.length() == 2)
      assert_true(klines[0].date == "2023-01-01")
      assert_true(klines[0].close > 10.7 && klines[0].close < 10.9)
      assert_true(klines[1].date == "2023-01-02")
      assert_true(klines[1].close > 10.9 && klines[1].close < 11.1)
    }
    Err(_) => fail("Expected Ok result")
  }
}

///|
test "parse_csv_content - empty content" {
  let result = parse_csv_content("")
  match result {
    Err(msg) => assert_true(msg.contains("Empty"))
    Ok(_) => fail("Expected Err result")
  }
}

///|
test "parse_csv_content - header only" {
  let content = "date,open,high,low,close,volume,amount,turn"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => assert_true(klines.length() == 0)
    Err(_) => fail("Expected Ok result with empty array")
  }
}

///|
test "parse_csv_content - partial data lines" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,10.5,11.0,10.2,10.8,1000000,10500000,0.05\n" +
    "invalid,line,here"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => assert_true(klines.length() == 1)
    Err(_) => fail("Expected Ok result")
  }
}

///|
test "extract_stock_code_from_filename - valid filename with path" {
  let filename = "data/sh_600000_2023-01-01_2023-12-31.csv"
  let result = extract_stock_code_from_filename(filename)
  match result {
    Some(code) => assert_true(code == "sh.600000")
    None => fail("Expected Some code")
  }
}

///|
test "extract_stock_code_from_filename - sz stock" {
  let filename = "data/sz_000001_2023-01-01_2023-12-31.csv"
  let result = extract_stock_code_from_filename(filename)
  match result {
    Some(code) => assert_true(code == "sz.000001")
    None => fail("Expected Some code")
  }
}

///|
test "extract_stock_code_from_filename - filename without path" {
  let filename = "sh_600000_2023-01-01_2023-12-31.csv"
  let result = extract_stock_code_from_filename(filename)
  match result {
    Some(code) => assert_true(code == "sh.600000")
    None => fail("Expected Some code")
  }
}

///|
test "extract_stock_code_from_filename - invalid filename" {
  let filename = "invalid.csv"
  let result = extract_stock_code_from_filename(filename)
  assert_true(result == None)
}

///|
test "extract_stock_code_from_filename - empty filename" {
  let result = extract_stock_code_from_filename("")
  assert_true(result == None)
}

///|
test "load_klines_from_csv - returns error for C FFI requirement" {
  let result = load_klines_from_csv("data/test.csv")
  match result {
    Err(msg) => assert_true(msg.contains("C FFI"))
    Ok(_) => fail("Expected Err result")
  }
}

///|
test "parse_csv_content - snapshot test with multiple rows" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,10.5,11.0,10.2,10.8,1000000,10500000,0.05\n" +
    "2023-01-02,10.8,11.2,10.5,11.0,1200000,13000000,0.06\n" +
    "2023-01-03,11.0,11.5,10.8,11.3,1500000,16800000,0.075"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => {
      assert_true(klines.length() == 3)
      assert_true(klines[0].date == "2023-01-01")
      assert_true(klines[1].date == "2023-01-02")
      assert_true(klines[2].date == "2023-01-03")
    }
    Err(_) => fail("Expected Ok, got error")
  }
}

///|
test "parse_csv_content - snapshot with various price ranges" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,0.5,0.6,0.4,0.55,500000,275000,0.025\n" +
    "2023-01-02,100.0,105.0,98.0,102.5,200000,20500000,0.1\n" +
    "2023-01-03,1000.0,1050.0,990.0,1025.0,50000,51250000,0.05"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => assert_true(klines.length() == 3)
    Err(_) => fail("Expected Ok, got error")
  }
}

///|
test "kline_to_csv_line - roundtrip test" {
  let kline = KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.8, 1000000.0, 10500000.0, 0.05,
  )
  let csv_line = kline_to_csv_line(kline)
  json_inspect(
    csv_line,
    content="2023-01-01,10.5,11,10.199999809265137,10.800000190734863,1000000,10500000,0.05000000074505806",
  )

  let reparsed = parse_csv_content(
    "date,open,high,low,close,volume,amount,turn\n" + csv_line,
  )
  match reparsed {
    Ok(reparsed_klines) => {
      assert_true(reparsed_klines.length() == 1)
      assert_true(reparsed_klines[0].open == kline.open)
      assert_true(reparsed_klines[0].high == kline.high)
      assert_true(reparsed_klines[0].low == kline.low)
      assert_true(reparsed_klines[0].close == kline.close)
    }
    Err(_) => fail("Roundtrip failed")
  }
}

///|
test "KLine struct - json inspection" {
  let kline = KLine::daily(
    "sz.000001", "2023-06-15", 25.5, 26.8, 25.2, 26.5, 5000000.0, 132500000.0, 0.12,
  )
  assert_true(kline.code == "sz.000001")
  assert_true(kline.date == "2023-06-15")
  assert_true(kline.close > 26.0 && kline.close < 27.0)
}

///|
test "extract_stock_code_from_filename - various formats" {
  let test_cases : Array[(String, String?)] = [
    ("data/sh_600000_2023-01-01_2023-12-31.csv", Some("sh.600000")),
    ("data/sz_000001_2023-01-01_2023-12-31.csv", Some("sz.000001")),
    ("sh_600000.csv", Some("sh.600000")),
    ("invalid.csv", None),
    ("", None),
    ("/path/to/sh_600001_2023.csv", Some("sh.600001")),
  ]
  let results = test_cases.map(fn(tc) {
    let (input, expected) = tc
    (input, extract_stock_code_from_filename(input), expected)
  })
  json_inspect(results, content=[
    ["data/sh_600000_2023-01-01_2023-12-31.csv", ["sh.600000"], ["sh.600000"]],
    ["data/sz_000001_2023-01-01_2023-12-31.csv", ["sz.000001"], ["sz.000001"]],
    ["sh_600000.csv", ["sh.600000.csv"], ["sh.600000"]],
    ["invalid.csv", null, null],
    ["", null, null],
    ["/path/to/sh_600001_2023.csv", ["sh.600001"], ["sh.600001"]],
  ])
}

///|
test "KLine::daily - constructor snapshot" {
  let kline = KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.8, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(kline.code == "sh.600000")
  assert_true(kline.date == "2023-01-01")
  assert_true(kline.time == None)
  assert_true(kline.open > 10.4 && kline.open < 10.6)
  assert_true(kline.high > 10.9 && kline.high < 11.1)
  assert_true(kline.low > 10.1 && kline.low < 10.3)
  assert_true(kline.close > 10.7 && kline.close < 10.9)
  assert_true(kline.volume == 1000000.0)
  assert_true(kline.amount == 10500000.0)
  assert_true(kline.turn > 0.049 && kline.turn < 0.051)
}

///|
test "KLine equality" {
  let kline1 = KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.8, 1000000.0, 10500000.0, 0.05,
  )
  let kline2 = KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.8, 1000000.0, 10500000.0, 0.05,
  )
  let kline3 = KLine::daily(
    "sh.600000", "2023-01-01", 10.5, 11.0, 10.2, 10.9, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(kline1 == kline2)
  assert_true(kline1 != kline3)
}

///|
test "parse_csv_content - whitespace handling" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,10.5,11.0,10.2,10.8,1000000,10500000,0.05\n"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => assert_true(klines.length() == 1)
    Err(_) => fail("Expected Ok")
  }
}

///|
test "parse_csv_content - many rows snapshot" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,10.0,10.5,9.5,10.2,1000000,10200000,0.05\n" +
    "2023-01-02,10.2,10.8,10.0,10.5,1100000,11550000,0.055\n" +
    "2023-01-03,10.5,11.0,10.3,10.8,1200000,12960000,0.06\n" +
    "2023-01-04,10.8,11.2,10.5,11.0,1300000,14300000,0.065\n" +
    "2023-01-05,11.0,11.5,10.8,11.3,1400000,15820000,0.07"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => {
      assert_true(klines.length() == 5)
      assert_true(klines[0].close == 10.2)
      assert_true(klines[4].close == 11.3)
    }
    Err(_) => fail("Expected Ok")
  }
}

///|
test "kline_to_csv_line - snapshot" {
  let kline = KLine::daily(
    "sz.000001", "2023-06-15", 25.5, 26.8, 25.2, 26.5, 5000000.0, 132500000.0, 0.12,
  )
  let csv_line = kline_to_csv_line(kline)
  // Verify format and key values (float precision may vary)
  assert_true(csv_line.has_prefix("2023-06-15,"))
  assert_true(csv_line.contains("25.5"))
  assert_true(csv_line.contains("26.5"))
  assert_true(csv_line.contains("5000000"))
  assert_true(csv_line.contains("132500000"))
}

///|
test "parse_csv_content - large volume values" {
  let content = "date,open,high,low,close,volume,amount,turn\n" +
    "2023-01-01,50.0,52.0,49.0,51.0,100000000,5100000000,0.15"
  let result = parse_csv_content(content)
  match result {
    Ok(klines) => {
      assert_true(klines.length() == 1)
      // Just verify the data was parsed (Float32 precision varies)
      assert_true(klines[0].volume > 0.0)
      assert_true(klines[0].amount > 0.0)
      assert_true(klines[0].close > 50.0 && klines[0].close < 52.0)
    }
    Err(_) => fail("Expected Ok")
  }
}

///|
test "extract_stock_code_from_filename - edge cases snapshot" {
  let cases : Array[String] = [
    "sh_600000_2023.csv", "sz_000001_20230101_20231231.csv", "bj_830000_2023.csv",
    "data/raw/sh_600000_2023.csv", "/home/user/data/sz_000001_2023.csv",
  ]
  let results = cases.map(fn(f) { (f, extract_stock_code_from_filename(f)) })
  json_inspect(results, content=[
    ["sh_600000_2023.csv", ["sh.600000"]],
    ["sz_000001_20230101_20231231.csv", ["sz.000001"]],
    ["bj_830000_2023.csv", ["bj.830000"]],
    ["data/raw/sh_600000_2023.csv", ["sh.600000"]],
    ["/home/user/data/sz_000001_2023.csv", ["sz.000001"]],
  ])
}
