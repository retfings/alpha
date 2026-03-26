/// Risk management types

///|
/// Risk action resulting from rule evaluation
pub enum RiskAction {
  Allow
  Reject
  ReducePosition(Float)
  StopTrading
}

///|
/// Risk evaluation result
pub struct RiskResult {
  passed : Bool
  message : String
  action : RiskAction
}

///|
/// Risk rule definition
pub struct RiskRule {
  name : String
  priority : Int
  check_fn : (Float, Float, Float) -> RiskResult
} derive(Show)

///|
/// Risk engine state
pub struct RiskEngine {
  rules : Array[RiskRule]
  mut stopped : Bool
  violations : Array[String]
}

///|
/// Create a new risk engine
pub fn create_risk_engine() -> RiskEngine {
  RiskEngine::{ rules: [], stopped: false, violations: [] }
}

///|
/// Add a rule to the engine
pub fn RiskEngine::add_rule(self : RiskEngine, rule : RiskRule) -> Unit {
  self.rules.push(rule)
}

///|
/// Check all rules against current state
/// Returns true if all rules pass
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
