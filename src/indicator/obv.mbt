/// On-Balance Volume (OBV) indicator
///
/// OBV is a volume-based indicator that uses volume flow to predict changes
/// in stock price. It adds volume on up days and subtracts volume on down days.

///|
/// Calculate OBV (On-Balance Volume)
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of OBV values
///
/// Interpretation:
/// - Rising OBV confirms rising prices (bullish)
/// - Falling OBV confirms falling prices (bearish)
/// - Divergence between OBV and price may signal a reversal
///
/// Formula:
/// - If Close > Previous Close: OBV = Previous OBV + Volume
/// - If Close < Previous Close: OBV = Previous OBV - Volume
/// - If Close = Previous Close: OBV = Previous OBV
///
/// Example usage:
/// ```mbt check-disabled
/// let obv_values = @indicator.obv(klines)
/// ```
pub fn obv(klines : Array[@data.KLine]) -> Array[Float] {
  if klines.length() == 0 {
    return []
  }

  let result : Array[Float] = []
  let mut obv = klines[0].volume
  result.push(obv)

  let len = klines.length()
  let mut i = 1

  while i < len {
    if klines[i].close > klines[i - 1].close {
      obv = obv + klines[i].volume
    } else if klines[i].close < klines[i - 1].close {
      obv = obv - klines[i].volume
    }
    // If close is equal, OBV doesn't change
    result.push(obv)
    i = i + 1
  }

  result
}
