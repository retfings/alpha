/// Strategy types and interfaces

///|
/// Trading action
pub(all) enum Action {
  Buy
  Sell
  Hold
} derive(Eq, Show)

///|
/// Trading signal
pub(all) struct Signal {
  stock : @data.StockCode
  action : Action
  price : Float
  timestamp : String
  strength : Float
}

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
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext) -> Signal
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
pub struct BacktestConfig {
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
