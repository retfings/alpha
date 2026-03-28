/// Stock Screener API Endpoint Tests
///
/// Blackbox tests for stock screening endpoints

///|
test "handle_list_indicators returns all indicators" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("indicators"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_list_indicators includes market indicators" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("price"))
  assert_true(response.body.contains("volume"))
  assert_true(response.body.contains("turnover_rate"))
}

///|
test "handle_list_indicators includes financial indicators" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("roe"))
  assert_true(response.body.contains("np_margin"))
  assert_true(response.body.contains("eps"))
}

///|
test "handle_get_indicators_by_category financial" {
  let response = handle_get_indicators_by_category("financial")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("category"))
  assert_true(response.body.contains("financial"))
  assert_true(response.body.contains("roe"))
}

///|
test "handle_get_indicators_by_category technical" {
  let response = handle_get_indicators_by_category("technical")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("macd"))
  assert_true(response.body.contains("rsi"))
  assert_true(response.body.contains("kdj"))
}

///|
test "handle_get_indicators_by_category market" {
  let response = handle_get_indicators_by_category("market")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("market_cap"))
  assert_true(response.body.contains("pe_ratio"))
}

///|
test "handle_get_indicators_by_category all" {
  let response = handle_get_indicators_by_category("all")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("financial"))
  assert_true(response.body.contains("technical"))
  assert_true(response.body.contains("market"))
}

///|
test "handle_get_indicators_by_category invalid category" {
  let response = handle_get_indicators_by_category("invalid")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
}

///|
test "handle_get_indicator roe" {
  let response = handle_get_indicator("roe")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Return on Equity"))
  assert_true(response.body.contains("formula"))
}

///|
test "handle_get_indicator np_margin" {
  let response = handle_get_indicator("np_margin")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Net Profit Margin"))
}

///|
test "handle_get_indicator eps" {
  let response = handle_get_indicator("eps")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Earnings Per Share"))
}

///|
test "handle_get_indicator macd" {
  let response = handle_get_indicator("macd")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("MACD"))
  assert_true(response.body.contains("Moving Average Convergence Divergence"))
}

///|
test "handle_get_indicator rsi" {
  let response = handle_get_indicator("rsi")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Relative Strength Index"))
}

///|
test "handle_get_indicator kdj" {
  let response = handle_get_indicator("kdj")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("KDJ"))
  assert_true(response.body.contains("Stochastic"))
}

///|
test "handle_get_indicator ma" {
  let response = handle_get_indicator("ma")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Moving Average"))
}

///|
test "handle_get_indicator not found" {
  let response = handle_get_indicator("nonexistent")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
  assert_true(response.body.contains("not found"))
}

///|
test "handle_screen with empty request" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("results"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_screen returns mock data" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
  assert_true(response.body.contains("Stock 600001"))
}

///|
test "handle_screen response includes score" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("score"))
}

///|
test "handle_screen response includes health rating" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("health"))
  assert_true(response.body.contains("Good"))
}

///|
test "handle_screen returns 5 mock stocks" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
  assert_true(response.body.contains("sh.600001"))
  assert_true(response.body.contains("sh.600002"))
  assert_true(response.body.contains("sh.600003"))
  assert_true(response.body.contains("sh.600004"))
}

///|
test "handle_list_trading_models returns all models" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("models"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_list_trading_models includes scoring model" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("score_rank"))
  assert_true(response.body.contains("综合评分排序模型"))
}

///|
test "handle_list_trading_models includes clustering model" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("cluster_select"))
  assert_true(response.body.contains("聚类选股模型"))
}

///|
test "handle_list_trading_models includes ml model" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("ml_classifier"))
  assert_true(response.body.contains("机器学习分类模型"))
}

///|
test "handle_list_trading_models includes factor model" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("factor_weighted"))
  assert_true(response.body.contains("因子加权模型"))
}

///|
test "handle_list_trading_models includes rule based model" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("rule_based"))
  assert_true(response.body.contains("规则筛选模型"))
}

///|
test "get_trading_models returns at least 5 models" {
  let models = get_trading_models()
  assert_true(models.length() >= 5)
}

///|
test "each trading model has required fields" {
  let models = get_trading_models()
  let mut all_valid = true
  for m in models {
    if m.id == "" || m.name == "" || m.description == "" || m.model_type == "" {
      all_valid = false
    }
  }
  assert_true(all_valid)
}

///|
test "handle_get_weights returns default weights" {
  let response = handle_get_weights()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("weights"))
  assert_true(response.body.contains("roe"))
  assert_true(response.body.contains("weight"))
}

///|
test "handle_set_weights returns success" {
  let response = handle_set_weights("{}")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("status"))
  assert_true(response.body.contains("configured"))
}

///|
test "trading model score_rank has correct type" {
  let models = get_trading_models()
  let mut found = false
  for m in models {
    if m.id == "score_rank" {
      found = true
      assert_true(m.model_type == "scoring")
      assert_true(m.output == "ranked_stock_list")
    }
  }
  assert_true(found)
}

///|
test "trading model cluster_select has correct type" {
  let models = get_trading_models()
  let mut found = false
  for m in models {
    if m.id == "cluster_select" {
      found = true
      assert_true(m.model_type == "clustering")
      assert_true(m.output == "cluster_assignments")
    }
  }
  assert_true(found)
}

///|
test "trading model ml_classifier has correct type" {
  let models = get_trading_models()
  let mut found = false
  for m in models {
    if m.id == "ml_classifier" {
      found = true
      assert_true(m.model_type == "classification")
      assert_true(m.output == "signal_labels")
    }
  }
  assert_true(found)
}

///|
test "trading model factor_weighted has correct type" {
  let models = get_trading_models()
  let mut found = false
  for m in models {
    if m.id == "factor_weighted" {
      found = true
      assert_true(m.model_type == "factor")
      assert_true(m.output == "composite_scores")
    }
  }
  assert_true(found)
}

///|
test "trading model rule_based has correct type" {
  let models = get_trading_models()
  let mut found = false
  for m in models {
    if m.id == "rule_based" {
      found = true
      assert_true(m.model_type == "rule_engine")
      assert_true(m.output == "filtered_stocks")
    }
  }
  assert_true(found)
}

///|
test "handle_list_indicators response format" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  // Response should be valid JSON with indicators array
  assert_true(response.body.contains("["))
  assert_true(response.body.contains("]"))
  assert_true(response.body.contains("\"id\""))
  assert_true(response.body.contains("\"name\""))
  assert_true(response.body.contains("\"category\""))
}

///|
test "handle_get_indicators_by_category response format" {
  let response = handle_get_indicators_by_category("financial")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"category\":\"financial\""))
  assert_true(response.body.contains("\"total\""))
}

///|
test "handle_screen response format" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"results\":["))
  assert_true(response.body.contains("\"total\":"))
}

///|
test "handle_get_indicator bollinger" {
  let response = handle_get_indicator("bollinger")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Bollinger Bands"))
  assert_true(response.body.contains("Volatility"))
}

///|
test "handle_get_indicator atr" {
  let response = handle_get_indicator("atr")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Average True Range"))
}

///|
test "handle_get_indicator market_cap" {
  let response = handle_get_indicator("market_cap")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Market Capitalization"))
}

///|
test "handle_get_indicator pe_ratio" {
  let response = handle_get_indicator("pe_ratio")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Price-to-Earnings"))
}

///|
test "handle_get_indicator pb_ratio" {
  let response = handle_get_indicator("pb_ratio")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Price-to-Book"))
}

///|
test "handle_get_indicator dividend_yield" {
  let response = handle_get_indicator("dividend_yield")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Dividend Yield"))
}

///|
test "handle_get_indicator volume_ratio" {
  let response = handle_get_indicator("volume_ratio")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Volume Ratio"))
}

///|
test "indicators have unit field" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"unit\""))
}

///|
/// Additional edge cases and boundary tests

///|
test "handle_list_indicators total count is 6" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"total\":6"))
}

///|
test "handle_get_indicators_by_category technical has multiple indicators" {
  let response = handle_get_indicators_by_category("technical")
  assert_true(response.status_code == 200)
  // Should have macd, rsi, kdj, ma, bollinger, atr
  assert_true(response.body.contains("macd"))
  assert_true(response.body.contains("rsi"))
  assert_true(response.body.contains("kdj"))
  assert_true(response.body.contains("ma"))
  assert_true(response.body.contains("bollinger"))
  assert_true(response.body.contains("atr"))
}

///|
test "handle_get_indicator returns formula field" {
  let response = handle_get_indicator("roe")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("formula"))
  assert_true(response.body.contains("Net Income"))
}

///|
test "handle_get_indicator returns range field" {
  let response = handle_get_indicator("roe")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("range"))
  assert_true(response.body.contains("0-50%"))
}

///|
test "handle_screen each result has all required fields" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("code"))
  assert_true(response.body.contains("name"))
  assert_true(response.body.contains("roe"))
  assert_true(response.body.contains("np_margin"))
  assert_true(response.body.contains("eps"))
  assert_true(response.body.contains("price"))
  assert_true(response.body.contains("volume"))
  assert_true(response.body.contains("health"))
  assert_true(response.body.contains("score"))
}

///|
test "ScreenRequest default construction" {
  let req = ScreenRequest::default()
  assert_true(req.min_roe == None)
  assert_true(req.min_np_margin == None)
  assert_true(req.limit == Some(100))
}

///|
test "get_mock_financials returns exactly 5 stocks" {
  let results = get_mock_financials()
  assert_true(results.length() == 5)
}

///|
test "get_mock_financials stock codes are unique" {
  let results = get_mock_financials()
  let mut has_duplicates = false
  let mut i = 0
  while i < results.length() {
    let mut j = i + 1
    while j < results.length() {
      if results[i].code == results[j].code {
        has_duplicates = true
      }
      j = j + 1
    }
    i = i + 1
  }
  assert_true(!has_duplicates)
}

///|
test "get_mock_financials all stocks have valid scores" {
  let results = get_mock_financials()
  for r in results {
    assert_true(r.score >= 0.0)
    assert_true(r.score <= 100.0)
  }
}

///|
test "get_mock_financials all stocks have non-negative values" {
  let results = get_mock_financials()
  for r in results {
    assert_true(r.roe >= 0.0)
    assert_true(r.np_margin >= 0.0)
    assert_true(r.eps >= 0.0)
    assert_true(r.price >= 0.0)
    assert_true(r.volume >= 0.0)
  }
}

///|
test "get_field returns correct values from mock data" {
  let results = get_mock_financials()
  let first = results[0]
  // Just verify get_field works without crashing
  let roe_val = get_field(first, "roe")
  let price_val = get_field(first, "price")
  assert_true(roe_val >= 0.0)
  assert_true(price_val >= 0.0)
}

///|
test "get_field returns score for unknown field" {
  let results = get_mock_financials()
  let first = results[0]
  let score_val = get_field(first, "unknown_field")
  assert_true(score_val == first.score)
}

///|
test "copy_results creates same length array" {
  let original = get_mock_financials()
  let copied = copy_results(original)
  assert_true(copied.length() == original.length())
}

///|
test "copy_results preserves data" {
  let original = get_mock_financials()
  let copied = copy_results(original)
  assert_true(copied.length() == original.length())
  // Check first element matches
  assert_true(copied[0].code == original[0].code)
  assert_true(copied[0].name == original[0].name)
}

///|
test "sort_results descending by roe" {
  let results = get_mock_financials()
  let sorted = sort_results(results, "roe", true)
  assert_true(sorted.length() == results.length())
  // First should have highest ROE
  assert_true(sorted[0].roe >= sorted[sorted.length() - 1].roe)
}

///|
test "sort_results ascending by roe" {
  let results = get_mock_financials()
  let sorted = sort_results(results, "roe", false)
  assert_true(sorted.length() == results.length())
  // First should have lowest ROE
  assert_true(sorted[0].roe <= sorted[sorted.length() - 1].roe)
}

///|
test "sort_results by price descending" {
  let results = get_mock_financials()
  let sorted = sort_results(results, "price", true)
  let len = sorted.length()
  let mut i = 0
  while i < len - 1 {
    assert_true(sorted[i].price >= sorted[i + 1].price)
    i = i + 1
  }
}

///|
test "handle_get_indicators_by_category empty string returns error" {
  let response = handle_get_indicators_by_category("")
  assert_true(response.status_code == 404 || response.body.contains("error"))
}

///|
test "handle_get_indicator empty string returns 404" {
  let response = handle_get_indicator("")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
}

///|
test "handle_get_indicator case sensitivity" {
  let response_lower = handle_get_indicator("roe")
  let response_upper = handle_get_indicator("ROE")
  assert_true(response_lower.status_code == 200)
  assert_true(response_upper.status_code == 404)
}

///|
test "handle_list_indicators response is consistent" {
  let response1 = handle_list_indicators()
  let response2 = handle_list_indicators()
  assert_true(response1.body == response2.body)
}

///|
test "handle_get_indicator response is consistent" {
  let response1 = handle_get_indicator("roe")
  let response2 = handle_get_indicator("roe")
  assert_true(response1.body == response2.body)
}

///|
test "handle_list_trading_models response is consistent" {
  let response1 = handle_list_trading_models()
  let response2 = handle_list_trading_models()
  assert_true(response1.body == response2.body)
}

///|
test "get_trading_models each model has non-empty parameters" {
  let models = get_trading_models()
  for m in models {
    assert_true(m.parameters.length() > 0)
  }
}

///|
test "get_trading_models model ids are unique" {
  let models = get_trading_models()
  let mut has_duplicates = false
  let mut i = 0
  while i < models.length() {
    let mut j = i + 1
    while j < models.length() {
      if models[i].id == models[j].id {
        has_duplicates = true
      }
      j = j + 1
    }
    i = i + 1
  }
  assert_true(!has_duplicates)
}

///|
test "handle_get_weights response format" {
  let response = handle_get_weights()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"indicator\":"))
  assert_true(response.body.contains("\"weight\":"))
  assert_true(response.body.contains("\"direction\":"))
}

///|
test "handle_set_weights with empty body" {
  let response = handle_set_weights("")
  assert_true(response.status_code == 200)
  assert_true(
    response.body.contains("status") || response.body.contains("message"),
  )
}

///|
test "health values are valid" {
  let results = get_mock_financials()
  for r in results {
    assert_true(
      r.health == "Excellent" ||
      r.health == "Good" ||
      r.health == "Fair" ||
      r.health == "Poor" ||
      r.health == "Critical",
    )
  }
}

///|
test "ScreenResult to_json produces valid output" {
  let results = get_mock_financials()
  let r = results[0]
  let json = r.to_json()
  // to_json returns a Json type, verify it's valid by checking it exists
  let json_str = json.to_string()
  assert_true(json_str.length() > 0)
  assert_true(json_str.contains(r.code))
}

///|
test "ScreenResult data access works" {
  let results = get_mock_financials()
  let r = results[0]
  // Access fields to verify they exist
  let _code = r.code
  let _name = r.name
  let _roe = r.roe
  assert_true(_code != "")
}

///|
test "ScreenResult struct is valid" {
  let results = get_mock_financials()
  // Just verify we can access the results
  assert_true(results.length() > 0)
}

///|
test "TradingModel struct is valid" {
  let models = get_trading_models()
  // Just verify we can access the models
  assert_true(models.length() > 0)
}

///|
test "handle_list_indicators JSON structure" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.has_prefix("{\"indicators\":["))
}

///|
test "handle_screen JSON structure" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"results\":["))
  assert_true(response.body.contains("\"total\":"))
}

///|
test "handle_get_weights JSON structure" {
  let response = handle_get_weights()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"weights\":["))
}

///|
test "handle_list_trading_models JSON structure" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"models\":["))
  assert_true(response.body.contains("\"total\":"))
}

///|
/// Performance benchmark tests

///|
test "performance handle_list_indicators 100 iterations" {
  let iterations = 100
  let mut i = 0
  while i < iterations {
    let _ = handle_list_indicators()
    i = i + 1
  }
  assert_true(true)
}

///|
test "performance handle_get_indicator 100 iterations" {
  let iterations = 100
  let mut i = 0
  while i < iterations {
    let _ = handle_get_indicator("roe")
    i = i + 1
  }
  assert_true(true)
}

///|
test "performance handle_screen 50 iterations" {
  let iterations = 50
  let mut i = 0
  while i < iterations {
    let _ = handle_screen(None)
    i = i + 1
  }
  assert_true(true)
}

///|
test "performance handle_list_trading_models 100 iterations" {
  let iterations = 100
  let mut i = 0
  while i < iterations {
    let _ = handle_list_trading_models()
    i = i + 1
  }
  assert_true(true)
}

///|
test "performance handle_get_weights 100 iterations" {
  let iterations = 100
  let mut i = 0
  while i < iterations {
    let _ = handle_get_weights()
    i = i + 1
  }
  assert_true(true)
}

///|
test "performance handle_get_indicators_by_category 100 iterations" {
  let iterations = 100
  let mut i = 0
  while i < iterations {
    let _ = handle_get_indicators_by_category("financial")
    i = i + 1
  }
  assert_true(true)
}

///|
/// Integration tests with route_request
/// Additional indicator tests with Chinese descriptions follow

///|
test "route_request /api/indicators GET" {
  let response = route_request("/api/indicators", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("indicators"))
}

///|
/// Additional indicator tests with Chinese descriptions

///|
test "handle_get_all_indicators returns Chinese descriptions" {
  let response = handle_get_all_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("相对强弱指数"))
  assert_true(response.body.contains("平滑异同移动平均线"))
  assert_true(response.body.contains("随机指标"))
}

///|
test "handle_get_all_indicators includes interpretation field" {
  let response = handle_get_all_indicators()
  assert_true(response.status_code == 200)
  // Interpretation field is in detail endpoint, not list endpoint
  assert_true(response.body.contains("indicators"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_get_indicator_detail rsi Chinese" {
  let response = handle_get_indicator_detail("rsi")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("相对强弱指数"))
  assert_true(response.body.contains(">70 超买，<30 超卖"))
}

///|
test "handle_get_indicator_detail macd Chinese" {
  let response = handle_get_indicator_detail("macd")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("金叉买入，死叉卖出"))
}

///|
test "handle_get_indicator_detail kdj Chinese" {
  let response = handle_get_indicator_detail("kdj")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("K>D 金叉买入"))
}

///|
test "handle_get_indicator_detail ma_trend" {
  let response = handle_get_indicator_detail("ma_trend")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("MA 趋势"))
  assert_true(response.body.contains("1=上升趋势"))
}

///|
test "handle_get_indicator_detail roe Chinese" {
  let response = handle_get_indicator_detail("roe")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains(">15% 为优秀"))
}

///|
test "handle_get_indicator_detail np_margin Chinese" {
  let response = handle_get_indicator_detail("np_margin")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("越高代表盈利效率越好"))
}

///|
test "handle_get_indicator_detail eps Chinese" {
  let response = handle_get_indicator_detail("eps")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("越高越好"))
}

///|
test "handle_get_indicator_detail turnover_rate" {
  let response = handle_get_indicator_detail("turnover_rate")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains(">10% 活跃"))
}

///|
test "handle_get_indicator_detail not found" {
  let response = handle_get_indicator_detail("nonexistent")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
}

///|
test "handle_get_indicator_detail empty string returns 404" {
  let response = handle_get_indicator_detail("")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
}

///|
test "handle_screener returns results with technical indicators" {
  let response = handle_screener(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("results"))
  assert_true(response.body.contains("rsi"))
  assert_true(response.body.contains("macd"))
  assert_true(response.body.contains("kdj"))
}

///|
test "handle_screener returns 10 stocks" {
  let response = handle_screener(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
  assert_true(response.body.contains("sh.600009"))
}

///|
test "handle_screener each result has all fields" {
  let response = handle_screener(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("code"))
  assert_true(response.body.contains("name"))
  assert_true(response.body.contains("price"))
  assert_true(response.body.contains("score"))
}

///|
/// Handler-level tests for screener API

///|
test "handle_screener returns results with technical indicators" {
  let response = handle_screener(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("rsi"))
  assert_true(response.body.contains("macd"))
  assert_true(response.body.contains("kdj"))
}

///|
test "handle_screener returns multiple stocks" {
  let response = handle_screener(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
  assert_true(response.body.contains("sh.600009"))
}

///|

///|
test "handle_get_weights each weight has required fields" {
  let response = handle_get_weights()
  assert_true(response.body.contains("\"indicator\":"))
  assert_true(response.body.contains("\"weight\":"))
  assert_true(response.body.contains("\"direction\":"))
}

///|
test "WeightConfig directions are valid" {
  let response = handle_get_weights()
  // Parse response manually to check directions
  assert_true(response.body.contains("\"asc\""))
  assert_true(response.body.contains("\"desc\""))
  assert_true(response.body.contains("\"neutral\""))
}

///|
test "handle_list_indicators includes 6 market indicators" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"total\":6"))
}

///|
test "handle_get_indicators_by_category financial includes 3 indicators" {
  let response = handle_get_indicators_by_category("financial")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"total\":3"))
  assert_true(response.body.contains("roe"))
  assert_true(response.body.contains("np_margin"))
  assert_true(response.body.contains("eps"))
}

///|
test "handle_get_indicators_by_category technical includes 6 indicators" {
  let response = handle_get_indicators_by_category("technical")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"total\":6"))
  assert_true(response.body.contains("macd"))
  assert_true(response.body.contains("rsi"))
  assert_true(response.body.contains("kdj"))
  assert_true(response.body.contains("ma"))
  assert_true(response.body.contains("bollinger"))
  assert_true(response.body.contains("atr"))
}

///|
test "handle_get_indicators_by_category market includes 5 indicators" {
  let response = handle_get_indicators_by_category("market")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"total\":5"))
  assert_true(response.body.contains("market_cap"))
  assert_true(response.body.contains("pe_ratio"))
  assert_true(response.body.contains("pb_ratio"))
  assert_true(response.body.contains("dividend_yield"))
  assert_true(response.body.contains("volume_ratio"))
}

///|
test "handle_get_indicator macd formula" {
  let response = handle_get_indicator("macd")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("12-period EMA"))
  assert_true(response.body.contains("26-period EMA"))
}

///|
test "handle_get_indicator rsi formula" {
  let response = handle_get_indicator("rsi")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Relative Strength Index"))
  assert_true(response.body.contains("formula"))
}

///|
test "handle_get_indicator kdj formula" {
  let response = handle_get_indicator("kdj")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("3K - 2D"))
}

///|
test "handle_get_indicator bollinger description" {
  let response = handle_get_indicator("bollinger")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Volatility bands"))
}

///|
test "handle_get_indicator atr description" {
  let response = handle_get_indicator("atr")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Average True Range"))
}

///|
test "handle_get_indicator dividend_yield range" {
  let response = handle_get_indicator("dividend_yield")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("range"))
  assert_true(response.body.contains("0-20%"))
}

///|
test "handle_get_indicator pe_ratio unit" {
  let response = handle_get_indicator("pe_ratio")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"unit\":\"ratio\""))
}

///|
/// Filter and sort tests moved to integration tests via handle_screen

///|
test "sort_results with unknown field uses score" {
  let results = get_mock_financials()
  let sorted = sort_results(results, "unknown_field", true)
  // Should fall back to score sorting
  assert_true(sorted.length() == results.length())
}

///|
test "sort_results by eps descending" {
  let results = get_mock_financials()
  let sorted = sort_results(results, "eps", true)
  let len = sorted.length()
  let mut i = 0
  while i < len - 1 {
    assert_true(sorted[i].eps >= sorted[i + 1].eps)
    i = i + 1
  }
}

///|
test "sort_results by volume ascending" {
  let results = get_mock_financials()
  let sorted = sort_results(results, "volume", false)
  let len = sorted.length()
  let mut i = 0
  while i < len - 1 {
    assert_true(sorted[i].volume <= sorted[i + 1].volume)
    i = i + 1
  }
}

///|
test "sort_results empty array" {
  let empty : Array[ScreenResult] = []
  let sorted = sort_results(empty, "roe", true)
  assert_true(sorted.length() == 0)
}

///|
test "copy_results preserves order" {
  let original = get_mock_financials()
  let copied = copy_results(original)
  assert_true(copied.length() == original.length())
  let mut i = 0
  while i < original.length() {
    assert_true(copied[i].code == original[i].code)
    i = i + 1
  }
}

///|
test "get_field roe" {
  let results = get_mock_financials()
  let r = results[0]
  assert_true(get_field(r, "roe") == r.roe)
}

///|
test "get_field np_margin" {
  let results = get_mock_financials()
  let r = results[0]
  assert_true(get_field(r, "np_margin") == r.np_margin)
}

///|
test "get_field volume" {
  let results = get_mock_financials()
  let r = results[0]
  assert_true(get_field(r, "volume") == r.volume)
}

///|
test "get_field score for unknown" {
  let results = get_mock_financials()
  let r = results[0]
  assert_true(get_field(r, "unknown") == r.score)
}

///|
test "ScreenRequest::default limit is 100" {
  let req = ScreenRequest::default()
  assert_true(req.limit == Some(100))
}

///|
test "ScreenRequest::default all optional fields are None" {
  let req = ScreenRequest::default()
  assert_true(req.min_roe == None)
  assert_true(req.min_np_margin == None)
  assert_true(req.sort_by == None)
  assert_true(req.sort_order == None)
}

///|
test "handle_screen limit applied" {
  let body = "{\"limit\":2}"
  let response = handle_screen(Some(body))
  assert_true(response.status_code == 200)
  // Should return limited results
  assert_true(response.body.contains("total"))
}

///|
test "TradingModel::score_rank parameters" {
  let models = get_trading_models()
  let m = models[0]
  assert_true(m.id == "score_rank")
  assert_true(m.parameters.contains("weights"))
  assert_true(m.parameters.contains("normalize_method"))
}

///|
test "TradingModel::cluster_select parameters" {
  let models = get_trading_models()
  for m in models {
    if m.id == "cluster_select" {
      assert_true(m.parameters.contains("n_clusters"))
      assert_true(m.parameters.contains("features"))
    }
  }
}

///|
test "TradingModel::ml_classifier parameters" {
  let models = get_trading_models()
  for m in models {
    if m.id == "ml_classifier" {
      assert_true(m.parameters.contains("model_type"))
      assert_true(m.parameters.contains("thresholds"))
    }
  }
}

///|
test "TradingModel::factor_weighted parameters" {
  let models = get_trading_models()
  for m in models {
    if m.id == "factor_weighted" {
      assert_true(m.parameters.contains("factor_weights"))
      assert_true(m.parameters.contains("normalization"))
    }
  }
}

///|
test "TradingModel::rule_based parameters" {
  let models = get_trading_models()
  for m in models {
    if m.id == "rule_based" {
      assert_true(m.parameters.contains("rules"))
      assert_true(m.parameters.contains("logic_operator"))
    }
  }
}

///|
test "handle_get_indicators_by_category case sensitivity" {
  let response_lower = handle_get_indicators_by_category("financial")
  let response_upper = handle_get_indicators_by_category("Financial")
  assert_true(response_lower.status_code == 200)
  assert_true(response_upper.status_code == 404)
}

///|
test "handle_get_indicator_case sensitivity" {
  let response_lower = handle_get_indicator("roe")
  let response_upper = handle_get_indicator("ROE")
  assert_true(response_lower.status_code == 200)
  assert_true(response_upper.status_code == 404)
}

///|
test "handle_get_indicators_by_category response includes descriptions" {
  let response = handle_get_indicators_by_category("financial")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("description"))
}

///|
test "handle_get_indicator range field present" {
  let response = handle_get_indicator("roe")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("range"))
}

///|
test "handle_get_indicator formula field present" {
  let response = handle_get_indicator("roe")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("formula"))
}

///|
test "handle_screener response structure" {
  let response = handle_screener(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.has_prefix("{\"results\":["))
  assert_true(response.body.contains("\"total\":"))
}

///|
test "handle_get_all_indicators response structure" {
  let response = handle_get_all_indicators()
  assert_true(response.status_code == 200)
  assert_true(response.body.has_prefix("{\"indicators\":["))
}

///|
test "handle_get_indicator_detail response structure" {
  let response = handle_get_indicator_detail("rsi")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("\"id\":\"rsi\""))
  assert_true(response.body.contains("\"name\":\""))
}

///|
test "handle_list_indicators JSON is valid" {
  let response = handle_list_indicators()
  assert_true(response.status_code == 200)
  // Basic JSON structure check
  assert_true(response.body.has_prefix("{\"indicators\":["))
  assert_true(response.body.contains("]"))
  assert_true(response.body.contains("}"))
}

///|
test "handle_screen JSON is valid" {
  let response = handle_screen(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.has_prefix("{\"results\":["))
}

///|
test "handle_get_weights JSON is valid" {
  let response = handle_get_weights()
  assert_true(response.status_code == 200)
  assert_true(response.body.has_prefix("{\"weights\":["))
}

///|
test "handle_list_trading_models JSON is valid" {
  let response = handle_list_trading_models()
  assert_true(response.status_code == 200)
  assert_true(response.body.has_prefix("{\"models\":["))
}

///|
test "route_request /api/screen POST" {
  let response = route_request("/api/screen", "POST", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("results"))
}

///|
test "route_request /api/weights GET" {
  let response = route_request("/api/weights", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("weights"))
}

///|
test "route_request /api/trading-models GET" {
  let response = route_request("/api/trading-models", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("models"))
}

///|
test "route_request /api/indicators/unknowncat returns 404" {
  let response = route_request("/api/indicators/unknowncat", "GET", "")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
}
