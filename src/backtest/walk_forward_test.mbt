/// Walk-Forward Analysis tests

///|
test "generate_walk_forward_windows - basic calculation" {
  let windows = generate_walk_forward_windows(
    100,
    30,
    10,
    Float::from_double(0.2),
  )

  // With total=100, window=30, step=10, oos_ratio=0.2:
  // oos_bars = 30 * 0.2 = 6, is_bars = 24
  // Windows: (0,24,24,30), (10,34,34,40), (20,44,44,50), ... (70,94,94,100)
  assert_true(windows.length() > 0)

  // First window
  let (is_start, is_end, oos_start, oos_end) = windows[0]
  assert_eq(is_start, 0)
  assert_eq(is_end, 24)
  assert_eq(oos_start, 24)
  assert_eq(oos_end, 30)
}

///|
test "generate_walk_forward_windows - exact boundaries" {
  let windows = generate_walk_forward_windows(
    60,
    30,
    10,
    Float::from_double(0.2),
  )

  // Should produce windows starting at: 0, 10, 20, 30
  // Window at 30: (30, 54, 54, 60) - valid
  // Window at 40: 40 + 30 = 70 > 60 - invalid
  assert_true(windows.length() >= 4)
}

///|
test "generate_walk_forward_windows - insufficient data" {
  let windows = generate_walk_forward_windows(
    20,
    30,
    10,
    Float::from_double(0.2),
  )

  // Not enough data for even one window
  assert_eq(windows.length(), 0)
}

///|
test "generate_walk_forward_windows - negative oos ratio" {
  let windows = generate_walk_forward_windows(
    100,
    30,
    10,
    Float::from_double(-0.1),
  )

  // Negative ratio should still produce windows but with larger IS
  assert_true(windows.length() > 0)
}

///|
test "generate_walk_forward_windows - 100% oos ratio" {
  let windows = generate_walk_forward_windows(
    100,
    30,
    10,
    Float::from_double(1.0),
  )

  // 100% OOS means 0% IS, which should produce no valid windows
  assert_eq(windows.length(), 0)
}

///|
test "generate_anchored_windows - basic calculation" {
  let windows = generate_anchored_windows(100, 30, 10, Float::from_double(0.2))

  // First window: size=30, oos=6, is=24 -> (0, 24, 24, 30)
  // Second window: size=40, oos=8, is=32 -> (10, 42, 42, 50)
  // Third window: size=50, oos=10, is=40 -> (20, 60, 60, 70)
  assert_true(windows.length() > 0)

  let (is_start, is_end, oos_start, oos_end) = windows[0]
  assert_eq(is_start, 0)
  assert_eq(is_end, 24)
  assert_eq(oos_start, 24)
  assert_eq(oos_end, 30)
}

///|
test "generate_anchored_windows - growing window" {
  let windows = generate_anchored_windows(100, 30, 10, Float::from_double(0.2))

  if windows.length() >= 2 {
    let (_, is_end_0, oos_start_0, oos_end_0) = windows[0]
    let (_, is_end_1, oos_start_1, oos_end_1) = windows[1]

    // In anchored mode, window size grows
    assert_true(oos_end_1 > oos_end_0)
    assert_true(is_end_1 > is_end_0)
  }
}

///|
test "generate_anchored_windows - minimum window" {
  let windows = generate_anchored_windows(50, 20, 5, Float::from_double(0.3))

  // Initial window of 20 should work
  assert_true(windows.length() > 0)
}

///|
test "walk_forward_config_default - standard values" {
  let config = walk_forward_config_default()

  assert_eq(config.window_size, 252)
  assert_eq(config.step_size, 63)
  assert_true(config.oos_ratio > Float::from_double(0.29))
  assert_true(config.oos_ratio < Float::from_double(0.31))
}

///|
test "create_walk_forward_config - custom values" {
  let config = create_walk_forward_config(
    100,
    25,
    Float::from_double(0.25),
    wf_mode_rolling(),
    10,
  )

  assert_eq(config.window_size, 100)
  assert_eq(config.step_size, 25)
  assert_true(config.oos_ratio > Float::from_double(0.24))
  assert_true(config.oos_ratio < Float::from_double(0.26))
  assert_true(
    match config.mode {
      WfMode::Rolling => true
      _ => false
    },
  )
  assert_eq(config.min_oos_bars, 10)
}

///|
test "generate_wf_windows - rolling mode" {
  let config = create_walk_forward_config(
    50,
    10,
    Float::from_double(0.2),
    wf_mode_rolling(),
    5,
  )
  let windows = generate_wf_windows(config, 100)

  // Rolling mode should use generate_walk_forward_windows
  assert_true(windows.length() > 0)
}

///|
test "generate_wf_windows - anchored mode" {
  let config = create_walk_forward_config(
    50,
    10,
    Float::from_double(0.2),
    wf_mode_anchored(),
    5,
  )
  let windows = generate_wf_windows(config, 100)

  // Anchored mode should use generate_anchored_windows
  assert_true(windows.length() > 0)
}

///|
test "calculate_sharpe - positive returns" {
  let returns : Array[Float] = [
    Float::from_double(0.01),
    Float::from_double(0.02),
    Float::from_double(0.015),
    Float::from_double(0.025),
  ]
  let sharpe = calculate_sharpe(returns, Float::from_double(0.0))

  // Should be positive
  assert_true(sharpe > Float::from_double(0.0))
}

///|
test "calculate_sharpe - negative returns" {
  let returns : Array[Float] = [
    Float::from_double(-0.01),
    Float::from_double(-0.02),
    Float::from_double(-0.015),
  ]
  let sharpe = calculate_sharpe(returns, Float::from_double(0.0))

  // Should be negative
  assert_true(sharpe < Float::from_double(0.0))
}

///|
test "calculate_sharpe - empty returns" {
  let returns : Array[Float] = []
  let sharpe = calculate_sharpe(returns, Float::from_double(0.0))

  assert_eq(sharpe, Float::from_double(0.0))
}

///|
test "calculate_sharpe - constant returns" {
  let returns : Array[Float] = [
    Float::from_double(0.01),
    Float::from_double(0.01),
    Float::from_double(0.01),
  ]
  let sharpe = calculate_sharpe(returns, Float::from_double(0.0))

  // Zero variance should return 0
  assert_eq(sharpe, Float::from_double(0.0))
}

///|
test "calculate_max_dd - declining equity" {
  let equity : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(90.0),
    Float::from_double(80.0),
    Float::from_double(70.0),
  ]
  let max_dd = calculate_max_dd(equity)

  // Max DD = (100 - 70) / 100 = 0.30
  assert_true(max_dd > Float::from_double(0.29))
  assert_true(max_dd < Float::from_double(0.31))
}

///|
test "calculate_max_dd - rising equity" {
  let equity : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(110.0),
    Float::from_double(120.0),
    Float::from_double(130.0),
  ]
  let max_dd = calculate_max_dd(equity)

  // No drawdown in continuously rising equity
  assert_eq(max_dd, Float::from_double(0.0))
}

///|
test "calculate_max_dd - peak then decline" {
  let equity : Array[Float] = [
    Float::from_double(100.0),
    Float::from_double(150.0),
    Float::from_double(120.0),
    Float::from_double(140.0),
  ]
  let max_dd = calculate_max_dd(equity)

  // Max DD from peak 150 to trough 120 = (150-120)/150 = 0.20
  assert_true(max_dd > Float::from_double(0.19))
  assert_true(max_dd < Float::from_double(0.21))
}

///|
test "calculate_max_dd - empty equity" {
  let equity : Array[Float] = []
  let max_dd = calculate_max_dd(equity)

  assert_eq(max_dd, Float::from_double(0.0))
}

///|
test "calculate_profit - basic calculation" {
  let returns : Array[Float] = [
    Float::from_double(0.01),
    Float::from_double(-0.02),
    Float::from_double(0.03),
  ]
  let profit = calculate_profit(returns)

  // 0.01 - 0.02 + 0.03 = 0.02
  assert_true(profit > Float::from_double(0.019))
  assert_true(profit < Float::from_double(0.021))
}

///|
test "calculate_profit - empty returns" {
  let returns : Array[Float] = []
  let profit = calculate_profit(returns)

  assert_eq(profit, Float::from_double(0.0))
}

///|
test "wf_result - struct creation" {
  let result = WfResult::{
    window_index: 0,
    in_sample_start: 0,
    in_sample_end: 50,
    oos_start: 50,
    oos_end: 70,
    is_profit: Float::from_double(1000.0),
    oos_profit: Float::from_double(500.0),
    is_sharpe: Float::from_double(1.5),
    oos_sharpe: Float::from_double(1.2),
    is_max_dd: Float::from_double(0.1),
    oos_max_dd: Float::from_double(0.15),
    is_trades: 10,
    oos_trades: 5,
  }

  assert_eq(result.window_index, 0)
  assert_eq(result.in_sample_end, 50)
}

///|
test "analyze_wf_results - empty results" {
  let results : Array[WfResult] = []
  let summary = analyze_wf_results(results)

  assert_eq(summary.total_windows, 0)
  assert_eq(summary.successful_windows, 0)
  assert_eq(summary.avg_oos_profit, Float::from_double(0.0))
  assert_eq(summary.robustness_score, Float::from_double(0.0))
}

///|
test "analyze_wf_results - single profitable window" {
  let results : Array[WfResult] = [
    WfResult::{
      window_index: 0,
      in_sample_start: 0,
      in_sample_end: 50,
      oos_start: 50,
      oos_end: 70,
      is_profit: Float::from_double(1000.0),
      oos_profit: Float::from_double(500.0),
      is_sharpe: Float::from_double(1.5),
      oos_sharpe: Float::from_double(1.2),
      is_max_dd: Float::from_double(0.1),
      oos_max_dd: Float::from_double(0.15),
      is_trades: 10,
      oos_trades: 5,
    },
  ]
  let summary = analyze_wf_results(results)

  assert_eq(summary.total_windows, 1)
  assert_eq(summary.successful_windows, 1)
  assert_true(summary.oos_success_rate > Float::from_double(0.9))
}

///|
test "analyze_wf_results - mixed results" {
  let results : Array[WfResult] = [
    WfResult::{
      window_index: 0,
      in_sample_start: 0,
      in_sample_end: 50,
      oos_start: 50,
      oos_end: 70,
      is_profit: Float::from_double(1000.0),
      oos_profit: Float::from_double(500.0),
      is_sharpe: Float::from_double(1.5),
      oos_sharpe: Float::from_double(1.0),
      is_max_dd: Float::from_double(0.1),
      oos_max_dd: Float::from_double(0.12),
      is_trades: 10,
      oos_trades: 5,
    },
    WfResult::{
      window_index: 1,
      in_sample_start: 10,
      in_sample_end: 60,
      oos_start: 60,
      oos_end: 80,
      is_profit: Float::from_double(800.0),
      oos_profit: Float::from_double(-200.0),
      is_sharpe: Float::from_double(1.2),
      oos_sharpe: Float::from_double(-0.5),
      is_max_dd: Float::from_double(0.15),
      oos_max_dd: Float::from_double(0.2),
      is_trades: 8,
      oos_trades: 4,
    },
  ]
  let summary = analyze_wf_results(results)

  assert_eq(summary.total_windows, 2)
  assert_eq(summary.successful_windows, 1)
  assert_true(summary.oos_success_rate > Float::from_double(0.49))
  assert_true(summary.oos_success_rate < Float::from_double(0.51))
}

///|
test "analyze_wf_results - degradation ratio calculation" {
  let results : Array[WfResult] = [
    WfResult::{
      window_index: 0,
      in_sample_start: 0,
      in_sample_end: 50,
      oos_start: 50,
      oos_end: 70,
      is_profit: Float::from_double(1000.0),
      oos_profit: Float::from_double(500.0),
      is_sharpe: Float::from_double(2.0),
      oos_sharpe: Float::from_double(1.0),
      is_max_dd: Float::from_double(0.1),
      oos_max_dd: Float::from_double(0.12),
      is_trades: 10,
      oos_trades: 5,
    },
  ]
  let summary = analyze_wf_results(results)

  // Degradation = 1.0 / 2.0 = 0.5
  assert_true(summary.degradation_ratio > Float::from_double(0.49))
  assert_true(summary.degradation_ratio < Float::from_double(0.51))
}

///|
test "passes_wf_validation - passing strategy" {
  let summary = WfSummary::{
    total_windows: 5,
    successful_windows: 3,
    avg_is_profit: Float::from_double(1000.0),
    avg_oos_profit: Float::from_double(500.0),
    avg_is_sharpe: Float::from_double(1.5),
    avg_oos_sharpe: Float::from_double(1.0),
    avg_is_max_dd: Float::from_double(0.1),
    avg_oos_max_dd: Float::from_double(0.12),
    oos_success_rate: Float::from_double(0.6),
    degradation_ratio: Float::from_double(0.67),
    robustness_score: Float::from_double(75.0),
  }

  assert_true(passes_wf_validation(summary))
}

///|
test "passes_wf_validation - failing low success rate" {
  let summary = WfSummary::{
    total_windows: 5,
    successful_windows: 1,
    avg_is_profit: Float::from_double(1000.0),
    avg_oos_profit: Float::from_double(500.0),
    avg_is_sharpe: Float::from_double(1.5),
    avg_oos_sharpe: Float::from_double(1.0),
    avg_is_max_dd: Float::from_double(0.1),
    avg_oos_max_dd: Float::from_double(0.12),
    oos_success_rate: Float::from_double(0.2),
    degradation_ratio: Float::from_double(0.67),
    robustness_score: Float::from_double(50.0),
  }

  // Success rate < 50%
  assert_true(!passes_wf_validation(summary))
}

///|
test "passes_wf_validation - failing degradation" {
  let summary = WfSummary::{
    total_windows: 5,
    successful_windows: 3,
    avg_is_profit: Float::from_double(1000.0),
    avg_oos_profit: Float::from_double(500.0),
    avg_is_sharpe: Float::from_double(2.0),
    avg_oos_sharpe: Float::from_double(0.5),
    avg_is_max_dd: Float::from_double(0.1),
    avg_oos_max_dd: Float::from_double(0.12),
    oos_success_rate: Float::from_double(0.6),
    degradation_ratio: Float::from_double(0.25),
    robustness_score: Float::from_double(50.0),
  }

  // Degradation ratio < 0.5
  assert_true(!passes_wf_validation(summary))
}

///|
test "passes_wf_validation - failing negative oos profit" {
  let summary = WfSummary::{
    total_windows: 5,
    successful_windows: 3,
    avg_is_profit: Float::from_double(1000.0),
    avg_oos_profit: Float::from_double(-100.0),
    avg_is_sharpe: Float::from_double(1.5),
    avg_oos_sharpe: Float::from_double(1.0),
    avg_is_max_dd: Float::from_double(0.1),
    avg_oos_max_dd: Float::from_double(0.12),
    oos_success_rate: Float::from_double(0.6),
    degradation_ratio: Float::from_double(0.67),
    robustness_score: Float::from_double(60.0),
  }

  // Negative OOS profit
  assert_true(!passes_wf_validation(summary))
}

///|
test "wf_mode_enum - equality" {
  assert_true(WfMode::Rolling == WfMode::Rolling)
  assert_true(WfMode::Anchored == WfMode::Anchored)
  assert_true(WfMode::Rolling != WfMode::Anchored)
}

///|
test "robustness_score - calculation example" {
  let results : Array[WfResult] = [
    WfResult::{
      window_index: 0,
      in_sample_start: 0,
      in_sample_end: 50,
      oos_start: 50,
      oos_end: 70,
      is_profit: Float::from_double(1000.0),
      oos_profit: Float::from_double(500.0),
      is_sharpe: Float::from_double(1.5),
      oos_sharpe: Float::from_double(1.2),
      is_max_dd: Float::from_double(0.1),
      oos_max_dd: Float::from_double(0.12),
      is_trades: 10,
      oos_trades: 5,
    },
    WfResult::{
      window_index: 1,
      in_sample_start: 10,
      in_sample_end: 60,
      oos_start: 60,
      oos_end: 80,
      is_profit: Float::from_double(800.0),
      oos_profit: Float::from_double(400.0),
      is_sharpe: Float::from_double(1.3),
      oos_sharpe: Float::from_double(1.1),
      is_max_dd: Float::from_double(0.12),
      oos_max_dd: Float::from_double(0.14),
      is_trades: 8,
      oos_trades: 4,
    },
  ]
  let summary = analyze_wf_results(results)

  // Both windows profitable, degradation ratio ~0.85
  // Score should be high: (1.0 * 40) + (0.85 * 40) + 20 = ~94
  assert_true(summary.robustness_score > Float::from_double(80.0))
}

///|
test "walk_forward_realistic_scenario" {
  // Simulate a realistic walk-forward analysis scenario
  // 2 years of daily data (~504 bars)
  let total_bars = 504
  let config = create_walk_forward_config(
    252,           // 1 year window
    63,            // Roll quarterly
    Float::from_double(0.3),  // 30% OOS
    WfMode::Rolling,
    21,            // Min 1 month OOS
  )

  let windows = generate_wf_windows(config, total_bars)

  // Should produce multiple windows
  assert_true(windows.length() >= 3)

  // Verify window structure
  for (is_start, is_end, oos_start, oos_end) in windows {
    assert_true(is_end > is_start)
    assert_true(oos_end > oos_start)
    assert_true(oos_start == is_end)
  }
}
