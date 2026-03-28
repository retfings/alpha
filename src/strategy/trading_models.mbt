/// Trading models for stock selection and rebalancing
///
/// This module provides two main trading models:
/// 1. Periodic Rebalancing (定期调仓) - Rebalance at fixed intervals
/// 2. Conditional Trigger (条件触发) - Trade when conditions are met

///|
/// Trading model type
pub enum TradingModelType {
  /// Periodic rebalancing at fixed intervals
  PeriodicRebalancing
  /// Conditional trigger based on indicators
  ConditionalTrigger
} derive(Eq, Show, ToJson)

///|
/// Rebalancing frequency for periodic model
pub enum RebalanceFrequency {
  /// Weekly rebalancing
  Weekly
  /// Bi-weekly rebalancing
  BiWeekly
  /// Monthly rebalancing
  Monthly
  /// Quarterly rebalancing
  Quarterly
  /// Custom interval (days)
  Custom(Int)
} derive(Eq, Show, ToJson)

///|
/// Periodic rebalancing configuration
pub struct PeriodicRebalancingConfig {
  /// Rebalancing frequency
  frequency : RebalanceFrequency
  /// Rebalancing day (1-28 for monthly, 1-4 for weekly)
  rebalance_day : Int
  /// Maximum positions to hold
  max_positions : Int
  /// Whether to rebalance on holidays (skip if false)
  skip_holidays : Bool
} derive(Show, ToJson)

///|
/// Create periodic rebalancing config with default values
pub fn PeriodicRebalancingConfig::default() -> PeriodicRebalancingConfig {
  PeriodicRebalancingConfig::{
    frequency: RebalanceFrequency::Monthly,
    rebalance_day: 1,
    max_positions: 10,
    skip_holidays: true,
  }
}

///|
/// Condition operator for conditional trigger model
pub enum ConditionOp {
  /// Greater than
  Gt
  /// Greater than or equal
  Gte
  /// Less than
  Lt
  /// Less than or equal
  Lte
  /// Equal
  Eq
  /// Cross above (was below, now above)
  CrossAbove
  /// Cross below (was above, now below)
  CrossBelow
} derive(Eq, Show, ToJson)

///|
/// Indicator type for condition
pub enum IndicatorType {
  /// Market indicators (price, volume, etc.)
  Market(String)
  /// Technical indicators (MACD, RSI, etc.)
  Technical(String)
  /// Financial indicators (ROE, margin, etc.)
  Financial(String)
} derive(Eq, Show, ToJson)

///|
/// Single condition for trigger model
pub struct TriggerCondition {
  /// Indicator to monitor
  indicator : IndicatorType
  /// Indicator name/parameter (e.g., "RSI_14", "MA_20")
  indicator_name : String
  /// Condition operator
  op : ConditionOp
  /// Threshold value
  threshold : Float
  /// Minimum threshold for range (optional)
  min_threshold : Float?
  /// Maximum threshold for range (optional)
  max_threshold : Float?
} derive(Show, ToJson)

///|
/// Create a trigger condition
pub fn TriggerCondition::create(
  indicator : IndicatorType,
  indicator_name : String,
  op : ConditionOp,
  threshold : Float,
) -> TriggerCondition {
  TriggerCondition::{
    indicator,
    indicator_name,
    op,
    threshold,
    min_threshold: None,
    max_threshold: None,
  }
}

///|
/// Create a range trigger condition
pub fn TriggerCondition::create_range(
  indicator : IndicatorType,
  indicator_name : String,
  min_val : Float,
  max_val : Float,
) -> TriggerCondition {
  TriggerCondition::{
    indicator,
    indicator_name,
    op: ConditionOp::Gte,
    threshold: min_val,
    min_threshold: Some(min_val),
    max_threshold: Some(max_val),
  }
}

///|
/// Conditional trigger model configuration
pub struct ConditionalTriggerConfig {
  /// List of trigger conditions
  conditions : Array[TriggerCondition]
  /// Logic: All conditions must be met, or Any condition
  require_all : Bool
  /// Minimum strength score (0-100)
  min_strength : Float
  /// Cooldown period (days) after trigger
  cooldown_days : Int
  /// Maximum positions to hold
  max_positions : Int
} derive(Show, ToJson)

///|
/// Create conditional trigger config with default values
pub fn ConditionalTriggerConfig::default() -> ConditionalTriggerConfig {
  ConditionalTriggerConfig::{
    conditions: [],
    require_all: true,
    min_strength: 50.0,
    cooldown_days: 5,
    max_positions: 10,
  }
}

///|
/// Trading model configuration (unified)
pub struct TradingModelConfig {
  /// Model type
  model_type : TradingModelType
  /// Periodic rebalancing config (if applicable)
  periodic_config : PeriodicRebalancingConfig?
  /// Conditional trigger config (if applicable)
  trigger_config : ConditionalTriggerConfig?
  /// Stock selection criteria
  stock_filters : Array[String]
  /// Weight configuration for ranking
  weights : WeightConfig?
} derive(Show, ToJson)

///|
/// Weight configuration for stock ranking
pub struct WeightConfig {
  /// Weight for market indicators (0-100)
  market_weight : Float
  /// Weight for technical indicators (0-100)
  technical_weight : Float
  /// Weight for financial indicators (0-100)
  financial_weight : Float
} derive(Show, ToJson)

///|
/// Create weight config with equal weights
pub fn WeightConfig::equal() -> WeightConfig {
  WeightConfig::{
    market_weight: 33.3,
    technical_weight: 33.3,
    financial_weight: 33.4,
  }
}

///|
/// Create weight config with custom weights
pub fn WeightConfig::create(
  market : Float,
  technical : Float,
  financial : Float,
) -> WeightConfig {
  WeightConfig::{
    market_weight: market,
    technical_weight: technical,
    financial_weight: financial,
  }
}

///|
/// Stock selection result
pub struct StockSelectionResult {
  /// Selected stock code
  code : @data.StockCode
  /// Selection score
  score : Float
  /// Triggered conditions (for conditional model)
  triggered_conditions : Array[String]
  /// Selection date
  selection_date : String
  /// Model type used
  model_type : TradingModelType
} derive(Show, ToJson)

///|
/// Check if a trigger condition is met
///
/// Parameters:
/// - condition: Trigger condition to check
/// - current_value: Current indicator value
/// - previous_value: Previous indicator value (for cross detection)
///
/// Returns:
/// - true if condition is met
pub fn check_trigger_condition(
  condition : TriggerCondition,
  current_value : Float,
  previous_value : Float,
) -> Bool {
  match condition.op {
    ConditionOp::Gt: { current_value > condition.threshold }
    ConditionOp::Gte: { current_value >= condition.threshold }
    ConditionOp::Lt: { current_value < condition.threshold }
    ConditionOp::Lte: { current_value <= condition.threshold }
    ConditionOp::Eq: { current_value == condition.threshold }
    ConditionOp::CrossAbove: {
      previous_value <= condition.threshold && current_value > condition.threshold
    }
    ConditionOp::CrossBelow: {
      previous_value >= condition.threshold && current_value < condition.threshold
    }
  }
}

///|
/// Check if value is within range
///
/// Parameters:
/// - value: Value to check
/// - min_val: Minimum value
/// - max_val: Maximum value
///
/// Returns:
/// - true if value is within range
pub fn is_in_range(value : Float, min_val : Float, max_val : Float) -> Bool {
  value >= min_val && value <= max_val
}

///|
/// Calculate combined score from weights
///
/// Parameters:
/// - weights: Weight configuration
/// - market_score: Market indicator score (0-100)
/// - technical_score: Technical indicator score (0-100)
/// - financial_score: Financial indicator score (0-100)
///
/// Returns:
/// - Combined weighted score
pub fn calculate_weighted_score(
  weights : WeightConfig,
  market_score : Float,
  technical_score : Float,
  financial_score : Float,
) -> Float {
  (
    market_score * weights.market_weight +
    technical_score * weights.technical_weight +
    financial_score * weights.financial_weight
  ) /
  100.0
}

///|
/// Normalize value to 0-100 score
///
/// Parameters:
/// - value: Actual value
/// - min_val: Minimum expected value
/// - max_val: Maximum expected value
/// - inverse: Whether higher values are worse (lower score)
///
/// Returns:
/// - Normalized score (0-100)
pub fn normalize_score(
  value : Float,
  min_val : Float,
  max_val : Float,
  inverse : Bool,
) -> Float {
  if max_val == min_val {
    return 50.0
  }

  let normalized = (value - min_val) / (max_val - min_val) * 100.0

  if inverse {
    100.0 - normalized
  } else {
    normalized
  }
}

///|
/// Periodic rebalancing engine state
pub struct PeriodicRebalancer {
  /// Configuration
  config : PeriodicRebalancingConfig
  /// Last rebalance date
  last_rebalance_date : String?
  /// Current positions
  positions : Array[@data.StockCode]
  /// Pending trades
  pending_trades : Array[(Action, @data.StockCode, Float)]
} derive(Show)

///|
/// Create periodic rebalancer
pub fn PeriodicRebalancer::create(
  config : PeriodicRebalancingConfig,
) -> PeriodicRebalancer {
  PeriodicRebalancer::{
    config,
    last_rebalance_date: None,
    positions: [],
    pending_trades: [],
  }
}

///|
/// Check if rebalancing is due
///
/// Parameters:
/// - rebalancer: PeriodicRebalancer
/// - current_date: Current trading date (YYYY-MM-DD)
///
/// Returns:
/// - true if rebalancing should be executed
pub fn PeriodicRebalancer::is_rebalance_due(
  rebalancer : PeriodicRebalancer,
  current_date : String,
) -> Bool {
  // If no previous rebalance, always due
  let last_date = match rebalancer.last_rebalance_date {
    Some(d): { d }
    None: { return true }
  }

  // Parse dates (simplified - assumes YYYY-MM-DD format)
  let (curr_year, curr_month, curr_day) = parse_date(current_date)
  let (last_year, last_month, last_day) = parse_date(last_date)

  match rebalancer.config.frequency {
    RebalanceFrequency::Weekly: {
      // Rebalance every 7 days
      days_since(last_date, current_date) >= 7
    }
    RebalanceFrequency::BiWeekly: {
      // Rebalance every 14 days
      days_since(last_date, current_date) >= 14
    }
    RebalanceFrequency::Monthly: {
      // Rebalance on specific day of month
      curr_month != last_month && curr_day >= rebalancer.config.rebalance_day
    }
    RebalanceFrequency::Quarterly: {
      // Rebalance every 3 months
      months_since(last_date, current_date) >= 3
    }
    RebalanceFrequency::Custom(days): {
      days_since(last_date, current_date) >= days
    }
  }
}

///|
/// Parse date string to (year, month, day)
fn parse_date(date : String) -> (Int, Int, Int) {
  // Simplified parsing for YYYY-MM-DD format
  let parts = date.split("-")
  if parts.length() >= 3 {
    (parts[0].to_int_or(2025), parts[1].to_int_or(1), parts[2].to_int_or(1))
  } else {
    (2025, 1, 1)
  }
}

///|
/// Calculate days between two dates (simplified)
fn days_since(date1 : String, date2 : String) -> Int {
  let (y1, m1, d1) = parse_date(date1)
  let (y2, m2, d2) = parse_date(date2)

  // Simplified calculation
  (y2 - y1) * 365 + (m2 - m1) * 30 + (d2 - d1)
}

///|
/// Calculate months between two dates (simplified)
fn months_since(date1 : String, date2 : String) -> Int {
  let (y1, m1, _) = parse_date(date1)
  let (y2, m2, _) = parse_date(date2)

  (y2 - y1) * 12 + (m2 - m1)
}

///|
/// Conditional trigger engine state
pub struct ConditionalTriggerEngine {
  /// Configuration
  config : ConditionalTriggerConfig
  /// Last trigger date per stock
  last_trigger_dates : Map[@data.StockCode, String]
  /// Active signals
  active_signals : Array[StockSelectionResult]
} derive(Show)

///|
/// Create conditional trigger engine
pub fn ConditionalTriggerEngine::create(
  config : ConditionalTriggerConfig,
) -> ConditionalTriggerEngine {
  ConditionalTriggerEngine::{
    config,
    last_trigger_dates: Map::new(),
    active_signals: [],
  }
}

///|
/// Check if stock meets trigger conditions
///
/// Parameters:
/// - engine: ConditionalTriggerEngine
/// - stock_code: Stock to check
/// - indicator_values: Current indicator values
/// - previous_values: Previous indicator values
/// - current_date: Current trading date
///
/// Returns:
/// - StockSelectionResult if triggered, None otherwise
pub fn ConditionalTriggerEngine::check_stock(
  engine : ConditionalTriggerEngine,
  stock_code : @data.StockCode,
  indicator_values : Map[String, Float],
  previous_values : Map[String, Float],
  current_date : String,
) -> StockSelectionResult? {
  // Check cooldown
  let last_trigger = Map::get(engine.last_trigger_dates, stock_code)
  if let Some(last) = last_trigger {
    if days_since(last, current_date) < engine.config.cooldown_days {
      return None
    }
  }

  let mut triggered = []
  let mut condition_count = 0

  // Check each condition
  for condition in engine.config.conditions {
    condition_count = condition_count + 1
    let ind_name = condition.indicator_name
    let curr_val = Map::get(indicator_values, ind_name).get_or(0.0)
    let prev_val = Map::get(previous_values, ind_name).get_or(0.0)

    if check_trigger_condition(condition, curr_val, prev_val) {
      triggered.push(ind_name)
    }
  }

  // Determine if trigger fires
  let should_trigger = if engine.config.require_all {
    triggered.length() == condition_count && condition_count > 0
  } else {
    triggered.length() > 0
  }

  if should_trigger {
    Some(StockSelectionResult::{
      code: stock_code,
      score: Float::from_int(triggered.length()) * 10.0,
      triggered_conditions: triggered,
      selection_date: current_date,
      model_type: TradingModelType::ConditionalTrigger,
    })
  } else {
    None
  }
}

///|
/// Mock indicator data generator for testing
pub fn generate_mock_indicator_data() -> Map[String, Float] {
  let mut data = Map::new()
  Map::set(data, "RSI_14", 65.5)
  Map::set(data, "MACD", 1.25)
  Map::set(data, "MA_20", 15.50)
  Map::set(data, "Volume_Ratio", 2.5)
  Map::set(data, "ROE", 12.8)
  Map::set(data, "NP_Margin", 18.5)
  data
}

///|
/// Mock previous indicator data generator for testing
pub fn generate_mock_previous_data() -> Map[String, Float] {
  let mut data = Map::new()
  Map::set(data, "RSI_14", 62.0)
  Map::set(data, "MACD", 1.10)
  Map::set(data, "MA_20", 15.30)
  Map::set(data, "Volume_Ratio", 1.8)
  Map::set(data, "ROE", 12.5)
  Map::set(data, "NP_Margin", 18.0)
  data
}
