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
/// ```mbt check-disabled
/// let config = @strategy.default_backtest_config()
///
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
/// ```mbt check-disabled
/// let config = @strategy.default_backtest_config()
///
/// let engine = create_backtest_engine(config)
///
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
          // Calculate quantity based on available capital (95% position limit)
          let available_cash = engine.portfolio.cash * 0.95
          let raw_quantity = available_cash / kline.close
          // Round down to nearest 100 shares (standard lot size)
          let quantity = Float::floor(raw_quantity / 100.0) * 100.0

          if quantity > 0.0 {
            // Execute buy through portfolio
            let success = engine.portfolio.buy(
              kline.code,
              quantity,
              kline.close,
            )
            if success {
              let cost = quantity * kline.close
              let commission = cost * engine.config.commission_rate
              trades.push(Trade::{
                stock: kline.code,
                action: @strategy.Action::Buy,
                price: kline.close,
                quantity,
                timestamp: kline.date,
                commission,
              })
            }
          }
        }
        @strategy.Action::Sell => {
          // Sell all holdings of this stock
          let mut quantity_sold : Float = 0.0
          let mut total_commission : Float = 0.0

          // Find and sell position for this stock
          for pos in engine.portfolio.positions {
            if pos.stock == kline.code && pos.quantity > 0.0 {
              quantity_sold = pos.quantity
              let proceeds = quantity_sold * kline.close
              total_commission = proceeds * engine.config.commission_rate
              let success = engine.portfolio.sell(
                kline.code,
                quantity_sold,
                kline.close,
              )
              if success {
                trades.push(Trade::{
                  stock: kline.code,
                  action: @strategy.Action::Sell,
                  price: kline.close,
                  quantity: quantity_sold,
                  timestamp: kline.date,
                  commission: total_commission,
                })
              }
              break
            }
          }
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
/// Generate backtest result with mutable state
fn generate_result_with_state(
  engine : BacktestEngine,
  _current_date : String,
  _current_equity : Float,
  _peak_equity : Float,
  max_drawdown : Float,
  trades : Array[Trade],
  equity_curve : Array[EquityPoint],
) -> BacktestResult {
  let final_capital = engine.portfolio.total_value()
  let total_return = (final_capital - engine.config.initial_capital) /
    engine.config.initial_capital

  let stats = calculate_stats_core(
    engine.config.initial_capital,
    engine.portfolio,
    equity_curve,
    trades,
    max_drawdown,
  )

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
/// Core statistics calculation function
/// Calculates backtest statistics from equity curve and trades
fn calculate_stats_core(
  initial_capital : Float,
  portfolio : @portfolio.Portfolio,
  equity_curve : Array[EquityPoint],
  trades : Array[Trade],
  max_drawdown : Float,
) -> BacktestStats {
  let equities = equity_curve.map(fn(e) { e.equity })
  let returns = calculate_returns(equities)

  let total_return = if initial_capital > 0.0 {
    (portfolio.total_value() - initial_capital) / initial_capital
  } else {
    0.0
  }

  // Annualized return
  let num_days = if equities.length() > 0 { equities.length() } else { 1 }
  let annual_return = if num_days > 0 {
    @math.powf(
      1.0 + total_return,
      Float::from_int(252) / Float::from_int(num_days),
    ) -
    1.0
  } else {
    0.0
  }

  // Sharpe ratio (annualized)
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

  // Sortino ratio (uses downside deviation instead of total std dev)
  let sortino = if returns.length() > 1 {
    let avg_return = average(returns)
    let downside_returns : Array[Float] = []
    for r in returns {
      if r < 0.0 {
        downside_returns.push(r)
      }
    }
    let downside_dev = if downside_returns.length() > 0 {
      let mut sum_sq : Float = 0.0
      for r in downside_returns {
        sum_sq = sum_sq + r * r
      }
      Float::sqrt(sum_sq / Float::from_int(downside_returns.length()))
    } else {
      0.0
    }
    if downside_dev > 0.0 {
      avg_return / downside_dev * Float::sqrt(252.0)
    } else {
      Float::from_double(999.0)
    }
  } else {
    0.0
  }

  // Calculate win/loss statistics by pairing buy and sell trades
  let mut winning = 0
  let mut losing = 0
  let mut total_profit : Float = 0.0
  let mut total_loss : Float = 0.0
  let mut buy_pending : Trade? = None
  let mut total_duration : Int = 0

  for trade in trades {
    match trade.action {
      @strategy.Action::Buy => buy_pending = Some(trade)
      @strategy.Action::Sell =>
        match buy_pending {
          Some(buy_trade) => {
            let buy_cost = buy_trade.quantity * buy_trade.price +
              buy_trade.commission
            let sell_proceeds = trade.quantity * trade.price - trade.commission
            let pnl = sell_proceeds - buy_cost

            if pnl > 0.0 {
              winning = winning + 1
              total_profit = total_profit + pnl
            } else {
              losing = losing + 1
              total_loss = total_loss + Float::abs(pnl)
            }

            // Calculate trade duration (simplified - counts as 1 day per trade)
            total_duration = total_duration + 1
          }
          None => ignore(())
        }
      @strategy.Action::Hold => ignore(())
    }
  }

  let total_closed_trades = winning + losing
  let avg_duration = if total_closed_trades > 0 {
    Float::from_int(total_duration) / Float::from_int(total_closed_trades)
  } else {
    0.0
  }

  let win_rate = if winning + losing > 0 {
    Float::from_int(winning) / Float::from_int(winning + losing)
  } else {
    0.0
  }

  let profit_factor = if total_loss > 0.0 {
    total_profit / total_loss
  } else if total_profit > 0.0 {
    Float::from_double(999.0)
  } else {
    0.0
  }

  BacktestStats::{
    total_return,
    annual_return,
    max_drawdown,
    sharpe_ratio: sharpe,
    sortino_ratio: sortino,
    win_rate,
    profit_factor,
    total_trades: trades.length(),
    winning_trades: winning,
    losing_trades: losing,
    avg_win: if winning > 0 {
      total_profit / Float::from_int(winning)
    } else {
      0.0
    },
    avg_loss: if losing > 0 {
      total_loss / Float::from_int(losing)
    } else {
      0.0
    },
    avg_trade_duration: avg_duration,
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
