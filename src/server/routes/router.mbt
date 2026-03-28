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
/// Handler: Get content type based on file extension
pub fn get_content_type(file_path : String) -> String {
  if file_path.has_suffix(".html") {
    "text/html; charset=utf-8"
  } else if file_path.has_suffix(".css") {
    "text/css"
  } else if file_path.has_suffix(".js") {
    "application/javascript"
  } else if file_path.has_suffix(".json") {
    "application/json"
  } else if file_path.has_suffix(".png") {
    "image/png"
  } else if file_path.has_suffix(".jpg") || file_path.has_suffix(".jpeg") {
    "image/jpeg"
  } else if file_path.has_suffix(".svg") {
    "image/svg+xml"
  } else {
    "text/plain"
  }
}

///|
/// Handler: Serve static file from www directory
fn handle_static_file(file_path : String) -> HttpResponse {
  let full_path = "www/" + file_path
  let content_type = get_content_type(file_path)
  match @ffi.read_file(full_path) {
    Some(content) => make_response_with_type(200, content, content_type)
    None =>
      make_response_with_type(
        404, "{\"error\":\"File not found\"}", "application/json",
      )
  }
}

///|
/// Route request to appropriate handler
pub fn route_request(
  path : String,
  http_method : String,
  body : String,
) -> HttpResponse {
  let clean_path = get_path_without_query(path)
  let query = extract_query_string(path)

  // Health check endpoint
  if clean_path == "/api/health" {
    return make_response(
      200, "{\"status\":\"ok\",\"service\":\"moonbit-drawdown\"}",
    )
  }

  // ===== Static Files / Frontend =====
  if clean_path == "/" || clean_path == "/index.html" {
    return handle_static_file("index.html")
  }

  // Serve CSS files
  if clean_path.has_prefix("/") && clean_path.has_suffix(".css") {
    let file = clean_path[1:].to_string()
    return handle_static_file(file)
  }

  // Serve JS files
  if clean_path.has_prefix("/") && clean_path.has_suffix(".js") {
    let file = clean_path[1:].to_string()
    return handle_static_file(file)
  }

  // Serve HTML files
  if clean_path.has_prefix("/") && clean_path.has_suffix(".html") {
    let file = clean_path[1:].to_string()
    return handle_static_file(file)
  }

  // Serve other static files (images, etc.)
  if clean_path.has_prefix("/") &&
    (
      clean_path.has_suffix(".png") ||
      clean_path.has_suffix(".jpg") ||
      clean_path.has_suffix(".jpeg") ||
      clean_path.has_suffix(".svg") ||
      clean_path.has_suffix(".ico")
    ) {
    let file = clean_path[1:].to_string()
    return handle_static_file(file)
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

  // ===== Screening Endpoints =====
  if clean_path == "/api/screen" && http_method == "POST" {
    return handle_screen(Some(body))
  }

  if clean_path == "/api/indicators" && http_method == "GET" {
    return handle_list_indicators()
  }

  if clean_path.has_prefix("/api/indicators/") && http_method == "GET" {
    let id = clean_path[15:].to_string()
    // Check if it's a category request
    if id == "financial" || id == "technical" || id == "market" || id == "all" {
      return handle_get_indicators_by_category(id)
    }
    // Otherwise it's a specific indicator request
    return handle_get_indicator(id)
  }

  if clean_path == "/api/trading-models" && http_method == "GET" {
    return handle_list_trading_models()
  }

  if clean_path == "/api/weights" && http_method == "GET" {
    return handle_get_weights()
  }

  if clean_path == "/api/weights" && http_method == "POST" {
    return handle_set_weights("{}")
  }

  // ===== Trading Model Configuration Endpoints =====
  if clean_path == "/api/trading-models/all" && http_method == "GET" {
    return handle_list_all_trading_models()
  }

  if clean_path == "/api/trading-models/examples" && http_method == "GET" {
    return handle_get_model_examples()
  }

  if clean_path == "/api/trading-models/periodic" && http_method == "POST" {
    return handle_create_periodic_model(None)
  }

  if clean_path == "/api/trading-models/trigger" && http_method == "POST" {
    return handle_create_trigger_model(None)
  }

  if clean_path == "/api/trading-models/trigger-types" && http_method == "GET" {
    return handle_get_trigger_types()
  }

  if clean_path == "/api/trading-models/rebalance-frequencies" &&
    http_method == "GET" {
    return handle_get_rebalance_frequencies()
  }

  // ===== Extended Screener Endpoints =====
  if clean_path == "/api/screener" && http_method == "POST" {
    return handle_screener(Some(body))
  }

  if clean_path == "/api/screener/indicators" && http_method == "GET" {
    return handle_get_all_indicators()
  }

  if clean_path.has_prefix("/api/screener/indicators/") && http_method == "GET" {
    let id = clean_path[25:].to_string()
    return handle_get_indicator_detail(id)
  }

  // ===== Backtest Endpoints =====
  if clean_path == "/api/backtest/run" && http_method == "POST" {
    return handle_run_backtest(body)
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

  // Parse request body for POST/PUT requests
  let body = extract_request_body(request)

  route_request(path, http_method, body)
}

///|
/// Extract request body from HTTP request string
fn extract_request_body(request : String) -> String {
  let lines = request.split("\n").to_array()
  let body_lines : Array[String] = []
  let mut in_body = false

  for line in lines {
    if in_body {
      body_lines.push(line.to_string())
    } else if line.trim() == "" {
      in_body = true
    }
  }

  body_lines.join("\n").trim().to_string()
}
