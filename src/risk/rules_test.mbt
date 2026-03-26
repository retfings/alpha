/// Risk module tests

///|
test "RiskResult and RiskAction basic operations" {
  // Test Allow action
  let allow_result = @risk.risk_result_pass("Test passed")
  assert_true(allow_result.passed)
  assert_true(allow_result.message == "Test passed")

  // Test Reject action
  let reject_result = @risk.risk_result_fail("Test failed", @risk.risk_action_reject())
  assert_true(!reject_result.passed)

  // Test ReducePosition action
  let reduce_result = @risk.risk_result_fail(
    "Reduce position",
    @risk.risk_action_reduce_position(0.1),
  )
  assert_true(!reduce_result.passed)
  match reduce_result.action {
    RiskAction::ReducePosition(pct) => {
      assert_true(pct == 0.1)
    }
    _ => { fail("Expected ReducePosition action") }
  }

  // Test StopTrading action
  let stop_result = @risk.risk_result_fail("Stop trading", @risk.risk_action_stop_trading())
  match stop_result.action {
    RiskAction::StopTrading => { assert_true(true) }
    _ => { fail("Expected StopTrading action") }
  }
}

///|
test "max_drawdown_rule" {
  let rule = @risk.max_drawdown_rule(0.10) // 10% threshold
  assert_true(rule.name.contains("Max Drawdown"))
  assert_true(rule.priority == 1)

  // Test within limit (5% drawdown, 10% threshold)
  let result1 = (rule.check_fn)(-0.05, 0.0, 0.0)
  assert_true(result1.passed)
  assert_true(result1.action == @risk.risk_action_allow())

  // Test exceeded (15% drawdown, 10% threshold)
  let result2 = (rule.check_fn)(-0.15, 0.0, 0.0)
  assert_true(!result2.passed)
  assert_true(result2.action == @risk.risk_action_stop_trading())
  assert_true(result2.message.contains("15.0"))
}

///|
test "position_limit_rule" {
  let rule = @risk.position_limit_rule(0.80) // 80% threshold
  assert_true(rule.name.contains("Position Limit"))
  assert_true(rule.priority == 2)

  // Test within limit (60% position, 80% threshold)
  let result1 = (rule.check_fn)(0.0, 0.60, 0.0)
  assert_true(result1.passed)
  assert_true(result1.action == @risk.risk_action_allow())

  // Test exceeded (90% position, 80% threshold)
  let result2 = (rule.check_fn)(0.0, 0.90, 0.0)
  assert_true(!result2.passed)
  match result2.action {
    RiskAction::ReducePosition(pct) => {
      // pct should be 0.90 - 0.80 = 0.10
      assert_true(pct > 0.09 && pct < 0.11)
    }
    _ => { fail("Expected ReducePosition action") }
  }
}

///|
test "daily_loss_limit_rule" {
  let rule = @risk.daily_loss_limit_rule(0.05) // 5% threshold
  assert_true(rule.name.contains("Daily Loss"))
  assert_true(rule.priority == 3)

  // Test within limit (3% loss, 5% threshold)
  let result1 = (rule.check_fn)(0.0, 0.0, -0.03)
  assert_true(result1.passed)
  assert_true(result1.action == @risk.risk_action_allow())

  // Test exceeded (7% loss, 5% threshold)
  let result2 = (rule.check_fn)(0.0, 0.0, -0.07)
  assert_true(!result2.passed)
  assert_true(result2.action == @risk.risk_action_stop_trading())
}

///|
test "stop_loss_rule" {
  let rule = @risk.stop_loss_rule("sh.600000", 0.08) // 8% threshold
  assert_true(rule.name.contains("sh.600000"))
  assert_true(rule.priority == 4)

  // Test within limit
  let result1 = (rule.check_fn)(0.0, 0.0, -0.05)
  assert_true(result1.passed)

  // Test triggered
  let result2 = (rule.check_fn)(0.0, 0.0, -0.10)
  assert_true(!result2.passed)
  match result2.action {
    RiskAction::ReducePosition(_) => { assert_true(true) }
    _ => { fail("Expected ReducePosition action") }
  }
}

///|
test "single_stock_limit_rule" {
  let rule = @risk.single_stock_limit_rule(0.30) // 30% threshold
  assert_true(rule.name.contains("Single Stock"))
  assert_true(rule.priority == 5)

  // Test within limit
  let result1 = (rule.check_fn)(0.0, 0.20, 0.0)
  assert_true(result1.passed)

  // Test exceeded
  let result2 = (rule.check_fn)(0.0, 0.40, 0.0)
  assert_true(!result2.passed)
  match result2.action {
    RiskAction::ReducePosition(pct) => {
      // pct should be 0.40 - 0.30 = 0.10
      assert_true(pct > 0.09 && pct < 0.11)
    }
    _ => { fail("Expected ReducePosition action") }
  }
}

///|
test "take_profit_rule" {
  let rule = @risk.take_profit_rule(0.05) // 5% profit target
  assert_true(rule.name.contains("Take Profit"))
  assert_true(rule.priority == 6)

  // Test profit target not reached (3% profit)
  let result1 = (rule.check_fn)(0.0, 0.0, -0.03)
  assert_true(result1.passed)
  assert_true(result1.action == @risk.risk_action_allow())

  // Test profit target reached (7% profit)
  let result2 = (rule.check_fn)(0.0, 0.0, -0.07)
  assert_true(result2.passed)
  match result2.action {
    RiskAction::ReducePosition(pct) => {
      assert_true(pct == 0.5)
    }
    _ => { fail("Expected ReducePosition action") }
  }
}

///|
test "RiskEngine basic operations" {
  let engine = @risk.create_risk_engine()
  assert_true(!engine.stopped)
  assert_true(engine.rules.length() == 0)

  // Add a rule
  let rule = @risk.max_drawdown_rule(0.10)
  engine.add_rule(rule)
  assert_true(engine.rules.length() == 1)
}

///|
test "RiskEngine check with no rules" {
  let engine = @risk.create_risk_engine()
  let result = engine.check(0.0, 0.0, 0.0)
  assert_true(result.passed)
  assert_true(result.action == @risk.risk_action_allow())
}

///|
test "RiskEngine check with rules passing" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.20))
  engine.add_rule(@risk.position_limit_rule(0.90))

  // All rules should pass
  let result = engine.check(-0.05, 0.50, -0.02)
  assert_true(result.passed)
  assert_true(result.message.contains("All risk rules passed"))
}

///|
test "RiskEngine check with rule failing" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))

  // Drawdown exceeds threshold
  let result = engine.check(-0.15, 0.0, 0.0)
  assert_true(!result.passed)
  assert_true(result.action == @risk.risk_action_stop_trading())
  assert_true(engine.violations.length() == 1)
}

///|
test "RiskEngine stopped state" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))

  // Trigger stop
  ignore(engine.check(-0.15, 0.0, 0.0))

  // Engine should be stopped
  assert_true(engine.stopped)

  // Subsequent checks should fail immediately
  let result2 = engine.check(0.0, 0.0, 0.0)
  assert_true(!result2.passed)
  assert_true(result2.message.contains("Trading stopped"))
}

///|
test "default_rules" {
  let rules = @risk.default_rules()
  assert_true(rules.length() == 3)

  // Verify rule types
  assert_true(rules[0].name.contains("Max Drawdown"))
  assert_true(rules[1].name.contains("Position Limit"))
  assert_true(rules[2].name.contains("Daily Loss"))
}

///|
test "RiskEngine with default rules" {
  // Test 1: Passing scenario
  let engine1 = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine1.add_rule(rule)
  }
  let result1 = engine1.check(-0.05, 0.50, -0.02)
  assert_true(result1.passed)

  // Test 2: Max drawdown failure
  let engine2 = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine2.add_rule(rule)
  }
  let result2 = engine2.check(-0.25, 0.50, -0.02)
  assert_true(!result2.passed)
  assert_true(result2.action == @risk.risk_action_stop_trading())

  // Test 3: Position limit failure
  let engine3 = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine3.add_rule(rule)
  }
  let result3 = engine3.check(-0.05, 0.98, -0.02)
  assert_true(!result3.passed)
  match result3.action {
    RiskAction::ReducePosition(_) => { assert_true(true) }
    _ => { fail("Expected ReducePosition action") }
  }

  // Test 4: Daily loss limit failure
  let engine4 = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine4.add_rule(rule)
  }
  let result4 = engine4.check(-0.05, 0.50, -0.08)
  assert_true(!result4.passed)
  assert_true(result4.action == @risk.risk_action_stop_trading())
}
