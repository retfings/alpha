/// HTTP request routing and path parsing

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
/// Extract stock code from path
pub fn extract_stock_code(path : String) -> String? {
  let parts = path.split("/").to_array()
  let mut i = 0
  while i < parts.length() {
    if parts[i] == "stocks" && i + 1 < parts.length() {
      let candidate = string_view_to_string(parts[i + 1])
      if candidate == "klines" || candidate == "compare" || candidate == "" {
        i = i + 1
        continue
      }
      if candidate.contains(".") {
        return Some(candidate)
      }
      return None
    }
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
