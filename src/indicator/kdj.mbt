/// KDJ (Stochastic Oscillator) indicator
///
/// KDJ is a momentum indicator that compares a security's closing price to its
/// price range over a specified period. It consists of three lines: K, D, and J.

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
///
/// Interpretation:
/// - Values above 80 indicate overbought conditions
/// - Values below 20 indicate oversold conditions
/// - K crossing above D is a bullish signal
/// - K crossing below D is a bearish signal
///
/// Example usage:
/// ```mbt check-disabled
/// let (k_line, d_line, j_line) = @indicator.kdj(klines, 9, 3, 3)
/// ```
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
