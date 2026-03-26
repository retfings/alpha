/// Backtest types and result structures

///|
/// A single trade record
pub struct Trade {
  stock : @data.StockCode
  action : @strategy.Action
  price : Float
  quantity : Float
  timestamp : String
  commission : Float
}

///|
/// Equity point at a specific date
pub struct EquityPoint {
  date : String
  equity : Float
  drawdown : Float
  position : Float
  cash : Float
}

///|
/// Backtest statistics
pub struct BacktestStats {
  total_return : Float
  annual_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  sortino_ratio : Float
  win_rate : Float
  profit_factor : Float
  total_trades : Int
  winning_trades : Int
  losing_trades : Int
  avg_win : Float
  avg_loss : Float
  avg_trade_duration : Float
}

///|
/// Complete backtest result
pub struct BacktestResult {
  initial_capital : Float
  final_capital : Float
  total_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  total_trades : Int
  equity_curve : Array[EquityPoint]
  trades : Array[Trade]
  stats : BacktestStats
}

///|
/// Trade log for analysis
pub struct TradeLog {
  entries : Array[TradeLogEntry]
}

///|
/// Single trade log entry
pub struct TradeLogEntry {
  date : String
  stock : @data.StockCode
  action : String
  price : Float
  quantity : Float
  pnl : Float?
  commentary : String
}

///|
/// Create an empty trade log
pub fn create_trade_log() -> TradeLog {
  TradeLog::{ entries: [] }
}

///|
/// Add entry to trade log
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
