/// Strategy API route handlers
///
/// REST endpoints for strategy CRUD operations

///|
/// Built-in strategy definition
pub struct BuiltInStrategy {
  name : String
  description : String
  default_parameters : String
  category : String
}

///|
/// Get all built-in strategies
pub fn get_builtin_strategies() -> Array[BuiltInStrategy] {
  [
    BuiltInStrategy::{
      name: "ma_cross",
      description: "Moving Average Crossover Strategy - generates signals when fast MA crosses slow MA",
      default_parameters: "{\"fast_period\":10,\"slow_period\":30}",
      category: "trend_following",
    },
    BuiltInStrategy::{
      name: "momentum",
      description: "Momentum Strategy - buys stocks with strong recent performance",
      default_parameters: "{\"lookback_period\":20,\"threshold\":0.05}",
      category: "momentum",
    },
    BuiltInStrategy::{
      name: "rsi_mean_reversion",
      description: "RSI Mean Reversion Strategy - buys oversold, sells overbought",
      default_parameters: "{\"rsi_period\":14,\"oversold\":30,\"overbought\":70}",
      category: "mean_reversion",
    },
  ]
}

///|
/// Handler: List all strategies
pub fn handle_list_strategies() -> HttpResponse {
  let builtin = get_builtin_strategies()
  let builtin_json = builtin.map(fn(s) {
    "{\"name\":\"\{s.name}\",\"description\":\"\{s.description}\",\"default_parameters\":\{s.default_parameters},\"category\":\"\{s.category}\"}"
  })

  let all_strategies = builtin_json
  let total = Int::to_string(all_strategies.length())
  let response = "{\"strategies\":[" +
    builtin_json.join(",") +
    "],\"total\":\{total}}"

  make_response(200, response)
}

///|
/// Handler: Get strategy by ID
pub fn handle_get_strategy(id : String) -> HttpResponse {
  for builtin in get_builtin_strategies() {
    if builtin.name == id {
      let response = "{\"id\":\"\{builtin.name}\",\"name\":\"\{builtin.name}\",\"description\":\"\{builtin.description}\",\"parameters\":\{builtin.default_parameters},\"category\":\"\{builtin.category}\",\"is_builtin\":true}"
      return make_response(200, response)
    }
  }

  make_response(404, "{\"error\":\"Strategy not found: \{id}\"}")
}

///|
/// Handler: Create new strategy (placeholder)
pub fn handle_create_strategy(body : String) -> HttpResponse {
  make_response(
    201,
    "{\"message\":\"Strategy creation not yet implemented\",\"body\":\"\{body}\"}",
  )
}

///|
/// Handler: Update strategy (placeholder)
pub fn handle_update_strategy(id : String, body : String) -> HttpResponse {
  make_response(
    200,
    "{\"message\":\"Strategy update not yet implemented\",\"id\":\"\{id}\"}",
  )
}

///|
/// Handler: Delete strategy (placeholder)
pub fn handle_delete_strategy(id : String) -> HttpResponse {
  make_response(
    200,
    "{\"message\":\"Strategy deletion not yet implemented\",\"id\":\"\{id}\"}",
  )
}
