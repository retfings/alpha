# API Reference

Complete API reference for the MoonBit Quantitative Drawdown Framework.

## Modules

- [@data](#data-module) - Data types and CSV loader
- [@indicator](#indicator-module) - Technical indicators
- [@portfolio](#portfolio-module) - Portfolio management
- [@risk](#risk-module) - Risk management
- [@drawdown](#drawdown-module) - Drawdown calculation
- [@strategy](#strategy-module) - Strategy engine
- [@backtest](#backtest-module) - Backtest engine

---

## @data Module

Data types and CSV loader for quantitative trading.

### Types

#### KLine

K-line (candlestick) data structure.

```mbt
pub struct KLine {
  code : StockCode      // Stock code (e.g., "sh.600000")
  date : String         // Trading date (YYYY-MM-DD)
  time : String?        // Optional time for minute data
  open : Float          // Opening price
  high : Float          // Highest price
  low : Float           // Lowest price
  close : Float         // Closing price
  volume : Float        // Trading volume
  amount : Float        // Trading amount (CNY)
  turn : Float          // Turnover rate (%)
}
```

#### StockCode

```mbt
pub type StockCode = String
```

#### Frequency

```mbt
pub enum Frequency {
  Daily, Weekly, Monthly, Minute5, Minute15, Minute30, Minute60
}
```

### Functions

#### parse_csv_content

Parse CSV string content into K-line array.

```mbt
pub fn parse_csv_content(content : String) -> Result[Array[KLine], String]
```

#### kline_to_csv_line

Convert K-line to CSV format string.

```mbt
pub fn kline_to_csv_line(kline : KLine) -> String
```

#### extract_stock_code_from_filename

Extract stock code from filename.

```mbt
pub fn extract_stock_code_from_filename(filename : String) -> String?
```

---

## @indicator Module

Technical analysis indicators library.

### Functions

#### sma

Calculate Simple Moving Average.

```mbt
pub fn sma(values : Array[Float], period : Int) -> Array[Float]
```

**Parameters:**
- `values`: Array of prices
- `period`: Number of periods to average

**Returns:** Array of SMA values (leading periods filled with 0.0)

#### ema

Calculate Exponential Moving Average.

```mbt
pub fn ema(values : Array[Float], period : Int) -> Array[Float]
```

#### rsi

Calculate Relative Strength Index.

```mbt
pub fn rsi(values : Array[Float], period : Int) -> Array[Float]
```

**Parameters:**
- `values`: Array of prices
- `period`: Number of periods (typically 14)

**Returns:** Array of RSI values (0-100 range)

#### macd

Calculate MACD indicator.

```mbt
pub fn macd(
  values : Array[Float],
  fast_period : Int,    // Typically 12
  slow_period : Int,    // Typically 26
  signal_period : Int,  // Typically 9
) -> (Array[Float], Array[Float], Array[Float])
```

**Returns:** Tuple of (MACD line, Signal line, Histogram)

#### bollinger_bands

Calculate Bollinger Bands.

```mbt
pub fn bollinger_bands(
  values : Array[Float],
  period : Int,      // Typically 20
  std_dev : Float,   // Typically 2.0
) -> (Array[Float], Array[Float], Array[Float])
```

**Returns:** Tuple of (upper_band, middle_band, lower_band)

#### atr

Calculate Average True Range.

```mbt
pub fn atr(klines : Array[KLine], period : Int) -> Array[Float]
```

---

## @portfolio Module

Portfolio and position management.

### Types

#### Position

```mbt
pub struct Position {
  stock : StockCode
  mut quantity : Float
  mut avg_cost : Float
  mut current_price : Float
}
```

#### Portfolio

```mbt
pub struct Portfolio {
  positions : Array[Position]
  mut cash : Float
  initial_capital : Float
}
```

### Functions

#### create_portfolio

```mbt
pub fn create_portfolio(initial_capital : Float) -> Portfolio
```

### Position Methods

- `value() -> Float` - Calculate position market value
- `pnl() -> Float` - Calculate unrealized P&L
- `pnl_pct() -> Float` - Calculate P&L percentage

### Portfolio Methods

- `total_value() -> Float` - Get total portfolio value
- `position_value() -> Float` - Get total position value
- `position_ratio() -> Float` - Get position ratio
- `total_pnl() -> Float` - Get total P&L
- `total_pnl_pct() -> Float` - Get total P&L percentage
- `buy(stock, quantity, price) -> Bool` - Buy stock
- `sell(stock, quantity, price) -> Bool` - Sell stock
- `update_prices(get_price) -> Unit` - Update current prices

---

## @risk Module

Risk management rules engine.

### Types

#### RiskAction

```mbt
pub enum RiskAction {
  Allow
  Reject
  ReducePosition(Float)
  StopTrading
}
```

#### RiskResult

```mbt
pub struct RiskResult {
  passed : Bool
  message : String
  action : RiskAction
}
```

#### RiskRule

```mbt
pub struct RiskRule {
  name : String
  priority : Int
  check_fn : (Float, Float, Float) -> RiskResult
}
```

#### RiskEngine

```mbt
pub struct RiskEngine {
  rules : Array[RiskRule]
  mut stopped : Bool
  violations : Array[String]
}
```

### Functions

#### create_risk_engine

```mbt
pub fn create_risk_engine() -> RiskEngine
```

### Built-in Rules

- `max_drawdown_rule(max_pct : Float) -> RiskRule`
- `position_limit_rule(max_pct : Float) -> RiskRule`
- `daily_loss_limit_rule(max_pct : Float) -> RiskRule`
- `stop_loss_rule(stock : String, max_loss_pct : Float) -> RiskRule`
- `single_stock_limit_rule(max_pct : Float) -> RiskRule`
- `take_profit_rule(min_profit_pct : Float) -> RiskRule`
- `default_rules() -> Array[RiskRule]`

### RiskEngine Methods

- `add_rule(rule : RiskRule) -> Unit`
- `check(drawdown, position_ratio, daily_loss) -> RiskResult`

---

## @drawdown Module

Drawdown calculation and monitoring.

### Types

#### DrawdownInfo

```mbt
pub struct DrawdownInfo {
  peak : Float
  trough : Float
  peak_date : String
  trough_date : String
  drawdown : Float
  duration : Int
  recovered : Bool
}
```

#### DrawdownLevel

```mbt
pub enum DrawdownLevel {
  Normal, Minor, Moderate, Significant, Severe
}
```

#### DrawdownAlert

```mbt
pub struct DrawdownAlert {
  warning_threshold : Float
  critical_threshold : Float
  max_threshold : Float
}
```

#### DrawdownMonitor

```mbt
pub struct DrawdownMonitor {
  mut peak_value : Float
  mut peak_date : String
  mut current_value : Float
  mut current_drawdown : Float
  warning_threshold : Float
  critical_threshold : Float
  mut alert_triggered : Bool
  mut last_alert_level : String
}
```

### Functions

#### calculate_max_drawdown

```mbt
pub fn calculate_max_drawdown(values : Array[Float]) -> Float
```

#### calculate_max_drawdown_detailed

```mbt
pub fn calculate_max_drawdown_detailed(
  values : Array[Float],
  dates : Array[String],
) -> DrawdownInfo?
```

#### calculate_drawdown_series

```mbt
pub fn calculate_drawdown_series(values : Array[Float]) -> Array[Float]
```

#### calculate_current_drawdown

```mbt
pub fn calculate_current_drawdown(values : Array[Float]) -> Float
```

#### get_drawdown_stats

```mbt
pub fn get_drawdown_stats(values : Array[Float]) -> DrawdownStats
```

#### create_monitor

```mbt
pub fn create_monitor(
  warning_threshold : Float,
  critical_threshold : Float,
) -> DrawdownMonitor
```

#### classify_drawdown

```mbt
pub fn classify_drawdown(drawdown : Float) -> DrawdownLevel
```

#### default_alert_config

```mbt
pub fn default_alert_config() -> DrawdownAlert
```

#### check_drawdown_alert

```mbt
pub fn check_drawdown_alert(
  drawdown : Float,
  config : DrawdownAlert,
) -> String
```

### DrawdownMonitor Methods

- `update(value, date) -> Unit`
- `get_drawdown() -> Float`
- `get_info() -> DrawdownInfo`
- `is_alert_triggered() -> Bool`
- `get_alert_level() -> String`
- `reset() -> Unit`

---

## @strategy Module

Strategy engine and built-in strategies.

### Types

#### Action

```mbt
pub enum Action {
  Buy, Sell, Hold
}
```

#### Signal

```mbt
pub struct Signal {
  stock : StockCode
  action : Action
  price : Float
  timestamp : String
  strength : Float
}
```

#### StrategyContext

```mbt
pub struct StrategyContext {
  capital : Float
  position : Float
  current_price : Float
  last_signal : Signal?
}
```

#### Strategy

```mbt
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (KLine, StrategyContext, Array[Float]) -> Signal
}
```

#### StrategyEngine

```mbt
pub struct StrategyEngine {
  capital : Float
  position : Float
  last_price : Float
  signals : Array[Signal]
  results : Array[StrategyResult]
}
```

#### BacktestConfig

```mbt
pub struct BacktestConfig {
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
  benchmark : StockCode?
}
```

### Functions

#### create_strategy

```mbt
pub fn create_strategy(
  name : String,
  on_init : (StrategyContext) -> Unit,
  on_bar : (KLine, StrategyContext, Array[Float]) -> Signal,
) -> Strategy
```

#### create_ma_cross_strategy

```mbt
pub fn create_ma_cross_strategy(
  fast_period : Int,
  slow_period : Int,
) -> MaCrossStrategy
```

#### default_backtest_config

```mbt
pub fn default_backtest_config() -> BacktestConfig
```

### Signal Functions

- `Signal::buy(stock, price, timestamp, strength) -> Signal`
- `Signal::sell(stock, price, timestamp, strength) -> Signal`
- `Signal::hold(stock, price, timestamp) -> Signal`
- `Signal::with_action(stock, action, price, timestamp, strength) -> Signal`

### StrategyEngine Functions

- `create_strategy_engine(initial_capital : Float) -> StrategyEngine`
- `process_bar(engine, strategy, kline, close_history) -> (StrategyResult, StrategyEngine)`
- `execute_signal(engine, result, volume) -> (StrategyEngine, Bool)`
- `get_engine_stats(engine) -> (Float, Float, Int)`
- `get_portfolio_value(engine) -> Float`
- `get_total_return(engine, initial_capital) -> Float`
- `get_trade_count(engine) -> Int`

---

## @backtest Module

Backtest engine and result reporting.

### Types

#### Trade

```mbt
pub struct Trade {
  stock : StockCode
  action : Action
  price : Float
  quantity : Float
  timestamp : String
  commission : Float
}
```

#### EquityPoint

```mbt
pub struct EquityPoint {
  date : String
  equity : Float
  drawdown : Float
  position : Float
  cash : Float
}
```

#### BacktestStats

```mbt
pub struct BacktestStats {
  total_return : Float
  annual_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  sortino_ratio : Float
  win_rate : Float
  profit_factor : Float
  total_trades : Int
  winning_trades : Int
  losing_trades : Int
  avg_win : Float
  avg_loss : Float
  avg_trade_duration : Float
}
```

#### BacktestResult

```mbt
pub struct BacktestResult {
  initial_capital : Float
  final_capital : Float
  total_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  total_trades : Int
  equity_curve : Array[EquityPoint]
  trades : Array[Trade]
  stats : BacktestStats
}
```

#### ReportFormat

```mbt
pub enum ReportFormat {
  Html, Text
}
```

#### ReportConfig

```mbt
pub struct ReportConfig {
  title : String
  author : String
  date : String
  format : ReportFormat
  include_equity_curve : Bool
  include_trades : Bool
  include_stats : Bool
}
```

### Functions

#### create_backtest_engine

```mbt
pub fn create_backtest_engine(config : BacktestConfig) -> BacktestEngine
```

#### run_backtest

```mbt
pub fn run_backtest(
  engine : BacktestEngine,
  klines : Array[KLine],
  strategy : Strategy,
) -> BacktestResult
```

#### generate_report

```mbt
pub fn generate_report(
  result : BacktestResult,
  config : ReportConfig,
) -> String
```

#### print_report

```mbt
pub fn print_report(
  result : BacktestResult,
  format? : ReportFormat = ReportFormat::Text,
) -> Unit
```

#### default_report_config

```mbt
pub fn default_report_config() -> ReportConfig
```

---

## Index

### A
- Action (type)
- atr() - Calculate Average True Range
- avg_trade_duration (field)
- amount (field)
- action (field)
- add() - Add entry to trade log
- add_rule() - Add risk rule to engine
- annual_return (field)
- author (field)
- action_to_string() - Convert action to string
- avg_loss (field)
- avg_win (field)

### B
- BacktestConfig (type)
- BacktestEngine (type)
- BacktestResult (type)
- BacktestStats (type)
- bollinger_bands() - Calculate Bollinger Bands
- buy() - Buy stock or add to position

### C
- calculate_current_drawdown() - Calculate current drawdown from peak
- calculate_drawdown_series() - Calculate drawdown at each point
- calculate_max_drawdown() - Calculate maximum drawdown
- calculate_max_drawdown_detailed() - Calculate max drawdown with details
- calculate_stats_with_state() - Calculate backtest statistics
- check() - Evaluate risk rules
- check_drawdown_alert() - Check drawdown against thresholds
- classify_drawdown() - Classify drawdown severity
- close (field)
- code (field)
- commission (field)
- commission_rate (field)
- commentary (field)
- config (field)
- create_backtest_engine() - Create backtest engine
- create_ma_cross_strategy() - Create MA crossover strategy
- create_monitor() - Create drawdown monitor
- create_momentum_strategy() - Create momentum strategy
- create_portfolio() - Create new portfolio
- create_risk_engine() - Create risk engine
- create_strategy() - Create strategy
- create_trade_log() - Create empty trade log
- current_date (field)
- current_drawdown (field)
- current_equity (field)
- current_price (field)

### D
- daily_loss_limit_rule() - Daily loss limit risk rule
- date (field)
- default_alert_config() - Default alert configuration
- default_backtest_config() - Default backtest configuration
- default_report_config() - Default report configuration
- default_rules() - Default risk rules
- drawdown (field)
- DrawdownAlert (type)
- DrawdownInfo (type)
- DrawdownLevel (type)
- DrawdownMonitor (type)
- drawdown_count (field)

### E
- ema() - Calculate Exponential Moving Average
- end_date (field)
- entries (field)
- equity (field)
- EquityPoint (type)
- execute_signal() - Execute trading signal
- executed (field)
- exec_price (field)
- exec_volume (field)
- extract_stock_code_from_filename() - Extract stock code from filename

### F
- fast_period (field)
- final_capital (field)
- format() - Report format
- format_pct() - Format percentage
- Frequency (type)

### G
- generate_report() - Generate backtest report
- generate_result_with_state() - Generate backtest result
- get_alert_level() - Get alert level
- get_drawdown() - Get current drawdown
- get_drawdown_stats() - Get drawdown statistics
- get_engine_stats() - Get engine statistics
- get_info() - Get drawdown info
- get_portfolio_value() - Get portfolio value
- get_total_return() - Get total return
- get_trade_count() - Get trade count

### H
- high (field)

### I
- include_equity_curve (field)
- include_stats (field)
- include_trades (field)
- initial_capital (field)
- is_alert_triggered() - Check if alert triggered
- is_overbought() - Check if overbought
- is_oversold() - Check if oversold

### K
- kline_to_csv_line() - Convert KLine to CSV
- KLine (type)

### L
- last_alert_level (field)
- last_price (field)
- last_signal (field)
- losing_trades (field)
- low (field)

### M
- macd() - Calculate MACD indicator
- ma_cross.mbt - MA Crossover Strategy
- max_drawdown (field)
- max_drawdown_rule() - Max drawdown risk rule
- momentum.mbt - Momentum Strategy
- max_threshold (field)

### N
- name (field)

### O
- OHLCV (type)
- on_bar (field)
- on_init (field)
- open (field)
- oversold_threshold (field)
- overbought_threshold (field)

### P
- parse_csv_content() - Parse CSV content to KLines
- peak (field)
- peak_date (field)
- peak_equity (field)
- peak_value (field)
- period (field)
- position (field)
- position_limit_rule() - Position limit risk rule
- position_ratio (field)
- position_value (field)
- positions (field)
- Portfolio (type)
- Position (type)
- print_report() - Print report to stdout
- process_bar() - Process bar through strategy
- profit_factor (field)
- pnl() - Calculate position P&L
- pnl_pct() - Calculate position P&L percentage

### Q
- quantity (field)

### R
- ReportConfig (type)
- ReportFormat (type)
- risk_action_allow() - Create Allow action
- risk_action_reduce_position() - Create ReducePosition action
- risk_action_reject() - Create Reject action
- risk_action_stop_trading() - Create StopTrading action
- risk_result_fail() - Create failing RiskResult
- risk_result_pass() - Create passing RiskResult
- RiskAction (type)
- RiskEngine (type)
- RiskResult (type)
- RiskRule (type)
- rsi() - Calculate Relative Strength Index
- run_backtest() - Run backtest on data
- rules (field)

### S
- sell() - Sell stock or reduce position
- sharpe_ratio (field)
- Signal (type)
- single_stock_limit_rule() - Single stock position limit rule
- slippage (field)
- sma() - Calculate Simple Moving Average
- sortino_ratio (field)
- start_date (field)
- stats (field)
- std_dev (field)
- stop_loss_rule() - Stop loss risk rule
- stopped (field)
- Strategy (type)
- StrategyContext (type)
- StrategyEngine (type)
- StrategyInfo (type)
- StrategyResult (type)
- stock (field)
- StockCode (type)
- strength (field)

### T
- take_profit_rule() - Take profit risk rule
- text (field)
- time (field)
- timestamp (field)
- title (field)
- total_capital (field)
- total_pnl() - Get total portfolio P&L
- total_pnl_pct() - Get total portfolio P&L percentage
- total_position_value (field)
- total_return (field)
- total_trades (field)
- total_value() - Get total portfolio value
- Trade (type)
- TradeLog (type)
- TradeLogEntry (type)
- trades (field)
- trough (field)
- trough_date (field)

### U
- update() - Update monitor with new value
- update_prices() - Update position prices
- upper_band (field)

### V
- value() - Calculate position value
- violations (field)
- volume (field)

### W
- warning_threshold (field)
- win_rate (field)
- winning_trades (field)

### B
- BacktestConfig (type)
- BacktestEngine (type)
- BacktestResult (type)
- BacktestStats (type)
- bollinger_bands()

### C
- calculate_current_drawdown()
- calculate_drawdown_series()
- calculate_max_drawdown()
- calculate_max_drawdown_detailed()
- check_drawdown_alert()
- classify_drawdown()
- create_backtest_engine()
- create_ma_cross_strategy()
- create_monitor()
- create_portfolio()
- create_risk_engine()
- create_strategy()

### D
- daily_loss_limit_rule()
- default_alert_config()
- default_backtest_config()
- default_report_config()
- default_rules()
- DrawdownAlert (type)
- DrawdownInfo (type)
- DrawdownLevel (type)
- DrawdownMonitor (type)

### E
- ema()
- EquityPoint (type)
- execute_signal()
- extract_stock_code_from_filename()

### F
- Frequency (type)

### G
- generate_report()
- get_alert_level()
- get_drawdown_stats()
- get_engine_stats()
- get_portfolio_value()
- get_total_return()
- get_trade_count()

### K
- kline_to_csv_line()
- KLine (type)

### M
- macd()
- max_drawdown_rule()

### P
- parse_csv_content()
- position_limit_rule()
- Portfolio (type)
- Position (type)
- print_report()
- process_bar()

### R
- ReportConfig (type)
- ReportFormat (type)
- RiskAction (type)
- RiskEngine (type)
- RiskResult (type)
- RiskRule (type)
- rsi()
- run_backtest()

### S
- Signal (type)
- single_stock_limit_rule()
- sma()
- stop_loss_rule()
- Strategy (type)
- StrategyContext (type)
- StrategyEngine (type)
- StockCode (type)

### T
- take_profit_rule()
- Trade (type)

### Update (2026-03-27)
- Added comprehensive docstrings to all public APIs
- Created README.mbt.md for each package
- Generated this API reference documentation
