///|
/// HTTP API Server for MoonBit Drawdown Framework

// Re-export from routes package
pub type HttpResponse = @routes.HttpResponse

///|
pub fn make_response(status_code : Int, body : String) -> HttpResponse {
  @routes.make_response(status_code, body)
}

///|
pub fn handle_request(request : String) -> HttpResponse {
  @routes.handle_request(request)
}

// FFI Functions

///|
/// Create HTTP server socket
#borrow(port)
extern "c" fn http_server_create(port : Int) -> Int = "moonbit_http_server_create"

///|
/// Accept connection and get request
#borrow(server_fd)
extern "c" fn http_server_accept(server_fd : Int) -> Bytes = "moonbit_http_server_accept"

///|
/// Send HTTP response with status code and content type
#borrow(server_fd, status_code, body, content_type)
extern "c" fn http_server_respond(
  server_fd : Int,
  status_code : Int,
  body : Bytes,
  content_type : Bytes,
) -> Int = "moonbit_http_server_respond"

///|
/// Close server socket
#borrow(server_fd)
extern "c" fn http_server_close(server_fd : Int) -> Int = "moonbit_http_server_close"

///|
/// Start HTTP server and handle requests
pub fn start_server(port : Int) -> Unit {
  println("Starting HTTP server on port \{port}")

  // Initialize stock data cache at startup (pre-load all K-line data)
  println("Initializing stock data cache...")
  let cache = @routes.initialize_stock_cache()
  println("Loaded \{cache.length()} stocks into cache (cached for fast screening)")

  let server_fd = http_server_create(port)
  if server_fd < 0 {
    println("Failed to create server socket")
    return
  }

  println("Server listening on port \{port}")
  println("Endpoints:")
  println("  GET  /api/health              - Health check")
  println("  GET  /api/strategies          - List strategies")
  println("  GET  /api/strategies/:id      - Get strategy")
  println("  GET  /api/stocks              - List stocks")
  println("  GET  /api/stocks/filter       - Filter stocks")
  println("  GET  /api/stocks/:code        - Get stock info")
  println("  GET  /api/stocks/:code/klines - Get klines")
  println("  GET  /api/industries          - List industries")
  println("  GET  /api/industries/:name/stocks - Get industry stocks")
  println("  POST /api/backtest/run        - Run backtest")
  println("  GET  /api/backtest            - List backtests")
  println("  GET  /api/backtest/:id/result - Get result")
  println("  GET  /api/drawdown/:code      - Get drawdown")
  println("  GET  /api/portfolio/drawdown  - Portfolio drawdown")
  println("  POST /api/screener            - Screen stocks with filters (e.g., price > 1)")
  println("")
  println("Press Ctrl+C to stop")
  println("")

  let mut request_count = 0
  while true {
    request_count = request_count + 1
    println("Waiting for request \{request_count}...")

    let request_bytes = http_server_accept(server_fd)
    let request = @utf8.decode_lossy(request_bytes)
    let response_obj = handle_request(request)
    // Convert body String to Bytes for C FFI
    let body_bytes = @utf8.encode(response_obj.body)
    let content_type_bytes = @utf8.encode(response_obj.content_type)
    let _ = http_server_respond(
      server_fd,
      response_obj.status_code,
      body_bytes,
      content_type_bytes,
    )
    println("Request \{request_count}: \{response_obj.status_code}")
  }

  let _ = http_server_close(server_fd)
  println("Server stopped")
}
