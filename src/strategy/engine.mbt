/// Strategy engine and registry

///|
/// Strategy result for a single period
pub struct StrategyResult {
  signal : Signal
  executed : Bool
  exec_price : Float
  exec_volume : Float
}

///|
/// Strategy engine state
pub(all) struct StrategyEngine {
  capital : Float
  position : Float
  last_price : Float
  signals : Array[Signal]
  results : Array[StrategyResult]
}

///|
/// Create a new strategy engine
pub fn create_strategy_engine(initial_capital : Float) -> StrategyEngine {
  StrategyEngine::{
    capital: initial_capital,
    position: 0.0,
    last_price: 0.0,
    signals: [],
    results: [],
  }
}

///|
/// Append signal to array and return new array
fn append_signal(arr : Array[Signal], elem : Signal) -> Array[Signal] {
  let mut new_arr = arr
  let _ = new_arr.push(elem)
  new_arr
}

///|
/// Append result to array and return new array
fn append_result(arr : Array[StrategyResult], elem : StrategyResult) -> Array[StrategyResult] {
  let mut new_arr = arr
  let _ = new_arr.push(elem)
  new_arr
}

///|
/// Process a single bar through the strategy
pub fn process_bar(
  engine : StrategyEngine,
  strategy : Strategy,
  kline : @data.KLine,
  close_history : Array[Float],
) -> (StrategyResult, StrategyEngine) {
  let ctx = StrategyContext::{
    capital: engine.capital,
    position: engine.position,
    current_price: kline.close,
    last_signal: engine.signals.last(),
  }

  let signal = (strategy.on_bar)(kline, ctx, close_history)
  let executed = false
  let exec_price : Float = 0.0
  let exec_volume : Float = 0.0

  let result = StrategyResult::{ signal, executed, exec_price, exec_volume }

  let updated_engine = StrategyEngine::{
    capital: engine.capital,
    position: engine.position,
    last_price: kline.close,
    signals: append_signal(engine.signals, signal),
    results: append_result(engine.results, result),
  }

  (result, updated_engine)
}

///|
/// Execute a signal (update capital and position)
pub fn execute_signal(
  engine : StrategyEngine,
  result : StrategyResult,
  volume : Float,
) -> (StrategyEngine, Bool) {
  let action = result.signal.action
  let price = result.signal.price

  let (new_capital, new_position, success) = match action {
    Action::Buy => {
      let cost = price * volume
      if cost > engine.capital {
        (engine.capital, engine.position, false)
      } else {
        (engine.capital - cost, engine.position + volume, true)
      }
    }
    Action::Sell =>
      if volume > engine.position {
        (engine.capital, engine.position, false)
      } else {
        (engine.capital + price * volume, engine.position - volume, true)
      }
    Action::Hold => (engine.capital, engine.position, true)
  }

  if success {
    let executed_result = StrategyResult::{
      signal: result.signal,
      executed: true,
      exec_price: price,
      exec_volume: volume,
    }
    let updated_engine = StrategyEngine::{
      capital: new_capital,
      position: new_position,
      last_price: engine.last_price,
      signals: engine.signals,
      results: append_result(engine.results, executed_result),
    }
    (updated_engine, true)
  } else {
    (engine, false)
  }
}

///|
/// Get engine statistics
pub fn get_engine_stats(engine : StrategyEngine) -> (Float, Float, Int) {
  (engine.capital, engine.position, engine.signals.length())
}
