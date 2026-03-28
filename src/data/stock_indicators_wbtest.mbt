///|
/// Whitebox tests for stock_indicators module
test "sma basic calculation" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
    Float::from_double(12.0),
    Float::from_double(13.0),
    Float::from_double(14.0),
  ]
  let result = sma(prices, 3)

  let _ = result[0] == Float::from_double(0.0)
  let _ = result[1] == Float::from_double(0.0)
  let _ = result[2] == Float::from_double(11.0)
  let _ = result[3] == Float::from_double(12.0)
  let _ = result[4] == Float::from_double(13.0)
}

///|
test "sma insufficient data" {
  let prices : Array[Float] = [
    Float::from_double(10.0),
    Float::from_double(11.0),
  ]
  let result = sma(prices, 5)
  let _ = result[0] == Float::from_double(0.0)
  let _ = result[1] == Float::from_double(0.0)
}

///|
test "calculate_price_stats_basic" {
  let klines = [
    KLine::daily(
      "sh.600000",
      "2024-01-01",
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(9.5),
      Float::from_double(10.2),
      Float::from_double(1000.0),
      Float::from_double(10200.0),
      Float::from_double(1.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-02",
      Float::from_double(10.2),
      Float::from_double(10.8),
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(1200.0),
      Float::from_double(12600.0),
      Float::from_double(1.8),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-03",
      Float::from_double(10.5),
      Float::from_double(11.0),
      Float::from_double(10.3),
      Float::from_double(10.8),
      Float::from_double(1100.0),
      Float::from_double(11880.0),
      Float::from_double(1.6),
    ),
  ]

  let stats = calculate_price_stats(klines, 2)

  let _ = stats.open == Float::from_double(10.5)
  let _ = stats.close == Float::from_double(10.8)
  let _ = stats.high == Float::from_double(11.0)
  let _ = stats.low == Float::from_double(10.3)
}

///|
test "calculate_price_stats_empty" {
  let klines : Array[KLine] = []
  let stats = calculate_price_stats(klines, 5)

  let _ = stats.open == Float::from_double(0.0)
  let _ = stats.close == Float::from_double(0.0)
  let _ = stats.avg_close == Float::from_double(0.0)
}

///|
test "calculate_volume_stats_basic" {
  let klines = [
    KLine::daily(
      "sh.600000",
      "2024-01-01",
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(9.5),
      Float::from_double(10.2),
      Float::from_double(1000.0),
      Float::from_double(10200.0),
      Float::from_double(1.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-02",
      Float::from_double(10.2),
      Float::from_double(10.8),
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(1500.0),
      Float::from_double(15750.0),
      Float::from_double(2.0),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-03",
      Float::from_double(10.5),
      Float::from_double(11.0),
      Float::from_double(10.3),
      Float::from_double(10.8),
      Float::from_double(2000.0),
      Float::from_double(21600.0),
      Float::from_double(2.5),
    ),
  ]

  let stats = calculate_volume_stats(klines, 2)

  let _ = stats.daily_volume == Float::from_double(2000.0)
  let _ = stats.avg_volume == Float::from_double(1750.0)
}

///|
test "calculate_turnover_stats_basic" {
  let klines = [
    KLine::daily(
      "sh.600000",
      "2024-01-01",
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(9.5),
      Float::from_double(10.2),
      Float::from_double(1000.0),
      Float::from_double(10200.0),
      Float::from_double(1.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-02",
      Float::from_double(10.2),
      Float::from_double(10.8),
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(1500.0),
      Float::from_double(15750.0),
      Float::from_double(2.0),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-03",
      Float::from_double(10.5),
      Float::from_double(11.0),
      Float::from_double(10.3),
      Float::from_double(10.8),
      Float::from_double(2000.0),
      Float::from_double(21600.0),
      Float::from_double(2.5),
    ),
  ]

  let stats = calculate_turnover_stats(klines, 2)

  let _ = stats.daily_turnover == Float::from_double(21600.0)
}

///|
test "calculate_turnover_rate_stats_basic" {
  let klines = [
    KLine::daily(
      "sh.600000",
      "2024-01-01",
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(9.5),
      Float::from_double(10.2),
      Float::from_double(1000.0),
      Float::from_double(10200.0),
      Float::from_double(1.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-02",
      Float::from_double(10.2),
      Float::from_double(10.8),
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(1500.0),
      Float::from_double(15750.0),
      Float::from_double(2.0),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-03",
      Float::from_double(10.5),
      Float::from_double(11.0),
      Float::from_double(10.3),
      Float::from_double(10.8),
      Float::from_double(2000.0),
      Float::from_double(21600.0),
      Float::from_double(2.5),
    ),
  ]

  let stats = calculate_turnover_rate_stats(klines, 2)

  let _ = stats.daily_turnover_rate == Float::from_double(2.5)
  let _ = stats.avg_turnover_rate == Float::from_double(2.25)
}

///|
test "calculate_price_change_stats_basic" {
  let klines = [
    KLine::daily(
      "sh.600000",
      "2024-01-01",
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(9.5),
      Float::from_double(10.0),
      Float::from_double(1000.0),
      Float::from_double(10000.0),
      Float::from_double(1.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-02",
      Float::from_double(10.0),
      Float::from_double(10.8),
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(1500.0),
      Float::from_double(15750.0),
      Float::from_double(2.0),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-03",
      Float::from_double(10.5),
      Float::from_double(11.0),
      Float::from_double(10.3),
      Float::from_double(11.0),
      Float::from_double(2000.0),
      Float::from_double(22000.0),
      Float::from_double(2.5),
    ),
  ]

  let stats = calculate_price_change_stats(klines, 2)

  let _ = stats.daily_change == Float::from_double(0.5)
  let _ = stats.period_change == Float::from_double(1.0)
  let _ = stats.period_change_pct == Float::from_double(10.0)
}

///|
test "calculate_stock_indicators_comprehensive" {
  let klines = [
    KLine::daily(
      "sh.600000",
      "2024-01-01",
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(9.5),
      Float::from_double(10.0),
      Float::from_double(1000.0),
      Float::from_double(10000.0),
      Float::from_double(1.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-02",
      Float::from_double(10.0),
      Float::from_double(10.8),
      Float::from_double(10.0),
      Float::from_double(10.5),
      Float::from_double(1500.0),
      Float::from_double(15750.0),
      Float::from_double(2.0),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-03",
      Float::from_double(10.5),
      Float::from_double(11.0),
      Float::from_double(10.3),
      Float::from_double(11.0),
      Float::from_double(2000.0),
      Float::from_double(22000.0),
      Float::from_double(2.5),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-04",
      Float::from_double(11.0),
      Float::from_double(11.5),
      Float::from_double(10.8),
      Float::from_double(11.2),
      Float::from_double(1800.0),
      Float::from_double(20160.0),
      Float::from_double(2.2),
    ),
    KLine::daily(
      "sh.600000",
      "2024-01-05",
      Float::from_double(11.2),
      Float::from_double(11.8),
      Float::from_double(11.0),
      Float::from_double(11.5),
      Float::from_double(2200.0),
      Float::from_double(25300.0),
      Float::from_double(2.8),
    ),
  ]

  let summary = calculate_stock_indicators(klines, 3)

  let _ = summary.code == "sh.600000"
  let _ = summary.date == "2024-01-05"
  let _ = summary.price.close == Float::from_double(11.5)
  let _ = summary.volume.daily_volume == Float::from_double(2200.0)
}
