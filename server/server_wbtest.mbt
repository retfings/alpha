/// HTTP Server module tests

///|
test "@routes.parse_request_path extracts path from GET request" {
  let request = "GET /api/health HTTP/1.1\nHost: localhost\n\n"
  let path = @routes.parse_request_path(request)
  assert_true(path == "/api/health")
}

///|
test "@routes.parse_request_path extracts path from POST request" {
  let request = "POST /api/backtest HTTP/1.1\nContent-Type: application/json\n\n"
  let path = @routes.parse_request_path(request)
  assert_true(path == "/api/backtest")
}

///|
test "@routes.parse_request_path returns root for empty request" {
  let request = ""
  let path = @routes.parse_request_path(request)
  assert_true(path == "/")
}

///|
test "@routes.parse_request_path returns root for malformed request" {
  let request = "INVALID\n\n"
  let path = @routes.parse_request_path(request)
  assert_true(path == "/")
}

///|
test "@routes.extract_stock_code from klines path" {
  let path = "/api/stocks/sh.600000/klines"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sh.600000"))
}

///|
test "@routes.extract_stock_code from stock info path" {
  let path = "/api/stocks/sz.000001"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sz.000001"))
}

///|
test "@routes.extract_stock_code from drawdown path" {
  let path = "/api/drawdown/sh.600000"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sh.600000"))
}

///|
test "@routes.extract_stock_code returns None for invalid path" {
  let path = "/api/health"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == None)
}

///|
test "@routes.extract_stock_code handles multiple stocks in path" {
  let path = "/api/stocks/sh.600000/compare/sz.000001"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sh.600000"))
}

///|
test "@routes.extract_backtest_id from result path" {
  let path = "/api/backtest/bt_123/result"
  let id = @routes.extract_backtest_id(path)
  assert_true(id == Some("bt_123"))
}

///|
test "@routes.extract_backtest_id returns None for base path" {
  let path = "/api/backtest"
  let id = @routes.extract_backtest_id(path)
  assert_true(id == None)
}

///|
test "@routes.extract_backtest_id returns None for unrelated path" {
  let path = "/api/health"
  let id = @routes.extract_backtest_id(path)
  assert_true(id == None)
}

///|
test "@routes.route_request health endpoint" {
  let response = @routes.route_request("/api/health", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("moonbit-drawdown"))
}

///|
test "@routes.route_request list stocks endpoint" {
  let response = @routes.route_request("/api/stocks", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
}

///|
test "@routes.route_request get stock info endpoint" {
  let response = @routes.route_request("/api/stocks/sh.600000", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
}

///|
test "@routes.route_request get klines endpoint" {
  let response = @routes.route_request("/api/stocks/sh.600000/klines", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("klines"))
}

///|
test "@routes.route_request start backtest endpoint" {
  let response = @routes.route_request("/api/backtest", "POST")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("started"))
}

///|
test "@routes.route_request get backtest result endpoint" {
  let response = @routes.route_request("/api/backtest/bt_001/result", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("bt_001"))
}

///|
test "@routes.route_request get drawdown endpoint" {
  let response = @routes.route_request("/api/drawdown/sh.600000", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("drawdown"))
}

///|
test "@routes.route_request portfolio drawdown endpoint" {
  let response = @routes.route_request("/api/portfolio/drawdown", "GET")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("portfolio"))
}

///|
test "@routes.route_request returns 404 for unknown path" {
  let response = @routes.route_request("/api/unknown", "GET")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("Not found"))
}

///|
test "@routes.route_request handles stock code with numbers" {
  let response = @routes.route_request("/api/stocks/12345/klines", "GET")
  assert_true(response.status_code == 400)
  assert_true(response.body.contains("Invalid stock code"))
}

///|
test "@routes.handle_request parses full HTTP request" {
  let request = "GET /api/health HTTP/1.1\nHost: localhost\nConnection: keep-alive\n\n"
  let response = @routes.handle_request(request)
  assert_true(response.status_code == 200)
}

///|
test "@routes.handle_request handles POST method" {
  let request = "POST /api/backtest HTTP/1.1\nContent-Type: application/json\nContent-Length: 0\n\n"
  let response = @routes.handle_request(request)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("started"))
}
