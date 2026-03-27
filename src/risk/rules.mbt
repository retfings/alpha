/// Built-in risk rules

///|
/// Maximum drawdown rule
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
/// Daily loss limit rule
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
pub fn stop_loss_rule(stock : String, max_loss_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Stop Loss Rule (" + stock + ")",
    priority: 4,
    check_fn: fn(_, _, position_pnl) {
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
#deprecated("Use total_exposure_limit_rule instead")
pub fn single_stock_limit_rule(max_pct : Float) -> RiskRule {
  total_exposure_limit_rule(max_pct)
}

///|
/// Check single stock exposure against a limit
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
/// Take profit rule
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
          action: RiskAction::ReducePosition(0.5),
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
/// Create default risk rules
pub fn default_rules() -> Array[RiskRule] {
  [
    max_drawdown_rule(0.20),
    position_limit_rule(0.95),
    daily_loss_limit_rule(0.05),
  ]
}

///|
/// Rule combinators

///|
/// Combine two rules with AND logic
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
/// Require at least N rules to pass out of M rules
pub fn at_least_rules(
  rules : Array[RiskRule],
  min_pass : Int,
  name : String,
) -> RiskRule {
  let mut min_priority = 999
  for rule in rules {
    min_priority = Int::min(min_priority, rule.priority)
  }
  RiskRule::{
    name,
    priority: min_priority,
    check_fn: fn(dd, pos_ratio, daily_loss) {
      let mut pass_count = 0
      let mut first_failure : RiskResult? = None

      for rule in rules {
        let result = (rule.check_fn)(dd, pos_ratio, daily_loss)
        if result.passed {
          pass_count = pass_count + 1
        } else if first_failure is None {
          first_failure = Some(result)
        }
      }

      if pass_count >= min_pass {
        RiskResult::{
          passed: true,
          message: "\{pass_count}/\{rules.length()} rules passed (required: \{min_pass})",
          action: RiskAction::Allow,
        }
      } else {
        match first_failure {
          Some(failure) => failure
          None =>
            RiskResult::{
              passed: false,
              message: "Only \{pass_count}/\{rules.length()} rules passed (required: \{min_pass})",
              action: RiskAction::Reject,
            }
        }
      }
    },
  }
}
