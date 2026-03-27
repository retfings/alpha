/// Trailing Stop risk management
///
/// Trailing stops protect profits by adjusting the stop-loss price as
/// the position moves favorably. Unlike static stop-losses, trailing
/// stops only move in the direction of profit.

///|
/// Trailing stop state for a position
pub struct TrailingStop {
  /// Initial stop price
  stop_price : Float
  /// Trailing percentage (e.g., 0.05 for 5%)
  trail_pct : Float
  /// Highest price seen since entry (for long positions)
  highest_price : Float
  /// Lowest price seen since entry (for short positions)
  lowest_price : Float
}

///|
/// Create a new trailing stop
///
/// Parameters:
/// - entry_price: Position entry price
/// - trail_pct: Trailing percentage (e.g., 0.05 for 5%)
/// - is_long: true for long position, false for short
///
/// Returns:
/// - Initialized TrailingStop state
pub fn create_trailing_stop(
  entry_price : Float,
  trail_pct : Float,
  is_long : Bool,
) -> TrailingStop {
  TrailingStop::{
    stop_price: entry_price *
    (if is_long { 1.0 - trail_pct } else { 1.0 + trail_pct }),
    trail_pct,
    highest_price: entry_price,
    lowest_price: entry_price,
  }
}

///|
/// Update trailing stop with new price (long position)
///
/// For long positions, the stop price only moves up as the highest price increases.
///
/// Parameters:
/// - ts: Current TrailingStop state
/// - current_price: Current market price
///
/// Returns:
/// - Updated TrailingStop state
pub fn trailing_stop_long_update(
  ts : TrailingStop,
  current_price : Float,
) -> TrailingStop {
  let new_highest = if current_price > ts.highest_price {
    current_price
  } else {
    ts.highest_price
  }
  let new_stop = new_highest * (1.0 - ts.trail_pct)

  // Stop price only moves up, never down
  let final_stop = if new_stop > ts.stop_price {
    new_stop
  } else {
    ts.stop_price
  }

  TrailingStop::{
    stop_price: final_stop,
    trail_pct: ts.trail_pct,
    highest_price: new_highest,
    lowest_price: ts.lowest_price,
  }
}

///|
/// Update trailing stop with new price (short position)
///
/// For short positions, the stop price only moves down as the lowest price decreases.
///
/// Parameters:
/// - ts: Current TrailingStop state
/// - current_price: Current market price
///
/// Returns:
/// - Updated TrailingStop state
pub fn trailing_stop_short_update(
  ts : TrailingStop,
  current_price : Float,
) -> TrailingStop {
  let new_lowest = if current_price < ts.lowest_price {
    current_price
  } else {
    ts.lowest_price
  }
  let new_stop = new_lowest * (1.0 + ts.trail_pct)

  // Stop price only moves down, never up
  let final_stop = if new_stop < ts.stop_price {
    new_stop
  } else {
    ts.stop_price
  }

  TrailingStop::{
    stop_price: final_stop,
    trail_pct: ts.trail_pct,
    highest_price: ts.highest_price,
    lowest_price: new_lowest,
  }
}

///|
/// Check if position should be stopped out
///
/// Parameters:
/// - ts: Current TrailingStop state
/// - current_price: Current market price
/// - is_long: true for long position, false for short
///
/// Returns:
/// - true if current price crosses the stop price (trigger exit)
pub fn is_stopped_out(
  ts : TrailingStop,
  current_price : Float,
  is_long : Bool,
) -> Bool {
  if is_long {
    current_price < ts.stop_price
  } else {
    current_price > ts.stop_price
  }
}

///|
/// Get current stop price
///
/// Parameters:
/// - ts: TrailingStop state
///
/// Returns:
/// - Current stop price
pub fn get_stop_price(ts : TrailingStop) -> Float {
  ts.stop_price
}

///|
/// Calculate ATR-based trailing stop level
///
/// ATR trailing stops use Average True Range to set dynamic stop distances
/// that adapt to market volatility.
///
/// **Formula:**
/// - Long: Stop = Highest High - (ATR Multiplier × ATR)
/// - Short: Stop = Lowest Low + (ATR Multiplier × ATR)
///
/// Parameters:
/// - highest: Highest price since entry
/// - lowest: Lowest price since entry
/// - atr: Current ATR value
/// - multiplier: ATR multiplier (typically 2.0 or 3.0)
/// - is_long: true for long position, false for short
///
/// Returns:
/// - Stop price level
pub fn atr_trailing_stop(
  highest : Float,
  lowest : Float,
  atr : Float,
  multiplier : Float,
  is_long : Bool,
) -> Float {
  let atr_distance = multiplier * atr
  if is_long {
    highest - atr_distance
  } else {
    lowest + atr_distance
  }
}

///|
/// Create ATR trailing stop state
///
/// Parameters:
/// - entry_price: Position entry price
/// - atr: Current ATR value
/// - multiplier: ATR multiplier (typically 2.0 or 3.0)
/// - is_long: true for long position, false for short
///
/// Returns:
/// - Initialized TrailingStop state with ATR-based stop
pub fn create_atr_trailing_stop(
  entry_price : Float,
  atr : Float,
  multiplier : Float,
  is_long : Bool,
) -> TrailingStop {
  let initial_stop = atr_trailing_stop(
    entry_price, entry_price, atr, multiplier, is_long,
  )
  TrailingStop::{
    stop_price: initial_stop,
    trail_pct: 0.0, // Not used for ATR trailing stops
    highest_price: entry_price,
    lowest_price: entry_price,
  }
}

///|
/// Update ATR trailing stop (long position)
///
/// Parameters:
/// - ts: Current TrailingStop state
/// - current_high: Current bar high
/// - current_low: Current bar low
/// - atr: Current ATR value
/// - multiplier: ATR multiplier
///
/// Returns:
/// - Updated TrailingStop state
pub fn atr_trailing_stop_long_update(
  ts : TrailingStop,
  current_high : Float,
  current_low : Float,
  atr : Float,
  multiplier : Float,
) -> TrailingStop {
  let new_highest = if current_high > ts.highest_price {
    current_high
  } else {
    ts.highest_price
  }
  let new_stop = atr_trailing_stop(
    new_highest, current_low, atr, multiplier, true,
  )

  // Stop price only moves up, never down
  let final_stop = if new_stop > ts.stop_price {
    new_stop
  } else {
    ts.stop_price
  }

  TrailingStop::{
    stop_price: final_stop,
    trail_pct: ts.trail_pct,
    highest_price: new_highest,
    lowest_price: if current_low < ts.lowest_price {
      current_low
    } else {
      ts.lowest_price
    },
  }
}

///|
/// Update ATR trailing stop (short position)
///
/// Parameters:
/// - ts: Current TrailingStop state
/// - current_high: Current bar high
/// - current_low: Current bar low
/// - atr: Current ATR value
/// - multiplier: ATR multiplier
///
/// Returns:
/// - Updated TrailingStop state
pub fn atr_trailing_stop_short_update(
  ts : TrailingStop,
  current_high : Float,
  current_low : Float,
  atr : Float,
  multiplier : Float,
) -> TrailingStop {
  let new_lowest = if current_low < ts.lowest_price {
    current_low
  } else {
    ts.lowest_price
  }
  let new_stop = atr_trailing_stop(
    current_high, new_lowest, atr, multiplier, false,
  )

  // Stop price only moves down, never up
  let final_stop = if new_stop < ts.stop_price {
    new_stop
  } else {
    ts.stop_price
  }

  TrailingStop::{
    stop_price: final_stop,
    trail_pct: ts.trail_pct,
    highest_price: if current_high > ts.highest_price {
      current_high
    } else {
      ts.highest_price
    },
    lowest_price: new_lowest,
  }
}

///|
/// Calculate trailing stop distance from current price
///
/// Parameters:
/// - ts: TrailingStop state
/// - current_price: Current market price
///
/// Returns:
/// - Distance as percentage of current price
pub fn trailing_stop_distance(
  ts : TrailingStop,
  current_price : Float,
) -> Float {
  if current_price == 0.0 {
    0.0
  } else {
    (current_price - ts.stop_price) / current_price
  }
}

///|
/// Enum representing trailing stop status
pub enum TrailingStopStatus {
  /// Stop price crossed, exit signal
  Triggered
  /// Position profitable and stop protecting gains
  Profitable
  /// Position at loss but stop not yet triggered
  AtLoss
  // Active reserved for future implementation
} derive(Eq, Show)

///|
/// Get trailing stop status
///
/// Parameters:
/// - ts: TrailingStop state
/// - entry_price: Original entry price
/// - current_price: Current market price
/// - is_long: true for long position, false for short
///
/// Returns:
/// - Current TrailingStopStatus
pub fn get_trailing_stop_status(
  ts : TrailingStop,
  entry_price : Float,
  current_price : Float,
  is_long : Bool,
) -> TrailingStopStatus {
  // First check if stopped out
  if is_stopped_out(ts, current_price, is_long) {
    TrailingStopStatus::Triggered
  } else if is_long {
    if current_price > entry_price && ts.stop_price > entry_price {
      TrailingStopStatus::Profitable
    } else if current_price > entry_price {
      TrailingStopStatus::Profitable
    } else {
      TrailingStopStatus::AtLoss
    }
  } else if current_price < entry_price && ts.stop_price < entry_price {
    TrailingStopStatus::Profitable
  } else if current_price < entry_price {
    TrailingStopStatus::Profitable
  } else {
    TrailingStopStatus::AtLoss
  }
}
