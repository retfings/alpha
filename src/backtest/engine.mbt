/// Backtest engine
///
/// Core engine for running strategy backtests on historical data.

///|
/// Backtest engine state
/// Manages the backtest execution and records results
pub struct BacktestEngine {
  /// Backtest configuration
  config : @strategy.BacktestConfig
  /// Portfolio being managed
  portfolio : @portfolio.Portfolio
  /// Risk engine for trade validation
  risk_engine : @risk.RiskEngine
  /// List of executed trades
  trades : Array[Trade]
  /// Equity curve (daily snapshots)
  equity_curve : Array[EquityPoint]
  /// Current date in backtest
  current_date : String
  /// Current equity value
  current_equity : Float
  /// Peak equity value seen
  peak_equity : Float
  /// Maximum drawdown seen
  max_drawdown : Float
}

///|
/// Create a new backtest engine
///
/// Parameters:
/// - config: Backtest configuration
///
/// Returns:
/// - Initialized BacktestEngine with:
///   - New portfolio with initial capital
///   - Risk engine with default rules
///   - Empty trade list and equity curve
///
/// Examples:
/// ```mbt check
/// let config = @strategy.default_backtest_config()
/// let engine = create_backtest_engine(config)
/// ```
pub fn create_backtest_engine(
  config : @strategy.BacktestConfig,
) -> BacktestEngine {
  let portfolio = @portfolio.create_portfolio(config.initial_capital)
  let risk_engine = @risk.create_risk_engine()

  // Add default risk rules
  let default_rules = @risk.default_rules()
  for rule in default_rules {
    risk_engine.add_rule(rule)
  }

  BacktestEngine::{
    config,
    portfolio,
    risk_engine,
    trades: [],
    equity_curve: [],
    current_date: "",
    current_equity: config.initial_capital,
    peak_equity: config.initial_capital,
    max_drawdown: 0.0,
  }
}

///|
/// Run backtest on given data
///
/// Parameters:
/// - engine: BacktestEngine to use
/// - klines: Array of historical K-line data
/// - strategy: Strategy to backtest
///
/// Returns:
/// - BacktestResult with full results and statistics
///
/// Behavior:
/// - Iterates through klines chronologically
/// - Gets strategy signals for each bar
/// - Checks risk rules before executing
/// - Records equity curve and trades
/// - Calculates final statistics
///
/// Examples:
/// ```mbt check
/// let config = @strategy.default_backtest_config()
/// let engine = create_backtest_engine(config)
/// let strategy = @strategy.builtins.create_ma_cross_strategy(10, 30)
/// // let klines = ... load data ...
/// // let result = run_backtest(engine, klines, strategy)
/// ```
pub fn run_backtest(
  engine : BacktestEngine,
  klines : Array[@data.KLine],
  strategy : @strategy.Strategy,
) -> BacktestResult {
  let close_history : Array[Float] = []

  let mut current_date = ""
  let mut current_equity : Float = engine.config.initial_capital
  let mut peak_equity : Float = engine.config.initial_capital
  let mut max_drawdown : Float = 0.0
  let trades : Array[Trade] = []
  let equity_curve : Array[EquityPoint] = []

  for kline in klines {
    current_date = kline.date
    close_history.push(kline.close)

    // Skip until we have enough data
    if close_history.length() < 20 {
      continue
    }

    // Recreate context with updated values
    let ctx = @strategy.StrategyContext::{
      capital: engine.portfolio.total_value(),
      position: engine.portfolio.position_value(),
      current_price: kline.close,
      last_signal: None,
    }

    // Get strategy signal
    let signal = (strategy.on_bar)(kline, ctx, close_history)

    // Check risk rules
    let current_dd = @drawdown.calculate_current_drawdown(
      equity_curve.map(fn(e) { e.equity }),
    )
    let pos_ratio = engine.portfolio.position_ratio()

    let risk_result = engine.risk_engine.check(current_dd, pos_ratio, 0.0)

    // Execute signal if risk allows
    if risk_result.passed {
      match signal.action {
        @strategy.Action::Buy => {
          let quantity : Float = 100.0 // Simplified - should calculate based on capital
          trades.push(Trade::{
            stock: kline.code,
            action: @strategy.Action::Buy,
            price: kline.close,
            quantity,
            timestamp: kline.date,
            commission: quantity * kline.close * engine.config.commission_rate,
          })
        }
        @strategy.Action::Sell => {
          // Simplified - sell all
          let quantity : Float = 100.0
          trades.push(Trade::{
            stock: kline.code,
            action: @strategy.Action::Sell,
            price: kline.close,
            quantity,
            timestamp: kline.date,
            commission: quantity * kline.close * engine.config.commission_rate,
          })
        }
        @strategy.Action::Hold => ignore(())
      }
    }

    // Record equity
    let equity = engine.portfolio.total_value()
    current_equity = equity
    if equity > peak_equity {
      peak_equity = equity
    }
    let dd : Float = (equity - peak_equity) / peak_equity
    if dd < max_drawdown {
      max_drawdown = dd
    }

    equity_curve.push(EquityPoint::{
      date: kline.date,
      equity,
      drawdown: dd,
      position: engine.portfolio.position_value(),
      cash: engine.portfolio.cash,
    })
  }

  generate_result_with_state(
    engine, current_date, current_equity, peak_equity, max_drawdown, trades, equity_curve,
  )
}

///|
/// Generate backtest result
fn generate_result(engine : BacktestEngine) -> BacktestResult {
  let final_capital = engine.portfolio.total_value()
  let total_return = (final_capital - engine.config.initial_capital) /
    engine.config.initial_capital

  let stats = calculate_stats(engine)

  BacktestResult::{
    initial_capital: engine.config.initial_capital,
    final_capital,
    total_return,
    max_drawdown: engine.max_drawdown,
    sharpe_ratio: stats.sharpe_ratio,
    total_trades: engine.trades.length(),
    equity_curve: engine.equity_curve,
    trades: engine.trades,
    stats,
  }
}

///|
/// Generate backtest result with mutable state
fn generate_result_with_state(
  engine : BacktestEngine,
  current_date : String,
  current_equity : Float,
  peak_equity : Float,
  max_drawdown : Float,
  trades : Array[Trade],
  equity_curve : Array[EquityPoint],
) -> BacktestResult {
  let final_capital = engine.portfolio.total_value()
  let total_return = (final_capital - engine.config.initial_capital) /
    engine.config.initial_capital

  let stats = calculate_stats_with_state(engine, equity_curve, trades)

  BacktestResult::{
    initial_capital: engine.config.initial_capital,
    final_capital,
    total_return,
    max_drawdown,
    sharpe_ratio: stats.sharpe_ratio,
    total_trades: trades.length(),
    equity_curve,
    trades,
    stats,
  }
}

///|
/// Calculate backtest statistics
fn calculate_stats(engine : BacktestEngine) -> BacktestStats {
  let equities = engine.equity_curve.map(fn(e) { e.equity })
  let returns = calculate_returns(equities)

  let total_return = if engine.config.initial_capital > 0.0 {
    (engine.portfolio.total_value() - engine.config.initial_capital) /
    engine.config.initial_capital
  } else {
    0.0
  }

  // Simplified Sharpe ratio (annualized)
  let sharpe = if returns.length() > 1 {
    let avg_return = average(returns)
    let std_return = std_dev(returns)
    if std_return > 0.0 {
      avg_return / std_return * Float::sqrt(252.0)
    } else {
      0.0
    }
  } else {
    0.0
  }

  // Count winning/losing trades
  let winning = 0
  let losing = 0
  for trade in engine.trades {
    if trade.action == @strategy.Action::Buy {
      // Will be closed by a sell - simplified counting
      ignore(())
    }
  }

  BacktestStats::{
    total_return,
    annual_return: total_return, // Simplified
    max_drawdown: engine.max_drawdown,
    sharpe_ratio: sharpe,
    sortino_ratio: 0.0, // Simplified
    win_rate: 0.5, // Simplified
    profit_factor: 1.0, // Simplified
    total_trades: engine.trades.length(),
    winning_trades: winning,
    losing_trades: losing,
    avg_win: 0.0,
    avg_loss: 0.0,
    avg_trade_duration: 0.0,
  }
}

///|
/// Calculate backtest statistics with mutable state
fn calculate_stats_with_state(
  engine : BacktestEngine,
  equity_curve : Array[EquityPoint],
  trades : Array[Trade],
) -> BacktestStats {
  let equities = equity_curve.map(fn(e) { e.equity })
  let returns = calculate_returns(equities)

  let total_return = if engine.config.initial_capital > 0.0 {
    (engine.portfolio.total_value() - engine.config.initial_capital) /
    engine.config.initial_capital
  } else {
    0.0
  }

  // Simplified Sharpe ratio (annualized)
  let sharpe = if returns.length() > 1 {
    let avg_return = average(returns)
    let std_return = std_dev(returns)
    if std_return > 0.0 {
      avg_return / std_return * Float::sqrt(252.0)
    } else {
      0.0
    }
  } else {
    0.0
  }

  // Count winning/losing trades
  let winning = 0
  let losing = 0
  for trade in trades {
    if trade.action == @strategy.Action::Buy {
      // Will be closed by a sell - simplified counting
      ignore(())
    }
  }

  BacktestStats::{
    total_return,
    annual_return: total_return, // Simplified
    max_drawdown: 0.0, // Will be overridden by caller
    sharpe_ratio: sharpe,
    sortino_ratio: 0.0, // Simplified
    win_rate: 0.5, // Simplified
    profit_factor: 1.0, // Simplified
    total_trades: trades.length(),
    winning_trades: winning,
    losing_trades: losing,
    avg_win: 0.0,
    avg_loss: 0.0,
    avg_trade_duration: 0.0,
  }
}

///|
/// Calculate returns from equity series
fn calculate_returns(equities : Array[Float]) -> Array[Float] {
  if equities.length() < 2 {
    return []
  }

  let returns : Array[Float] = []
  let mut i = 1
  while i < equities.length() {
    let ret = (equities[i] - equities[i - 1]) / equities[i - 1]
    returns.push(ret)
    i = i + 1
  }
  returns
}

///|
/// Calculate average of an array
fn average(values : Array[Float]) -> Float {
  if values.length() == 0 {
    return Float::from_double(0.0)
  }
  let mut sum : Float = 0.0
  for v in values {
    sum = sum + v
  }
  sum / Float::from_int(values.length())
}

///|
/// Calculate standard deviation
fn std_dev(values : Array[Float]) -> Float {
  if values.length() < 2 {
    return Float::from_double(0.0)
  }
  let avg = average(values)
  let mut sum_sq : Float = 0.0
  for v in values {
    let diff : Float = v - avg
    sum_sq = sum_sq + diff * diff
  }
  Float::sqrt(sum_sq / Float::from_int(values.length() - 1))
}
