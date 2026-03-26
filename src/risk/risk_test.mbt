/// Risk package black-box snapshot tests

///|
test "max_drawdown_rule snapshot" {
  let rule = @risk.max_drawdown_rule(0.10)
  inspect(rule.name, content="Max Drawdown Rule")
  inspect(rule.priority, content="1")

  // Test within limit
  let result1 = (rule.check_fn)(-0.05, 0.0, 0.0)
  inspect(result1.passed, content="true")
  inspect(result1.message, content="Drawdown within limits")

  // Test at threshold (edge case)
  let result2 = (rule.check_fn)(-0.10, 0.0, 0.0)
  inspect(result2.passed, content="false")

  // Test exceeded
  let result3 = (rule.check_fn)(-0.20, 0.0, 0.0)
  inspect(result3.passed, content="false")
}

///|
test "position_limit_rule snapshot" {
  let rule = @risk.position_limit_rule(0.80)
  inspect(rule.name, content="Position Limit Rule")
  inspect(rule.priority, content="2")

  // Test within limit
  let result1 = (rule.check_fn)(0.0, 0.50, 0.0)
  inspect(result1.passed, content="true")

  // Test at threshold (edge case)
  let result2 = (rule.check_fn)(0.0, 0.80, 0.0)
  inspect(result2.passed, content="true")

  // Test exceeded
  let result3 = (rule.check_fn)(0.0, 0.95, 0.0)
  inspect(result3.passed, content="false")

  // Test zero position
  let result4 = (rule.check_fn)(0.0, 0.0, 0.0)
  inspect(result4.passed, content="true")

  // Test full position (edge case)
  let result5 = (rule.check_fn)(0.0, 1.0, 0.0)
  inspect(result5.passed, content="false")
}

///|
test "daily_loss_limit_rule snapshot" {
  let rule = @risk.daily_loss_limit_rule(0.05)
  inspect(rule.name, content="Daily Loss Limit Rule")
  inspect(rule.priority, content="3")

  // Test within limit
  let result1 = (rule.check_fn)(0.0, 0.0, -0.03)
  inspect(result1.passed, content="true")

  // Test at threshold (edge case)
  let result2 = (rule.check_fn)(0.0, 0.0, -0.05)
  inspect(result2.passed, content="false")

  // Test exceeded
  let result3 = (rule.check_fn)(0.0, 0.0, -0.10)
  inspect(result3.passed, content="false")

  // Test zero loss
  let result4 = (rule.check_fn)(0.0, 0.0, 0.0)
  inspect(result4.passed, content="true")

  // Test profit (negative loss)
  let result5 = (rule.check_fn)(0.0, 0.0, 0.05)
  inspect(result5.passed, content="true")
}

///|
test "stop_loss_rule snapshot" {
  let rule = @risk.stop_loss_rule("sh.600000", 0.08)
  inspect(rule.name, content="Stop Loss Rule (sh.600000)")
  inspect(rule.priority, content="4")

  // Test within limit
  let result1 = (rule.check_fn)(0.0, 0.0, -0.05)
  inspect(result1.passed, content="true")

  // Test at threshold (edge case)
  let result2 = (rule.check_fn)(0.0, 0.0, -0.08)
  inspect(result2.passed, content="false")

  // Test exceeded
  let result3 = (rule.check_fn)(0.0, 0.0, -0.15)
  inspect(result3.passed, content="false")
}

///|
test "single_stock_limit_rule snapshot" {
  let rule = @risk.single_stock_limit_rule(0.30)
  inspect(rule.name, content="Single Stock Limit Rule")
  inspect(rule.priority, content="5")

  // Test within limit
  let result1 = (rule.check_fn)(0.0, 0.20, 0.0)
  inspect(result1.passed, content="true")

  // Test at threshold (edge case)
  let result2 = (rule.check_fn)(0.0, 0.30, 0.0)
  inspect(result2.passed, content="true")

  // Test exceeded
  let result3 = (rule.check_fn)(0.0, 0.50, 0.0)
  inspect(result3.passed, content="false")
}

///|
test "take_profit_rule snapshot" {
  let rule = @risk.take_profit_rule(0.05)
  inspect(rule.name, content="Take Profit Rule")
  inspect(rule.priority, content="6")

  // Test profit not reached
  let result1 = (rule.check_fn)(0.0, 0.0, -0.03)
  inspect(result1.passed, content="true")
  inspect(result1.message, content="Profit target not yet reached")

  // Test at threshold (edge case)
  let result2 = (rule.check_fn)(0.0, 0.0, -0.05)
  inspect(result2.passed, content="true")

  // Test profit exceeded
  let result3 = (rule.check_fn)(0.0, 0.0, -0.10)
  inspect(result3.passed, content="true")
  inspect(result3.message, content="Profit target reached: 10%")
}

///|
test "RiskAction equality snapshot" {
  // Allow
  let allow1 = @risk.risk_action_allow()
  let allow2 = @risk.risk_action_allow()
  inspect(allow1 == allow2, content="true")

  // StopTrading
  let stop1 = @risk.risk_action_stop_trading()
  let stop2 = @risk.risk_action_stop_trading()
  inspect(stop1 == stop2, content="true")

  // ReducePosition - same value
  let reduce1 = @risk.risk_action_reduce_position(0.1)
  let reduce2 = @risk.risk_action_reduce_position(0.1)
  inspect(reduce1 == reduce2, content="true")

  // ReducePosition - different value
  let reduce3 = @risk.risk_action_reduce_position(0.2)
  inspect(reduce1 == reduce3, content="false")

  // Allow vs StopTrading
  inspect(allow1 == stop1, content="false")
}

///|
test "RiskEngine empty check snapshot" {
  let engine = @risk.create_risk_engine()
  inspect(engine.stopped, content="false")
  inspect(engine.violations.length(), content="0")

  let result = engine.check(0.0, 0.0, 0.0)
  inspect(result.passed, content="true")
  inspect(result.message, content="All risk rules passed")
}

///|
test "RiskEngine with single rule passing snapshot" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))

  let result = engine.check(-0.05, 0.0, 0.0)
  inspect(result.passed, content="true")
  inspect(engine.violations.length(), content="0")
  inspect(engine.stopped, content="false")
}

///|
test "RiskEngine with single rule failing snapshot" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))

  let result = engine.check(-0.15, 0.0, 0.0)
  inspect(result.passed, content="false")
  inspect(engine.violations.length(), content="1")
  inspect(engine.stopped, content="true")
}

///|
test "RiskEngine stopped state persistence snapshot" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))

  // First check triggers stop
  ignore(engine.check(-0.15, 0.0, 0.0))

  // Second check should fail immediately due to stopped state
  let result2 = engine.check(0.0, 0.0, 0.0)
  inspect(result2.passed, content="false")
  inspect(result2.message, content="Trading stopped due to previous violations")
  inspect(engine.stopped, content="true")
}

///|
test "RiskEngine multiple rules all passing snapshot" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.20))
  engine.add_rule(@risk.position_limit_rule(0.90))
  engine.add_rule(@risk.daily_loss_limit_rule(0.10))

  let result = engine.check(-0.10, 0.50, -0.05)
  inspect(result.passed, content="true")
  inspect(engine.violations.length(), content="0")
}

///|
test "RiskEngine multiple rules first failing snapshot" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))
  engine.add_rule(@risk.position_limit_rule(0.90))

  // First rule fails
  let result = engine.check(-0.15, 0.50, 0.0)
  inspect(result.passed, content="false")
  inspect(engine.violations.length(), content="1")
}

///|
test "RiskEngine multiple rules second failing snapshot" {
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(0.10))
  engine.add_rule(@risk.position_limit_rule(0.50))

  // First rule passes, second fails
  let result = engine.check(-0.05, 0.60, 0.0)
  inspect(result.passed, content="false")
  inspect(engine.violations.length(), content="1")
}

///|
test "default_rules snapshot" {
  let rules = @risk.default_rules()
  inspect(rules.length(), content="3")

  // Verify rule configurations
  inspect(rules[0].name, content="Max Drawdown Rule")
  inspect(rules[0].priority, content="1")

  inspect(rules[1].name, content="Position Limit Rule")
  inspect(rules[1].priority, content="2")

  inspect(rules[2].name, content="Daily Loss Limit Rule")
  inspect(rules[2].priority, content="3")
}

///|
test "RiskEngine with default_rules passing snapshot" {
  let engine = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine.add_rule(rule)
  }

  // All rules should pass
  let result = engine.check(-0.10, 0.50, -0.02)
  inspect(result.passed, content="true")
}

///|
test "RiskEngine with default_rules drawdown failure snapshot" {
  let engine = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine.add_rule(rule)
  }

  // Max drawdown (20%) exceeded
  let result = engine.check(-0.25, 0.50, -0.02)
  inspect(result.passed, content="false")
  inspect(result.action, content="StopTrading")
}

///|
test "RiskEngine with default_rules position limit failure snapshot" {
  let engine = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine.add_rule(rule)
  }

  // Position limit (95%) exceeded
  let result = engine.check(-0.05, 0.98, -0.02)
  inspect(result.passed, content="false")
}

///|
test "RiskEngine with default_rules daily loss failure snapshot" {
  let engine = @risk.create_risk_engine()
  for rule in @risk.default_rules() {
    engine.add_rule(rule)
  }

  // Daily loss limit (5%) exceeded
  let result = engine.check(-0.05, 0.50, -0.08)
  inspect(result.passed, content="false")
  inspect(result.action, content="StopTrading")
}

///|
test "risk rule boundary conditions snapshot" {
  // Test drawdown rule at exact boundary
  let dd_rule = @risk.max_drawdown_rule(0.10)
  let at_boundary = (dd_rule.check_fn)(-0.10, 0.0, 0.0)
  inspect(at_boundary.passed, content="false")

  // Test position rule at exact boundary
  let pos_rule = @risk.position_limit_rule(0.80)
  let pos_at_boundary = (pos_rule.check_fn)(0.0, 0.80, 0.0)
  inspect(pos_at_boundary.passed, content="true")

  // Test daily loss rule at exact boundary
  let dl_rule = @risk.daily_loss_limit_rule(0.05)
  let dl_at_boundary = (dl_rule.check_fn)(0.0, 0.0, -0.05)
  inspect(dl_at_boundary.passed, content="false")
}

///|
test "risk rule message content snapshot" {
  // Max drawdown message format
  let dd_rule = @risk.max_drawdown_rule(0.10)
  let dd_result = (dd_rule.check_fn)(-0.15, 0.0, 0.0)
  inspect(dd_result.message.contains("Maximum drawdown exceeded"), content="true")
  inspect(dd_result.message.contains("15.0"), content="true")

  // Position limit message format
  let pos_rule = @risk.position_limit_rule(0.80)
  let pos_result = (pos_rule.check_fn)(0.0, 0.95, 0.0)
  inspect(pos_result.message.contains("Position limit exceeded"), content="true")
  inspect(pos_result.message.contains("95"), content="true")

  // Daily loss message format
  let dl_rule = @risk.daily_loss_limit_rule(0.05)
  let dl_result = (dl_rule.check_fn)(0.0, 0.0, -0.07)
  inspect(dl_result.message.contains("Daily loss limit exceeded"), content="true")
  inspect(dl_result.message.contains("7"), content="true")
}
