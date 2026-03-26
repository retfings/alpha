/// HTTP Server for Quantitative Drawdown Framework
///
/// Provides REST API endpoints and serves static web files.

///|
/// API Response wrapper
pub struct ApiResponse {
  success : Bool
  data : String?
  error : String?
} derive(ToJson)

///|
/// Create success response
pub fn api_success(data : String) -> ApiResponse {
  ApiResponse::{ success: true, data: Some(data), error: None }
}

///|
/// Create error response
pub fn api_error(msg : String) -> ApiResponse {
  ApiResponse::{ success: false, data: None, error: Some(msg) }
}

///|
/// Get list of available strategies
pub fn get_strategies() -> String {
  let strategies = [
    ("ma_cross", "MA Crossover Strategy", "Moving average crossover trend following"),
    ("momentum", "RSI Momentum Strategy", "RSI-based mean reversion strategy"),
  ]

  "[" +
  strategies.map(fn(s) {
    "{\"id\": \"" + s.0 + "\", \"name\": \"" + s.1 + "\", \"description\": \"" + s.2 + "\"}"
  }).join(",") +
  "]"
}

///|
/// Get list of sample stocks
pub fn get_stocks() -> String {
  let stocks = [
    ("sh.600000", "Pudong Development Bank"),
    ("sh.600036", "China Merchants Bank"),
    ("sz.000001", "Ping An Bank"),
    ("sz.000002", "China Vanke"),
  ]

  "[" +
  stocks.map(fn(s) {
    "{\"code\": \"" + s.0 + "\", \"name\": \"" + s.1 + "\"}"
  }).join(",") +
  "]"
}

///|
/// Get list of drawdown calculations
pub fn get_drawdowns() -> String {
  let drawdowns = [
    ("max_drawdown", "Maximum Drawdown", "Largest peak-to-trough decline"),
    ("current_drawdown", "Current Drawdown", "Drawdown from most recent peak"),
    ("drawdown_duration", "Drawdown Duration", "Time spent in drawdown"),
  ]

  "[" +
  drawdowns.map(fn(d) {
    "{\"id\": \"" + d.0 + "\", \"name\": \"" + d.1 + "\", \"description\": \"" + d.2 + "\"}"
  }).join(",") +
  "]"
}

///|
/// Server configuration
pub struct ServerConfig {
  host : String
  port : Int
  static_dir : String
}

///|
/// Create default server config
pub fn default_server_config() -> ServerConfig {
  ServerConfig::{
    host: "127.0.0.1",
    port: 8080,
    static_dir: "www",
  }
}

///|
/// Start HTTP server
/// Note: Actual server requires MoonBit HTTP runtime or external server.
pub fn start_server(config : ServerConfig) -> Result[Unit, String] {
  let msg = "Server starting on " + config.host + ":" + config.port.to_string()
  // In production, this would bind to the port and handle requests
  Ok(())
}

///|
/// Serve static file
pub fn serve_static_file(path : String) -> Result[String, String] {
  match path {
    "/" => Ok("index.html")
    _ => Err("File not found".to_string())
  }
}
