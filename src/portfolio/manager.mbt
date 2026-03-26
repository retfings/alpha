/// Portfolio and position management

///|
/// Position in a single stock
pub struct Position {
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
  let zero = Float::from_double(0.0)
  let mut total = self.cash
  for pos in self.positions {
    total = total + pos.value()
  }
  total
}

///|
/// Get total position value
pub fn Portfolio::position_value(self : Portfolio) -> Float {
  let zero = Float::from_double(0.0)
  let mut total = zero
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
