/// Financial metrics for stock analysis
///
/// Fundamental financial indicators:
/// - roe_avg: Average return on equity
/// - np_margin: Net profit margin
/// - gp_margin: Gross profit margin
/// - net_profit: Net profit
/// - eps_ttm: Earnings per share (trailing twelve months)
/// - mb_revenue: Main business revenue
/// - total_share: Total share capital
/// - liqa_share: Liquidatable share capital

///|
/// Financial metrics structure containing all fundamental indicators
pub struct FinancialMetrics {
  /// Average return on equity (%)
  roe_avg : Float
  /// Net profit margin (%)
  np_margin : Float
  /// Gross profit margin (%)
  gp_margin : Float
  /// Net profit (in CNY)
  net_profit : Float
  /// Earnings per share TTM (CNY)
  eps_ttm : Float
  /// Main business revenue (in CNY)
  mb_revenue : Float
  /// Total share capital (shares)
  total_share : Float
  /// Liquidatable share capital (shares)
  liqa_share : Float
} derive(Show, ToJson)

///|
/// Create financial metrics with default values (zero)
/// Used when data is unavailable or for initialization
pub fn empty_financial_metrics() -> FinancialMetrics {
  FinancialMetrics::{
    roe_avg: 0.0,
    np_margin: 0.0,
    gp_margin: 0.0,
    net_profit: 0.0,
    eps_ttm: 0.0,
    mb_revenue: 0.0,
    total_share: 0.0,
    liqa_share: 0.0,
  }
}

///|
/// Create financial metrics from raw values
///
/// Parameters:
/// - roe_avg: Average ROE (%)
/// - np_margin: Net profit margin (%)
/// - gp_margin: Gross profit margin (%)
/// - net_profit: Net profit (CNY)
/// - eps_ttm: EPS TTM (CNY)
/// - mb_revenue: Main business revenue (CNY)
/// - total_share: Total share capital
/// - liqa_share: Liquidatable share capital
///
/// Returns:
/// - FinancialMetrics structure
pub fn create_financial_metrics(
  roe_avg : Float,
  np_margin : Float,
  gp_margin : Float,
  net_profit : Float,
  eps_ttm : Float,
  mb_revenue : Float,
  total_share : Float,
  liqa_share : Float,
) -> FinancialMetrics {
  FinancialMetrics::{
    roe_avg,
    np_margin,
    gp_margin,
    net_profit,
    eps_ttm,
    mb_revenue,
    total_share,
    liqa_share,
  }
}

///|
/// Financial health rating based on multiple metrics
pub enum FinancialHealth {
  /// Excellent: Strong fundamentals across all metrics
  Excellent
  /// Good: Above average fundamentals
  Good
  /// Fair: Average fundamentals
  Fair
  /// Poor: Below average fundamentals
  Poor
  /// Critical: Weak fundamentals, high risk
  Critical
} derive(Show, ToJson, Eq)

///|
/// Evaluate financial health based on metrics
///
/// Rating criteria:
/// - Excellent: ROE > 20%, NP Margin > 15%, EPS growth positive
/// - Good: ROE > 15%, NP Margin > 10%
/// - Fair: ROE > 10%, NP Margin > 5%
/// - Poor: ROE > 5% or positive EPS
/// - Critical: ROE <= 5% or negative EPS
///
/// Parameters:
/// - metrics: FinancialMetrics to evaluate
///
/// Returns:
/// - FinancialHealth rating
pub fn evaluate_financial_health(metrics : FinancialMetrics) -> FinancialHealth {
  let roe = metrics.roe_avg
  let np_margin = metrics.np_margin
  let eps = metrics.eps_ttm

  // Excellent: ROE > 20%, NP Margin > 15%, positive EPS
  if roe > 20.0 && np_margin > 15.0 && eps > 0.0 {
    FinancialHealth::Excellent
    // Good: ROE > 15%, NP Margin > 10%
  } else if roe > 15.0 && np_margin > 10.0 {
    FinancialHealth::Good
    // Fair: ROE > 10%, NP Margin > 5%
  } else if roe > 10.0 && np_margin > 5.0 {
    FinancialHealth::Fair
    // Poor: ROE > 5% or positive EPS
  } else if roe > 5.0 || eps > 0.0 {
    FinancialHealth::Poor
    // Critical: ROE <= 5% and non-positive EPS
  } else {
    FinancialHealth::Critical
  }
}

///|
/// Check if a stock meets minimum quality criteria
///
/// Quality criteria:
/// - ROE > 10% (company generates good return on equity)
/// - Net profit margin > 5% (company is profitable)
/// - EPS TTM > 0 (positive earnings)
///
/// Parameters:
/// - metrics: FinancialMetrics to check
///
/// Returns:
/// - true if all quality criteria are met
pub fn is_quality_stock(metrics : FinancialMetrics) -> Bool {
  metrics.roe_avg > 10.0 && metrics.np_margin > 5.0 && metrics.eps_ttm > 0.0
}

///|
/// Check if a stock is undervalued based on basic criteria
///
/// Note: This is a simplified check. Full valuation analysis
/// would require P/E, P/B, PEG ratios and industry comparison.
///
/// Parameters:
/// - metrics: FinancialMetrics to evaluate
/// - roe_threshold: Minimum ROE for consideration (default 15%)
///
/// Returns:
/// - true if stock meets value criteria
pub fn is_value_stock(
  metrics : FinancialMetrics,
  roe_threshold : Float,
) -> Bool {
  metrics.roe_avg > roe_threshold && metrics.np_margin > 0.0
}

///|
/// Check if a stock has growth characteristics
///
/// Growth criteria:
/// - Positive EPS (profitable)
/// - Strong profit margins (> 10%)
///
/// Parameters:
/// - metrics: FinancialMetrics to evaluate
///
/// Returns:
/// - true if stock shows growth characteristics
pub fn is_growth_stock(metrics : FinancialMetrics) -> Bool {
  metrics.eps_ttm > 0.0 && metrics.np_margin > 10.0
}

///|
/// Compare two stocks by ROE
///
/// Parameters:
/// - a: First FinancialMetrics
/// - b: Second FinancialMetrics
///
/// Returns:
/// - true if a has higher ROE than b
pub fn compare_by_roe(a : FinancialMetrics, b : FinancialMetrics) -> Bool {
  a.roe_avg > b.roe_avg
}

///|
/// Compare two stocks by net profit margin
///
/// Parameters:
/// - a: First FinancialMetrics
/// - b: Second FinancialMetrics
///
/// Returns:
/// - true if a has higher net profit margin than b
pub fn compare_by_np_margin(a : FinancialMetrics, b : FinancialMetrics) -> Bool {
  a.np_margin > b.np_margin
}

///|
/// Compare two stocks by EPS
///
/// Parameters:
/// - a: First FinancialMetrics
/// - b: Second FinancialMetrics
///
/// Returns:
/// - true if a has higher EPS than b
pub fn compare_by_eps(a : FinancialMetrics, b : FinancialMetrics) -> Bool {
  a.eps_ttm > b.eps_ttm
}

///|
/// Financial metrics with stock code for portfolio tracking
pub struct StockFinancials {
  /// Stock code
  code : String
  /// Financial metrics
  metrics : FinancialMetrics
  /// Health rating
  health : FinancialHealth
} derive(Show, ToJson)

///|
/// Create StockFinancials from code and metrics
///
/// Parameters:
/// - code: Stock code
/// - metrics: FinancialMetrics
///
/// Returns:
/// - StockFinancials with evaluated health rating
pub fn create_stock_financials(
  code : String,
  metrics : FinancialMetrics,
) -> StockFinancials {
  StockFinancials::{ code, metrics, health: evaluate_financial_health(metrics) }
}

///|
/// Screen stocks by minimum financial criteria
///
/// Screening criteria:
/// - ROE >= min_roe
/// - Net profit margin >= min_np_margin
/// - EPS TTM >= min_eps
///
/// Parameters:
/// - stocks: Array of StockFinancials to screen
/// - min_roe: Minimum ROE (%)
/// - min_np_margin: Minimum net profit margin (%)
/// - min_eps: Minimum EPS TTM
///
/// Returns:
/// - Array of stocks meeting all criteria
pub fn screen_by_financials(
  stocks : Array[StockFinancials],
  min_roe : Float,
  min_np_margin : Float,
  min_eps : Float,
) -> Array[StockFinancials] {
  stocks.filter(fn(s) {
    s.metrics.roe_avg >= min_roe &&
    s.metrics.np_margin >= min_np_margin &&
    s.metrics.eps_ttm >= min_eps
  })
}

///|
/// Get stocks by health rating
///
/// Parameters:
/// - stocks: Array of StockFinancials
/// - target_health: Desired FinancialHealth rating
///
/// Returns:
/// - Array of stocks with matching health rating
pub fn filter_by_health(
  stocks : Array[StockFinancials],
  target_health : FinancialHealth,
) -> Array[StockFinancials] {
  stocks.filter(fn(s) { s.health == target_health })
}

///|
/// Sort stocks by ROE (descending)
///
/// Parameters:
/// - stocks: Array of StockFinancials
///
/// Returns:
/// - Sorted array (highest ROE first)
///
/// Note: This uses a simple bubble sort for MoonBit compatibility.
/// For large datasets, consider using a more efficient algorithm.

///|
/// Copy an array of StockFinancials (workaround for missing clone method)
fn copy_stock_financials_array(
  arr : Array[StockFinancials],
) -> Array[StockFinancials] {
  let result : Array[StockFinancials] = []
  let mut i = 0
  while i < arr.length() {
    result.push(arr[i])
    i = i + 1
  }
  result
}

///|
pub fn sort_by_roe_desc(
  stocks : Array[StockFinancials],
) -> Array[StockFinancials] {
  let result = copy_stock_financials_array(stocks)
  let len = result.length()
  let mut i = 0
  while i < len {
    let mut j = 0
    while j < len - i - 1 {
      if result[j].metrics.roe_avg < result[j + 1].metrics.roe_avg {
        let temp = result[j]
        result[j] = result[j + 1]
        result[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}

///|
/// Sort stocks by net profit margin (descending)
///
/// Parameters:
/// - stocks: Array of StockFinancials
///
/// Returns:
/// - Sorted array (highest margin first)
pub fn sort_by_np_margin_desc(
  stocks : Array[StockFinancials],
) -> Array[StockFinancials] {
  let result = copy_stock_financials_array(stocks)
  let len = result.length()
  let mut i = 0
  while i < len {
    let mut j = 0
    while j < len - i - 1 {
      if result[j].metrics.np_margin < result[j + 1].metrics.np_margin {
        let temp = result[j]
        result[j] = result[j + 1]
        result[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}

///|
/// Sort stocks by EPS (descending)
///
/// Parameters:
/// - stocks: Array of StockFinancials
///
/// Returns:
/// - Sorted array (highest EPS first)
pub fn sort_by_eps_desc(
  stocks : Array[StockFinancials],
) -> Array[StockFinancials] {
  let result = copy_stock_financials_array(stocks)
  let len = result.length()
  let mut i = 0
  while i < len {
    let mut j = 0
    while j < len - i - 1 {
      if result[j].metrics.eps_ttm < result[j + 1].metrics.eps_ttm {
        let temp = result[j]
        result[j] = result[j + 1]
        result[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}
