/// Black-box tests for data normalizer module

///|
test "AdjustType enum - pattern matching" {
  // Test AdjustType enum via pattern matching
  let check_adjust_type = fn(t : @data.AdjustType) -> String {
    match t {
      @data.AdjustType::None => "None"
      @data.AdjustType::Forward => "Forward"
      @data.AdjustType::Backward => "Backward"
    }
  }

  // We can verify the enum is accessible via match
  // Since enum variants are read-only, we test the type exists
  let _ = check_adjust_type // Suppress unused warning
}

///|
test "create_adjust_factor - basic creation" {
  let factor = @data.create_adjust_factor("2023-01-01", 0.5, 0.1)
  assert_true(factor.date == "2023-01-01")
  assert_true(factor.ratio > 0.49 && factor.ratio < 0.51)
  assert_true(factor.dividend > 0.09 && factor.dividend < 0.11)
  assert_true(factor.rights_ratio == 0.0)
  assert_true(factor.rights_price == 0.0)
}

///|
test "apply_forward_adjustment - empty array" {
  let klines : Array[@data.KLine] = []
  let result = @data.apply_forward_adjustment(klines, 0.5)
  assert_true(result.length() == 0)
}

///|
test "apply_forward_adjustment - factor 1.0 no change" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let result = @data.apply_forward_adjustment(klines, 1.0)
  assert_true(result.length() == 1)
  assert_true(result[0].open == klines[0].open)
  assert_true(result[0].close == klines[0].close)
}

///|
test "apply_forward_adjustment - split adjustment 2:1" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 20.0, 22.0, 19.0, 21.0, 1000000.0, 21000000.0, 0.05,
    ),
  ]
  // 2:1 split means prices are halved
  let result = @data.apply_forward_adjustment(klines, 0.5)
  assert_true(result.length() == 1)
  assert_true(result[0].close > 10.4 && result[0].close < 10.6)
  // Volume should double
  assert_true(result[0].volume > 1999999.0 && result[0].volume < 2000001.0)
}

///|
test "apply_forward_adjustment - multiple klines" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
  ]
  let result = @data.apply_forward_adjustment(klines, 0.8)
  assert_true(result.length() == 2)
  // All prices should be multiplied by 0.8
  assert_true(result[0].close > 8.3 && result[0].close < 8.5)
  assert_true(result[1].close > 8.7 && result[1].close < 8.9)
}

///|
test "apply_backward_adjustment - empty array" {
  let klines : Array[@data.KLine] = []
  let result = @data.apply_backward_adjustment(klines, 0.5)
  assert_true(result.length() == 0)
}

///|
test "apply_backward_adjustment - factor 1.0 no change" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let result = @data.apply_backward_adjustment(klines, 1.0)
  assert_true(result.length() == 1)
  assert_true(result[0].open == klines[0].open)
}

///|
test "apply_backward_adjustment - reverse split" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  // Reverse split 1:2 means prices double
  let result = @data.apply_backward_adjustment(klines, 0.5)
  assert_true(result.length() == 1)
  assert_true(result[0].close > 20.9 && result[0].close < 21.1)
  // Volume should be halved
  assert_true(result[0].volume > 499999.0 && result[0].volume < 500001.0)
}

///|
test "normalize_to_date - empty klines" {
  let klines : Array[@data.KLine] = []
  let factors : Array[@data.AdjustFactor] = []
  let result = @data.normalize_to_date(klines, "2023-01-01", factors)
  assert_true(result.length() == 0)
}

///|
test "normalize_to_date - with adjustment factors" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
  ]
  let factors = [@data.create_adjust_factor("2023-01-01", 0.9, 0.0)]
  let result = @data.normalize_to_date(klines, "2023-01-02", factors)
  assert_true(result.length() == 2)
  // Prices should be adjusted by factor
  assert_true(result[0].close < klines[0].close)
}

///|
test "normalize_price_series - empty array" {
  let klines : Array[@data.KLine] = []
  let result = @data.normalize_price_series(klines)
  assert_true(result.length() == 0)
}

///|
test "normalize_price_series - single element" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
  ]
  let result = @data.normalize_price_series(klines)
  assert_true(result.length() == 1)
  assert_true(result[0] == 1.0)
}

///|
test "normalize_price_series - multiple elements" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
  ]
  let result = @data.normalize_price_series(klines)
  assert_true(result.length() == 3)
  assert_true(result[0] == 1.0)
  assert_true(result[1] > 1.09 && result[1] < 1.11)
  assert_true(result[2] > 1.19 && result[2] < 1.21)
}

///|
test "normalize_price_series - zero base price" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 0.0, 0.0, 0.0, 0.0, 1000000.0, 0.0, 0.0,
    ),
  ]
  let result = @data.normalize_price_series(klines)
  assert_true(result.length() == 0)
}

///|
test "calculate_returns - empty array" {
  let klines : Array[@data.KLine] = []
  let result = @data.calculate_returns(klines)
  assert_true(result.length() == 0)
}

///|
test "calculate_returns - single element" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let result = @data.calculate_returns(klines)
  assert_true(result.length() == 0)
}

///|
test "calculate_returns - two elements positive return" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
  ]
  let result = @data.calculate_returns(klines)
  assert_true(result.length() == 1)
  // (11 - 10) / 10 = 0.1 = 10%
  assert_true(result[0] > 0.09 && result[0] < 0.11)
}

///|
test "calculate_returns - negative return" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 10.5, 9.0, 9.0, 1200000.0, 10800000.0, 0.06,
    ),
  ]
  let result = @data.calculate_returns(klines)
  assert_true(result.length() == 1)
  // (9 - 10) / 10 = -0.1 = -10%
  assert_true(result[0] < -0.09 && result[0] > -0.11)
}

///|
test "calculate_returns - multiple elements snapshot" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
  ]
  let result = @data.calculate_returns(klines)
  assert_true(result.length() == 2)
  // Day 1->2: (11-10)/10 = 0.1
  assert_true(result[0] > 0.09 && result[0] < 0.11)
  // Day 2->3: (12-11)/11 = 0.0909...
  assert_true(result[1] > 0.08 && result[1] < 0.10)
}

///|
test "calculate_log_returns - empty array" {
  let klines : Array[@data.KLine] = []
  let result = @data.calculate_log_returns(klines)
  assert_true(result.length() == 0)
}

///|
test "calculate_log_returns - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
  ]
  let result = @data.calculate_log_returns(klines)
  assert_true(result.length() == 1)
  // Log return approximated as simple return for small values
  assert_true(result[0] > 0.09 && result[0] < 0.11)
}

///|
test "calculate_rolling_volatility - insufficient data" {
  let returns : Array[Float] = [0.01, 0.02]
  let result = @data.calculate_rolling_volatility(returns, 5)
  assert_true(result.length() == 0)
}

///|
test "calculate_rolling_volatility - window too small" {
  let returns : Array[Float] = [0.01, 0.02, 0.03]
  let result = @data.calculate_rolling_volatility(returns, 1)
  assert_true(result.length() == 0)
}

///|
test "calculate_rolling_volatility - basic calculation" {
  let returns : Array[Float] = [0.01, -0.02, 0.03, -0.01, 0.02]
  let result = @data.calculate_rolling_volatility(returns, 3)
  assert_true(result.length() == 3)
  // Just verify we get positive volatility values
  assert_true(result[0] > 0.0)
  assert_true(result[1] > 0.0)
  assert_true(result[2] > 0.0)
}

///|
test "annualize_volatility - basic calculation" {
  let daily_vol : Float = 0.02
  let result = @data.annualize_volatility(daily_vol, 252)
  // Annualized = daily * sqrt(252) ≈ 0.02 * 15.87 ≈ 0.317
  assert_true(result > 0.30 && result < 0.33)
}

///|
test "annualize_volatility - zero input" {
  let result = @data.annualize_volatility(0.0, 252)
  assert_true(result == 0.0)
}

///|
test "normalize_volume - insufficient data" {
  let klines : Array[@data.KLine] = []
  let result = @data.normalize_volume(klines, 5)
  assert_true(result.length() == 0)
}

///|
test "normalize_volume - basic calculation" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.0, 1000000.0, 10000000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 11.5, 10.0, 11.0, 2000000.0, 22000000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
  ]
  let result = @data.normalize_volume(klines, 2)
  assert_true(result.length() == 2)
  // First ratio: avg(1M, 2M) = 1.5M, ratio = 2M/1.5M = 1.33
  assert_true(result[0] > 1.3 && result[0] < 1.4)
  // Second ratio: avg(2M, 1.5M) = 1.75M, ratio = 1.5M/1.75M = 0.857
  assert_true(result[1] > 0.85 && result[1] < 0.87)
}

///|
test "validate_kline - valid kline" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(@data.validate_kline(kline) == true)
}

///|
test "validate_kline - high less than low" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 9.0, 11.0, 10.5, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(@data.validate_kline(kline) == false)
}

///|
test "validate_kline - high less than close" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 10.5, 9.5, 11.0, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(@data.validate_kline(kline) == false)
}

///|
test "validate_kline - low greater than open" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 10.5, 10.8, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(@data.validate_kline(kline) == false)
}

///|
test "validate_kline - zero open price" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 0.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
  )
  assert_true(@data.validate_kline(kline) == false)
}

///|
test "validate_kline - negative volume" {
  let kline = @data.KLine::daily(
    "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, -1000000.0, 10500000.0, 0.05,
  )
  assert_true(@data.validate_kline(kline) == false)
}

///|
test "filter_invalid_klines - mixed valid and invalid" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.0, 9.0, 11.0, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
  ]
  let result = @data.filter_invalid_klines(klines)
  assert_true(result.length() == 2)
  assert_true(result[0].date == "2023-01-01")
  assert_true(result[1].date == "2023-01-03")
}

///|
test "sort_klines_by_date - unsorted input" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
  ]
  let result = @data.sort_klines_by_date(klines)
  assert_true(result.length() == 3)
  assert_true(result[0].date == "2023-01-01")
  assert_true(result[1].date == "2023-01-02")
  assert_true(result[2].date == "2023-01-03")
}

///|
test "sort_klines_by_date - already sorted" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
  ]
  let result = @data.sort_klines_by_date(klines)
  assert_true(result.length() == 2)
  assert_true(result[0].date == "2023-01-01")
  assert_true(result[1].date == "2023-01-02")
}

///|
test "trim_klines_to_range - full overlap" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
  ]
  let result = @data.trim_klines_to_range(klines, "2023-01-01", "2023-01-03")
  assert_true(result.length() == 3)
}

///|
test "trim_klines_to_range - partial overlap" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-02", 10.5, 11.5, 10.0, 11.0, 1200000.0, 13200000.0, 0.06,
    ),
    @data.KLine::daily(
      "sh.600000", "2023-01-03", 11.0, 12.0, 10.5, 12.0, 1500000.0, 18000000.0, 0.07,
    ),
  ]
  let result = @data.trim_klines_to_range(klines, "2023-01-02", "2023-01-02")
  assert_true(result.length() == 1)
  assert_true(result[0].date == "2023-01-02")
}

///|
test "trim_klines_to_range - no overlap" {
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2023-01-01", 10.0, 11.0, 9.5, 10.5, 1000000.0, 10500000.0, 0.05,
    ),
  ]
  let result = @data.trim_klines_to_range(klines, "2023-02-01", "2023-02-28")
  assert_true(result.length() == 0)
}

// Note: Tests for adjust_klines and resample_klines require enum variants
// (AdjustType, Frequency) which are read-only and cannot be constructed
// in blackbox tests. These are tested in whitebox tests instead.

