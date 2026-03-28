///|
/// Whitebox tests for financial_metrics module
test "empty_financial_metrics" {
  let metrics = empty_financial_metrics()
  let _ = metrics.roe_avg == 0.0
  let _ = metrics.np_margin == 0.0
  let _ = metrics.gp_margin == 0.0
  let _ = metrics.net_profit == 0.0
  let _ = metrics.eps_ttm == 0.0
  let _ = metrics.mb_revenue == 0.0
  let _ = metrics.total_share == 0.0
  let _ = metrics.liqa_share == 0.0
}

///|
test "create_financial_metrics" {
  let metrics = create_financial_metrics(
    15.5, 12.3, 25.0, 50000.0, 2.5, 1000000.0, 500000.0, 300000.0,
  )
  let _ = metrics.roe_avg == 15.5
  let _ = metrics.np_margin == 12.3
  let _ = metrics.gp_margin == 25.0
}

///|
test "evaluate_financial_health_excellent" {
  let metrics = create_financial_metrics(
    25.0, 18.0, 30.0, 100000.0, 3.5, 2000000.0, 500000.0, 300000.0,
  )
  let health = evaluate_financial_health(metrics)
  let _ = health == FinancialHealth::Excellent
}

///|
test "evaluate_financial_health_good" {
  let metrics = create_financial_metrics(
    18.0, 12.0, 22.0, 50000.0, 2.0, 1000000.0, 500000.0, 300000.0,
  )
  let health = evaluate_financial_health(metrics)
  let _ = health == FinancialHealth::Good
}

///|
test "evaluate_financial_health_fair" {
  let metrics = create_financial_metrics(
    12.0, 8.0, 18.0, 30000.0, 1.5, 800000.0, 500000.0, 300000.0,
  )
  let health = evaluate_financial_health(metrics)
  let _ = health == FinancialHealth::Fair
}

///|
test "evaluate_financial_health_poor" {
  let metrics = create_financial_metrics(
    6.0, 3.0, 10.0, 10000.0, 0.5, 500000.0, 500000.0, 300000.0,
  )
  let health = evaluate_financial_health(metrics)
  let _ = health == FinancialHealth::Poor
}

///|
test "evaluate_financial_health_critical" {
  let metrics = create_financial_metrics(
    3.0, -2.0, 5.0, -5000.0, -0.5, 300000.0, 500000.0, 300000.0,
  )
  let health = evaluate_financial_health(metrics)
  let _ = health == FinancialHealth::Critical
}

///|
test "is_quality_stock_true" {
  let metrics = create_financial_metrics(
    15.0, 8.0, 20.0, 50000.0, 2.0, 1000000.0, 500000.0, 300000.0,
  )
  let _ = is_quality_stock(metrics) == true
}

///|
test "is_quality_stock_false_low_roe" {
  let metrics = create_financial_metrics(
    8.0, 8.0, 20.0, 50000.0, 2.0, 1000000.0, 500000.0, 300000.0,
  )
  let _ = is_quality_stock(metrics) == false
}

///|
test "is_value_stock" {
  let metrics = create_financial_metrics(
    18.0, 5.0, 15.0, 30000.0, 1.5, 800000.0, 500000.0, 300000.0,
  )
  let _ = is_value_stock(metrics, 15.0) == true
}

///|
test "is_growth_stock" {
  let metrics = create_financial_metrics(
    18.0, 15.0, 25.0, 80000.0, 3.0, 1500000.0, 500000.0, 300000.0,
  )
  let _ = is_growth_stock(metrics) == true
}

///|
test "compare_by_roe" {
  let a = create_financial_metrics(
    20.0, 10.0, 20.0, 50000.0, 2.0, 1000000.0, 500000.0, 300000.0,
  )
  let b = create_financial_metrics(
    15.0, 12.0, 22.0, 60000.0, 2.5, 1200000.0, 500000.0, 300000.0,
  )
  let _ = compare_by_roe(a, b) == true
}

///|
test "create_stock_financials" {
  let metrics = create_financial_metrics(
    18.0, 12.0, 22.0, 50000.0, 2.0, 1000000.0, 500000.0, 300000.0,
  )
  let stock = create_stock_financials("sh.600000", metrics)
  let _ = stock.code == "sh.600000"
  let _ = stock.health == FinancialHealth::Good
}

///|
test "sort_by_roe_desc" {
  let stocks = [
    create_stock_financials(
      "sh.600000",
      create_financial_metrics(
        15.0, 10.0, 20.0, 50000.0, 2.0, 1000000.0, 500000.0, 300000.0,
      ),
    ),
    create_stock_financials(
      "sh.600001",
      create_financial_metrics(
        25.0, 15.0, 25.0, 100000.0, 3.5, 2000000.0, 500000.0, 300000.0,
      ),
    ),
    create_stock_financials(
      "sh.600002",
      create_financial_metrics(
        10.0, 8.0, 15.0, 30000.0, 1.0, 500000.0, 500000.0, 300000.0,
      ),
    ),
  ]
  let sorted = sort_by_roe_desc(stocks)
  let _ = sorted[0].code == "sh.600001"
  let _ = sorted[1].code == "sh.600000"
  let _ = sorted[2].code == "sh.600002"
}
