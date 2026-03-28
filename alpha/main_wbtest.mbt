///|
/// CLI main module whitebox tests
/// Tests for serve command parsing and execution
using @alpha/parsers {_parse_serve_args, _parse_args}

///|
test "Command::Serve with default port" {
  // Test that serve command is recognized (construction happens via parser)
  let args = ["serve"]
  let cmd = _parse_args(args)
  match cmd {
    Command::Serve(port) => assert_true(port == 8080)
    _ => fail("Expected Command::Serve")
  }
}

///|
test "Command::Serve with custom port 3000" {
  let args = ["serve", "--port", "3000"]
  let cmd = _parse_args(args)
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
test "test all command variants via parsers" {
  // Test remaining commands via parser functions
  let help_cmd = _parse_args(["help"])
  let analyze_cmd = _parse_args(["analyze", "--stock", "sh.600000"])
  let backtest_cmd = _parse_args([
    "backtest", "--strategy", "ma_cross", "--stock", "sh.600000",
  ])
  let serve_cmd = _parse_args(["serve", "--port", "8080"])

  // Verify commands parsed correctly via pattern matching
  match help_cmd {
    Command::Help => assert_true(true)
    _ => fail("Expected Command::Help")
  }
  match analyze_cmd {
    Command::Analyze(_, _) => assert_true(true)
    _ => fail("Expected Command::Analyze")
  }
  match backtest_cmd {
    Command::Backtest(_, _, _, _) => assert_true(true)
    _ => fail("Expected Command::Backtest")
  }
  match serve_cmd {
    Command::Serve(_) => assert_true(true)
    _ => fail("Expected Command::Serve")
  }
}
