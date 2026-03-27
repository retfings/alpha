/// ADX (Average Directional Index) indicator
///
/// ADX is a trend strength indicator that measures the strength of a trend
/// without regard to its direction. Values above 25 indicate a strong trend.

///|
/// Calculate True Range for a single kline
fn calc_tr(kline : @data.KLine, prev_close : Float) -> Float {
  let hl = kline.high - kline.low
  let hc = Float::abs(kline.high - prev_close)
  let lc = Float::abs(kline.low - prev_close)
  let max_range = if hl > hc { hl } else { hc }
  if max_range > lc {
    max_range
  } else {
    lc
  }
}

///|
/// Calculate Plus Directional Movement (+DM)
fn calc_plus_dm(
  current_high : Float,
  prev_high : Float,
  current_low : Float,
  prev_low : Float,
) -> Float {
  let up_move = current_high - prev_high
  let down_move = prev_low - current_low
  if up_move > down_move && up_move > Float::from_double(0.0) {
    up_move
  } else {
    Float::from_double(0.0)
  }
}

///|
/// Calculate Minus Directional Movement (-DM)
fn calc_minus_dm(
  current_high : Float,
  prev_high : Float,
  current_low : Float,
  prev_low : Float,
) -> Float {
  let up_move = current_high - prev_high
  let down_move = prev_low - current_low
  if down_move > up_move && down_move > Float::from_double(0.0) {
    down_move
  } else {
    Float::from_double(0.0)
  }
}

///|
/// Calculate ADX (Average Directional Index)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: ADX period (typically 14)
///
/// Returns:
/// - Array of ADX values (same length as input, with leading zeros)
///
/// Example usage:
/// ```mbt check-disabled
/// let adx_values = @indicator.adx(klines, 14)
/// ```
pub fn adx(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  if klines.length() <= period || period <= 1 {
    return klines.map(fn(_) { Float::from_double(0.0) })
  }

  let len = klines.length()
  let tr_values : Array[Float] = []
  let plus_dm_values : Array[Float] = []
  let minus_dm_values : Array[Float] = []

  // Calculate TR, +DM, -DM for each kline
  let mut i = 0
  while i < len {
    if i == 0 {
      tr_values.push(klines[i].high - klines[i].low)
      plus_dm_values.push(Float::from_double(0.0))
      minus_dm_values.push(Float::from_double(0.0))
    } else {
      let tr = calc_tr(klines[i], klines[i - 1].close)
      tr_values.push(tr)
      let pdm = calc_plus_dm(
        klines[i].high,
        klines[i - 1].high,
        klines[i].low,
        klines[i - 1].low,
      )
      plus_dm_values.push(pdm)
      let mdm = calc_minus_dm(
        klines[i].high,
        klines[i - 1].high,
        klines[i].low,
        klines[i - 1].low,
      )
      minus_dm_values.push(mdm)
    }
    i = i + 1
  }

  // Calculate smoothed TR, +DM, -DM using Wilder's smoothing
  let mut tr_smooth : Float = Float::from_double(0.0)
  let mut plus_dm_smooth : Float = Float::from_double(0.0)
  let mut minus_dm_smooth : Float = Float::from_double(0.0)

  // Initial sum for first 'period' values
  i = 0
  while i < period {
    tr_smooth = tr_smooth + tr_values[i]
    plus_dm_smooth = plus_dm_smooth + plus_dm_values[i]
    minus_dm_smooth = minus_dm_smooth + minus_dm_values[i]
    i = i + 1
  }

  let adx_values : Array[Float] = []

  // Fill leading zeros
  i = 0
  while i < period {
    adx_values.push(Float::from_double(0.0))
    i = i + 1
  }

  // Calculate ADX for remaining values
  i = period
  while i < len {
    // Calculate +DI and -DI
    let plus_di = if tr_smooth > Float::from_double(0.0) {
      plus_dm_smooth / tr_smooth * Float::from_double(100.0)
    } else {
      Float::from_double(0.0)
    }
    let minus_di = if tr_smooth > Float::from_double(0.0) {
      minus_dm_smooth / tr_smooth * Float::from_double(100.0)
    } else {
      Float::from_double(0.0)
    }

    // Calculate DX
    let di_sum = plus_di + minus_di
    let di_diff = Float::abs(plus_di - minus_di)
    let dx = if di_sum > Float::from_double(0.0) {
      di_diff / di_sum * Float::from_double(100.0)
    } else {
      Float::from_double(0.0)
    }

    adx_values.push(dx)

    // Apply Wilder's smoothing for next iteration
    if i + 1 < len {
      let period_f = Float::from_int(period)
      tr_smooth = tr_smooth - tr_smooth / period_f + tr_values[i + 1]
      plus_dm_smooth = plus_dm_smooth -
        plus_dm_smooth / period_f +
        plus_dm_values[i + 1]
      minus_dm_smooth = minus_dm_smooth -
        minus_dm_smooth / period_f +
        minus_dm_values[i + 1]
    }
    i = i + 1
  }

  adx_values
}

///|
/// Calculate +DI (Plus Directional Indicator)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: DI period (typically 14)
///
/// Returns:
/// - Array of +DI values
pub fn plus_di(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  if klines.length() <= period || period <= 1 {
    return klines.map(fn(_) { Float::from_double(0.0) })
  }

  let len = klines.length()
  let tr_values : Array[Float] = []
  let plus_dm_values : Array[Float] = []

  let mut i = 0
  while i < len {
    if i == 0 {
      tr_values.push(klines[i].high - klines[i].low)
      plus_dm_values.push(Float::from_double(0.0))
    } else {
      let tr = calc_tr(klines[i], klines[i - 1].close)
      tr_values.push(tr)
      let pdm = calc_plus_dm(
        klines[i].high,
        klines[i - 1].high,
        klines[i].low,
        klines[i - 1].low,
      )
      plus_dm_values.push(pdm)
    }
    i = i + 1
  }

  let mut tr_smooth : Float = Float::from_double(0.0)
  let mut plus_dm_smooth : Float = Float::from_double(0.0)

  i = 0
  while i < period {
    tr_smooth = tr_smooth + tr_values[i]
    plus_dm_smooth = plus_dm_smooth + plus_dm_values[i]
    i = i + 1
  }

  let di_values : Array[Float] = []
  i = 0
  while i < period {
    di_values.push(Float::from_double(0.0))
    i = i + 1
  }

  i = period
  while i < len {
    let pdi = if tr_smooth > Float::from_double(0.0) {
      plus_dm_smooth / tr_smooth * Float::from_double(100.0)
    } else {
      Float::from_double(0.0)
    }
    di_values.push(pdi)

    if i + 1 < len {
      let period_f = Float::from_int(period)
      tr_smooth = tr_smooth - tr_smooth / period_f + tr_values[i + 1]
      plus_dm_smooth = plus_dm_smooth -
        plus_dm_smooth / period_f +
        plus_dm_values[i + 1]
    }
    i = i + 1
  }

  di_values
}

///|
/// Calculate -DI (Minus Directional Indicator)
///
/// Parameters:
/// - klines: Array of K-line data
/// - period: DI period (typically 14)
///
/// Returns:
/// - Array of -DI values
pub fn minus_di(klines : Array[@data.KLine], period : Int) -> Array[Float] {
  if klines.length() <= period || period <= 1 {
    return klines.map(fn(_) { Float::from_double(0.0) })
  }

  let len = klines.length()
  let tr_values : Array[Float] = []
  let minus_dm_values : Array[Float] = []

  let mut i = 0
  while i < len {
    if i == 0 {
      tr_values.push(klines[i].high - klines[i].low)
      minus_dm_values.push(Float::from_double(0.0))
    } else {
      let tr = calc_tr(klines[i], klines[i - 1].close)
      tr_values.push(tr)
      let mdm = calc_minus_dm(
        klines[i].high,
        klines[i - 1].high,
        klines[i].low,
        klines[i - 1].low,
      )
      minus_dm_values.push(mdm)
    }
    i = i + 1
  }

  let mut tr_smooth : Float = Float::from_double(0.0)
  let mut minus_dm_smooth : Float = Float::from_double(0.0)

  i = 0
  while i < period {
    tr_smooth = tr_smooth + tr_values[i]
    minus_dm_smooth = minus_dm_smooth + minus_dm_values[i]
    i = i + 1
  }

  let di_values : Array[Float] = []
  i = 0
  while i < period {
    di_values.push(Float::from_double(0.0))
    i = i + 1
  }

  i = period
  while i < len {
    let mdi = if tr_smooth > Float::from_double(0.0) {
      minus_dm_smooth / tr_smooth * Float::from_double(100.0)
    } else {
      Float::from_double(0.0)
    }
    di_values.push(mdi)

    if i + 1 < len {
      let period_f = Float::from_int(period)
      tr_smooth = tr_smooth - tr_smooth / period_f + tr_values[i + 1]
      minus_dm_smooth = minus_dm_smooth -
        minus_dm_smooth / period_f +
        minus_dm_values[i + 1]
    }
    i = i + 1
  }

  di_values
}

///|
/// Check if trend is strong based on ADX value
///
/// Parameters:
/// - adx_value: Current ADX value
/// - threshold: Threshold for strong trend (default 25)
///
/// Returns:
/// - true if trend is strong, false otherwise
pub fn is_strong_trend(adx_value : Float, threshold : Float) -> Bool {
  adx_value > threshold
}
