///|
/// Whitebox tests for drawdown_integration module
///
/// Tests for drawdown-aware trading signal processing:
/// - DrawdownRiskManager configuration and state
/// - Position reduction logic
/// - Trading halt/resume thresholds
/// - Signal wrapping with drawdown context
/// - Portfolio drawdown monitoring
/// - Execution statistics
test "DrawdownRiskManagerConfig default values" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()

  assert_float_eq(config.reduce_position_threshold, -0.10, 0.0001)
  assert_float_eq(config.reduce_position_by, 0.50, 0.0001)
  assert_float_eq(config.stop_trading_threshold, -0.20, 0.0001)
  assert_float_eq(config.resume_threshold, -0.05, 0.0001)
}

///|
test "DrawdownRiskManager create" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  assert(manager.is_trading_allowed == true)
  assert_float_eq(manager.position_factor, 1.0, 0.0001)
  assert_float_eq(manager.peak_value, 100000.0, 0.0001)
  assert_float_eq(manager.current_value, 100000.0, 0.0001)
  assert_float_eq(manager.current_drawdown, 0.0, 0.0001)
  assert(manager.drawdown_level == @drawdown.DrawdownLevel::Normal)
}

///|
test "DrawdownRiskManager update_value no drawdown" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Portfolio stays flat
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 100000.0,
  )

  assert(manager.is_trading_allowed == true)
  assert_float_eq(manager.position_factor, 1.0, 0.0001)
  assert_float_eq(manager.current_drawdown, 0.0, 0.0001)
}

///|
test "DrawdownRiskManager update_value new peak" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Portfolio increases to new peak
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 120000.0,
  )

  assert(manager.is_trading_allowed == true)
  assert_float_eq(manager.position_factor, 1.0, 0.0001)
  assert_float_eq(manager.peak_value, 120000.0, 0.0001)
  assert_float_eq(manager.current_value, 120000.0, 0.0001)
  assert_float_eq(manager.current_drawdown, 0.0, 0.0001)
}

///|
test "DrawdownRiskManager update_value moderate drawdown" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Portfolio goes up then down 8%
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 110000.0,
  )
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 101200.0,
  )

  assert(manager.is_trading_allowed == true)
  assert_float_eq(manager.position_factor, 1.0, 0.0001)
  assert_float_eq(manager.peak_value, 110000.0, 0.0001)
  // Drawdown = (101200 - 110000) / 110000 = -0.08 = -8%
  assert(manager.current_drawdown < -0.07 && manager.current_drawdown > -0.09)
}

///|
test "DrawdownRiskManager update_value position reduction triggered" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Portfolio goes up then down 12% (exceeds reduce_position_threshold of -10%)
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 100000.0,
  )
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 88000.0,
  )

  assert(manager.is_trading_allowed == true)
  // Position should be reduced by 50%
  assert_float_eq(manager.position_factor, 0.5, 0.0001)
  assert_float_eq(manager.peak_value, 100000.0, 0.0001)
  // Drawdown = (88000 - 100000) / 100000 = -0.12 = -12%
  assert(manager.current_drawdown < -0.11 && manager.current_drawdown < -0.12)
}

///|
test "DrawdownRiskManager update_value trading stopped" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Portfolio drops 22% (exceeds stop_trading_threshold of -20%)
  let manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 78000.0,
  )

  assert(manager.is_trading_allowed == false)
  assert_float_eq(manager.position_factor, 0.0, 0.0001)
  // Drawdown = (78000 - 100000) / 100000 = -0.22 = -22%
  assert(manager.current_drawdown < -0.20)
}

///|
test "DrawdownRiskManager update_value resume trading after recovery" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let mut manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // First trigger stop (22% drawdown)
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 78000.0,
  )
  assert(manager.is_trading_allowed == false)

  // Portfolio recovers to 97% of peak (3% drawdown, within resume_threshold of -5%)
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 97000.0,
  )

  assert(manager.is_trading_allowed == true)
  assert_float_eq(manager.position_factor, 1.0, 0.0001)
}

///|
test "DrawdownRiskManager wrap_signal normal trading" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Buy,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  let wrapped = @drawdown_integration.DrawdownRiskManager::wrap_signal(
    manager, signal,
  )

  assert(wrapped.should_execute == true)
  assert(wrapped.rejection_reason == None)
  assert_float_eq(wrapped.position_factor, 1.0, 0.0001)
}

///|
test "DrawdownRiskManager wrap_signal stopped trading" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let mut manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Trigger trading stop
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 78000.0,
  )

  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Buy,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  let wrapped = @drawdown_integration.DrawdownRiskManager::wrap_signal(
    manager, signal,
  )

  assert(wrapped.should_execute == false)
  assert(wrapped.rejection_reason != None)
  assert(
    wrapped.rejection_reason.get_or("") == "Trading stopped due to drawdown",
  )
}

///|
test "DrawdownRiskManager wrap_signal Hold action" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Hold,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  let wrapped = @drawdown_integration.DrawdownRiskManager::wrap_signal(
    manager, signal,
  )

  // Hold signals should not execute
  assert(wrapped.should_execute == false)
  assert(wrapped.rejection_reason != None)
}

///|
test "DrawdownRiskManager get_adjusted_position_size" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let mut manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Full position
  let size = @drawdown_integration.DrawdownRiskManager::get_adjusted_position_size(
    manager, 5000.0,
  )
  assert_float_eq(size, 5000.0, 0.0001)

  // Reduce position (simulate 12% drawdown)
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 88000.0,
  )
  let size = @drawdown_integration.DrawdownRiskManager::get_adjusted_position_size(
    manager, 5000.0,
  )
  // 50% reduction
  assert_float_eq(size, 2500.0, 0.0001)

  // Stopped trading (22% drawdown)
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 78000.0,
  )
  let size = @drawdown_integration.DrawdownRiskManager::get_adjusted_position_size(
    manager, 5000.0,
  )
  assert_float_eq(size, 0.0, 0.0001)
}

///|
test "DrawdownRiskManager is_trading_allowed" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let mut manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  // Initially allowed
  assert(
    @drawdown_integration.DrawdownRiskManager::is_trading_allowed(manager) ==
    true,
  )

  // Trigger stop
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 78000.0,
  )
  assert(
    @drawdown_integration.DrawdownRiskManager::is_trading_allowed(manager) ==
    false,
  )

  // Recover
  manager = @drawdown_integration.DrawdownRiskManager::update_value(
    manager, 97000.0,
  )
  assert(
    @drawdown_integration.DrawdownRiskManager::is_trading_allowed(manager) ==
    true,
  )
}

///|
test "DrawdownRiskManager get_status format" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let manager = @drawdown_integration.DrawdownRiskManager::create(
    config, 100000.0,
  )

  let status = @drawdown_integration.DrawdownRiskManager::get_status(manager)

  // Status should contain key information
  assert(status.contains("Drawdown"))
  assert(status.contains("Level"))
  assert(status.contains("Status"))
}

///|
test "DrawdownAwareSignal creation" {
  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Buy,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  let wrapped = @drawdown_integration.DrawdownAwareSignal::{
    signal,
    drawdown: -0.05,
    drawdown_level: @drawdown.DrawdownLevel::Minor,
    position_factor: 1.0,
    should_execute: true,
    rejection_reason: None,
  }

  assert(wrapped.signal.stock == "sh.600000")
  assert_float_eq(wrapped.drawdown, -0.05, 0.0001)
  assert(wrapped.drawdown_level == @drawdown.DrawdownLevel::Minor)
  assert_float_eq(wrapped.position_factor, 1.0, 0.0001)
  assert(wrapped.should_execute == true)
}

///|
test "PortfolioDrawdownMonitor create" {
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::create(100000.0)

  assert_float_eq(monitor.initial_value, 100000.0, 0.0001)
  assert_float_eq(monitor.peak_value, 100000.0, 0.0001)
  assert_float_eq(monitor.current_value, 100000.0, 0.0001)
  assert_float_eq(monitor.current_drawdown, 0.0, 0.0001)
  assert_float_eq(monitor.max_drawdown, 0.0, 0.0001)
  assert(monitor.drawdown_level == @drawdown.DrawdownLevel::Normal)
  assert(monitor.positions.length() == 0)
}

///|
test "PortfolioDrawdownMonitor update_from_positions" {
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::create(100000.0)

  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 50000.0)
  let positions = Map::set(positions, "sz.000001", 60000.0)

  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::update_from_positions(
    monitor, positions,
  )

  assert_float_eq(monitor.current_value, 110000.0, 0.0001)
  assert_float_eq(monitor.peak_value, 110000.0, 0.0001)
  assert_float_eq(monitor.current_drawdown, 0.0, 0.0001)
}

///|
test "PortfolioDrawdownMonitor update_from_positions drawdown" {
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::create(100000.0)

  // First go up
  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 60000.0)
  let positions = Map::set(positions, "sz.000001", 60000.0)
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::update_from_positions(
    monitor, positions,
  )

  assert_float_eq(monitor.peak_value, 120000.0, 0.0001)

  // Then down
  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 50000.0)
  let positions = Map::set(positions, "sz.000001", 50000.0)
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::update_from_positions(
    monitor, positions,
  )

  assert_float_eq(monitor.current_value, 100000.0, 0.0001)
  assert(monitor.current_drawdown < 0.0)
  assert(monitor.max_drawdown < 0.0)
}

///|
test "PortfolioDrawdownMonitor get_drawdown_info" {
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::create(100000.0)

  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 80000.0)
  let monitor = @drawdown_integration.PortfolioDrawdownMonitor::update_from_positions(
    monitor, positions,
  )

  let info = @drawdown_integration.PortfolioDrawdownMonitor::get_drawdown_info(
    monitor,
  )

  assert_float_eq(info.peak, 100000.0, 0.0001)
  assert_float_eq(info.trough, 80000.0, 0.0001)
  assert(info.drawdown < 0.0)
}

///|
test "DrawdownAwareStrategyExecutor create" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  assert(executor.signals.length() == 0)
  assert(executor.executed_signals.length() == 0)
  assert(executor.rejected_signals.length() == 0)
}

///|
test "DrawdownAwareStrategyExecutor process_signal executed" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Buy,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  // Create positions map
  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 100000.0)

  let mut executor = executor
  executor.portfolio_monitor.positions = positions

  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::process_signal(
    executor, signal, 100000.0,
  )

  assert(executor.signals.length() == 1)
  assert(executor.executed_signals.length() == 1)
  assert(executor.rejected_signals.length() == 0)
}

///|
test "DrawdownAwareStrategyExecutor process_signal rejected due to drawdown" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let mut executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  // First trigger trading stop
  executor.risk_manager = @drawdown_integration.DrawdownRiskManager::update_value(
    executor.risk_manager,
    78000.0,
  )

  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Buy,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 78000.0)
  executor.portfolio_monitor.positions = positions

  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::process_signal(
    executor, signal, 78000.0,
  )

  assert(executor.signals.length() == 1)
  assert(executor.executed_signals.length() == 0)
  assert(executor.rejected_signals.length() == 1)

  let rejected = executor.rejected_signals[0]
  assert(rejected.0.contains("sh.600000"))
  assert(rejected.1 == "Trading stopped due to drawdown")
}

///|
test "DrawdownAwareStrategyExecutor process_signal rejected Hold" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  let signal = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Hold,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }

  let positions = Map::new()
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::process_signal(
    executor, signal, 100000.0,
  )

  assert(executor.signals.length() == 1)
  assert(executor.executed_signals.length() == 0)
  assert(executor.rejected_signals.length() == 1)
}

///|
test "DrawdownAwareStrategyExecutor get_status" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  let status = @drawdown_integration.DrawdownAwareStrategyExecutor::get_status(
    executor,
  )

  assert(status.contains("Drawdown"))
  assert(status.contains("Signals"))
}

///|
test "DrawdownAwareStrategyExecutor get_stats empty" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  let stats = @drawdown_integration.DrawdownAwareStrategyExecutor::get_stats(
    executor,
  )

  assert(stats.total_signals == 0)
  assert(stats.executed == 0)
  assert(stats.rejected == 0)
  assert_float_eq(stats.execution_rate, 0.0, 0.0001)
}

///|
test "DrawdownAwareStrategyExecutor get_stats with signals" {
  let config = @drawdown_integration.DrawdownRiskManagerConfig::default()
  let mut executor = @drawdown_integration.DrawdownAwareStrategyExecutor::create(
    config, 100000.0,
  )

  let positions = Map::new()
  let positions = Map::set(positions, "sh.600000", 100000.0)
  executor.portfolio_monitor.positions = positions

  // Add 3 Buy signals (executed)
  let signal1 = @types.Signal::{
    stock: "sh.600000",
    action: @types.Action::Buy,
    price: 10.5,
    size: 1000.0,
    date: "2024-03-28",
  }
  let signal2 = @types.Signal::{
    stock: "sz.000001",
    action: @types.Action::Buy,
    price: 20.0,
    size: 500.0,
    date: "2024-03-28",
  }
  let signal3 = @types.Signal::{
    stock: "sh.600001",
    action: @types.Action::Sell,
    price: 15.0,
    size: 800.0,
    date: "2024-03-28",
  }

  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::process_signal(
    executor, signal1, 100000.0,
  )
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::process_signal(
    executor, signal2, 100000.0,
  )
  let executor = @drawdown_integration.DrawdownAwareStrategyExecutor::process_signal(
    executor, signal3, 100000.0,
  )

  let stats = @drawdown_integration.DrawdownAwareStrategyExecutor::get_stats(
    executor,
  )

  assert(stats.total_signals == 3)
  assert(stats.executed == 3)
  assert(stats.rejected == 0)
  assert_float_eq(stats.execution_rate, 1.0, 0.0001)
}

///|
test "ExecutionStats creation" {
  let stats = @drawdown_integration.ExecutionStats::{
    total_signals: 10,
    executed: 7,
    rejected: 3,
    execution_rate: 0.7,
    current_drawdown: -0.05,
    max_drawdown: -0.08,
  }

  assert(stats.total_signals == 10)
  assert(stats.executed == 7)
  assert(stats.rejected == 3)
  assert_float_eq(stats.execution_rate, 0.7, 0.0001)
  assert_float_eq(stats.current_drawdown, -0.05, 0.0001)
  assert_float_eq(stats.max_drawdown, -0.08, 0.0001)
}

///|
test "show_action helper" {
  assert(@types.show_action(@types.Action::Buy) == "Buy")
  assert(@types.show_action(@types.Action::Sell) == "Sell")
  assert(@types.show_action(@types.Action::Hold) == "Hold")
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
