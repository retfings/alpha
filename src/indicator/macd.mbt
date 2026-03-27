/// MACD (Moving Average Convergence Divergence) indicator

///|
/// MACD result structure containing all three components
pub struct MACDResult {
  /// MACD line (fast EMA - slow EMA)
  macd_line : Array[Float]
  /// Signal line (EMA of MACD line)
  signal_line : Array[Float]
  /// Histogram (MACD line - signal line)
  histogram : Array[Float]
} derive(Show)

///|
/// Calculate MACD (Moving Average Convergence Divergence)
///
/// MACD is a trend-following momentum indicator that shows the relationship
/// between two moving averages of a security's price.
///
/// **Components:**
/// - MACD Line: 12-period EMA - 26-period EMA
/// - Signal Line: 9-period EMA of MACD Line
/// - Histogram: MACD Line - Signal Line
///
/// **Interpretation:**
/// - Bullish signal: MACD line crosses above signal line
/// - Bearish signal: MACD line crosses below signal line
/// - Divergence: Price makes new high/low but MACD doesn't (potential reversal)
///
/// Parameters:
/// - prices: Array of closing prices
/// - fast_period: Fast EMA period (typically 12)
/// - slow_period: Slow EMA period (typically 26)
/// - signal_period: Signal line EMA period (typically 9)
///
/// Returns:
/// - MACDResult struct containing macd_line, signal_line, and histogram arrays
/// - All arrays have the same length as input prices
///
/// Examples:
/// ```mbt check-disabled
/// let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0]
/// let result = macd(prices, 12, 26, 9)
/// inspect(result.macd_line)
/// inspect(result.signal_line)
/// inspect(result.histogram)
/// ```
pub fn macd(
  prices : Array[Float],
  fast_period : Int,
  slow_period : Int,
  signal_period : Int,
) -> MACDResult {
  let fast_ema = ema(prices, fast_period)
  let slow_ema = ema(prices, slow_period)

  let macd_line : Array[Float] = []
  let len = prices.length()
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

  MACDResult::{ macd_line, signal_line, histogram }
}

///|
/// Calculate MACD with standard parameters (12, 26, 9)
///
/// Standard MACD parameters commonly used in technical analysis:
/// - Fast EMA: 12 periods
/// - Slow EMA: 26 periods
/// - Signal EMA: 9 periods
///
/// Parameters:
/// - prices: Array of closing prices
///
/// Returns:
/// - MACDResult struct with standard parameter calculations
///
/// Examples:
/// ```mbt check-disabled
/// let prices = [100.0, 102.0, 101.0, 103.0, 105.0]
///
/// let result = macd_standard(prices)
/// ```
pub fn macd_standard(prices : Array[Float]) -> MACDResult {
  macd(prices, 12, 26, 9)
}

///|
/// Check for bullish crossover (MACD crosses above signal line)
///
/// Parameters:
/// - result: MACDResult containing macd_line and signal_line
/// - index: Index to check for crossover
///
/// Returns:
/// - true if MACD line crossed above signal line at given index
/// - false if index < 1 or no crossover
///
/// Examples:
/// ```mbt check-disabled
/// let result = macd(prices, 12, 26, 9)
/// if bullish_crossover(result, result.macd_line.length() - 1) {
///   // Potential buy signal
/// }
/// ```
pub fn bullish_crossover(result : MACDResult, index : Int) -> Bool {
  if index < 1 {
    return false
  }
  let prev_macd = result.macd_line[index - 1]
  let prev_signal = result.signal_line[index - 1]
  let curr_macd = result.macd_line[index]
  let curr_signal = result.signal_line[index]

  // MACD was below signal, now above
  curr_macd > curr_signal && prev_macd <= prev_signal
}

///|
/// Check for bearish crossover (MACD crosses below signal line)
///
/// Parameters:
/// - result: MACDResult containing macd_line and signal_line
/// - index: Index to check for crossover
///
/// Returns:
/// - true if MACD line crossed below signal line at given index
/// - false if index < 1 or no crossover
///
/// Examples:
/// ```mbt check-disabled
/// let result = macd(prices, 12, 26, 9)
/// if bearish_crossover(result, result.macd_line.length() - 1) {
///   // Potential sell signal
/// }
/// ```
pub fn bearish_crossover(result : MACDResult, index : Int) -> Bool {
  if index < 1 {
    return false
  }
  let prev_macd = result.macd_line[index - 1]
  let prev_signal = result.signal_line[index - 1]
  let curr_macd = result.macd_line[index]
  let curr_signal = result.signal_line[index]

  // MACD was above signal, now below
  curr_macd < curr_signal && prev_macd >= prev_signal
}

///|
/// Check if histogram is increasing (momentum strengthening)
///
/// Parameters:
/// - result: MACDResult containing histogram values
/// - index: Index to check
///
/// Returns:
/// - true if histogram value increased from previous period
/// - false if index < 1 or histogram decreased/stayed same
///
/// Examples:
/// ```mbt check-disabled
/// let result = macd(prices, 12, 26, 9)
/// if histogram_increasing(result, result.histogram.length() - 1) {
///   // Momentum is strengthening
/// }
/// ```
pub fn histogram_increasing(result : MACDResult, index : Int) -> Bool {
  if index < 1 {
    return false
  }
  result.histogram[index] > result.histogram[index - 1]
}

///|
/// Check if histogram is decreasing (momentum weakening)
///
/// Parameters:
/// - result: MACDResult containing histogram values
/// - index: Index to check
///
/// Returns:
/// - true if histogram value decreased from previous period
/// - false if index < 1 or histogram increased/stayed same
///
/// Examples:
/// ```mbt check-disabled
/// let result = macd(prices, 12, 26, 9)
/// if histogram_decreasing(result, result.histogram.length() - 1) {
///   // Momentum is weakening
/// }
/// ```
pub fn histogram_decreasing(result : MACDResult, index : Int) -> Bool {
  if index < 1 {
    return false
  }
  result.histogram[index] < result.histogram[index - 1]
}
