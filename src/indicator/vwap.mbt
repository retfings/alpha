/// VWAP (Volume-Weighted Average Price) indicator
///
/// VWAP is a trading benchmark that gives the average price a security has
/// traded at throughout the day, based on both volume and price.

///|
/// Calculate Typical Price for a single K-line
///
/// Typical Price = (High + Low + Close) / 3
///
/// Parameters:
/// - kline: Single K-line data
///
/// Returns:
/// - Typical price value
fn typical_price(kline : @data.KLine) -> Float {
  (kline.high + kline.low + kline.close) / Float::from_double(3.0)
}

///|
/// Calculate VWAP (Volume-Weighted Average Price)
///
/// VWAP is calculated as the cumulative sum of (Typical Price × Volume)
/// divided by the cumulative sum of Volume.
///
/// **Formula:**
/// - Typical Price = (High + Low + Close) / 3
/// - VWAP = Σ(Typical Price × Volume) / Σ(Volume)
///
/// **Interpretation:**
/// - Price above VWAP: Bullish (trading at premium)
/// - Price below VWAP: Bearish (trading at discount)
/// - VWAP acts as dynamic support/resistance
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of VWAP values (same length as input)
/// - First value is the typical price of first kline
///
/// Example usage:
/// ```mbt check-disabled
/// let vwap_values = @indicator.vwap(klines)
/// ```
pub fn vwap(klines : Array[@data.KLine]) -> Array[Float] {
  if klines.length() == 0 {
    return []
  }

  let result : Array[Float] = []
  let mut cum_tp_volume = Float::from_double(0.0)
  let mut cum_volume = Float::from_double(0.0)

  let len = klines.length()
  let mut i = 0

  while i < len {
    let tp = typical_price(klines[i])
    cum_tp_volume = cum_tp_volume + tp * klines[i].volume
    cum_volume = cum_volume + klines[i].volume

    if cum_volume == Float::from_double(0.0) {
      result.push(Float::from_double(0.0))
    } else {
      result.push(cum_tp_volume / cum_volume)
    }
    i = i + 1
  }

  result
}

///|
/// Calculate VWAP with reset period
///
/// Similar to standard VWAP but resets the cumulative calculation
/// after a specified number of periods. Useful for longer time series.
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Number of periods before reset (e.g., 20 for daily reset)
///
/// Returns:
/// - Array of VWAP values
///
/// Example usage:
/// ```mbt check-disabled
/// let vwap_values = @indicator.vwap_with_reset(klines, 20)
/// ```
pub fn vwap_with_reset(
  klines : Array[@data.KLine],
  period : Int,
) -> Array[Float] {
  if klines.length() == 0 || period <= 0 {
    return []
  }

  let result : Array[Float] = []
  let mut cum_tp_volume = Float::from_double(0.0)
  let mut cum_volume = Float::from_double(0.0)
  let mut bar_count = 0

  let len = klines.length()
  let mut i = 0

  while i < len {
    // Reset at period boundaries
    if bar_count >= period {
      cum_tp_volume = Float::from_double(0.0)
      cum_volume = Float::from_double(0.0)
      bar_count = 0
    }

    let tp = typical_price(klines[i])
    cum_tp_volume = cum_tp_volume + tp * klines[i].volume
    cum_volume = cum_volume + klines[i].volume
    bar_count = bar_count + 1

    if cum_volume == Float::from_double(0.0) {
      result.push(Float::from_double(0.0))
    } else {
      result.push(cum_tp_volume / cum_volume)
    }
    i = i + 1
  }

  result
}

///|
/// Calculate VWAP Bands (Upper and Lower)
///
/// VWAP bands are similar to Bollinger Bands but centered around VWAP.
/// They use standard deviation of price from VWAP to create dynamic bands.
///
/// **Formula:**
/// - Upper Band = VWAP + (multiplier × StdDev)
/// - Lower Band = VWAP - (multiplier × StdDev)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period for standard deviation
/// - multiplier: Band width multiplier (typically 1.0 or 2.0)
///
/// Returns:
/// - Tuple of (upper_band, vwap, lower_band) arrays
///
/// Example usage:
/// ```mbt check-disabled
/// let (upper, vwap, lower) = @indicator.vwap_bands(klines, 20, 2.0)
/// ```
pub fn vwap_bands(
  klines : Array[@data.KLine],
  period : Int,
  multiplier : Float,
) -> (Array[Float], Array[Float], Array[Float]) {
  let zero = Float::from_double(0.0)
  let period_f = Float::from_int(period)

  if klines.length() == 0 || period <= 0 {
    let empty : Array[Float] = []
    return (empty, empty, empty)
  }

  let vwap_values = vwap(klines)
  let upper : Array[Float] = []
  let lower : Array[Float] = []
  let len = klines.length()

  let mut i = 0
  while i < len {
    if i < period - 1 {
      // Insufficient data for std dev calculation
      upper.push(zero)
      lower.push(zero)
    } else {
      // Calculate standard deviation of close from VWAP
      let mut sum_sq = Float::from_double(0.0)
      let mut j = i - period + 1
      while j <= i {
        let diff = klines[j].close - vwap_values[j]
        sum_sq = sum_sq + diff * diff
        j = j + 1
      }
      let std = Float::sqrt(sum_sq / period_f)
      let vwap = vwap_values[i]

      upper.push(vwap + multiplier * std)
      lower.push(vwap - multiplier * std)
    }
    i = i + 1
  }

  (upper, vwap_values, lower)
}

///|
/// Check if price is above VWAP
///
/// Parameters:
/// - kline: Current K-line
/// - vwap: Current VWAP value
///
/// Returns:
/// - true if close price is above VWAP
pub fn is_above_vwap(kline : @data.KLine, vwap : Float) -> Bool {
  kline.close > vwap
}

///|
/// Check if price is below VWAP
///
/// Parameters:
/// - kline: Current K-line
/// - vwap: Current VWAP value
///
/// Returns:
/// - true if close price is below VWAP
pub fn is_below_vwap(kline : @data.KLine, vwap : Float) -> Bool {
  kline.close < vwap
}

///|
/// Calculate VWAP deviation percentage
///
/// Measures how far the current price deviates from VWAP as a percentage.
///
/// **Formula:**
/// - Deviation = (Close - VWAP) / VWAP × 100
///
/// Parameters:
/// - kline: Current K-line
/// - vwap: Current VWAP value
///
/// Returns:
/// - Deviation percentage (positive = above VWAP, negative = below)
pub fn vwap_deviation(kline : @data.KLine, vwap : Float) -> Float {
  if vwap == Float::from_double(0.0) {
    Float::from_double(0.0)
  } else {
    (kline.close - vwap) / vwap * Float::from_double(100.0)
  }
}

///|
/// Enum representing price position relative to VWAP
pub enum VwapPosition {
  /// Price above VWAP (bullish)
  /// Price below VWAP (bearish)
  /// Price at VWAP (neutral)
  Above
  Below
  Equal
} derive(Eq, Show)

///|
/// Get price position relative to VWAP
///
/// Parameters:
/// - kline: Current K-line
/// - vwap: Current VWAP value
///
/// Returns:
/// - VwapPosition enum value
pub fn vwap_position(kline : @data.KLine, vwap : Float) -> VwapPosition {
  if kline.close > vwap {
    VwapPosition::Above
  } else if kline.close < vwap {
    VwapPosition::Below
  } else {
    VwapPosition::Equal
  }
}
