///|
/// Whitebox tests for technical.mbt module
///
/// Tests for technical indicator signals and analysis functions
test "TechnicalSignals_default_values" {
  let signals = TechnicalSignals::{
    macd_signal: 0,
    rsi_signal: 0,
    kdj_signal: 0,
    ma_trend: 0,
    total_score: 0,
  }

  let _ = signals.macd_signal == 0
  let _ = signals.rsi_signal == 0
  let _ = signals.kdj_signal == 0
  let _ = signals.ma_trend == 0
  let _ = signals.total_score == 0
}

///|
test "TechnicalSignals_bullish_scenario" {
  let signals = TechnicalSignals::{
    macd_signal: 1,
    rsi_signal: -1,
    kdj_signal: 1,
    ma_trend: 1,
    total_score: 4,
  }

  let _ = signals.macd_signal == 1
  let _ = signals.rsi_signal == -1
  let _ = signals.total_score == 4
}

///|
test "rate_technicals_strong_buy" {
  let signals = TechnicalSignals::{
    macd_signal: 1,
    rsi_signal: -1,
    kdj_signal: 1,
    ma_trend: 1,
    total_score: 4,
  }
  let rating = rate_technicals(signals)
  let _ = rating == TechnicalRating::StrongBuy
}

///|
test "rate_technicals_buy" {
  let signals = TechnicalSignals::{
    macd_signal: 1,
    rsi_signal: 0,
    kdj_signal: 1,
    ma_trend: 0,
    total_score: 2,
  }
  let rating = rate_technicals(signals)
  let _ = rating == TechnicalRating::Buy
}

///|
test "rate_technicals_neutral" {
  let signals = TechnicalSignals::{
    macd_signal: 0,
    rsi_signal: 0,
    kdj_signal: 0,
    ma_trend: 0,
    total_score: 0,
  }
  let rating = rate_technicals(signals)
  let _ = rating == TechnicalRating::Neutral
}

///|
test "rate_technicals_sell" {
  let signals = TechnicalSignals::{
    macd_signal: -1,
    rsi_signal: 1,
    kdj_signal: -1,
    ma_trend: 0,
    total_score: -2,
  }
  let rating = rate_technicals(signals)
  let _ = rating == TechnicalRating::Sell
}

///|
test "rate_technicals_strong_sell" {
  let signals = TechnicalSignals::{
    macd_signal: -1,
    rsi_signal: 1,
    kdj_signal: -1,
    ma_trend: -1,
    total_score: -4,
  }
  let rating = rate_technicals(signals)
  let _ = rating == TechnicalRating::StrongSell
}

///|
test "is_technical_buy_true" {
  let signals = TechnicalSignals::{
    macd_signal: 1,
    rsi_signal: 0,
    kdj_signal: 1,
    ma_trend: 0,
    total_score: 2,
  }
  let _ = is_technical_buy(signals) == true
}

///|
test "is_technical_buy_false_rsi_overbought" {
  let signals = TechnicalSignals::{
    macd_signal: 1,
    rsi_signal: 1,
    kdj_signal: 1,
    ma_trend: 0,
    total_score: 2,
  }
  let _ = is_technical_buy(signals) == false
}

///|
test "is_technical_buy_false_low_score" {
  let signals = TechnicalSignals::{
    macd_signal: 0,
    rsi_signal: 0,
    kdj_signal: 0,
    ma_trend: 1,
    total_score: 1,
  }
  let _ = is_technical_buy(signals) == false
}

///|
test "is_technical_sell_true" {
  let signals = TechnicalSignals::{
    macd_signal: -1,
    rsi_signal: 0,
    kdj_signal: -1,
    ma_trend: 0,
    total_score: -2,
  }
  let _ = is_technical_sell(signals) == true
}

///|
test "is_technical_sell_true_rsi_overbought" {
  let signals = TechnicalSignals::{
    macd_signal: 0,
    rsi_signal: 1,
    kdj_signal: 0,
    ma_trend: 0,
    total_score: -1,
  }
  let _ = is_technical_sell(signals) == true
}

///|
test "is_technical_sell_false" {
  let signals = TechnicalSignals::{
    macd_signal: 0,
    rsi_signal: 0,
    kdj_signal: 0,
    ma_trend: 0,
    total_score: 0,
  }
  let _ = is_technical_sell(signals) == false
}

///|
test "calculate_technical_signals_insufficient_data" {
  let klines : Array[@data.KLine] = [
    @data.KLine::daily(
      "sh.600000", "2024-01-01", 10.0, 10.5, 9.5, 10.2, 1000.0, 10200.0, 1.5,
    ),
    @data.KLine::daily(
      "sh.600000", "2024-01-02", 10.2, 10.8, 10.0, 10.5, 1200.0, 12600.0, 1.8,
    ),
  ]

  let signals = calculate_technical_signals(klines, 14, 12, 26, 9, 9, 10, 20)

  // Should return all zeros for insufficient data
  let _ = signals.macd_signal == 0
  let _ = signals.rsi_signal == 0
  let _ = signals.kdj_signal == 0
  let _ = signals.ma_trend == 0
  let _ = signals.total_score == 0
}

///|
test "quick_technical_analysis" {
  let klines : Array[@data.KLine] = []
  let signals = quick_technical_analysis(klines)

  let _ = signals.macd_signal == 0
  let _ = signals.rsi_signal == 0
  let _ = signals.total_score == 0
}

///|
test "TechnicalRating_equality" {
  let buy1 = TechnicalRating::Buy
  let buy2 = TechnicalRating::Buy
  let sell = TechnicalRating::Sell

  let _ = buy1 == buy2
  let _ = buy1 != sell
}

///|
test "TechnicalRating_show" {
  let rating = TechnicalRating::StrongBuy
  let str = rating.to_string()
  let _ = str.contains("StrongBuy")
}
