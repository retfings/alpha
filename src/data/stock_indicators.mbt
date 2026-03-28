/// Stock market data indicators

///|
/// Calculate N-day simple moving average of prices
pub fn sma(values : Array[Float], period : Int) -> Array[Float] {
  if values.length() < period || period <= 0 {
    return values.map(fn(_) { Float::from_double(0.0) })
  }

  let result : Array[Float] = []
  let len = values.length()

  let mut window_sum : Float = Float::from_double(0.0)
  let mut i = 0
  while i < period {
    window_sum = window_sum + values[i]
    i = i + 1
  }

  i = 0
  while i < period - 1 {
    result.push(Float::from_double(0.0))
    i = i + 1
  }

  result.push(window_sum / Float::from_int(period))

  i = period
  while i < len {
    window_sum = window_sum + values[i] - values[i - period]
    result.push(window_sum / Float::from_int(period))
    i = i + 1
  }

  result
}

///|
/// Stock price statistics for a given period
pub struct PriceStats {
  open : Float
  close : Float
  high : Float
  low : Float
  avg_close : Float
  avg_high : Float
  avg_low : Float
} derive(Show, ToJson)

///|
pub fn calculate_price_stats(klines : Array[KLine], period : Int) -> PriceStats {
  if klines.length() == 0 {
    return PriceStats::{
      open: 0.0,
      close: 0.0,
      high: 0.0,
      low: 0.0,
      avg_close: 0.0,
      avg_high: 0.0,
      avg_low: 0.0,
    }
  }

  let last = klines[klines.length() - 1]

  let (avg_close, avg_high, avg_low) = if klines.length() >= period {
    let mut sum_close : Float = 0.0
    let mut sum_high : Float = 0.0
    let mut sum_low : Float = 0.0
    let mut i = klines.length() - period
    while i < klines.length() {
      sum_close = sum_close + klines[i].close
      sum_high = sum_high + klines[i].high
      sum_low = sum_low + klines[i].low
      i = i + 1
    }
    (
      sum_close / Float::from_int(period),
      sum_high / Float::from_int(period),
      sum_low / Float::from_int(period),
    )
  } else {
    (0.0, 0.0, 0.0)
  }

  PriceStats::{
    open: last.open,
    close: last.close,
    high: last.high,
    low: last.low,
    avg_close,
    avg_high,
    avg_low,
  }
}

///|
/// Volume statistics for a given period
pub struct VolumeStats {
  daily_volume : Float
  avg_volume : Float
  volume_ratio : Float
  max_volume : Float
  min_volume : Float
} derive(Show, ToJson)

///|
pub fn calculate_volume_stats(
  klines : Array[KLine],
  period : Int,
) -> VolumeStats {
  if klines.length() == 0 {
    return VolumeStats::{
      daily_volume: 0.0,
      avg_volume: 0.0,
      volume_ratio: 0.0,
      max_volume: 0.0,
      min_volume: 0.0,
    }
  }

  let last = klines[klines.length() - 1]

  let (avg_vol, max_vol, min_vol) = if klines.length() >= period {
    let mut sum : Float = 0.0
    let mut max = klines[klines.length() - period].volume
    let mut min = klines[klines.length() - period].volume
    let mut i = klines.length() - period
    while i < klines.length() {
      let v = klines[i].volume
      sum = sum + v
      if v > max {
        max = v
      }
      if v < min {
        min = v
      }
      i = i + 1
    }
    (sum / Float::from_int(period), max, min)
  } else {
    let mut sum : Float = 0.0
    let mut max = klines[0].volume
    let mut min = klines[0].volume
    let mut i = 0
    while i < klines.length() {
      let v = klines[i].volume
      sum = sum + v
      if v > max {
        max = v
      }
      if v < min {
        min = v
      }
      i = i + 1
    }
    (sum / Float::from_int(klines.length()), max, min)
  }

  let vol_ratio = if avg_vol > 0.0 { last.volume / avg_vol } else { 0.0 }

  VolumeStats::{
    daily_volume: last.volume,
    avg_volume: avg_vol,
    volume_ratio: vol_ratio,
    max_volume: max_vol,
    min_volume: min_vol,
  }
}

///|
/// Turnover statistics for a given period
pub struct TurnoverStats {
  daily_turnover : Float
  avg_turnover : Float
  turnover_ratio : Float
} derive(Show, ToJson)

///|
pub fn calculate_turnover_stats(
  klines : Array[KLine],
  period : Int,
) -> TurnoverStats {
  if klines.length() == 0 {
    return TurnoverStats::{
      daily_turnover: 0.0,
      avg_turnover: 0.0,
      turnover_ratio: 0.0,
    }
  }

  let last = klines[klines.length() - 1]

  let avg_turnover = if klines.length() >= period {
    let mut sum : Float = 0.0
    let mut i = klines.length() - period
    while i < klines.length() {
      sum = sum + klines[i].amount
      i = i + 1
    }
    sum / Float::from_int(period)
  } else {
    let mut sum : Float = 0.0
    let mut i = 0
    while i < klines.length() {
      sum = sum + klines[i].amount
      i = i + 1
    }
    sum / Float::from_int(klines.length())
  }

  let turnover_ratio = if avg_turnover > 0.0 {
    last.amount / avg_turnover
  } else {
    0.0
  }

  TurnoverStats::{ daily_turnover: last.amount, avg_turnover, turnover_ratio }
}

///|
/// Turnover rate statistics for a given period
pub struct TurnoverRateStats {
  daily_turnover_rate : Float
  avg_turnover_rate : Float
  rate_ratio : Float
  max_turnover_rate : Float
} derive(Show, ToJson)

///|
pub fn calculate_turnover_rate_stats(
  klines : Array[KLine],
  period : Int,
) -> TurnoverRateStats {
  if klines.length() == 0 {
    return TurnoverRateStats::{
      daily_turnover_rate: 0.0,
      avg_turnover_rate: 0.0,
      rate_ratio: 0.0,
      max_turnover_rate: 0.0,
    }
  }

  let last = klines[klines.length() - 1]

  let (avg_turn, max_turn) = if klines.length() >= period {
    let mut sum : Float = 0.0
    let mut max = klines[klines.length() - period].turn
    let mut i = klines.length() - period
    while i < klines.length() {
      let t = klines[i].turn
      sum = sum + t
      if t > max {
        max = t
      }
      i = i + 1
    }
    (sum / Float::from_int(period), max)
  } else {
    let mut sum : Float = 0.0
    let mut max = klines[0].turn
    let mut i = 0
    while i < klines.length() {
      let t = klines[i].turn
      sum = sum + t
      if t > max {
        max = t
      }
      i = i + 1
    }
    (sum / Float::from_int(klines.length()), max)
  }

  let rate_ratio = if avg_turn > 0.0 { last.turn / avg_turn } else { 0.0 }

  TurnoverRateStats::{
    daily_turnover_rate: last.turn,
    avg_turnover_rate: avg_turn,
    rate_ratio,
    max_turnover_rate: max_turn,
  }
}

///|
/// Price change statistics
pub struct PriceChangeStats {
  daily_change : Float
  daily_change_pct : Float
  avg_change : Float
  avg_change_pct : Float
  period_change : Float
  period_change_pct : Float
} derive(Show, ToJson)

///|
pub fn calculate_price_change_stats(
  klines : Array[KLine],
  period : Int,
) -> PriceChangeStats {
  if klines.length() == 0 {
    return PriceChangeStats::{
      daily_change: 0.0,
      daily_change_pct: 0.0,
      avg_change: 0.0,
      avg_change_pct: 0.0,
      period_change: 0.0,
      period_change_pct: 0.0,
    }
  }

  let len = klines.length()
  let last = klines[len - 1]

  let daily_change = if len >= 2 {
    last.close - klines[len - 2].close
  } else {
    0.0
  }
  let prev_close = if len >= 2 { klines[len - 2].close } else { last.close }
  let daily_change_pct = if prev_close > 0.0 {
    daily_change / prev_close * 100.0
  } else {
    0.0
  }

  let (avg_change, avg_change_pct) = if len >= 2 {
    let mut sum_change : Float = 0.0
    let mut sum_pct : Float = 0.0
    let mut count = 0
    let mut i = 1
    let start = if len - 1 >= period { len - period } else { 1 }
    while i < len {
      if i >= start {
        let change = klines[i].close - klines[i - 1].close
        let p = if klines[i - 1].close > 0.0 {
          change / klines[i - 1].close * 100.0
        } else {
          0.0
        }
        sum_change = sum_change + change
        sum_pct = sum_pct + p
        count = count + 1
      }
      i = i + 1
    }
    if count > 0 {
      (sum_change / Float::from_int(count), sum_pct / Float::from_int(count))
    } else {
      (0.0, 0.0)
    }
  } else {
    (0.0, 0.0)
  }

  let period_change = last.close - klines[0].close
  let period_start = klines[0].close
  let period_change_pct = if period_start > 0.0 {
    period_change / period_start * 100.0
  } else {
    0.0
  }

  PriceChangeStats::{
    daily_change,
    daily_change_pct,
    avg_change,
    avg_change_pct,
    period_change,
    period_change_pct,
  }
}

///|
/// Combined stock indicator summary
pub struct StockIndicatorSummary {
  code : String
  date : String
  price : PriceStats
  volume : VolumeStats
  turnover : TurnoverStats
  turnover_rate : TurnoverRateStats
  price_change : PriceChangeStats
} derive(Show, ToJson)

///|
pub fn calculate_stock_indicators(
  klines : Array[KLine],
  period : Int,
) -> StockIndicatorSummary {
  let code = if klines.length() > 0 { klines[0].code } else { "" }
  let date = if klines.length() > 0 {
    klines[klines.length() - 1].date
  } else {
    ""
  }

  StockIndicatorSummary::{
    code,
    date,
    price: calculate_price_stats(klines, period),
    volume: calculate_volume_stats(klines, period),
    turnover: calculate_turnover_stats(klines, period),
    turnover_rate: calculate_turnover_rate_stats(klines, period),
    price_change: calculate_price_change_stats(klines, period),
  }
}
