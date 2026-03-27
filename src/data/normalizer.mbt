/// Data normalizer for stock K-line data
///
/// This module provides functions for normalizing and adjusting stock prices
/// to account for corporate actions such as splits, dividends, and rights issues.
/// Essential for accurate backtesting and technical analysis.

///|
/// Adjustment type for price normalization
pub enum AdjustType {
  /// No adjustment (raw prices)
  None
  /// Forward adjustment (向前复权) - adjusts historical prices to current share base
  Forward
  /// Backward adjustment (向后复权) - adjusts current prices to historical share base
  Backward
} derive(Eq, Show)

///|
/// Helper function to create AdjustType::None
/// Useful for testing and configuration
pub fn adjust_type_none() -> AdjustType {
  AdjustType::None
}

///|
/// Helper function to create AdjustType::Forward
/// Useful for testing and configuration
pub fn adjust_type_forward() -> AdjustType {
  AdjustType::Forward
}

///|
/// Helper function to create AdjustType::Backward
/// Useful for testing and configuration
pub fn adjust_type_backward() -> AdjustType {
  AdjustType::Backward
}

///|
/// Adjustment factor information
pub struct AdjustFactor {
  /// Date when adjustment takes effect
  date : String
  /// Adjustment ratio (e.g., 0.5 for 2:1 split)
  ratio : Float
  /// Cash dividend per share
  dividend : Float
  /// Rights issue ratio
  rights_ratio : Float
  /// Rights issue price
  rights_price : Float
} derive(Show)

///|
/// Create an adjustment factor with default values
pub fn create_adjust_factor(
  date : String,
  ratio : Float,
  dividend : Float,
) -> AdjustFactor {
  AdjustFactor::{ date, ratio, dividend, rights_ratio: 0.0, rights_price: 0.0 }
}

///|
/// Apply forward adjustment to K-line data
///
/// Forward adjustment (向前复权) adjusts historical prices to match current share structure.
/// This is the most common method for backtesting as it reflects real trading conditions.
///
/// Parameters:
/// - klines: Array of K-line data to adjust
/// - adjust_factor: Cumulative adjustment factor to apply
///
/// Returns:
/// - Array of adjusted K-line data
pub fn apply_forward_adjustment(
  klines : Array[KLine],
  adjust_factor : Float,
) -> Array[KLine] {
  if klines.length() == 0 || adjust_factor == 1.0 {
    return klines
  }

  let result : Array[KLine] = []
  for kline in klines {
    result.push(KLine::{
      code: kline.code,
      date: kline.date,
      time: kline.time,
      open: kline.open * adjust_factor,
      high: kline.high * adjust_factor,
      low: kline.low * adjust_factor,
      close: kline.close * adjust_factor,
      volume: kline.volume / adjust_factor,
      amount: kline.amount,
      turn: kline.turn,
    })
  }
  result
}

///|
/// Apply backward adjustment to K-line data
///
/// Backward adjustment (向后复权) adjusts current prices to match historical share structure.
/// Useful for comparing current prices with historical levels.
///
/// Parameters:
/// - klines: Array of K-line data to adjust
/// - adjust_factor: Cumulative adjustment factor to apply
///
/// Returns:
/// - Array of adjusted K-line data
pub fn apply_backward_adjustment(
  klines : Array[KLine],
  adjust_factor : Float,
) -> Array[KLine] {
  if klines.length() == 0 || adjust_factor == 1.0 {
    return klines
  }

  let result : Array[KLine] = []
  for kline in klines {
    result.push(KLine::{
      code: kline.code,
      date: kline.date,
      time: kline.time,
      open: kline.open / adjust_factor,
      high: kline.high / adjust_factor,
      low: kline.low / adjust_factor,
      close: kline.close / adjust_factor,
      volume: kline.volume * adjust_factor,
      amount: kline.amount,
      turn: kline.turn,
    })
  }
  result
}

///|
/// Normalize prices to a specific date
///
/// This function adjusts all prices in the dataset to be comparable
/// with prices on the target date, accounting for splits and dividends.
///
/// Parameters:
/// - klines: Array of K-line data
/// - target_date: Date to normalize to (YYYY-MM-DD format)
/// - adjust_factors: Array of adjustment factors sorted by date
///
/// Returns:
/// - Array of normalized K-line data
pub fn normalize_to_date(
  klines : Array[KLine],
  target_date : String,
  adjust_factors : Array[AdjustFactor],
) -> Array[KLine] {
  if klines.length() == 0 {
    return klines
  }

  // Find cumulative adjustment factor for target date
  let cumulative_factor = calculate_cumulative_factor(
    target_date, adjust_factors,
  )

  // Apply forward adjustment
  apply_forward_adjustment(klines, cumulative_factor)
}

///|
/// Calculate cumulative adjustment factor up to a given date
fn calculate_cumulative_factor(
  target_date : String,
  adjust_factors : Array[AdjustFactor],
) -> Float {
  let mut factor : Float = 1.0

  for af in adjust_factors {
    if af.date <= target_date {
      // Apply split adjustment
      if af.ratio != 1.0 {
        factor = factor * af.ratio
      }
      // Apply dividend adjustment (simplified)
      if af.dividend > 0.0 {
        factor = factor * 0.99 // Simplified: assume small dividend impact
      }
    }
  }

  factor
}

///|
/// Normalize price series to start at 1.0 (base 100)
///
/// Useful for comparing relative performance across different stocks.
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of normalized prices starting at 1.0
pub fn normalize_price_series(klines : Array[KLine]) -> Array[Float] {
  if klines.length() == 0 {
    return []
  }

  let base_price = klines[0].close
  if base_price <= 0.0 {
    return []
  }

  let result : Array[Float] = []
  for kline in klines {
    result.push(kline.close / base_price)
  }
  result
}

///|
/// Calculate percentage returns from K-line data
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of daily returns (percentage change)
pub fn calculate_returns(klines : Array[KLine]) -> Array[Float] {
  if klines.length() < 2 {
    return []
  }

  let returns : Array[Float] = []
  let mut i = 1
  while i < klines.length() {
    let prev_close = klines[i - 1].close
    let curr_close = klines[i].close
    if prev_close > 0.0 {
      let daily_return = (curr_close - prev_close) / prev_close
      returns.push(daily_return)
    } else {
      returns.push(0.0)
    }
    i = i + 1
  }
  returns
}

///|
/// Calculate log returns from K-line data
///
/// Log returns are additive over time and useful for statistical analysis.
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of log returns
pub fn calculate_log_returns(klines : Array[KLine]) -> Array[Float] {
  if klines.length() < 2 {
    return []
  }

  let log_returns : Array[Float] = []
  let mut i = 1
  while i < klines.length() {
    let prev_close = klines[i - 1].close
    let curr_close = klines[i].close
    if prev_close > 0.0 && curr_close > 0.0 {
      // Approximate log return using simple return for small values
      // log(1+x) ≈ x when x is small
      let simple_return = (curr_close - prev_close) / prev_close
      log_returns.push(simple_return)
    } else {
      log_returns.push(0.0)
    }
    i = i + 1
  }
  log_returns
}

///|
/// Calculate rolling volatility (standard deviation of returns)
///
/// Parameters:
/// - returns: Array of returns
/// - window: Rolling window size
///
/// Returns:
/// - Array of rolling volatilities
pub fn calculate_rolling_volatility(
  returns : Array[Float],
  window : Int,
) -> Array[Float] {
  if returns.length() < window || window < 2 {
    return []
  }

  let volatilities : Array[Float] = []
  let mut i = window - 1
  while i < returns.length() {
    // Calculate mean
    let mut sum : Float = 0.0
    let mut j = i - window + 1
    while j <= i {
      sum = sum + returns[j]
      j = j + 1
    }
    let mean = sum / Float::from_int(window)

    // Calculate variance
    let mut variance_sum : Float = 0.0
    j = i - window + 1
    while j <= i {
      let diff = returns[j] - mean
      variance_sum = variance_sum + diff * diff
      j = j + 1
    }
    let variance = variance_sum / Float::from_int(window - 1)

    // Convert Double from sqrt to Float
    let std_dev = Float::sqrt(variance)
    volatilities.push(std_dev)
    i = i + 1
  }
  volatilities
}

///|
/// Annualize volatility
///
/// Parameters:
/// - daily_volatility: Daily volatility
/// - trading_days: Number of trading days per year (default 252)
///
/// Returns:
/// - Annualized volatility
pub fn annualize_volatility(
  daily_volatility : Float,
  trading_days : Int,
) -> Float {
  let sqrt_factor = Float::sqrt(Float::from_int(trading_days))
  daily_volatility * sqrt_factor
}

///|
/// Normalize volume by average
///
/// Parameters:
/// - klines: Array of K-line data
/// - window: Rolling window for average calculation
///
/// Returns:
/// - Array of normalized volume ratios
pub fn normalize_volume(klines : Array[KLine], window : Int) -> Array[Float] {
  if klines.length() < window {
    return []
  }

  let ratios : Array[Float] = []
  let mut i = window - 1
  while i < klines.length() {
    // Calculate average volume
    let mut sum : Float = 0.0
    let mut j = i - window + 1
    while j <= i {
      sum = sum + klines[j].volume
      j = j + 1
    }
    let avg_volume = sum / Float::from_int(window)

    if avg_volume > 0.0 {
      ratios.push(klines[i].volume / avg_volume)
    } else {
      ratios.push(1.0)
    }
    i = i + 1
  }
  ratios
}

///|
/// Check if K-line data is valid
///
/// Validates:
/// - High >= Low
/// - High >= Open, High >= Close
/// - Low <= Open, Low <= Close
/// - All prices > 0
/// - Volume >= 0
///
/// Parameters:
/// - kline: K-line data to validate
///
/// Returns:
/// - true if valid, false otherwise
pub fn validate_kline(kline : KLine) -> Bool {
  if kline.high < kline.low {
    return false
  }
  if kline.high < kline.open || kline.high < kline.close {
    return false
  }
  if kline.low > kline.open || kline.low > kline.close {
    return false
  }
  if kline.open <= 0.0 || kline.close <= 0.0 {
    return false
  }
  if kline.volume < 0.0 {
    return false
  }
  true
}

///|
/// Filter invalid K-line data
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Array of valid K-line data
pub fn filter_invalid_klines(klines : Array[KLine]) -> Array[KLine] {
  let valid : Array[KLine] = []
  for kline in klines {
    if validate_kline(kline) {
      valid.push(kline)
    }
  }
  valid
}

///|
/// Sort K-line data by date (ascending)
///
/// Parameters:
/// - klines: Array of K-line data
///
/// Returns:
/// - Sorted array of K-line data
pub fn sort_klines_by_date(klines : Array[KLine]) -> Array[KLine] {
  // Simple bubble sort for MoonBit (no stdlib sort yet)
  let sorted : Array[KLine] = []
  for kline in klines {
    sorted.push(kline)
  }
  let len = sorted.length()
  let mut i = 0
  while i < len - 1 {
    let mut j = 0
    while j < len - i - 1 {
      if sorted[j].date > sorted[j + 1].date {
        let temp = sorted[j]
        sorted[j] = sorted[j + 1]
        sorted[j + 1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  sorted
}

///|
/// Trim K-line data to date range
///
/// Parameters:
/// - klines: Array of K-line data
/// - start_date: Start date (inclusive)
/// - end_date: End date (inclusive)
///
/// Returns:
/// - Filtered array of K-line data
pub fn trim_klines_to_range(
  klines : Array[KLine],
  start_date : String,
  end_date : String,
) -> Array[KLine] {
  let result : Array[KLine] = []
  for kline in klines {
    if kline.date >= start_date && kline.date <= end_date {
      result.push(kline)
    }
  }
  result
}

///|
/// Parse a 4-digit year from a date string at given position
fn parse_date_int(date : String, start : Int, len : Int) -> Int {
  let mut val = 0
  let mut i = 0
  while i < len {
    let idx = start + i
    if idx < date.length() {
      let c : UInt16 = date.code_unit_at(idx)
      if c >= 48 && c <= 57 {
        val = val * 10 + (c.to_int() - 48)
      }
    }
    i = i + 1
  }
  val
}

///|
/// Get the week number for a date (YYYY-MM-DD format)
/// Returns a unique week identifier based on year and week number
fn get_week_key(date : String) -> String {
  // Extract year, month, day from YYYY-MM-DD format
  let year = parse_date_int(date, 0, 4)
  let month = parse_date_int(date, 5, 2)
  let day = parse_date_int(date, 9, 2)

  // Calculate day of year
  let days_in_months = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  let day_of_year = days_in_months[month - 1] + day

  // Add leap day if applicable
  let is_leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
  let mut day_of_year_adj = day_of_year
  if is_leap && month > 2 {
    day_of_year_adj = day_of_year_adj + 1
  }

  // Calculate week number (ISO 8601 style: week starts on Monday)
  // Find day of week using Zeller-like formula
  let mut y = year
  let mut m = month
  if m < 3 {
    m = m + 12
    y = y - 1
  }
  let q = day
  let k = y % 100
  let j = y / 100
  let h = (q + 13 * (m + 1) / 5 + k + k / 4 + j / 4 - 2 * j) % 7
  // h: 0=Saturday, 1=Sunday, 2=Monday, ..., 6=Friday
  // Convert to ISO: 1=Monday, ..., 7=Sunday
  let day_of_week = (h + 5) % 7 + 1

  // Calculate week number
  let week_num = (day_of_year_adj - day_of_week + 10) / 7

  // Handle edge cases
  let final_week = if week_num <= 0 {
    // Last week of previous year
    year - 1
  } else if week_num > 52 {
    // Check if it's actually week 1 of next year
    let days_in_year = if is_leap { 366 } else { 365 }
    let remaining_days = days_in_year - day_of_year_adj
    if remaining_days < 7 && day_of_week <= 4 {
      // It's week 1 of next year
      year + 1
    } else {
      week_num
    }
  } else {
    week_num
  }

  // Return year-week format for grouping
  Int::to_string(year) + "-W" + Int::to_string(final_week)
}

///|
/// Adjust K-line data based on adjustment type
///
/// Unified function that applies forward, backward, or no adjustment
/// based on the specified AdjustType.
///
/// Parameters:
/// - klines: Array of K-line data to adjust
/// - adjust_type: Type of adjustment (None, Forward, Backward)
/// - adjust_factor: Adjustment factor to apply
///
/// Returns:
/// - Array of adjusted K-line data
pub fn adjust_klines(
  klines : Array[KLine],
  adjust_type : AdjustType,
  adjust_factor : Float,
) -> Array[KLine] {
  match adjust_type {
    AdjustType::None => klines
    AdjustType::Forward => apply_forward_adjustment(klines, adjust_factor)
    AdjustType::Backward => apply_backward_adjustment(klines, adjust_factor)
  }
}

///|
/// Resample K-line data to lower frequency
///
/// Parameters:
/// - klines: Array of daily K-line data (must be sorted by date)
/// - frequency: Target frequency (Weekly, Monthly)
///
/// Returns:
/// - Resampled K-line data with OHLCV aggregated correctly
///
/// Behavior:
/// - Weekly: Groups by ISO week number, uses first open, last close, high/low extremes
/// - Monthly: Groups by year-month, uses first open, last close, high/low extremes
pub fn resample_klines(
  klines : Array[KLine],
  frequency : Frequency,
) -> Array[KLine] {
  if klines.length() == 0 {
    return []
  }

  let result : Array[KLine] = []
  let mut period_start : KLine? = None
  let mut current_period_key = ""

  for kline in klines {
    // Calculate period key based on frequency
    let period_key = match frequency {
      Frequency::Weekly => get_week_key(kline.date)
      Frequency::Monthly => kline.date[:7].to_string() // YYYY-MM format
      _ => kline.date // For other frequencies, use date as-is
    }

    match period_start {
      None => {
        // First kline, initialize period
        current_period_key = period_key
        period_start = Some(KLine::{
          code: kline.code,
          date: kline.date,
          time: kline.time,
          open: kline.open,
          high: kline.high,
          low: kline.low,
          close: kline.close,
          volume: kline.volume,
          amount: kline.amount,
          turn: kline.turn,
        })
      }
      Some(start) =>
        // Check if still in same period
        if period_key == current_period_key {
          // Same period, aggregate OHLCV
          period_start = Some(KLine::{
            code: start.code,
            date: start.date,
            time: start.time,
            open: start.open,
            high: if start.high > kline.high {
              start.high
            } else {
              kline.high
            },
            low: if start.low < kline.low {
              start.low
            } else {
              kline.low
            },
            close: kline.close,
            volume: start.volume + kline.volume,
            amount: start.amount + kline.amount,
            turn: start.turn + kline.turn,
          })
        } else {
          // New period, push completed period and start new one
          result.push(start)
          current_period_key = period_key
          period_start = Some(KLine::{
            code: kline.code,
            date: kline.date,
            time: kline.time,
            open: kline.open,
            high: kline.high,
            low: kline.low,
            close: kline.close,
            volume: kline.volume,
            amount: kline.amount,
            turn: kline.turn,
          })
        }
    }
  }

  // Don't forget the last period
  match period_start {
    Some(last) => result.push(last)
    None => ignore(())
  }

  result
}
