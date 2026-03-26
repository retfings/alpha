/// HTTP API server for quantitative drawdown framework
///
/// This module provides HTTP API endpoints for:
/// - Stock data retrieval
/// - Backtest execution
/// - Drawdown analysis
/// - Portfolio management
///
/// Note: Actual HTTP serving requires C FFI or external runtime.
/// This module provides the business logic and type definitions.

///|
/// API Response wrapper
pub(all) enum ApiResponse[T] {
  Success(T)
  Error(ApiError)
}

///|
/// API error information
pub(all) struct ApiError {
  code : Int
  message : String
  details : String?
} derive(Show)

///|
/// Stock information
pub(all) struct StockInfo {
  code : String
  name : String
  exchange : String
  market : String
} derive(Show)

///|
/// K-line data with stock code
pub(all) struct KLineData {
  stock_code : String
  klines : Array[@data.KLine]
} derive(Show)

///|
/// Drawdown analysis result
pub(all) struct DrawdownResult {
  stock_code : String
  start_date : String
  end_date : String
  max_drawdown : Float
  peak : Float
  trough : Float
  peak_date : String
  trough_date : String
  duration : Int
  drawdown_series : Array[DrawdownPoint]
}

///|
/// Single drawdown point
pub(all) struct DrawdownPoint {
  date : String
  value : Float
  drawdown : Float
}

///|
/// Portfolio drawdown result
pub(all) struct PortfolioDrawdownResult {
  max_drawdown : Float
  current_drawdown : Float
  peak_date : String
  peak_value : Float
  drawdown_series : Array[DrawdownPoint]
  positions : Array[PositionInfo]
}

///|
/// Position information
pub(all) struct PositionInfo {
  stock_code : String
  quantity : Float
  avg_price : Float
  current_price : Float
  market_value : Float
  pnl : Float
  pnl_percent : Float
}

///|
/// Backtest request parameters
pub(all) struct BacktestRequest {
  stock_code : String
  strategy : String
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
}

///|
/// List available stocks
///
/// Returns array of stock codes available in the data directory
pub fn list_stocks() -> Array[String] {
  // Placeholder - would scan data directory for CSV files
  // For now, return hardcoded list based on known data files
  [
    "sh.600000", "sh.600004", "sh.600006", "sh.600007",
    "sh.600008", "sh.600009", "sh.600010", "sh.600011",
    "sh.600012", "sh.600015", "sh.600016", "sh.600017",
    "sh.600018", "sh.600019", "sh.600020", "sh.600021",
    "sh.600022", "sh.600023", "sh.600025", "sh.600026",
  ]
}

///|
/// Get stock info
///
/// Parameters:
/// - code: Stock code (e.g., "sh.600000")
///
/// Returns:
/// - Some(StockInfo) if stock exists
/// - None if stock not found
pub fn get_stock_info(code : String) -> StockInfo? {
  let parts = code.split(".")
  let arr = parts.to_array()
  if arr.length() >= 2 {
    Some(StockInfo::{
      code: code,
      name: "股票" + code,
      exchange: arr[0].to_string(),
      market: "A 股",
    })
  } else {
    None
  }
}

///|
/// Get K-line data for a stock
///
/// Parameters:
/// - code: Stock code
/// - start: Start date (YYYY-MM-DD)
/// - end: End date (YYYY-MM-DD)
///
/// Returns:
/// - Ok(KLineData) on success
/// - Err(String) on failure
pub fn get_klines(
  code : String,
  start : String,
  end : String,
) -> Result[KLineData, String] {
  // Placeholder - would load actual CSV data
  // This is a mock implementation
  let mock_klines : Array[@data.KLine] = []

  // In real implementation:
  // 1. Find CSV file for stock
  // 2. Parse CSV content
  // 3. Filter by date range
  // 4. Return KLineData

  ignore(start)
  ignore(end)

  Ok(KLineData::{
    stock_code: code,
    klines: mock_klines,
  })
}

///|
/// Calculate drawdown for a stock
///
/// Parameters:
/// - code: Stock code
/// - start: Start date
/// - end: End date
///
/// Returns:
/// - Ok(DrawdownResult) on success
/// - Err(String) on failure
pub fn calculate_drawdown(
  code : String,
  start : String,
  end : String,
) -> Result[DrawdownResult, String] {
  // Get K-line data first
  let kline_result = get_klines(code, start, end)

  match kline_result {
    Ok(kline_data) => {
      if kline_data.klines.length() == 0 {
        return Err("No data available for stock \{code}")
      }

      // Extract close prices
      let closes : Array[Float] = []
      let dates : Array[String] = []
      for kline in kline_data.klines {
        closes.push(kline.close)
        dates.push(kline.date)
      }

      // Calculate drawdown series
      let drawdown_series = calculate_drawdown_series(closes, dates)

      // Find max drawdown
      let max_dd_info = find_max_drawdown(drawdown_series)

      Ok(DrawdownResult::{
        stock_code: code,
        start_date: start,
        end_date: end,
        max_drawdown: max_dd_info.max_drawdown,
        peak: max_dd_info.peak,
        trough: max_dd_info.trough,
        peak_date: max_dd_info.peak_date,
        trough_date: max_dd_info.trough_date,
        duration: max_dd_info.duration,
        drawdown_series: drawdown_series,
      })
    }
    Err(e) => Err(e)
  }
}

///|
/// Calculate drawdown series from prices
fn calculate_drawdown_series(
  prices : Array[Float],
  dates : Array[String],
) -> Array[DrawdownPoint] {
  if prices.length() == 0 {
    return []
  }

  let result : Array[DrawdownPoint] = []
  let mut peak = prices[0]

  let mut i = 0
  while i < prices.length() {
    let price = prices[i]
    let date = dates[i]

    if price > peak {
      peak = price
    }

    let drawdown = (peak - price) / peak

    result.push(DrawdownPoint::{
      date: date,
      value: price,
      drawdown: drawdown,
    })

    i = i + 1
  }

  result
}

///|
/// Find maximum drawdown info from series
struct MaxDrawdownInfo {
  max_drawdown : Float
  peak : Float
  trough : Float
  peak_date : String
  trough_date : String
  duration : Int
}

fn find_max_drawdown(series : Array[DrawdownPoint]) -> MaxDrawdownInfo {
  if series.length() == 0 {
    return MaxDrawdownInfo::{
      max_drawdown: 0.0,
      peak: 0.0,
      trough: 0.0,
      peak_date: "",
      trough_date: "",
      duration: 0,
    }
  }

  let mut max_dd : Float = 0.0
  let peak_val = series[0].value
  let peak_date = series[0].date
  let mut trough_val = series[0].value
  let mut trough_date = series[0].date
  let mut duration = 0

  let mut i = 0
  while i < series.length() {
    let point = series[i]
    if point.drawdown > max_dd {
      max_dd = point.drawdown
      trough_val = point.value
      trough_date = point.date
    }
    if point.value == peak_val {
      duration = duration + 1
    }
    i = i + 1
  }

  MaxDrawdownInfo::{
    max_drawdown: max_dd,
    peak: peak_val,
    trough: trough_val,
    peak_date: peak_date,
    trough_date: trough_date,
    duration: duration,
  }
}

///|
/// Run backtest - simplified placeholder
///
/// Parameters:
/// - request: Backtest request parameters
///
/// Returns:
/// - Ok(BacktestResult) on success
/// - Err(String) on failure
pub fn run_backtest_api(request : BacktestRequest) -> Result[@backtest.BacktestResult, String] {
  // Get K-line data
  let kline_result = get_klines(
    request.stock_code,
    request.start_date,
    request.end_date,
  )

  match kline_result {
    Ok(kline_data) => {
      if kline_data.klines.length() == 0 {
        return Err("No data available for stock \{request.stock_code}")
      }

      // For now, return a mock backtest result
      // Real implementation would:
      // 1. Create backtest config
      // 2. Create backtest engine
      // 3. Get strategy by name
      // 4. Run backtest with strategy
      // 5. Return results

      ignore(request)

      // Mock result
      let mock_equity : Array[@backtest.EquityPoint] = []
      let mock_trades : Array[@backtest.Trade] = []
      let mock_stats = @backtest.BacktestStats::{
        total_return: 0.0,
        annual_return: 0.0,
        max_drawdown: 0.0,
        sharpe_ratio: 0.0,
        sortino_ratio: 0.0,
        win_rate: 0.0,
        profit_factor: 0.0,
        total_trades: 0,
        winning_trades: 0,
        losing_trades: 0,
        avg_win: 0.0,
        avg_loss: 0.0,
        avg_trade_duration: 0.0,
      }

      let result = @backtest.BacktestResult::{
        initial_capital: request.initial_capital,
        final_capital: request.initial_capital,
        total_return: 0.0,
        max_drawdown: 0.0,
        sharpe_ratio: 0.0,
        total_trades: 0,
        equity_curve: mock_equity,
        trades: mock_trades,
        stats: mock_stats,
      }

      Ok(result)
    }
    Err(e) => Err("Failed to load data: " + e)
  }
}

///|
/// Get strategy info by name - returns strategy metadata
fn get_strategy_info(name : String) -> StrategyInfo? {
  match name {
    "ma_cross" => {
      Some(StrategyInfo::{
        name: "ma_cross",
        description: "均线交叉策略",
        params: ["short_period", "long_period"],
      })
    }
    "momentum" => {
      Some(StrategyInfo::{
        name: "momentum",
        description: "动量策略",
        params: ["lookback_period", "threshold"],
      })
    }
    _ => None
  }
}

///|
/// List available strategies
pub fn list_strategies() -> Array[StrategyInfo] {
  [
    StrategyInfo::{
      name: "ma_cross",
      description: "均线交叉策略",
      params: ["short_period", "long_period"],
    },
    StrategyInfo::{
      name: "momentum",
      description: "动量策略",
      params: ["lookback_period", "threshold"],
    },
  ]
}

///|
/// Strategy information
pub(all) struct StrategyInfo {
  name : String
  description : String
  params : Array[String]
} derive(Show)

///|
/// Save result to JSON file (placeholder)
pub fn save_result_to_json[T](result : T, path : String) -> Result[Unit, String] {
  // Placeholder - MoonBit doesn't have built-in file writing yet
  // This would be implemented via C FFI
  ignore(result)
  ignore(path)
  Err("File writing requires C FFI implementation")
}
