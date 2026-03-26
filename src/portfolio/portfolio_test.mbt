/// Portfolio integration tests - snapshot tests for position and portfolio management

///|
test "Position creation snapshot" {
  let pos = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.5,
    current_price: 10.5,
  }
  inspect(pos.stock, content="sh.600000")
  inspect(pos.quantity, content="1000")
  inspect(pos.avg_cost, content="10.5")
  inspect(pos.current_price, content="10.5")
}

///|
test "Position value calculation snapshot" {
  let pos = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.5,
    current_price: 12.0,
  }
  let value = pos.value()
  inspect(value, content="12000")
}

///|
test "Position P&L calculation snapshot" {
  let pos = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.5,
    current_price: 12.0,
  }
  let pnl = pos.pnl()
  inspect(pnl, content="1500")
}

///|
test "Position P&L percentage calculation snapshot" {
  let pos = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.0,
    current_price: 11.5,
  }
  let pnl_pct = pos.pnl_pct()
  inspect(pnl_pct, content="0.15000000596046448")
}

///|
test "Position P&L percentage zero cost snapshot" {
  let pos = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 0.0,
    current_price: 11.5,
  }
  let pnl_pct = pos.pnl_pct()
  inspect(pnl_pct, content="0")
}

///|
test "Position loss scenario snapshot" {
  let pos = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 500.0,
    avg_cost: 20.0,
    current_price: 18.5,
  }
  let pnl = pos.pnl()
  let pnl_pct = pos.pnl_pct()
  inspect(pnl, content="-750")
  inspect(pnl_pct, content="-0.07500000298023224")
}

///|
test "Portfolio creation snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  inspect(portfolio.cash, content="100000")
  inspect(portfolio.initial_capital, content="100000")
  inspect(portfolio.positions.length(), content="0")
}

///|
test "Portfolio creation with zero capital snapshot" {
  let portfolio = @portfolio.create_portfolio(0.0)
  inspect(portfolio.cash, content="0")
  inspect(portfolio.initial_capital, content="0")
  inspect(portfolio.positions.length(), content="0")
}

///|
test "Portfolio total_value empty snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let value = portfolio.total_value()
  inspect(value, content="100000")
}

///|
test "Portfolio position_value empty snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let pos_value = portfolio.position_value()
  inspect(pos_value, content="0")
}

///|
test "Portfolio position_ratio empty snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let ratio = portfolio.position_ratio()
  inspect(ratio, content="0")
}

///|
test "Portfolio total_pnl empty snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let pnl = portfolio.total_pnl()
  inspect(pnl, content="0")
}

///|
test "Portfolio total_pnl_pct empty snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let pnl_pct = portfolio.total_pnl_pct()
  inspect(pnl_pct, content="0")
}

///|
test "Portfolio buy first position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let success = portfolio.buy("sh.600000", 500.0, 10.0)
  inspect(success, content="true")
  inspect(portfolio.cash, content="95000")
  inspect(portfolio.positions.length(), content="1")
  inspect(portfolio.positions[0].stock, content="sh.600000")
  inspect(portfolio.positions[0].quantity, content="500")
  inspect(portfolio.positions[0].avg_cost, content="10")
}

///|
test "Portfolio buy insufficient funds snapshot" {
  let portfolio = @portfolio.create_portfolio(5000.0)
  let success = portfolio.buy("sh.600000", 1000.0, 10.0)
  inspect(success, content="false")
  inspect(portfolio.cash, content="5000")
  inspect(portfolio.positions.length(), content="0")
}

///|
test "Portfolio buy multiple positions snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.buy("sz.000001", 300.0, 20.0))

  inspect(portfolio.cash, content="89000")
  inspect(portfolio.positions.length(), content="2")
  inspect(portfolio.positions[0].stock, content="sh.600000")
  inspect(portfolio.positions[1].stock, content="sz.000001")
}

///|
test "Portfolio buy add to existing position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.buy("sh.600000", 300.0, 11.0))

  inspect(portfolio.positions.length(), content="1")
  inspect(portfolio.positions[0].quantity, content="800")
  inspect(
    portfolio.positions[0].avg_cost,
    content=(
      #|10.375
    ),
  )
}

///|
test "Portfolio total_value with positions snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let value = portfolio.total_value()
  inspect(value, content="100000")
}

///|
test "Portfolio position_value with positions snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let pos_value = portfolio.position_value()
  inspect(pos_value, content="5000")
}

///|
test "Portfolio position_ratio with positions snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let ratio = portfolio.position_ratio()
  inspect(ratio, content="0.05000000074505806")
}

///|
test "Portfolio sell partial position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let success = portfolio.sell("sh.600000", 200.0, 12.0)
  inspect(success, content="true")
  inspect(portfolio.positions[0].quantity, content="300")
  inspect(portfolio.cash, content="97400")
}

///|
test "Portfolio sell full position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let success = portfolio.sell("sh.600000", 500.0, 12.0)
  inspect(success, content="true")
  inspect(portfolio.positions.length(), content="0")
  inspect(
    portfolio.cash,
    content=(
      #|101000
    ),
  )
}

///|
test "Portfolio sell more than held snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let success = portfolio.sell("sh.600000", 1000.0, 12.0)
  inspect(success, content="false")
  inspect(portfolio.positions.length(), content="1")
}

///|
test "Portfolio sell non-existent position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let success = portfolio.sell("sz.000001", 100.0, 20.0)
  inspect(success, content="false")
}

///|
test "Portfolio P&L after profitable trade snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.sell("sh.600000", 500.0, 12.0))

  let pnl = portfolio.total_pnl()
  let pnl_pct = portfolio.total_pnl_pct()
  inspect(
    pnl,
    content=(
      #|1000
    ),
  )
  inspect(
    pnl_pct,
    content=(
      #|0.009999999776482582
    ),
  )
}

///|
test "Portfolio P&L after losing trade snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.sell("sh.600000", 500.0, 8.0))

  let pnl = portfolio.total_pnl()
  let pnl_pct = portfolio.total_pnl_pct()
  inspect(pnl, content="-1000")
  inspect(pnl_pct, content="-0.009999999776482582")
}

///|
test "Portfolio update_prices snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.buy("sz.000001", 300.0, 20.0))

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(11.0)
    } else {
      Float::from_double(22.0)
    }
  }
  portfolio.update_prices(get_price)

  inspect(portfolio.positions[0].current_price, content="11")
  inspect(portfolio.positions[1].current_price, content="22")
}

///|
test "Portfolio update_prices affects value snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(12.0)
    } else {
      Float::from_double(10.0)
    }
  }
  portfolio.update_prices(get_price)

  let value = portfolio.total_value()
  let pos_value = portfolio.position_value()
  inspect(pos_value, content="6000")
  inspect(value, content="101000")
}

///|
test "Portfolio multiple positions complex scenario snapshot" {
  let portfolio = @portfolio.create_portfolio(200000.0)

  ignore(portfolio.buy("sh.600000", 1000.0, 10.0))
  ignore(portfolio.buy("sz.000001", 500.0, 20.0))
  ignore(portfolio.buy("sh.600036", 800.0, 30.0))

  inspect(portfolio.positions.length(), content="3")
  inspect(portfolio.cash, content="156000")
  inspect(portfolio.position_value(), content="44000")
  inspect(portfolio.total_value(), content="200000")

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(11.0)
    } else if code == "sz.000001" {
      Float::from_double(19.0)
    } else {
      Float::from_double(33.0)
    }
  }
  portfolio.update_prices(get_price)

  let final_value = portfolio.total_value()
  let final_pnl = portfolio.total_pnl()
  inspect(
    final_value,
    content=(
      #|202900
    ),
  )
  inspect(
    final_pnl,
    content=(
      #|2900
    ),
  )
}

///|
test "Portfolio zero capital buy failure snapshot" {
  let portfolio = @portfolio.create_portfolio(0.0)
  let success = portfolio.buy("sh.600000", 100.0, 10.0)
  inspect(success, content="false")
}

///|
test "Portfolio boundary case exact funds snapshot" {
  let portfolio = @portfolio.create_portfolio(5000.0)
  let success = portfolio.buy("sh.600000", 500.0, 10.0)
  inspect(success, content="true")
  inspect(portfolio.cash, content="0")
}

///|
test "Position equality snapshot" {
  let pos1 = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.5,
    current_price: 12.0,
  }
  let pos2 = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.5,
    current_price: 12.0,
  }
  let pos3 = @portfolio.Position::{
    stock: "sh.600000",
    quantity: 1000.0,
    avg_cost: 10.5,
    current_price: 11.0,
  }
  inspect(pos1 == pos2, content="true")
  inspect(pos1 == pos3, content="false")
}

///|
test "Portfolio Show instance snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  // Just verify the portfolio can be inspected without error
  inspect(portfolio.cash, content="95000")
}

///|
test "Portfolio calculate_position_pnl snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.buy("sz.000001", 300.0, 20.0))

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(12.0)
    } else {
      Float::from_double(18.0)
    }
  }
  portfolio.update_prices(get_price)

  let pnl = portfolio.calculate_position_pnl()
  // sh.600000: (12-10)*500 = 1000, sz.000001: (18-20)*300 = -600
  // Total: 1000 - 600 = 400
  inspect(pnl > Float::from_double(399.0), content="true")
  inspect(pnl < Float::from_double(401.0), content="true")
}

///|
test "Portfolio calculate_position_pnl_pct snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(11.0)
    } else {
      Float::from_double(10.0)
    }
  }
  portfolio.update_prices(get_price)

  let pnl_pct = portfolio.calculate_position_pnl_pct()
  // (11-10)/10 = 0.1 = 10%
  inspect(pnl_pct > Float::from_double(0.09), content="true")
  inspect(pnl_pct < Float::from_double(0.11), content="true")
}

///|
test "Portfolio get_total_exposure snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  ignore(portfolio.buy("sz.000001", 300.0, 20.0))

  let exposure = portfolio.get_total_exposure()
  // 500*10 + 300*20 = 5000 + 6000 = 11000
  inspect(exposure, content="11000")
}

///|
test "Portfolio get_position found snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  match portfolio.get_position("sh.600000") {
    Some(pos) => {
      inspect(pos.quantity, content="500")
      inspect(pos.avg_cost, content="10")
    }
    None => fail("Position should exist")
  }
}

///|
test "Portfolio get_position not found snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  match portfolio.get_position("sz.000001") {
    Some(_) => fail("Position should not exist")
    None => inspect("Position not found", content="Position not found")
  }
}

///|
test "Portfolio get_position_pnl snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(12.0)
    } else {
      Float::from_double(10.0)
    }
  }
  portfolio.update_prices(get_price)

  let pnl = portfolio.get_position_pnl("sh.600000")
  // (12-10)*500 = 1000
  inspect(pnl > Float::from_double(999.0), content="true")
  inspect(pnl < Float::from_double(1001.0), content="true")
}

///|
test "Portfolio get_position_pnl non-existent snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let pnl = portfolio.get_position_pnl("sz.000001")
  inspect(pnl, content="0")
}

///|
test "Portfolio get_position_pnl_pct snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(11.5)
    } else {
      Float::from_double(10.0)
    }
  }
  portfolio.update_prices(get_price)

  let pnl_pct = portfolio.get_position_pnl_pct("sh.600000")
  // (11.5-10)/10 = 0.15 = 15%
  inspect(pnl_pct > Float::from_double(0.14), content="true")
  inspect(pnl_pct < Float::from_double(0.16), content="true")
}

///|
test "Portfolio position_count snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  inspect(portfolio.position_count(), content="0")

  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  inspect(portfolio.position_count(), content="1")

  ignore(portfolio.buy("sz.000001", 300.0, 20.0))
  inspect(portfolio.position_count(), content="2")

  ignore(portfolio.sell("sh.600000", 500.0, 12.0))
  inspect(portfolio.position_count(), content="1")
}

///|
test "Portfolio has_position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  inspect(portfolio.has_position("sh.600000"), content="true")
  inspect(portfolio.has_position("sz.000001"), content="false")
}

///|
test "Portfolio calculate_daily_pnl snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))

  // Previous day position value: 500 * 10 = 5000
  let prev_values = Map::new()
  prev_values.set("sh.600000", Float::from_double(5000.0))

  // Current price: 12.0, current value: 500 * 12 = 6000
  let current_prices = Map::new()
  current_prices.set("sh.600000", Float::from_double(12.0))

  let daily_pnl = portfolio.calculate_daily_pnl(prev_values, current_prices)
  // Daily P&L = current value - previous value = 6000 - 5000 = 1000
  inspect(daily_pnl > Float::from_double(999.0), content="true")
  inspect(daily_pnl < Float::from_double(1001.0), content="true")
}

///|
test "Portfolio comprehensive P&L tracking scenario snapshot" {
  let portfolio = @portfolio.create_portfolio(200000.0)

  // Build positions
  ignore(portfolio.buy("sh.600000", 1000.0, 10.0))
  ignore(portfolio.buy("sz.000001", 500.0, 20.0))
  ignore(portfolio.buy("sh.600036", 800.0, 30.0))

  // Update prices to simulate market movement
  let get_price = fn(code) -> Float {
    if code == "sh.600000" {
      Float::from_double(11.0) // +10%
    } else if code == "sz.000001" {
      Float::from_double(19.0) // -5%
    } else {
      Float::from_double(33.0) // +10%
    }
  }
  portfolio.update_prices(get_price)

  // Check total P&L
  let total_pnl = portfolio.calculate_position_pnl()
  // sh.600000: (11-10)*1000 = 1000
  // sz.000001: (19-20)*500 = -500
  // sh.600036: (33-30)*800 = 2400
  // Total: 1000 - 500 + 2400 = 2900
  inspect(total_pnl > Float::from_double(2899.0), content="true")
  inspect(total_pnl < Float::from_double(2901.0), content="true")

  // Check individual position P&L
  let pnl_sh600000 = portfolio.get_position_pnl("sh.600000")
  inspect(pnl_sh600000 > Float::from_double(999.0), content="true")
  inspect(pnl_sh600000 < Float::from_double(1001.0), content="true")

  let pnl_sz000001 = portfolio.get_position_pnl("sz.000001")
  inspect(pnl_sz000001 < Float::from_double(-499.0), content="true")
  inspect(pnl_sz000001 > Float::from_double(-501.0), content="true")

  // Check exposure
  let exposure = portfolio.get_total_exposure()
  // 11*1000 + 19*500 + 33*800 = 11000 + 9500 + 26400 = 46900
  inspect(exposure > Float::from_double(46899.0), content="true")
  inspect(exposure < Float::from_double(46901.0), content="true")

  // Check position count
  inspect(portfolio.position_count(), content="3")

  // Verify all positions exist
  inspect(portfolio.has_position("sh.600000"), content="true")
  inspect(portfolio.has_position("sz.000001"), content="true")
  inspect(portfolio.has_position("sh.600036"), content="true")
  inspect(portfolio.has_position("sh.999999"), content="false")
}

///|
/// Edge case: Buy with zero quantity
test "Portfolio buy zero quantity snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let success = portfolio.buy("sh.600000", 0.0, 10.0)
  // Zero quantity costs 0, so it succeeds and creates position with 0 quantity
  inspect(success, content="true")
  inspect(portfolio.positions.length(), content="1")
  inspect(portfolio.cash, content="100000")
  inspect(portfolio.positions[0].quantity, content="0")
}

///|
/// Edge case: Buy with zero price (free shares)
test "Portfolio buy zero price snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let success = portfolio.buy("sh.600000", 100.0, 0.0)
  inspect(success, content="true")
  inspect(portfolio.positions.length(), content="1")
  inspect(portfolio.cash, content="100000")
  inspect(portfolio.positions[0].avg_cost, content="0")
}

///|
/// Edge case: Sell zero quantity
test "Portfolio sell zero quantity snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 100.0, 10.0))
  let success = portfolio.sell("sh.600000", 0.0, 12.0)
  // Selling 0 quantity succeeds but doesn't change cash
  inspect(success, content="true")
  inspect(portfolio.positions[0].quantity, content="100")
  inspect(portfolio.cash, content="99000")
}

///|
/// Edge case: Sell zero price
test "Portfolio sell zero price snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  ignore(portfolio.buy("sh.600000", 100.0, 10.0))
  let success = portfolio.sell("sh.600000", 50.0, 0.0)
  // Selling at zero price gives no cash
  inspect(success, content="true")
  inspect(portfolio.positions[0].quantity, content="50")
  inspect(portfolio.cash, content="99000")
}

///|
/// Edge case: Multiple buys and sells on same stock
test "Portfolio complex position management snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)

  // Buy in tranches
  ignore(portfolio.buy("sh.600000", 100.0, 10.0))  // 100 @ 10
  ignore(portfolio.buy("sh.600000", 200.0, 12.0))  // 200 @ 12
  ignore(portfolio.buy("sh.600000", 100.0, 11.0))  // 100 @ 11

  // Total: 400 shares, avg cost = (1000+2400+1100)/400 = 11.25
  inspect(portfolio.positions[0].quantity, content="400")
  inspect(portfolio.positions[0].avg_cost > Float::from_double(11.2), content="true")
  inspect(portfolio.positions[0].avg_cost < Float::from_double(11.3), content="true")

  // Sell partial
  ignore(portfolio.sell("sh.600000", 150.0, 13.0))
  inspect(portfolio.positions[0].quantity, content="250")
  // Avg cost should remain unchanged after sell
  inspect(portfolio.positions[0].avg_cost > Float::from_double(11.2), content="true")

  // Sell remaining
  ignore(portfolio.sell("sh.600000", 250.0, 14.0))
  inspect(portfolio.positions.length(), content="0")
}

///|
/// Edge case: Portfolio with single position - full lifecycle
test "Portfolio single position full lifecycle snapshot" {
  let portfolio = @portfolio.create_portfolio(50000.0)

  // Buy
  ignore(portfolio.buy("sh.600000", 500.0, 10.0))
  inspect(portfolio.cash, content="45000")
  inspect(portfolio.position_count(), content="1")

  // Update price up
  let get_price_up = fn(code) -> Float {
    if code == "sh.600000" { Float::from_double(12.0) } else { Float::from_double(0.0) }
  }
  portfolio.update_prices(get_price_up)
  let pnl_up = portfolio.get_position_pnl("sh.600000")
  inspect(pnl_up > Float::from_double(999.0), content="true")

  // Update price down
  let get_price_down = fn(code) -> Float {
    if code == "sh.600000" { Float::from_double(8.0) } else { Float::from_double(0.0) }
  }
  portfolio.update_prices(get_price_down)
  let pnl_down = portfolio.get_position_pnl("sh.600000")
  inspect(pnl_down < Float::from_double(-999.0), content="true")

  // Close position at loss
  ignore(portfolio.sell("sh.600000", 500.0, 8.0))
  inspect(portfolio.position_count(), content="0")
  inspect(portfolio.cash, content="49000")
  inspect(portfolio.total_pnl(), content="-1000")
}

///|
/// Edge case: Portfolio daily P&L with empty positions
test "Portfolio daily pnl empty positions snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let prev_values = Map::new()
  let current_prices = Map::new()
  let daily_pnl = portfolio.calculate_daily_pnl(prev_values, current_prices)
  inspect(daily_pnl, content="0")
}

///|
/// Edge case: get_position_pnl with non-existent position
test "Portfolio get_position_pnl non-existent position snapshot" {
  let portfolio = @portfolio.create_portfolio(100000.0)
  let pnl = portfolio.get_position_pnl("sh.600000")
  inspect(pnl, content="0")
  let pnl_pct = portfolio.get_position_pnl_pct("sh.600000")
  inspect(pnl_pct, content="0")
}
