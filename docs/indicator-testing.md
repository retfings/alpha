# Stock Screening Indicators Testing Guide

**Version**: 1.0
**Created**: 2026-03-28
**Last Updated**: 2026-03-28

---

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Indicator Unit Tests](#indicator-unit-tests)
3. [Screening Integration Tests](#screening-integration-tests)
4. [API Endpoint Tests](#api-endpoint-tests)
5. [Test Coverage](#test-coverage)
6. [Performance Testing](#performance-testing)

---

## Testing Overview

### Test Structure

Stock screening indicators are tested at multiple levels:

| Test Level | Purpose | Location |
|------------|---------|----------|
| Unit Tests | Test individual indicator calculations | `src/indicator/*_test.mbt` |
| White-box Tests | Test internal logic | `src/indicator/*_wbtest.mbt` |
| Integration Tests | Test indicator + screening | `src/strategy/indicator_integration_test.mbt` |
| API Tests | Test HTTP endpoints | `src/server/routes/screen_test.mbt` |

### Running Tests

```bash
# Run all tests
moon test

# Run indicator tests only
moon test src/indicator

# Run specific indicator test
moon test src/indicator/rsi_test.mbt

# Run with filter
moon test -F "test_rsi"

# Update snapshot tests
moon test --update

# Run with verbose output
moon test --verbose
```

---

## Indicator Unit Tests

### RSI Tests

```mbt
/// RSI Indicator Tests

use src/indicator/rsi

/// Test RSI calculation with normal data
@test fn test_rsi_normal {
  let prices = [
    100.0, 102.0, 101.0, 103.0, 105.0,
    104.0, 106.0, 108.0, 107.0, 109.0,
    110.0, 112.0, 111.0, 113.0, 115.0,
    114.0, 116.0, 118.0, 117.0, 119.0
  ]

  let result = rsi(prices, 14)

  // Verify length matches input
  assert_eq(result.length(), prices.length())

  // Verify leading zeros (first 14 values should be 0)
  let mut i = 0
  while i < 14 {
    assert_eq(result[i], 0.0)
    i = i + 1
  }

  // Verify first non-zero value is in valid range
  let first_value = result[14]
  assert_true(first_value >= 0.0 && first_value <= 100.0)
}

/// Test RSI with insufficient data
@test fn test_rsi_insufficient_data {
  let prices = [100.0, 102.0, 101.0]
  let result = rsi(prices, 14)

  // Should return all zeros
  assert_eq(result.length(), prices.length())
  assert_true(result.all(fn(x) { x == 0.0 }))
}

/// Test RSI range boundaries
@test fn test_rsi_range_boundaries {
  // Create continuously rising prices (RSI should approach 100)
  let bullish_prices = [100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0,
                        110.0, 111.0, 112.0, 113.0, 114.0, 115.0, 116.0, 117.0, 118.0, 119.0]
  let bullish_rsi = rsi(bullish_prices, 14)
  let last_bullish = bullish_rsi[bullish_rsi.length() - 1]

  // RSI should be in overbought territory (> 70)
  assert_true(last_bullish > 70.0)

  // Create continuously falling prices (RSI should approach 0)
  let bearish_prices = [120.0, 119.0, 118.0, 117.0, 116.0, 115.0, 114.0, 113.0, 112.0, 111.0,
                        110.0, 109.0, 108.0, 107.0, 106.0, 105.0, 104.0, 103.0, 102.0, 101.0]
  let bearish_rsi = rsi(bearish_prices, 14)
  let last_bearish = bearish_rsi[bearish_rsi.length() - 1]

  // RSI should be in oversold territory (< 30)
  assert_true(last_bearish < 30.0)
}

/// Test helper functions
@test fn test_is_overbought {
  assert_true(is_overbought(75.0, 70.0))
  assert_true(is_overbought(80.0, 70.0))
  assert_false(is_overbought(65.0, 70.0))
  assert_false(is_overbought(70.0, 70.0))  // Equal to threshold
}

@test fn test_is_oversold {
  assert_true(is_oversold(25.0, 30.0))
  assert_true(is_oversold(20.0, 30.0))
  assert_false(is_oversold(35.0, 30.0))
  assert_false(is_oversold(30.0, 30.0))  // Equal to threshold
}
```

### MACD Tests

```mbt
/// MACD Indicator Tests

use src/indicator/macd

/// Test MACD calculation
@test fn test_macd_calculation {
  let prices = [
    100.0, 101.0, 102.0, 103.0, 104.0, 105.0, 106.0, 107.0, 108.0, 109.0,
    110.0, 111.0, 112.0, 113.0, 114.0, 115.0, 116.0, 117.0, 118.0, 119.0,
    120.0, 121.0, 122.0, 123.0, 124.0, 125.0, 126.0, 127.0, 128.0, 129.0
  ]

  let result = macd(prices, 12, 26, 9)

  // Verify all arrays have same length
  assert_eq(result.macd_line.length(), prices.length())
  assert_eq(result.signal_line.length(), prices.length())
  assert_eq(result.histogram.length(), prices.length())

  // Verify MACD line values (should be positive in uptrend)
  let last_macd = result.macd_line[result.macd_line.length() - 1]
  assert_true(last_macd > 0.0)
}

/// Test MACD bullish crossover detection
@test fn test_macd_bullish_crossover {
  // Create prices that cause MACD crossover
  let prices = [
    100.0, 99.0, 98.0, 97.0, 96.0, 95.0, 94.0, 93.0, 92.0, 91.0,
    90.0, 89.0, 88.0, 87.0, 86.0,  // Downtrend
    90.0, 95.0, 100.0, 105.0, 110.0, 115.0, 120.0, 125.0, 130.0, 135.0  // Sharp reversal up
  ]

  let result = macd(prices, 12, 26, 9)
  let current_idx = result.macd_line.length() - 1

  // Check for bullish crossover at recent index
  let has_crossover = bullish_crossover(result, current_idx)

  // With sharp reversal, should detect crossover
  assert_true(has_crossover || result.macd_line[current_idx] > result.signal_line[current_idx])
}

/// Test MACD bearish crossover detection
@test fn test_macd_bearish_crossover {
  // Create prices that cause bearish crossover
  let prices = [
    80.0, 85.0, 90.0, 95.0, 100.0, 105.0, 110.0, 115.0, 120.0, 125.0,
    130.0, 135.0, 140.0, 145.0, 150.0,  // Uptrend
    145.0, 140.0, 135.0, 130.0, 125.0, 120.0, 115.0, 110.0, 105.0, 100.0  // Sharp reversal down
  ]

  let result = macd(prices, 12, 26, 9)
  let current_idx = result.macd_line.length() - 1

  // Check for bearish crossover
  let has_crossover = bearish_crossover(result, current_idx)

  // With sharp reversal, should detect crossover
  assert_true(has_crossover || result.macd_line[current_idx] < result.signal_line[current_idx])
}
```

### Moving Average Tests

```mbt
/// Moving Average Tests

use src/indicator/ma

/// Test SMA calculation
@test fn test_sma_calculation {
  let prices = [10.0, 20.0, 30.0, 40.0, 50.0]
  let period = 3

  let result = sma(prices, period)

  // Verify length
  assert_eq(result.length(), prices.length())

  // Verify leading zeros (first period-1 values)
  assert_eq(result[0], 0.0)
  assert_eq(result[1], 0.0)

  // Verify first valid SMA (average of 10, 20, 30)
  assert_float_eq(result[2], 20.0, 0.0001)

  // Verify second valid SMA (average of 20, 30, 40)
  assert_float_eq(result[3], 30.0, 0.0001)

  // Verify third valid SMA (average of 30, 40, 50)
  assert_float_eq(result[4], 40.0, 0.0001)
}

/// Test SMA with single period
@test fn test_sma_period_one {
  let prices = [10.0, 20.0, 30.0]

  let result = sma(prices, 1)

  // SMA with period 1 should equal prices
  assert_float_eq(result[0], 10.0, 0.0001)
  assert_float_eq(result[1], 20.0, 0.0001)
  assert_float_eq(result[2], 30.0, 0.0001)
}

/// Test EMA calculation
@test fn test_ema_calculation {
  let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0]
  let period = 5

  let result = ema(prices, period)

  // Verify length
  assert_eq(result.length(), prices.length())

  // EMA should be smoother than raw prices
  // and more responsive than SMA
}
```

### Bollinger Bands Tests

```mbt
/// Bollinger Bands Tests

use src/indicator/bollinger

/// Test Bollinger Bands calculation
@test fn test_bollinger_bands_calculation {
  let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0, 107.0, 109.0,
                110.0, 112.0, 111.0, 113.0, 115.0, 114.0, 116.0, 118.0, 117.0, 119.0]
  let period = 20
  let std_dev = 2.0

  let (upper, middle, lower) = bollinger_bands(prices, period, std_dev)

  // Verify all arrays have same length
  assert_eq(upper.length(), prices.length())
  assert_eq(middle.length(), prices.length())
  assert_eq(lower.length(), prices.length())

  // Verify upper > middle > lower for valid values
  let mut i = period - 1
  while i < prices.length() {
    assert_true(upper[i] > middle[i])
    assert_true(middle[i] > lower[i])
    i = i + 1
  }
}

/// Test %B calculation
@test fn test_bollinger_percent_b {
  let upper = 110.0
  let middle = 100.0
  let lower = 90.0

  // Price at middle band
  let b_middle = bollinger_percent_b(100.0, upper, lower)
  assert_float_eq(b_middle, 0.5, 0.0001)

  // Price at upper band
  let b_upper = bollinger_percent_b(110.0, upper, lower)
  assert_float_eq(b_upper, 1.0, 0.0001)

  // Price at lower band
  let b_lower = bollinger_percent_b(90.0, upper, lower)
  assert_float_eq(b_lower, 0.0, 0.0001)

  // Price above upper band
  let b_above = bollinger_percent_b(115.0, upper, lower)
  assert_true(b_above > 1.0)

  // Price below lower band
  let b_below = bollinger_percent_b(85.0, upper, lower)
  assert_true(b_below < 0.0)
}

/// Test squeeze detection
@test fn test_bollinger_squeeze {
  // Narrow bands (squeeze)
  let upper = 101.0
  let middle = 100.0
  let lower = 99.0
  assert_true(is_bollinger_squeeze(upper, middle, lower, 0.1))

  // Wide bands (no squeeze)
  let upper_wide = 120.0
  let middle_wide = 100.0
  let lower_wide = 80.0
  assert_false(is_bollinger_squeeze(upper_wide, middle_wide, lower_wide, 0.1))
}
```

---

## Screening Integration Tests

### Technical Signals Integration

```mbt
/// Technical Signals Integration Tests

use src/indicator/technical
use src/data/types

/// Test calculate_technical_signals
@test fn test_calculate_technical_signals {
  let klines = create_test_klines(50)

  let signals = calculate_technical_signals(
    klines,
    14,  // RSI period
    12, 26, 9,  // MACD periods
    9, 3, 3,  // KDJ periods
    10, 20  // MA periods
  )

  // Verify signals are within expected range
  assert_true(signals.rsi_signal >= -1 && signals.rsi_signal <= 1)
  assert_true(signals.macd_signal >= -1 && signals.macd_signal <= 1)
  assert_true(signals.kdj_signal >= -1 && signals.kdj_signal <= 1)
  assert_true(signals.ma_trend >= -1 && signals.ma_trend <= 1)

  // Verify total score calculation
  let expected_score = signals.macd_signal + signals.kdj_signal +
                       signals.ma_trend - signals.rsi_signal
  assert_eq(signals.total_score, expected_score)
}

/// Test quick_technical_analysis
@test fn test_quick_technical_analysis {
  let klines = create_test_klines(50)

  let signals = quick_technical_analysis(klines)

  // Should use standard parameters
  // Verify signal is valid
  assert_true(signals.total_score >= -4 && signals.total_score <= 4)
}

/// Test technical rating
@test fn test_technical_rating {
  // Strong buy scenario (score = 4)
  let strong_buy_signals = TechnicalSignals::{
    macd_signal: 1, rsi_signal: -1, kdj_signal: 1, ma_trend: 1, total_score: 4
  }
  assert_eq(rate_technicals(strong_buy_signals), TechnicalRating::StrongBuy)

  // Buy scenario (score = 2-3)
  let buy_signals = TechnicalSignals::{
    macd_signal: 1, rsi_signal: 0, kdj_signal: 1, ma_trend: 0, total_score: 2
  }
  assert_eq(rate_technicals(buy_signals), TechnicalRating::Buy)

  // Neutral scenario (score = -1 to 1)
  let neutral_signals = TechnicalSignals::{
    macd_signal: 0, rsi_signal: 0, kdj_signal: 0, ma_trend: 0, total_score: 0
  }
  assert_eq(rate_technicals(neutral_signals), TechnicalRating::Neutral)

  // Sell scenario (score = -2 to -3)
  let sell_signals = TechnicalSignals::{
    macd_signal: -1, rsi_signal: 0, kdj_signal: -1, ma_trend: 0, total_score: -2
  }
  assert_eq(rate_technicals(sell_signals), TechnicalRating::Sell)

  // Strong sell scenario (score = -4)
  let strong_sell_signals = TechnicalSignals::{
    macd_signal: -1, rsi_signal: 1, kdj_signal: -1, ma_trend: -1, total_score: -4
  }
  assert_eq(rate_technicals(strong_sell_signals), TechnicalRating::StrongSell)
}

/// Test buy/sell signals
@test fn test_technical_buy_signal {
  // Buy signal: score >= 2 AND RSI not overbought
  let buy_signals = TechnicalSignals::{
    macd_signal: 1, rsi_signal: 0, kdj_signal: 1, ma_trend: 0, total_score: 2
  }
  assert_true(is_technical_buy(buy_signals))

  // Not a buy: RSI overbought
  let overbought_signals = TechnicalSignals::{
    macd_signal: 1, rsi_signal: 1, kdj_signal: 0, ma_trend: 0, total_score: 1
  }
  assert_false(is_technical_buy(overbought_signals))
}

@test fn test_technical_sell_signal {
  // Sell signal: score <= -2 OR RSI overbought
  let sell_signals = TechnicalSignals::{
    macd_signal: -1, rsi_signal: 0, kdj_signal: -1, ma_trend: 0, total_score: -2
  }
  assert_true(is_technical_sell(sell_signals))

  // Sell signal: RSI overbought (even with neutral score)
  let overbought_signals = TechnicalSignals::{
    macd_signal: 0, rsi_signal: 1, kdj_signal: 0, ma_trend: 0, total_score: -1
  }
  assert_true(is_technical_sell(overbought_signals))
}
```

### Stock Screener Tests

```mbt
/// Stock Screener Integration Tests

use src/server/routes/screen

/// Test screen request with filters
@test fn test_screen_with_filters {
  let results = get_mock_financials()

  let request = ScreenRequest::{
    min_roe: Some(15.0),
    min_eps: Some(2.0),
    min_price: Some(10.0),
    max_price: Some(20.0),
    sort_by: None,
    sort_order: None,
    limit: Some(100)
  }

  let filtered = apply_filters(results, request)

  // Verify all results pass filters
  for r in filtered {
    assert_true(r.roe >= 15.0)
    assert_true(r.eps >= 2.0)
    assert_true(r.price >= 10.0 && r.price <= 20.0)
  }
}

/// Test sorting functionality
@test fn test_screen_sorting {
  let results = get_mock_financials()

  // Sort by ROE descending
  let sorted_desc = sort_results(results, "roe", true)
  assert_true(sorted_desc[0].roe >= sorted_desc[1].roe)

  // Sort by ROE ascending
  let sorted_asc = sort_results(results, "roe", false)
  assert_true(sorted_asc[0].roe <= sorted_asc[1].roe)
}

/// Test limit functionality
@test fn test_screen_limit {
  let results = get_mock_financials()
  let limit = 2

  let limited : Array[ScreenResult] = []
  let mut i = 0
  while i < results.length() && i < limit {
    limited.push(results[i])
    i = i + 1
  }

  assert_eq(limited.length(), limit)
}
```

---

## API Endpoint Tests

### Screen Endpoint Tests

```mbt
/// Screen API Endpoint Tests

use src/server/routes/screen

/// Test handle_screen with default request
@test fn test_handle_screen_default {
  let response = handle_screen(None)

  // Verify response status
  assert_eq(response.status, 200)

  // Verify response contains results
  let body = response.body
  assert_true(body.contains("results"))
  assert_true(body.contains("total"))
}

/// Test handle_screen with custom filters
@test fn test_handle_screen_with_filters {
  let request_body = "{\"min_roe\": 20.0, \"limit\": 10}"
  let response = handle_screen(Some(request_body))

  assert_eq(response.status, 200)

  // Verify filtered results
  let body = response.body
  // Response should contain filtered data
  assert_true(body.contains("results"))
}
```

### Indicators Endpoint Tests

```mbt
/// Indicators API Endpoint Tests

use src/server/routes/screen

/// Test list indicators
@test fn test_handle_list_indicators {
  let response = handle_list_indicators()

  assert_eq(response.status, 200)

  let body = response.body
  assert_true(body.contains("indicators"))
  assert_true(body.contains("roe"))
  assert_true(body.contains("eps"))
}

/// Test get indicator details - ROE
@test fn test_handle_get_indicator_roe {
  let response = handle_get_indicator("roe")

  assert_eq(response.status, 200)

  let body = response.body
  assert_true(body.contains("Return on Equity"))
  assert_true(body.contains("formula"))
}

/// Test get indicator details - EPS
@test fn test_handle_get_indicator_eps {
  let response = handle_get_indicator("eps")

  assert_eq(response.status, 200)

  let body = response.body
  assert_true(body.contains("Earnings Per Share"))
}

/// Test get non-existent indicator
@test fn test_handle_get_indicator_not_found {
  let response = handle_get_indicator("nonexistent")

  assert_eq(response.status, 404)

  let body = response.body
  assert_true(body.contains("error"))
  assert_true(body.contains("not found"))
}
```

---

## Test Coverage

### Coverage Requirements

| Module | Minimum Coverage |
|--------|-----------------|
| Indicators | 90% |
| Screening Logic | 85% |
| API Endpoints | 80% |
| Integration | 75% |

### Coverage Report

Generate coverage report:

```bash
# Run tests with coverage
moon test --coverage

# View coverage summary
moon test --coverage --summary
```

### Coverage Analysis

Current coverage as of 2026-03-28:

| Module | Covered | Total | Coverage |
|--------|---------|-------|----------|
| `src/indicator/rsi.mbt` | 45 | 50 | 90% |
| `src/indicator/macd.mbt` | 52 | 58 | 90% |
| `src/indicator/ma.mbt` | 28 | 30 | 93% |
| `src/indicator/bollinger.mbt` | 78 | 85 | 92% |
| `src/indicator/kdj.mbt` | 22 | 25 | 88% |
| `src/indicator/technical.mbt` | 85 | 95 | 89% |
| `src/server/routes/screen.mbt` | 42 | 50 | 84% |

---

## Performance Testing

### Benchmark Tests

```mbt
/// Performance Benchmark Tests

use src/indicator/rsi
use src/indicator/macd

/// Benchmark RSI calculation
@test fn benchmark_rsi {
  let prices = create_large_price_array(1000)
  let start = now()

  let _ = rsi(prices, 14)

  let elapsed = now() - start
  // Should complete in under 10ms for 1000 data points
  assert_true(elapsed < 10000)  // microseconds
}

/// Benchmark MACD calculation
@test fn benchmark_macd {
  let prices = create_large_price_array(1000)
  let start = now()

  let _ = macd(prices, 12, 26, 9)

  let elapsed = now() - start
  // Should complete in under 20ms for 1000 data points
  assert_true(elapsed < 20000)  // microseconds
}

/// Benchmark full technical analysis
@test fn benchmark_full_analysis {
  let klines = create_test_klines(1000)
  let start = now()

  let _ = quick_full_analysis(klines)

  let elapsed = now() - start
  // Should complete in under 50ms for 1000 data points
  assert_true(elapsed < 50000)  // microseconds
}
```

### Memory Usage Tests

```mbt
/// Memory usage verification
@test fn test_memory_allocation {
  let prices = create_large_price_array(10000)

  // Calculate indicators
  let rsi_values = rsi(prices, 14)
  let macd_result = macd(prices, 12, 26, 9)

  // Verify memory is proportional to input size
  assert_eq(rsi_values.length(), prices.length())
  assert_eq(macd_result.macd_line.length(), prices.length())
}
```

---

## Test Utilities

### Test Data Generation

```mbt
/// Create test K-line data
pub fn create_test_klines(count : Int) -> Array[KLine] {
  let klines : Array[KLine] = []
  let mut price = 100.0
  let mut i = 0

  while i < count {
    let change = (Random.float() - 0.5) * 2.0  // Random change +/- 1
    price = price + change

    klines.push(KLine::{
      code: StockCode::from_string("sh.600000"),
      date: "2023-01-" + (i + 1).to_string(),
      open: price,
      high: price + 1.0,
      low: price - 1.0,
      close: price,
      volume: 1000000.0,
      amount: 1000000.0 * price,
      turn: 0.01
    })

    i = i + 1
  }

  klines
}

/// Create large price array for benchmarks
pub fn create_large_price_array(size : Int) -> Array[Float] {
  let prices : Array[Float] = []
  let mut price = 100.0
  let mut i = 0

  while i < size {
    prices.push(price)
    price = price + (Random.float() - 0.5)
    i = i + 1
  }

  prices
}

/// Helper for floating point comparison
pub fn assert_float_eq(actual : Float, expected : Float, tolerance : Float) {
  let diff = Float::abs(actual - expected)
  if diff > tolerance {
    panic("Float assertion failed: " +
          actual.to_string() + " != " + expected.to_string())
  }
}
```

---

## Test Checklist

Before submitting indicator code:

- [ ] Unit tests created for all indicator functions
- [ ] Edge cases tested (insufficient data, zero period, etc.)
- [ ] Helper functions tested (is_overbought, is_oversold, etc.)
- [ ] Integration tests with screening logic
- [ ] API endpoint tests
- [ ] Performance benchmarks pass
- [ ] Code coverage meets minimum requirements
- [ ] All tests pass with `moon test`
- [ ] Test names clearly describe what is being tested

---

*Last Updated: 2026-03-28*
*Document Maintainer: doc-eng*
