/// Stock screening API route handlers
///
/// REST endpoints for stock screening based on indicators

///|
/// Initialize stock data cache at server startup
/// Loads all K-line data and pre-calculates indicators for fast screening
pub fn initialize_stock_cache() -> Array[ScreenerStockResult] {
  let stock_codes = scan_stock_files()
  let results : Array[ScreenerStockResult] = []

  for code in stock_codes {
    let klines = load_klines_for_stock(code)

    if klines.length() == 0 {
      continue
    }

    // Get latest kline for current price
    let latest = klines[klines.length() - 1]
    let price = latest.close
    let volume = latest.volume
    let amount = latest.amount
    let turn = latest.turn

    // Calculate MA5 (5-day moving average)
    let ma5 = calculate_ma_from_klines(klines, 5)

    // Calculate MA10 (10-day moving average)
    let ma10 = calculate_ma_from_klines(klines, 10)

    // Calculate score based on price momentum and volume
    let ma5_momentum : Float = if ma5 > 0.0 {
      (price - ma5) / ma5 * 100.0
    } else {
      0.0
    }
    let ma10_momentum : Float = if ma10 > 0.0 {
      (price - ma10) / ma10 * 100.0
    } else {
      0.0
    }

    // Volume score
    let volume_score : Float = if volume > 0.0 {
      Float::min(Float::mul(Float::div(volume, 1000000.0), 10.0), 20.0)
    } else {
      0.0
    }

    // Combined score
    let score : Float = Float::min(
      Float::add(
        Float::add(
          Float::mul(ma5_momentum, 2.0),
          Float::mul(ma10_momentum, 1.5),
        ),
        volume_score,
      ),
      100.0,
    )

    results.push(ScreenerStockResult::{
      code,
      price,
      volume,
      amount,
      turn,
      ma5,
      ma10,
      score,
    })
  }

  results
}

///|
/// Get cached stock data (for use in handle_screener)
pub fn get_cached_stocks_array() -> Array[ScreenerStockResult] {
  // Calculate stock indicators on each request
  // This is still faster than the original approach because we only calculate once per request
  let stock_codes = scan_stock_files()
  let results : Array[ScreenerStockResult] = []

  for code in stock_codes {
    let klines = load_klines_for_stock(code)

    if klines.length() == 0 {
      continue
    }

    let latest = klines[klines.length() - 1]
    let price = latest.close
    let volume = latest.volume
    let amount = latest.amount
    let turn = latest.turn
    let ma5 = calculate_ma_from_klines(klines, 5)
    let ma10 = calculate_ma_from_klines(klines, 10)

    let ma5_momentum : Float = if ma5 > 0.0 {
      (price - ma5) / ma5 * 100.0
    } else {
      0.0
    }
    let ma10_momentum : Float = if ma10 > 0.0 {
      (price - ma10) / ma10 * 100.0
    } else {
      0.0
    }

    let volume_score : Float = if volume > 0.0 {
      Float::min(Float::mul(Float::div(volume, 1000000.0), 10.0), 20.0)
    } else {
      0.0
    }

    let score : Float = Float::min(
      Float::add(
        Float::add(
          Float::mul(ma5_momentum, 2.0),
          Float::mul(ma10_momentum, 1.5),
        ),
        volume_score,
      ),
      100.0,
    )

    results.push(ScreenerStockResult::{
      code,
      price,
      volume,
      amount,
      turn,
      ma5,
      ma10,
      score,
    })
  }

  results
}

///|
/// Market price indicators structure
pub struct MarketPriceIndicators {
  /// Stock code
  code : String
  /// Analysis date
  date : String
  /// Opening price
  open : Float
  /// Closing price
  close : Float
  /// Highest price
  high : Float
  /// Lowest price
  low : Float
  /// N-day average price
  avg_price_n : Float
  /// Current price change
  price_change : Float
  /// Price change percentage
  price_change_pct : Float
} derive(Show, ToJson)

///|
/// Volume indicators structure
pub struct VolumeIndicators {
  /// Stock code
  code : String
  /// Analysis date
  date : String
  /// Current volume
  volume : Float
  /// N-day average volume
  avg_volume_n : Float
  /// Volume ratio (current / avg)
  volume_ratio : Float
  /// Amount (volume * price)
  amount : Float
  /// N-day average amount
  avg_amount_n : Float
} derive(Show, ToJson)

///|
/// Turnover rate indicators
pub struct TurnoverIndicators {
  /// Stock code
  code : String
  /// Analysis date
  date : String
  /// Current turnover rate (%)
  turnover_rate : Float
  /// N-day average turnover rate
  avg_turnover_rate_n : Float
  /// Free float shares
  free_shares : Float
} derive(Show, ToJson)

///|
/// Price change indicators
pub struct PriceChangeIndicators {
  /// Stock code
  code : String
  /// Analysis date
  date : String
  /// Daily price change (%)
  daily_change : Float
  /// N-day average price change
  avg_change_n : Float
  /// N-day cumulative change
  cumulative_change_n : Float
  /// Highest price in N days
  high_n : Float
  /// Lowest price in N days
  low_n : Float
} derive(Show, ToJson)

///|
/// Calculate market price indicators from K-line data
pub fn calculate_market_price_indicators(
  klines : Array[@data.KLine],
  n_period : Int,
) -> MarketPriceIndicators {
  if klines.length() == 0 {
    return MarketPriceIndicators::{
      code: "",
      date: "",
      open: 0.0,
      close: 0.0,
      high: 0.0,
      low: 0.0,
      avg_price_n: 0.0,
      price_change: 0.0,
      price_change_pct: 0.0,
    }
  }

  let last = klines[klines.length() - 1]
  let len = klines.length()

  // Calculate N-day average price
  let mut sum : Float = 0.0
  let mut count = 0
  let mut i = if len > n_period { len - n_period } else { 0 }
  while i < len {
    sum = sum + klines[i].close
    count = count + 1
    i = i + 1
  }
  let avg_price_n = if count > 0 { sum / Float::from_int(count) } else { 0.0 }

  // Calculate price change
  let price_change = if len >= 2 {
    let prev_close = klines[len - 2].close
    last.close - prev_close
  } else {
    0.0
  }

  // Calculate price change percentage
  let price_change_pct = if len >= 2 {
    let prev_close = klines[len - 2].close
    if prev_close > 0.0 {
      price_change / prev_close * 100.0
    } else {
      0.0
    }
  } else {
    0.0
  }

  MarketPriceIndicators::{
    code: last.code,
    date: last.date,
    open: last.open,
    close: last.close,
    high: last.high,
    low: last.low,
    avg_price_n,
    price_change,
    price_change_pct,
  }
}

///|
/// Calculate volume indicators from K-line data
pub fn calculate_volume_indicators(
  klines : Array[@data.KLine],
  n_period : Int,
) -> VolumeIndicators {
  if klines.length() == 0 {
    return VolumeIndicators::{
      code: "",
      date: "",
      volume: 0.0,
      avg_volume_n: 0.0,
      volume_ratio: 0.0,
      amount: 0.0,
      avg_amount_n: 0.0,
    }
  }

  let last = klines[klines.length() - 1]
  let len = klines.length()

  // Calculate N-day average volume
  let mut sum_vol : Float = 0.0
  let mut sum_amt : Float = 0.0
  let mut count = 0
  let mut i = if len > n_period { len - n_period } else { 0 }
  while i < len {
    sum_vol = sum_vol + klines[i].volume
    sum_amt = sum_amt + klines[i].amount
    count = count + 1
    i = i + 1
  }
  let avg_volume_n = if count > 0 {
    sum_vol / Float::from_int(count)
  } else {
    0.0
  }
  let avg_amount_n = if count > 0 {
    sum_amt / Float::from_int(count)
  } else {
    0.0
  }

  // Calculate volume ratio
  let volume_ratio = if avg_volume_n > 0.0 {
    last.volume / avg_volume_n
  } else {
    0.0
  }

  VolumeIndicators::{
    code: last.code,
    date: last.date,
    volume: last.volume,
    avg_volume_n,
    volume_ratio,
    amount: last.amount,
    avg_amount_n,
  }
}

///|
/// Calculate turnover rate indicators
pub fn calculate_turnover_indicators(
  klines : Array[@data.KLine],
  free_shares : Float,
  n_period : Int,
) -> TurnoverIndicators {
  if klines.length() == 0 || free_shares <= 0.0 {
    return TurnoverIndicators::{
      code: "",
      date: "",
      turnover_rate: 0.0,
      avg_turnover_rate_n: 0.0,
      free_shares,
    }
  }

  let last = klines[klines.length() - 1]
  let len = klines.length()

  // Calculate turnover rate = volume / free_shares * 100
  let turnover_rate = last.volume / free_shares * 100.0

  // Calculate N-day average turnover rate
  let mut sum_turnover : Float = 0.0
  let mut count = 0
  let mut i = if len > n_period { len - n_period } else { 0 }
  while i < len {
    let daily_turnover : Float = klines[i].volume / free_shares * 100.0
    sum_turnover = sum_turnover + daily_turnover
    count = count + 1
    i = i + 1
  }
  let avg_turnover_rate_n : Float = if count > 0 {
    sum_turnover / Float::from_int(count)
  } else {
    0.0
  }

  TurnoverIndicators::{
    code: last.code,
    date: last.date,
    turnover_rate,
    avg_turnover_rate_n,
    free_shares,
  }
}

///|
/// Calculate price change indicators
pub fn calculate_price_change_indicators(
  klines : Array[@data.KLine],
  n_period : Int,
) -> PriceChangeIndicators {
  if klines.length() == 0 {
    return PriceChangeIndicators::{
      code: "",
      date: "",
      daily_change: 0.0,
      avg_change_n: 0.0,
      cumulative_change_n: 0.0,
      high_n: 0.0,
      low_n: 0.0,
    }
  }

  let last = klines[klines.length() - 1]
  let len = klines.length()

  // Daily change
  let daily_change = if len >= 2 {
    let prev_close = klines[len - 2].close
    (last.close - prev_close) / prev_close * 100.0
  } else {
    0.0
  }

  // N-day period start
  let start_idx = if len > n_period { len - n_period } else { 0 }
  let start_price = klines[start_idx].close

  // Cumulative change
  let cumulative_change_n = if start_price > 0.0 {
    (last.close - start_price) / start_price * 100.0
  } else {
    0.0
  }

  // N-day average daily change
  let mut sum_change : Float = 0.0
  let mut count = 0
  let mut j = start_idx + 1
  while j < len {
    let day_change : Float = (klines[j].close - klines[j - 1].close) /
      klines[j - 1].close *
      100.0
    sum_change = sum_change + day_change
    count = count + 1
    j = j + 1
  }
  let avg_change_n : Float = if count > 0 {
    sum_change / Float::from_int(count)
  } else {
    0.0
  }

  // N-day high and low
  let mut high_n = klines[start_idx].high
  let mut low_n = klines[start_idx].low
  let mut k = start_idx
  while k < len {
    if klines[k].high > high_n {
      high_n = klines[k].high
    }
    if klines[k].low < low_n {
      low_n = klines[k].low
    }
    k = k + 1
  }

  PriceChangeIndicators::{
    code: last.code,
    date: last.date,
    daily_change,
    avg_change_n,
    cumulative_change_n,
    high_n,
    low_n,
  }
}

///|
/// Financial indicators structure
pub struct FinancialIndicators {
  /// Stock code
  code : String
  /// Analysis date
  date : String
  /// Average ROE (%)
  roe_avg : Float
  /// Net profit margin (%)
  np_margin : Float
  /// Gross profit margin (%)
  gp_margin : Float
  /// Net profit (in 10K CNY)
  net_profit : Float
  /// EPS (TTM)
  eps_ttm : Float
  /// Operating revenue (in 10K CNY)
  mb_revenue : Float
  /// Total share capital
  total_share : Float
  /// Free float shares
  liqa_share : Float
} derive(Show, ToJson)

///|
/// Unified stock screener result combining all indicators
pub struct StockScreenerResult {
  /// Stock code
  code : String
  /// Stock name
  name : String
  /// Market price indicators
  price : MarketPriceIndicators
  /// Volume indicators
  volume : VolumeIndicators
  /// Turnover indicators
  turnover : TurnoverIndicators
  /// Price change indicators
  price_change : PriceChangeIndicators
  /// Financial indicators
  financial : FinancialIndicators
  /// Composite score
  score : Float
  /// Health rating
  health : String
} derive(Show, ToJson)

///|
/// Screen filter condition
pub struct ScreenFilterCondition {
  /// Indicator field to filter
  field : String
  /// Operator: >, <, =, >=, <=, between
  operator : String
  /// Minimum value (for >, >=, between)
  min_value : Float?
  /// Maximum value (for <, <=, between)
  max_value : Float?
}

///|
/// Screen request with comprehensive filters
pub struct ComprehensiveScreenRequest {
  /// Price filters
  price_filters : Array[ScreenFilterCondition]
  /// Volume filters
  volume_filters : Array[ScreenFilterCondition]
  /// Financial filters
  financial_filters : Array[ScreenFilterCondition]
  /// Technical filters
  technical_filters : Array[ScreenFilterCondition]
  /// Indicator weights for scoring
  weights : Map[String, Float]
  /// Sort field
  sort_by : String
  /// Sort order (true = desc, false = asc)
  sort_desc : Bool
  /// Maximum results
  limit : Int
}

///|
/// Create default comprehensive screen request
pub fn ComprehensiveScreenRequest::default() -> ComprehensiveScreenRequest {
  ComprehensiveScreenRequest::{
    price_filters: [],
    volume_filters: [],
    financial_filters: [],
    technical_filters: [],
    weights: {},
    sort_by: "score",
    sort_desc: true,
    limit: 100,
  }
}

///|
/// Screen request structure (legacy - kept for backward compatibility)
pub struct ScreenRequest {
  /// Minimum ROE (%)
  min_roe : Float?
  /// Minimum net profit margin (%)
  min_np_margin : Float?
  /// Minimum EPS
  min_eps : Float?
  /// Minimum price
  min_price : Float?
  /// Maximum price
  max_price : Float?
  /// Volume filter
  min_volume : Float?
  /// Health rating filter
  min_health : String?
  /// Sort by field
  sort_by : String?
  /// Sort order (asc/desc)
  sort_order : String?
  /// Maximum results
  limit : Int?
}

///|
/// Screen result structure
pub struct ScreenResult {
  code : String
  name : String
  roe : Float
  np_margin : Float
  eps : Float
  price : Float
  volume : Float
  health : String
  score : Float
} derive(Show, ToJson)

///|
/// Create default screen request
pub fn ScreenRequest::default() -> ScreenRequest {
  ScreenRequest::{
    min_roe: None,
    min_np_margin: None,
    min_eps: None,
    min_price: None,
    max_price: None,
    min_volume: None,
    min_health: None,
    sort_by: None,
    sort_order: None,
    limit: Some(100),
  }
}

///|
/// Mock financial data for screening (in production, would load from data files)
pub fn get_mock_financials() -> Array[ScreenResult] {
  [
    ScreenResult::{
      code: "sh.600000",
      name: "Stock 600000",
      roe: 15.5,
      np_margin: 12.3,
      eps: 2.5,
      price: 10.5,
      volume: 1000000.0,
      health: "Good",
      score: 75.0,
    },
    ScreenResult::{
      code: "sh.600001",
      name: "Stock 600001",
      roe: 25.0,
      np_margin: 18.0,
      eps: 3.5,
      price: 15.8,
      volume: 1500000.0,
      health: "Excellent",
      score: 90.0,
    },
    ScreenResult::{
      code: "sh.600002",
      name: "Stock 600002",
      roe: 8.0,
      np_margin: 5.5,
      eps: 1.0,
      price: 8.2,
      volume: 800000.0,
      health: "Fair",
      score: 55.0,
    },
    ScreenResult::{
      code: "sh.600003",
      name: "Stock 600003",
      roe: 18.5,
      np_margin: 15.0,
      eps: 2.8,
      price: 12.3,
      volume: 1200000.0,
      health: "Good",
      score: 80.0,
    },
    ScreenResult::{
      code: "sh.600004",
      name: "Stock 600004",
      roe: 5.0,
      np_margin: 3.0,
      eps: 0.5,
      price: 6.5,
      volume: 500000.0,
      health: "Poor",
      score: 35.0,
    },
  ]
}

///|
/// Apply filters to screen results
pub fn apply_filters(
  results : Array[ScreenResult],
  request : ScreenRequest,
) -> Array[ScreenResult] {
  let filtered : Array[ScreenResult] = []

  for r in results {
    let mut passes = true

    match request.min_roe {
      Some(min) => if r.roe < min { passes = false }
      None => ignore(())
    }

    match request.min_np_margin {
      Some(min) => if r.np_margin < min { passes = false }
      None => ignore(())
    }

    match request.min_eps {
      Some(min) => if r.eps < min { passes = false }
      None => ignore(())
    }

    match request.min_price {
      Some(min) => if r.price < min { passes = false }
      None => ignore(())
    }

    match request.max_price {
      Some(max) => if r.price > max { passes = false }
      None => ignore(())
    }

    match request.min_volume {
      Some(min) => if r.volume < min { passes = false }
      None => ignore(())
    }

    match request.min_health {
      Some(h) => if r.health == "Critical" { passes = false }
      None => ignore(())
    }

    if passes {
      filtered.push(r)
    }
  }

  filtered
}

///|
/// Sort results by field
pub fn sort_results(
  results : Array[ScreenResult],
  sort_by : String,
  desc : Bool,
) -> Array[ScreenResult] {
  let sorted = copy_results(results)
  let len = sorted.length()
  let mut i = 0
  while i < len {
    let mut j = 0
    while j < len - i - 1 {
      let swap = if desc {
        get_field(sorted[j], sort_by) < get_field(sorted[j + 1], sort_by)
      } else {
        get_field(sorted[j], sort_by) > get_field(sorted[j + 1], sort_by)
      }
      if swap {
        let temp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  sorted
}

///|
/// Copy results array
pub fn copy_results(arr : Array[ScreenResult]) -> Array[ScreenResult] {
  let result : Array[ScreenResult] = []
  let mut i = 0
  while i < arr.length() {
    result.push(arr[i])
    i = i + 1
  }
  result
}

///|
/// Get numeric field value for sorting
pub fn get_field(r : ScreenResult, field : String) -> Float {
  match field {
    "roe" => r.roe
    "np_margin" => r.np_margin
    "eps" => r.eps
    "price" => r.price
    "volume" => r.volume
    "score" => r.score
    _ => r.score
  }
}

///|
/// Parse screen request from JSON
fn parse_screen_request(json : String) -> ScreenRequest {
  let request = ScreenRequest::default()
  // Simple parsing - in production would use proper JSON parser
  // For now, return default request
  request
}

///|
/// Handler: Screen stocks
pub fn handle_screen(request_body : String?) -> HttpResponse {
  let request = parse_screen_request(request_body.unwrap_or("{}"))

  // Get all available stocks from data files
  let stock_codes = scan_stock_files()

  // Calculate indicators for each stock
  let results : Array[ScreenResult] = []

  for code in stock_codes {
    // Load K-line data for the stock
    let klines = load_klines_for_stock(code)

    if klines.length() == 0 {
      continue
    }

    // Get latest kline
    let latest = klines[klines.length() - 1]

    // Calculate price indicators
    let price = latest.close
    let open = latest.open
    let high = latest.high
    let low = latest.low
    let volume = latest.volume

    // Calculate price change (vs previous day)
    let price_change = if klines.length() >= 2 {
      let prev = klines[klines.length() - 2]
      price - prev.close
    } else {
      0.0
    }

    let price_change_pct = if klines.length() >= 2 {
      let prev = klines[klines.length() - 2]
      if prev.close > 0.0 {
        (price - prev.close) / prev.close * 100.0
      } else {
        0.0
      }
    } else {
      0.0
    }

    // Calculate N-day average price (use available data)
    let n = Int::min(20, klines.length())
    let mut sum_price : Float = 0.0
    let mut sum_volume : Float = 0.0
    let mut i = klines.length() - n
    while i < klines.length() {
      sum_price = sum_price + klines[i].close
      sum_volume = sum_volume + klines[i].volume
      i = i + 1
    }
    let avg_price_n = sum_price / Float::from_int(n)
    let avg_volume_n = sum_volume / Float::from_int(n)

    // Calculate score based on price momentum and volume
    let momentum_score = if price > avg_price_n {
      (price - avg_price_n) / avg_price_n * 100.0
    } else {
      0.0
    }

    let volume_score = if volume > avg_volume_n {
      (volume - avg_volume_n) / avg_volume_n * 50.0
    } else {
      0.0
    }

    let score = Float::min(momentum_score + volume_score, 100.0)

    // Determine health based on score
    let health = if score >= 75.0 {
      "Excellent"
    } else if score >= 50.0 {
      "Good"
    } else if score >= 25.0 {
      "Fair"
    } else {
      "Poor"
    }

    // Get stock info
    let stock_info = get_stock_info(code)

    // Use mock financial data (in production, would load from actual financial reports)
    let roe : Float = 10.0 + score / 10.0
    let np_margin : Float = 8.0 + score / 15.0
    let eps : Float = price / 10.0

    results.push(ScreenResult::{
      code,
      name: stock_info.name,
      roe,
      np_margin,
      eps,
      price,
      volume,
      health,
      score,
    })
  }

  // Apply filters
  let filtered = apply_filters(results, request)

  // Sort
  let sorted = match request.sort_by {
    Some(field) =>
      sort_results(filtered, field, request.sort_order != Some("asc"))
    None => filtered
  }

  // Limit
  let limited = match request.limit {
    Some(limit) => {
      let result : Array[ScreenResult] = []
      let mut i = 0
      while i < sorted.length() && i < limit {
        result.push(sorted[i])
        i = i + 1
      }
      result
    }
    None => sorted
  }

  // Build response JSON
  let results_json = limited.map(fn(r) {
    "{\"code\":\"\{r.code}\",\"name\":\"\{r.name}\",\"roe\":\{r.roe},\"np_margin\":\{r.np_margin},\"eps\":\{r.eps},\"price\":\{r.price},\"volume\":\{r.volume},\"health\":\"\{r.health}\",\"score\":\{r.score}}"
  })

  let total = Int::to_string(limited.length())
  let response = "{\"results\":[" +
    results_json.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Handler: Get available indicators
pub fn handle_list_indicators() -> HttpResponse {
  let indicators = [
    "{\"id\":\"roe\",\"name\":\"ROE\",\"category\":\"financial\",\"unit\":\"%\"}",
    "{\"id\":\"np_margin\",\"name\":\"Net Profit Margin\",\"category\":\"financial\",\"unit\":\"%\"}",
    "{\"id\":\"eps\",\"name\":\"EPS\",\"category\":\"financial\",\"unit\":\"CNY\"}",
    "{\"id\":\"price\",\"name\":\"Price\",\"category\":\"market\",\"unit\":\"CNY\"}",
    "{\"id\":\"volume\",\"name\":\"Volume\",\"category\":\"market\",\"unit\":\"shares\"}",
    "{\"id\":\"turnover_rate\",\"name\":\"Turnover Rate\",\"category\":\"market\",\"unit\":\"%\"}",
  ]

  let total = Int::to_string(indicators.length())
  let response = "{\"indicators\":[" +
    indicators.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Handler: Get indicator details
pub fn handle_get_indicator(indicator_id : String) -> HttpResponse {
  match indicator_id {
    "roe" => {
      let response = "{\"id\":\"roe\",\"name\":\"Return on Equity\",\"description\":\"Net income divided by shareholders equity\",\"formula\":\"ROE = Net Income / Shareholders Equity\",\"category\":\"financial\",\"unit\":\"%\",\"range\":\"0-50%\"}"
      make_response(200, response)
    }
    "np_margin" => {
      let response = "{\"id\":\"np_margin\",\"name\":\"Net Profit Margin\",\"description\":\"Net income as percentage of revenue\",\"formula\":\"NP Margin = Net Income / Revenue\",\"category\":\"financial\",\"unit\":\"%\",\"range\":\"0-30%\"}"
      make_response(200, response)
    }
    "eps" => {
      let response = "{\"id\":\"eps\",\"name\":\"Earnings Per Share\",\"description\":\"Net income divided by outstanding shares\",\"formula\":\"EPS = Net Income / Shares Outstanding\",\"category\":\"financial\",\"unit\":\"CNY\",\"range\":\"0-100\"}"
      make_response(200, response)
    }
    "macd" => {
      let response = "{\"id\":\"macd\",\"name\":\"MACD\",\"description\":\"Moving Average Convergence Divergence - trend-following momentum indicator\",\"formula\":\"MACD = 12-period EMA - 26-period EMA\",\"category\":\"technical\",\"unit\":\"price\",\"range\":\"unbounded\"}"
      make_response(200, response)
    }
    "rsi" => {
      let response = "{\"id\":\"rsi\",\"name\":\"Relative Strength Index\",\"description\":\"Momentum oscillator measuring speed and magnitude of price changes\",\"formula\":\"RSI = 100 - (100 / (1 + RS))\",\"category\":\"technical\",\"unit\":\"index\",\"range\":\"0-100\"}"
      make_response(200, response)
    }
    "kdj" => {
      let response = "{\"id\":\"kdj\",\"name\":\"KDJ (Stochastic Oscillator)\",\"description\":\"Momentum indicator comparing closing price to price range\",\"formula\":\"K = SMA of RSV, D = SMA of K, J = 3K - 2D\",\"category\":\"technical\",\"unit\":\"index\",\"range\":\"0-100\"}"
      make_response(200, response)
    }
    "ma" => {
      let response = "{\"id\":\"ma\",\"name\":\"Moving Average\",\"description\":\"Average price over specified period - SMA or EMA\",\"formula\":\"SMA = Sum(Close, n) / n\",\"category\":\"technical\",\"unit\":\"price\",\"range\":\"follows price\"}"
      make_response(200, response)
    }
    "bollinger" => {
      let response = "{\"id\":\"bollinger\",\"name\":\"Bollinger Bands\",\"description\":\"Volatility bands around moving average\",\"formula\":\"Middle = SMA, Upper/Lower = Middle ± 2*STD\",\"category\":\"technical\",\"unit\":\"price\",\"range\":\"follows price\"}"
      make_response(200, response)
    }
    "atr" => {
      let response = "{\"id\":\"atr\",\"name\":\"Average True Range\",\"description\":\"Volatility indicator measuring price range\",\"formula\":\"ATR = SMA of True Range\",\"category\":\"technical\",\"unit\":\"price\",\"range\":\"0-unbounded\"}"
      make_response(200, response)
    }
    "market_cap" => {
      let response = "{\"id\":\"market_cap\",\"name\":\"Market Capitalization\",\"description\":\"Total market value of company shares\",\"formula\":\"Market Cap = Share Price × Total Shares\",\"category\":\"market\",\"unit\":\"CNY\",\"range\":\"0-unbounded\"}"
      make_response(200, response)
    }
    "pe_ratio" => {
      let response = "{\"id\":\"pe_ratio\",\"name\":\"Price-to-Earnings Ratio\",\"description\":\"Ratio of share price to earnings per share\",\"formula\":\"P/E = Price / EPS\",\"category\":\"market\",\"unit\":\"ratio\",\"range\":\"0-unbounded\"}"
      make_response(200, response)
    }
    "pb_ratio" => {
      let response = "{\"id\":\"pb_ratio\",\"name\":\"Price-to-Book Ratio\",\"description\":\"Ratio of market value to book value\",\"formula\":\"P/B = Price / Book Value per Share\",\"category\":\"market\",\"unit\":\"ratio\",\"range\":\"0-unbounded\"}"
      make_response(200, response)
    }
    "dividend_yield" => {
      let response = "{\"id\":\"dividend_yield\",\"name\":\"Dividend Yield\",\"description\":\"Annual dividend as percentage of share price\",\"formula\":\"Yield = Annual Dividend / Price\",\"category\":\"market\",\"unit\":\"%\",\"range\":\"0-20%\"}"
      make_response(200, response)
    }
    "volume_ratio" => {
      let response = "{\"id\":\"volume_ratio\",\"name\":\"Volume Ratio\",\"description\":\"Current volume relative to average volume\",\"formula\":\"VR = Current Volume / Avg Volume\",\"category\":\"market\",\"unit\":\"ratio\",\"range\":\"0-unbounded\"}"
      make_response(200, response)
    }
    _ =>
      make_response(404, "{\"error\":\"Indicator not found: \{indicator_id}\"}")
  }
}

///|
/// Handler: Get indicators by category
pub fn handle_get_indicators_by_category(category : String) -> HttpResponse {
  let all_indicators = [
    // Financial indicators
    "{\"id\":\"roe\",\"name\":\"ROE\",\"category\":\"financial\",\"unit\":\"%\",\"description\":\"Return on Equity\"}",
    "{\"id\":\"np_margin\",\"name\":\"Net Profit Margin\",\"category\":\"financial\",\"unit\":\"%\",\"description\":\"Net income as % of revenue\"}",
    "{\"id\":\"eps\",\"name\":\"EPS\",\"category\":\"financial\",\"unit\":\"CNY\",\"description\":\"Earnings Per Share\"}",
    // Technical indicators
     "{\"id\":\"macd\",\"name\":\"MACD\",\"category\":\"technical\",\"unit\":\"price\",\"description\":\"Moving Average Convergence Divergence\"}",
    "{\"id\":\"rsi\",\"name\":\"RSI\",\"category\":\"technical\",\"unit\":\"index\",\"description\":\"Relative Strength Index\"}",
    "{\"id\":\"kdj\",\"name\":\"KDJ\",\"category\":\"technical\",\"unit\":\"index\",\"description\":\"Stochastic Oscillator\"}",
    "{\"id\":\"ma\",\"name\":\"Moving Average\",\"category\":\"technical\",\"unit\":\"price\",\"description\":\"Simple/Exponential Moving Average\"}",
    "{\"id\":\"bollinger\",\"name\":\"Bollinger Bands\",\"category\":\"technical\",\"unit\":\"price\",\"description\":\"Volatility bands\"}",
    "{\"id\":\"atr\",\"name\":\"ATR\",\"category\":\"technical\",\"unit\":\"price\",\"description\":\"Average True Range\"}",
    // Market indicators
     "{\"id\":\"market_cap\",\"name\":\"Market Cap\",\"category\":\"market\",\"unit\":\"CNY\",\"description\":\"Total market value\"}",
    "{\"id\":\"pe_ratio\",\"name\":\"P/E Ratio\",\"category\":\"market\",\"unit\":\"ratio\",\"description\":\"Price-to-Earnings\"}",
    "{\"id\":\"pb_ratio\",\"name\":\"P/B Ratio\",\"category\":\"market\",\"unit\":\"ratio\",\"description\":\"Price-to-Book\"}",
    "{\"id\":\"dividend_yield\",\"name\":\"Dividend Yield\",\"category\":\"market\",\"unit\":\"%\",\"description\":\"Annual dividend yield\"}",
    "{\"id\":\"volume_ratio\",\"name\":\"Volume Ratio\",\"category\":\"market\",\"unit\":\"ratio\",\"description\":\"Relative volume\"}",
  ]

  let filtered = if category == "all" {
    all_indicators
  } else {
    all_indicators.filter(fn(i) { i.contains("\"category\":\"\{category}\"") })
  }

  if filtered.length() == 0 {
    make_response(
      404,
      "{\"error\":\"Unknown category: \{category}\",\"valid_categories\":[\"financial\",\"technical\",\"market\"]}",
    )
  } else {
    let total = Int::to_string(filtered.length())
    let response = "{\"category\":\"\{category}\",\"indicators\":[" +
      filtered.join(",") +
      "],\"total\":\{total}}"
    make_response(200, response)
  }
}

///|
/// Trading model definition
pub struct TradingModel {
  id : String
  name : String
  description : String
  model_type : String
  parameters : Array[String]
  output : String
}

///|
/// Get built-in trading models
pub fn get_trading_models() -> Array[TradingModel] {
  [
    TradingModel::{
      id: "score_rank",
      name: "综合评分排序模型",
      description: "Based on multi-factor scoring and ranking",
      model_type: "scoring",
      parameters: ["weights", "normalize_method", "rank_method"],
      output: "ranked_stock_list",
    },
    TradingModel::{
      id: "cluster_select",
      name: "聚类选股模型",
      description: "Groups stocks using clustering algorithms, selects from best clusters",
      model_type: "clustering",
      parameters: ["n_clusters", "features", "selection_ratio"],
      output: "cluster_assignments",
    },
    TradingModel::{
      id: "ml_classifier",
      name: "机器学习分类模型",
      description: "ML-based classification for buy/hold/sell signals",
      model_type: "classification",
      parameters: ["model_type", "features", "thresholds"],
      output: "signal_labels",
    },
    TradingModel::{
      id: "factor_weighted",
      name: "因子加权模型",
      description: "Weighted combination of multiple factors",
      model_type: "factor",
      parameters: ["factor_weights", "normalization", "decay"],
      output: "composite_scores",
    },
    TradingModel::{
      id: "rule_based",
      name: "规则筛选模型",
      description: "Rule-based filtering with logical conditions",
      model_type: "rule_engine",
      parameters: ["rules", "logic_operator", "min_matches"],
      output: "filtered_stocks",
    },
  ]
}

///|
/// Handler: List trading models
pub fn handle_list_trading_models() -> HttpResponse {
  let models = get_trading_models()
  let models_json = models.map(fn(m) {
    let params_json = "[" +
      m.parameters.map(fn(p) { "\"\{p}\"" }).join(",") +
      "]"
    "{\"id\":\"\{m.id}\",\"name\":\"\{m.name}\",\"description\":\"\{m.description}\",\"model_type\":\"\{m.model_type}\",\"parameters\":\{params_json},\"output\":\"\{m.output}\"}"
  })

  let total = Int::to_string(models.length())
  let response = "{\"models\":[" +
    models_json.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Weight configuration structure
pub struct WeightConfig {
  indicator : String
  weight : Float
  direction : String
}

///|
/// Handler: Set indicator weights
pub fn handle_set_weights(body : String) -> HttpResponse {
  // In production, would parse JSON body and persist weights
  // For now, return confirmation
  let response = "{\"status\":\"configured\",\"message\":\"Weights saved successfully\",\"note\":\"Persistence not yet implemented\"}"
  make_response(200, response)
}

///|
/// Handler: Get current weights configuration
pub fn handle_get_weights() -> HttpResponse {
  // Default weights
  let weights = [
    "{\"indicator\":\"roe\",\"weight\":0.3,\"direction\":\"asc\"}", "{\"indicator\":\"np_margin\",\"weight\":0.2,\"direction\":\"asc\"}",
    "{\"indicator\":\"eps\",\"weight\":0.2,\"direction\":\"asc\"}", "{\"indicator\":\"pe_ratio\",\"weight\":0.15,\"direction\":\"desc\"}",
    "{\"indicator\":\"rsi\",\"weight\":0.15,\"direction\":\"neutral\"}",
  ]
  let response = "{\"weights\":[" + weights.join(",") + "]}"
  make_response(200, response)
}

///|
/// Handler: Get indicator by ID (alias for handle_get_indicator)
pub fn handle_get_screen_indicator(indicator_id : String) -> HttpResponse {
  handle_get_indicator(indicator_id)
}

///|
/// Screener request structure with filters and weights
pub struct ScreenerRequest {
  filters : Array[ScreenerFilter]
  weights : Map[String, Int]
  sort_by : String
  sort_order : String
  limit : Int
}

///|
/// Single filter condition
pub struct ScreenerFilter {
  indicator : String
  operator : String
  value : Float?
  min : Float?
  max : Float?
}

///|
/// Screener result structure with technical indicators and K-line based data
pub struct ScreenerStockResult {
  code : String
  price : Float
  volume : Float
  amount : Float
  turn : Float
  ma5 : Float
  ma10 : Float
  score : Float
} derive(Show, ToJson)

///|
/// Mock stock data for screener with K-line based indicators (for testing)
fn get_screener_mock_data() -> Array[ScreenerStockResult] {
  [
    ScreenerStockResult::{
      code: "sh.600000",
      price: 8.52,
      volume: 25000000.0,
      amount: 213000000.0,
      turn: 0.025,
      ma5: 8.45,
      ma10: 8.30,
      score: 65.0,
    },
    ScreenerStockResult::{
      code: "sh.600001",
      price: 3.45,
      volume: 18000000.0,
      amount: 62100000.0,
      turn: 0.018,
      ma5: 3.40,
      ma10: 3.35,
      score: 48.0,
    },
    ScreenerStockResult::{
      code: "sh.600002",
      price: 5.67,
      volume: 12000000.0,
      amount: 68040000.0,
      turn: 0.012,
      ma5: 5.60,
      ma10: 5.50,
      score: 72.0,
    },
    ScreenerStockResult::{
      code: "sh.600003",
      price: 4.23,
      volume: 9500000.0,
      amount: 40185000.0,
      turn: 0.0095,
      ma5: 4.20,
      ma10: 4.15,
      score: 55.0,
    },
    ScreenerStockResult::{
      code: "sh.600004",
      price: 12.89,
      volume: 32000000.0,
      amount: 412480000.0,
      turn: 0.032,
      ma5: 12.70,
      ma10: 12.50,
      score: 85.0,
    },
  ]
}

///|
/// Calculate moving average from K-line data
pub fn calculate_ma_from_klines(
  klines : Array[@data.KLine],
  period : Int,
) -> Float {
  if klines.length() < period {
    // Not enough data, return latest close price
    if klines.length() > 0 {
      return klines[klines.length() - 1].close
    }
    return 0.0
  }

  // Calculate average of last 'period' closing prices
  let mut sum : Float = 0.0
  let start_idx = klines.length() - period
  let mut i = start_idx
  while i < klines.length() {
    sum = sum + klines[i].close
    i = i + 1
  }

  Float::div(sum, Float::from_int(period))
}

///|
/// Apply filters to screener results
pub fn apply_screener_filters(
  results : Array[ScreenerStockResult],
  filters : Array[ScreenerFilter],
) -> Array[ScreenerStockResult] {
  if filters.length() == 0 {
    return results
  }

  let filtered : Array[ScreenerStockResult] = []

  for result in results {
    let mut matches = true

    for filter in filters {
      // Get the value for the indicator field
      let value = get_indicator_value(result, filter.indicator)

      // Apply the filter operator
      match filter.operator {
        ">" =>
          match filter.value {
            Some(v) => if value <= v { matches = false }
            None => ignore(())
          }
        ">=" =>
          match filter.value {
            Some(v) => if value < v { matches = false }
            None => ignore(())
          }
        "<" =>
          match filter.value {
            Some(v) => if value >= v { matches = false }
            None => ignore(())
          }
        "<=" =>
          match filter.value {
            Some(v) => if value > v { matches = false }
            None => ignore(())
          }
        "=" =>
          match filter.value {
            Some(v) => if Float::abs(value - v) > 0.0001 { matches = false }
            None => ignore(())
          }
        "between" =>
          match (filter.min, filter.max) {
            (Some(min), Some(max)) =>
              if value < min || value > max {
                matches = false
              }
            _ => ignore(())
          }
        _ => ignore(())
      }

      if !matches {
        break
      }
    }

    if matches {
      filtered.push(result)
    }
  }

  filtered
}

///|
/// Get indicator value from result by field name
fn get_indicator_value(
  result : ScreenerStockResult,
  indicator : String,
) -> Float {
  match indicator {
    "price" => result.price
    "volume" => result.volume
    "amount" => result.amount
    "turn" => result.turn
    "ma5" => result.ma5
    "ma10" => result.ma10
    "score" => result.score
    _ => 0.0
  }
}

///|
/// Sort screener results by score (descending)
pub fn sort_screener_results_by_score(
  results : Array[ScreenerStockResult],
) -> Array[ScreenerStockResult] {
  // Simple bubble sort for now (can be optimized later)
  let sorted = results.copy()
  let len = sorted.length()
  let mut i = 0
  while i < len {
    let mut j = 0
    while j < len - i - 1 {
      if sorted[j].score < sorted[j + 1].score {
        // Swap
        let temp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  sorted
}

///|
/// Limit results to maximum count
pub fn limit_results(
  results : Array[ScreenerStockResult],
  limit : Int?,
) -> Array[ScreenerStockResult] {
  match limit {
    Some(n) =>
      if results.length() <= n {
        results
      } else {
        let limited : Array[ScreenerStockResult] = []
        let mut i = 0
        while i < n && i < results.length() {
          limited.push(results[i])
          i = i + 1
        }
        limited
      }
    None => results
  }
}

///|
/// Parse screener request from JSON with proper filter handling
fn parse_screener_request(json : String) -> ScreenerRequest {
  // Simple JSON parsing - extract filters array
  // Format: {"filters":[{"indicator":"price","operator":"gt","value":1.0}],"weights":{},"sort_by":"score","sort_order":"desc","limit":100}

  let filters : Array[ScreenerFilter] = []
  let weights : Map[String, Int] = {}
  let mut sort_by = "score"
  let mut sort_order = "desc"
  let mut limit = 100

  // Parse filters if present
  if json.contains("\"filters\"") {
    // Extract filters array content
    match json.find("\"filters\"") {
      Some(filters_start) => {
        // Find the opening bracket
        match json[filters_start:].find("[") {
          Some(bracket_pos) => {
            let filters_content_start = filters_start + bracket_pos
            // Find matching closing bracket
            let mut bracket_count = 0
            let mut filters_content_end = filters_content_start
            let content = json[filters_content_start:]
            let mut i = 0
            while i < content.char_length() {
              let c = content.at(i)
              if c == 91 {  // '['
                bracket_count = bracket_count + 1
              } else if c == 93 {  // ']'
                bracket_count = bracket_count - 1
                if bracket_count == 0 {
                  filters_content_end = filters_content_start + i
                  break
                }
              }
              i = i + 1
            }

            // Parse each filter object
            if filters_content_end > filters_content_start {
              let filters_str = json[filters_content_start:filters_content_end + 1]
              // Extract individual filter objects
              let filter_objects = filters_str.split("},{").to_array()
              for obj in filter_objects {
                let clean_obj = obj.replace(old="{", new="").replace(old="}", new="").to_string()
                // Parse indicator, operator, value
                let indicator = extract_json_string(clean_obj, "\"indicator\"")
                let operator = extract_json_string(clean_obj, "\"operator\"")
                let value = extract_json_float(clean_obj, "\"value\"")

                if indicator != "" && operator != "" {
                  filters.push(ScreenerFilter::{
                    indicator,
                    operator,
                    value: value,
                    min: None,
                    max: None,
                  })
                }
              }
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }

  // Parse weights if present
  if json.contains("\"weights\"") {
    // Simplified: just use empty weights for now
  }

  // Parse sort_by if present
  if json.contains("\"sort_by\"") {
    let sb = extract_json_string(json, "\"sort_by\"")
    if sb != "" {
      sort_by = sb
    }
  }

  // Parse sort_order if present
  if json.contains("\"sort_order\"") {
    let so = extract_json_string(json, "\"sort_order\"")
    if so != "" {
      sort_order = so
    }
  }

  // Parse limit if present
  if json.contains("\"limit\"") {
    let lim = extract_json_int(json, "\"limit\"")
    if lim > 0 {
      limit = lim
    }
  }

  return ScreenerRequest::{ filters, weights, sort_by, sort_order, limit }
}

///|
/// Extract string value from JSON (public for use in other modules)
pub fn extract_json_string(json : String, key : String) -> String {
  match json.find(key) {
    Some(key_pos) => {
      let rest = json[key_pos:]
      match rest.find(":") {
        Some(colon_pos) => {
          let after_colon = rest[colon_pos + 1:]
          let trimmed = after_colon.trim().to_string()
          if trimmed.length() == 0 {
            return ""
          }

          // Check if it's a quoted string
          if trimmed.at(0) == 34 {
            // Find closing quote
            let content = trimmed[1:].to_string()
            match content.find("\"") {
              Some(end_quote) => content[0:end_quote].to_string()
              None => ""
            }
          } else {
            ""
          }
        }
        None => ""
      }
    }
    None => ""
  }
}

///|
/// Simple float parser (handles basic decimal numbers)
fn parse_float_simple_for_screener(s : String) -> Float {
  // Handle negative numbers
  let mut negative = false
  let mut start_idx = 0
  if s.length() > 0 && s.at(0) == 45 {
    negative = true
    start_idx = 1
  }

  let mut int_part : Int = 0
  let mut dec_part : Float = 0.0
  let mut dec_divisor : Float = 1.0
  let mut in_decimal = false

  let mut i = start_idx
  while i < s.char_length() {
    let c = s.at(i)
    // '0' = 48, '9' = 57 in ASCII/UTF-16
    if c >= 48 && c <= 57 {
      let digit : Int = UInt16::to_int(c) - 48
      if !in_decimal {
        int_part = int_part * 10 + digit
      } else {
        dec_divisor = dec_divisor * 10.0
        dec_part = dec_part + Float::from_int(digit) / dec_divisor
      }
    } else if c == 46 {
      // '.' = 46
      in_decimal = true
    }
    i = i + 1
  }

  let result = Float::from_int(int_part) + dec_part
  if negative {
    -result
  } else {
    result
  }
}

///|
/// Extract float value from JSON (public for use in other modules)
pub fn extract_json_float(json : String, key : String) -> Float? {
  match json.find(key) {
    Some(key_pos) => {
      let rest = json[key_pos:]
      match rest.find(":") {
        Some(colon_pos) => {
          let after_colon = rest[colon_pos + 1:]
          let trimmed = after_colon.trim().to_string()
          if trimmed.length() == 0 {
            return None
          }

          // Parse numeric value - extract digits, decimal point, and minus sign
          let mut num_end = 0
          let mut i = 0
          while i < trimmed.char_length() && i < 20 {
            let c = trimmed.at(i)
            if (c >= 48 && c <= 57) || c == 46 || c == 45 {
              num_end = i + 1
            } else if num_end > 0 {
              break
            }
            i = i + 1
          }

          if num_end == 0 {
            return None
          }

          let num_str = trimmed[0:num_end].to_string()
          Some(parse_float_simple_for_screener(num_str))
        }
        None => None
      }
    }
    None => None
  }
}

///|
/// Extract int value from JSON
fn extract_json_int(json : String, key : String) -> Int {
  let float_val = extract_json_float(json, key)
  match float_val {
    Some(f) => Float::to_int(f)
    None => 100
  }
}

///|
/// Handler: Run stock screener with filters and weights
pub fn handle_screener(request_body : String?) -> HttpResponse {
  let request = parse_screener_request(request_body.unwrap_or("{}"))

  // Get cached stock data (pre-calculated at server startup)
  let all_results = get_cached_stocks_array()

  // Apply filters from request
  let filtered = apply_screener_filters(all_results, request.filters)

  // Sort by specified field
  let sorted = if request.sort_by == "price" {
    sort_screener_results_by_field(filtered, "price", request.sort_order == "desc")
  } else if request.sort_by == "volume" {
    sort_screener_results_by_field(filtered, "volume", request.sort_order == "desc")
  } else if request.sort_by == "amount" {
    sort_screener_results_by_field(filtered, "amount", request.sort_order == "desc")
  } else if request.sort_by == "turn" {
    sort_screener_results_by_field(filtered, "turn", request.sort_order == "desc")
  } else if request.sort_by == "ma5" {
    sort_screener_results_by_field(filtered, "ma5", request.sort_order == "desc")
  } else if request.sort_by == "ma10" {
    sort_screener_results_by_field(filtered, "ma10", request.sort_order == "desc")
  } else {
    sort_screener_results_by_score(filtered)
  }

  // Limit results
  let limited = limit_results(sorted, Some(request.limit))

  // Build response JSON
  let results_json = limited.map(fn(r) {
    "{\"code\":\"\{r.code}\",\"price\":\{r.price},\"volume\":\{r.volume},\"amount\":\{r.amount},\"turn\":\{r.turn},\"ma5\":\{r.ma5},\"ma10\":\{r.ma10},\"score\":\{r.score}}"
  })

  let total = Int::to_string(limited.length())
  let response = "{\"results\":[" +
    results_json.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Sort screener results by specified field
pub fn sort_screener_results_by_field(
  results : Array[ScreenerStockResult],
  field : String,
  desc : Bool,
) -> Array[ScreenerStockResult] {
  let sorted = results.copy()
  let len = sorted.length()
  let mut i = 0
  while i < len {
    let mut j = 0
    while j < len - i - 1 {
      let val_j = get_indicator_value(sorted[j], field)
      let val_j1 = get_indicator_value(sorted[j + 1], field)

      let should_swap = if desc {
        val_j < val_j1
      } else {
        val_j > val_j1
      }

      if should_swap {
        let temp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  sorted
}

///|
/// Handler: Get all available indicators with detailed metadata
pub fn handle_get_all_indicators() -> HttpResponse {
  let indicators = [
    "{\"id\":\"rsi\",\"name\":\"RSI\",\"description\":\"相对强弱指数，衡量价格变动速度和幅度的动量指标\",\"formula\":\"RSI = 100 - 100/(1+RS), RS=平均涨幅/平均跌幅\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"0-100\",\"default_period\":14}",
    "{\"id\":\"macd\",\"name\":\"MACD\",\"description\":\"平滑异同移动平均线，利用长短周期 EMA 的聚合与分离来研判买卖时机\",\"formula\":\"MACD 线=12 日 EMA-26 日 EMA, 信号线=9 日 EMA\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"-∞ to +∞\",\"default_period\":\"12,26,9\"}",
    "{\"id\":\"kdj\",\"name\":\"KDJ\",\"description\":\"随机指标，通过统计价格位置来研判超买超卖\",\"formula\":\"K=2/3*前日 K+1/3*RSV, D=2/3*前日 D+1/3*前日 K, J=3K-2D\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"0-100\",\"default_period\":\"9,3,3\"}",
    "{\"id\":\"ma_trend\",\"name\":\"MA 趋势\",\"description\":\"通过短长期均线比较判断趋势方向\",\"formula\":\"短期 MA(10 日) vs 长期 MA(20 日)\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"-1,0,1\",\"default_period\":\"10,20\"}",
    "{\"id\":\"roe\",\"name\":\"ROE\",\"description\":\"净资产收益率，衡量公司利用股东权益创造利润的能力\",\"formula\":\"ROE = 净利润 / 股东权益 × 100%\",\"category\":\"financial\",\"unit\":\"%\",\"range\":\"0-50%\"}",
    "{\"id\":\"np_margin\",\"name\":\"净利率\",\"description\":\"净利率，衡量公司盈利能力\",\"formula\":\"净利率 = 净利润 / 营业收入 × 100%\",\"category\":\"financial\",\"unit\":\"%\",\"range\":\"0-50%\"}",
    "{\"id\":\"eps\",\"name\":\"EPS\",\"description\":\"每股收益，衡量公司每股创造的净利润\",\"formula\":\"EPS = 净利润 / 总股本\",\"category\":\"financial\",\"unit\":\"元\",\"range\":\"0-100\"}",
    "{\"id\":\"price\",\"name\":\"价格\",\"description\":\"当前市场价格\",\"formula\":\"市场价格\",\"category\":\"market\",\"unit\":\"元\",\"range\":\"0-∞\"}",
    "{\"id\":\"volume\",\"name\":\"成交量\",\"description\":\"一定时间内的交易股数\",\"formula\":\"成交量 = 成交股数\",\"category\":\"market\",\"unit\":\"股\",\"range\":\"0-∞\"}",
    "{\"id\":\"turnover_rate\",\"name\":\"换手率\",\"description\":\"一定时间内市场中股票转手买卖的频率\",\"formula\":\"换手率 = 成交量 / 流通股本 × 100%\",\"category\":\"market\",\"unit\":\"%\",\"range\":\"0-100%\"}",
  ]

  let total = Int::to_string(indicators.length())
  let response = "{\"indicators\":[" +
    indicators.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Handler: Get indicator detail by ID with Chinese descriptions
pub fn handle_get_indicator_detail(indicator_id : String) -> HttpResponse {
  match indicator_id {
    "rsi" => {
      let response = "{\"id\":\"rsi\",\"name\":\"相对强弱指数\",\"description\":\"衡量价格变动速度和幅度的动量指标，用于研判超买超卖状态\",\"formula\":\"RSI = 100 - 100/(1+RS)，其中 RS=平均涨幅/平均跌幅\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"0-100\",\"interpretation\":\">70 超买，<30 超卖\",\"default_period\":14}"
      make_response(200, response)
    }
    "macd" => {
      let response = "{\"id\":\"macd\",\"name\":\"平滑异同移动平均线\",\"description\":\"利用长短周期 EMA 的聚合与分离来研判买卖时机\",\"formula\":\"MACD 线=12 日 EMA-26 日 EMA, 信号线=9 日 EMA of MACD 线\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"-∞ to +∞\",\"interpretation\":\"金叉买入，死叉卖出\",\"default_period\":\"12,26,9\"}"
      make_response(200, response)
    }
    "kdj" => {
      let response = "{\"id\":\"kdj\",\"name\":\"随机指标\",\"description\":\"通过统计价格位置来研判超买超卖，由 K 线、D 线、J 线组成\",\"formula\":\"K=2/3*前日 K+1/3*RSV, D=2/3*前日 D+1/3*前日 K, J=3K-2D\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"0-100\",\"interpretation\":\"K>D 金叉买入，K<D 死叉卖出\",\"default_period\":\"9,3,3\"}"
      make_response(200, response)
    }
    "ma_trend" => {
      let response = "{\"id\":\"ma_trend\",\"name\":\"MA 趋势\",\"description\":\"通过短长期均线比较判断趋势方向\",\"formula\":\"短期 MA(10 日) vs 长期 MA(20 日)\",\"category\":\"technical\",\"unit\":\"\",\"range\":\"-1,0,1\",\"interpretation\":\"1=上升趋势，-1=下降趋势，0=震荡\",\"default_period\":\"10,20\"}"
      make_response(200, response)
    }
    "roe" => {
      let response = "{\"id\":\"roe\",\"name\":\"净资产收益率\",\"description\":\"衡量公司利用股东权益创造利润的能力，是衡量公司盈利能力的重要指标\",\"formula\":\"ROE = 净利润 / 股东权益 × 100%\",\"category\":\"financial\",\"unit\":\"%\",\"range\":\"0-50%\",\"interpretation\":\">15% 为优秀\",\"default_period\":\"TTM\"}"
      make_response(200, response)
    }
    "np_margin" => {
      let response = "{\"id\":\"np_margin\",\"name\":\"净利率\",\"description\":\"衡量公司盈利能力，表示每一元收入中有多少是净利润\",\"formula\":\"净利率 = 净利润 / 营业收入 × 100%\",\"category\":\"financial\",\"unit\":\"%\",\"range\":\"0-50%\",\"interpretation\":\"越高代表盈利效率越好\",\"default_period\":\"TTM\"}"
      make_response(200, response)
    }
    "eps" => {
      let response = "{\"id\":\"eps\",\"name\":\"每股收益\",\"description\":\"衡量公司每股创造的净利润，是衡量股票价值的重要指标\",\"formula\":\"EPS = 净利润 / 总股本\",\"category\":\"financial\",\"unit\":\"元\",\"range\":\"0-100\",\"interpretation\":\"越高越好\",\"default_period\":\"TTM\"}"
      make_response(200, response)
    }
    "price" => {
      let response = "{\"id\":\"price\",\"name\":\"价格\",\"description\":\"当前市场价格，可用于筛选特定价格区间的股票\",\"formula\":\"市场价格\",\"category\":\"market\",\"unit\":\"元\",\"range\":\"0-∞\",\"interpretation\":\"根据策略选择高价股或低价股\",\"default_period\":\"current\"}"
      make_response(200, response)
    }
    "volume" => {
      let response = "{\"id\":\"volume\",\"name\":\"成交量\",\"description\":\"一定时间内的交易股数，反映市场活跃度和流动性\",\"formula\":\"成交量 = 成交股数\",\"category\":\"market\",\"unit\":\"股\",\"range\":\"0-∞\",\"interpretation\":\"高成交量通常表示市场关注度高\",\"default_period\":\"daily\"}"
      make_response(200, response)
    }
    "turnover_rate" => {
      let response = "{\"id\":\"turnover_rate\",\"name\":\"换手率\",\"description\":\"一定时间内市场中股票转手买卖的频率，反映股票流通性强弱\",\"formula\":\"换手率 = 成交量 / 流通股本 × 100%\",\"category\":\"market\",\"unit\":\"%\",\"range\":\"0-100%\",\"interpretation\":\">10% 活跃，<1% 冷清\",\"default_period\":\"daily\"}"
      make_response(200, response)
    }
    _ =>
      make_response(
        404,
        "{\"error\":\"Indicator not found\",\"id\":\"\{indicator_id}\"}",
      )
  }
}

///|
/// Trading model types
pub enum TradingModelType {
  /// Periodic rebalancing (weekly, bi-weekly, monthly, quarterly)
  PeriodicRebalance
  /// Condition-based trigger
  ConditionTrigger
  /// Score-based ranking
  ScoreRanking
  /// Multi-factor weighted
  MultiFactor
} derive(Show, ToJson, Eq)

///|
/// Rebalancing frequency options
pub enum RebalanceFrequency {
  /// Weekly (every Monday)
  Weekly
  /// Bi-weekly (every 2 weeks)
  BiWeekly
  /// Monthly (first trading day of month)
  Monthly
  /// Quarterly (first trading day of quarter)
  Quarterly
} derive(Show, ToJson, Eq)

///|
/// Convert frequency to string
pub fn RebalanceFrequency::to_string(self : RebalanceFrequency) -> String {
  match self {
    RebalanceFrequency::Weekly => "weekly"
    RebalanceFrequency::BiWeekly => "biweekly"
    RebalanceFrequency::Monthly => "monthly"
    RebalanceFrequency::Quarterly => "quarterly"
  }
}

///|
/// Parse frequency from string
pub fn RebalanceFrequency::from_string(s : String) -> RebalanceFrequency {
  match s {
    "weekly" => RebalanceFrequency::Weekly
    "biweekly" => RebalanceFrequency::BiWeekly
    "monthly" => RebalanceFrequency::Monthly
    "quarterly" => RebalanceFrequency::Quarterly
    _ => RebalanceFrequency::Monthly
  }
}

///|
/// Periodic rebalancing configuration
pub struct PeriodicRebalanceConfig {
  /// Rebalancing frequency
  frequency : RebalanceFrequency
  /// Specific day of week (1-5 for Mon-Fri, used for weekly)
  day_of_week : Int?
  /// Specific day of month (1-31, used for monthly)
  day_of_month : Int?
  /// Number of stocks to hold
  holding_count : Int
  /// Whether to reinvest dividends
  reinvest_dividends : Bool
} derive(Show, ToJson)

///|
/// Condition trigger type
pub enum TriggerConditionType {
  /// Technical indicator trigger (RSI, MACD, etc.)
  Technical
  /// Price-based trigger
  Price
  /// Volume-based trigger
  Volume
  /// Financial metric trigger
  Financial
} derive(Show, ToJson, Eq)

///|
/// Single trigger condition
pub struct TriggerCondition {
  /// Condition type
  condition_type : TriggerConditionType
  /// Indicator field (e.g., "rsi", "macd", "price")
  field : String
  /// Operator (>, <, >=, <=, =, cross_above, cross_below)
  operator : String
  /// Threshold value
  threshold : Float
  /// Period for calculation
  period : Int?
} derive(Show, ToJson)

///|
/// Condition-based trigger configuration
pub struct ConditionTriggerConfig {
  /// Trigger conditions (all must be met for AND, any for OR)
  conditions : Array[TriggerCondition]
  /// Logic operator: "AND" or "OR"
  logic_operator : String
  /// Action when triggered: "buy", "sell", "rebalance"
  action : String
  /// Cooldown period in days after trigger
  cooldown_days : Int
  /// Stop loss percentage
  stop_loss_pct : Float?
  /// Take profit percentage
  take_profit_pct : Float?
} derive(Show, ToJson)

///|
/// Trading model instance
pub struct TradingModelInstance {
  /// Model ID
  id : String
  /// Model name
  name : String
  /// Model type
  model_type : TradingModelType
  /// Configuration
  config : Json
  /// Created at
  created_at : String
  /// Is active
  is_active : Bool
} derive(Show, ToJson)

///|
/// Create default periodic rebalance config
pub fn PeriodicRebalanceConfig::default() -> PeriodicRebalanceConfig {
  PeriodicRebalanceConfig::{
    frequency: RebalanceFrequency::Monthly,
    day_of_week: None,
    day_of_month: Some(1),
    holding_count: 10,
    reinvest_dividends: true,
  }
}

///|
/// Create default condition trigger config
pub fn ConditionTriggerConfig::default() -> ConditionTriggerConfig {
  ConditionTriggerConfig::{
    conditions: [],
    logic_operator: "AND",
    action: "rebalance",
    cooldown_days: 5,
    stop_loss_pct: Some(10.0),
    take_profit_pct: Some(20.0),
  }
}

///|
/// Create a trigger condition
pub fn TriggerCondition::create(
  condition_type : TriggerConditionType,
  field : String,
  operator : String,
  threshold : Float,
  period : Int?,
) -> TriggerCondition {
  TriggerCondition::{ condition_type, field, operator, threshold, period }
}

///|
/// Technical trigger condition builder
pub fn TriggerCondition::technical(
  field : String,
  operator : String,
  threshold : Float,
  period : Int?,
) -> TriggerCondition {
  TriggerCondition::{
    condition_type: TriggerConditionType::Technical,
    field,
    operator,
    threshold,
    period,
  }
}

///|
/// Price trigger condition builder
pub fn TriggerCondition::price(
  operator : String,
  threshold : Float,
) -> TriggerCondition {
  TriggerCondition::{
    condition_type: TriggerConditionType::Price,
    field: "price",
    operator,
    threshold,
    period: None,
  }
}

///|
/// Evaluate if a trigger condition is met
pub fn TriggerCondition::evaluate(
  self : TriggerCondition,
  current_value : Float,
  prev_value : Float?,
) -> Bool {
  match self.operator {
    ">" => current_value > self.threshold
    "<" => current_value < self.threshold
    ">=" => current_value >= self.threshold
    "<=" => current_value <= self.threshold
    "=" => Float::to_double(current_value) == Float::to_double(self.threshold)
    "cross_above" =>
      match prev_value {
        Some(prev) => prev <= self.threshold && current_value > self.threshold
        None => false
      }
    "cross_below" =>
      match prev_value {
        Some(prev) => prev >= self.threshold && current_value < self.threshold
        None => false
      }
    _ => false
  }
}

///|
/// Evaluate all trigger conditions
pub fn evaluate_trigger_conditions(
  conditions : Array[TriggerCondition],
  values : Map[String, Float],
  prev_values : Map[String, Float]?,
  logic_operator : String,
) -> Bool {
  if conditions.length() == 0 {
    return false
  }

  let results : Array[Bool] = []
  for cond in conditions {
    let current_val = match values.get(cond.field) {
      Some(v) => v
      None => 0.0
    }
    let prev_val = match prev_values {
      Some(pv) => pv.get(cond.field)
      None => None
    }
    results.push(cond.evaluate(current_val, prev_val))
  }

  // Apply logic operator
  if logic_operator == "AND" {
    let mut all_true = true
    for r in results {
      if !r {
        all_true = false
      }
    }
    all_true
  } else {
    // OR
    let mut any_true = false
    for r in results {
      if r {
        any_true = true
      }
    }
    any_true
  }
}

///|
/// Handler: Create periodic rebalancing model
pub fn handle_create_periodic_model(config_body : String?) -> HttpResponse {
  let _freq = RebalanceFrequency::Monthly
  let config = PeriodicRebalanceConfig::default()

  let reinvest_str = if config.reinvest_dividends { "true" } else { "false" }
  let config_json = "{\"frequency\":\"\{config.frequency.to_string()}\",\"holding_count\":\{Int::to_string(config.holding_count)},\"reinvest_dividends\":\{reinvest_str}}"

  let response = "{\"status\":\"created\",\"model_type\":\"periodic_rebalance\",\"config\":\{config_json},\"message\":\"Periodic rebalancing model configured\"}"
  make_response(200, response)
}

///|
/// Handler: Create condition trigger model
pub fn handle_create_trigger_model(config_body : String?) -> HttpResponse {
  let config = ConditionTriggerConfig::default()

  let conditions_json = "[" +
    config.conditions
    .map(fn(c) {
      "{\"type\":\"technical\",\"field\":\"\{c.field}\",\"operator\":\"\{c.operator}\",\"threshold\":\{c.threshold}}"
    })
    .join(",") +
    "]"

  let response = "{\"status\":\"created\",\"model_type\":\"condition_trigger\",\"config\":{\"logic_operator\":\"\{config.logic_operator}\",\"action\":\"\{config.action}\",\"cooldown_days\":\{Int::to_string(config.cooldown_days)},\"conditions\":\{conditions_json}},\"message\":\"Condition trigger model configured\"}"
  make_response(200, response)
}

///|
/// Handler: Get trading model examples
pub fn handle_get_model_examples() -> HttpResponse {
  let examples = [
    "{\"id\":\"example_1\",\"name\":\"Monthly Rebalance\",\"type\":\"periodic_rebalance\",\"config\":{\"frequency\":\"monthly\",\"holding_count\":10,\"reinvest_dividends\":true},\"description\":\"Rebalance portfolio monthly, holding top 10 scored stocks\"}",
    "{\"id\":\"example_2\",\"name\":\"RSI Oversold Trigger\",\"type\":\"condition_trigger\",\"config\":{\"conditions\":[{\"field\":\"rsi\",\"operator\":\"cross_below\",\"threshold\":30}],\"logic_operator\":\"AND\",\"action\":\"buy\",\"cooldown_days\":5},\"description\":\"Buy when RSI crosses below 30\"}",
    "{\"id\":\"example_3\",\"name\":\"MACD Golden Cross\",\"type\":\"condition_trigger\",\"config\":{\"conditions\":[{\"field\":\"macd\",\"operator\":\"cross_above\",\"threshold\":0}],\"logic_operator\":\"AND\",\"action\":\"buy\",\"cooldown_days\":3},\"description\":\"Buy on MACD golden cross\"}",
    "{\"id\":\"example_4\",\"name\":\"Weekly Rotation\",\"type\":\"periodic_rebalance\",\"config\":{\"frequency\":\"weekly\",\"day_of_week\":1,\"holding_count\":5},\"description\":\"Weekly rotation every Monday\"}",
  ]

  let total = Int::to_string(examples.length())
  let response = "{\"examples\":[" +
    examples.join(",") +
    "],\"total\":\{total}}"
  make_response(200, response)
}

///|
/// Handler: Get available trigger types
pub fn handle_get_trigger_types() -> HttpResponse {
  let trigger_types = [
    "{\"id\":\"technical\",\"name\":\"Technical Indicator Trigger\",\"description\":\"Trigger based on technical indicators like RSI, MACD, KDJ\",\"supported_fields\":[\"rsi\",\"macd\",\"kdj_k\",\"kdj_d\",\"ma_short\",\"ma_long\"],\"operators\":[\">\",\"<\",\">=\",\"<=\",\"=\",\"cross_above\",\"cross_below\"]}",
    "{\"id\":\"price\",\"name\":\"Price Trigger\",\"description\":\"Trigger based on price movements\",\"supported_fields\":[\"price\",\"price_change_pct\",\"cumulative_change\"],\"operators\":[\">\",\"<\",\">=\",\"<=\",\"=\",\"cross_above\",\"cross_below\"]}",
    "{\"id\":\"volume\",\"name\":\"Volume Trigger\",\"description\":\"Trigger based on volume changes\",\"supported_fields\":[\"volume\",\"volume_ratio\",\"turnover_rate\"],\"operators\":[\">\",\"<\",\">=\",\"<=\",\"=\"]}",
    "{\"id\":\"financial\",\"name\":\"Financial Trigger\",\"description\":\"Trigger based on financial metrics\",\"supported_fields\":[\"roe\",\"np_margin\",\"eps\",\"pe_ratio\"],\"operators\":[\">\",\"<\",\">=\",\"<=\"]}",
  ]

  let total = Int::to_string(trigger_types.length())
  let response = "{\"trigger_types\":[" +
    trigger_types.join(",") +
    "],\"total\":\{total}}"
  make_response(200, response)
}

///|
/// Handler: Get rebalancing frequencies
pub fn handle_get_rebalance_frequencies() -> HttpResponse {
  let frequencies = [
    "{\"id\":\"weekly\",\"name\":\"Weekly\",\"description\":\"Rebalance every week (default: Monday)\",\"configurable\":\"day_of_week\"}",
    "{\"id\":\"biweekly\",\"name\":\"Bi-weekly\",\"description\":\"Rebalance every 2 weeks\",\"configurable\":null}",
    "{\"id\":\"monthly\",\"name\":\"Monthly\",\"description\":\"Rebalance every month\",\"configurable\":\"day_of_month\"}",
    "{\"id\":\"quarterly\",\"name\":\"Quarterly\",\"description\":\"Rebalance every quarter\",\"configurable\":null}",
  ]

  let total = Int::to_string(frequencies.length())
  let response = "{\"frequencies\":[" +
    frequencies.join(",") +
    "],\"total\":\{total}}"
  make_response(200, response)
}

///|
/// Calculate RSI from K-line data
fn calculate_rsi_from_klines(
  klines : Array[@data.KLine],
  period : Int,
) -> Float {
  if klines.length() < period + 1 {
    return 50.0
  }

  let closes = klines.map(fn(k) { k.close })
  let rsi_array = @indicator.rsi(closes, period)

  if rsi_array.length() > 0 {
    rsi_array[rsi_array.length() - 1]
  } else {
    50.0
  }
}

///|
/// Calculate MACD from K-line data
fn calculate_macd_from_klines(
  klines : Array[@data.KLine],
  fast : Int,
  slow : Int,
  signal : Int,
) -> Float {
  if klines.length() < slow + 1 {
    return 0.0
  }

  let closes = klines.map(fn(k) { k.close })
  let result = @indicator.macd(closes, fast, slow, signal)

  if result.macd_line.length() > 0 {
    result.macd_line[result.macd_line.length() - 1]
  } else {
    0.0
  }
}

///|
/// Calculate KDJ from K-line data
fn calculate_kdj_from_klines(
  klines : Array[@data.KLine],
  n_period : Int,
) -> Float {
  if klines.length() < n_period {
    return 50.0
  }

  let (k_line, d_line, j_line) = @indicator.kdj(klines, n_period, 3, 3)

  if j_line.length() > 0 {
    j_line[j_line.length() - 1]
  } else {
    50.0
  }
}

///|
/// Handler: List all trading models
pub fn handle_list_all_trading_models() -> HttpResponse {
  // Combine built-in models and trigger types
  let models = get_trading_models()
  let models_json = models.map(fn(m) {
    let params_json = "[" +
      m.parameters.map(fn(p) { "\"\{p}\"" }).join(",") +
      "]"
    "{\"id\":\"\{m.id}\",\"name\":\"\{m.name}\",\"description\":\"\{m.description}\",\"model_type\":\"\{m.model_type}\",\"parameters\":\{params_json},\"output\":\"\{m.output}\"}"
  })

  let total = Int::to_string(models.length())
  let response = "{\"models\":[" +
    models_json.join(",") +
    "],\"total\":\{total}}"
  make_response(200, response)
}
