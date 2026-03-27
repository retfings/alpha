/// Walk-Forward Analysis Engine
///
/// Walk-Forward Analysis (WFA) is a methodology for validating trading strategies
/// by testing them on multiple out-of-sample periods. This helps detect overfitting
/// and ensures the strategy is robust across different market conditions.
///
/// **Methodology:**
/// 1. Split data into in-sample (optimization) and out-of-sample (validation) periods
/// 2. Optimize strategy parameters on in-sample data
/// 3. Test optimized parameters on out-of-sample data
/// 4. Roll the window forward and repeat
/// 5. Aggregate results to assess strategy robustness

///|
///\n/// Walk-Forward window configuration
///
/// Parameters:
/// - total_bars: Total number of bars in the dataset
/// - window_size: Size of each in-sample window in bars
/// - step_size: Number of bars to roll forward each iteration
/// - oos_ratio: Ratio of out-of-sample data (e.g., 0.2 = 20% OOS)
///
/// Returns:
/// - Array of (in_sample_start, in_sample_end, oos_start, oos_end) tuples
pub fn generate_walk_forward_windows(
  total_bars : Int,
  window_size : Int,
  step_size : Int,
  oos_ratio : Float,
) -> Array[(Int, Int, Int, Int)] {
  let windows : Array[(Int, Int, Int, Int)] = []
  let oos_bars = Float::to_int(Float::from_int(window_size) * oos_ratio)
  let is_bars = window_size - oos_bars

  if is_bars <= 0 {
    windows
  } else {
    let mut start = 0
    while start + window_size <= total_bars {
      let is_start = start
      let is_end = start + is_bars
      let oos_start = is_end
      let oos_end = start + window_size

      windows.push((is_start, is_end, oos_start, oos_end))
      start = start + step_size
    }
    windows
  }
}

///|
///\n/// Walk-Forward mode
pub enum WfMode {
  /// Rolling window: fixed-size window moves forward
  /// Anchored window: in-sample grows, OOS rolls
  Rolling
  Anchored
} derive(Eq, Show)

///|
/// Helper functions to create WfMode values
pub fn wf_mode_rolling() -> WfMode {
  WfMode::Rolling
}

///|
pub fn wf_mode_anchored() -> WfMode {
  WfMode::Anchored
}

///|
///\n/// Walk-Forward configuration
pub struct WalkForwardConfig {
  /// Size of rolling window in bars
  window_size : Int
  /// Step size for rolling forward
  step_size : Int
  /// Out-of-sample ratio (0.0-1.0)
  oos_ratio : Float
  /// Rolling or Anchored mode
  mode : WfMode
  /// Minimum OOS bars required
  min_oos_bars : Int
} derive(Show)

///|
///\n/// Create Walk-Forward configuration
///
/// Parameters:
/// - window_size: Size of each window in bars
/// - step_size: Number of bars to roll forward
/// - oos_ratio: Out-of-sample ratio (e.g., 0.2 for 20%)
/// - mode: Rolling or Anchored mode
/// - min_oos_bars: Minimum OOS bars required
///
/// Returns:
/// - WalkForwardConfig instance
pub fn create_walk_forward_config(
  window_size : Int,
  step_size : Int,
  oos_ratio : Float,
  mode : WfMode,
  min_oos_bars : Int,
) -> WalkForwardConfig {
  WalkForwardConfig::{ window_size, step_size, oos_ratio, mode, min_oos_bars }
}

///|
/// Single Walk-Forward result
pub struct WfResult {
  window_index : Int
  in_sample_start : Int
  in_sample_end : Int
  oos_start : Int
  oos_end : Int
  is_profit : Float
  oos_profit : Float
  is_sharpe : Float
  oos_sharpe : Float
  is_max_dd : Float
  oos_max_dd : Float
  is_trades : Int
  oos_trades : Int
} derive(Show)

///|
/// Create WfResult instance
pub fn create_wf_result(
  window_index : Int,
  in_sample_start : Int,
  in_sample_end : Int,
  oos_start : Int,
  oos_end : Int,
  is_profit : Float,
  oos_profit : Float,
  is_sharpe : Float,
  oos_sharpe : Float,
  is_max_dd : Float,
  oos_max_dd : Float,
  is_trades : Int,
  oos_trades : Int,
) -> WfResult {
  WfResult::{
    window_index,
    in_sample_start,
    in_sample_end,
    oos_start,
    oos_end,
    is_profit,
    oos_profit,
    is_sharpe,
    oos_sharpe,
    is_max_dd,
    oos_max_dd,
    is_trades,
    oos_trades,
  }
}

///|
///\n/// Walk-Forward analysis summary
pub struct WfSummary {
  /// Total windows
  total_windows : Int
  /// Windows where OOS was profitable
  successful_windows : Int
  /// Average in-sample profit
  avg_is_profit : Float
  /// Average out-of-sample profit
  avg_oos_profit : Float
  /// Average in-sample Sharpe ratio
  avg_is_sharpe : Float
  /// Average out-of-sample Sharpe ratio
  avg_oos_sharpe : Float
  /// Average in-sample max drawdown
  avg_is_max_dd : Float
  /// Average out-of-sample max drawdown
  avg_oos_max_dd : Float
  /// % of windows with profitable OOS
  oos_success_rate : Float
  /// OOS Sharpe / IS Sharpe
  degradation_ratio : Float
  /// Overall robustness score (0-100)
  robustness_score : Float
} derive(Show)

///|
/// Create WfSummary instance
pub fn create_wf_summary(
  total_windows : Int,
  successful_windows : Int,
  avg_is_profit : Float,
  avg_oos_profit : Float,
  avg_is_sharpe : Float,
  avg_oos_sharpe : Float,
  avg_is_max_dd : Float,
  avg_oos_max_dd : Float,
  oos_success_rate : Float,
  degradation_ratio : Float,
  robustness_score : Float,
) -> WfSummary {
  WfSummary::{
    total_windows,
    successful_windows,
    avg_is_profit,
    avg_oos_profit,
    avg_is_sharpe,
    avg_oos_sharpe,
    avg_is_max_dd,
    avg_oos_max_dd,
    oos_success_rate,
    degradation_ratio,
    robustness_score,
  }
}

///|
///\n/// Calculate Walk-Forward windows for anchored mode
///
/// In anchored mode, the in-sample period grows with each iteration
/// while the out-of-sample period rolls forward.
///
/// Parameters:
/// - total_bars: Total bars available
/// - initial_window: Initial in-sample window size
/// - step_size: Bars to add each iteration
/// - oos_ratio: OOS ratio applied to current window
///
/// Returns:
/// - Array of (is_start, is_end, oos_start, oos_end) tuples
pub fn generate_anchored_windows(
  total_bars : Int,
  initial_window : Int,
  step_size : Int,
  oos_ratio : Float,
) -> Array[(Int, Int, Int, Int)] {
  let windows : Array[(Int, Int, Int, Int)] = []
  let mut window_size = initial_window
  let mut start = 0

  while start + window_size <= total_bars {
    let oos_bars = Float::to_int(Float::from_int(window_size) * oos_ratio)
    let is_bars = window_size - oos_bars

    if is_bars > 0 {
      let is_start = start
      let is_end = start + is_bars
      let oos_start = is_end
      let oos_end = start + window_size

      windows.push((is_start, is_end, oos_start, oos_end))
    }

    start = start + step_size
    window_size = window_size + step_size
  }
  windows
}

///|
///\n/// Generate windows based on mode
pub fn generate_wf_windows(
  config : WalkForwardConfig,
  total_bars : Int,
) -> Array[(Int, Int, Int, Int)] {
  match config.mode {
    WfMode::Rolling =>
      generate_walk_forward_windows(
        total_bars,
        config.window_size,
        config.step_size,
        config.oos_ratio,
      )
    WfMode::Anchored =>
      generate_anchored_windows(
        total_bars,
        config.window_size,
        config.step_size,
        config.oos_ratio,
      )
  }
}

///|
///\n/// Calculate Sharpe ratio from returns
pub fn calculate_sharpe(
  returns : Array[Float],
  risk_free_rate : Float,
) -> Float {
  if returns.length() == 0 {
    Float::from_double(0.0)
  } else {
    let mut sum = Float::from_double(0.0)
    for r in returns {
      sum = sum + (r - risk_free_rate)
    }
    let avg_return = sum / Float::from_int(returns.length())

    let mut variance_sum = Float::from_double(0.0)
    for r in returns {
      let diff = r - avg_return
      variance_sum = variance_sum + diff * diff
    }
    let std_dev = Float::sqrt(variance_sum / Float::from_int(returns.length()))

    if std_dev <= Float::from_double(0.0) {
      Float::from_double(0.0)
    } else {
      avg_return *
      Float::from_int(252) /
      (std_dev * Float::sqrt(Float::from_int(252)))
    }
  }
}

///|
///\n/// Calculate maximum drawdown from equity curve
pub fn calculate_max_dd(equity : Array[Float]) -> Float {
  if equity.length() == 0 {
    Float::from_double(0.0)
  } else {
    let mut peak = equity[0]
    let mut max_dd = Float::from_double(0.0)

    for value in equity {
      if value > peak {
        peak = value
      }
      if peak > Float::from_double(0.0) {
        let dd = (peak - value) / peak
        if dd > max_dd {
          max_dd = dd
        }
      }
    }
    max_dd
  }
}

///|
///\n/// Calculate total profit from returns
pub fn calculate_profit(returns : Array[Float]) -> Float {
  let mut total = Float::from_double(0.0)
  for r in returns {
    total = total + r
  }
  total
}

///|
///\n/// Analyze Walk-Forward results
///
/// Parameters:
/// - results: Array of WfResult from each window
///
/// Returns:
/// - WfSummary with aggregated statistics
pub fn analyze_wf_results(results : Array[WfResult]) -> WfSummary {
  let total = results.length()
  if total == 0 {
    create_wf_summary(
      0,
      0,
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
      Float::from_double(0.0),
    )
  } else {
    let mut successful = 0
    let mut sum_is_profit = Float::from_double(0.0)
    let mut sum_oos_profit = Float::from_double(0.0)
    let mut sum_is_sharpe = Float::from_double(0.0)
    let mut sum_oos_sharpe = Float::from_double(0.0)
    let mut sum_is_dd = Float::from_double(0.0)
    let mut sum_oos_dd = Float::from_double(0.0)

    for result in results {
      if result.oos_profit > Float::from_double(0.0) {
        successful = successful + 1
      }
      sum_is_profit = sum_is_profit + result.is_profit
      sum_oos_profit = sum_oos_profit + result.oos_profit
      sum_is_sharpe = sum_is_sharpe + result.is_sharpe
      sum_oos_sharpe = sum_oos_sharpe + result.oos_sharpe
      sum_is_dd = sum_is_dd + result.is_max_dd
      sum_oos_dd = sum_oos_dd + result.oos_max_dd
    }

    let total_float = Float::from_int(total)
    let avg_is_profit = sum_is_profit / total_float
    let avg_oos_profit = sum_oos_profit / total_float
    let avg_is_sharpe = sum_is_sharpe / total_float
    let avg_oos_sharpe = sum_oos_sharpe / total_float
    let avg_is_dd = sum_is_dd / total_float
    let avg_oos_dd = sum_oos_dd / total_float
    let oos_success_rate = Float::from_int(successful) / total_float

    let degradation_ratio = if avg_is_sharpe > Float::from_double(0.0) {
      avg_oos_sharpe / avg_is_sharpe
    } else {
      Float::from_double(0.0)
    }

    // Robustness score: weighted combination of success rate, degradation ratio, and OOS profitability
    let robustness_score = oos_success_rate * Float::from_double(40.0) +
      Float::min(
        Float::from_double(1.0),
        Float::max(Float::from_double(0.0), degradation_ratio),
      ) *
      Float::from_double(40.0) +
      (if avg_oos_profit > Float::from_double(0.0) {
        Float::from_double(20.0)
      } else {
        Float::from_double(0.0)
      })

    create_wf_summary(
      total, successful, avg_is_profit, avg_oos_profit, avg_is_sharpe, avg_oos_sharpe,
      avg_is_dd, avg_oos_dd, oos_success_rate, degradation_ratio, robustness_score,
    )
  }
}

///|
///\n/// Check if strategy passes Walk-Forward validation
///
/// A strategy passes WFA validation if:
/// - OOS success rate >= 50%
/// - Degradation ratio >= 0.5 (OOS Sharpe at least 50% of IS Sharpe)
/// - Average OOS profit is positive
///
/// Parameters:
/// - summary: WfSummary from analysis
///
/// Returns:
/// - true if strategy passes all criteria
pub fn passes_wf_validation(summary : WfSummary) -> Bool {
  summary.oos_success_rate >= 0.5 &&
  summary.degradation_ratio >= 0.5 &&
  summary.avg_oos_profit > 0.0
}

///|
///\n/// Default Walk-Forward config (industry standard)
///
/// Uses 70% in-sample, 30% out-of-sample with rolling window
pub fn walk_forward_config_default() -> WalkForwardConfig {
  WalkForwardConfig::{
    window_size: 252, // 1 year of daily data
    step_size: 63, // Roll forward quarterly
    oos_ratio: Float::from_double(0.3), // 30% OOS
    mode: WfMode::Rolling,
    min_oos_bars: 21, // Minimum 1 month OOS
  }
}
