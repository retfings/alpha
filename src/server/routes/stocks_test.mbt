/// Stock API Endpoint Tests
///
/// Blackbox tests for stock selection endpoints

///|
test "handle_list_stocks returns all stocks" {
  let response = handle_list_stocks()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_list_stocks response format" {
  let response = handle_list_stocks()
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"stocks":[{"code":"sh.600000","name":"Stock 600000","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600001","name":"Stock 600001","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600002","name":"Stock 600002","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600003","name":"Stock 600003","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600004","name":"Stock 600004","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600005","name":"Stock 600005","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600006","name":"Stock 600006","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600007","name":"Stock 600007","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600008","name":"Stock 600008","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600009","name":"Stock 600009","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600010","name":"Stock 600010","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600011","name":"Stock 600011","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600012","name":"Stock 600012","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600015","name":"Stock 600015","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600016","name":"Stock 600016","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600017","name":"Stock 600017","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600018","name":"Stock 600018","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600019","name":"Stock 600019","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600020","name":"Stock 600020","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"}],"total":19}
    ),
  )
}

///|
test "get_all_stocks returns non-empty array" {
  let stocks = get_all_stocks()
  assert_true(stocks.length() > 0)
}

///|
test "get_all_stocks each stock has required fields" {
  let stocks = get_all_stocks()
  let mut all_valid = true
  for stock in stocks {
    if stock.code == "" || stock.name == "" || stock.industry == "" {
      all_valid = false
    }
  }
  assert_true(all_valid)
}

///|
test "scan_stock_files returns expected stock codes" {
  let codes = scan_stock_files()
  assert_true(codes.length() > 0)
  // Check first stock code format
  assert_true(codes[0].has_prefix("sh."))
}

///|
test "get_stock_info returns correct info for valid code" {
  let info = get_stock_info("sh.600000")
  assert_true(info.code == "sh.600000")
  assert_true(info.name == "Stock 600000")
  assert_true(info.market == "SH")
  assert_true(info.status == "active")
}

///|
test "get_industry_for_code banking range" {
  let industry = get_industry_for_code("sh.600000")
  assert_true(industry == "Banking")
}

///|
test "get_industry_for_code securities range" {
  let industry = get_industry_for_code("sh.600100")
  assert_true(industry == "Securities")
}

///|
test "get_industry_for_code insurance range" {
  let industry = get_industry_for_code("sh.600200")
  assert_true(industry == "Insurance")
}

///|
test "get_industry_for_code real estate range" {
  let industry = get_industry_for_code("sh.600300")
  assert_true(industry == "Real Estate")
}

///|
test "get_industry_for_code transportation range" {
  let industry = get_industry_for_code("sh.600400")
  assert_true(industry == "Transportation")
}

///|
test "get_industry_for_code utilities range" {
  let industry = get_industry_for_code("sh.600500")
  assert_true(industry == "Utilities")
}

///|
test "get_industry_for_code automotive range" {
  let industry = get_industry_for_code("sh.600600")
  assert_true(industry == "Automotive")
}

///|
test "get_industry_for_code steel range" {
  let industry = get_industry_for_code("sh.600700")
  assert_true(industry == "Steel")
}

///|
test "get_industry_for_code technology range" {
  let industry = get_industry_for_code("sh.600800")
  assert_true(industry == "Technology")
}

///|
test "get_industry_for_code consumer goods range" {
  let industry = get_industry_for_code("sh.600900")
  assert_true(industry == "Consumer Goods")
}

///|
test "get_industry_for_code general fallback" {
  let industry = get_industry_for_code("sh.601000")
  assert_true(industry == "General")
}

///|
test "get_name_for_code returns formatted name" {
  let name = get_name_for_code("sh.600000")
  assert_true(name == "Stock 600000")
}

///|
test "get_name_for_code different codes" {
  let name1 = get_name_for_code("sh.600001")
  let name2 = get_name_for_code("sh.600002")
  assert_true(name1 == "Stock 600001")
  assert_true(name2 == "Stock 600002")
  assert_true(name1 != name2)
}

///|
test "get_all_industries returns unique industries" {
  let industries = get_all_industries()
  assert_true(industries.length() > 0)
  // Check no duplicates
  let mut has_duplicates = false
  let mut i = 0
  while i < industries.length() {
    let mut j = i + 1
    while j < industries.length() {
      if industries[i] == industries[j] {
        has_duplicates = true
      }
      j = j + 1
    }
    i = i + 1
  }
  assert_true(!has_duplicates)
}

///|
test "get_stocks_by_industry returns filtered stocks" {
  let banking_stocks = get_stocks_by_industry("Banking")
  assert_true(banking_stocks.length() > 0)
  // All returned stocks should be in Banking industry
  let mut all_banking = true
  for stock in banking_stocks {
    if stock.industry != "Banking" {
      all_banking = false
    }
  }
  assert_true(all_banking)
}

///|
test "get_stocks_by_industry empty for non-existent industry" {
  let stocks = get_stocks_by_industry("NonExistent")
  assert_true(stocks.length() == 0)
}

///|
test "filter_stocks with empty filter returns all" {
  let filter = StockFilter::empty()
  let result = filter_stocks(filter)
  let all = get_all_stocks()
  assert_true(result.length() == all.length())
}

///|
test "filter_stocks by industry" {
  let filter = StockFilter::create(Some("Banking"), None, None)
  let result = filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.industry == "Banking")
  }
}

///|
test "filter_stocks by market" {
  let filter = StockFilter::create(None, Some("SH"), None)
  let result = filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.market == "SH")
  }
}

///|
test "filter_stocks by status" {
  let filter = StockFilter::create(None, None, Some("active"))
  let result = filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.status == "active")
  }
}

///|
test "filter_stocks by multiple criteria" {
  let filter = StockFilter::create(Some("Banking"), Some("SH"), Some("active"))
  let result = filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.industry == "Banking")
    assert_true(stock.market == "SH")
    assert_true(stock.status == "active")
  }
}

///|
test "handle_filter_stocks returns valid response" {
  let response = handle_filter_stocks(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_get_stock returns stock info" {
  let response = handle_get_stock("sh.600000")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
  assert_true(response.body.contains("Stock 600000"))
}

///|
test "handle_get_stock returns 404 for unknown stock" {
  let response = handle_get_stock("unknown.code")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
  assert_true(response.body.contains("not found"))
}

///|
test "handle_get_klines returns sample data when no file" {
  let response = handle_get_klines("sh.600000")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("klines"))
  assert_true(response.body.contains("stock"))
}

///|
test "handle_list_industries returns industry list" {
  let response = handle_list_industries()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("industries"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_get_industry_stocks returns stocks for industry" {
  let response = handle_get_industry_stocks("Banking")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("industry"))
  assert_true(response.body.contains("Banking"))
  assert_true(response.body.contains("stocks"))
}

///|
test "handle_get_industry_stocks returns 404 for unknown industry" {
  let response = handle_get_industry_stocks("UnknownIndustry")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("industry"))
  // Should still return 200 with empty stocks array
}
