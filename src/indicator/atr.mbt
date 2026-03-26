/// Average True Range (ATR) indicator
///
/// ATR is a volatility indicator that measures the average range of price movement
/// over a specified period. Higher ATR values indicate higher volatility.

///|
/// Calculate True Range for each K-line
///
/// True Range is the maximum of:
/// - High - Low
/// - |High - Previous Close|
/// - |Low - Previous Close|
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of True Range values
pub fn true_range(klines : Array[@data.KLine]) -> Array[Float] {
  if klines.length() == 0 {
    return []
  }

  let tr : Array[Float] = []
  let len = klines.length()
  let mut i = 0

  while i < len {
    let kline = klines[i]
    if i == 0 {
      tr.push(kline.high - kline.low)
    } else {
      let prev_close = klines[i - 1].close
      let hl = kline.high - kline.low
      let hc = Float::abs(kline.high - prev_close)
      let lc = Float::abs(kline.low - prev_close)
      let max_range = if hl > hc { hl } else { hc }
      tr.push(if max_range > lc { max_range } else { lc })
    }
    i = i + 1
  }

  tr
}

///|
/// Calculate ATR (Average True Range)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: ATR period (typically 14)
///
/// Returns:
/// - Array of ATR values (same length as input, with leading zeros)
///
/// Example usage:
/// ```mbt check-disabled
/// let atr_values = @indicator.atr(klines, 14)
/// ```
pub fn atr(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  if klines.length() <= period || period <= 0 {
    return klines.map(fn(_) { Float::from_double(0.0) })
  }

  let tr = true_range(klines)
  let atr_values = sma(tr, period)
  atr_values
}
