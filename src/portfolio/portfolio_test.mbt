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
  inspect(portfolio.cash, content=(
    #|101000
  ))
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
  inspect(pnl, content=(
    #|1000
  ))
  inspect(pnl_pct, content=(
    #|0.009999999776482582
  ))
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
  inspect(final_value, content=(
    #|202900
  ))
  inspect(final_pnl, content=(
    #|2900
  ))
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
