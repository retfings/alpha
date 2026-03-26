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
pub struct StrategyEngine {
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
/// Process a single bar through the strategy
pub fn process_bar(
  engine : StrategyEngine,
  strategy : Strategy,
  kline : @data.KLine,
) -> StrategyResult {
  let ctx = StrategyContext::{
    capital: engine.capital,
    position: engine.position,
    current_price: kline.close,
    last_signal: engine.signals.last(),
  }

  let signal = (strategy.on_bar)(kline, ctx)
  let executed = false
  let exec_price : Float = 0.0
  let exec_volume : Float = 0.0

  StrategyResult::{ signal, executed, exec_price, exec_volume }
}

///|
/// Get engine statistics
pub fn get_engine_stats(engine : StrategyEngine) -> (Float, Float, Int) {
  (engine.capital, engine.position, engine.signals.length())
}
