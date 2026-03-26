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
