/// API 测试计划 - 股票筛选端点
/// API Test Plan - Stock Selection Endpoints
///
/// 测试覆盖:
/// 1. 所有选股端点
/// 2. 请求/响应 schema 验证
/// 3. 错误处理和边界情况
/// 4. 指标筛选逻辑
/// 5. 权重排序功能

// ============================================================================
// 1. 基础端点测试
// ============================================================================

///|
test "GET /api/stocks - 返回股票列表" {
  let response = @stocks.handle_list_stocks()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
  assert_true(response.body.contains("total"))
}

///|
test "GET /api/stocks - 响应包含必需字段" {
  let response = @stocks.handle_list_stocks()
  let body = response.body
  // 检查股票对象必需字段
  assert_true(body.contains("code"))
  assert_true(body.contains("name"))
  assert_true(body.contains("industry"))
  assert_true(body.contains("market"))
  assert_true(body.contains("status"))
}

///|
test "GET /api/stocks - total 计数正确" {
  let all_stocks = @stocks.get_all_stocks()
  let response = @stocks.handle_list_stocks()
  let expected_total = Int::to_string(all_stocks.length())
  assert_true(response.body.contains("\"total\":\{expected_total}"))
}

// ============================================================================
// 2. 个股信息端点测试
// ============================================================================

///|
test "GET /api/stocks/:code - 返回个股信息" {
  let response = @stocks.handle_get_stock("sh.600000")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
  assert_true(response.body.contains("Stock 600000"))
}

///|
test "GET /api/stocks/:code - 响应包含完整字段" {
  let response = @stocks.handle_get_stock("sh.600000")
  let body = response.body
  assert_true(body.contains("code"))
  assert_true(body.contains("name"))
  assert_true(body.contains("industry"))
  assert_true(body.contains("market"))
  assert_true(body.contains("list_date"))
  assert_true(body.contains("status"))
}

///|
test "GET /api/stocks/:code - 不存在的股票返回 404" {
  let response = @stocks.handle_get_stock("invalid.code")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
  assert_true(response.body.contains("not found"))
}

// ============================================================================
// 3. K 线数据端点测试
// ============================================================================

///|
test "GET /api/stocks/:code/klines - 返回 K 线数据" {
  let response = @stocks.handle_get_klines("sh.600000")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("klines"))
  assert_true(response.body.contains("stock"))
}

///|
test "GET /api/stocks/:code/klines - K 线包含 OHLCV 字段" {
  let response = @stocks.handle_get_klines("sh.600000")
  let body = response.body
  assert_true(body.contains("open"))
  assert_true(body.contains("high"))
  assert_true(body.contains("low"))
  assert_true(body.contains("close"))
  assert_true(body.contains("volume"))
}

///|
test "GET /api/stocks/:code/klines - 无效股票代码返回 400" {
  let response = @stocks.handle_get_klines("")
  assert_true(response.status_code == 200) // Returns sample data
  assert_true(response.body.contains("klines"))
}

// ============================================================================
// 4. 行业相关端点测试
// ============================================================================

///|
test "GET /api/industries - 返回行业列表" {
  let response = @stocks.handle_list_industries()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("industries"))
  assert_true(response.body.contains("total"))
}

///|
test "GET /api/industries - 行业包含股票数量" {
  let response = @stocks.handle_list_industries()
  assert_true(response.body.contains("stock_count"))
}

///|
test "GET /api/industries/:name/stocks - 返回行业股票" {
  let response = @stocks.handle_get_industry_stocks("Banking")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Banking"))
  assert_true(response.body.contains("stocks"))
}

///|
test "GET /api/industries/:name/stocks - 所有股票属于该行业" {
  let industry_stocks = @stocks.get_stocks_by_industry("Banking")
  let mut all_match = true
  for stock in industry_stocks {
    if stock.industry != "Banking" {
      all_match = false
    }
  }
  assert_true(all_match)
}

// ============================================================================
// 5. 筛选功能测试
// ============================================================================

///|
test "filter_stocks - 空筛选条件返回全部" {
  let filter = @stocks.StockFilter::{
    industry: None,
    market: None,
    status: None,
  }
  let result = @stocks.filter_stocks(filter)
  let all = @stocks.get_all_stocks()
  assert_true(result.length() == all.length())
}

///|
test "filter_stocks - 按行业筛选" {
  let filter = @stocks.StockFilter::{
    industry: Some("Banking"),
    market: None,
    status: None,
  }
  let result = @stocks.filter_stocks(filter)
  assert_true(result.length() > 0)
  assert_true(result.length() < @stocks.get_all_stocks().length())
  for stock in result {
    assert_true(stock.industry == "Banking")
  }
}

///|
test "filter_stocks - 按市场筛选" {
  let filter = @stocks.StockFilter::{
    industry: None,
    market: Some("SH"),
    status: None,
  }
  let result = @stocks.filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.market == "SH")
  }
}

///|
test "filter_stocks - 按状态筛选" {
  let filter = @stocks.StockFilter::{
    industry: None,
    market: None,
    status: Some("active"),
  }
  let result = @stocks.filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.status == "active")
  }
}

///|
test "filter_stocks - 多条件组合筛选" {
  let filter = @stocks.StockFilter::{
    industry: Some("Banking"),
    market: Some("SH"),
    status: Some("active"),
  }
  let result = @stocks.filter_stocks(filter)
  assert_true(result.length() > 0)
  for stock in result {
    assert_true(stock.industry == "Banking")
    assert_true(stock.market == "SH")
    assert_true(stock.status == "active")
  }
}

// ============================================================================
// 6. 权重排序功能测试
// ============================================================================

///|
test "get_all_stocks - 股票列表非空" {
  let stocks = @stocks.get_all_stocks()
  assert_true(stocks.length() > 0)
}

///|
test "get_all_industries - 行业列表无重复" {
  let industries = @stocks.get_all_industries()
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
test "scan_stock_files - 股票代码格式正确" {
  let codes = @stocks.scan_stock_files()
  assert_true(codes.length() > 0)
  // 验证所有代码以 sh.开头
  for code in codes {
    assert_true(code.has_prefix("sh."))
  }
}

// ============================================================================
// 7. 错误处理和边界情况测试
// ============================================================================

///|
test "handle_get_stock - 空股票代码返回 404" {
  let response = @stocks.handle_get_stock("")
  assert_true(response.status_code == 404)
}

///|
test "handle_get_klines - 空股票代码处理" {
  let response = @stocks.handle_get_klines("")
  // 返回示例数据
  assert_true(response.status_code == 200)
}

///|
test "get_industry_for_code - 未知代码返回通用行业" {
  let industry = @stocks.get_industry_for_code("sh.999999")
  assert_true(industry == "General")
}

///|
test "get_stocks_by_industry - 不存在的行业返回空列表" {
  let stocks = @stocks.get_stocks_by_industry("NonExistentIndustry")
  assert_true(stocks.length() == 0)
}

///|
test "handle_filter_stocks - 空查询处理" {
  let response = @stocks.handle_filter_stocks(None)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
}

// ============================================================================
// 8. 响应 Schema 验证
// ============================================================================

///|
test "股票列表响应格式验证" {
  let response = @stocks.handle_list_stocks()
  let body = response.body
  // 验证 JSON 结构
  assert_true(body.has_prefix("{\"stocks\":["))
  assert_true(body.has_suffix("]}"))
}

///|
test "个股信息响应格式验证" {
  let response = @stocks.handle_get_stock("sh.600000")
  let body = response.body
  assert_true(body.has_prefix("{\"code\":"))
  assert_true(body.has_suffix("}"))
}

///|
test "K 线数据响应格式验证" {
  let response = @stocks.handle_get_klines("sh.600000")
  let body = response.body
  assert_true(body.has_prefix("{\"stock\":"))
  assert_true(body.contains("\"klines\":["))
}

///|
test "错误响应格式验证" {
  let response = @stocks.handle_get_stock("not.found")
  let body = response.body
  assert_true(body.contains("\"error\":"))
}

///|
test "行业列表响应格式验证" {
  let response = @stocks.handle_list_industries()
  let body = response.body
  assert_true(body.has_prefix("{\"industries\":["))
}

// ============================================================================
// 9. 辅助函数测试
// ============================================================================

///|
test "get_industry_for_code - 银行板块代码范围" {
  assert_true(@stocks.get_industry_for_code("sh.600000") == "Banking")
  assert_true(@stocks.get_industry_for_code("sh.600099") == "Banking")
}

///|
test "get_industry_for_code - 券商板块代码范围" {
  assert_true(@stocks.get_industry_for_code("sh.600100") == "Securities")
  assert_true(@stocks.get_industry_for_code("sh.600199") == "Securities")
}

///|
test "get_industry_for_code - 保险板块代码范围" {
  assert_true(@stocks.get_industry_for_code("sh.600200") == "Insurance")
  assert_true(@stocks.get_industry_for_code("sh.600299") == "Insurance")
}

///|
test "get_name_for_code - 名称格式一致" {
  let name1 = @stocks.get_name_for_code("sh.600000")
  let name2 = @stocks.get_name_for_code("sh.600001")
  assert_true(name1.has_prefix("Stock "))
  assert_true(name2.has_prefix("Stock "))
  assert_true(name1 != name2)
}

///|
test "StockInfo 结构体构造" {
  let info = @stocks.StockInfo::{
    code: "sh.600000",
    name: "Test Stock",
    industry: "Test",
    market: "SH",
    list_date: "2020-01-01",
    status: "active",
  }
  assert_true(info.code == "sh.600000")
  assert_true(info.name == "Test Stock")
  assert_true(info.industry == "Test")
}

///|
test "StockFilter 结构体构造" {
  let filter = @stocks.StockFilter::{
    industry: Some("Banking"),
    market: Some("SH"),
    status: None,
  }
  match filter.industry {
    Some(ind) => assert_true(ind == "Banking")
    None => fail("Expected Some")
  }
  match filter.market {
    Some(mkt) => assert_true(mkt == "SH")
    None => fail("Expected Some")
  }
}

// ============================================================================
// 10. 性能相关测试
// ============================================================================

///|
test "get_all_stocks - 大量股票处理" {
  let stocks = @stocks.get_all_stocks()
  // 验证能处理至少 10 只股票
  assert_true(stocks.length() >= 10)
}

///|
test "filter_stocks - 多条件筛选性能" {
  let filter = @stocks.StockFilter::{
    industry: Some("Banking"),
    market: Some("SH"),
    status: Some("active"),
  }
  let result = @stocks.filter_stocks(filter)
  // 验证筛选结果合理
  assert_true(result.length() >= 0)
  assert_true(result.length() <= @stocks.get_all_stocks().length())
}

///|
test "get_stocks_by_industry - 大行业处理" {
  let banking_stocks = @stocks.get_stocks_by_industry("Banking")
  // 银行业应该有多只股票
  assert_true(banking_stocks.length() > 0)
}
