/// Bollinger Bands volatility indicator

///|
/// Calculate Bollinger Bands
///
/// Bollinger Bands consist of three lines:
/// - Middle Band: Simple Moving Average (SMA) of prices
/// - Upper Band: Middle Band + (std_dev_multiplier * standard deviation)
/// - Lower Band: Middle Band - (std_dev_multiplier * standard deviation)
///
/// **Interpretation:**
/// - Price near upper band: Potentially overbought
/// - Price near lower band: Potentially oversold
/// - Narrow bands (squeeze): Low volatility, potential breakout ahead
/// - Wide bands (expansion): High volatility
///
/// Parameters:
/// - prices: Array of closing prices
/// - period: SMA period (typically 20)
/// - std_dev_multiplier: Standard deviation multiplier (typically 2.0)
///
/// Returns:
/// - Tuple of (upper_band, middle_band, lower_band) arrays
/// - All arrays have same length as input
/// - First (period - 1) values are 0 (insufficient data)
///
/// Examples:
/// ```mbt check-disabled
/// let prices = [100.0, 102.0, 101.0, 103.0, 105.0]
/// let (upper, middle, lower) = bollinger_bands(prices, 3, 2.0)
/// ```
pub fn bollinger_bands(
  prices : Array[Float],
  period : Int,
  std_dev_multiplier : Float,
) -> (Array[Float], Array[Float], Array[Float]) {
  let zero = Float::from_double(0.0)
  let period_float = Float::from_int(period)

  if prices.length() < period || period <= 0 {
    let empty = prices.map(fn(_) { zero })
    return (empty, empty, empty)
  }

  let upper : Array[Float] = []
  let middle : Array[Float] = []
  let lower : Array[Float] = []
  let len = prices.length()

  // Calculate SMA for middle band and std deviation
  let mut i = 0
  while i < len {
    if i < period - 1 {
      // Insufficient data - add zeros
      upper.push(zero)
      middle.push(zero)
      lower.push(zero)
    } else {
      // Calculate SMA for current window
      let mut sum : Float = zero
      let mut j = i - period + 1
      while j <= i {
        sum = sum + prices[j]
        j = j + 1
      }
      let sma = sum / period_float
      middle.push(sma)

      // Calculate standard deviation
      let mut sum_sq : Float = zero
      j = i - period + 1
      while j <= i {
        let diff = prices[j] - sma
        sum_sq = sum_sq + diff * diff
        j = j + 1
      }
      let std = Float::sqrt(sum_sq / period_float)
      let band_width = std_dev_multiplier * std

      upper.push(sma + band_width)
      lower.push(sma - band_width)
    }
    i = i + 1
  }

  (upper, middle, lower)
}

///|
/// Calculate Bollinger Bands with default parameters
///
/// Uses standard defaults: period=20, std_dev_multiplier=2.0
///
/// Parameters:
/// - prices: Array of closing prices
///
/// Returns:
/// - Tuple of (upper_band, middle_band, lower_band) arrays
pub fn bollinger_bands_default(
  prices : Array[Float],
) -> (Array[Float], Array[Float], Array[Float]) {
  bollinger_bands(prices, 20, Float::from_double(2.0))
}

///|
/// Calculate %B (Percent B) indicator
///
/// %B shows where the current price is relative to the Bollinger Bands.
///
/// **Formula:**
/// - %B = (Price - Lower Band) / (Upper Band - Lower Band)
///
/// **Interpretation:**
/// - %B > 1: Price above upper band (overbought)
/// - %B < 0: Price below lower band (oversold)
/// - %B = 0.5: Price at middle band
/// - %B = 0: Price at lower band
/// - %B = 1: Price at upper band
///
/// Parameters:
/// - price: Current price
/// - upper: Upper band value
/// - lower: Lower band value
///
/// Returns:
/// - %B value (typically 0-1 range, but can exceed)
///
/// Examples:
/// ```mbt check-disabled
/// let percent_b = bollinger_percent_b(105.0, 110.0, 100.0)
/// // Returns 0.5 (price at middle)
/// ```
pub fn bollinger_percent_b(
  price : Float,
  upper : Float,
  lower : Float,
) -> Float {
  let zero = Float::from_double(0.0)
  let band_width = upper - lower

  if band_width == zero {
    zero
  } else {
    (price - lower) / band_width
  }
}

///|
/// Calculate Bollinger Band Width
///
/// Band Width measures the distance between the upper and lower bands,
/// normalized by the middle band. It's used to identify volatility squeezes.
///
/// **Formula:**
/// - Band Width = (Upper Band - Lower Band) / Middle Band
///
/// **Interpretation:**
/// - Low Band Width: Squeeze (low volatility) - potential breakout
/// - High Band Width: Expansion (high volatility)
///
/// Parameters:
/// - upper: Upper band value
/// - lower: Lower band value
/// - middle: Middle band value
///
/// Returns:
/// - Band Width value (normalized)
///
/// Examples:
/// ```mbt check-disabled
/// let width = bollinger_band_width(110.0, 90.0, 100.0)
/// // Returns 0.2 (20% band width)
/// ```
pub fn bollinger_band_width(
  upper : Float,
  lower : Float,
  middle : Float,
) -> Float {
  let zero = Float::from_double(0.0)

  if middle == zero {
    zero
  } else {
    (upper - lower) / middle
  }
}

///|
/// Check if Bollinger Bands indicate a squeeze
///
/// A squeeze occurs when the bands are narrow relative to the middle band,
/// indicating low volatility and potential for a breakout.
///
/// Parameters:
/// - upper: Upper band value
/// - lower: Lower band value
/// - middle: Middle band value
/// - threshold: Squeeze threshold (typically 0.1 or 10%)
///
/// Returns:
/// - true if band width is below threshold
///
/// Examples:
/// ```mbt check-disabled
/// if is_bollinger_squeeze(102.0, 98.0, 100.0, 0.1) {
///   // Bands are narrow - watch for breakout
/// }
/// ```
pub fn is_bollinger_squeeze(
  upper : Float,
  lower : Float,
  middle : Float,
  threshold : Float,
) -> Bool {
  let width = bollinger_band_width(upper, lower, middle)
  width < threshold
}

///|
/// Check if price is above the upper band
///
/// Parameters:
/// - price: Current price
/// - upper: Upper band value
///
/// Returns:
/// - true if price is above upper band
pub fn is_above_upper_band(price : Float, upper : Float) -> Bool {
  price > upper
}

///|
/// Check if price is below the lower band
///
/// Parameters:
/// - price: Current price
/// - lower: Lower band value
///
/// Returns:
/// - true if price is below lower band
pub fn is_below_lower_band(price : Float, lower : Float) -> Bool {
  price < lower
}

///|
/// Get price position relative to Bollinger Bands
///
/// Parameters:
/// - price: Current price
/// - upper: Upper band value
/// - middle: Middle band value
/// - lower: Lower band value
///
/// Returns:
/// - Position enum indicating where price is relative to bands
pub fn bollinger_position(
  price : Float,
  upper : Float,
  middle : Float,
  lower : Float,
) -> BollingerPosition {
  if price > upper {
    BollingerPosition::AboveUpper
  } else if price >= middle {
    BollingerPosition::AboveMiddle
  } else if price >= lower {
    BollingerPosition::BelowMiddle
  } else {
    BollingerPosition::BelowLower
  }
}

///|
/// Calculate Bollinger Bands Bandwidth (array version)
///
/// Bandwidth measures the relative width between the upper and lower bands.
/// It indicates volatility: high bandwidth = high volatility, low bandwidth = low volatility.
///
/// Formula:
/// - Bandwidth = (Upper Band - Lower Band) / Middle Band
///
/// Parameters:
/// - upper: Upper band values
/// - middle: Middle band values
/// - lower: Lower band values
///
/// Returns:
/// - Array of Bandwidth values (same length as input)
///
/// Example usage:
/// ```mbt check-disabled
/// let (upper, middle, lower) = bollinger_bands(prices, 20, 2.0)
/// let bandwidth_values = bandwidth(upper, middle, lower)
/// ```
pub fn bandwidth(
  upper : Array[Float],
  middle : Array[Float],
  lower : Array[Float],
) -> Array[Float] {
  let zero = Float::from_double(0.0)
  let len = upper.length()
  let result : Array[Float] = []
  let mut i = 0

  while i < len {
    if middle[i] == zero {
      result.push(zero)
    } else {
      result.push((upper[i] - lower[i]) / middle[i])
    }
    i = i + 1
  }

  result
}

///|
/// Calculate Percent B (%B) - array version
///
/// %B indicates where the current price is relative to the Bollinger Bands.
/// It is a normalized oscillator that ranges from 0 to 1 (but can exceed these bounds).
///
/// Formula:
/// - %B = (Price - Lower Band) / (Upper Band - Lower Band)
///
/// Interpretation:
/// - %B > 1: Price above upper band (potentially overbought)
/// - %B < 0: Price below lower band (potentially oversold)
/// - %B = 0.5: Price at middle band
/// - %B = 0: Price at lower band
/// - %B = 1: Price at upper band
///
/// Parameters:
/// - prices: Array of prices
/// - upper: Upper band values
/// - lower: Lower band values
///
/// Returns:
/// - Array of %B values (same length as input)
///
/// Example usage:
/// ```mbt check-disabled
/// let (upper, _, lower) = bollinger_bands(prices, 20, 2.0)
/// let percent_b_values = percent_b(prices, upper, lower)
/// ```
pub fn percent_b(
  prices : Array[Float],
  upper : Array[Float],
  lower : Array[Float],
) -> Array[Float] {
  let zero = Float::from_double(0.0)
  let len = prices.length()
  let result : Array[Float] = []
  let mut i = 0

  while i < len {
    let band_width = upper[i] - lower[i]
    if band_width == zero {
      result.push(zero)
    } else {
      result.push((prices[i] - lower[i]) / band_width)
    }
    i = i + 1
  }

  result
}

///|
/// Enum representing price position relative to Bollinger Bands
pub enum BollingerPosition {
  AboveUpper // Price above upper band (potentially overbought)
  AboveMiddle // Price between middle and upper band
  BelowMiddle // Price between lower and middle band
  BelowLower // Price below lower band (potentially oversold)
} derive(Eq, Show)
