/// Williams %R (Williams Percent Range) indicator
///
/// Williams %R is a momentum indicator that measures the level of the close
/// relative to the highest high for the lookback period. It is similar to the
/// Stochastic Oscillator but plotted on a negative scale.

///|
/// Calculate Williams %R (Williams Percent Range)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period (typically 14)
///
/// Returns:
/// - Array of Williams %R values (range: -100 to 0)
///
/// Interpretation:
/// - Values above -20 indicate overbought conditions
/// - Values below -80 indicate oversold conditions
/// - Williams %R is plotted on a scale of -100 to 0
///
/// Formula:
/// Williams %R = (Highest High - Close) / (Highest High - Lowest Low) * -100
///
/// Example usage:
/// ```mbt check-disabled
/// let wr_values = @indicator.williams_r(klines, 14)
/// ```
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
