/// Built-in risk rules

///|
/// Maximum drawdown rule
/// Stops trading if drawdown exceeds threshold
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
/// Limits maximum position ratio
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
/// Triggers when a position loses more than the threshold
pub fn stop_loss_rule(stock : String, max_loss_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Stop Loss Rule (" + stock + ")",
    priority: 4,
    check_fn: fn(_, _, daily_loss) {
      // Note: This is a simplified version
      // Full implementation would track per-position P&L
      if daily_loss <= -max_loss_pct {
        RiskResult::{
          passed: false,
          message: "Stop loss triggered: " +
          Float::to_string(daily_loss * 100.0) +
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
/// Single stock position limit rule
/// Limits exposure to any single stock
pub fn single_stock_limit_rule(max_pct : Float) -> RiskRule {
  RiskRule::{
    name: "Single Stock Limit Rule",
    priority: 5,
    check_fn: fn(_, pos_ratio, _) {
      // Note: This checks total position ratio
      // Full implementation would check per-stock exposure
      if pos_ratio > max_pct {
        RiskResult::{
          passed: false,
          message: "Single stock exposure exceeded: " +
          Float::to_string(pos_ratio * 100.0) +
          "%",
          action: RiskAction::ReducePosition(pos_ratio - max_pct),
        }
      } else {
        RiskResult::{
          passed: true,
          message: "Single stock exposure within limits",
          action: RiskAction::Allow,
        }
      }
    },
  }
}

///|
/// Take profit rule (optional profit-taking trigger)
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
pub fn default_rules() -> Array[RiskRule] {
  [
    max_drawdown_rule(0.20), // 20% max drawdown
    position_limit_rule(0.95), // 95% max position
    daily_loss_limit_rule(0.05), // 5% daily loss limit
  ]
}
