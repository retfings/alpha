///|
/// Alpha module - Quantitative Drawdown Framework
///
/// A MoonBit-based framework for quantitative trading and drawdown analysis
///
/// ## Modules
///
/// - `@data` - Data types and loaders
/// - `@drawdown` - Drawdown calculation and monitoring
/// - `@strategy` - Strategy engine and built-in strategies
/// - `@risk` - Risk management rules
/// - `@portfolio` - Portfolio and position management
/// - `@indicator` - Technical indicators (MA, RSI, MACD, etc.)
/// - `@backtest` - Backtest engine and reporting

// Re-export commonly used types for convenience

// Data types
pub type KLine = @data.KLine

///|
pub type StockCode = @data.StockCode

///|
pub type Frequency = @data.Frequency

// Strategy types

///|
pub type Signal = @strategy.Signal

///|
pub type Action = @strategy.Action

///|
pub type StrategyContext = @strategy.StrategyContext

///|
pub type BacktestConfig = @strategy.BacktestConfig

// Risk types

///|
pub type RiskRule = @risk.RiskRule

///|
pub type RiskResult = @risk.RiskResult

///|
pub type RiskAction = @risk.RiskAction

// Portfolio types

///|
pub type Position = @portfolio.Position

///|
pub type Portfolio = @portfolio.Portfolio

// Backtest types

///|
pub type Trade = @backtest.Trade

///|
pub type EquityPoint = @backtest.EquityPoint

///|
pub type BacktestResult = @backtest.BacktestResult

///|
pub type BacktestStats = @backtest.BacktestStats

// Drawdown types

///|
pub type DrawdownInfo = @drawdown.DrawdownInfo

///|
pub type DrawdownLevel = @drawdown.DrawdownLevel

///|
pub type DrawdownAlert = @drawdown.DrawdownAlert
