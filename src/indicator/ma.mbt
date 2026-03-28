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
