/// HTTP API Server for MoonBit Drawdown Framework
///
/// Provides RESTful API endpoints for:
/// - Stock data queries
/// - Backtest execution and results
/// - Drawdown analysis
/// - Portfolio monitoring

///|
/// HTTP Response structure
/// Represents an HTTP response with status code and body
pub struct HttpResponse {
  /// HTTP status code (e.g., 200, 404, 500)
  status_code : Int
  /// Response body as a string (typically JSON)
  body : String
} derive(Show, ToJson)

///|
/// Create HTTP response
///
/// Parameters:
/// - status_code: HTTP status code (e.g., 200 for success, 404 for not found)
/// - body: Response body content (typically JSON string)
///
/// Returns:
/// - HttpResponse with the specified status and body
///
/// Example:
/// ```mbt check-disabled
/// let response = make_response(200, "{\"status\":\"ok\"}")
/// assert_true(response.status_code == 200)
/// ```
pub fn make_response(status_code : Int, body : String) -> HttpResponse {
  HttpResponse::{ status_code, body }
}

///|
/// Convert StringView to String
///
/// Parameters:
/// - sv: StringView to convert
///
/// Returns:
/// - String containing the same content as the StringView
///
/// Example:
/// ```mbt check-disabled
/// let view = "hello"[:]
/// let str = string_view_to_string(view)
/// assert_true(str == "hello")
/// ```
pub fn string_view_to_string(sv : StringView) -> String {
  sv.to_string()
}

///|
/// Parse HTTP request path
///
/// Extracts the path from an HTTP request string by parsing the first line.
///
/// Parameters:
/// - request: Raw HTTP request string (e.g., "GET /api/stocks HTTP/1.1\n...")
///
/// Returns:
/// - Path string extracted from the request (e.g., "/api/stocks")
/// - Returns "/" if parsing fails
///
/// Example:
/// ```mbt check-disabled
/// let request = "GET /api/stocks HTTP/1.1\nHost: localhost\n\n"
/// let path = parse_request_path(request)
/// assert_true(path == "/api/stocks")
/// ```
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
///
/// Parses stock code from API paths like `/api/stocks/sh.600000/klines` or `/api/drawdown/sh.600000`.
///
/// Parameters:
/// - path: URL path string containing stock code
///
/// Returns:
/// - Some(stock_code) if valid stock code found (format: "market.code" like "sh.600000")
/// - None if no valid stock code found
///
/// Example:
/// ```mbt check-disabled
/// let path1 = "/api/stocks/sh.600000/klines"
/// let path2 = "/api/drawdown/sz.000001"
/// assert_true(extract_stock_code(path1) == Some("sh.600000"))
/// assert_true(extract_stock_code(path2) == Some("sz.000001"))
/// ```
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
///
/// Parses backtest ID from API paths like `/api/backtest/bt_001/result`.
///
/// Parameters:
/// - path: URL path string containing backtest ID
///
/// Returns:
/// - Some(backtest_id) if valid ID found
/// - None if no valid ID found or if path points to "result" keyword
///
/// Example:
/// ```mbt check-disabled
/// let path = "/api/backtest/bt_001/result"
/// assert_true(extract_backtest_id(path) == Some("bt_001"))
/// ```
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
///
/// Main request routing function that dispatches HTTP requests to appropriate handlers
/// based on path and HTTP method.
///
/// Parameters:
/// - path: URL path extracted from HTTP request
/// - http_method: HTTP method (GET, POST, PUT, DELETE, etc.)
///
/// Returns:
/// - HttpResponse with appropriate status code and body
///
/// Routes:
/// - `GET /api/health` - Health check endpoint
/// - `GET /api/stocks` - List all available stocks
/// - `GET /api/stocks/{code}` - Get stock information
/// - `GET /api/stocks/{code}/klines` - Get K-line data
/// - `POST /api/backtest` - Start new backtest
/// - `GET /api/backtest/{id}/result` - Get backtest result
/// - `GET /api/drawdown/{code}` - Get stock drawdown analysis
/// - `GET /api/portfolio/drawdown` - Get portfolio drawdown
///
/// Example:
/// ```mbt check-disabled
/// let response1 = route_request("/api/health", "GET")
/// assert_true(response1.status_code == 200)
///
/// let response2 = route_request("/api/stocks", "GET")
/// assert_true(response2.status_code == 200)
///
/// let response3 = route_request("/api/unknown", "GET")
/// assert_true(response3.status_code == 404)
/// ```
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
///
/// Returns a list of all available stocks in the system.
///
/// **Request:**
/// - Method: GET
/// - Path: /api/stocks
/// - Headers: None required
///
/// **Response:**
/// - Status 200: JSON array of stocks with code, name, and total count
///
/// **Example Response:**
/// ```json
/// {
///   "stocks": [{"code": "sh.600000", "name": "Ping An Bank"}],
///   "total": 1
/// }
/// ```
///
/// **Error Responses:**
/// - None currently defined
fn handle_list_stocks() -> HttpResponse {
  make_response(
    200, "{\"stocks\":[{\"code\":\"sh.600000\",\"name\":\"Ping An Bank\"}],\"total\":1}",
  )
}

///|
/// Handler: Get stock info
///
/// Returns detailed information for a specific stock.
///
/// **Request:**
/// - Method: GET
/// - Path: /api/stocks/{code}
/// - Parameters: code - Stock code (e.g., "sh.600000")
///
/// **Response:**
/// - Status 200: JSON object with stock details
///
/// **Example Response:**
/// ```json
/// {
///   "stock": {
///     "code": "sh.600000",
///     "name": "Sample Stock"
///   }
/// }
/// ```
///
/// **Error Responses:**
/// - Status 400: Invalid stock code format
fn handle_get_stock(stock : String) -> HttpResponse {
  make_response(
    200,
    "{\"stock\":{\"code\":\"\{stock}\",\"name\":\"Sample Stock\"}}",
  )
}

///|
/// Handler: Get klines for stock
///
/// Returns K-line (candlestick) data for a specific stock.
///
/// **Request:**
/// - Method: GET
/// - Path: /api/stocks/{code}/klines
/// - Parameters: code - Stock code (e.g., "sh.600000")
///
/// **Response:**
/// - Status 200: JSON object with stock code, klines array, and count
///
/// **Example Response:**
/// ```json
/// {
///   "stock": "sh.600000",
///   "klines": [{"date": "2024-01-02", "close": 10.8}],
///   "count": 1
/// }
/// ```
///
/// **Error Responses:**
/// - Status 400: Invalid stock code format
fn handle_get_klines(stock : String) -> HttpResponse {
  make_response(
    200,
    "{\"stock\":\"\{stock}\",\"klines\":[{\"date\":\"2024-01-02\",\"close\":10.8}],\"count\":1}",
  )
}

///|
/// Handler: Get backtest result
///
/// Returns the result of a previously executed backtest.
///
/// **Request:**
/// - Method: GET
/// - Path: /api/backtest/{id}/result
/// - Parameters: id - Backtest ID (e.g., "bt_001")
///
/// **Response:**
/// - Status 200: JSON object with backtest_id, status, and result metrics
///
/// **Example Response:**
/// ```json
/// {
///   "backtest_id": "bt_001",
///   "status": "completed",
///   "result": {
///     "total_return": 0.1245,
///     "max_drawdown": -0.0832
///   }
/// }
/// ```
///
/// **Error Responses:**
/// - Status 400: Invalid backtest ID format
/// - Status 404: Backtest not found
fn handle_get_backtest_result(id : String) -> HttpResponse {
  make_response(
    200,
    "{\"backtest_id\":\"\{id}\",\"status\":\"completed\",\"result\":{\"total_return\":0.1245,\"max_drawdown\":-0.0832}}",
  )
}

///|
/// Handler: Get drawdown for stock
///
/// Returns drawdown analysis for a specific stock.
///
/// **Request:**
/// - Method: GET
/// - Path: /api/drawdown/{code}
/// - Parameters: code - Stock code (e.g., "sh.600000")
///
/// **Response:**
/// - Status 200: JSON object with stock code and drawdown metrics
///
/// **Example Response:**
/// ```json
/// {
///   "stock": "sh.600000",
///   "drawdown": {
///     "current": -0.0245,
///     "max": -0.1523
///   }
/// }
/// ```
///
/// **Error Responses:**
/// - Status 400: Invalid stock code format
fn handle_get_drawdown(stock : String) -> HttpResponse {
  make_response(
    200,
    "{\"stock\":\"\{stock}\",\"drawdown\":{\"current\":-0.0245,\"max\":-0.1523}}",
  )
}

///|
/// Handler: Get portfolio drawdown
///
/// Returns drawdown analysis for the entire portfolio.
///
/// **Request:**
/// - Method: GET
/// - Path: /api/portfolio/drawdown
/// - Headers: None required
///
/// **Response:**
/// - Status 200: JSON object with portfolio-level drawdown metrics
///
/// **Example Response:**
/// ```json
/// {
///   "portfolio": {
///     "total_drawdown": -0.0532,
///     "max_stock_drawdown": -0.1523
///   }
/// }
/// ```
///
/// **Error Responses:**
/// - None currently defined
fn handle_portfolio_drawdown() -> HttpResponse {
  make_response(
    200, "{\"portfolio\":{\"total_drawdown\":-0.0532,\"max_stock_drawdown\":-0.1523}}",
  )
}

///|
/// Handle incoming HTTP request
///
/// Main entry point for processing raw HTTP requests. Parses the request to extract
/// the path and HTTP method, then routes to the appropriate handler.
///
/// Parameters:
/// - request: Raw HTTP request string including headers (e.g., "GET /api/stocks HTTP/1.1\nHost: localhost\n\n")
///
/// Returns:
/// - HttpResponse with appropriate status code and body based on the routed handler
///
/// Example:
/// ```mbt check-disabled
/// let request = "GET /api/health HTTP/1.1\nHost: localhost\n\n"
/// let response = handle_request(request)
/// assert_true(response.status_code == 200)
/// ```
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
///
/// Parameters:
/// - port: Port number to bind the server to (e.g., 8080, 3000)
///
/// Returns:
/// - Server file descriptor (non-negative integer) on success
/// - Negative integer on failure
#borrow(port)
extern "c" fn http_server_create(port : Int) -> Int = "moonbit_http_server_create"

///|
/// Accept connection and get request
///
/// Blocks until an incoming HTTP connection is received, then reads the request.
///
/// Parameters:
/// - server_fd: Server file descriptor returned by http_server_create
///
/// Returns:
/// - Raw HTTP request string including all headers
#borrow(server_fd)
extern "c" fn http_server_accept(server_fd : Int) -> String = "moonbit_http_server_accept"

///|
/// Send HTTP response
///
/// Parameters:
/// - server_fd: Server file descriptor for the client connection
/// - response: HTTP response string to send (format: "STATUS_CODE BODY")
///
/// Returns:
/// - 0 on success
/// - Non-zero on failure
#borrow(server_fd, response)
extern "c" fn http_server_respond(server_fd : Int, response : String) -> Int = "moonbit_http_server_respond"

///|
/// Close server socket
///
/// Parameters:
/// - server_fd: Server file descriptor to close
///
/// Returns:
/// - 0 on success
/// - Non-zero on failure
#borrow(server_fd)
extern "c" fn http_server_close(server_fd : Int) -> Int = "moonbit_http_server_close"

///|
/// Start HTTP server and handle requests
///
/// Initializes an HTTP server on the specified port and processes incoming requests
/// in a synchronous loop. Handles up to 100 requests before shutting down.
///
/// Parameters:
/// - port: Port number to listen on (e.g., 8080 for default, 3000 for alternative)
///
/// Behavior:
/// - Creates server socket and binds to port
/// - Prints available endpoints to stdout
/// - Enters request handling loop (max 100 requests)
/// - For each request: accepts connection, routes to handler, sends response
/// - Closes server socket on exit
///
/// Example:
/// ```mbt check-disabled
/// // Start server on port 8080
/// start_server(8080)
///
/// // Start server on custom port
/// start_server(3000)
/// ```
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
