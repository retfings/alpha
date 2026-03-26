/// Relative Strength Index (RSI) indicator

///|
/// Calculate RSI (Relative Strength Index)
///
/// RSI is a momentum oscillator that measures the speed and magnitude
/// of recent price changes to evaluate overbought or oversold conditions.
///
/// **Formula:**
/// - RSI = 100 - (100 / (1 + RS))
/// - RS = Average Gain / Average Loss over the period
///
/// **Interpretation:**
/// - RSI > 70: Overbought (potential sell signal)
/// - RSI < 30: Oversold (potential buy signal)
/// - RSI = 50: Neutral
///
/// Parameters:
/// - prices: Array of closing prices
/// - period: Number of periods (commonly 14)
///
/// Returns:
/// - Array of RSI values (same length as input, with leading zeros)
/// - First (period) values are 0 (insufficient data for calculation)
///
/// Examples:
/// ```mbt check-disabled
/// let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0]
///
/// let rsi_values = rsi(prices, 14)
/// ```
pub fn rsi(prices : Array[Float], period : Int) -> Array[Float] {
  if prices.length() <= period || period <= 0 {
    return prices.map(fn(_) { Float::from_double(0.0) })
  }

  let result : Array[Float] = []
  let len = prices.length()

  // Calculate gains and losses
  let gains : Array[Float] = []
  let losses : Array[Float] = []

  let mut i = 1
  while i < len {
    let change = prices[i] - prices[i - 1]
    if change > 0.0 {
      gains.push(change)
      losses.push(Float::from_double(0.0))
    } else {
      gains.push(Float::from_double(0.0))
      losses.push(-change)
    }
    i = i + 1
  }

  // Calculate initial average gain and loss (simple average for first period)
  let mut avg_gain : Float = Float::from_double(0.0)
  let mut avg_loss : Float = Float::from_double(0.0)

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

  // Add leading zeros (period number of zeros)
  i = 0
  while i < period {
    result.push(Float::from_double(0.0))
    i = i + 1
  }

  // Calculate first RSI value
  let rsi_value = if avg_loss == Float::from_double(0.0) {
    Float::from_double(100.0)
  } else {
    let rs = avg_gain / avg_loss
    Float::from_double(100.0) -
    Float::from_double(100.0) / (Float::from_double(1.0) + rs)
  }
  result.push(rsi_value)

  // Calculate remaining RSI values using smoothed averages
  i = period
  while i < gains.length() {
    // Smoothed averages: (prev_avg * (period-1) + current) / period
    avg_gain = (avg_gain * Float::from_int(period - 1) + gains[i]) /
      Float::from_int(period)
    avg_loss = (avg_loss * Float::from_int(period - 1) + losses[i]) /
      Float::from_int(period)

    let rsi_val = if avg_loss == Float::from_double(0.0) {
      Float::from_double(100.0)
    } else {
      let rs = avg_gain / avg_loss
      Float::from_double(100.0) -
      Float::from_double(100.0) / (Float::from_double(1.0) + rs)
    }
    result.push(rsi_val)

    i = i + 1
  }

  result
}

///|
/// Check if RSI indicates overbought condition
///
/// Parameters:
/// - rsi_value: Current RSI value
/// - threshold: Overbought threshold (default 70)
///
/// Returns:
/// - true if RSI is above threshold (overbought)
///
/// Examples:
/// ```mbt check-disabled
/// if is_overbought(rsi_value, 70.0) {
///   // Consider selling
/// }
/// ```
pub fn is_overbought(rsi_value : Float, threshold : Float) -> Bool {
  rsi_value > threshold
}

///|
/// Check if RSI indicates oversold condition
///
/// Parameters:
/// - rsi_value: Current RSI value
/// - threshold: Oversold threshold (default 30)
///
/// Returns:
/// - true if RSI is below threshold (oversold)
///
/// Examples:
/// ```mbt check-disabled
/// if is_oversold(rsi_value, 30.0) {
///   // Consider buying
/// }
/// ```
pub fn is_oversold(rsi_value : Float, threshold : Float) -> Bool {
  rsi_value < threshold
}
