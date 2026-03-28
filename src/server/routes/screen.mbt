/// Stock screening API route handlers
///
/// REST endpoints for stock screening based on indicators

///|
/// Screen request structure
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
    ScreenResult::{ code: "sh.600000", name: "Stock 600000", roe: 15.5, np_margin: 12.3, eps: 2.5, price: 10.5, volume: 1000000.0, health: "Good", score: 75.0 },
    ScreenResult::{ code: "sh.600001", name: "Stock 600001", roe: 25.0, np_margin: 18.0, eps: 3.5, price: 15.8, volume: 1500000.0, health: "Excellent", score: 90.0 },
    ScreenResult::{ code: "sh.600002", name: "Stock 600002", roe: 8.0, np_margin: 5.5, eps: 1.0, price: 8.2, volume: 800000.0, health: "Fair", score: 55.0 },
    ScreenResult::{ code: "sh.600003", name: "Stock 600003", roe: 18.5, np_margin: 15.0, eps: 2.8, price: 12.3, volume: 1200000.0, health: "Good", score: 80.0 },
    ScreenResult::{ code: "sh.600004", name: "Stock 600004", roe: 5.0, np_margin: 3.0, eps: 0.5, price: 6.5, volume: 500000.0, health: "Poor", score: 35.0 },
  ]
}

///|
/// Apply filters to screen results
pub fn apply_filters(results : Array[ScreenResult], request : ScreenRequest) -> Array[ScreenResult] {
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
pub fn sort_results(results : Array[ScreenResult], sort_by : String, desc : Bool) -> Array[ScreenResult] {
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

  // Get mock data
  let results = get_mock_financials()

  // Apply filters
  let filtered = apply_filters(results, request)

  // Sort
  let sorted = match request.sort_by {
    Some(field) => sort_results(filtered, field, request.sort_order != Some("asc"))
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
  let response = "{\"results\":[" + results_json.join(",") + "],\"total\":\{total}}"

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
  let response = "{\"indicators\":[" + indicators.join(",") + "],\"total\":\{total}}"

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
    _ => make_response(404, "{\"error\":\"Indicator not found: \{indicator_id}\"}")
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
    make_response(404, "{\"error\":\"Unknown category: \{category}\",\"valid_categories\":[\"financial\",\"technical\",\"market\"]}")
  } else {
    let total = Int::to_string(filtered.length())
    let response = "{\"category\":\"\{category}\",\"indicators\":[" + filtered.join(",") + "],\"total\":\{total}}"
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
    let params_json = "[" + m.parameters.map(fn(p) { "\"\{p}\"" }).join(",") + "]"
    "{\"id\":\"\{m.id}\",\"name\":\"\{m.name}\",\"description\":\"\{m.description}\",\"model_type\":\"\{m.model_type}\",\"parameters\":\{params_json},\"output\":\"\{m.output}\"}"
  })

  let total = Int::to_string(models.length())
  let response = "{\"models\":[" + models_json.join(",") + "],\"total\":\{total}}"

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
    "{\"indicator\":\"roe\",\"weight\":0.3,\"direction\":\"asc\"}",
    "{\"indicator\":\"np_margin\",\"weight\":0.2,\"direction\":\"asc\"}",
    "{\"indicator\":\"eps\",\"weight\":0.2,\"direction\":\"asc\"}",
    "{\"indicator\":\"pe_ratio\",\"weight\":0.15,\"direction\":\"desc\"}",
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
/// Screener result structure with technical indicators
pub struct ScreenerStockResult {
  code : String
  name : String
  price : Float
  rsi : Float
  macd : Float
  kdj : Float
  roe : Float
  np_margin : Float
  eps : Float
  volume : Float
  score : Float
} derive(Show, ToJson)

///|
/// Parse screener request from JSON
fn parse_screener_request(_json : String) -> ScreenerRequest {
  ScreenerRequest::{
    filters: [],
    weights: {},
    sort_by: "score",
    sort_order: "desc",
    limit: 100,
  }
}

///|
/// Mock stock data for screener with technical indicators
fn get_screener_mock_data() -> Array[ScreenerStockResult] {
  [
    ScreenerStockResult::{ code: "sh.600000", name: "浦发银行", price: 8.52, rsi: 45.2, macd: 0.0234, kdj: 52.3, roe: 12.5, np_margin: 28.3, eps: 1.25, volume: 25000000.0, score: 65.0 },
    ScreenerStockResult::{ code: "sh.600001", name: "邯郸钢铁", price: 3.45, rsi: 62.8, macd: -0.0123, kdj: 71.2, roe: 8.2, np_margin: 5.1, eps: 0.32, volume: 18000000.0, score: 48.0 },
    ScreenerStockResult::{ code: "sh.600002", name: "齐鲁石化", price: 5.67, rsi: 38.5, macd: 0.0456, kdj: 35.8, roe: 15.8, np_margin: 12.4, eps: 0.89, volume: 12000000.0, score: 72.0 },
    ScreenerStockResult::{ code: "sh.600003", name: "东北高速", price: 4.23, rsi: 55.1, macd: 0.0089, kdj: 48.6, roe: 6.5, np_margin: 18.2, eps: 0.45, volume: 9500000.0, score: 55.0 },
    ScreenerStockResult::{ code: "sh.600004", name: "白云机场", price: 12.89, rsi: 72.4, macd: 0.1234, kdj: 82.1, roe: 18.3, np_margin: 32.5, eps: 1.85, volume: 32000000.0, score: 85.0 },
    ScreenerStockResult::{ code: "sh.600005", name: "武钢股份", price: 4.56, rsi: 48.9, macd: -0.0056, kdj: 42.3, roe: 10.2, np_margin: 8.7, eps: 0.52, volume: 21000000.0, score: 52.0 },
    ScreenerStockResult::{ code: "sh.600006", name: "东风汽车", price: 7.34, rsi: 58.2, macd: 0.0312, kdj: 61.5, roe: 14.6, np_margin: 6.8, eps: 0.78, volume: 15000000.0, score: 68.0 },
    ScreenerStockResult::{ code: "sh.600007", name: "上港集团", price: 6.12, rsi: 41.6, macd: -0.0178, kdj: 38.9, roe: 22.1, np_margin: 42.3, eps: 1.12, volume: 28000000.0, score: 78.0 },
    ScreenerStockResult::{ code: "sh.600008", name: "首创股份", price: 3.89, rsi: 67.3, macd: 0.0201, kdj: 69.8, roe: 9.8, np_margin: 15.6, eps: 0.41, volume: 11000000.0, score: 58.0 },
    ScreenerStockResult::{ code: "sh.600009", name: "上海机场", price: 45.67, rsi: 52.8, macd: 0.5678, kdj: 55.2, roe: 25.4, np_margin: 38.9, eps: 2.35, volume: 8500000.0, score: 88.0 },
  ]
}

///|
/// Handler: Run stock screener with filters and weights
pub fn handle_screener(request_body : String?) -> HttpResponse {
  let _request = parse_screener_request(request_body.unwrap_or("{}"))

  // Get mock data (in production, would apply filters and calculate scores)
  let results = get_screener_mock_data()

  // Build response JSON
  let results_json = results.map(fn(r) {
    "{\"code\":\"\{r.code}\",\"name\":\"\{r.name}\",\"price\":\{r.price},\"rsi\":\{r.rsi},\"macd\":\{r.macd},\"kdj\":\{r.kdj},\"roe\":\{r.roe},\"np_margin\":\{r.np_margin},\"eps\":\{r.eps},\"volume\":\{r.volume},\"score\":\{r.score}}"
  })

  let total = Int::to_string(results.length())
  let response = "{\"results\":[" + results_json.join(",") + "],\"total\":\{total}}"

  make_response(200, response)
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
  let response = "{\"indicators\":[" + indicators.join(",") + "],\"total\":\{total}}"

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
    _ => make_response(404, "{\"error\":\"Indicator not found\",\"id\":\"\{indicator_id}\"}")
  }
}
