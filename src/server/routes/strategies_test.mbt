/// Strategy API Endpoint Tests
///
/// Blackbox tests for strategy selection and management endpoints

///|
test "handle_list_strategies returns all built-in strategies" {
  let response = handle_list_strategies()
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("strategies"))
  assert_true(response.body.contains("total"))
}

///|
test "handle_list_strategies response format" {
  let response = handle_list_strategies()
  assert_true(response.status_code == 200)
  // Should contain at least 3 built-in strategies
  assert_true(response.body.contains("ma_cross"))
  assert_true(response.body.contains("momentum"))
  assert_true(response.body.contains("rsi_mean_reversion"))
}

///|
test "handle_list_strategies includes strategy fields" {
  let response = handle_list_strategies()
  assert_true(response.status_code == 200)
  // Each strategy should have name, description, default_parameters, category
  assert_true(response.body.contains("name"))
  assert_true(response.body.contains("description"))
  assert_true(response.body.contains("default_parameters"))
  assert_true(response.body.contains("category"))
}

///|
test "get_builtin_strategies returns non-empty array" {
  let strategies = get_builtin_strategies()
  assert_true(strategies.length() >= 3)
}

///|
test "get_builtin_strategies each has required fields" {
  let strategies = get_builtin_strategies()
  let mut all_valid = true
  for s in strategies {
    if s.name == "" || s.description == "" || s.category == "" {
      all_valid = false
    }
  }
  assert_true(all_valid)
}

///|
test "ma_cross strategy details" {
  let strategies = get_builtin_strategies()
  let mut found = false
  for s in strategies {
    if s.name == "ma_cross" {
      found = true
      assert_true(s.category == "trend_following")
      assert_true(s.default_parameters.contains("fast_period"))
      assert_true(s.default_parameters.contains("slow_period"))
    }
  }
  assert_true(found)
}

///|
test "momentum strategy details" {
  let strategies = get_builtin_strategies()
  let mut found = false
  for s in strategies {
    if s.name == "momentum" {
      found = true
      assert_true(s.category == "momentum")
      assert_true(s.default_parameters.contains("lookback_period"))
    }
  }
  assert_true(found)
}

///|
test "rsi_mean_reversion strategy details" {
  let strategies = get_builtin_strategies()
  let mut found = false
  for s in strategies {
    if s.name == "rsi_mean_reversion" {
      found = true
      assert_true(s.category == "mean_reversion")
      assert_true(s.default_parameters.contains("rsi_period"))
      assert_true(s.default_parameters.contains("oversold"))
      assert_true(s.default_parameters.contains("overbought"))
    }
  }
  assert_true(found)
}

///|
test "handle_get_strategy returns ma_cross details" {
  let response = handle_get_strategy("ma_cross")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("ma_cross"))
  assert_true(response.body.contains("is_builtin"))
  assert_true(response.body.contains("Moving Average Crossover"))
}

///|
test "handle_get_strategy returns momentum details" {
  let response = handle_get_strategy("momentum")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("momentum"))
  assert_true(response.body.contains("Momentum Strategy"))
}

///|
test "handle_get_strategy returns rsi_mean_reversion details" {
  let response = handle_get_strategy("rsi_mean_reversion")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("rsi_mean_reversion"))
  assert_true(response.body.contains("RSI Mean Reversion"))
}

///|
test "handle_get_strategy returns 404 for unknown strategy" {
  let response = handle_get_strategy("unknown_strategy")
  assert_true(response.status_code == 404)
  assert_true(response.body.contains("error"))
  assert_true(response.body.contains("not found"))
}

///|
test "handle_create_strategy returns placeholder response" {
  let body = "{\"name\":\"test_strategy\",\"description\":\"Test\"}"
  let response = handle_create_strategy(body)
  assert_true(response.status_code == 201)
  assert_true(response.body.contains("message"))
  assert_true(response.body.contains("not yet implemented"))
}

///|
test "handle_update_strategy returns placeholder response" {
  let body = "{\"name\":\"updated_name\"}"
  let response = handle_update_strategy("ma_cross", body)
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("message"))
  assert_true(response.body.contains("not yet implemented"))
}

///|
test "handle_delete_strategy returns placeholder response" {
  let response = handle_delete_strategy("ma_cross")
  assert_true(response.status_code == 200)
  assert_true(response.body.contains("message"))
  assert_true(response.body.contains("not yet implemented"))
}

///|
test "BuiltInStrategy struct construction" {
  let s = BuiltInStrategy::create("test", "Test strategy", "{}", "test_category")
  assert_true(s.name == "test")
  assert_true(s.description == "Test strategy")
  assert_true(s.default_parameters == "{}")
  assert_true(s.category == "test_category")
}

///|
test "strategy categories are unique" {
  let strategies = get_builtin_strategies()
  // Collect categories
  let categories : Array[String] = []
  for s in strategies {
    let mut found = false
    for cat in categories {
      if cat == s.category {
        found = true
      }
    }
    if !found {
      categories.push(s.category)
    }
  }
  // Should have at least 2 different categories
  assert_true(categories.length() >= 2)
}

///|
test "strategy names are unique" {
  let strategies = get_builtin_strategies()
  let mut has_duplicates = false
  let mut i = 0
  while i < strategies.length() {
    let mut j = i + 1
    while j < strategies.length() {
      if strategies[i].name == strategies[j].name {
        has_duplicates = true
      }
      j = j + 1
    }
    i = i + 1
  }
  assert_true(!has_duplicates)
}
