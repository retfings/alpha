/// Aroon trend indicator
///
/// Aroon is a trend-following indicator that measures time between highs and lows.
/// It consists of two lines: Aroon Up and Aroon Down.
///
/// **Interpretation:**
/// - Aroon Up > Aroon Down: Uptrend
/// - Aroon Down > Aroon Up: Downtrend
/// - Both low (< 50): Consolidation/range-bound market
/// - Both high (> 70): Strong trend (direction depends on which is higher)

///|
/// Calculate Aroon Up and Down
///
/// Aroon Up = ((Period - Days Since Highest High) / Period) * 100
/// Aroon Down = ((Period - Days Since Lowest Low) / Period) * 100
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period (typically 25 or 14)
///
/// Returns:
/// - Tuple of (aroon_up, aroon_down) arrays
/// - Values range from 0 to 100
///
/// Example usage:
/// ```mbt check-disabled
/// let (up, down) = aroon(klines, 25)
/// ```
pub fn aroon(klines : Array[@data.KLine], period : Int) -> (Array[Float], Array[Float]) {
  let zero = Float::from_double(0.0)
  let hundred = Float::from_double(100.0)
  let period_f = Float::from_int(period)

  if klines.length() == 0 || period <= 0 {
    let empty : Array[Float] = []
    return (empty, empty)
  }

  let up : Array[Float] = []
  let down : Array[Float] = []
  let len = klines.length()

  let mut i = 0
  while i < len {
    if i < period - 1 {
      // Insufficient data
      up.push(zero)
      down.push(zero)
    } else {
      // Find days since highest high and lowest low in the lookback period
      let mut highest_high = klines[i].high
      let mut lowest_low = klines[i].low
      let mut days_since_high = 0
      let mut days_since_low = 0

      let mut j = 1
      while j < period && i - j >= 0 {
        let idx = i - j
        if klines[idx].high > highest_high {
          highest_high = klines[idx].high
          days_since_high = j
        }
        if klines[idx].low < lowest_low {
          lowest_low = klines[idx].low
          days_since_low = j
        }
        j = j + 1
      }

      let up_val = (period_f - Float::from_int(days_since_high)) / period_f * hundred
      let down_val = (period_f - Float::from_int(days_since_low)) / period_f * hundred

      up.push(up_val)
      down.push(down_val)
    }
    i = i + 1
  }

  (up, down)
}

///|
/// Calculate Aroon Oscillator
///
/// Aroon Oscillator = Aroon Up - Aroon Down
///
/// Oscillator values range from -100 to +100:
/// - Positive: Bullish momentum
/// - Negative: Bearish momentum
/// - Near zero: Consolidation
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period
///
/// Returns:
/// - Array of oscillator values
pub fn aroon_oscillator(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  let (up, down) = aroon(klines, period)
  let len = up.length()
  let result : Array[Float] = []

  let mut i = 0
  while i < len {
    result.push(up[i] - down[i])
    i = i + 1
  }

  result
}

///|
/// Check if Aroon indicates an uptrend
///
/// Parameters:
/// - up: Aroon Up value
/// - down: Aroon Down value
///
/// Returns:
/// - true if Aroon Up > Aroon Down
pub fn is_aroon_uptrend(up : Float, down : Float) -> Bool {
  up > down
}

///|
/// Check if Aroon indicates a downtrend
///
/// Parameters:
/// - up: Aroon Up value
/// - down: Aroon Down value
///
/// Returns:
/// - true if Aroon Down > Aroon Up
pub fn is_aroon_downtrend(up : Float, down : Float) -> Bool {
  down > up
}

///|
/// Check if Aroon indicates a strong trend
///
/// A strong trend is indicated when one line is above 70 and the other is below 30.
///
/// Parameters:
/// - up: Aroon Up value
/// - down: Aroon Down value
///
/// Returns:
/// - true if strong trend detected
pub fn is_aroon_strong_trend(up : Float, down : Float) -> Bool {
  let threshold_high = Float::from_double(70.0)
  let threshold_low = Float::from_double(30.0)
  (up > threshold_high && down < threshold_low) ||
    (down > threshold_high && up < threshold_low)
}

///|
/// Check if Aroon indicates consolidation (sideways market)
///
/// Consolidation occurs when both Aroon lines are below 50.
///
/// Parameters:
/// - up: Aroon Up value
/// - down: Aroon Down value
///
/// Returns:
/// - true if consolidation detected
pub fn is_aroon_consolidation(up : Float, down : Float) -> Bool {
  let threshold = Float::from_double(50.0)
  up < threshold && down < threshold
}

///|
/// Enum representing Aroon trend state
pub enum AroonTrend {
  StrongUptrend   /// Aroon Up > 70, Aroon Down < 30
  Uptrend         /// Aroon Up > Aroon Down
  Neutral         /// Both lines near middle or crossing
  Downtrend       /// Aroon Down > Aroon Up
  StrongDowntrend /// Aroon Down > 70, Aroon Up < 30
  Consolidation   /// Both lines < 50
} derive(Eq, Show)

///|
/// Get Aroon trend state
///
/// Parameters:
/// - up: Aroon Up value
/// - down: Aroon Down value
///
/// Returns:
/// - AroonTrend enum value
pub fn get_aroon_trend(up : Float, down : Float) -> AroonTrend {
  let high_threshold = Float::from_double(70.0)
  let low_threshold = Float::from_double(30.0)
  let mid_threshold = Float::from_double(50.0)

  // Check for strong trends first
  if up > high_threshold && down < low_threshold {
    AroonTrend::StrongUptrend
  } else if down > high_threshold && up < low_threshold {
    AroonTrend::StrongDowntrend
  } else if up < mid_threshold && down < mid_threshold {
    AroonTrend::Consolidation
  } else if up > down {
    AroonTrend::Uptrend
  } else if down > up {
    AroonTrend::Downtrend
  } else {
    AroonTrend::Neutral
  }
}
