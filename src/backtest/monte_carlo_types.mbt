/// Monte Carlo simulation types
///
/// Types for representing Monte Carlo simulation results and configurations.

///|
/// Monte Carlo simulation mode
pub enum MonteCarloMode {
  /// Shuffle trade order randomly
  TradeShuffle
  /// Randomly skip trades with given probability
  TradeSkip
  /// Add random noise to trade prices
  SlippageNoise
  // Bootstrap and Combined reserved for future implementation
} derive(Show, Eq)

///|
/// Monte Carlo simulation configuration
pub struct MonteCarloConfig {
  /// Simulation mode
  mode : MonteCarloMode
  /// Number of simulation runs
  num_runs : Int
  /// Skip probability (for TradeSkip mode, 0.0-1.0)
  skip_probability : Float
  /// Maximum slippage noise (for SlippageNoise mode, e.g., 0.01 for 1%)
  max_slippage : Float
  /// Random seed for reproducibility (None = use system seed)
  seed : Int?
} derive(Show)

///|
/// Create default Monte Carlo configuration
pub fn default_monte_carlo_config() -> MonteCarloConfig {
  MonteCarloConfig::{
    mode: MonteCarloMode::TradeShuffle,
    num_runs: 100,
    skip_probability: 0.1,
    max_slippage: 0.005,
    seed: None,
  }
}

///|
/// Create Monte Carlo config for trade shuffling
pub fn trade_shuffle_config(num_runs : Int) -> MonteCarloConfig {
  MonteCarloConfig::{
    mode: MonteCarloMode::TradeShuffle,
    num_runs,
    skip_probability: 0.0,
    max_slippage: 0.0,
    seed: None,
  }
}

///|
/// Create Monte Carlo config for trade skipping
pub fn trade_skip_config(num_runs : Int, skip_prob : Float) -> MonteCarloConfig {
  MonteCarloConfig::{
    mode: MonteCarloMode::TradeSkip,
    num_runs,
    skip_probability: skip_prob,
    max_slippage: 0.0,
    seed: None,
  }
}

///|
/// Create Monte Carlo config for slippage noise
pub fn slippage_noise_config(
  num_runs : Int,
  max_slip : Float,
) -> MonteCarloConfig {
  MonteCarloConfig::{
    mode: MonteCarloMode::SlippageNoise,
    num_runs,
    skip_probability: 0.0,
    max_slippage: max_slip,
    seed: None,
  }
}

///|
/// Single Monte Carlo run result
/// Reserved for future Monte Carlo simulation implementation
pub struct MonteCarloRun {
  /// Run index
  run_id : Int
  /// Total return
  total_return : Float
  /// Max drawdown
  max_drawdown : Float
  /// Sharpe ratio
  sharpe_ratio : Float
  /// Final capital
  final_capital : Float
  /// Number of trades executed
  num_trades : Int
  /// Whether this run was profitable
  is_profitable : Bool
} derive(Show)

///|
/// Helper function to create a MonteCarloRun instance
/// Reserved for future Monte Carlo simulation implementation
pub fn create_monte_carlo_run(
  run_id : Int,
  total_return : Float,
  max_drawdown : Float,
  sharpe_ratio : Float,
  final_capital : Float,
  num_trades : Int,
  is_profitable : Bool,
) -> MonteCarloRun {
  MonteCarloRun::{
    run_id,
    total_return,
    max_drawdown,
    sharpe_ratio,
    final_capital,
    num_trades,
    is_profitable,
  }
}

///|
/// Monte Carlo simulation summary statistics
pub struct MonteCarloSummary {
  /// Number of simulation runs
  num_runs : Int
  /// Mean total return
  mean_return : Float
  /// Median total return
  median_return : Float
  /// Standard deviation of returns
  std_return : Float
  /// Minimum return (worst case)
  min_return : Float
  /// Maximum return (best case)
  max_return : Float
  /// Return at 5th percentile (95% confidence lower bound)
  percentile_5 : Float
  /// Return at 95th percentile (95% confidence upper bound)
  percentile_95 : Float
  /// Percentage of profitable runs
  profit_rate : Float
  /// Mean max drawdown
  mean_drawdown : Float
  /// Worst max drawdown
  worst_drawdown : Float
  /// Mean Sharpe ratio
  mean_sharpe : Float
  /// Percentage of runs exceeding original backtest return
  beat_original_rate : Float
  /// Robustness score (0-100, higher = more robust)
  robustness_score : Float
  /// Original backtest return for comparison
  original_return : Float
} derive(Show)

///|
/// Create empty Monte Carlo summary
pub fn create_monte_carlo_summary(original_return : Float) -> MonteCarloSummary {
  MonteCarloSummary::{
    num_runs: 0,
    mean_return: 0.0,
    median_return: 0.0,
    std_return: 0.0,
    min_return: 0.0,
    max_return: 0.0,
    percentile_5: 0.0,
    percentile_95: 0.0,
    profit_rate: 0.0,
    mean_drawdown: 0.0,
    worst_drawdown: 0.0,
    mean_sharpe: 0.0,
    beat_original_rate: 0.0,
    robustness_score: 0.0,
    original_return,
  }
}

///|
/// Monte Carlo simulation result
/// Reserved for future Monte Carlo simulation implementation
pub struct MonteCarloResult {
  /// Individual run results
  runs : Array[MonteCarloRun]
  /// Summary statistics
  summary : MonteCarloSummary
  /// Configuration used
  config : MonteCarloConfig
} derive(Show)

///|
/// Helper function to create a MonteCarloResult instance
/// Reserved for future Monte Carlo simulation implementation
pub fn create_monte_carlo_result(
  runs : Array[MonteCarloRun],
  summary : MonteCarloSummary,
  config : MonteCarloConfig,
) -> MonteCarloResult {
  MonteCarloResult::{ runs, summary, config }
}
