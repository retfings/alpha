/// Stock API route handlers
///
/// REST endpoints for stock listing and filtering

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
/// Get sample stock data (simulating Baostock integration)
fn get_sample_stocks() -> Array[StockInfo] {
  [
    StockInfo::{
      code: "sh.600000",
      name: "Ping An Bank",
      industry: "Banking",
      market: "SH",
      list_date: "1991-04-03",
      status: "active",
    },
    StockInfo::{
      code: "sh.600001",
      name: "China Feihe",
      industry: "Consumer Goods",
      market: "SH",
      list_date: "2019-11-13",
      status: "active",
    },
    StockInfo::{
      code: "sh.600004",
      name: "Guangzhou Baiyun",
      industry: "Transportation",
      market: "SH",
      list_date: "1998-08-04",
      status: "active",
    },
    StockInfo::{
      code: "sh.600006",
      name: "Dongfeng Motor",
      industry: "Automotive",
      market: "SH",
      list_date: "1999-07-26",
      status: "active",
    },
    StockInfo::{
      code: "sh.600007",
      name: "China World Trade",
      industry: "Real Estate",
      market: "SH",
      list_date: "1999-03-12",
      status: "active",
    },
    StockInfo::{
      code: "sh.600008",
      name: "Beijing Capital",
      industry: "Utilities",
      market: "SH",
      list_date: "1998-09-25",
      status: "active",
    },
    StockInfo::{
      code: "sh.600009",
      name: "Shanghai Airport",
      industry: "Transportation",
      market: "SH",
      list_date: "1998-11-18",
      status: "active",
    },
    StockInfo::{
      code: "sh.600010",
      name: "Baotou Steel",
      industry: "Steel",
      market: "SH",
      list_date: "2001-05-11",
      status: "active",
    },
    StockInfo::{
      code: "sh.600011",
      name: "Huaneng Power",
      industry: "Utilities",
      market: "SH",
      list_date: "1998-02-05",
      status: "active",
    },
    StockInfo::{
      code: "sh.600012",
      name: "Anhui Expressway",
      industry: "Transportation",
      market: "SH",
      list_date: "1996-11-13",
      status: "active",
    },
  ]
}

///|
/// Get all unique industries from stock data
pub fn get_all_industries() -> Array[String] {
  let stocks = get_sample_stocks()
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
  let stocks = get_sample_stocks()
  let result : Array[StockInfo] = []
  for stock in stocks {
    if stock.industry == industry {
      result.push(stock)
    }
  }
  result
}

///|
/// Stock filter parameters
pub struct StockFilter {
  industry : String?
  market : String?
  status : String?
}

///|
/// Filter stocks based on criteria
pub fn filter_stocks(filter : StockFilter) -> Array[StockInfo] {
  let stocks = get_sample_stocks()
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
/// Handler: List all stocks
pub fn handle_list_stocks() -> HttpResponse {
  let stocks = get_sample_stocks()
  let stocks_json = stocks.map(fn(s) {
    "{\"code\":\"\{s.code}\",\"name\":\"\{s.name}\",\"industry\":\"\{s.industry}\",\"market\":\"\{s.market}\",\"list_date\":\"\{s.list_date}\",\"status\":\"\{s.status}\"}"
  })

  let total = Int::to_string(stocks.length())
  let response = "{\"stocks\":[" + stocks_json.join(",") + "],\"total\":\{total}}"

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
  let response = "{\"stocks\":[" + stocks_json.join(",") + "],\"total\":\{total},\"query\":\"\{query_str}\"}"

  make_response(200, response)
}

///|
/// Handler: Get stock info by code
pub fn handle_get_stock(code : String) -> HttpResponse {
  let stocks = get_sample_stocks()
  for stock in stocks {
    if stock.code == code {
      let response = "{\"code\":\"\{stock.code}\",\"name\":\"\{stock.name}\",\"industry\":\"\{stock.industry}\",\"market\":\"\{stock.market}\",\"list_date\":\"\{stock.list_date}\",\"status\":\"\{stock.status}\"}"
      return make_response(200, response)
    }
  }
  make_response(404, "{\"error\":\"Stock not found: \{code}\"}")
}

///|
/// Handler: Get K-lines for stock (placeholder)
pub fn handle_get_klines(code : String) -> HttpResponse {
  let sample_kline = "{\"date\":\"2026-03-27\",\"open\":10.5,\"high\":11.0,\"low\":10.3,\"close\":10.8,\"volume\":1000000.0,\"amount\":10800000.0,\"turn\":0.05}"
  let response = "{\"stock\":\"\{code}\",\"klines\":[\{sample_kline}],\"count\":1}"
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
  let response = "{\"industries\":[" + industry_data.join(",") + "],\"total\":\{total}}"

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
  let response = "{\"industry\":\"\{industry}\",\"stocks\":[" + stocks_json.join(",") + "],\"total\":\{total}}"

  make_response(200, response)
}
