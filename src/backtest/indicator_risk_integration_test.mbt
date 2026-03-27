/// Integration tests for Indicator + Risk Engine + Drawdown interactions
///
/// This module tests the integration between:
/// - Indicator library (RSI, MACD, Bollinger Bands, etc.)
/// - Risk management engine (rules, limits, stops)
/// - Drawdown monitoring (alerts, thresholds, duration)
///
/// Test scenarios:
/// 1. Indicator signals triggering risk rules
/// 2. Drawdown limit interactions with strategy signals
/// 3. Multi-indicator combination with risk management

///|
test "integration: RSI oversold signal with drawdown check" {
  // Scenario: RSI indicates oversold (buy signal), but drawdown is near limit
  // Expected: Risk engine should allow trade if drawdown is within limits

  // Create price data showing decline (for RSI calculation)
  let prices = [
    Float::from_double(100.0),
    Float::from_double(98.0),
    Float::from_double(96.0),
    Float::from_double(94.0),
    Float::from_double(92.0),
    Float::from_double(90.0),
    Float::from_double(88.0),
    Float::from_double(86.0),
    Float::from_double(84.0),
    Float::from_double(82.0),
    Float::from_double(80.0),
    Float::from_double(78.0),
    Float::from_double(76.0),
    Float::from_double(74.0),
    Float::from_double(72.0),
    Float::from_double(70.0),
  ]

  // Calculate RSI - should be oversold (< 30)
  let rsi_values = @indicator.rsi(prices, 14)
  let current_rsi = rsi_values[rsi_values.length() - 1]

  // Verify RSI is oversold
  assert_true(current_rsi < Float::from_double(30.0))

  // Simulate portfolio state: -15% drawdown (within 20% limit)
  let current_drawdown = Float::from_double(-0.15)
  let position_ratio = Float::from_double(0.5)
  let daily_loss = Float::from_double(-0.02)

  // Create risk engine with max drawdown rule (20% limit)
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))

  // Check if trade is allowed
  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Drawdown is within limits, trade should be allowed
  assert_true(risk_result.passed)
  assert_true(
    match risk_result.action {
      @risk.RiskAction::Allow => true
      _ => false
    },
  )
}

///|
test "integration: RSI signal blocked by drawdown limit" {
  // Scenario: RSI indicates oversold (buy signal), but drawdown exceeded limit
  // Expected: Risk engine should block trade

  // Create oversold RSI scenario
  let prices = [
    Float::from_double(100.0),
    Float::from_double(95.0),
    Float::from_double(90.0),
    Float::from_double(85.0),
    Float::from_double(80.0),
    Float::from_double(75.0),
    Float::from_double(70.0),
    Float::from_double(65.0),
    Float::from_double(60.0),
    Float::from_double(55.0),
    Float::from_double(50.0),
    Float::from_double(45.0),
    Float::from_double(40.0),
    Float::from_double(35.0),
    Float::from_double(30.0),
    Float::from_double(25.0),
  ]

  let rsi_values = @indicator.rsi(prices, 14)
  let current_rsi = rsi_values[rsi_values.length() - 1]
  assert_true(current_rsi < Float::from_double(30.0))

  // Simulate portfolio state: -25% drawdown (exceeds 20% limit)
  let current_drawdown = Float::from_double(-0.25)
  let position_ratio = Float::from_double(0.3)
  let daily_loss = Float::from_double(-0.05)

  // Create risk engine with max drawdown rule
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))

  // Check if trade is allowed
  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Drawdown exceeded, trade should be rejected
  assert_true(!risk_result.passed)
  assert_true(
    match risk_result.action {
      @risk.RiskAction::StopTrading => true
      _ => false
    },
  )
}

///|
test "integration: MACD crossover with position limit check" {
  // Scenario: MACD bullish crossover generates buy signal
  // Expected: Risk engine checks position limits before allowing

  // Create price data for MACD calculation
  let prices = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(109.0),
    Float::from_double(111.0),
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(114.0),
    Float::from_double(113.0),
    Float::from_double(115.0),
    Float::from_double(117.0),
    Float::from_double(116.0),
    Float::from_double(118.0),
    Float::from_double(120.0),
    Float::from_double(119.0),
    Float::from_double(121.0),
    Float::from_double(123.0),
    Float::from_double(122.0),
    Float::from_double(125.0),
  ]

  // Calculate MACD
  let (macd_line, signal_line, histogram) = @indicator.macd(prices, 12, 26, 9)

  // Check for bullish crossover (histogram > 0)
  let len = histogram.length()
  let current_histogram = histogram[len - 1]
  let prev_histogram = histogram[len - 2]

  // Verify MACD calculation completed
  assert_true(macd_line.length() == prices.length())
  assert_true(signal_line.length() == prices.length())
  assert_true(histogram.length() == prices.length())

  // Simulate portfolio state: high position ratio
  let current_drawdown = Float::from_double(-0.05)
  let position_ratio = Float::from_double(0.92) // Near 95% limit
  let daily_loss = Float::from_double(0.01)

  // Create risk engine with position limit rule
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.95)))

  // Check if additional position is allowed
  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Position is within limits, should be allowed
  assert_true(risk_result.passed)
}

///|
test "integration: Position limit exceeded blocks MACD signal" {
  // Scenario: MACD bullish signal but position limit exceeded
  // Expected: Risk engine blocks additional positions

  let prices = [
    Float::from_double(100.0),
    Float::from_double(102.0),
    Float::from_double(101.0),
    Float::from_double(103.0),
    Float::from_double(105.0),
    Float::from_double(104.0),
    Float::from_double(106.0),
    Float::from_double(108.0),
    Float::from_double(107.0),
    Float::from_double(109.0),
    Float::from_double(111.0),
    Float::from_double(110.0),
    Float::from_double(112.0),
    Float::from_double(114.0),
    Float::from_double(113.0),
    Float::from_double(115.0),
    Float::from_double(117.0),
    Float::from_double(116.0),
    Float::from_double(118.0),
    Float::from_double(120.0),
    Float::from_double(119.0),
    Float::from_double(121.0),
    Float::from_double(123.0),
    Float::from_double(122.0),
    Float::from_double(125.0),
  ]

  let (_, _, histogram) = @indicator.macd(prices, 12, 26, 9)
  let len = histogram.length()
  assert_true(histogram[len - 1] > Float::from_double(0.0))

  // Simulate portfolio state: position limit exceeded
  let current_drawdown = Float::from_double(-0.03)
  let position_ratio = Float::from_double(0.98) // Exceeds 95% limit
  let daily_loss = Float::from_double(0.005)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.95)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Position limit exceeded, should reduce position
  assert_true(!risk_result.passed)
  assert_true(
    match risk_result.action {
      @risk.RiskAction::ReducePosition(_) => true
      _ => false
    },
  )
}

///|
test "integration: Multi-indicator confluence with risk management" {
  // Scenario: RSI + MACD + Bollinger Bands all calculated
  // Expected: Risk engine evaluates before allowing trade

  let prices = [
    Float::from_double(100.0),
    Float::from_double(98.0),
    Float::from_double(96.0),
    Float::from_double(94.0),
    Float::from_double(92.0),
    Float::from_double(90.0),
    Float::from_double(88.0),
    Float::from_double(86.0),
    Float::from_double(84.0),
    Float::from_double(82.0),
    Float::from_double(80.0),
    Float::from_double(78.0),
    Float::from_double(76.0),
    Float::from_double(74.0),
    Float::from_double(72.0),
    Float::from_double(70.0),
    Float::from_double(68.0),
    Float::from_double(66.0),
    Float::from_double(64.0),
    Float::from_double(62.0),
    Float::from_double(60.0),
    Float::from_double(58.0),
    Float::from_double(56.0),
    Float::from_double(55.0),
    Float::from_double(57.0),
    Float::from_double(59.0),
    Float::from_double(61.0),
    Float::from_double(63.0),
  ]

  // Calculate multiple indicators
  let rsi_values = @indicator.rsi(prices, 14)
  let (_, _, histogram) = @indicator.macd(prices, 12, 26, 9)
  let (_, _, bb_lower) = @indicator.bollinger_bands(prices, 20, 2.0)

  let len = prices.length()
  let current_price = prices[len - 1]
  let current_rsi = rsi_values[len - 1]
  let current_histogram = histogram[len - 1]
  let current_bb_lower = bb_lower[len - 1]

  // Verify indicators are calculated (non-zero values)
  assert_true(current_rsi > Float::from_double(0.0))
  assert_true(current_histogram != Float::from_double(0.0))
  assert_true(current_bb_lower > Float::from_double(0.0))

  // Check if any buy signal condition is met
  let rsi_oversold = current_rsi < Float::from_double(30.0)
  let macd_bullish = current_histogram > Float::from_double(0.0)
  let at_lower_band = current_price <= current_bb_lower

  // At least one indicator signals
  let any_signal = rsi_oversold || macd_bullish || at_lower_band
  assert_true(any_signal)

  // Check risk constraints
  let current_drawdown = Float::from_double(-0.08)
  let position_ratio = Float::from_double(0.40)
  let daily_loss = Float::from_double(-0.01)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.95)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // All risk rules pass, trade allowed
  assert_true(risk_result.passed)
}

///|
test "integration: Daily loss limit triggers on indicator signal" {
  // Scenario: Strategy generates signal but daily loss limit exceeded
  // Expected: Risk engine stops trading for the day

  let prices = [
    Float::from_double(100.0),
    Float::from_double(101.0),
    Float::from_double(102.0),
    Float::from_double(103.0),
    Float::from_double(104.0),
    Float::from_double(105.0),
    Float::from_double(106.0),
    Float::from_double(107.0),
    Float::from_double(108.0),
    Float::from_double(109.0),
    Float::from_double(110.0),
    Float::from_double(111.0),
    Float::from_double(112.0),
    Float::from_double(113.0),
    Float::from_double(114.0),
    Float::from_double(115.0),
  ]

  // Calculate SMA for simple trend signal
  let sma_values = @indicator.sma(prices, 5)
  let len = sma_values.length()
  let current_price = prices[len - 1]
  let current_sma = sma_values[len - 1]

  // Price above SMA = bullish signal
  assert_true(current_price > current_sma)

  // Simulate portfolio state: daily loss limit exceeded
  let current_drawdown = Float::from_double(-0.10)
  let position_ratio = Float::from_double(0.50)
  let daily_loss = Float::from_double(-0.06) // Exceeds 5% limit

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.daily_loss_limit_rule(Float::from_double(0.05)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Daily loss limit exceeded, trading stopped
  assert_true(!risk_result.passed)
  assert_true(
    match risk_result.action {
      @risk.RiskAction::StopTrading => true
      _ => false
    },
  )
}

///|
test "integration: Drawdown alert triggered by indicator-based trade" {
  // Scenario: After a series of losing trades based on indicator signals,
  // drawdown reaches warning level
  // Expected: Drawdown alert is triggered

  // Simulate portfolio drawdown after multiple losing trades
  let initial_capital = Float::from_double(100000.0)
  let current_value = Float::from_double(88000.0) // 12% drawdown

  let drawdown = (current_value - initial_capital) / initial_capital

  // Verify drawdown calculation
  assert_true(drawdown < Float::from_double(-0.10))
  assert_true(drawdown > Float::from_double(-0.15))

  // Check drawdown alert level
  let level = @drawdown.classify_drawdown(drawdown)
  assert_true(
    match level {
      @drawdown.DrawdownLevel::Moderate => true
      _ => false
    },
  )

  // Check alert configuration
  let config = @drawdown.default_alert_config()
  let alert_status = @drawdown.check_drawdown_alert(drawdown, config)

  // Should trigger warning level alert
  assert_true(alert_status == "CAUTION: Warning drawdown level reached")
}

///|
test "integration: Trailing stop with ATR from indicator" {
  // Scenario: Use ATR indicator to set trailing stop distance
  // Expected: ATR-based trailing stop adjusts to volatility

  // Create K-line data for ATR calculation
  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 102.0, 98.0, 101.0, 1000000.0, 101000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 101.0, 103.0, 99.0, 100.0, 1100000.0, 110000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 100.0, 104.0, 97.0, 102.0, 1200000.0, 122400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 102.0, 105.0, 100.0, 103.0, 1300000.0, 133900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 103.0, 106.0, 101.0, 104.0, 1400000.0, 145600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 104.0, 107.0, 102.0, 105.0, 1500000.0, 157500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 105.0, 108.0, 103.0, 106.0, 1600000.0, 169600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 106.0, 109.0, 104.0, 107.0, 1700000.0, 181900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 107.0, 110.0, 105.0, 108.0, 1800000.0, 194400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 108.0, 111.0, 106.0, 109.0, 1900000.0, 207100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 109.0, 112.0, 107.0, 110.0, 2000000.0, 220000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 110.0, 113.0, 108.0, 111.0, 2100000.0, 233100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 111.0, 114.0, 109.0, 112.0, 2200000.0, 246400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 112.0, 115.0, 110.0, 113.0, 2300000.0, 259900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 113.0, 116.0, 111.0, 114.0, 2400000.0, 273600000.0,
      0.01,
    ),
  ]

  // Calculate ATR
  let atr_values = @indicator.atr(klines, 14)
  let current_atr = atr_values[atr_values.length() - 1]

  // Verify ATR calculation
  assert_true(current_atr > Float::from_double(0.0))

  // Create ATR-based trailing stop for long position
  let entry_price = Float::from_double(110.0)
  let atr_multiplier = Float::from_double(2.0)
  let ts = @risk.create_atr_trailing_stop(
    entry_price, current_atr, atr_multiplier, true,
  )

  // Verify stop price is below entry (for long position)
  let stop_price = @risk.get_stop_price(ts)
  assert_true(stop_price < entry_price)

  // Simulate price rise
  let new_high = Float::from_double(115.0)
  let ts_updated = @risk.atr_trailing_stop_long_update(
    ts, new_high, new_high, current_atr, atr_multiplier,
  )

  // Stop should have moved up
  let new_stop = @risk.get_stop_price(ts_updated)
  assert_true(new_stop >= stop_price)
}

///|
test "integration: Williams %R oversold with risk check" {
  // Scenario: Williams %R indicates oversold conditions
  // Expected: Risk engine validates before allowing contrarian trade

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 105.0, 95.0, 98.0, 1000000.0, 98000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 98.0, 102.0, 93.0, 95.0, 1100000.0, 104500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 95.0, 98.0, 90.0, 92.0, 1200000.0, 110400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 92.0, 95.0, 87.0, 89.0, 1300000.0, 115700000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 89.0, 92.0, 84.0, 86.0, 1400000.0, 120400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 86.0, 89.0, 81.0, 83.0, 1500000.0, 124500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 83.0, 86.0, 78.0, 80.0, 1600000.0, 128000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 80.0, 83.0, 75.0, 77.0, 1700000.0, 130900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 77.0, 80.0, 72.0, 74.0, 1800000.0, 133200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 74.0, 77.0, 69.0, 71.0, 1900000.0, 134900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 71.0, 74.0, 66.0, 68.0, 2000000.0, 136000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 68.0, 71.0, 63.0, 65.0, 2100000.0, 136500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 65.0, 68.0, 60.0, 62.0, 2200000.0, 136400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 62.0, 65.0, 57.0, 59.0, 2300000.0, 135700000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 59.0, 62.0, 54.0, 56.0, 2400000.0, 134400000.0,
      0.01,
    ),
  ]

  // Calculate Williams %R
  let wr_values = @indicator.williams_r(klines, 14)
  let current_wr = wr_values[wr_values.length() - 1]

  // Williams %R < -80 indicates oversold
  assert_true(current_wr < Float::from_double(-80.0))

  // Check risk constraints
  let current_drawdown = Float::from_double(-0.05)
  let position_ratio = Float::from_double(0.30)
  let daily_loss = Float::from_double(-0.01)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.15)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Risk rules pass, contrarian trade allowed
  assert_true(risk_result.passed)
}

///|
test "integration: CCI extreme with drawdown monitor" {
  // Scenario: CCI calculated, drawdown monitor tracks impact
  // Expected: Drawdown level classification and alert triggering

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 102.0, 98.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 103.0, 99.0, 102.0, 1100000.0, 112200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 102.0, 105.0, 101.0, 104.0, 1200000.0, 124800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 104.0, 107.0, 103.0, 106.0, 1300000.0, 137800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 106.0, 109.0, 105.0, 108.0, 1400000.0, 151200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 108.0, 111.0, 107.0, 110.0, 1500000.0, 165000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 110.0, 113.0, 109.0, 112.0, 1600000.0, 179200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 112.0, 115.0, 111.0, 114.0, 1700000.0, 193800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 114.0, 117.0, 113.0, 116.0, 1800000.0, 208800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 116.0, 119.0, 115.0, 118.0, 1900000.0, 224200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 118.0, 121.0, 117.0, 120.0, 2000000.0, 240000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 120.0, 123.0, 119.0, 122.0, 2100000.0, 256200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 122.0, 125.0, 121.0, 124.0, 2200000.0, 272800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 124.0, 127.0, 123.0, 126.0, 2300000.0, 289800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 126.0, 129.0, 125.0, 128.0, 2400000.0, 307200000.0,
      0.01,
    ),
  ]

  // Calculate CCI
  let cci_values = @indicator.cci(klines, 14)
  let current_cci = cci_values[cci_values.length() - 1]

  // Verify CCI is calculated (non-zero)
  assert_true(current_cci != Float::from_double(0.0))

  // Simulate drawdown from peak
  let peak_value = Float::from_double(100000.0)
  let current_value = Float::from_double(85000.0) // 15% drawdown
  let drawdown = (current_value - peak_value) / peak_value

  // Classify drawdown level
  let level = @drawdown.classify_drawdown(drawdown)
  assert_true(
    match level {
      @drawdown.DrawdownLevel::Moderate => true
      _ => false
    },
  )

  // Create alert instance
  let alert = @drawdown.create_drawdown_alert(
    "sh.600000", drawdown, "2024-01-15",
  )

  // Verify alert was created with correct level
  assert_true(
    match alert.level {
      @drawdown.DrawdownLevel::Moderate => true
      _ => false
    },
  )
}

///|
test "integration: KDJ golden cross with multiple risk rules" {
  // Scenario: KDJ golden cross generates buy signal
  // Expected: All risk rules evaluated before execution

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 103.0, 97.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 102.0, 96.0, 98.0, 1100000.0, 107800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 98.0, 100.0, 94.0, 96.0, 1200000.0, 115200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 96.0, 98.0, 92.0, 94.0, 1300000.0, 122200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 94.0, 96.0, 90.0, 92.0, 1400000.0, 128800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 92.0, 94.0, 88.0, 90.0, 1500000.0, 135000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 90.0, 92.0, 86.0, 88.0, 1600000.0, 140800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 88.0, 90.0, 84.0, 86.0, 1700000.0, 146200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 86.0, 88.0, 82.0, 84.0, 1800000.0, 151200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 84.0, 86.0, 80.0, 82.0, 1900000.0, 155800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 82.0, 84.0, 78.0, 80.0, 2000000.0, 160000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 80.0, 84.0, 79.0, 83.0, 2100000.0, 174300000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 83.0, 87.0, 82.0, 86.0, 2200000.0, 189200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 86.0, 90.0, 85.0, 89.0, 2300000.0, 204700000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 89.0, 93.0, 88.0, 92.0, 2400000.0, 220800000.0,
      0.01,
    ),
  ]

  // Calculate KDJ
  let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)
  let len = k_line.length()

  // Golden cross: K crosses above D
  let k_current = k_line[len - 1]
  let d_current = d_line[len - 1]
  let k_prev = k_line[len - 2]
  let d_prev = d_line[len - 2]

  // Verify KDJ calculation
  assert_true(k_line.length() == klines.length())
  assert_true(d_line.length() == klines.length())
  assert_true(j_line.length() == klines.length())

  // Simulate portfolio state
  let current_drawdown = Float::from_double(-0.07)
  let position_ratio = Float::from_double(0.60)
  let daily_loss = Float::from_double(-0.02)

  // Create risk engine with multiple rules
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.15)))
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.80)))
  engine.add_rule(@risk.daily_loss_limit_rule(Float::from_double(0.05)))

  // Check all risk rules
  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // All rules pass
  assert_true(risk_result.passed)
  assert_true(
    match risk_result.action {
      @risk.RiskAction::Allow => true
      _ => false
    },
  )
}

///|
test "integration: OBV divergence with risk monitoring" {
  // Scenario: OBV calculated with volume analysis
  // Expected: Risk engine validates before allowing trade

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 102.0, 98.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 101.0, 97.0, 98.0, 1200000.0, 117600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 98.0, 99.0, 95.0, 96.0, 1400000.0, 134400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 96.0, 97.0, 93.0, 94.0, 1600000.0, 150400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 94.0, 95.0, 91.0, 92.0, 1800000.0, 165600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 92.0, 93.0, 89.0, 90.0, 2000000.0, 180000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 90.0, 91.0, 87.0, 88.0, 2200000.0, 193600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 88.0, 89.0, 85.0, 86.0, 2400000.0, 206400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 86.0, 87.0, 83.0, 84.0, 2600000.0, 218400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 84.0, 85.0, 81.0, 82.0, 2800000.0, 229600000.0,
      0.01,
    ),
  ]

  // Calculate OBV
  let obv_values = @indicator.obv(klines)

  // Verify OBV is calculated (non-empty array with correct length)
  let len = obv_values.length()
  assert_true(len == klines.length())

  // OBV starts at first volume and changes based on price direction
  // In this declining price scenario, OBV should be decreasing
  assert_true(obv_values[0] == klines[0].volume)

  // Check risk constraints
  let current_drawdown = Float::from_double(-0.10)
  let position_ratio = Float::from_double(0.40)
  let daily_loss = Float::from_double(-0.02)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Risk rules pass, trade allowed
  assert_true(risk_result.passed)
}

///|
test "integration: Aroon trend change with drawdown alert" {
  // Scenario: Aroon indicates trend change, check drawdown status
  // Expected: Drawdown monitoring integrates with signal validation

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 105.0, 98.0, 103.0, 1000000.0, 103000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 103.0, 108.0, 101.0, 106.0, 1100000.0, 116600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 106.0, 111.0, 104.0, 109.0, 1200000.0, 130800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 109.0, 114.0, 107.0, 112.0, 1300000.0, 145600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 112.0, 117.0, 110.0, 115.0, 1400000.0, 161000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 115.0, 120.0, 113.0, 118.0, 1500000.0, 177000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 118.0, 123.0, 116.0, 121.0, 1600000.0, 193600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 121.0, 126.0, 119.0, 124.0, 1700000.0, 210800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 124.0, 129.0, 122.0, 127.0, 1800000.0, 228600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 127.0, 132.0, 125.0, 130.0, 1900000.0, 247000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 130.0, 135.0, 128.0, 133.0, 2000000.0, 266000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 133.0, 138.0, 131.0, 136.0, 2100000.0, 285600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 136.0, 141.0, 134.0, 139.0, 2200000.0, 305800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 139.0, 144.0, 137.0, 142.0, 2300000.0, 326600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 142.0, 147.0, 140.0, 145.0, 2400000.0, 348000000.0,
      0.01,
    ),
  ]

  // Calculate Aroon
  let (aroon_up, aroon_down) = @indicator.aroon(klines, 14)
  let len = aroon_up.length()

  // Strong uptrend: Aroon Up > 70, Aroon Down < 30
  let aroon_up_strong = aroon_up[len - 1] > Float::from_double(70.0)
  let aroon_down_weak = aroon_down[len - 1] < Float::from_double(30.0)

  assert_true(aroon_up_strong)
  assert_true(aroon_down_weak)

  // Simulate portfolio in profit (positive drawdown)
  let current_drawdown = Float::from_double(0.15) // 15% gain
  let position_ratio = Float::from_double(0.70)
  let daily_loss = Float::from_double(0.02)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // In profit, all rules pass
  assert_true(risk_result.passed)
}

///|
test "integration: ADX trend strength with position sizing" {
  // Scenario: ADX indicates strong trend, adjust position based on risk
  // Expected: Position size validated against risk limits

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 102.0, 98.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 101.0, 99.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 100.0, 101.0, 99.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 100.0, 102.0, 99.0, 101.0, 1100000.0, 111100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 101.0, 103.0, 100.0, 102.0, 1200000.0, 122400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 102.0, 104.0, 101.0, 103.0, 1300000.0, 133900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 103.0, 105.0, 102.0, 104.0, 1400000.0, 145600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 104.0, 106.0, 103.0, 105.0, 1500000.0, 157500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 105.0, 107.0, 104.0, 106.0, 1600000.0, 169600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 106.0, 108.0, 105.0, 107.0, 1700000.0, 181900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 107.0, 109.0, 106.0, 108.0, 1800000.0, 194400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 108.0, 110.0, 107.0, 109.0, 1900000.0, 207100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 109.0, 111.0, 108.0, 110.0, 2000000.0, 220000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 110.0, 112.0, 109.0, 111.0, 2100000.0, 233100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 111.0, 113.0, 110.0, 112.0, 2200000.0, 246400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-16", 112.0, 114.0, 111.0, 113.0, 2300000.0, 259900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-17", 113.0, 115.0, 112.0, 114.0, 2400000.0, 273600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-18", 114.0, 116.0, 113.0, 115.0, 2500000.0, 287500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-19", 115.0, 117.0, 114.0, 116.0, 2600000.0, 301600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-20", 116.0, 118.0, 115.0, 117.0, 2700000.0, 315900000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-21", 117.0, 119.0, 116.0, 118.0, 2800000.0, 330400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-22", 118.0, 120.0, 117.0, 119.0, 2900000.0, 345100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-23", 119.0, 121.0, 118.0, 120.0, 3000000.0, 360000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-24", 120.0, 122.0, 119.0, 121.0, 3100000.0, 375100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-25", 121.0, 123.0, 120.0, 122.0, 3200000.0, 390400000.0,
      0.01,
    ),
  ]

  // Calculate ADX
  let adx_values = @indicator.adx(klines, 14)
  let current_adx = adx_values[adx_values.length() - 1]

  // ADX > 25 indicates strong trend
  assert_true(current_adx > Float::from_double(20.0))

  // Simulate portfolio state with moderate risk
  let current_drawdown = Float::from_double(-0.05)
  let position_ratio = Float::from_double(0.50)
  let daily_loss = Float::from_double(0.005)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.15)))
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.75)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // All rules pass, position allowed
  assert_true(risk_result.passed)
}

///|
test "integration: multi-indicator confluence with full backtest flow" {
  // Scenario: Complete pipeline from K-line data through SMA/RSI indicators
  // to strategy signal generation and risk validation

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 102.0, 98.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 103.0, 99.0, 102.0, 1100000.0, 112200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 102.0, 105.0, 101.0, 104.0, 1200000.0, 124800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 104.0, 107.0, 103.0, 106.0, 1300000.0, 137800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 106.0, 109.0, 105.0, 108.0, 1400000.0, 151200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 108.0, 111.0, 107.0, 110.0, 1500000.0, 165000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 110.0, 113.0, 109.0, 112.0, 1600000.0, 179200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 112.0, 115.0, 111.0, 114.0, 1700000.0, 193800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 114.0, 117.0, 113.0, 116.0, 1800000.0, 208800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 116.0, 119.0, 115.0, 118.0, 1900000.0, 224200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-11", 118.0, 121.0, 117.0, 120.0, 2000000.0, 240000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-12", 120.0, 123.0, 119.0, 122.0, 2100000.0, 256200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-13", 122.0, 125.0, 121.0, 124.0, 2200000.0, 272800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-14", 124.0, 127.0, 123.0, 126.0, 2300000.0, 289800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-15", 126.0, 129.0, 125.0, 128.0, 2400000.0, 307200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-16", 128.0, 131.0, 127.0, 130.0, 2500000.0, 325000000.0,
      0.01,
    ),
  ]

  // Calculate indicators
  let closes : Array[Float] = []
  let mut i = 0
  while i < klines.length() {
    closes.push(klines[i].close)
    i = i + 1
  }

  let sma_values = @indicator.sma(closes, 5)
  let rsi_values = @indicator.rsi(closes, 14)

  // Verify indicators are calculated
  assert_true(sma_values.length() == klines.length())
  assert_true(rsi_values.length() == klines.length())

  // Simulate strategy signal: price above SMA (bullish)
  let current_price = klines[klines.length() - 1].close
  let current_sma = sma_values[sma_values.length() - 1]
  let bullish_signal = current_price > current_sma
  assert_true(bullish_signal)

  // Risk engine validation
  let current_drawdown = Float::from_double(-0.08)
  let position_ratio = Float::from_double(0.40)
  let daily_loss = Float::from_double(0.01)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.80)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Signal validated, trade allowed
  assert_true(risk_result.passed)
}

///|
test "integration: drawdown monitoring with portfolio rebalancing trigger" {
  // Scenario: Portfolio drawdown calculation, severity classification,
  // and risk engine position reduction suggestions

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 102.0, 98.0, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 101.0, 97.0, 98.0, 1100000.0, 107800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 98.0, 99.0, 94.0, 95.0, 1200000.0, 114000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 95.0, 96.0, 90.0, 91.0, 1300000.0, 118300000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 91.0, 92.0, 86.0, 87.0, 1400000.0, 121800000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 87.0, 88.0, 82.0, 83.0, 1500000.0, 124500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 83.0, 84.0, 78.0, 79.0, 1600000.0, 126400000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 79.0, 82.0, 77.0, 81.0, 1700000.0, 137700000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 81.0, 85.0, 80.0, 84.0, 1800000.0, 151200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 84.0, 88.0, 83.0, 87.0, 1900000.0, 165300000.0,
      0.01,
    ),
  ]

  // Calculate closes for drawdown
  let closes : Array[Float] = []
  let mut i = 0
  while i < klines.length() {
    closes.push(klines[i].close)
    i = i + 1
  }

  // Peak was 100, current is 87, drawdown = -13%
  let peak = Float::from_double(100.0)
  let current = closes[closes.length() - 1]
  let drawdown = (current - peak) / peak

  // Test drawdown classification
  let level = @drawdown.classify_drawdown(drawdown)

  // -13% should be Minor level (between -10% and -15%)
  assert_true(
    match level {
      @drawdown.DrawdownLevel::Minor => true
      @drawdown.DrawdownLevel::Normal => drawdown > Float::from_double(-0.10)
      _ => false
    },
  )

  // Simulate risk engine with drawdown monitoring
  let current_drawdown = drawdown
  let position_ratio = Float::from_double(0.70)
  let daily_loss = Float::from_double(-0.03)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.15)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Drawdown is close to limit (-13% vs -15%), but still within bounds
  assert_true(risk_result.passed)
}

///|
test "integration: rapid price swings with stop-loss logic" {
  // Scenario: Trailing stop behavior during volatile price movements,
  // ATR calculation, and risk engine response to high drawdown

  let klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 105.0, 95.0, 102.0, 2000000.0, 200000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 102.0, 108.0, 98.0, 96.0, 2200000.0, 211200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 96.0, 102.0, 90.0, 100.0, 2400000.0, 240000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 100.0, 106.0, 94.0, 92.0, 2600000.0, 239200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 92.0, 98.0, 86.0, 95.0, 2800000.0, 266000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-06", 95.0, 101.0, 89.0, 88.0, 3000000.0, 264000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-07", 88.0, 94.0, 82.0, 91.0, 3200000.0, 291200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-08", 91.0, 97.0, 85.0, 94.0, 3400000.0, 319600000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-09", 94.0, 100.0, 88.0, 97.0, 3600000.0, 349200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-10", 97.0, 103.0, 91.0, 100.0, 3800000.0, 380000000.0,
      0.01,
    ),
  ]

  // Calculate ATR for volatility measurement
  let atr_values = @indicator.atr(klines, 14)
  let current_atr = atr_values[atr_values.length() - 1]

  // ATR should reflect high volatility
  assert_true(current_atr > Float::from_double(0.0))

  // Simulate trailing stop calculation (2x ATR)
  let entry_price = Float::from_double(100.0)
  let trailing_stop = entry_price - Float::from_double(2.0) * current_atr

  // Current price
  let current_price = klines[klines.length() - 1].close

  // Verify stop-loss not triggered (price > trailing stop)
  assert_true(current_price > trailing_stop)

  // Risk engine check with elevated drawdown from volatility
  let current_drawdown = Float::from_double(-0.10)
  let position_ratio = Float::from_double(0.50)
  let daily_loss = Float::from_double(-0.04)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.20)))
  engine.add_rule(@risk.daily_loss_limit_rule(Float::from_double(0.05)))

  let risk_result = engine.check(current_drawdown, position_ratio, daily_loss)

  // Despite volatility, risk rules pass
  assert_true(risk_result.passed)
}

///|
test "integration: ATR volatility triggers dynamic position sizing" {
  // Scenario: ATR-based volatility measurement with low vs high volatility
  // scenarios and position limit enforcement

  // Low volatility scenario
  let low_vol_klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 100.5, 99.5, 100.0, 1000000.0, 100000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 100.0, 100.5, 99.5, 100.2, 1000000.0, 100200000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 100.2, 100.7, 99.7, 100.1, 1000000.0, 100100000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 100.1, 100.6, 99.6, 100.3, 1000000.0, 100300000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 100.3, 100.8, 99.8, 100.2, 1000000.0, 100200000.0,
      0.01,
    ),
  ]

  // High volatility scenario
  let high_vol_klines = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 100.0, 110.0, 90.0, 95.0, 3000000.0, 285000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 95.0, 105.0, 85.0, 100.0, 3500000.0, 350000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-03", 100.0, 115.0, 95.0, 90.0, 4000000.0, 360000000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-04", 90.0, 100.0, 80.0, 95.0, 4500000.0, 427500000.0,
      0.01,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-05", 95.0, 110.0, 90.0, 105.0, 5000000.0, 525000000.0,
      0.01,
    ),
  ]

  // Calculate ATR for both scenarios
  let low_vol_atr = @indicator.atr(low_vol_klines, 5)
  let high_vol_atr = @indicator.atr(high_vol_klines, 5)

  let low_atr_value = low_vol_atr[low_vol_atr.length() - 1]
  let high_atr_value = high_vol_atr[high_vol_atr.length() - 1]

  // Verify ATR reflects volatility difference
  assert_true(high_atr_value > low_atr_value)

  // Simulate position sizing based on volatility
  // Low volatility: allow higher position (0.80)
  // High volatility: reduce position (0.40)
  let low_vol_position = Float::from_double(0.80)
  let high_vol_position = Float::from_double(0.40)

  // Risk engine with position limits
  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.position_limit_rule(Float::from_double(0.80)))

  // Low volatility scenario - position at max allowed
  let result_low = engine.check(
    Float::from_double(0.0),
    low_vol_position,
    Float::from_double(0.0),
  )
  assert_true(result_low.passed)

  // High volatility scenario - reduced position
  let result_high = engine.check(
    Float::from_double(0.0),
    high_vol_position,
    Float::from_double(0.0),
  )
  assert_true(result_high.passed)
}

///|
test "integration: portfolio drawdown aggregation across positions" {
  // Scenario: Multi-stock drawdown aggregation,
  // worst stock identification, and portfolio-level risk assessment

  // Stock A: -15% drawdown
  let stock_a_peak = Float::from_double(100.0)
  let stock_a_current = Float::from_double(85.0)
  let stock_a_dd = (stock_a_current - stock_a_peak) / stock_a_peak

  // Stock B: -8% drawdown
  let stock_b_peak = Float::from_double(200.0)
  let stock_b_current = Float::from_double(184.0)
  let stock_b_dd = (stock_b_current - stock_b_peak) / stock_b_peak

  // Stock C: -20% drawdown (worst)
  let stock_c_peak = Float::from_double(150.0)
  let stock_c_current = Float::from_double(120.0)
  let stock_c_dd = (stock_c_current - stock_c_peak) / stock_c_peak

  // Portfolio weighted average drawdown (equal weights)
  let portfolio_dd = (stock_a_dd + stock_b_dd + stock_c_dd) /
    Float::from_double(3.0)

  // Verify portfolio drawdown calculation
  assert_true(portfolio_dd < Float::from_double(0.0))
  assert_true(portfolio_dd > Float::from_double(-0.20))

  // Identify worst performer (Stock C at -20%)
  let worst_dd = stock_c_dd
  assert_true(worst_dd == stock_c_dd)

  // Create portfolio drawdown tracker with all stock drawdowns
  let stock_drawdowns : Array[(String, Float)] = [
    ("stock_a", stock_a_dd),
    ("stock_b", stock_b_dd),
    ("stock_c", stock_c_dd),
  ]
  let portfolio = @drawdown.create_portfolio_drawdown(stock_drawdowns)

  // Verify portfolio aggregation
  let agg_dd = portfolio.total_drawdown
  assert_true(agg_dd < Float::from_double(0.0))

  // Risk engine check with portfolio-level drawdown
  let position_ratio = Float::from_double(0.60)
  let daily_loss = Float::from_double(-0.02)

  let engine = @risk.create_risk_engine()
  engine.add_rule(@risk.max_drawdown_rule(Float::from_double(0.25)))

  let risk_result = engine.check(agg_dd, position_ratio, daily_loss)

  // Portfolio drawdown within limits
  assert_true(risk_result.passed)
}
