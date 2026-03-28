/// Kelly Criterion Position Sizing tests

///|
test "kelly_fraction - basic calculation 60% win rate 2:1 ratio" {
  // Kelly = 0.60 - (0.40 / 2.0) = 0.60 - 0.20 = 0.40
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  assert_true(kelly > Float::from_double(0.39))
  assert_true(kelly < Float::from_double(0.41))
}

///|
test "kelly_fraction - 50% win rate 2:1 ratio" {
  // Kelly = 0.50 - (0.50 / 2.0) = 0.50 - 0.25 = 0.25
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.50),
    Float::from_double(2.0),
  )
  assert_true(kelly > Float::from_double(0.24))
  assert_true(kelly < Float::from_double(0.26))
}

///|
test "kelly_fraction - 40% win rate 3:1 ratio" {
  // Kelly = 0.40 - (0.60 / 3.0) = 0.40 - 0.20 = 0.20
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.40),
    Float::from_double(3.0),
  )
  assert_true(kelly > Float::from_double(0.19))
  assert_true(kelly < Float::from_double(0.21))
}

///|
test "kelly_fraction - unfavorable returns zero" {
  // Kelly = 0.30 - (0.70 / 1.0) = 0.30 - 0.70 = -0.40 -> 0.0
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.30),
    Float::from_double(1.0),
  )
  assert_eq(kelly, Float::from_double(0.0))
}

///|
test "kelly_fraction - zero win loss ratio returns zero" {
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.60),
    Float::from_double(0.0),
  )
  assert_eq(kelly, Float::from_double(0.0))
}

///|
test "kelly_fraction - edge case 100% win rate" {
  // Kelly = 1.0 - (0.0 / R) = 1.0
  let kelly = @risk.kelly_fraction(
    Float::from_double(1.0),
    Float::from_double(2.0),
  )
  assert_eq(kelly, Float::from_double(1.0))
}

///|
test "kelly_fraction - edge case 0% win rate" {
  // Kelly = 0.0 - (1.0 / R) -> negative -> 0.0
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.0),
    Float::from_double(2.0),
  )
  assert_eq(kelly, Float::from_double(0.0))
}

///|
test "half_kelly - returns 50% of full kelly" {
  let full = @risk.kelly_fraction(
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  let half = @risk.half_kelly(Float::from_double(0.60), Float::from_double(2.0))
  assert_true(half > Float::from_double(0.19))
  assert_true(half < Float::from_double(0.21))
  assert_true(half * Float::from_double(2.0) > full - Float::from_double(0.01))
}

///|
test "quarter_kelly - returns 25% of full kelly" {
  let full = @risk.kelly_fraction(
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  let quarter = @risk.quarter_kelly(
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  assert_true(quarter > Float::from_double(0.09))
  assert_true(quarter < Float::from_double(0.11))
  assert_true(
    quarter * Float::from_double(4.0) > full - Float::from_double(0.01),
  )
}

///|
test "kelly_position_size - full kelly" {
  let size = @risk.kelly_position_size(
    Float::from_double(0.60),
    Float::from_double(2.0),
    Float::from_double(100000.0),
    @risk.kelly_mode_full(),
    Float::from_double(0.0),
  )
  assert_true(size > Float::from_double(39000.0))
  assert_true(size < Float::from_double(41000.0))
}

///|
test "kelly_position_size - half kelly" {
  let size = @risk.kelly_position_size(
    Float::from_double(0.60),
    Float::from_double(2.0),
    Float::from_double(100000.0),
    @risk.kelly_mode_half(),
    Float::from_double(0.0),
  )
  assert_true(size > Float::from_double(19000.0))
  assert_true(size < Float::from_double(21000.0))
}

///|
test "kelly_position_size - quarter kelly" {
  let size = @risk.kelly_position_size(
    Float::from_double(0.60),
    Float::from_double(2.0),
    Float::from_double(100000.0),
    @risk.kelly_mode_quarter(),
    Float::from_double(0.0),
  )
  assert_true(size > Float::from_double(9000.0))
  assert_true(size < Float::from_double(11000.0))
}

///|
test "kelly_position_size - custom fraction" {
  let size = @risk.kelly_position_size(
    Float::from_double(0.60),
    Float::from_double(2.0),
    Float::from_double(100000.0),
    @risk.kelly_mode_custom(Float::from_double(0.75)),
    Float::from_double(0.75), // custom_fraction must match the mode's intended fraction
  )
  // Kelly = 0.40, 0.40 * 0.75 = 0.30, Size = 30000
  assert_true(size > Float::from_double(29000.0))
  assert_true(size < Float::from_double(31000.0))
}

///|
test "calculate_win_rate - basic calculation" {
  let win_rate = @risk.calculate_win_rate(60, 40)
  // 60 / (60 + 40) = 0.60
  assert_true(win_rate > Float::from_double(0.59))
  assert_true(win_rate < Float::from_double(0.61))
}

///|
test "calculate_win_rate - equal wins and losses" {
  let win_rate = @risk.calculate_win_rate(50, 50)
  assert_eq(win_rate, Float::from_double(0.5))
}

///|
test "calculate_win_rate - zero trades returns zero" {
  let win_rate = @risk.calculate_win_rate(0, 0)
  assert_eq(win_rate, Float::from_double(0.0))
}

///|
test "calculate_win_loss_ratio - basic calculation" {
  // avg_win = 60000/60 = 1000, avg_loss = 30000/40 = 750
  // ratio = 1000 / 750 = 1.333
  let ratio = @risk.calculate_win_loss_ratio(
    Float::from_double(60000.0),
    Float::from_double(30000.0),
    60,
    40,
  )
  assert_true(ratio > Float::from_double(1.30))
  assert_true(ratio < Float::from_double(1.37))
}

///|
test "calculate_win_loss_ratio - zero wins returns zero" {
  let ratio = @risk.calculate_win_loss_ratio(
    Float::from_double(0.0),
    Float::from_double(30000.0),
    0,
    40,
  )
  assert_eq(ratio, Float::from_double(0.0))
}

///|
test "calculate_win_loss_ratio - zero losses returns zero" {
  let ratio = @risk.calculate_win_loss_ratio(
    Float::from_double(60000.0),
    Float::from_double(0.0),
    60,
    0,
  )
  assert_eq(ratio, Float::from_double(0.0))
}

///|
test "kelly_from_trades - combined calculation" {
  // 60 wins, 40 losses -> win rate = 0.60
  // 60000 / 60 = 1000 avg win, 30000 / 40 = 750 avg loss
  // ratio = 1.333
  // Kelly = 0.60 - (0.40 / 1.333) = 0.60 - 0.30 = 0.30
  let kelly = @risk.kelly_from_trades(
    Float::from_double(60000.0),
    Float::from_double(30000.0),
    60,
    40,
  )
  assert_true(kelly > Float::from_double(0.29))
  assert_true(kelly < Float::from_double(0.31))
}

///|
test "kelly_with_cap - caps at maximum" {
  let uncapped = @risk.kelly_fraction(
    Float::from_double(0.70),
    Float::from_double(3.0),
  )
  // Kelly = 0.70 - (0.30 / 3.0) = 0.70 - 0.10 = 0.60
  assert_true(uncapped > Float::from_double(0.59))

  let capped = @risk.kelly_with_cap(uncapped, Float::from_double(0.25))
  assert_eq(capped, Float::from_double(0.25))
}

///|
test "kelly_with_cap - no cap when below maximum" {
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.50),
    Float::from_double(1.5),
  )
  // Kelly = 0.50 - (0.50 / 1.5) = 0.50 - 0.333 = 0.167
  let capped = @risk.kelly_with_cap(kelly, Float::from_double(0.25))
  assert_true(capped > Float::from_double(0.16))
  assert_true(capped < Float::from_double(0.18))
}

///|
test "expected_growth_rate - positive at optimal kelly" {
  // At Kelly fraction, growth rate should be positive
  let kelly = @risk.kelly_fraction(
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  let growth = @risk.expected_growth_rate(
    kelly,
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  assert_true(growth > Float::from_double(0.0))
}

///|
test "expected_growth_rate - calculation example" {
  // E[Return] = W*(f*R) - (1-W)*f
  // = 0.60 * (0.40 * 2.0) - 0.40 * 0.40
  // = 0.60 * 0.80 - 0.16
  // = 0.48 - 0.16 = 0.32
  let growth = @risk.expected_growth_rate(
    Float::from_double(0.40),
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  assert_true(growth > Float::from_double(0.30))
  assert_true(growth < Float::from_double(0.34))
}

///|
test "is_strategy_suitable_for_kelly - good strategy" {
  // 55% win rate, 1.5:1 ratio should be suitable
  let suitable = @risk.is_strategy_suitable_for_kelly(
    Float::from_double(0.55),
    Float::from_double(1.5),
  )
  assert_true(suitable)
}

///|
test "is_strategy_suitable_for_kelly - low win rate" {
  // 30% win rate is below 40% threshold
  let suitable = @risk.is_strategy_suitable_for_kelly(
    Float::from_double(0.30),
    Float::from_double(2.0),
  )
  assert_true(!suitable)
}

///|
test "is_strategy_suitable_for_kelly - poor ratio" {
  // 0.8:1 ratio is below 1.0 threshold
  let suitable = @risk.is_strategy_suitable_for_kelly(
    Float::from_double(0.60),
    Float::from_double(0.8),
  )
  assert_true(!suitable)
}

///|
test "is_strategy_suitable_for_kelly - unfavorable kelly" {
  // Even with ok win rate, if Kelly is negative, not suitable
  let suitable = @risk.is_strategy_suitable_for_kelly(
    Float::from_double(0.40),
    Float::from_double(0.5),
  )
  assert_true(!suitable)
}

///|
test "kelly modes enum equality" {
  // Test enum equality using helper functions
  assert_true(@risk.kelly_mode_full() == @risk.kelly_mode_full())
  assert_true(@risk.kelly_mode_half() == @risk.kelly_mode_half())
  assert_true(@risk.kelly_mode_quarter() == @risk.kelly_mode_quarter())
  assert_true(@risk.kelly_mode_full() != @risk.kelly_mode_half())
}

///|
test "realistic_strategy_simulation" {
  // Simulate a realistic trend-following strategy
  // Win rate: 45%, Win/Loss ratio: 2.5:1
  let win_rate = Float::from_double(0.45)
  let win_loss_ratio = Float::from_double(2.5)
  let capital = Float::from_double(500000.0)

  let _full_kelly = @risk.kelly_fraction(win_rate, win_loss_ratio)
  // Kelly = 0.45 - (0.55 / 2.5) = 0.45 - 0.22 = 0.23

  let half_kelly_size = @risk.kelly_position_size(
    win_rate,
    win_loss_ratio,
    capital,
    @risk.kelly_mode_half(),
    Float::from_double(0.0),
  )

  // Half Kelly = 0.115, Size = 500000 * 0.115 = 57500
  assert_true(half_kelly_size > Float::from_double(55000.0))
  assert_true(half_kelly_size < Float::from_double(60000.0))

  // Strategy should be suitable
  assert_true(@risk.is_strategy_suitable_for_kelly(win_rate, win_loss_ratio))
}

///|
test "kelly_mode_custom - creates custom fraction" {
  let custom = @risk.kelly_mode_custom(Float::from_double(0.60))
  // Verify the custom mode can be used in position sizing
  // Note: The custom_fraction parameter (5th arg) is used, not the value stored in the enum
  let size = @risk.kelly_position_size(
    Float::from_double(0.60),
    Float::from_double(2.0),
    Float::from_double(100000.0),
    custom,
    Float::from_double(0.60), // custom_fraction must be passed separately
  )
  // Kelly = 0.40, 0.40 * 0.60 = 0.24, Size = 24000
  assert_true(size > Float::from_double(23000.0))
  assert_true(size < Float::from_double(25000.0))
}

///|
test "expected_growth_rate - zero kelly returns zero" {
  let growth = @risk.expected_growth_rate(
    Float::from_double(0.0),
    Float::from_double(0.60),
    Float::from_double(2.0),
  )
  assert_eq(growth, Float::from_double(0.0))
}

///|
test "kelly_from_trades - zero total trades" {
  let kelly = @risk.kelly_from_trades(
    Float::from_double(0.0),
    Float::from_double(0.0),
    0,
    0,
  )
  assert_eq(kelly, Float::from_double(0.0))
}
