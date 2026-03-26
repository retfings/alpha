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
} derive(ToJson, Show, Eq)

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
} derive(ToJson, Show)

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

///|
/// Find top N drawdowns from a value series
///
/// Identifies and returns the N largest (most severe) drawdown periods.
///
/// Parameters:
/// - values: Array of portfolio values in chronological order
/// - dates: Array of corresponding dates
/// - n: Number of top drawdowns to return
///
/// Returns:
/// - Array of DrawdownInfo sorted by severity (most severe first)
///
/// Examples:
/// ```mbt check
/// test "find_top_drawdowns example" {
///   let values = [100.0, 110.0, 100.0, 120.0, 100.0, 130.0]
///   let dates = ["2023-01-01", "2023-01-02", "2023-01-03", "2023-01-04", "2023-01-05", "2023-01-06"]
///   let top = find_top_drawdowns(values, dates, 2)
///   assert_true(top.length() == 2)
///   // First drawdown should be more severe
///   assert_true(top[0].drawdown <= top[1].drawdown)
/// }
/// ```
pub fn find_top_drawdowns(
  values : Array[Float],
  dates : Array[String],
  n : Int,
) -> Array[DrawdownInfo] {
  if values.length() < 2 || values.length() != dates.length() || n <= 0 {
    return []
  }

  // Find all drawdown periods
  let drawdowns : Array[DrawdownInfo] = []
  let len = values.length()
  let mut i = 0
  let mut peak_index = 0
  let mut peak_value = values[0]

  while i < len {
    let value = values[i]
    if value > peak_value {
      // Found new peak, check if previous drawdown is significant
      if i > peak_index + 1 {
        // Calculate drawdown from peak to trough
        let mut trough_index = peak_index + 1
        let mut trough_value = values[peak_index + 1]
        let mut j = peak_index + 1
        while j < i {
          if values[j] < trough_value {
            trough_value = values[j]
            trough_index = j
          }
          j = j + 1
        }
        let dd = (trough_value - peak_value) / peak_value
        if dd < -0.01 {
          // Only record if > 1% drawdown
          drawdowns.push(DrawdownInfo::{
            peak: peak_value,
            trough: trough_value,
            peak_date: dates[peak_index],
            trough_date: dates[trough_index],
            drawdown: dd,
            duration: trough_index - peak_index,
            recovered: value >= peak_value,
          })
        }
      }
      peak_value = value
      peak_index = i
    }
    i = i + 1
  }

  // Check final drawdown period
  if len > peak_index + 1 {
    let mut trough_index = peak_index + 1
    let mut trough_value = values[peak_index + 1]
    let mut j = peak_index + 1
    while j < len {
      if values[j] < trough_value {
        trough_value = values[j]
        trough_index = j
      }
      j = j + 1
    }
    let dd = (trough_value - peak_value) / peak_value
    if dd < -0.01 {
      drawdowns.push(DrawdownInfo::{
        peak: peak_value,
        trough: trough_value,
        peak_date: dates[peak_index],
        trough_date: dates[trough_index],
        drawdown: dd,
        duration: trough_index - peak_index,
        recovered: values[len - 1] >= peak_value,
      })
    }
  }

  // Sort by drawdown severity (most severe first) using bubble sort
  let result : Array[DrawdownInfo] = []
  for dd in drawdowns {
    result.push(dd)
  }
  let result_len = result.length()
  let mut ii = 0
  while ii < result_len - 1 {
    let mut jj = 0
    while jj < result_len - ii - 1 {
      if result[jj].drawdown > result[jj + 1].drawdown {
        let temp = result[jj]
        result[jj] = result[jj + 1]
        result[jj + 1] = temp
      }
      jj = jj + 1
    }
    ii = ii + 1
  }

  // Return top n
  if result.length() <= n {
    result
  } else {
    // Manually extract first n elements
    let top_n : Array[DrawdownInfo] = []
    let mut idx = 0
    while idx < n {
      top_n.push(result[idx])
      idx = idx + 1
    }
    top_n
  }
}
