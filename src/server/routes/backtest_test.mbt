/// Backtest API Endpoint Tests
///
/// Blackbox tests for backtest execution and result endpoints

///|
test "handle_run_backtest returns completed response" {
  let body = "{\"strategy\":\"ma_cross\",\"stock\":\"sh.600000\"}"
  let response = handle_run_backtest(body)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("completed"))
  assert_true(response.body.contains("backtest_id"))
}

///|
test "handle_run_backtest with empty body" {
  let body = "{}"
  let response = handle_run_backtest(body)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("completed"))
}

///|
test "handle_run_backtest generates backtest_id" {
  let body = "{}"
  let response = handle_run_backtest(body)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("bt_001"))
}

///|
test "handle_list_backtests returns empty list" {
  let response = handle_list_backtests()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("backtests"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_get_backtest_result returns result for any id" {
  let response = handle_get_backtest_result("bt_001")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("bt_001"))
  assert_true(response.body.contains("status"))
}

///|
test "handle_get_backtest_result includes all result fields" {
  let response = handle_get_backtest_result("bt_test")
  assert_true(response.status_code == 200)
  // Should contain backtest result fields
  assert_true(response.body.contains("initial_capital"))
  assert_true(response.body.contains("final_capital"))
  assert_true(response.body.contains("total_return"))
  assert_true(response.body.contains("max_drawdown"))
  assert_true(response.body.contains("sharpe_ratio"))
}

///|
test "handle_get_backtest_result for different ids" {
  let resp1 = handle_get_backtest_result("bt_123")
  let resp2 = handle_get_backtest_result("bt_456")
  assert_true(resp1.status_code == 200)
  assert_true(resp2.status_code == 200)
  assert_true(resp1.body.contains("bt_123"))
  assert_true(resp2.body.contains("bt_456"))
}

///|
test "handle_delete_backtest returns success message" {
  let response = handle_delete_backtest("bt_001")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("message"))
  assert_true(response.body.contains("deleted"))
}

///|
test "backtest response includes all required metrics" {
  let response = handle_get_backtest_result("bt_metrics_test")
  assert_true(response.status_code == 200)
  let body = response.body
  // Check all required metrics are present
  assert_true(body.contains("backtest_id"))
  assert_true(body.contains("status"))
  assert_true(body.contains("result"))
  assert_true(body.contains("initial_capital"))
  assert_true(body.contains("final_capital"))
  assert_true(body.contains("total_return"))
  assert_true(body.contains("max_drawdown"))
  assert_true(body.contains("sharpe_ratio"))
  assert_true(body.contains("total_trades"))
  assert_true(body.contains("win_rate"))
}

///|
test "backtest run returns bt_001 id" {
  let response = handle_run_backtest("{}")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("bt_001"))
}
