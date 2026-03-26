/// CLI main module whitebox tests
/// Tests for serve command parsing and execution

///|
test "Command::Serve with default port" {
  let cmd = Command::Serve(8080)
  match cmd {
    Command::Serve(port) => assert_true(port == 8080)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "Command::Serve with custom port 3000" {
  let cmd = Command::Serve(3000)
  match cmd {
    Command::Serve(port) => assert_true(port == 3000)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_serve_args with no arguments uses default port 8080" {
  let args = ["serve"]
  let cmd = _parse_serve_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 8080)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_serve_args with --port 3000" {
  let args = ["serve", "--port", "3000"]
  let cmd = _parse_serve_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 3000)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_serve_args with --port 8888" {
  let args = ["serve", "--port", "8888"]
  let cmd = _parse_serve_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 8888)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_serve_args with --port 65535 (max port)" {
  let args = ["serve", "--port", "65535"]
  let cmd = _parse_serve_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 65535)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_serve_args with invalid port falls back to default" {
  let args = ["serve", "--port", "invalid"]
  let cmd = _parse_serve_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 8080)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_serve_args with --port at end of args" {
  let args = ["serve", "--unknown", "--port", "4000"]
  let cmd = _parse_serve_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 4000)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "_parse_args routes serve command correctly" {
  let args = ["serve", "--port", "9000"]
  let cmd = _parse_args(args)
  match cmd {
    Command::Serve(9000) => assert_true(true)
    _ => fail("Expected Command::Serve with port 9000")
  }
}

///|
test "_parse_args serve without port uses default" {
  let args = ["serve"]
  let cmd = _parse_args(args)
  match cmd {
    Command::Serve(8080) => assert_true(true)
    _ => fail("Expected Command::Serve with default port 8080")
  }
}

///|
test "test all command variants exist" {
  let help_cmd = Command::Help
  let analyze_cmd = Command::Analyze("sh.600000", "max_drawdown")
  let backtest_cmd = Command::Backtest(
    "ma_cross", "sh.600000", "2023-01-01", "2023-12-31",
  )
  let monitor_cmd = Command::Monitor("sh.600000")
  let report_cmd = Command::Report("html")
  let list_cmd = Command::ListStrategies
  let serve_cmd = Command::Serve(8080)

  ignore(help_cmd)
  ignore(analyze_cmd)
  ignore(backtest_cmd)
  ignore(monitor_cmd)
  ignore(report_cmd)
  ignore(list_cmd)
  ignore(serve_cmd)
  assert_true(true)
}
