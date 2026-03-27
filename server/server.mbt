/// HTTP API Server for MoonBit Drawdown Framework

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

    let request = http_server_accept(server_fd)
    let response_obj = handle_request(request)
    let response_str = "\{response_obj.status_code} \{response_obj.body}"
    let _ = http_server_respond(server_fd, response_str)
    println("Request \{request_count}: \{response_obj.status_code}")
  }

  let _ = http_server_close(server_fd)
  println("Server stopped")
}
