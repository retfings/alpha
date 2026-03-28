/// Technical indicators for stock selection
///
/// This module provides a unified interface to technical indicators
/// used in stock screening and analysis. It re-exports indicators
/// from individual modules and provides composite analysis functions.
///
/// Indicators included:
/// - MACD (Moving Average Convergence Divergence)
/// - MA (Moving Average - SMA and EMA)
/// - KDJ (Stochastic Oscillator)
/// - RSI (Relative Strength Index)

///|
/// Technical indicator signals summary
pub struct TechnicalSignals {
  /// MACD signal (1 = bullish, -1 = bearish, 0 = neutral)
  macd_signal : Int
  /// RSI signal (1 = overbought, -1 = oversold, 0 = neutral)
  rsi_signal : Int
  /// KDJ signal (1 = bullish crossover, -1 = bearish, 0 = neutral)
  kdj_signal : Int
  /// MA trend (1 = uptrend, -1 = downtrend, 0 = neutral)
  ma_trend : Int
  /// Overall technical score (-4 to 4)
  total_score : Int
} derive(Show, ToJson)

///|
/// Calculate technical signals from K-line data
///
/// Parameters:
/// - klines: Array of K-line data
/// - rsi_period: RSI calculation period (typically 14)
/// - macd_fast: MACD fast EMA period (typically 12)
/// - macd_slow: MACD slow EMA period (typically 26)
/// - macd_signal_period: MACD signal line period (typically 9)
/// - kdj_n: KDJ lookback period (typically 9)
/// - ma_short: Short-term MA period (typically 5 or 10)
/// - ma_long: Long-term MA period (typically 20 or 60)
///
/// Returns:
/// - TechnicalSignals with all indicator readings
pub fn calculate_technical_signals(
  klines : Array[@data.KLine],
  rsi_period : Int,
  macd_fast : Int,
  macd_slow : Int,
  macd_signal_period : Int,
  kdj_n : Int,
  ma_short : Int,
  ma_long : Int,
) -> TechnicalSignals {
  if klines.length() < macd_slow {
    return TechnicalSignals::{
      macd_signal: 0,
      rsi_signal: 0,
      kdj_signal: 0,
      ma_trend: 0,
      total_score: 0,
    }
  }

  let closes = klines.map(fn(k) { k.close })

  // RSI signal
  let rsi_values = rsi(closes, rsi_period)
  let last_rsi = rsi_values[rsi_values.length() - 1]
  let rsi_signal = if last_rsi > 70.0 {
    1 // Overbought - potential sell
  } else if last_rsi < 30.0 {
    -1 // Oversold - potential buy
  } else {
    0 // Neutral
  }

  // MACD signal
  let macd_result = macd(closes, macd_fast, macd_slow, macd_signal_period)
  let len = macd_result.macd_line.length()
  let macd_signal = if len >= 2 {
    let curr_macd = macd_result.macd_line[len - 1]
    let curr_signal = macd_result.signal_line[len - 1]
    let prev_macd = macd_result.macd_line[len - 2]
    let prev_signal = macd_result.signal_line[len - 2]
    if curr_macd > curr_signal && prev_macd <= prev_signal {
      1 // Bullish crossover
    } else if curr_macd < curr_signal && prev_macd >= prev_signal {
      -1 // Bearish crossover
    } else if curr_macd > curr_signal {
      0 // Above signal (neutral bullish)
    } else {
      0 // Below signal (neutral bearish)
    }
  } else {
    0
  }

  // KDJ signal
  let (k_line, d_line, _) = kdj(klines, kdj_n, 3, 3)
  let kdj_signal = if k_line.length() >= 2 && d_line.length() >= 2 {
    let curr_k = k_line[k_line.length() - 1]
    let curr_d = d_line[d_line.length() - 1]
    let prev_k = k_line[k_line.length() - 2]
    let prev_d = d_line[d_line.length() - 2]
    if curr_k > curr_d && prev_k <= prev_d {
      1 // Bullish crossover
    } else if curr_k < curr_d && prev_k >= prev_d {
      -1 // Bearish crossover
    } else {
      0
    }
  } else {
    0
  }

  // MA trend
  let ma_short_values = sma(closes, ma_short)
  let ma_long_values = sma(closes, ma_long)
  let ma_trend = if ma_short_values.length() > 0 && ma_long_values.length() > 0 {
    let short_ma = ma_short_values[ma_short_values.length() - 1]
    let long_ma = ma_long_values[ma_long_values.length() - 1]
    if short_ma > long_ma {
      1 // Uptrend (golden cross)
    } else if short_ma < long_ma {
      -1 // Downtrend (death cross)
    } else {
      0
    }
  } else {
    0
  }

  // Calculate total score
  // Note: For RSI, overbought (1) is bearish for long positions
  // For others, 1 is bullish
  let total_score = macd_signal + kdj_signal + ma_trend - rsi_signal

  TechnicalSignals::{
    macd_signal,
    rsi_signal,
    kdj_signal,
    ma_trend,
    total_score,
  }
}

///|
/// Simplified technical analysis with standard parameters
///
/// Uses standard indicator parameters:
/// - RSI: 14 periods
/// - MACD: 12, 26, 9
/// - KDJ: 9, 3, 3
/// - MA: 10 and 20 periods
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - TechnicalSignals with standard parameter calculations
pub fn quick_technical_analysis(
  klines : Array[@data.KLine],
) -> TechnicalSignals {
  calculate_technical_signals(klines, 14, 12, 26, 9, 9, 10, 20)
}

///|
/// Technical rating based on total score
pub enum TechnicalRating {
  /// Strong buy (score = 4)
  StrongBuy
  /// Buy (score = 2 to 3)
  Buy
  /// Neutral (score = -1 to 1)
  Neutral
  /// Sell (score = -2 to -3)
  Sell
  /// Strong sell (score = -4)
  StrongSell
} derive(Show, ToJson, Eq)

///|
/// Convert technical score to rating
///
/// Parameters:
/// - signals: TechnicalSignals
///
/// Returns:
/// - TechnicalRating based on total_score
pub fn rate_technicals(signals : TechnicalSignals) -> TechnicalRating {
  let score = signals.total_score
  if score >= 4 {
    TechnicalRating::StrongBuy
  } else if score >= 2 {
    TechnicalRating::Buy
  } else if score >= -1 {
    TechnicalRating::Neutral
  } else if score >= -3 {
    TechnicalRating::Sell
  } else {
    TechnicalRating::StrongSell
  }
}

///|
/// Check if technical signals indicate a buy opportunity
///
/// Buy criteria:
/// - Total score >= 2 (bullish)
/// - RSI not overbought (< 70)
///
/// Parameters:
/// - signals: TechnicalSignals
///
/// Returns:
/// - true if buy criteria are met
pub fn is_technical_buy(signals : TechnicalSignals) -> Bool {
  signals.total_score >= 2 && signals.rsi_signal != 1
}

///|
/// Check if technical signals indicate a sell opportunity
///
/// Sell criteria:
/// - Total score <= -2 (bearish)
/// - OR RSI overbought (> 70)
///
/// Parameters:
/// - signals: TechnicalSignals
///
/// Returns:
/// - true if sell criteria are met
pub fn is_technical_sell(signals : TechnicalSignals) -> Bool {
  signals.total_score <= -2 || signals.rsi_signal == 1
}

///|
/// Technical analysis result with detailed indicator values
pub struct TechnicalAnalysisResult {
  /// Stock code
  code : @data.StockCode
  /// Analysis date
  date : String
  /// Latest close price
  close : Float
  /// RSI value
  rsi : Float
  /// MACD line value
  macd_line : Float
  /// MACD signal line value
  macd_signal_line : Float
  /// K value from KDJ
  k_value : Float
  /// D value from KDJ
  d_value : Float
  /// Short-term MA
  ma_short : Float
  /// Long-term MA
  ma_long : Float
  /// Summary signals
  signals : TechnicalSignals
  /// Overall rating
  rating : TechnicalRating
} derive(Show, ToJson)

///|
/// Perform comprehensive technical analysis
///
/// Parameters:
/// - klines: Array of K-line data
/// - rsi_period: RSI period
/// - macd_fast: MACD fast period
/// - macd_slow: MACD slow period
/// - macd_signal_period: MACD signal period
/// - kdj_n: KDJ lookback period
/// - ma_short: Short MA period
/// - ma_long: Long MA period
///
/// Returns:
/// - TechnicalAnalysisResult with all values and ratings
pub fn analyze_technicals(
  klines : Array[@data.KLine],
  rsi_period : Int,
  macd_fast : Int,
  macd_slow : Int,
  macd_signal_period : Int,
  kdj_n : Int,
  ma_short : Int,
  ma_long : Int,
) -> TechnicalAnalysisResult {
  if klines.length() == 0 {
    return TechnicalAnalysisResult::{
      code: "",
      date: "",
      close: 0.0,
      rsi: 0.0,
      macd_line: 0.0,
      macd_signal_line: 0.0,
      k_value: 0.0,
      d_value: 0.0,
      ma_short: 0.0,
      ma_long: 0.0,
      signals: TechnicalSignals::{
        macd_signal: 0,
        rsi_signal: 0,
        kdj_signal: 0,
        ma_trend: 0,
        total_score: 0,
      },
      rating: TechnicalRating::Neutral,
    }
  }

  let last = klines[klines.length() - 1]
  let closes = klines.map(fn(k) { k.close })

  // Calculate all indicators
  let rsi_values = rsi(closes, rsi_period)
  let last_rsi = rsi_values[rsi_values.length() - 1]

  let macd_result = macd(closes, macd_fast, macd_slow, macd_signal_period)
  let last_macd = macd_result.macd_line[macd_result.macd_line.length() - 1]
  let last_macd_signal = macd_result.signal_line[macd_result.signal_line.length() -
    1]

  let (k_line, d_line, _) = kdj(klines, kdj_n, 3, 3)
  let last_k = k_line[k_line.length() - 1]
  let last_d = d_line[d_line.length() - 1]

  let ma_short_values = sma(closes, ma_short)
  let ma_long_values = sma(closes, ma_long)
  let last_ma_short = ma_short_values[ma_short_values.length() - 1]
  let last_ma_long = ma_long_values[ma_long_values.length() - 1]

  let signals = calculate_technical_signals(
    klines, rsi_period, macd_fast, macd_slow, macd_signal_period, kdj_n, ma_short,
    ma_long,
  )

  TechnicalAnalysisResult::{
    code: last.code,
    date: last.date,
    close: last.close,
    rsi: last_rsi,
    macd_line: last_macd,
    macd_signal_line: last_macd_signal,
    k_value: last_k,
    d_value: last_d,
    ma_short: last_ma_short,
    ma_long: last_ma_long,
    signals,
    rating: rate_technicals(signals),
  }
}

///|
/// Perform technical analysis with standard parameters
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - TechnicalAnalysisResult with standard parameter calculations
pub fn quick_full_analysis(
  klines : Array[@data.KLine],
) -> TechnicalAnalysisResult {
  analyze_technicals(klines, 14, 12, 26, 9, 9, 10, 20)
}
