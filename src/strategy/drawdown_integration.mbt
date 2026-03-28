/// Integration between trading models and drawdown monitoring
///
/// This module provides:
/// - Drawdown-aware trading signals
/// - Risk-adjusted position sizing based on drawdown
/// - Automatic position reduction on drawdown thresholds

///|
/// Drawdown-aware trading signal
pub struct DrawdownAwareSignal {
  /// Underlying trading signal
  signal : @types.Signal
  /// Current portfolio drawdown
  drawdown : Float
  /// Drawdown level
  drawdown_level : @drawdown.DrawdownLevel
  /// Position adjustment factor (0.0 - 1.0)
  position_factor : Float
  /// Whether signal should be executed
  should_execute : Bool
  /// Reason for rejection (if any)
  rejection_reason : String?
} derive(Show, ToJson)

///|
/// Drawdown risk manager configuration
pub struct DrawdownRiskManagerConfig {
  /// Reduce position when drawdown exceeds this threshold
  reduce_position_threshold : Float
  /// Reduce position by this percentage when threshold exceeded
  reduce_position_by : Float
  /// Stop trading when drawdown exceeds this threshold
  stop_trading_threshold : Float
  /// Resume trading when drawdown recovers to this level
  resume_threshold : Float
} derive(Show, ToJson)

///|
/// Create default drawdown risk manager config
pub fn DrawdownRiskManagerConfig::default() -> DrawdownRiskManagerConfig {
  DrawdownRiskManagerConfig::{
    reduce_position_threshold: -0.10, // Reduce at 10% drawdown
    reduce_position_by: 0.50, // Reduce by 50%
    stop_trading_threshold: -0.20, // Stop at 20% drawdown
    resume_threshold: -0.05, // Resume at 5% drawdown
  }
}

///|
/// Drawdown risk manager state
pub struct DrawdownRiskManager {
  /// Configuration
  config : DrawdownRiskManagerConfig
  /// Current trading state
  is_trading_allowed : Bool
  /// Current position reduction factor
  position_factor : Float
  /// Peak portfolio value
  peak_value : Float
  /// Current portfolio value
  current_value : Float
  /// Current drawdown
  current_drawdown : Float
  /// Drawdown level
  drawdown_level : @drawdown.DrawdownLevel
} derive(Show)

///|
/// Create drawdown risk manager
pub fn DrawdownRiskManager::create(
  config : DrawdownRiskManagerConfig,
  initial_value : Float,
) -> DrawdownRiskManager {
  DrawdownRiskManager::{
    config,
    is_trading_allowed: true,
    position_factor: 1.0,
    peak_value: initial_value,
    current_value: initial_value,
    current_drawdown: 0.0,
    drawdown_level: @drawdown.DrawdownLevel::Normal,
  }
}

///|
/// Update portfolio value and recalculate drawdown
///
/// Parameters:
/// - manager: DrawdownRiskManager
/// - current_value: Current portfolio value
///
/// Returns:
/// - Updated DrawdownRiskManager
pub fn DrawdownRiskManager::update_value(
  manager : DrawdownRiskManager,
  current_value : Float,
) -> DrawdownRiskManager {
  let mut new_manager = manager
  new_manager.current_value = current_value

  // Update peak if current exceeds it
  if current_value > new_manager.peak_value {
    new_manager.peak_value = current_value
  }

  // Calculate drawdown
  if new_manager.peak_value > 0.0 {
    new_manager.current_drawdown = (current_value - new_manager.peak_value) /
      new_manager.peak_value
  }

  // Classify drawdown level
  new_manager.drawdown_level = @drawdown.classify_drawdown(
    new_manager.current_drawdown,
  )

  // Update trading state based on drawdown
  let (allowed, factor) = update_trading_state(new_manager)
  new_manager.is_trading_allowed = allowed
  new_manager.position_factor = factor

  new_manager
}

///|
/// Update trading state based on drawdown
fn update_trading_state(manager : DrawdownRiskManager) -> (Bool, Float) {
  let dd = manager.current_drawdown
  let config = manager.config

  // Check if should stop trading
  if dd <= config.stop_trading_threshold && !manager.is_trading_allowed {
    // Already stopped, wait for recovery
    if dd >= config.resume_threshold {
      (true, 1.0) // Resume trading
    } else {
      (false, 0.0) // Keep stopped
    }
  } else if dd <= config.stop_trading_threshold {
    // Just crossed stop threshold
    (false, 0.0)
  } else if dd <= config.reduce_position_threshold {
    // Reduce position
    (true, 1.0 - config.reduce_position_by)
  } else {
    // Normal trading
    (true, 1.0)
  }
}

///|
/// Wrap a trading signal with drawdown awareness
///
/// Parameters:
/// - manager: DrawdownRiskManager
/// - signal: Original trading signal
///
/// Returns:
/// - DrawdownAwareSignal with execution decision
pub fn DrawdownRiskManager::wrap_signal(
  manager : DrawdownRiskManager,
  signal : @types.Signal,
) -> DrawdownAwareSignal {
  let should_execute = manager.is_trading_allowed &&
    signal.action != @types.Action::Hold
  let rejection_reason = if !manager.is_trading_allowed {
    Some("Trading stopped due to drawdown")
  } else if signal.action == @types.Action::Hold {
    Some("Signal is Hold")
  } else {
    None
  }

  DrawdownAwareSignal::{
    signal,
    drawdown: manager.current_drawdown,
    drawdown_level: manager.drawdown_level,
    position_factor: manager.position_factor,
    should_execute,
    rejection_reason,
  }
}

///|
/// Get adjusted position size based on drawdown
///
/// Parameters:
/// - manager: DrawdownRiskManager
/// - base_size: Original position size
///
/// Returns:
/// - Adjusted position size
pub fn DrawdownRiskManager::get_adjusted_position_size(
  manager : DrawdownRiskManager,
  base_size : Float,
) -> Float {
  base_size * manager.position_factor
}

///|
/// Check if trading is currently allowed
pub fn DrawdownRiskManager::is_trading_allowed(
  manager : DrawdownRiskManager,
) -> Bool {
  manager.is_trading_allowed
}

///|
/// Get current drawdown status as human-readable string
pub fn DrawdownRiskManager::get_status(manager : DrawdownRiskManager) -> String {
  let dd_pct = manager.current_drawdown * 100.0
  let level_str = match manager.drawdown_level {
    @drawdown.DrawdownLevel::Normal => "Normal"
    @drawdown.DrawdownLevel::Minor => "Minor"
    @drawdown.DrawdownLevel::Moderate => "Moderate"
    @drawdown.DrawdownLevel::Significant => "Significant"
    @drawdown.DrawdownLevel::Severe => "Severe"
  }

  let trading_status = if manager.is_trading_allowed {
    if manager.position_factor < 1.0 {
      "Reduced Position"
    } else {
      "Active"
    }
  } else {
    "Stopped"
  }

  "Drawdown: " +
  ~+(dd_pct.to_string()) +
  ~+("% | Level: ") +
  ~+(level_str) +
  ~+(" | Status: ") +
  ~+(trading_status)
}

///|
/// Portfolio drawdown monitor for multi-position portfolios
pub struct PortfolioDrawdownMonitor {
  /// Initial portfolio value
  initial_value : Float
  /// Peak portfolio value
  peak_value : Float
  /// Current portfolio value
  current_value : Float
  /// Current drawdown
  current_drawdown : Float
  /// Maximum drawdown experienced
  max_drawdown : Float
  /// Drawdown level
  drawdown_level : @drawdown.DrawdownLevel
  /// Individual position values
  positions : Map[@data.StockCode, Float]
} derive(Show)

///|
/// Create portfolio drawdown monitor
pub fn PortfolioDrawdownMonitor::create(
  initial_value : Float,
) -> PortfolioDrawdownMonitor {
  PortfolioDrawdownMonitor::{
    initial_value,
    peak_value: initial_value,
    current_value: initial_value,
    current_drawdown: 0.0,
    max_drawdown: 0.0,
    drawdown_level: @drawdown.DrawdownLevel::Normal,
    positions: Map::new(),
  }
}

///|
/// Update portfolio value from positions
///
/// Parameters:
/// - monitor: PortfolioDrawdownMonitor
/// - positions: Map of stock codes to current values
///
/// Returns:
/// - Updated PortfolioDrawdownMonitor
pub fn PortfolioDrawdownMonitor::update_from_positions(
  monitor : PortfolioDrawdownMonitor,
  positions : Map[@data.StockCode, Float],
) -> PortfolioDrawdownMonitor {
  let mut new_monitor = monitor
  new_monitor.positions = positions

  // Calculate total portfolio value
  let total = Map::values(positions).fold(0.0, fn(acc, v) { acc + v })
  new_monitor.current_value = total

  // Update peak
  if total > new_monitor.peak_value {
    new_monitor.peak_value = total
  }

  // Calculate drawdown
  if new_monitor.peak_value > 0.0 {
    new_monitor.current_drawdown = (total - new_monitor.peak_value) /
      new_monitor.peak_value
  }

  // Update max drawdown
  if new_monitor.current_drawdown < new_monitor.max_drawdown {
    new_monitor.max_drawdown = new_monitor.current_drawdown
  }

  // Classify level
  new_monitor.drawdown_level = @drawdown.classify_drawdown(
    new_monitor.current_drawdown,
  )

  new_monitor
}

///|
/// Get portfolio drawdown info
pub fn PortfolioDrawdownMonitor::get_drawdown_info(
  monitor : PortfolioDrawdownMonitor,
) -> @drawdown.DrawdownInfo {
  @drawdown.DrawdownInfo::{
    peak: monitor.peak_value,
    trough: monitor.current_value,
    peak_date: "", // Would need date tracking
    trough_date: "",
    drawdown: monitor.current_drawdown,
    duration: 0, // Would need date tracking
    recovered: monitor.current_drawdown >= 0.0,
  }
}

///|
/// Get portfolio summary
pub fn PortfolioDrawdownMonitor::get_summary(
  monitor : PortfolioDrawdownMonitor,
) -> @drawdown.PortfolioDrawdown {
  let stock_drawdowns : Array[(@data.StockCode, Float)] = []

  // Calculate individual stock drawdowns (simplified)
  // In practice, would need historical peak for each position

  @drawdown.create_portfolio_drawdown(stock_drawdowns)
}

///|
/// Strategy executor with integrated drawdown monitoring
pub struct DrawdownAwareStrategyExecutor {
  /// Risk manager
  risk_manager : DrawdownRiskManager
  /// Portfolio monitor
  portfolio_monitor : PortfolioDrawdownMonitor
  /// Signals generated
  signals : Array[@types.Signal]
  /// Executed signals
  executed_signals : Array[@types.Signal]
  /// Rejected signals
  rejected_signals : Array[(String, String)] // (signal_desc, reason)
} derive(Show)

///|
/// Create drawdown-aware strategy executor
pub fn DrawdownAwareStrategyExecutor::create(
  risk_config : DrawdownRiskManagerConfig,
  initial_capital : Float,
) -> DrawdownAwareStrategyExecutor {
  DrawdownAwareStrategyExecutor::{
    risk_manager: DrawdownRiskManager::create(risk_config, initial_capital),
    portfolio_monitor: PortfolioDrawdownMonitor::create(initial_capital),
    signals: [],
    executed_signals: [],
    rejected_signals: [],
  }
}

///|
/// Process a trading signal with drawdown checks
///
/// Parameters:
/// - executor: DrawdownAwareStrategyExecutor
/// - signal: Signal to process
/// - portfolio_value: Current portfolio value
///
/// Returns:
/// - Updated executor with signal processed
pub fn DrawdownAwareStrategyExecutor::process_signal(
  executor : DrawdownAwareStrategyExecutor,
  signal : @types.Signal,
  portfolio_value : Float,
) -> DrawdownAwareStrategyExecutor {
  let mut new_executor = executor

  // Update risk manager with current value
  new_executor.risk_manager = DrawdownRiskManager::update_value(
    new_executor.risk_manager,
    portfolio_value,
  )

  // Update portfolio monitor
  let positions = new_executor.portfolio_monitor.positions
  new_executor.portfolio_monitor = PortfolioDrawdownMonitor::update_from_positions(
    new_executor.portfolio_monitor,
    positions,
  )

  // Record signal
  new_executor.signals.push(signal)

  // Wrap signal with drawdown awareness
  let wrapped = DrawdownRiskManager::wrap_signal(
    new_executor.risk_manager,
    signal,
  )

  if wrapped.should_execute {
    new_executor.executed_signals.push(signal)
  } else {
    let reason = wrapped.rejection_reason.get_or("Unknown")
    new_executor.rejected_signals.push(
      (signal.stock + ~+(" ") + ~+(@types.show_action(signal.action)), reason),
    )
  }

  new_executor
}

///|
/// Get executor status summary
pub fn DrawdownAwareStrategyExecutor::get_status(
  executor : DrawdownAwareStrategyExecutor,
) -> String {
  let rm_status = DrawdownRiskManager::get_status(executor.risk_manager)
  rm_status +
  ~+(" | Signals: ") +
  ~+(executor.executed_signals.length().to_string()) +
  ~+(" executed, ") +
  ~+(executor.rejected_signals.length().to_string()) +
  ~+(" rejected")
}

///|
/// Get execution statistics
pub struct ExecutionStats {
  total_signals : Int
  executed : Int
  rejected : Int
  execution_rate : Float
  current_drawdown : Float
  max_drawdown : Float
} derive(Show)

///|
/// Get execution statistics from executor
pub fn DrawdownAwareStrategyExecutor::get_stats(
  executor : DrawdownAwareStrategyExecutor,
) -> ExecutionStats {
  let total = executor.signals.length()
  let exec = executor.executed_signals.length()
  let rej = executor.rejected_signals.length()

  let rate = if total > 0 {
    Float::from_int(exec) / Float::from_int(total)
  } else {
    0.0
  }

  ExecutionStats::{
    total_signals: total,
    executed: exec,
    rejected: rej,
    execution_rate: rate,
    current_drawdown: executor.risk_manager.current_drawdown,
    max_drawdown: executor.risk_manager.current_drawdown.min(
      executor.risk_manager.current_drawdown,
    ),
  }
}

///|
/// Show action as string (helper for executor status)
fn @types.show_action(action : @types.Action) -> String {
  match action {
    @types.Action::Buy => "Buy"
    @types.Action::Sell => "Sell"
    @types.Action::Hold => "Hold"
  }
}
