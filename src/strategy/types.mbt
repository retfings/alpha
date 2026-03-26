/// Strategy types and interfaces

///|
/// Trading action
pub(all) enum Action {
  Buy
  Sell
  Hold
} derive(Eq, Show, ToJson)

///|
/// Trading signal
pub(all) struct Signal {
  stock : @data.StockCode
  action : Action
  price : Float
  timestamp : String
  strength : Float
} derive(ToJson, Show)

///|
/// Strategy context (passed to strategy during execution)
pub(all) struct StrategyContext {
  capital : Float
  position : Float
  current_price : Float
  last_signal : Signal?
}

///|
/// Strategy type as a record of functions
/// This is an alternative to using traits
pub(all) struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext, Array[Float]) -> Signal
}

///|
/// Strategy metadata
pub struct StrategyInfo {
  name : String
  description : String
  author : String
  version : String
}

///|
/// Backtest configuration
pub(all) struct BacktestConfig {
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
  benchmark : @data.StockCode?
}

///|
/// Default backtest configuration
pub fn default_backtest_config() -> BacktestConfig {
  BacktestConfig::{
    start_date: "",
    end_date: "",
    initial_capital: 100000.0,
    commission_rate: 0.0003,
    slippage: 0.001,
    benchmark: None,
  }
}

///|
/// Create a buy signal
pub fn Signal::buy(
  stock : @data.StockCode,
  price : Float,
  timestamp : String,
  strength : Float,
) -> Signal {
  Signal::{ stock, action: Action::Buy, price, timestamp, strength }
}

///|
/// Create a sell signal
pub fn Signal::sell(
  stock : @data.StockCode,
  price : Float,
  timestamp : String,
  strength : Float,
) -> Signal {
  Signal::{ stock, action: Action::Sell, price, timestamp, strength }
}

///|
/// Create a hold signal
pub fn Signal::hold(
  stock : @data.StockCode,
  price : Float,
  timestamp : String,
) -> Signal {
  Signal::{ stock, action: Action::Hold, price, timestamp, strength: 0.0 }
}

///|
/// Create a signal with custom action
pub fn Signal::with_action(
  stock : @data.StockCode,
  action : Action,
  price : Float,
  timestamp : String,
  strength : Float,
) -> Signal {
  Signal::{ stock, action, price, timestamp, strength }
}
