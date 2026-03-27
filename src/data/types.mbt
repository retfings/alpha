/// Data types for quantitative trading

///|
/// Stock code type (e.g., "sh.600000", "sz.000001")
/// Represents a unique identifier for a traded security
pub type StockCode = String

///|
/// Trading frequency enumeration
/// Used to specify the time interval of market data
pub enum Frequency {
  /// Daily bars (one bar per trading day)
  Daily
  /// Weekly bars (one bar per trading week)
  Weekly
  /// Monthly bars (one bar per trading month)
  Monthly
  /// 5-minute bars
  Minute5
  /// 15-minute bars
  Minute15
  /// 30-minute bars
  Minute30
  /// 60-minute (hourly) bars
  Minute60
} derive(Eq, Show)

///|
/// K-line (candlestick) data structure
/// Represents OHLCV data for a single trading period
pub struct KLine {
  /// Stock code (e.g., "sh.600000")
  code : StockCode
  /// Trading date in YYYY-MM-DD format
  date : String
  /// Time of day (for minute-level data, optional for daily bars)
  time : String?
  /// Opening price at the start of the period
  open : Float
  /// Highest price during the period
  high : Float
  /// Lowest price during the period
  low : Float
  /// Closing price at the end of the period
  close : Float
  /// Trading volume (number of shares/contracts traded)
  volume : Float
  /// Trading amount (total value in CNY)
  amount : Float
  /// Turnover rate as a percentage (volume / float shares)
  turn : Float
} derive(Eq, ToJson, Show)

///|
/// Create a KLine with minimal fields (daily bars)
pub fn KLine::daily(
  code : StockCode,
  date : String,
  open : Float,
  high : Float,
  low : Float,
  close : Float,
  volume : Float,
  amount : Float,
  turn : Float,
) -> KLine {
  KLine::{
    code,
    date,
    time: None,
    open,
    high,
    low,
    close,
    volume,
    amount,
    turn,
  }
}

///|
/// Create a KLine with all fields (for minute bars or custom time)
pub fn KLine::create(
  code : StockCode,
  date : String,
  open : Float,
  high : Float,
  low : Float,
  close : Float,
  volume : Float,
  amount : Float,
  turn : Float,
  time? : String,
) -> KLine {
  KLine::{ code, date, time, open, high, low, close, volume, amount, turn }
}

///|
/// Time series data type
/// Generic type for pairing timestamps with values
pub type TimeSeries[T] = Array[(Int64, T)]
