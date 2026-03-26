/// File I/O FFI bindings
///
/// This module provides low-level file operations using C FFI.
/// For CSV loading, use the higher-level loader.mbt module instead.

///|
/// Read file content as Bytes
/// Returns None if file doesn't exist or can't be read
#borrow(path)
extern "c" fn __read_file_bytes(path : Bytes) -> Bytes? = "moonbit_read_file"

///|
/// Write content to file
/// Returns 0 on success, -1 on failure
#borrow(path, content)
extern "c" fn __write_file_bytes(
  path : Bytes,
  content : Bytes,
  len : Int,
) -> Int = "moonbit_write_file"

///|
/// Check if file exists
/// Returns 1 if exists, 0 otherwise
#borrow(path)
extern "c" fn __file_exists(path : Bytes) -> Int = "moonbit_file_exists"

///|
/// Create directory (including parent directories)
/// Returns 0 on success, -1 on failure
#borrow(path)
extern "c" fn __mkdir_p(path : Bytes) -> Int = "moonbit_mkdir_p"

///|
/// Read file content as String
/// Returns None if file doesn't exist or can't be read
pub fn read_file(path : String) -> String? {
  let path_bytes = @utf8.encode(path)
  match __read_file_bytes(path_bytes) {
    Some(bytes) =>
      // Create string from bytes using encoding module
      Some(@utf8.decode_lossy(bytes))
    None => None
  }
}

///|
/// Write string content to file
/// Returns true on success, false on failure
pub fn write_file(path : String, content : String) -> Bool {
  let path_bytes = @utf8.encode(path)
  let content_bytes = @utf8.encode(content)
  let len = content_bytes.length()
  let result = __write_file_bytes(path_bytes, content_bytes, len)
  result == 0
}

///|
/// Check if file exists
pub fn file_exists(path : String) -> Bool {
  let path_bytes = @utf8.encode(path)
  let result = __file_exists(path_bytes)
  result == 1
}

///|
/// Create directory (including parent directories)
/// Returns true on success, false on failure
pub fn mkdir_p(path : String) -> Bool {
  let path_bytes = @utf8.encode(path)
  let result = __mkdir_p(path_bytes)
  result == 0
}

///|
/// Read CSV file content and return as string
/// Helper function for CSV loader
pub fn read_csv_file(path : String) -> String? {
  read_file(path)
}

///|
/// Get environment variable value
/// Returns None if variable is not set
#borrow(name)
extern "c" fn __getenv(name : Bytes) -> Bytes? = "moonbit_getenv"

///|
/// Get environment variable as String
pub fn getenv(name : String) -> String? {
  let name_bytes = @utf8.encode(name)
  match __getenv(name_bytes) {
    Some(bytes) => Some(@utf8.decode_lossy(bytes))
    None => None
  }
}
