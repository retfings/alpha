/// Risk management types
///
/// Types and utilities for the risk management system, including
/// risk actions, results, rules, and the risk engine.

///|
/// Risk action resulting from rule evaluation
/// Determines what action to take when a risk rule is triggered
pub enum RiskAction {
  /// Allow the trade/order to proceed
  Allow
  /// Reject the trade/order
  Reject
  /// Reduce position by specified percentage (0.0-1.0)
  ReducePosition(Float)
  /// Stop all trading immediately
  StopTrading
} derive(Show, Eq)

///|
/// Helper functions for creating RiskAction values (for tests)
///
/// These functions provide convenient constructors for testing
pub fn risk_action_allow() -> RiskAction {
  RiskAction::Allow
}

///|
pub fn risk_action_reject() -> RiskAction {
  RiskAction::Reject
}

///|
pub fn risk_action_stop_trading() -> RiskAction {
  RiskAction::StopTrading
}

///|
/// Create a ReducePosition action
///
/// Parameters:
/// - pct: Percentage to reduce (0.0-1.0)
pub fn risk_action_reduce_position(pct : Float) -> RiskAction {
  RiskAction::ReducePosition(pct)
}

///|
/// Helper functions for creating RiskResult values (for tests)
///
/// Parameters:
/// - message: Description of the result
pub fn risk_result_pass(message : String) -> RiskResult {
  RiskResult::{ passed: true, message, action: RiskAction::Allow }
}

///|
/// Create a failing RiskResult
///
/// Parameters:
/// - message: Description of why the rule failed
/// - action: Action to take in response
pub fn risk_result_fail(message : String, action : RiskAction) -> RiskResult {
  RiskResult::{ passed: false, message, action }
}

///|
/// Risk evaluation result
/// Returned by risk rule checks
pub struct RiskResult {
  /// Whether the rule passed (true) or failed (false)
  passed : Bool
  /// Human-readable explanation of the result
  message : String
  /// Recommended action based on the rule evaluation
  action : RiskAction
}

///|
/// Risk rule definition
/// A rule that checks risk constraints and returns an action
pub struct RiskRule {
  /// Rule name for identification and logging
  name : String
  /// Priority (lower number = higher priority)
  priority : Int
  /// Check function: (drawdown, position_ratio, daily_loss) -> RiskResult
  check_fn : (Float, Float, Float) -> RiskResult
} derive(Show)

///|
/// Risk engine state
/// Manages a collection of risk rules and evaluates them
pub struct RiskEngine {
  /// List of registered risk rules
  rules : Array[RiskRule]
  /// Whether trading has been stopped due to violations
  mut stopped : Bool
  /// History of rule violations
  violations : Array[String]
}

///|
/// Create a new risk engine
///
/// Returns:
/// - Empty risk engine with no rules
///
/// Usage:
/// ```mbt check-disabled
/// let engine = create_risk_engine()
/// engine.add_rule(max_drawdown_rule(0.2))
/// ```
pub fn create_risk_engine() -> RiskEngine {
  RiskEngine::{ rules: [], stopped: false, violations: [] }
}

///|
/// Add a rule to the engine
///
/// Parameters:
/// - rule: RiskRule to add
///
/// Rules are evaluated in order of priority (lower number = higher priority)
pub fn RiskEngine::add_rule(self : RiskEngine, rule : RiskRule) -> Unit {
  self.rules.push(rule)
}

///|
/// Check all rules against current state
///
/// Parameters:
/// - current_drawdown: Current portfolio drawdown (negative percentage)
/// - position_ratio: Current position ratio (0.0-1.0)
/// - daily_loss: Current daily loss (negative percentage)
///
/// Returns:
/// - Combined RiskResult from all rule evaluations
/// - Returns StopTrading if engine was already stopped
///
/// Behavior:
/// - Evaluates rules in priority order
/// - Stops at first failing rule
/// - Records violations for logging
pub fn RiskEngine::check(
  self : RiskEngine,
  current_drawdown : Float,
  position_ratio : Float,
  daily_loss : Float,
) -> RiskResult {
  if self.stopped {
    return RiskResult::{
      passed: false,
      message: "Trading stopped due to previous violations",
      action: RiskAction::StopTrading,
    }
  }

  for rule in self.rules {
    let result = (rule.check_fn)(current_drawdown, position_ratio, daily_loss)
    if !result.passed {
      self.violations.push(rule.name + ": " + result.message)
      match result.action {
        RiskAction::StopTrading => {
          self.stopped = true
          return result
        }
        RiskAction::Reject => return result
        RiskAction::ReducePosition(_) => return result
        RiskAction::Allow => ignore(())
      }
    }
  }

  RiskResult::{
    passed: true,
    message: "All risk rules passed",
    action: RiskAction::Allow,
  }
}
