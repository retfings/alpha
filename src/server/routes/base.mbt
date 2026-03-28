/// Routes subpackage base module
///
/// This module defines the HttpResponse type, make_response function,
/// and routing helper utilities.

///|
/// HTTP Response structure
pub struct HttpResponse {
  status_code : Int
  body : String
  content_type : String
} derive(Show, ToJson)

///|
/// Create HTTP response
pub fn make_response(status_code : Int, body : String) -> HttpResponse {
  HttpResponse::{ status_code, body, content_type: "application/json" }
}

///|
/// Create HTTP response with custom content type
pub fn make_html_response(body : String) -> HttpResponse {
  HttpResponse::{
    status_code: 200,
    body,
    content_type: "text/html; charset=utf-8",
  }
}

///|
/// Create HTTP response with custom content type
pub fn make_response_with_type(
  status_code : Int,
  body : String,
  content_type : String,
) -> HttpResponse {
  HttpResponse::{ status_code, body, content_type }
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
/// Get path without query string
pub fn get_path_without_query(path : String) -> String {
  let parts = path.split("?")
  let parts_arr = parts.to_array()
  if parts_arr.length() > 0 {
    parts_arr[0].to_string()
  } else {
    path
  }
}

///|
/// Extract query string from path
pub fn extract_query_string(path : String) -> String? {
  let parts = path.split("?")
  let parts_arr = parts.to_array()
  if parts_arr.length() > 1 {
    Some(parts_arr[1].to_string())
  } else {
    None
  }
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
