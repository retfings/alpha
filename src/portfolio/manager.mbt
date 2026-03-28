/// Portfolio and position management
///
/// Design note: This module uses imperative mutable style with `mut` fields.
/// Methods like `buy`/`sell` modify `self` in-place and return `Bool` for success.
/// This is intentional for performance and simplicity in the backtest engine.
///
/// TODO: Consider functional alternative returning `(Portfolio, Bool)` for better
/// testability and immutability if needed in the future.

///|
/// Position in a single stock
pub(all) struct Position {
  stock : @data.StockCode
  mut quantity : Float
  mut avg_cost : Float
  mut current_price : Float
} derive(Show, Eq)

///|
/// Calculate position value
pub fn Position::value(self : Position) -> Float {
  self.quantity * self.current_price
}

///|
/// Calculate position P&L
pub fn Position::pnl(self : Position) -> Float {
  (self.current_price - self.avg_cost) * self.quantity
}

///|
/// Calculate position P&L percentage
pub fn Position::pnl_pct(self : Position) -> Float {
  let zero = Float::from_double(0.0)
  if self.avg_cost > zero {
    (self.current_price - self.avg_cost) / self.avg_cost
  } else {
    zero
  }
}

///|
/// Portfolio containing multiple positions
pub struct Portfolio {
  positions : Array[Position]
  mut cash : Float
  initial_capital : Float
} derive(Show)

///|
/// Create a new portfolio
pub fn create_portfolio(initial_capital : Float) -> Portfolio {
  Portfolio::{ positions: [], cash: initial_capital, initial_capital }
}

///|
/// Get total portfolio value
pub fn Portfolio::total_value(self : Portfolio) -> Float {
  let mut total = self.cash
  for pos in self.positions {
    total = total + pos.value()
  }
  total
}

///|
/// Get total position value
pub fn Portfolio::position_value(self : Portfolio) -> Float {
  let mut total = Float::from_double(0.0)
  for pos in self.positions {
    total = total + pos.value()
  }
  total
}

///|
/// Get position ratio (position / total)
pub fn Portfolio::position_ratio(self : Portfolio) -> Float {
  let zero = Float::from_double(0.0)
  let total = self.total_value()
  if total > zero {
    self.position_value() / total
  } else {
    zero
  }
}

///|
/// Get portfolio P&L
pub fn Portfolio::total_pnl(self : Portfolio) -> Float {
  self.total_value() - self.initial_capital
}

///|
/// Get portfolio P&L percentage
pub fn Portfolio::total_pnl_pct(self : Portfolio) -> Float {
  let zero = Float::from_double(0.0)
  if self.initial_capital > zero {
    self.total_pnl() / self.initial_capital
  } else {
    zero
  }
}

///|
/// Buy a stock (add or create position)
pub fn Portfolio::buy(
  self : Portfolio,
  stock : @data.StockCode,
  quantity : Float,
  price : Float,
) -> Bool {
  let cost = quantity * price
  if cost > self.cash {
    return false
  }

  // Find existing position
  let mut found = false
  for pos in self.positions {
    if pos.stock == stock {
      // Update average cost
      let total_cost = pos.avg_cost * pos.quantity + cost
      pos.quantity = pos.quantity + quantity
      pos.avg_cost = total_cost / pos.quantity
      pos.current_price = price
      found = true
    }
  }

  if !found {
    self.positions.push(Position::{
      stock,
      quantity,
      avg_cost: price,
      current_price: price,
    })
  }

  self.cash = self.cash - cost
  true
}

///|
/// Sell a stock (reduce or close position)
pub fn Portfolio::sell(
  self : Portfolio,
  stock : @data.StockCode,
  quantity : Float,
  price : Float,
) -> Bool {
  let mut i = 0
  while i < self.positions.length() {
    let pos = self.positions[i]
    if pos.stock == stock {
      if pos.quantity >= quantity {
        pos.quantity = pos.quantity - quantity
        self.cash = self.cash + quantity * price
        if pos.quantity == 0.0 {
          ignore(self.positions.remove(i))
        }
        return true
      }
    }
    i = i + 1
  }
  false
}

///|
/// Update current prices for all positions
pub fn Portfolio::update_prices(
  self : Portfolio,
  get_price : (@data.StockCode) -> Float,
) -> Unit {
  for pos in self.positions {
    pos.current_price = get_price(pos.stock)
  }
}

///|
/// Calculate total position P&L
///
/// Returns:
/// - Sum of all position P&L (unrealized)
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = create_portfolio(100000.0)
/// // ... add some positions ...
///
/// let pnl = portfolio.calculate_position_pnl()
/// ```
pub fn Portfolio::calculate_position_pnl(self : Portfolio) -> Float {
  let mut total_pnl = Float::from_double(0.0)
  for pos in self.positions {
    total_pnl = total_pnl + pos.pnl()
  }
  total_pnl
}

///|
/// Calculate total position P&L percentage
///
/// Returns:
/// - Weighted average P&L percentage across all positions
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = create_portfolio(100000.0)
/// // ... add some positions ...
///
/// let pnl_pct = portfolio.calculate_position_pnl_pct()
/// ```
pub fn Portfolio::calculate_position_pnl_pct(self : Portfolio) -> Float {
  let zero = Float::from_double(0.0)
  let mut total_cost = zero
  let mut total_value = zero
  for pos in self.positions {
    total_cost = total_cost + pos.avg_cost * pos.quantity
    total_value = total_value + pos.current_price * pos.quantity
  }
  if total_cost > zero {
    (total_value - total_cost) / total_cost
  } else {
    zero
  }
}

///|
/// Get total exposure (sum of all position values)
///
/// Returns:
/// - Total value of all positions (excludes cash)
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = create_portfolio(100000.0)
/// // ... add some positions ...
///
/// let exposure = portfolio.get_total_exposure()
/// ```
pub fn Portfolio::get_total_exposure(self : Portfolio) -> Float {
  self.position_value()
}

///|
/// Get position by stock code
///
/// Parameters:
/// - stock: Stock code to find
///
/// Returns:
/// - Position if found, None otherwise
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = create_portfolio(100000.0)
/// // ... add some positions ...
/// match portfolio.get_position("sh.600000") {
///   Some(pos) => inspect(pos.quantity)
///   None => inspect("Position not found")
/// }
/// ```
pub fn Portfolio::get_position(
  self : Portfolio,
  stock : @data.StockCode,
) -> Position? {
  for pos in self.positions {
    if pos.stock == stock {
      return Some(pos)
    }
  }
  None
}

///|
/// Get P&L for a specific position
///
/// Parameters:
/// - stock: Stock code to get P&L for
///
/// Returns:
/// - P&L if position exists, 0.0 otherwise
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = create_portfolio(100000.0)
/// // ... add some positions ...
///
/// let pnl = portfolio.get_position_pnl("sh.600000")
/// ```
pub fn Portfolio::get_position_pnl(
  self : Portfolio,
  stock : @data.StockCode,
) -> Float {
  match self.get_position(stock) {
    Some(pos) => pos.pnl()
    None => Float::from_double(0.0)
  }
}

///|
/// Get P&L percentage for a specific position
///
/// Parameters:
/// - stock: Stock code to get P&L percentage for
///
/// Returns:
/// - P&L percentage if position exists, 0.0 otherwise
///
/// Examples:
/// ```mbt check-disabled
/// let portfolio = create_portfolio(100000.0)
/// // ... add some positions ...
///
/// let pnl_pct = portfolio.get_position_pnl_pct("sh.600000")
/// ```
pub fn Portfolio::get_position_pnl_pct(
  self : Portfolio,
  stock : @data.StockCode,
) -> Float {
  match self.get_position(stock) {
    Some(pos) => pos.pnl_pct()
    None => Float::from_double(0.0)
  }
}

///|
/// Get number of positions
///
/// Returns:
/// - Number of open positions in the portfolio
pub fn Portfolio::position_count(self : Portfolio) -> Int {
  self.positions.length()
}

///|
/// Check if portfolio has a position
///
/// Parameters:
/// - stock: Stock code to check
///
/// Returns:
/// - true if portfolio holds the stock, false otherwise
pub fn Portfolio::has_position(
  self : Portfolio,
  stock : @data.StockCode,
) -> Bool {
  for pos in self.positions {
    if pos.stock == stock {
      return true
    }
  }
  false
}

///|
/// Get daily P&L change
///
/// Calculates the change in portfolio value from the previous day to today
/// by comparing position values using previous and current prices.
///
/// Parameters:
/// - prev_values: Map of stock codes to their position values from previous day
/// - current_prices: Map of stock codes to their current prices
///
/// Returns:
/// - Total P&L change since previous day (positive for gains, negative for losses)
///
/// Examples:
/// ```mbt check-disabled
/// let prev_values : Map[@data.StockCode, Float] = Map::new()
/// prev_values.set("sh.600000", 50000.0)
/// prev_values.set("sz.000001", 30000.0)
/// let current_prices : Map[@data.StockCode, Float] = Map::new()
/// current_prices.set("sh.600000", 51000.0)
/// current_prices.set("sz.000001", 29000.0)
/// let daily_pnl = portfolio.calculate_daily_pnl(prev_values, current_prices)
/// // daily_pnl should be 1000.0 (1000 gain - 1000 loss = 0, but this depends on positions)
/// ```
pub fn Portfolio::calculate_daily_pnl(
  self : Portfolio,
  prev_values : Map[@data.StockCode, Float],
  current_prices : Map[@data.StockCode, Float],
) -> Float {
  let mut daily_pnl = Float::from_double(0.0)

  // Calculate P&L for each position by comparing current value to previous value
  for pos in self.positions {
    match prev_values.get(pos.stock) {
      Some(prev_value) =>
        // Get current price for this position
        match current_prices.get(pos.stock) {
          Some(current_price) => {
            let current_value = pos.quantity * current_price
            daily_pnl = daily_pnl + (current_value - prev_value)
          }
          None => {
            // If no current price, use position's current_price
            let current_value = pos.value()
            daily_pnl = daily_pnl + (current_value - prev_value)
          }
        }
      None =>
        // New position today (not in prev_values), count full value as gain
        daily_pnl = daily_pnl + pos.value()
    }
  }

  daily_pnl
}
