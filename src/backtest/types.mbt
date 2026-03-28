/// Backtest types and result structures
///
/// Types for representing backtest results, trades, and performance statistics.

///|
/// A single trade record
/// Represents an executed trade in the backtest
pub(all) struct Trade {
  /// Stock code traded
  stock : @data.StockCode
  /// Action taken (Buy/Sell)
  action : @strategy.Action
  /// Execution price
  price : Float
  /// Number of shares traded
  quantity : Float
  /// Timestamp of trade
  timestamp : String
  /// Commission paid for the trade
  commission : Float
} derive(ToJson, Show)

///|
/// Equity point at a specific date
/// Snapshot of portfolio state at a point in time
pub(all) struct EquityPoint {
  /// Date in YYYY-MM-DD format
  date : String
  /// Total portfolio equity
  equity : Float
  /// Current drawdown (negative percentage)
  drawdown : Float
  /// Position value
  position : Float
  /// Available cash
  cash : Float
} derive(ToJson, Show)

///|
/// Backtest statistics
/// Performance metrics calculated from backtest results
pub(all) struct BacktestStats {
  /// Total return as percentage (e.g., 0.15 for 15%)
  total_return : Float
  /// Annualized return as percentage
  annual_return : Float
  /// Maximum drawdown (negative percentage)
  max_drawdown : Float
  /// Sharpe ratio (risk-adjusted return measure)
  sharpe_ratio : Float
  /// Sortino ratio (downside risk-adjusted return)
  sortino_ratio : Float
  /// Win rate (winning trades / total trades)
  win_rate : Float
  /// Profit factor (gross profit / gross loss)
  profit_factor : Float
  /// Total number of trades
  total_trades : Int
  /// Number of winning trades
  winning_trades : Int
  /// Number of losing trades
  losing_trades : Int
  /// Average profit per winning trade
  avg_win : Float
  /// Average loss per losing trade
  avg_loss : Float
  /// Average trade duration (in days)
  avg_trade_duration : Float
} derive(ToJson, Show)

///|
/// Complete backtest result
/// Full results from running a backtest
pub(all) struct BacktestResult {
  /// Initial capital at start of backtest
  initial_capital : Float
  /// Final capital at end of backtest
  final_capital : Float
  /// Total return as percentage
  total_return : Float
  /// Maximum drawdown experienced
  max_drawdown : Float
  /// Sharpe ratio
  sharpe_ratio : Float
  /// Total number of trades executed
  total_trades : Int
  /// Equity curve (daily snapshots)
  equity_curve : Array[EquityPoint]
  /// List of all trades
  trades : Array[Trade]
  /// Calculated statistics
  stats : BacktestStats
} derive(ToJson, Show)

///|
/// Trade log for analysis
/// Detailed log of trades with commentary
pub(all) struct TradeLog {
  /// List of trade log entries
  entries : Array[TradeLogEntry]
}

///|
/// Single trade log entry
/// Detailed information about a single trade
pub(all) struct TradeLogEntry {
  /// Trade date
  date : String
  /// Stock code
  stock : @data.StockCode
  /// Action description
  action : String
  /// Execution price
  price : Float
  /// Quantity traded
  quantity : Float
  /// P&L if known (None for open trades)
  pnl : Float?
  /// Commentary or notes about the trade
  commentary : String
}

///|
/// Create an empty trade log
///
/// Returns:
/// - Empty TradeLog ready for adding entries
pub fn create_trade_log() -> TradeLog {
  TradeLog::{ entries: [] }
}

///|
/// Add entry to trade log
///
/// Parameters:
/// - date: Trade date
/// - stock: Stock code
/// - action: Action description
/// - price: Execution price
/// - quantity: Quantity traded
/// - pnl: P&L (optional)
/// - commentary: Notes about the trade
pub fn TradeLog::add(
  self : TradeLog,
  date : String,
  stock : @data.StockCode,
  action : String,
  price : Float,
  quantity : Float,
  pnl : Float?,
  commentary : String,
) -> Unit {
  self.entries.push(TradeLogEntry::{
    date,
    stock,
    action,
    price,
    quantity,
    pnl,
    commentary,
  })
}
