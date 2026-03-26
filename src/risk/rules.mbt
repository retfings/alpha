/// Built-in risk rules
///
/// Predefined risk rules for common risk management scenarios:
/// - Maximum drawdown limits
/// - Position size limits
/// - Daily loss limits
/// - Stop loss and take profit rules

///|
/// Maximum drawdown rule
///
/// Stops trading if portfolio drawdown exceeds the specified threshold.
/// This is a critical risk control that prevents catastrophic losses.
///
/// Parameters:
/// - max_pct: Maximum allowed drawdown (e.g., 0.20 for 20%)
///
/// Returns:
/// - RiskRule that triggers StopTrading when exceeded
///
/// Examples:
/// ```mbt check-disabled
/// test "max_drawdown_rule example" {
///   let rule = max_drawdown_rule(0.20) // 20% max drawdown
///   ignore(rule)
/// }
/// ```
pub fn max_drawdown_rule(max_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Max Drawdown Rule",
    priority: 1,
    check_fn: fn(dd, _, _) {
      if dd <= -max_pct {
        RiskResult::{
          passed: false,
          message: "Maximum drawdown exceeded: " +
          Float::to_string(dd * 100.0) +
          "%",
          action: RiskAction::StopTrading,
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Drawdown within limits",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Position limit rule
///
/// Limits the maximum position ratio (position value / total portfolio value).
/// Helps prevent over-concentration in any single position or the market.
///
/// Parameters:
/// - max_pct: Maximum allowed position ratio (e.g., 0.95 for 95%)
///
/// Returns:
/// - RiskRule that triggers ReducePosition when exceeded
///
/// Examples:
/// ```mbt check-disabled
/// test "position_limit_rule example" {
///   let rule = position_limit_rule(0.95) // 95% max position
///   ignore(rule)
/// }
/// ```
pub fn position_limit_rule(max_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Position Limit Rule",
    priority: 2,
    check_fn: fn(_, pos_ratio, _) {
      if pos_ratio > max_pct {
        RiskResult::{
          passed: false,
          message: "Position limit exceeded: " +
          Float::to_string(pos_ratio * 100.0) +
          "%",
          action: RiskAction::ReducePosition(pos_ratio - max_pct),
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Position within limits",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Stop loss rule (daily loss limit)
///
/// Stops trading if the daily loss exceeds the specified threshold.
/// This is a circuit breaker that prevents emotional trading during bad days.
///
/// Parameters:
/// - max_pct: Maximum allowed daily loss (e.g., 0.05 for 5%)
///
/// Returns:
/// - RiskRule that triggers StopTrading when exceeded
///
/// Examples:
/// ```mbt check-disabled
/// test "daily_loss_limit_rule example" {
///   let rule = daily_loss_limit_rule(0.05) // 5% daily loss limit
///   ignore(rule)
/// }
/// ```
pub fn daily_loss_limit_rule(max_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Daily Loss Limit Rule",
    priority: 3,
    check_fn: fn(_, _, daily_loss) {
      if daily_loss <= -max_pct {
        RiskResult::{
          passed: false,
          message: "Daily loss limit exceeded: " +
          Float::to_string(daily_loss * 100.0) +
          "%",
          action: RiskAction::StopTrading,
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Daily loss within limits",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Stop loss rule for individual positions
///
/// Triggers when a position loses more than the specified threshold.
/// Uses the position's P&L percentage for accurate loss tracking.
///
/// Parameters:
/// - stock: Stock code this rule applies to
/// - max_loss_pct: Maximum allowed loss percentage (e.g., 0.10 for 10%)
///
/// Returns:
/// - RiskRule that triggers ReducePosition when exceeded
///
/// Usage with portfolio:
/// ```mbt check-disabled
/// let portfolio = @portfolio.create_portfolio(100000.0)
/// // ... add positions ...
///
/// let position_pnl_pct = portfolio.get_position_pnl_pct("sh.600000")
///
/// let rule = stop_loss_rule("sh.600000", 0.10)
///
/// let result = rule.check_fn(0.0, 0.0, position_pnl_pct)
/// ```
pub fn stop_loss_rule(stock : String, max_loss_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Stop Loss Rule (" + stock + ")",
    priority: 4,
    check_fn: fn(_, _, position_pnl) {
      // position_pnl should be the position's P&L percentage (negative for losses)
      if position_pnl <= -max_loss_pct {
        RiskResult::{
          passed: false,
          message: "Stop loss triggered: " +
          Float::to_string(position_pnl * 100.0) +
          "%",
          action: RiskAction::ReducePosition(max_loss_pct),
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Position loss within limits",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Per-position stop loss rule with explicit P&L
///
/// Checks if a specific position's P&L percentage exceeds the loss threshold.
/// This is a more explicit version that works with real position P&L data.
///
/// Parameters:
/// - stock: Stock code to check
/// - max_loss_pct: Maximum allowed loss (e.g., 0.10 for 10%)
/// - position_pnl_pct: Current position P&L percentage (negative for losses)
///
/// Returns:
/// - RiskResult indicating whether the position passed the check
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = @portfolio.create_portfolio(100000.0)
///
/// let position_pnl_pct = portfolio.get_position_pnl_pct("sh.600000")
///
/// let result = check_position_stop_loss("sh.600000", 0.10, position_pnl_pct)
/// ```
pub fn check_position_stop_loss(
  stock : String,
  max_loss_pct : Float,
  position_pnl_pct : Float,
) -> RiskResult {
  if position_pnl_pct <= -max_loss_pct {
    RiskResult::{
      passed: false,
      message: "Stop loss triggered for " +
      stock +
      ": " +
      Float::to_string(position_pnl_pct * 100.0) +
      "%",
      action: RiskAction::ReducePosition(max_loss_pct),
    }
  } else {
    RiskResult::{
      passed: true,
      message: "Position " + stock + " loss within limits",
      action: RiskAction::Allow,
    }
  }
}

///|
/// Portfolio-wide stop loss check
///
/// Checks all positions in the portfolio against a stop loss threshold.
/// Returns the first position that triggers stop loss.
///
/// Parameters:
/// - portfolio: Portfolio to check
/// - max_loss_pct: Maximum allowed loss per position (e.g., 0.10 for 10%)
///
/// Returns:
/// - Optional tuple of (stock_code, RiskResult) for the first triggering position
/// - None if all positions are within limits
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = @portfolio.create_portfolio(100000.0)
/// // ... add positions ...
/// match check_portfolio_stop_loss(portfolio, 0.10) {
///   Some((stock, result)) => inspect("Stop loss: " + stock)
///   None => inspect("All positions within limits")
/// }
/// ```
pub fn check_portfolio_stop_loss(
  portfolio : @portfolio.Portfolio,
  max_loss_pct : Float,
) -> (@data.StockCode, RiskResult)? {
  for pos in portfolio.positions {
    let pnl_pct = pos.pnl_pct()
    if pnl_pct <= -max_loss_pct {
      return Some(
        (
          pos.stock,
          RiskResult::{
            passed: false,
            message: "Stop loss triggered: " +
            Float::to_string(pnl_pct * 100.0) +
            "%",
            action: RiskAction::ReducePosition(max_loss_pct),
          },
        ),
      )
    }
  }
  None
}

///|
/// Total position exposure limit rule
///
/// Limits the total position exposure (sum of all positions / total portfolio value).
/// This is a portfolio-level exposure check, not per-stock.
///
/// For single-stock exposure checks, use `check_single_stock_exposure` instead,
/// which requires direct access to the portfolio.
///
/// Parameters:
/// - max_pct: Maximum allowed total position exposure (e.g., 0.95 for 95%)
///
/// Returns:
/// - RiskRule that triggers ReducePosition when exceeded
///
/// Examples:
/// ```mbt check-disabled
/// test "total_exposure_limit_rule example" {
///   let rule = total_exposure_limit_rule(0.95) // 95% max exposure
///   ignore(rule)
/// }
/// ```
pub fn total_exposure_limit_rule(max_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Total Exposure Limit Rule",
    priority: 5,
    check_fn: fn(_, pos_ratio, _) {
      if pos_ratio > max_pct {
        RiskResult::{
          passed: false,
          message: "Total position exposure exceeded: " +
          Float::to_string(pos_ratio * 100.0) +
          "%",
          action: RiskAction::ReducePosition(pos_ratio - max_pct),
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Total position exposure within limits",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Single stock position limit rule (DEPRECATED)
///
/// **Deprecated:** This function is an alias for `total_exposure_limit_rule` for backwards compatibility.
/// The name is misleading - it checks TOTAL position exposure, not per-stock exposure.
///
/// **Migration:** Use `total_exposure_limit_rule` instead:
/// ```mbt nocheck
/// // Old (deprecated):
/// let rule = single_stock_limit_rule(0.20)
///
/// // New (recommended):
///
/// let rule = total_exposure_limit_rule(0.20)
/// ```
///
/// For proper single-stock exposure checks, use `check_single_stock_exposure` instead.
///
/// Parameters:
/// - max_pct: Maximum allowed exposure (e.g., 0.20 for 20%)
///
/// Returns:
/// - RiskRule (same as total_exposure_limit_rule)
///
/// @deprecated Use `total_exposure_limit_rule` instead
#deprecated("Use total_exposure_limit_rule instead")
pub fn single_stock_limit_rule(max_pct : Float) -> RiskRule {
  total_exposure_limit_rule(max_pct)
}

///|
/// Check single stock exposure against a limit
///
/// This function directly checks if any single position exceeds the specified
/// percentage of the total portfolio value.
///
/// Parameters:
/// - portfolio: Portfolio to check
/// - max_pct: Maximum allowed single stock exposure (e.g., 0.20 for 20%)
///
/// Returns:
/// - Some(stock_code, RiskResult) if any position exceeds the limit
/// - None if all positions are within limits
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = @portfolio.create_portfolio(100000.0)
/// // ... add positions ...
/// match check_single_stock_exposure(portfolio, 0.20) {
///   Some((stock, result)) => inspect("Exceeded: " + stock)
///   None => inspect("All positions within limits")
/// }
/// ```
pub fn check_single_stock_exposure(
  portfolio : @portfolio.Portfolio,
  max_pct : Float,
) -> (@data.StockCode, RiskResult)? {
  let total_value = portfolio.total_value()
  if total_value <= 0.0 {
    return None
  }

  for pos in portfolio.positions {
    let position_value = pos.value()
    let exposure = position_value / total_value
    if exposure > max_pct {
      return Some(
        (
          pos.stock,
          RiskResult::{
            passed: false,
            message: "Single stock exposure exceeded for " +
            pos.stock +
            ": " +
            Float::to_string(exposure * 100.0) +
            "%",
            action: RiskAction::ReducePosition(exposure - max_pct),
          },
        ),
      )
    }
  }
  None
}

///|
/// Take profit rule (optional profit-taking trigger)
///
/// Suggests taking profits when daily profit reaches a specified threshold.
/// This rule doesn't block trades but suggests partial profit-taking.
///
/// Parameters:
/// - min_profit_pct: Minimum profit to trigger take-profit (e.g., 0.10 for 10%)
///
/// Returns:
/// - RiskRule that suggests ReducePosition(0.5) when profit target reached
///
/// Examples:
/// ```mbt check-disabled
/// test {
///   let rule = take_profit_rule(0.10) // Take profit at 10% gain
///   ignore(rule)
/// }
/// ```
pub fn take_profit_rule(min_profit_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Take Profit Rule",
    priority: 6,
    check_fn: fn(_, _, daily_loss) {
      let daily_profit = -daily_loss
      if daily_profit >= min_profit_pct {
        RiskResult::{
          passed: true,
          message: "Profit target reached: " +
          Float::to_string(daily_profit * 100.0) +
          "%",
          action: RiskAction::ReducePosition(0.5), // Suggest taking half profits
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Profit target not yet reached",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Create default risk rules with common thresholds
///
/// Returns an array of commonly used risk rules with standard thresholds:
/// - Max drawdown: 20%
/// - Position limit: 95%
/// - Daily loss limit: 5%
///
/// Returns:
/// - Array[RiskRule] ready to be added to a RiskEngine
///
/// Examples:
/// ```mbt check-disabled
/// let rules = default_rules()
/// let engine = create_risk_engine()
/// for rule in rules {
///   engine.add_rule(rule)
/// }
/// ```
pub fn default_rules() -> Array[RiskRule] {
  [
    max_drawdown_rule(0.20), // 20% max drawdown
    position_limit_rule(0.95), // 95% max position
    daily_loss_limit_rule(0.05), // 5% daily loss limit
  ]
}

///|
/// Rule Combinators
///
/// Combinators for composing complex risk rules from simpler ones.
/// This enables flexible risk management strategies through rule composition.

///|
/// Combine two rules with AND logic
///
/// Both rules must pass for the combined rule to pass.
/// If either rule fails, returns the result of the failing rule.
/// If both fail, returns the first failure.
///
/// Parameters:
/// - rule1: First rule to check
/// - rule2: Second rule to check
/// - name: Name for the combined rule
///
/// Returns:
/// - A new RiskRule that requires both rules to pass
///
/// Examples:
/// ```mbt check-disabled
/// let combined = and_rules(
///   max_drawdown_rule(0.20),
///   daily_loss_limit_rule(0.05),
///   "Drawdown AND Daily Loss Check",
/// )
/// ```
pub fn and_rules(rule1 : RiskRule, rule2 : RiskRule, name : String) -> RiskRule {
  RiskRule::{
    name,
    priority: Int::min(rule1.priority, rule2.priority),
    check_fn: fn(dd, pos_ratio, daily_loss) {
      let result1 = (rule1.check_fn)(dd, pos_ratio, daily_loss)
      if !result1.passed {
        return result1
      }
      let result2 = (rule2.check_fn)(dd, pos_ratio, daily_loss)
      result2
    },
  }
}

///|
/// Combine two rules with OR logic
///
/// At least one rule must pass for the combined rule to pass.
/// If both rules fail, returns the first failure.
///
/// Parameters:
/// - rule1: First rule to check
/// - rule2: Second rule to check
/// - name: Name for the combined rule
///
/// Returns:
/// - A new RiskRule that passes if either rule passes
///
/// Examples:
/// ```mbt check-disabled
/// let combined = or_rules(
///   max_drawdown_rule(0.25),
///   daily_loss_limit_rule(0.10),
///   "Drawdown OR Daily Loss Check",
/// )
/// ```
pub fn or_rules(rule1 : RiskRule, rule2 : RiskRule, name : String) -> RiskRule {
  RiskRule::{
    name,
    priority: Int::min(rule1.priority, rule2.priority),
    check_fn: fn(dd, pos_ratio, daily_loss) {
      let result1 = (rule1.check_fn)(dd, pos_ratio, daily_loss)
      if result1.passed {
        return result1
      }
      (rule2.check_fn)(dd, pos_ratio, daily_loss)
    },
  }
}

///|
/// Negate a rule with NOT logic
///
/// Inverts the pass/fail result of the wrapped rule.
/// Useful for creating exception rules or inverse conditions.
///
/// Parameters:
/// - rule: Rule to negate
/// - name: Name for the negated rule
///
/// Returns:
/// - A new RiskRule with inverted logic
///
/// Examples:
/// ```mbt check-disabled
/// // Allow trading only when NOT in max drawdown
/// let exception_rule = not_rule(max_drawdown_rule(0.20), "Not In Max Drawdown")
/// ```
pub fn not_rule(rule : RiskRule, name : String) -> RiskRule {
  RiskRule::{
    name,
    priority: rule.priority,
    check_fn: fn(dd, pos_ratio, daily_loss) {
      let result = (rule.check_fn)(dd, pos_ratio, daily_loss)
      let negated_action = if !result.passed {
        RiskAction::Allow
      } else {
        match result.action {
          RiskAction::Allow => RiskAction::Reject
          _ => result.action
        }
      }
      RiskResult::{
        passed: !result.passed,
        message: if result.passed {
          "Negated: " + result.message
        } else {
          result.message
        },
        action: negated_action,
      }
    },
  }
}

///|
/// Execute multiple rules sequentially
///
/// Runs rules in order and returns the first failing result.
/// If all rules pass, returns a combined success.
///
/// Parameters:
/// - rules: Array of rules to execute in sequence
/// - name: Name for the sequential rule
///
/// Returns:
/// - A new RiskRule that executes all rules in sequence
///
/// Examples:
/// ```mbt check-disabled
/// let combined = sequential_rules(
///   [
///     max_drawdown_rule(0.20),
///     position_limit_rule(0.95),
///     daily_loss_limit_rule(0.05),
///   ],
///   "Comprehensive Risk Check",
/// )
/// ```
pub fn sequential_rules(rules : Array[RiskRule], name : String) -> RiskRule {
  let mut min_priority = 999
  for rule in rules {
    min_priority = Int::min(min_priority, rule.priority)
  }
  RiskRule::{
    name,
    priority: min_priority,
    check_fn: fn(dd, pos_ratio, daily_loss) {
      for rule in rules {
        let result = (rule.check_fn)(dd, pos_ratio, daily_loss)
        if !result.passed {
          return result
        }
      }
      RiskResult::{
        passed: true,
        message: "All " + Int::to_string(rules.length()) + " rules passed",
        action: RiskAction::Allow,
      }
    },
  }
}

///|
/// Rule Combinators (continued)
