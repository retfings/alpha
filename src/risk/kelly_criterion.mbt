/// Kelly Criterion Position Sizing
///
/// The Kelly Criterion is a mathematical formula for determining the optimal
/// position size to maximize long-term portfolio growth while avoiding ruin.
///
/// **Formula:**
/// Kelly % = W - [(1 - W) / R]
/// Where:
/// - W = Win probability (win rate)
/// - R = Win/Loss ratio (average win / average loss)

///|
/// Calculate Kelly Criterion fraction
///
/// The Kelly fraction represents the optimal percentage of capital to risk
/// on each trade to maximize long-term growth.
///
/// **Formula:**
/// Kelly % = WinRate - [(1 - WinRate) / WinLossRatio]
///
/// Parameters:
/// - win_rate: Probability of winning (0.0 to 1.0)
/// - win_loss_ratio: Average win amount / Average loss amount
///
/// Returns:
/// - Kelly fraction as a decimal (e.g., 0.25 = 25% of capital)
/// - Returns 0.0 if calculation yields negative (unfavorable conditions)
///
/// Example usage:
/// ```mbt check-disabled
/// // Strategy with 60% win rate and 2:1 win/loss ratio
/// let kelly = kelly_fraction(0.60, 2.0)
/// // Returns 0.40 (40% of capital)
/// ```
pub fn kelly_fraction(win_rate : Float, win_loss_ratio : Float) -> Float {
  if win_loss_ratio <= 0.0 {
    0.0
  } else {
    let kelly = win_rate - (1.0 - win_rate) / win_loss_ratio
    // Kelly should not be negative - unfavorable conditions
    if kelly < 0.0 {
      0.0
    } else {
      kelly
    }
  }
}

///|
/// Calculate Half-Kelly fraction
///
/// Half-Kelly is a more conservative approach that uses 50% of the
/// full Kelly fraction. This reduces volatility and drawdowns while
/// still capturing most of the growth potential.
///
/// Parameters:
/// - win_rate: Probability of winning (0.0 to 1.0)
/// - win_loss_ratio: Average win amount / Average loss amount
///
/// Returns:
/// - Half-Kelly fraction (50% of full Kelly)
pub fn half_kelly(win_rate : Float, win_loss_ratio : Float) -> Float {
  kelly_fraction(win_rate, win_loss_ratio) * 0.5
}

///|
/// Calculate Quarter-Kelly fraction
///
/// Quarter-Kelly is an even more conservative approach using 25% of
/// the full Kelly fraction. Recommended for risk-averse traders or
/// when there is uncertainty in the win rate/loss ratio estimates.
///
/// Parameters:
/// - win_rate: Probability of winning (0.0 to 1.0)
/// - win_loss_ratio: Average win amount / Average loss amount
///
/// Returns:
/// - Quarter-Kelly fraction (25% of full Kelly)
pub fn quarter_kelly(win_rate : Float, win_loss_ratio : Float) -> Float {
  kelly_fraction(win_rate, win_loss_ratio) * 0.25
}

///|
/// Kelly multiplier options for flexibility
pub enum KellyMode {
  /// Full Kelly (100%)
  /// Half Kelly (50%)
  /// Quarter Kelly (25%)
  /// Custom fraction
  Full
  Half
  Quarter
  Custom
} derive(Eq, Show)

///|
/// Helper functions to create KellyMode values
pub fn kelly_mode_full() -> KellyMode {
  KellyMode::Full
}

///|
pub fn kelly_mode_half() -> KellyMode {
  KellyMode::Half
}

///|
pub fn kelly_mode_quarter() -> KellyMode {
  KellyMode::Quarter
}

///|
pub fn kelly_mode_custom(_fraction : Float) -> KellyMode {
  KellyMode::Custom
}

///|
/// Calculate Kelly-based position size
///
/// Parameters:
/// - win_rate: Probability of winning (0.0 to 1.0)
/// - win_loss_ratio: Average win amount / Average loss amount
/// - capital: Total available capital
/// - mode: Kelly mode (Full, Half, Quarter, Custom)
/// - custom_fraction: Custom fraction (only used if mode is Custom)
///
/// Returns:
/// - Position size in capital units
pub fn kelly_position_size(
  win_rate : Float,
  win_loss_ratio : Float,
  capital : Float,
  mode : KellyMode,
  custom_fraction : Float,
) -> Float {
  let full_kelly = kelly_fraction(win_rate, win_loss_ratio)

  let kelly_pct = match mode {
    KellyMode::Full => full_kelly
    KellyMode::Half => full_kelly * 0.5
    KellyMode::Quarter => full_kelly * 0.25
    KellyMode::Custom => full_kelly * custom_fraction
  }

  capital * kelly_pct
}

///|
/// Calculate win rate from trade history
///
/// Parameters:
/// - wins: Number of winning trades
/// - losses: Number of losing trades
///
/// Returns:
/// - Win rate as a decimal (0.0 to 1.0)
pub fn calculate_win_rate(wins : Int, losses : Int) -> Float {
  let total = wins + losses
  if total == 0 {
    0.0
  } else {
    Float::from_int(wins) / Float::from_int(total)
  }
}

///|
/// Calculate win/loss ratio from trade history
///
/// Parameters:
/// - total_wins: Sum of all winning trade P&L
/// - total_losses: Sum of all losing trade P&L (as positive number)
/// - wins: Number of winning trades
/// - losses: Number of losing trades
///
/// Returns:
/// - Win/Loss ratio (average win / average loss)
pub fn calculate_win_loss_ratio(
  total_wins : Float,
  total_losses : Float,
  wins : Int,
  losses : Int,
) -> Float {
  if wins == 0 || losses == 0 || total_losses <= 0.0 {
    0.0
  } else {
    let avg_win = total_wins / Float::from_int(wins)
    let avg_loss = total_losses / Float::from_int(losses)
    avg_win / avg_loss
  }
}

///|
/// Calculate Kelly fraction from trade history
///
/// Convenience function that calculates Kelly fraction directly from
/// trade statistics.
///
/// Parameters:
/// - total_wins: Sum of all winning trade P&L
/// - total_losses: Sum of all losing trade P&L (as positive number)
/// - wins: Number of winning trades
/// - losses: Number of losing trades
///
/// Returns:
/// - Kelly fraction as a decimal
pub fn kelly_from_trades(
  total_wins : Float,
  total_losses : Float,
  wins : Int,
  losses : Int,
) -> Float {
  let win_rate = calculate_win_rate(wins, losses)
  let win_loss_ratio = calculate_win_loss_ratio(
    total_wins, total_losses, wins, losses,
  )
  kelly_fraction(win_rate, win_loss_ratio)
}

///|
/// Maximum Kelly cap to prevent over-concentration
///
/// Parameters:
/// - kelly_value: Raw Kelly fraction
/// - max_pct: Maximum allowed position size (e.g., 0.25 for 25%)
///
/// Returns:
/// - Capped Kelly fraction
pub fn kelly_with_cap(kelly_value : Float, max_pct : Float) -> Float {
  if kelly_value > max_pct {
    max_pct
  } else {
    kelly_value
  }
}

///|
/// Calculate expected growth rate at Kelly fraction
///
/// The expected growth rate shows how much the portfolio is expected
/// to grow per trade at the given Kelly fraction.
///
/// **Formula:**
/// Growth Rate = (1 + f*R)^W * (1 - f)^(1-W) - 1
/// Where f = Kelly fraction, R = Win/Loss ratio, W = Win rate
///
/// Parameters:
/// - kelly_fraction: Position size as fraction of capital
/// - win_rate: Probability of winning
/// - win_loss_ratio: Win/Loss ratio
///
/// Returns:
/// - Expected growth rate per trade
pub fn expected_growth_rate(
  kelly_fraction : Float,
  win_rate : Float,
  win_loss_ratio : Float,
) -> Float {
  // Simplified approximation: E[Return] = W*(f*R) - (1-W)*f
  win_rate * (kelly_fraction * win_loss_ratio) -
  (1.0 - win_rate) * kelly_fraction
}

///|
/// Check if strategy is suitable for Kelly sizing
///
/// A strategy is suitable if:
/// - Win rate is above 40%
/// - Win/Loss ratio is above 1.0
/// - Kelly fraction is positive
///
/// Parameters:
/// - win_rate: Probability of winning
/// - win_loss_ratio: Win/Loss ratio
///
/// Returns:
/// - true if strategy meets minimum criteria
pub fn is_strategy_suitable_for_kelly(
  win_rate : Float,
  win_loss_ratio : Float,
) -> Bool {
  win_rate >= 0.40 &&
  win_loss_ratio >= 1.0 &&
  kelly_fraction(win_rate, win_loss_ratio) > 0.0
}
