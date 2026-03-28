/// HTTP Server module tests

///|
test "parse_request_path extracts path from GET request" {
  let request = "GET /api/health HTTP/1.1\nHost: localhost\n\n"
  let path = @routes.parse_request_path(request)
  assert_true(path == "/api/health")
}

///|
test "parse_request_path extracts path from POST request" {
  let request = "POST /api/backtest HTTP/1.1\nContent-Type: application/json\n\n"
  let path = @routes.parse_request_path(request)
  assert_true(path == "/api/backtest")
}

///|
test "parse_request_path returns root for empty request" {
  let request = ""
  let path = @routes.parse_request_path(request)
  assert_true(path == "/")
}

///|
test "parse_request_path returns root for malformed request" {
  let request = "INVALID\n\n"
  let path = @routes.parse_request_path(request)
  assert_true(path == "/")
}

///|
test "extract_stock_code from klines path" {
  let path = "/api/stocks/sh.600000/klines"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sh.600000"))
}

///|
test "extract_stock_code from stock info path" {
  let path = "/api/stocks/sz.000001"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sz.000001"))
}

///|
test "extract_stock_code from drawdown path" {
  let path = "/api/drawdown/sh.600000"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sh.600000"))
}

///|
test "extract_stock_code returns None for invalid path" {
  let path = "/api/health"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == None)
}

///|
test "extract_stock_code handles multiple stocks in path" {
  let path = "/api/stocks/sh.600000/compare/sz.000001"
  let stock = @routes.extract_stock_code(path)
  assert_true(stock == Some("sh.600000"))
}

///|
test "extract_backtest_id from result path" {
  let path = "/api/backtest/bt_123/result"
  let id = @routes.extract_backtest_id(path)
  assert_true(id == Some("bt_123"))
}

///|
test "extract_backtest_id returns None for base path" {
  let path = "/api/backtest"
  let id = @routes.extract_backtest_id(path)
  assert_true(id == None)
}

///|
test "extract_backtest_id returns None for unrelated path" {
  let path = "/api/health"
  let id = @routes.extract_backtest_id(path)
  assert_true(id == None)
}

///|
test "route_request health endpoint" {
  let response = @routes.route_request("/api/health", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("moonbit-drawdown"))
}

///|
test "route_request list stocks endpoint" {
  let response = @routes.route_request("/api/stocks", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
}

///|
test "route_request get stock info endpoint" {
  let response = @routes.route_request("/api/stocks/sh.600000", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
}

///|
test "route_request get klines endpoint" {
  let response = @routes.route_request(
    "/api/stocks/sh.600000/klines", "GET", "",
  )
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("klines"))
}

///|
test "route_request start backtest endpoint" {
  let response = @routes.route_request("/api/backtest", "POST", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("started"))
}

///|
test "route_request get backtest result endpoint" {
  let response = @routes.route_request("/api/backtest/bt_001/result", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("bt_001"))
}

///|
test "route_request get drawdown endpoint" {
  let response = @routes.route_request("/api/drawdown/sh.600000", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("drawdown"))
}

///|
test "route_request portfolio drawdown endpoint" {
  let response = @routes.route_request("/api/portfolio/drawdown", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("portfolio"))
}

///|
test "route_request returns 404 for unknown path" {
  let response = @routes.route_request("/api/unknown", "GET", "")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("Not found"))
}

///|
test "route_request handles stock code with numbers" {
  // Note: "invalid" starts with 'i' which is a-z, so it's considered valid
  // Use a path without stocks keyword to trigger 400
  let response = @routes.route_request("/api/stocks/12345/klines", "GET", "")
  assert_true(response.status_code == 400)
  assert_true(response.body.contains("Invalid stock code"))
}

///|
test "handle_request parses full HTTP request" {
  let request = "GET /api/health HTTP/1.1\nHost: localhost\nConnection: keep-alive\n\n"
  let response = @routes.handle_request(request)
  assert_true(response.status_code == 200)
}

///|
test "handle_request handles POST method" {
  let request = "POST /api/backtest HTTP/1.1\nContent-Type: application/json\nContent-Length: 0\n\n"
  let response = @routes.handle_request(request)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("started"))
}

///|
test "route_request health endpoint response body" {
  let response = @routes.route_request("/api/health", "GET", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"status":"ok","service":"moonbit-drawdown"}
    ),
  )
}

///|
test "route_request list stocks response body" {
  let response = @routes.route_request("/api/stocks", "GET", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"stocks":[{"code":"sh.600000","name":"Stock 600000","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600001","name":"Stock 600001","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600002","name":"Stock 600002","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600003","name":"Stock 600003","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600004","name":"Stock 600004","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600005","name":"Stock 600005","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600006","name":"Stock 600006","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600007","name":"Stock 600007","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600008","name":"Stock 600008","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600009","name":"Stock 600009","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600010","name":"Stock 600010","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600011","name":"Stock 600011","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600012","name":"Stock 600012","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600015","name":"Stock 600015","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600016","name":"Stock 600016","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600017","name":"Stock 600017","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600018","name":"Stock 600018","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600019","name":"Stock 600019","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"},{"code":"sh.600020","name":"Stock 600020","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"}],"total":19}
    ),
  )
}

///|
test "route_request get stock info response body" {
  let response = @routes.route_request("/api/stocks/sh.600000", "GET", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"code":"sh.600000","name":"Stock 600000","industry":"Banking","market":"SH","list_date":"1990-01-01","status":"active"}
    ),
  )
}

///|
test "route_request get klines response body" {
  let response = @routes.route_request(
    "/api/stocks/sh.600000/klines", "GET", "",
  )
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"stock":"sh.600000","klines":[{"date":"2026-03-27","open":10.5,"high":11.0,"low":10.3,"close":10.8,"volume":1000000.0,"amount":10800000.0,"turn":0.05}],"count":1}
    ),
  )
}

///|
test "route_request backtest start response body" {
  let response = @routes.route_request("/api/backtest", "POST", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"status":"started","backtest_id":"bt_001"}
    ),
  )
}

///|
test "route_request backtest result response body" {
  let response = @routes.route_request("/api/backtest/bt_123/result", "GET", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"backtest_id":"bt_123","status":"completed","result":{"initial_capital":100000.0,"final_capital":112450.0,"total_return":0.1245,"max_drawdown":-0.0832,"sharpe_ratio":1.25,"total_trades":24,"win_rate":0.625}}
    ),
  )
}

///|
test "route_request drawdown response body" {
  let response = @routes.route_request("/api/drawdown/sh.600000", "GET", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"stock":"sh.600000","drawdown":{"current":-0.0245,"max":-0.1523}}
    ),
  )
}

///|
test "route_request portfolio drawdown response body" {
  let response = @routes.route_request("/api/portfolio/drawdown", "GET", "")
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"portfolio":{"total_drawdown":-0.0532,"max_stock_drawdown":-0.1523}}
    ),
  )
}

///|
test "route_request 404 response body" {
  let response = @routes.route_request("/api/unknown", "GET", "")
  assert_true(response.status_code == 404)
  inspect(
    response.body,
    content=(
      #|{"error":"Not found","path":"/api/unknown"}
    ),
  )
}

///|
test "route_request 400 invalid stock code response body" {
  let response = @routes.route_request("/api/stocks//klines", "GET", "")
  assert_true(response.status_code == 400)
  inspect(
    response.body,
    content=(
      #|{"error":"Invalid stock code"}
    ),
  )
}

///|
test "route_request 400 invalid backtest id response body" {
  let response = @routes.route_request("/api/backtest//result", "GET", "")
  assert_true(response.status_code == 400)
  inspect(
    response.body,
    content=(
      #|{"error":"Invalid backtest ID"}
    ),
  )
}

///|
test "handle_request full GET health request response" {
  let request = "GET /api/health HTTP/1.1\nHost: localhost:8080\nUser-Agent: TestClient\n\n"
  let response = @routes.handle_request(request)
  assert_true(response.status_code == 200)
  inspect(
    response.body,
    content=(
      #|{"status":"ok","service":"moonbit-drawdown"}
    ),
  )
}
