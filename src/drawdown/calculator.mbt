/// Drawdown calculation core

///|
/// Drawdown information
pub struct DrawdownInfo {
  /// Peak value
  peak : Float
  /// Trough value
  trough : Float
  /// Peak date
  peak_date : String
  /// Trough date
  trough_date : String
  /// Drawdown percentage (negative value)
  drawdown : Float
  /// Duration in days
  duration : Int
  /// Whether recovered
  recovered : Bool
}

///|
/// Drawdown series (drawdown at each point in time)
pub type DrawdownSeries = Array[Float]

///|
/// Calculate maximum drawdown from a list of values (e.g., equity curve)
///
/// Parameters:
/// - values: Array of portfolio values in chronological order
///
/// Returns:
/// - Maximum drawdown as a negative percentage (e.g., -0.15 for 15% drawdown)
pub fn calculate_max_drawdown(values : Array[Float]) -> Float {
  if values.length() < 2 {
    return 0.0
  }

  let mut max_drawdown : Float = 0.0
  let mut peak : Float = 0.0

  for value in values {
    if value > peak {
      peak = value
    }
    if peak > 0.0 {
      let drawdown = (value - peak) / peak
      if drawdown < max_drawdown {
        max_drawdown = drawdown
      }
    }
  }

  max_drawdown
}

///|
/// Calculate maximum drawdown with detailed information
///
/// Parameters:
/// - values: Array of portfolio values
/// - dates: Array of corresponding dates
///
/// Returns:
/// - DrawdownInfo with peak/trough details
pub fn calculate_max_drawdown_detailed(
  values : Array[Float],
  dates : Array[String],
) -> DrawdownInfo? {
  if values.length() < 2 || values.length() != dates.length() {
    return None
  }

  let mut max_drawdown : Float = 0.0
  let mut peak : Float = 0.0
  let mut peak_date = ""
  let mut peak_index = 0
  let mut trough_index = 0
  let len = values.length()
  let mut i = 0

  while i < len {
    let value = values[i]
    if value > peak {
      peak = value
      peak_date = dates[i]
      peak_index = i
    }
    if peak > 0.0 {
      let drawdown = (value - peak) / peak
      if drawdown < max_drawdown {
        max_drawdown = drawdown
        trough_index = i
      }
    }
    i = i + 1
  }

  Some(DrawdownInfo::{
    peak,
    trough: values[trough_index],
    peak_date,
    trough_date: dates[trough_index],
    drawdown: max_drawdown,
    duration: trough_index - peak_index,
    recovered: values[values.length() - 1] >= peak,
  })
}

///|
/// Calculate drawdown series (drawdown at each point in time)
///
/// Parameters:
/// - values: Array of portfolio values in chronological order
///
/// Returns:
/// - Array of drawdown percentages at each point
pub fn calculate_drawdown_series(values : Array[Float]) -> Array[Float] {
  if values.length() == 0 {
    return []
  }

  let series : Array[Float] = []
  let mut peak : Float = 0.0

  for value in values {
    if value > peak {
      peak = value
    }
    if peak > 0.0 {
      let drawdown = (value - peak) / peak
      series.push(drawdown)
    } else {
      series.push(0.0)
    }
  }

  series
}

///|
/// Calculate current drawdown (most recent drawdown from peak)
///
/// Parameters:
/// - values: Array of portfolio values in chronological order
///
/// Returns:
/// - Current drawdown as a negative percentage
pub fn calculate_current_drawdown(values : Array[Float]) -> Float {
  if values.length() == 0 {
    return 0.0
  }

  let mut peak : Float = 0.0
  let current = values.last()

  for value in values {
    if value > peak {
      peak = value
    }
  }

  match current {
    Some(c) if peak > 0.0 => (c - peak) / peak
    _ => 0.0
  }
}

///|
/// Calculate drawdown from K-line data (using close prices)
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Maximum drawdown based on close prices
pub fn calculate_drawdown_from_klines(klines : Array[@data.KLine]) -> Float {
  let values = klines.map(fn(k) { k.close })
  calculate_max_drawdown(values)
}

///|
/// Drawdown statistics
pub struct DrawdownStats {
  max_drawdown : Float
  current_drawdown : Float
  avg_drawdown : Float
  drawdown_count : Int
}

///|
/// Get comprehensive drawdown statistics
pub fn get_drawdown_stats(values : Array[Float]) -> DrawdownStats {
  let series = calculate_drawdown_series(values)
  let max_dd = calculate_max_drawdown(values)
  let current_dd = calculate_current_drawdown(values)

  // Calculate average of negative drawdowns
  let negative_drawdowns : Array[Float] = {
    let arr = []
    for d in series {
      if d < 0.0 {
        arr.push(d)
      }
    }
    arr
  }

  let avg_dd = if negative_drawdowns.length() > 0 {
    let mut sum : Float = 0.0
    for d in negative_drawdowns {
      sum = sum + d
    }
    sum / Float::from_int(negative_drawdowns.length())
  } else {
    0.0
  }

  DrawdownStats::{
    max_drawdown: max_dd,
    current_drawdown: current_dd,
    avg_drawdown: avg_dd,
    drawdown_count: negative_drawdowns.length(),
  }
}
