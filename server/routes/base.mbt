/// Routes subpackage base module
///
/// This module defines the HttpResponse type and make_response function
/// to avoid circular dependency with the parent server package.

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
