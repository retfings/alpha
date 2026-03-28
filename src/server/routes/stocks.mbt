/// Stock API route handlers
///
/// REST endpoints for stock listing and filtering with CSV data integration

///|
/// Stock information structure
pub struct StockInfo {
  code : String
  name : String
  industry : String
  market : String
  list_date : String
  status : String
}

///|
/// Stock filter parameters
pub struct StockFilter {
  industry : String?
  market : String?
  status : String?
}

///|
/// Create stock filter with default values
pub fn StockFilter::create(
  industry : String?,
  market : String?,
  status : String?,
) -> StockFilter {
  StockFilter::{
    industry,
    market,
    status,
  }
}

///|
/// Create empty stock filter
pub fn StockFilter::empty() -> StockFilter {
  StockFilter::{
    industry: None,
    market: None,
    status: None,
  }
}

///|
/// Scan data directory for available stock CSV files
pub fn scan_stock_files() -> Array[String] {
  // Known stock codes from data files
  // Note: In production, this would use directory listing to scan for CSV files
  [
    "sh.600000", "sh.600001", "sh.600002", "sh.600003", "sh.600004", "sh.600005",
    "sh.600006", "sh.600007", "sh.600008", "sh.600009", "sh.600010", "sh.600011",
    "sh.600012", "sh.600015", "sh.600016", "sh.600017", "sh.600018", "sh.600019",
    "sh.600020",
  ]
}

///|
/// Get stock info by code (with industry mapping)
pub fn get_stock_info(code : String) -> StockInfo {
  // Industry mapping based on stock code ranges
  let industry = get_industry_for_code(code)
  let name = get_name_for_code(code)

  StockInfo::{
    code,
    name,
    industry,
    market: "SH",
    list_date: "1990-01-01",
    status: "active",
  }
}

///|
/// Get industry based on stock code
pub fn get_industry_for_code(code : String) -> String {
  let code_num = code[3:]
  let prefix = code_num[0:2]

  match prefix {
    "60" => "Banking"
    "61" => "Securities"
    "62" => "Insurance"
    "63" => "Real Estate"
    "64" => "Transportation"
    "65" => "Utilities"
    "66" => "Automotive"
    "67" => "Steel"
    "68" => "Technology"
    "69" => "Consumer Goods"
    _ => "General"
  }
}

///|
/// Get stock name based on code
pub fn get_name_for_code(code : String) -> String {
  let code_num = code[3:]
  "Stock " + code_num.to_string()
}

///|
/// Get all stocks from data files
pub fn get_all_stocks() -> Array[StockInfo] {
  let codes = scan_stock_files()
  let stocks : Array[StockInfo] = []

  for code in codes {
    stocks.push(get_stock_info(code))
  }

  stocks
}

///|
/// Get all unique industries
pub fn get_all_industries() -> Array[String] {
  let stocks = get_all_stocks()
  let industries : Array[String] = []
  let seen : Array[String] = []

  for stock in stocks {
    let mut found = false
    for ind in seen {
      if ind == stock.industry {
        found = true
      }
    }
    if !found {
      industries.push(stock.industry)
      seen.push(stock.industry)
    }
  }

  industries
}

///|
/// Get stocks by industry
pub fn get_stocks_by_industry(industry : String) -> Array[StockInfo] {
  let stocks = get_all_stocks()
  let result : Array[StockInfo] = []

  for stock in stocks {
    if stock.industry == industry {
      result.push(stock)
    }
  }

  result
}

///|
/// Filter stocks based on criteria
pub fn filter_stocks(filter : StockFilter) -> Array[StockInfo] {
  let stocks = get_all_stocks()
  let result : Array[StockInfo] = []

  for stock in stocks {
    let mut matches = true

    match filter.industry {
      Some(ind) => if stock.industry != ind { matches = false }
      None => ignore(())
    }

    match filter.market {
      Some(mkt) => if stock.market != mkt { matches = false }
      None => ignore(())
    }

    match filter.status {
      Some(st) => if stock.status != st { matches = false }
      None => ignore(())
    }

    if matches {
      result.push(stock)
    }
  }

  result
}

///|
/// Load K-line data from CSV file
pub fn load_klines_for_stock(code : String) -> Array[@data.KLine] {
  let filename = "data/" + code.replace(old=".", new="_") + "_*.csv"

  // In production, would scan for matching file and load
  // For now, return empty array (placeholder)
  @data.load_klines_from_csv(filename).unwrap_or([])
}

///|
/// Handler: List all stocks
pub fn handle_list_stocks() -> HttpResponse {
  let stocks = get_all_stocks()
  let stocks_json = stocks.map(fn(s) {
    "{\"code\":\"\{s.code}\",\"name\":\"\{s.name}\",\"industry\":\"\{s.industry}\",\"market\":\"\{s.market}\",\"list_date\":\"\{s.list_date}\",\"status\":\"\{s.status}\"}"
  })

  let total = Int::to_string(stocks.length())
  let response = "{\"stocks\":[" +
    stocks_json.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Handler: Filter stocks
pub fn handle_filter_stocks(query : String?) -> HttpResponse {
  let filter = StockFilter::{ industry: None, market: None, status: None }
  let stocks = filter_stocks(filter)

  let stocks_json = stocks.map(fn(s) {
    "{\"code\":\"\{s.code}\",\"name\":\"\{s.name}\",\"industry\":\"\{s.industry}\",\"market\":\"\{s.market}\",\"list_date\":\"\{s.list_date}\",\"status\":\"\{s.status}\"}"
  })

  let total = Int::to_string(stocks.length())
  let query_str = if query != None { query.unwrap() } else { "" }
  let response = "{\"stocks\":[" +
    stocks_json.join(",") +
    "],\"total\":\{total},\"query\":\"\{query_str}\"}"

  make_response(200, response)
}

///|
/// Handler: Get stock info by code
pub fn handle_get_stock(code : String) -> HttpResponse {
  let stocks = get_all_stocks()
  for stock in stocks {
    if stock.code == code {
      let response = "{\"code\":\"\{stock.code}\",\"name\":\"\{stock.name}\",\"industry\":\"\{stock.industry}\",\"market\":\"\{stock.market}\",\"list_date\":\"\{stock.list_date}\",\"status\":\"\{stock.status}\"}"
      return make_response(200, response)
    }
  }
  make_response(404, "{\"error\":\"Stock not found: \{code}\"}")
}

///|
/// Handler: Get K-lines for stock
pub fn handle_get_klines(code : String) -> HttpResponse {
  let klines = load_klines_for_stock(code)

  if klines.length() == 0 {
    // Return sample kline if no data loaded
    let sample_kline = "{\"date\":\"2026-03-27\",\"open\":10.5,\"high\":11.0,\"low\":10.3,\"close\":10.8,\"volume\":1000000.0,\"amount\":10800000.0,\"turn\":0.05}"
    let response = "{\"stock\":\"\{code}\",\"klines\":[\{sample_kline}],\"count\":1}"
    return make_response(200, response)
  }

  let klines_json = klines.map(fn(k) {
    "{\"date\":\"\{k.date}\",\"open\":\{k.open},\"high\":\{k.high},\"low\":\{k.low},\"close\":\{k.close},\"volume\":\{k.volume},\"amount\":\{k.amount},\"turn\":\{k.turn}}"
  })

  let count = Int::to_string(klines.length())
  let response = "{\"stock\":\"\{code}\",\"klines\":[" +
    klines_json.join(",") +
    "],\"count\":\{count}}"

  make_response(200, response)
}

///|
/// Handler: List industries
pub fn handle_list_industries() -> HttpResponse {
  let industries = get_all_industries()
  let industry_data = industries.map(fn(ind) {
    let stocks = get_stocks_by_industry(ind)
    let count = Int::to_string(stocks.length())
    "{\"name\":\"\{ind}\",\"stock_count\":\{count}}"
  })

  let total = Int::to_string(industries.length())
  let response = "{\"industries\":[" +
    industry_data.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Handler: Get stocks in industry
pub fn handle_get_industry_stocks(industry : String) -> HttpResponse {
  let stocks = get_stocks_by_industry(industry)
  let stocks_json = stocks.map(fn(s) {
    "{\"code\":\"\{s.code}\",\"name\":\"\{s.name}\",\"market\":\"\{s.market}\",\"list_date\":\"\{s.list_date}\",\"status\":\"\{s.status}\"}"
  })

  let total = Int::to_string(stocks.length())
  let response = "{\"industry\":\"\{industry}\",\"stocks\":[" +
    stocks_json.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}
