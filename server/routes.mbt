/// HTTP request routing and path parsing
///
/// This module routes incoming HTTP requests to appropriate handlers.
/// New endpoints are implemented in server/routes/*.mbt files.

import {
  "retfings/alpha/server/routes" @routes,
  "moonbitlang/core/json",
}

///|
/// Extract query string from path
fn extract_query_string(path : String) -> String? {
  let parts = path.split("?")
  let parts_arr = parts.to_array()
  if parts_arr.length() > 1 {
    Some(parts_arr[1].to_string())
  } else {
    None
  }
}

///|
/// Get path without query string
fn get_path_without_query(path : String) -> String {
  let parts = path.split("?")
  let parts_arr = parts.to_array()
  if parts_arr.length() > 0 {
    parts_arr[0].to_string()
  } else {
    path
  }
}

///|
/// Handler: Get drawdown for stock
fn handle_get_drawdown(stock : String) -> @routes.HttpResponse {
  make_response(
    200,
    "{\"stock\":\"\{stock}\",\"drawdown\":{\"current\":-0.0245,\"max\":-0.1523}}",
  )
}

///|
/// Handler: Get portfolio drawdown
fn handle_portfolio_drawdown() -> @routes.HttpResponse {
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
pub fn route_request(path : String, http_method : String) -> @routes.HttpResponse {
  let clean_path = get_path_without_query(path)
  let query = extract_query_string(path)

  // Health check endpoint
  if clean_path == "/api/health" {
    return make_response(
      200, "{\"status\":\"ok\",\"service\":\"moonbit-drawdown\"}",
    )
  }

  // ===== Strategy Endpoints =====
  if clean_path == "/api/strategies" && http_method == "GET" {
    return @routes.handle_list_strategies()
  }

  if clean_path.has_prefix("/api/strategies/") && http_method == "GET" {
    let id = clean_path.substring(16)
    return @routes.handle_get_strategy(id)
  }

  if clean_path.has_prefix("/api/strategies/") && http_method == "DELETE" {
    let id = clean_path.substring(16)
    return @routes.handle_delete_strategy(id)
  }

  // ===== Stock Endpoints =====
  if clean_path == "/api/stocks" && http_method == "GET" {
    return @routes.handle_list_stocks()
  }

  if clean_path == "/api/stocks/filter" && http_method == "GET" {
    return @routes.handle_filter_stocks(query)
  }

  if clean_path.has_prefix("/api/stocks/") && clean_path.has_suffix("/klines") {
    let code = extract_stock_code(clean_path)
    match code {
      Some(c) => return @routes.handle_get_klines(c)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  if clean_path.has_prefix("/api/stocks/") && !clean_path.contains("/filter") {
    let code = extract_stock_code(clean_path)
    match code {
      Some(c) => return @routes.handle_get_stock(c)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  // ===== Industry Endpoints =====
  if clean_path == "/api/industries" && http_method == "GET" {
    return @routes.handle_list_industries()
  }

  if clean_path.has_prefix("/api/industries/") && clean_path.has_suffix("/stocks") {
    let industry = clean_path.substring(16)
    let industry_clean = industry.replace("/stocks", "")
    return @routes.handle_get_industry_stocks(industry_clean)
  }

  // ===== Backtest Endpoints =====
  if clean_path == "/api/backtest/run" && http_method == "POST" {
    return @routes.handle_run_backtest("{}")
  }

  if clean_path == "/api/backtest" && http_method == "GET" {
    return @routes.handle_list_backtests()
  }

  if clean_path.has_prefix("/api/backtest/") && clean_path.has_suffix("/result") {
    let id = clean_path.substring(14)
    let id_clean = id.replace("/result", "")
    return @routes.handle_get_backtest_result(id_clean)
  }

  if clean_path.has_prefix("/api/backtest/") && http_method == "DELETE" {
    let id = clean_path.substring(14)
    return @routes.handle_delete_backtest(id)
  }

  // ===== Drawdown Endpoints =====
  if clean_path.has_prefix("/api/drawdown/") {
    match extract_stock_code(clean_path) {
      Some(stock) => return handle_get_drawdown(stock)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  if clean_path == "/api/portfolio/drawdown" {
    return handle_portfolio_drawdown()
  }

  // 404 for unmatched routes
  make_response(404, "{\"error\":\"Not found\",\"path\":\"\{path}\"}")
}

///|
/// Handle incoming HTTP request
pub fn handle_request(request : String) -> @routes.HttpResponse {
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
