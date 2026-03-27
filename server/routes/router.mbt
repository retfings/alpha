/// HTTP request routing
///
/// Routes incoming HTTP requests to appropriate handlers.

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
/// Route request to appropriate handler
pub fn route_request(path : String, http_method : String) -> HttpResponse {
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
    return handle_list_strategies()
  }

  if clean_path.has_prefix("/api/strategies/") && http_method == "GET" {
    let id = clean_path[16:].to_string()
    return handle_get_strategy(id)
  }

  if clean_path.has_prefix("/api/strategies/") && http_method == "DELETE" {
    let id = clean_path[16:].to_string()
    return handle_delete_strategy(id)
  }

  // ===== Stock Endpoints =====
  if clean_path == "/api/stocks" && http_method == "GET" {
    return handle_list_stocks()
  }

  if clean_path == "/api/stocks/filter" && http_method == "GET" {
    return handle_filter_stocks(query)
  }

  if clean_path.has_prefix("/api/stocks/") && clean_path.has_suffix("/klines") {
    let code = extract_stock_code(clean_path)
    match code {
      Some(c) => return handle_get_klines(c)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  if clean_path.has_prefix("/api/stocks/") && !clean_path.contains("/filter") {
    let code = extract_stock_code(clean_path)
    match code {
      Some(c) => return handle_get_stock(c)
      None => return make_response(400, "{\"error\":\"Invalid stock code\"}")
    }
  }

  // ===== Industry Endpoints =====
  if clean_path == "/api/industries" && http_method == "GET" {
    return handle_list_industries()
  }

  if clean_path.has_prefix("/api/industries/") &&
    clean_path.has_suffix("/stocks") {
    let industry = clean_path[16:].to_string()
    let industry_clean = industry.replace(old="/stocks", new="")
    return handle_get_industry_stocks(industry_clean)
  }

  // ===== Backtest Endpoints =====
  if clean_path == "/api/backtest/run" && http_method == "POST" {
    return handle_run_backtest("{}")
  }

  if clean_path == "/api/backtest" && http_method == "GET" {
    return handle_list_backtests()
  }

  if clean_path.has_prefix("/api/backtest/") && clean_path.has_suffix("/result") {
    let id = clean_path[14:].to_string()
    let id_clean = id.replace(old="/result", new="")
    return handle_get_backtest_result(id_clean)
  }

  if clean_path.has_prefix("/api/backtest/") && http_method == "DELETE" {
    let id = clean_path[14:].to_string()
    return handle_delete_backtest(id)
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
pub fn handle_request(request : String) -> HttpResponse {
  let path = parse_request_path(request)
  let lines = request.split("\n").to_array()
  let http_method = if lines.length() > 0 {
    let parts = lines[0].split(" ").to_array()
    if parts.length() > 0 {
      parts[0].to_string()
    } else {
      "GET"
    }
  } else {
    "GET"
  }

  route_request(path, http_method)
}
