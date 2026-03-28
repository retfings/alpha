/// Router Tests
///
/// Tests for HTTP request routing and path parsing utilities

///|
test "parse_request_path extracts path from simple GET" {
  let request = "GET /api/health HTTP/1.1\n\n"
  let path = parse_request_path(request)
  assert_true(path == "/api/health")
}

///|
test "parse_request_path extracts path with query string" {
  let request = "GET /api/stocks?page=1 HTTP/1.1\n\n"
  let path = parse_request_path(request)
  assert_true(path == "/api/stocks")
}

///|
test "parse_request_path returns root for empty" {
  let request = ""
  let path = parse_request_path(request)
  assert_true(path == "/")
}

///|
test "parse_request_path handles malformed request" {
  let request = "INVALID\n\n"
  let path = parse_request_path(request)
  assert_true(path == "/")
}

///|
test "parse_request_path handles path without HTTP version" {
  let request = "GET /api/test\n\n"
  let path = parse_request_path(request)
  assert_true(path == "/api/test")
}

///|
test "extract_query_string from URL with query" {
  let path = "/api/stocks?page=1&size=10"
  let query = extract_query_string(path)
  assert_true(query != None)
}

///|
test "extract_query_string from URL without query" {
  let path = "/api/stocks"
  let query = extract_query_string(path)
  assert_true(query == None)
}

///|
test "get_path_without_query removes query string" {
  let path = "/api/stocks?filter=banking"
  let clean = get_path_without_query(path)
  assert_true(clean == "/api/stocks")
}

///|
test "get_path_without_query returns same path without query" {
  let path = "/api/stocks"
  let clean = get_path_without_query(path)
  assert_true(clean == "/api/stocks")
}

///|
test "extract_stock_code from klines path" {
  let path = "/api/stocks/sh.600000/klines"
  let code = extract_stock_code(path)
  assert_true(code == Some("sh.600000"))
}

///|
test "extract_stock_code from simple stock path" {
  let path = "/api/stocks/sh.600000"
  let code = extract_stock_code(path)
  assert_true(code == Some("sh.600000"))
}

///|
test "extract_stock_code from drawdown path" {
  let path = "/api/drawdown/sh.600000"
  let code = extract_stock_code(path)
  assert_true(code == Some("sh.600000"))
}

///|
test "extract_stock_code returns None for health path" {
  let path = "/api/health"
  let code = extract_stock_code(path)
  assert_true(code == None)
}

///|
test "extract_stock_code returns None for stocks list path" {
  let path = "/api/stocks"
  let code = extract_stock_code(path)
  assert_true(code == None)
}

///|
test "extract_backtest_id from result path" {
  let path = "/api/backtest/bt_123/result"
  let id = extract_backtest_id(path)
  assert_true(id == Some("bt_123"))
}

///|
test "extract_backtest_id returns None for base path" {
  let path = "/api/backtest"
  let id = extract_backtest_id(path)
  assert_true(id == None)
}

///|
test "extract_backtest_id returns None for unrelated path" {
  let path = "/api/health"
  let id = extract_backtest_id(path)
  assert_true(id == None)
}

///|
test "route_request health endpoint GET" {
  let response = route_request("/api/health", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("moonbit-drawdown"))
}

///|
test "route_request static files root" {
  let response = route_request("/", "GET", "")
  // Should try to serve index.html or return 404 if file not found
  assert_true(response.status_code == 200 || response.status_code == 404)
}

///|
test "route_request static HTML file" {
  let response = route_request("/index.html", "GET", "")
  // Should try to serve file or return 404
  assert_true(response.status_code == 200 || response.status_code == 404)
}

///|
test "route_request static CSS file" {
  let response = route_request("/styles.css", "GET", "")
  // Should try to serve file or return 404
  assert_true(response.status_code == 200 || response.status_code == 404)
}

///|
test "route_request static JS file" {
  let response = route_request("/app.js", "GET", "")
  // Should try to serve file or return 404
  assert_true(response.status_code == 200 || response.status_code == 404)
}

///|
test "route_request strategies list GET" {
  let response = route_request("/api/strategies", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("strategies"))
}

///|
test "route_request get strategy by id GET" {
  let response = route_request("/api/strategies/ma_cross", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("ma_cross"))
}

///|
test "route_request stocks list GET" {
  let response = route_request("/api/stocks", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
}

///|
test "route_request stocks filter GET" {
  let response = route_request("/api/stocks/filter", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("stocks"))
}

///|
test "route_request get stock info GET" {
  let response = route_request("/api/stocks/sh.600000", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("sh.600000"))
}

///|
test "route_request get klines GET" {
  let response = route_request("/api/stocks/sh.600000/klines", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("klines"))
}

///|
test "route_request industries list GET" {
  let response = route_request("/api/industries", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("industries"))
}

///|
test "route_request get industry stocks GET" {
  let response = route_request("/api/industries/Banking/stocks", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("Banking"))
}

///|
test "route_request backtest run POST" {
  let response = route_request("/api/backtest/run", "POST", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("backtest"))
}

///|
test "route_request backtest list GET" {
  let response = route_request("/api/backtest", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("backtests"))
}

///|
test "route_request get backtest result GET" {
  let response = route_request("/api/backtest/bt_001/result", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("bt_001"))
}

///|
test "route_request get drawdown GET" {
  let response = route_request("/api/drawdown/sh.600000", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("drawdown"))
}

///|
test "route_request portfolio drawdown GET" {
  let response = route_request("/api/portfolio/drawdown", "GET", "")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("portfolio"))
}

///|
test "route_request unknown path returns 404" {
  let response = route_request("/api/unknown/path", "GET", "")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("Not found"))
}

///|
test "route_request invalid stock code returns 400" {
  let response = route_request("/api/stocks//klines", "GET", "")
  assert_true(response.status_code == 400)
  assert_true(response.body.contains("Invalid stock code"))
}

///|
test "route_request invalid backtest id returns 400" {
  let response = route_request("/api/backtest//result", "GET", "")
  assert_true(response.status_code == 400)
  assert_true(response.body.contains("Invalid backtest ID"))
}

///|
test "handle_request parses full GET request" {
  let request = "GET /api/health HTTP/1.1\nHost: localhost\n\n"
  let response = handle_request(request)
  assert_true(response.status_code == 200)
}

///|
test "handle_request parses POST request" {
  let request = "POST /api/backtest HTTP/1.1\nContent-Type: application/json\n\n"
  let response = handle_request(request)
  assert_true(response.status_code == 200)
}

///|
test "make_response creates correct response" {
  let response = make_response(200, "{\"test\":true}")
  assert_true(response.status_code == 200)
  assert_true(response.body == "{\"test\":true}")
}

///|
test "make_response_with_type creates response with content type" {
  let response = make_response_with_type(
    200, "{\"test\":true}", "application/json",
  )
  assert_true(response.status_code == 200)
  assert_true(response.body == "{\"test\":true}")
}

///|
test "get_content_type for HTML" {
  let content_type = get_content_type("index.html")
  assert_true(content_type == "text/html; charset=utf-8")
}

///|
test "get_content_type for CSS" {
  let content_type = get_content_type("styles.css")
  assert_true(content_type == "text/css")
}

///|
test "get_content_type for JS" {
  let content_type = get_content_type("app.js")
  assert_true(content_type == "application/javascript")
}

///|
test "get_content_type for JSON" {
  let content_type = get_content_type("data.json")
  assert_true(content_type == "application/json")
}

///|
test "get_content_type for PNG" {
  let content_type = get_content_type("image.png")
  assert_true(content_type == "image/png")
}

///|
test "get_content_type for JPG" {
  let content_type = get_content_type("image.jpg")
  assert_true(content_type == "image/jpeg")
}

///|
test "get_content_type for JPEG" {
  let content_type = get_content_type("image.jpeg")
  assert_true(content_type == "image/jpeg")
}

///|
test "get_content_type for SVG" {
  let content_type = get_content_type("icon.svg")
  assert_true(content_type == "image/svg+xml")
}

///|
test "get_content_type for unknown extension" {
  let content_type = get_content_type("file.xyz")
  assert_true(content_type == "text/plain")
}
