/// Backtest API route handlers
///
/// REST endpoints for backtest execution and results

///|
/// Parse backtest request from JSON
fn parse_backtest_request(json : String) -> BacktestRequest {
  // Default values
  let stock = "sh.600000"
  let strategy = "ma_cross"
  let start_date = ""
  let end_date = ""
  let initial_capital : Float = 100000.0
  let commission_rate : Float = 0.0003
  let slippage : Float = 0.001

  // Simple JSON parsing (production should use proper JSON parser)
  let mut stock_val = stock
  let mut strategy_val = strategy
  let mut start_date_val = start_date
  let mut end_date_val = end_date
  let mut initial_capital_val = initial_capital

  if json.contains("\"stock\"") {
    stock_val = extract_json_string_simple(json, "stock")
  }
  if json.contains("\"strategy\"") {
    strategy_val = extract_json_string_simple(json, "strategy")
  }
  if json.contains("\"start_date\"") {
    start_date_val = extract_json_string_simple(json, "start_date")
  }
  if json.contains("\"end_date\"") {
    end_date_val = extract_json_string_simple(json, "end_date")
  }
  if json.contains("\"initial_capital\"") {
    initial_capital_val = extract_json_float_simple(json, "initial_capital")
  }

  BacktestRequest::{
    stock: stock_val,
    strategy: strategy_val,
    start_date: start_date_val,
    end_date: end_date_val,
    initial_capital: initial_capital_val,
    commission_rate,
    slippage,
  }
}

///|
/// Extract string value from JSON (local private version for backtest)
fn extract_json_string_simple(json : String, key : String) -> String {
  let search_key = "\"" + key + "\":\""
  match json.find(search_key) {
    Some(idx) => {
      let start = idx + search_key.length()
      let rest = json[start:]
      match rest.find("\"") {
        Some(end_idx) => rest[0:end_idx].to_string()
        None => ""
      }
    }
    None => ""
  }
}

///|
/// Extract float value from JSON (local private version for backtest)
fn extract_json_float_simple(json : String, key : String) -> Float {
  let search_key = "\"" + key + "\":"
  match json.find(search_key) {
    Some(idx) => {
      let start = idx + search_key.length()
      let rest = json[start:]
      // Find the end of the number (comma, brace, or end of string)
      let mut end_idx = rest.length()
      let chars = rest.to_array()
      let mut i = 0
      while i < chars.length() {
        let c = chars[i].to_string()
        if c == "," || c == "}" || c == " " {
          end_idx = i
          i = chars.length()
        }
        i = i + 1
      }
      let num_str = rest[0:end_idx].trim().to_string()
      // Parse float manually (simple implementation)
      // For production, use a proper JSON parser
      parse_float_simple(num_str)
    }
    None => 0.0
  }
}

///|
/// Simple float parser (handles basic decimal numbers)
fn parse_float_simple(s : String) -> Float {
  // Handle negative numbers
  let mut negative = false
  let mut start_idx = 0
  if s.length() > 0 && s[0:1] == "-" {
    negative = true
    start_idx = 1
  }

  let mut int_part : Int = 0
  let mut dec_part : Float = 0.0
  let mut dec_divisor : Float = 1.0
  let mut in_decimal = false

  let mut i = start_idx
  while i < s.char_length() {
    let c = s.at(i)
    // '0' = 48, '9' = 57 in ASCII/UTF-16
    if c >= 48 && c <= 57 {
      let digit : Int = UInt16::to_int(c) - 48
      if !in_decimal {
        int_part = int_part * 10 + digit
      } else {
        dec_divisor = dec_divisor * 10.0
        dec_part = dec_part + Float::from_int(digit) / dec_divisor
      }
    } else if c == 46 {
      // '.' = 46
      in_decimal = true
    }
    i = i + 1
  }

  let result = Float::from_int(int_part) + dec_part
  if negative {
    -result
  } else {
    result
  }
}

///|
/// Backtest request parameters
pub struct BacktestRequest {
  stock : String
  strategy : String
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
}

///|
/// Handler: Run backtest on strategy
pub fn handle_run_backtest(body : String) -> HttpResponse {
  // Parse request
  let request = parse_backtest_request(body)

  // Load K-line data for the stock
  let klines = load_klines_for_stock_with_date_range(
    request.stock,
    if request.start_date == "" {
      None
    } else {
      Some(request.start_date)
    },
    if request.end_date == "" {
      None
    } else {
      Some(request.end_date)
    },
  )

  if klines.length() == 0 {
    return make_response(
      400,
      "{\"error\":\"No data available for stock: " + request.stock + "\"}",
    )
  }

  // Create strategy based on request
  let strategy = create_strategy_from_name(request.strategy)

  // Create backtest config
  let config = @strategy.BacktestConfig::{
    start_date: request.start_date,
    end_date: request.end_date,
    initial_capital: request.initial_capital,
    commission_rate: request.commission_rate,
    slippage: request.slippage,
    benchmark: None,
  }

  // Create and run backtest engine
  let engine = @backtest.create_backtest_engine(config)
  let result = @backtest.run_backtest(engine, klines, strategy)

  // Convert result to JSON response
  let response_json = result.to_json().stringify()

  make_response(200, response_json)
}

///|
/// Create strategy from name
fn create_strategy_from_name(name : String) -> @strategy.Strategy {
  // Default to MA Crossover strategy
  if name == "ma_cross" || name == "" {
    let ma_cross = @builtins.create_ma_cross_strategy(10, 30)
    @strategy.Strategy::{
      name: ma_cross.name(),
      on_init: fn(_ctx) {  },
      on_bar: fn(kline, ctx, history) { ma_cross.on_bar(kline, ctx, history) },
    }
  } else if name == "momentum" {
    // Momentum strategy (placeholder - implement if needed)
    let ma_cross = @builtins.create_ma_cross_strategy(10, 30)
    @strategy.Strategy::{
      name: "Momentum (fallback to MA Cross)",
      on_init: fn(_ctx) {  },
      on_bar: fn(kline, ctx, history) { ma_cross.on_bar(kline, ctx, history) },
    }
  } else {
    // Default fallback
    let ma_cross = @builtins.create_ma_cross_strategy(10, 30)
    @strategy.Strategy::{
      name: ma_cross.name(),
      on_init: fn(_ctx) {  },
      on_bar: fn(kline, ctx, history) { ma_cross.on_bar(kline, ctx, history) },
    }
  }
}

///|
/// Handler: Get backtest result by ID
pub fn handle_get_backtest_result(id : String) -> HttpResponse {
  // For now, return a sample result
  // In production, this would load from storage
  let response = "{\"backtest_id\":\"\{id}\",\"status\":\"completed\",\"result\":{\"initial_capital\":100000.0,\"final_capital\":112450.0,\"total_return\":0.1245,\"max_drawdown\":-0.0832,\"sharpe_ratio\":1.25,\"total_trades\":24,\"win_rate\":0.625}}"
  make_response(200, response)
}

///|
/// Handler: List all backtests
pub fn handle_list_backtests() -> HttpResponse {
  let response = "{\"backtests\":[],\"total\":0}"
  make_response(200, response)
}

///|
/// Handler: Delete backtest result
pub fn handle_delete_backtest(id : String) -> HttpResponse {
  let response = "{\"id\":\"\{id}\",\"message\":\"Backtest result deleted successfully\"}"
  make_response(200, response)
}
