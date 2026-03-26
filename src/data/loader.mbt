/// CSV data loader for stock K-line data
///
/// This module provides functions for parsing CSV-formatted stock data
/// into structured K-line objects for use in backtesting and analysis.

///|
/// Parse a string to Float, returns None if parsing fails
///
/// Note: MoonBit stdlib doesn't have parse_float yet, this is a simple
/// implementation that handles basic integer and decimal formats.
/// Supports negative numbers and decimal points.
fn parse_float(s : StringView) -> Float? {
  // Handle empty string
  if s.length() == 0 {
    return None
  }

  let str = s.to_string()
  let sign : Float = if str.has_prefix("-") { -1.0 } else { 1.0 }
  let start = if str.has_prefix("-") || str.has_prefix("+") { 1 } else { 0 }

  // Find decimal point
  let parts = str.split(".")
  let parts_arr = parts.to_array()

  if parts_arr.length() == 0 {
    return None
  }

  // Parse integer part using while loop
  let int_part_str = parts_arr[0]
  let mut int_val = 0
  let mut i = start
  while i < int_part_str.length() {
    let c : UInt16 = int_part_str.code_unit_at(i)
    if c >= 48 && c <= 57 { // '0' = 48, '9' = 57
      int_val = int_val * 10 + (c.to_int() - 48)
    } else {
      return None
    }
    i = i + 1
  }

  // Parse decimal part if exists
  let mut frac_val : Float = 0.0
  if parts_arr.length() > 1 {
    let frac_str = parts_arr[1]
    let mut multiplier : Float = 0.1
    let mut j = 0
    while j < frac_str.length() {
      let c : UInt16 = frac_str.code_unit_at(j)
      if c >= 48 && c <= 57 {
        let digit = c.to_int() - 48
        frac_val = frac_val + Float::from_int(digit) * multiplier
        multiplier = multiplier * 0.1
      } else {
        return None
      }
      j = j + 1
    }
  }

  Some(sign * (Float::from_int(int_val) + frac_val))
}

///|
/// Load K-line data from a CSV file
///
/// Parameters:
/// - path: Path to the CSV file containing stock data
///
/// Returns:
/// - Ok(Array[KLine]) on successful parse
/// - Err(String) containing error message on failure
///
/// Example usage:
/// ```mbt check-disabled
/// let klines = load_klines_from_csv("data/sh_600000_2023.csv")
/// match klines {
///   Ok(data) => inspect(data.length())
///   Err(e) => inspect(e)
/// }
/// ```
pub fn load_klines_from_csv(path : String) -> Result[Array[KLine], String] {
  // Try to read file using FFI
  match @ffi.read_file(path) {
    Some(content) => parse_csv_content(content)
    None => Err("Failed to read file: \{path}")
  }
}

///|
/// Load K-line data from CSV string content
///
/// Parameters:
/// - content: CSV content as a string (including header row)
///
/// Returns:
/// - Ok(Array[KLine]) on successful parse
/// - Err(String) containing error message on failure
///
/// Expected CSV format:
/// ```text
/// date,open,high,low,close,volume,amount,turn
/// 2023-01-01,10.5,11.0,10.3,10.8,1000000,10800000,0.05
/// 2023-01-02,10.8,11.2,10.6,11.0,1200000,13200000,0.06
/// ```
///
/// Examples:
/// ```mbt nocheck
/// test "parse_csv_content example" {
///   let csv = "date,open,high,low,close,volume,amount,turn\n2023-01-01,10.5,11.0,10.3,10.8,1000000,10800000,0.05"
///   let result = parse_csv_content(csv)
///   assert_true(match result { Ok(_) => true | Err(_) => false })
/// }
/// ```
pub fn parse_csv_content(content : String) -> Result[Array[KLine], String] {
  // Parse CSV content line by line
  if content.length() == 0 {
    return Err("Empty CSV content")
  }

  let lines = content.split("\n")
  let lines_arr = lines.to_array()

  if lines_arr.length() == 0 {
    return Err("Empty CSV content")
  }

  let klines : Array[KLine] = []

  // Skip header line, parse data lines
  let mut i = 1
  while i < lines_arr.length() {
    let line = lines_arr[i]
    match parse_kline_line(line) {
      Some(kline) => klines.push(kline)
      None => {
        let _ = 0
      }
    }
    i = i + 1
  }

  Ok(klines)
}

///|
/// Parse a single CSV line into a KLine
fn parse_kline_line(line : StringView) -> KLine? {
  let fields = line.split(",")
  let field_array = fields.to_array()

  if field_array.length() < 8 {
    return None
  }

  // Extract fields from CSV, trimming whitespace (handles Windows \r\n line endings)
  // Expected format: date,open,high,low,close,volume,amount,turn
  let date = field_array[0].trim()
  let open_str = field_array[1].trim()
  let high_str = field_array[2].trim()
  let low_str = field_array[3].trim()
  let close_str = field_array[4].trim()
  let volume_str = field_array[5].trim()
  let amount_str = field_array[6].trim()
  let turn_str = field_array[7].trim()

  // Check if all numeric conversions succeeded
  let open = parse_float(open_str)
  let high = parse_float(high_str)
  let low = parse_float(low_str)
  let close = parse_float(close_str)
  let volume = parse_float(volume_str)
  let amount = parse_float(amount_str)
  let turn = parse_float(turn_str)

  match (open, high, low, close, volume, amount, turn) {
    (Some(o), Some(h), Some(l), Some(c), Some(v), Some(a), Some(t)) =>
      Some(KLine::{
        code: "",
        date: date.to_string(),
        time: None,
        open: o,
        high: h,
        low: l,
        close: c,
        volume: v,
        amount: a,
        turn: t,
      })
    _ => None
  }
}

///|
/// Convert a KLine to CSV line format
///
/// Parameters:
/// - kline: KLine structure to serialize
///
/// Returns:
/// - CSV-formatted string (without header)
///
/// Output format: date,open,high,low,close,volume,amount,turn
///
/// Examples:
/// ```mbt nocheck
/// test "kline_to_csv_line example" {
///   let kline = KLine::{
///     code: "sh.600000",
///     date: "2023-01-01",
///     time: None,
///     open: 10.5,
///     high: 11.0,
///     low: 10.3,
///     close: 10.8,
///     volume: 1000000.0,
///     amount: 10800000.0,
///     turn: 0.05,
///   }
///   let csv_line = kline_to_csv_line(kline)
///   assert_true(
///     csv_line == "2023-01-01,10.5,11.0,10.3,10.8,1000000,10800000,0.05",
///   )
/// }
/// ```
pub fn kline_to_csv_line(kline : KLine) -> String {
  "\{kline.date},\{kline.open},\{kline.high},\{kline.low},\{kline.close},\{kline.volume},\{kline.amount},\{kline.turn}"
}

///|
/// Extract stock code from filename
///
/// Parses stock code from filename in format:
/// `{exchange}_{code}_{start_date}_{end_date}.csv`
///
/// Parameters:
/// - filename: Full path or just filename
///
/// Returns:
/// - Stock code in format "exchange.code" (e.g., "sh.600000")
/// - None if filename doesn't match expected format
///
/// Examples:
/// ```mbt nocheck
/// extract_stock_code_from_filename("sh_600000_2023-01-01_2023-12-31.csv")
///   // Returns: Some("sh.600000")
/// extract_stock_code_from_filename("/data/sz_000001_2023.csv")
///   // Returns: Some("sz.000001")
/// extract_stock_code_from_filename("invalid.csv")
///   // Returns: None
/// ```
pub fn extract_stock_code_from_filename(filename : String) -> String? {
  let parts = filename.split("/")
  let parts_arr = parts.to_array()
  let file_part = parts_arr.last()

  match file_part {
    Some(f) => {
      let name_parts = f.split("_")
      let name_array = name_parts.to_array()
      if name_array.length() >= 2 {
        let exchange = name_array[0]
        let code_num = name_array[1]
        Some("\{exchange}.\{code_num}")
      } else {
        None
      }
    }
    None => None
  }
}
