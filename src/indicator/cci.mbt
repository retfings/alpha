/// Commodity Channel Index (CCI) indicator
///
/// CCI is a momentum oscillator that measures the variation of a security's
/// typical price from its statistical mean. It is used to identify overbought
/// and oversold conditions.

///|
/// Calculate CCI (Commodity Channel Index)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: Lookback period (typically 20)
///
/// Returns:
/// - Array of CCI values (same length as input, with leading zeros)
///
/// Interpretation:
/// - Values above +100 indicate overbought conditions
/// - Values below -100 indicate oversold conditions
/// - CCI crossing above +100 is a bullish signal
/// - CCI crossing below -100 is a bearish signal
///
/// Formula:
/// CCI = (Typical Price - SMA of TP) / (0.015 * Mean Deviation)
/// where Typical Price = (High + Low + Close) / 3
///
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
