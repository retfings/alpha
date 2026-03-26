/// HTTP API Server for MoonBit Drawdown Framework
///
/// Provides RESTful API endpoints for:
/// - Stock data queries
/// - Backtest execution and results
/// - Drawdown analysis
/// - Portfolio monitoring

///|
/// HTTP Response structure
pub struct HttpResponse {
  status_code : Int
  body : String
} derive(Show, ToJson)

///|
/// Create HTTP response
pub fn make_response(status_code : Int, body : String) -> HttpResponse {
  HttpResponse::{ status_code, body }
}

///|
/// Convert StringView to String
pub fn string_view_to_string(sv : StringView) -> String {
  sv.to_string()
}

///|
/// Parse HTTP request path
pub fn parse_request_path(request : String) -> String {
  let lines = request.split("\n").to_array()
  if lines.length() > 0 {
    let first_line = lines[0]
    let parts = first_line.split(" ").to_array()
    if parts.length() >= 2 {
      return string_view_to_string(parts[1])
    }
  }
  "/"
}

///|
/// Extract stock code from path like /api/stocks/sh.600000/klines or /api/drawdown/sh.600000
pub fn extract_stock_code(path : String) -> String? {
  let parts = path.split("/").to_array()
  let mut i = 0
  while i < parts.length() {
    // Check for /api/stocks/{code} pattern
    if parts[i] == "stocks" && i + 1 < parts.length() {
      let candidate = string_view_to_string(parts[i + 1])
      // Skip if it's a keyword or empty
      if candidate == "klines" || candidate == "compare" || candidate == "" {
        i = i + 1
        continue
      }
      // Validate stock code format (must contain '.' like sh.600000)
      if candidate.contains(".") {
        return Some(candidate)
      }
      // Invalid stock code format
      return None
    }
    // Check for /api/drawdown/{code} pattern
    if parts[i] == "drawdown" && i + 1 < parts.length() {
      let candidate = string_view_to_string(parts[i + 1])
      if candidate != "" && candidate.contains(".") {
        return Some(candidate)
      }
    }
    i = i + 1
  }
  None
}

///|
/// Extract backtest ID from path
pub fn extract_backtest_id(path : String) -> String? {
  let parts = path.split("/").to_array()
  let mut i = 0
  while i < parts.length() {
    if parts[i] == "backtest" && i + 1 < parts.length() {
      let candidate = string_view_to_string(parts[i + 1])
      if candidate != "result" && candidate != "" {
        return Some(candidate)
      }
    }
    i = i + 1
  }
  None
}

///|
/// Route request to appropriate handler
pub fn route_request(path : String, http_method : String) -> HttpResponse {
  if path == "/api/health" {
    return make_response(
      200, "{\"status\":\"ok\",\"service\":\"moonbit-drawdown\"}",
    )
  }

  if path == "/api/stocks" && http_method == "GET" {
    return handle_list_stocks()
  }

  if path.contains("/api/stocks/") && path.contains("/klines") {
    match extract_stock_code(path) {
      Some(stock) => return handle_get_klines(stock)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  if path.has_prefix("/api/stocks/") && !path.contains("/klines") {
    match extract_stock_code(path) {
      Some(stock) => return handle_get_stock(stock)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  if path == "/api/backtest" && http_method == "POST" {
    return make_response(
      200, "{\"status\":\"started\",\"backtest_id\":\"bt_001\"}",
    )
  }

  if path.contains("/api/backtest/") && path.contains("/result") {
    match extract_backtest_id(path) {
      Some(id) => return handle_get_backtest_result(id)
      None => return make_response(400, "{\"error\":\"Invalid backtest ID\"}")
    }
  }

  if path.has_prefix("/api/drawdown/") {
    match extract_stock_code(path) {
      Some(stock) => return handle_get_drawdown(stock)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  if path == "/api/portfolio/drawdown" {
    return handle_portfolio_drawdown()
  }

  make_response(404, "{\"error\":\"Not found\",\"path\":\"\{path}\"}")
}

///|
/// Handler: List available stocks
fn handle_list_stocks() -> HttpResponse {
  make_response(
    200, "{\"stocks\":[{\"code\":\"sh.600000\",\"name\":\"Ping An Bank\"}],\"total\":1}",
  )
}

///|
/// Handler: Get stock info
fn handle_get_stock(stock : String) -> HttpResponse {
  make_response(
    200,
    "{\"stock\":{\"code\":\"\{stock}\",\"name\":\"Sample Stock\"}}",
  )
}

///|
/// Handler: Get klines for stock
fn handle_get_klines(stock : String) -> HttpResponse {
  make_response(
    200,
    "{\"stock\":\"\{stock}\",\"klines\":[{\"date\":\"2024-01-02\",\"close\":10.8}],\"count\":1}",
  )
}

///|
/// Handler: Get backtest result
fn handle_get_backtest_result(id : String) -> HttpResponse {
  make_response(
    200,
    "{\"backtest_id\":\"\{id}\",\"status\":\"completed\",\"result\":{\"total_return\":0.1245,\"max_drawdown\":-0.0832}}",
  )
}

///|
/// Handler: Get drawdown for stock
fn handle_get_drawdown(stock : String) -> HttpResponse {
  make_response(
    200,
    "{\"stock\":\"\{stock}\",\"drawdown\":{\"current\":-0.0245,\"max\":-0.1523}}",
  )
}

///|
/// Handler: Get portfolio drawdown
fn handle_portfolio_drawdown() -> HttpResponse {
  make_response(
    200, "{\"portfolio\":{\"total_drawdown\":-0.0532,\"max_stock_drawdown\":-0.1523}}",
  )
}

///|
/// Handle incoming HTTP request
pub fn handle_request(request : String) -> HttpResponse {
  let path = parse_request_path(request)
  let lines = request.split("\n").to_array()
  let http_method = if lines.length() > 0 {
    let parts = lines[0].split(" ").to_array()
    if parts.length() > 0 {
      string_view_to_string(parts[0])
    } else {
      "GET"
    }
  } else {
    "GET"
  }

  route_request(path, http_method)
}

// FFI Functions

///|
/// Create HTTP server socket
#borrow(port)
extern "c" fn http_server_create(port : Int) -> Int = "moonbit_http_server_create"

///|
/// Accept connection and get request
#borrow(server_fd)
extern "c" fn http_server_accept(server_fd : Int) -> String = "moonbit_http_server_accept"

///|
/// Send HTTP response
#borrow(server_fd, response)
extern "c" fn http_server_respond(server_fd : Int, response : String) -> Int = "moonbit_http_server_respond"

///|
/// Close server socket
#borrow(server_fd)
extern "c" fn http_server_close(server_fd : Int) -> Int = "moonbit_http_server_close"

///|
/// Start HTTP server and handle requests
pub fn start_server(port : Int) -> Unit {
  println("Starting HTTP server on port \{port}")

  let server_fd = http_server_create(port)
  if server_fd < 0 {
    println("Failed to create server socket")
    return
  }

  println("Server listening on port \{port}")
  println("Endpoints:")
  println("  GET  /api/health              - Health check")
  println("  GET  /api/stocks              - List stocks")
  println("  GET  /api/stocks/:code        - Get stock info")
  println("  GET  /api/stocks/:code/klines - Get klines")
  println("  POST /api/backtest            - Start backtest")
  println("  GET  /api/backtest/:id/result - Get result")
  println("  GET  /api/drawdown/:code      - Get drawdown")
  println("  GET  /api/portfolio/drawdown  - Portfolio drawdown")
  println("")
  println("Press Ctrl+C to stop")
  println("")

  let mut request_count = 0
  while request_count < 100 {
    request_count = request_count + 1

    // Accept incoming connection
    let request = http_server_accept(server_fd)

    // Handle request and get response
    let response_obj = handle_request(request)

    // Send response
    let response_str = "\{response_obj.status_code} \{response_obj.body}"
    let _ = http_server_respond(server_fd, response_str)

    println("Request \{request_count}: \{response_obj.status_code}")
  }

  let _ = http_server_close(server_fd)
  println("Server stopped")
}
