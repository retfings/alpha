/// Technical indicators library

///|
/// Calculate Simple Moving Average (SMA)
///
/// Parameters:
/// - values: Array of prices
/// - period: Number of periods
///
/// Returns:
/// - Array of SMA values (same length as input, with leading zeros)
///
/// Performance: O(n) using sliding window (vs O(n*p) naive approach)
pub fn sma(values : Array[Float], period : Int) -> Array[Float] {
  if values.length() < period || period <= 0 {
    return values.map(fn(_) { Float::from_double(0.0) })
  }

  let result : Array[Float] = []
  let len = values.length()

  // Calculate initial sum for first window
  let mut window_sum : Float = Float::from_double(0.0)
  let mut i = 0
  while i < period {
    window_sum = window_sum + values[i]
    i = i + 1
  }

  // Add leading zeros
  i = 0
  while i < period - 1 {
    result.push(Float::from_double(0.0))
    i = i + 1
  }

  // Add first SMA value
  result.push(window_sum / Float::from_int(period))

  // Use sliding window for remaining values (O(1) per iteration)
  i = period
  while i < len {
    window_sum = window_sum + values[i] - values[i - period]
    result.push(window_sum / Float::from_int(period))
    i = i + 1
  }

  result
}

///|
/// Calculate Exponential Moving Average (EMA)
///
/// Parameters:
/// - values: Array of prices
/// - period: Number of periods
///
/// Returns:
/// - Array of EMA values
pub fn ema(values : Array[Float], period : Int) -> Array[Float] {
  let zero = Float::from_double(0.0)
  let two = Float::from_double(2.0)

  if values.length() < period || period <= 0 {
    return values.map(fn(_) { zero })
  }

  let result : Array[Float] = []
  let multiplier = two / Float::from_int(period + 1)
  let len = values.length()
  let mut i = 0

  // First EMA is SMA
  let mut sum : Float = zero
  while i < period {
    sum = sum + values[i]
    i = i + 1
  }
  let mut prev_ema = sum / Float::from_int(period)

  i = 0
  while i < period - 1 {
    result.push(zero)
    i = i + 1
  }
  result.push(prev_ema)

  i = period
  while i < len {
    prev_ema = (values[i] - prev_ema) * multiplier + prev_ema
    result.push(prev_ema)
    i = i + 1
  }

  result
}

///|
/// Calculate RSI (Relative Strength Index)
///
/// Parameters:
/// - values: Array of prices
/// - period: Number of periods (typically 14)
///
/// Returns:
/// - Array of RSI values (0-100 range)
pub fn rsi(values : Array[Float], period : Int) -> Array[Float] {
  let zero = Float::from_double(0.0)
  let one = Float::from_double(1.0)
  let hundred = Float::from_double(100.0)

  if values.length() <= period || period <= 0 {
    return values.map(fn(_) { zero })
  }

  let result : Array[Float] = []
  let len = values.length()
  let mut i = 1

  // Calculate gains and losses
  let gains : Array[Float] = []
  let losses : Array[Float] = []

  while i < len {
    let change = values[i] - values[i - 1]
    if change > zero {
      gains.push(change)
      losses.push(zero)
    } else {
      gains.push(zero)
      losses.push(Float::abs(change))
    }
    i = i + 1
  }

  // First RSI calculation
  let mut avg_gain = zero
  let mut avg_loss = zero
  i = 0
  while i < period {
    if i < gains.length() {
      avg_gain = avg_gain + gains[i]
      avg_loss = avg_loss + losses[i]
    }
    i = i + 1
  }
  avg_gain = avg_gain / Float::from_int(period)
  avg_loss = avg_loss / Float::from_int(period)

  // Fill leading zeros
  i = 0
  while i < period {
    result.push(zero)
    i = i + 1
  }

  // Calculate first RSI
  if avg_loss == zero {
    result.push(hundred)
  } else {
    let rs = avg_gain / avg_loss
    result.push(hundred - hundred / (one + rs))
  }

  // Calculate remaining RSI values
  i = period
  let period_minus_one = Float::from_int(period - 1)
  let period_float = Float::from_int(period)
  while i < gains.length() {
    avg_gain = (avg_gain * period_minus_one + gains[i]) / period_float
    avg_loss = (avg_loss * period_minus_one + losses[i]) / period_float

    if avg_loss == zero {
      result.push(hundred)
    } else {
      let rs = avg_gain / avg_loss
      result.push(hundred - hundred / (one + rs))
    }
    i = i + 1
  }

  result
}

///|
/// Calculate MACD (Moving Average Convergence Divergence)
///
/// Parameters:
/// - values: Array of prices
/// - fast_period: Fast EMA period (typically 12)
/// - slow_period: Slow EMA period (typically 26)
/// - signal_period: Signal line EMA period (typically 9)
///
/// Returns:
/// - Tuple of (MACD line, Signal line, Histogram) arrays
pub fn macd(
  values : Array[Float],
  fast_period : Int,
  slow_period : Int,
  signal_period : Int,
) -> (Array[Float], Array[Float], Array[Float]) {
  let fast_ema = ema(values, fast_period)
  let slow_ema = ema(values, slow_period)

  let macd_line : Array[Float] = []
  let len = values.length()
  let mut i = 0

  while i < len {
    macd_line.push(fast_ema[i] - slow_ema[i])
    i = i + 1
  }

  let signal_line = ema(macd_line, signal_period)

  let histogram : Array[Float] = []
  i = 0
  while i < len {
    histogram.push(macd_line[i] - signal_line[i])
    i = i + 1
  }

  (macd_line, signal_line, histogram)
}

///|
/// Calculate Bollinger Bands
///
/// Parameters:
/// - values: Array of prices
/// - period: SMA period (typically 20)
/// - std_dev: Standard deviation multiplier (typically 2)
///
/// Returns:
/// - Tuple of (upper_band, middle_band, lower_band) arrays
pub fn bollinger_bands(
  values : Array[Float],
  period : Int,
  std_dev : Float,
) -> (Array[Float], Array[Float], Array[Float]) {
  let zero = Float::from_double(0.0)
  let middle = sma(values, period)
  let upper : Array[Float] = []
  let lower : Array[Float] = []
  let len = values.length()
  let mut i = 0
  let period_float = Float::from_int(period)

  while i < len {
    if i < period - 1 || middle[i] == zero {
      upper.push(zero)
      lower.push(zero)
    } else {
      // Calculate standard deviation
      let mut sum_sq : Float = zero
      let mut j = i - period + 1
      while j <= i {
        let diff = values[j] - middle[i]
        sum_sq = sum_sq + diff * diff
        j = j + 1
      }
      let std = Float::sqrt(sum_sq / period_float)
      upper.push(middle[i] + std_dev * std)
      lower.push(middle[i] - std_dev * std)
    }
    i = i + 1
  }

  (upper, middle, lower)
}

///|
/// Calculate ATR (Average True Range)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: ATR period (typically 14)
///
/// Returns:
/// - Array of ATR values
pub fn atr(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  if klines.length() <= period || period <= 0 {
    return klines.map(fn(_) { Float::from_double(0.0) })
  }

  let tr : Array[Float] = []
  let len = klines.length()
  let mut i = 0

  while i < len {
    let kline = klines[i]
    if i == 0 {
      tr.push(kline.high - kline.low)
    } else {
      let prev_close = klines[i - 1].close
      let hl = kline.high - kline.low
      let hc = Float::abs(kline.high - prev_close)
      let lc = Float::abs(kline.low - prev_close)
      let max_range = if hl > hc { hl } else { hc }
      tr.push(if max_range > lc { max_range } else { lc })
    }
    i = i + 1
  }

  // Calculate ATR as SMA of TR
  let atr_values = sma(tr, period)
  atr_values
}

///|
/// Calculate KDJ (Stochastic Oscillator)
///
/// Parameters:
/// - klines: Array of K-line data
/// - n_period: Lookback period for highest high and lowest low (typically 9)
/// - k_period: Smoothing period for K line (typically 3)
/// - d_period: Smoothing period for D line (typically 3)
///
/// Returns:
/// - Tuple of (K, D, J) arrays where J = 3*K - 2*D
pub fn kdj(
  klines : Array[@data.KLine],
  n_period : Int,
  k_period : Int,
  d_period : Int,
) -> (Array[Float], Array[Float], Array[Float]) {
  let zero = Float::from_double(0.0)
  let hundred = Float::from_double(100.0)
  let three = Float::from_double(3.0)
  let two = Float::from_double(2.0)

  if klines.length() < n_period {
    return (
      klines.map(fn(_) { zero }),
      klines.map(fn(_) { zero }),
      klines.map(fn(_) { zero }),
    )
  }

  let len = klines.length()
  let k_raw : Array[Float] = []
  let mut i = 0

  // Calculate raw K values (stochastic %)
  while i < len {
    if i < n_period - 1 {
      k_raw.push(zero)
    } else {
      // Find highest high and lowest low over lookback period
      let mut highest = klines[i - n_period + 1].low
      let mut lowest = klines[i - n_period + 1].high
      let mut j = i - n_period + 1
      while j <= i {
        if klines[j].high > highest {
          highest = klines[j].high
        }
        if klines[j].low < lowest {
          lowest = klines[j].low
        }
        j = j + 1
      }

      let range = highest - lowest
      if range == zero {
        k_raw.push(hundred)
      } else {
        let close = klines[i].close
        let k_val = (close - lowest) / range * hundred
        k_raw.push(k_val)
      }
    }
    i = i + 1
  }

  // Smooth K with EMA
  let k_line = ema(k_raw, k_period)

  // Calculate D as EMA of K
  let d_line = ema(k_line, d_period)

  // Calculate J = 3*K - 2*D
  let j_line : Array[Float] = []
  i = 0
  while i < len {
    j_line.push(three * k_line[i] - two * d_line[i])
    i = i + 1
  }

  (k_line, d_line, j_line)
}

///|
/// Calculate CCI (Commodity Channel Index)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period (typically 20)
///
/// Returns:
/// - Array of CCI values
pub fn cci(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  let zero = Float::from_double(0.0)
  let point_oh_one = Float::from_double(0.015)

  if klines.length() < period {
    return klines.map(fn(_) { zero })
  }

  let len = klines.length()
  let result : Array[Float] = []
  let mut i = 0

  while i < len {
    if i < period - 1 {
      result.push(zero)
    } else {
      // Calculate typical price for each period
      let typical_prices : Array[Float] = []
      let mut j = i - period + 1
      while j <= i {
        let tp = (klines[j].high + klines[j].low + klines[j].close) /
          Float::from_double(3.0)
        typical_prices.push(tp)
        j = j + 1
      }

      // Calculate SMA of typical prices
      let mut sum : Float = zero
      for tp in typical_prices {
        sum = sum + tp
      }
      let sma_tp = sum / Float::from_int(period)

      // Calculate mean deviation
      let mut deviation_sum : Float = zero
      for tp in typical_prices {
        deviation_sum = deviation_sum + Float::abs(tp - sma_tp)
      }
      let mean_deviation = deviation_sum / Float::from_int(period)

      // Current typical price
      let current_tp = (klines[i].high + klines[i].low + klines[i].close) /
        Float::from_double(3.0)

      // CCI = (TP - SMA) / (0.015 * Mean Deviation)
      if mean_deviation == zero {
        result.push(zero)
      } else {
        let cci_val = (current_tp - sma_tp) / (point_oh_one * mean_deviation)
        result.push(cci_val)
      }
    }
    i = i + 1
  }

  result
}

///|
/// Calculate Williams %R (Williams Percent Range)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period (typically 14)
///
/// Returns:
/// - Array of Williams %R values (range: -100 to 0)
pub fn williams_r(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  let zero = Float::from_double(0.0)
  let neg_hundred = Float::from_double(-100.0)

  if klines.length() < period {
    return klines.map(fn(_) { zero })
  }

  let len = klines.length()
  let result : Array[Float] = []
  let mut i = 0

  while i < len {
    if i < period - 1 {
      result.push(zero)
    } else {
      // Find highest high and lowest low over lookback period
      let mut highest = klines[i - period + 1].low
      let mut lowest = klines[i - period + 1].high
      let mut j = i - period + 1
      while j <= i {
        if klines[j].high > highest {
          highest = klines[j].high
        }
        if klines[j].low < lowest {
          lowest = klines[j].low
        }
        j = j + 1
      }

      let range = highest - lowest
      if range == zero {
        result.push(zero)
      } else {
        let close = klines[i].close
        // Williams %R = (Highest High - Close) / (Highest High - Lowest Low) * -100
        let wr_val = (highest - close) / range * neg_hundred
        result.push(wr_val)
      }
    }
    i = i + 1
  }

  result
}

///|
/// Calculate OBV (On-Balance Volume)
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of OBV values
pub fn obv(klines : Array[@data.KLine]) -> Array[Float] {
  if klines.length() == 0 {
    return []
  }

  let result : Array[Float] = []
  let mut obv = klines[0].volume
  result.push(obv)

  let len = klines.length()
  let mut i = 1

  while i < len {
    if klines[i].close > klines[i - 1].close {
      obv = obv + klines[i].volume
    } else if klines[i].close < klines[i - 1].close {
      obv = obv - klines[i].volume
    }
    // If close is equal, OBV doesn't change
    result.push(obv)
    i = i + 1
  }

  result
}
