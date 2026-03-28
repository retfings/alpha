///|
/// Whitebox tests for trading_models module
///
/// Tests for trading model configurations and engine logic:
/// - Periodic rebalancing model
/// - Conditional trigger model
/// - Weight calculation and scoring
/// - Trigger condition evaluation
test "PeriodicRebalancingConfig default values" {
  let config = @trading_models.PeriodicRebalancingConfig::default()

  assert(config.frequency == @trading_models.RebalanceFrequency::Monthly)
  assert(config.rebalance_day == 1)
  assert(config.max_positions == 10)
  assert(config.skip_holidays == true)
}

///|
test "RebalanceFrequency enum to json" {
  let weekly = @trading_models.RebalanceFrequency::Weekly
  let monthly = @trading_models.RebalanceFrequency::Monthly
  let custom = @trading_models.RebalanceFrequency::Custom(10)

  // Verify enum values are distinct
  assert(weekly != monthly)
  assert(monthly != custom)
}

///|
test "PeriodicRebalancingConfig custom values" {
  let config = @trading_models.PeriodicRebalancingConfig::{
    frequency: @trading_models.RebalanceFrequency::BiWeekly,
    rebalance_day: 15,
    max_positions: 20,
    skip_holidays: false,
  }

  assert(config.frequency == @trading_models.RebalanceFrequency::BiWeekly)
  assert(config.rebalance_day == 15)
  assert(config.max_positions == 20)
  assert(config.skip_holidays == false)
}

///|
test "ConditionOp enum values" {
  let gt = @trading_models.ConditionOp::Gt
  let gte = @trading_models.ConditionOp::Gte
  let lt = @trading_models.ConditionOp::Lt
  let lte = @trading_models.ConditionOp::Lte
  let eq = @trading_models.ConditionOp::Eq
  let cross_above = @trading_models.ConditionOp::CrossAbove
  let cross_below = @trading_models.ConditionOp::CrossBelow

  // Verify all operators are distinct
  assert(gt != gte)
  assert(lt != lte)
  assert(cross_above != cross_below)
  assert(gt != cross_above)
}

///|
test "IndicatorType enum variants" {
  let market = @trading_models.IndicatorType::Market("Volume_Ratio")
  let technical = @trading_models.IndicatorType::Technical("RSI_14")
  let financial = @trading_models.IndicatorType::Financial("ROE")

  assert(market != technical)
  assert(technical != financial)
  assert(market != financial)
}

///|
test "TriggerCondition create basic" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Gte,
    30.0,
  )

  assert(condition.indicator_name == "RSI_14")
  assert(condition.op == @trading_models.ConditionOp::Gte)
  assert_float_eq(condition.threshold, 30.0, 0.0001)
  assert(condition.min_threshold == None)
  assert(condition.max_threshold == None)
}

///|
test "TriggerCondition create range" {
  let condition = @trading_models.TriggerCondition::create_range(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    30.0,
    70.0,
  )

  assert(condition.indicator_name == "RSI_14")
  assert_float_eq(condition.threshold, 30.0, 0.0001)
  assert(condition.min_threshold != None)
  assert(condition.max_threshold != None)
  assert_float_eq(condition.min_threshold.get_or(0.0), 30.0, 0.0001)
  assert_float_eq(condition.max_threshold.get_or(0.0), 70.0, 0.0001)
}

///|
test "ConditionalTriggerConfig default values" {
  let config = @trading_models.ConditionalTriggerConfig::default()

  assert(config.conditions.length() == 0)
  assert(config.require_all == true)
  assert_float_eq(config.min_strength, 50.0, 0.0001)
  assert(config.cooldown_days == 5)
  assert(config.max_positions == 10)
}

///|
test "check_trigger_condition Gt operator" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Gt,
    50.0,
  )

  // Above threshold - should trigger
  assert(@trading_models.check_trigger_condition(condition, 55.0, 48.0) == true)
  // Below threshold - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 45.0, 48.0) == false,
  )
  // At threshold - should not trigger (strict greater than)
  assert(
    @trading_models.check_trigger_condition(condition, 50.0, 48.0) == false,
  )
}

///|
test "check_trigger_condition Gte operator" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Gte,
    50.0,
  )

  // Above threshold - should trigger
  assert(@trading_models.check_trigger_condition(condition, 55.0, 48.0) == true)
  // Below threshold - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 45.0, 48.0) == false,
  )
  // At threshold - should trigger (greater than or equal)
  assert(@trading_models.check_trigger_condition(condition, 50.0, 48.0) == true)
}

///|
test "check_trigger_condition Lt operator" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Lt,
    30.0,
  )

  // Below threshold - should trigger
  assert(@trading_models.check_trigger_condition(condition, 25.0, 35.0) == true)
  // Above threshold - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 35.0, 25.0) == false,
  )
}

///|
test "check_trigger_condition Lte operator" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Lte,
    30.0,
  )

  // Below threshold - should trigger
  assert(@trading_models.check_trigger_condition(condition, 25.0, 35.0) == true)
  // Above threshold - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 35.0, 25.0) == false,
  )
  // At threshold - should trigger
  assert(@trading_models.check_trigger_condition(condition, 30.0, 25.0) == true)
}

///|
test "check_trigger_condition CrossAbove" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::CrossAbove,
    50.0,
  )

  // Crossed above (was below, now above) - should trigger
  assert(@trading_models.check_trigger_condition(condition, 55.0, 45.0) == true)
  // Already above - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 55.0, 60.0) == false,
  )
  // Still below - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 45.0, 40.0) == false,
  )
  // Crossed below - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 45.0, 55.0) == false,
  )
}

///|
test "check_trigger_condition CrossBelow" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::CrossBelow,
    50.0,
  )

  // Crossed below (was above, now below) - should trigger
  assert(@trading_models.check_trigger_condition(condition, 45.0, 55.0) == true)
  // Already below - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 45.0, 40.0) == false,
  )
  // Still above - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 55.0, 60.0) == false,
  )
  // Crossed above - should not trigger
  assert(
    @trading_models.check_trigger_condition(condition, 55.0, 45.0) == false,
  )
}

///|
test "is_in_range function" {
  // Within range
  assert(@trading_models.is_in_range(5.0, 0.0, 10.0) == true)
  assert(@trading_models.is_in_range(0.0, 0.0, 10.0) == true)
  assert(@trading_models.is_in_range(10.0, 0.0, 10.0) == true)

  // Outside range
  assert(@trading_models.is_in_range(-1.0, 0.0, 10.0) == false)
  assert(@trading_models.is_in_range(11.0, 0.0, 10.0) == false)
}

///|
test "WeightConfig equal weights" {
  let weights = @trading_models.WeightConfig::equal()

  let total = weights.market_weight +
    weights.technical_weight +
    weights.financial_weight
  assert_float_eq(total, 100.0, 0.1)
}

///|
test "WeightConfig custom weights" {
  let weights = @trading_models.WeightConfig::create(50.0, 30.0, 20.0)

  assert_float_eq(weights.market_weight, 50.0, 0.0001)
  assert_float_eq(weights.technical_weight, 30.0, 0.0001)
  assert_float_eq(weights.financial_weight, 20.0, 0.0001)
}

///|
test "calculate_weighted_score" {
  let weights = @trading_models.WeightConfig::create(40.0, 35.0, 25.0)

  let score = @trading_models.calculate_weighted_score(
    weights, 80.0, 60.0, 70.0,
  )

  // Expected: (80 * 40 + 60 * 35 + 70 * 25) / 100 = (3200 + 2100 + 1750) / 100 = 70.5
  assert_float_eq(score, 70.5, 0.0001)
}

///|
test "calculate_weighted_score equal weights" {
  let weights = @trading_models.WeightConfig::equal()

  let score = @trading_models.calculate_weighted_score(
    weights, 60.0, 70.0, 80.0,
  )

  // With equal weights (~33.3 each), result should be close to average
  // (60 * 33.3 + 70 * 33.3 + 80 * 33.4) / 100 = ~70
  assert(score > 69.0 && score < 71.0)
}

///|
test "normalize_score standard" {
  // Higher values are better (inverse = false)
  let score = @trading_models.normalize_score(75.0, 50.0, 100.0, false)

  // (75 - 50) / (100 - 50) * 100 = 50
  assert_float_eq(score, 50.0, 0.0001)
}

///|
test "normalize_score inverse" {
  // Higher values are worse (inverse = true), e.g., P/E ratio
  let score = @trading_models.normalize_score(25.0, 10.0, 50.0, true)

  // Normalized: (25 - 10) / (50 - 10) * 100 = 37.5
  // Inverted: 100 - 37.5 = 62.5
  assert_float_eq(score, 62.5, 0.0001)
}

///|
test "normalize_score at boundaries" {
  // At minimum (non-inverse)
  assert_float_eq(
    @trading_models.normalize_score(0.0, 0.0, 100.0, false),
    0.0,
    0.0001,
  )

  // At maximum (non-inverse)
  assert_float_eq(
    @trading_models.normalize_score(100.0, 0.0, 100.0, false),
    100.0,
    0.0001,
  )

  // At minimum (inverse) - should be 100
  assert_float_eq(
    @trading_models.normalize_score(0.0, 0.0, 100.0, true),
    100.0,
    0.0001,
  )

  // At maximum (inverse) - should be 0
  assert_float_eq(
    @trading_models.normalize_score(100.0, 0.0, 100.0, true),
    0.0,
    0.0001,
  )
}

///|
test "normalize_score zero range" {
  // When min == max, should return 50
  assert_float_eq(
    @trading_models.normalize_score(50.0, 50.0, 50.0, false),
    50.0,
    0.0001,
  )
}

///|
test "PeriodicRebalancer create" {
  let config = @trading_models.PeriodicRebalancingConfig::default()
  let rebalancer = @trading_models.PeriodicRebalancer::create(config)

  assert(rebalancer.positions.length() == 0)
  assert(rebalancer.pending_trades.length() == 0)
  assert(rebalancer.last_rebalance_date == None)
}

///|
test "PeriodicRebalancer is_rebalance_due no previous" {
  let config = @trading_models.PeriodicRebalancingConfig::default()
  let rebalancer = @trading_models.PeriodicRebalancer::create(config)

  // No previous rebalance - always due
  assert(
    @trading_models.PeriodicRebalancer::is_rebalance_due(
      rebalancer, "2024-03-28",
    ) ==
    true,
  )
}

///|
test "ConditionalTriggerEngine create" {
  let config = @trading_models.ConditionalTriggerConfig::default()
  let engine = @trading_models.ConditionalTriggerEngine::create(config)

  assert(engine.active_signals.length() == 0)
}

///|
test "ConditionalTriggerEngine check_stock single condition" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Gte,
    30.0,
  )

  let config = @trading_models.ConditionalTriggerConfig::{
    conditions: [condition],
    require_all: true,
    min_strength: 50.0,
    cooldown_days: 5,
    max_positions: 10,
  }

  let engine = @trading_models.ConditionalTriggerEngine::create(config)

  let indicator_values = Map::new()
  let indicator_values = Map::set(indicator_values, "RSI_14", 35.0)

  let previous_values = Map::new()
  let previous_values = Map::set(previous_values, "RSI_14", 28.0)

  let result = @trading_models.ConditionalTriggerEngine::check_stock(
    engine, "sh.600000", indicator_values, previous_values, "2024-03-28",
  )

  // Condition met (RSI >= 30), should trigger
  assert(result != None)
  let r = result.get_or(@trading_models.StockSelectionResult::{
    code: "",
    score: 0.0,
    triggered_conditions: [],
    selection_date: "",
    model_type: @trading_models.TradingModelType::ConditionalTrigger,
  })
  assert(r.code == "sh.600000")
  assert(r.triggered_conditions.length() > 0)
}

///|
test "ConditionalTriggerEngine check_stock condition not met" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Gte,
    50.0,
  )

  let config = @trading_models.ConditionalTriggerConfig::{
    conditions: [condition],
    require_all: true,
    min_strength: 50.0,
    cooldown_days: 5,
    max_positions: 10,
  }

  let engine = @trading_models.ConditionalTriggerEngine::create(config)

  let indicator_values = Map::new()
  let indicator_values = Map::set(indicator_values, "RSI_14", 35.0)

  let previous_values = Map::new()

  let result = @trading_models.ConditionalTriggerEngine::check_stock(
    engine, "sh.600000", indicator_values, previous_values, "2024-03-28",
  )

  // Condition not met (RSI < 50), should not trigger
  assert(result == None)
}

///|
test "ConditionalTriggerEngine check_stock cooldown" {
  let condition = @trading_models.TriggerCondition::create(
    @trading_models.IndicatorType::Technical("RSI_14"),
    "RSI_14",
    @trading_models.ConditionOp::Gte,
    30.0,
  )

  let config = @trading_models.ConditionalTriggerConfig::{
    conditions: [condition],
    require_all: true,
    min_strength: 50.0,
    cooldown_days: 10,
    max_positions: 10,
  }

  let mut engine = @trading_models.ConditionalTriggerEngine::create(config)
  // Set last trigger date
  engine.last_trigger_dates = Map::set(
    engine.last_trigger_dates,
    "sh.600000",
    "2024-03-25",
  )

  let indicator_values = Map::new()
  let indicator_values = Map::set(indicator_values, "RSI_14", 35.0)

  let previous_values = Map::new()

  // Current date is only 3 days after last trigger, within 10-day cooldown
  let result = @trading_models.ConditionalTriggerEngine::check_stock(
    engine, "sh.600000", indicator_values, previous_values, "2024-03-28",
  )

  // In cooldown period, should not trigger
  assert(result == None)
}

///|
test "TradingModelType enum" {
  let periodic = @trading_models.TradingModelType::PeriodicRebalancing
  let conditional = @trading_models.TradingModelType::ConditionalTrigger

  assert(periodic != conditional)
}

///|
test "StockSelectionResult creation" {
  let result = @trading_models.StockSelectionResult::{
    code: "sh.600000",
    score: 85.5,
    triggered_conditions: ["RSI_14", "MACD"],
    selection_date: "2024-03-28",
    model_type: @trading_models.TradingModelType::ConditionalTrigger,
  }

  assert(result.code == "sh.600000")
  assert_float_eq(result.score, 85.5, 0.0001)
  assert(result.triggered_conditions.length() == 2)
  assert(result.selection_date == "2024-03-28")
}

///|
test "TradingModelConfig with periodic" {
  let periodic_config = @trading_models.PeriodicRebalancingConfig::default()

  let config = @trading_models.TradingModelConfig::{
    model_type: @trading_models.TradingModelType::PeriodicRebalancing,
    periodic_config: Some(periodic_config),
    trigger_config: None,
    stock_filters: ["banking", "technology"],
    weights: None,
  }

  assert(
    config.model_type == @trading_models.TradingModelType::PeriodicRebalancing,
  )
  assert(config.periodic_config != None)
  assert(config.stock_filters.length() == 2)
}

///|
test "TradingModelConfig with trigger" {
  let trigger_config = @trading_models.ConditionalTriggerConfig::default()

  let config = @trading_models.TradingModelConfig::{
    model_type: @trading_models.TradingModelType::ConditionalTrigger,
    periodic_config: None,
    trigger_config: Some(trigger_config),
    stock_filters: [],
    weights: Some(@trading_models.WeightConfig::equal()),
  }

  assert(
    config.model_type == @trading_models.TradingModelType::ConditionalTrigger,
  )
  assert(config.trigger_config != None)
  assert(config.weights != None)
}

///|
test "generate_mock_indicator_data" {
  let data = @trading_models.generate_mock_indicator_data()

  assert(Map::get(data, "RSI_14") != None)
  assert(Map::get(data, "MACD") != None)
  assert(Map::get(data, "ROE") != None)
}

///|
test "generate_mock_previous_data" {
  let data = @trading_models.generate_mock_previous_data()

  assert(Map::get(data, "RSI_14") != None)
  assert(Map::get(data, "Volume_Ratio") != None)
}

///|
fn assert_float_eq(actual : Float, expected : Float, tolerance : Float) -> Unit {
  let diff = Float::abs(actual - expected)
  if diff > tolerance {
    error(
      "Float assertion failed: expected " +
      ~+(expected.to_string()) +
      ~+(", got ") +
      ~+(actual.to_string()),
    )
  }
}
