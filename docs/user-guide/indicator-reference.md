# 技术指标参考手册

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [趋势指标](#趋势指标)
2. [动量指标](#动量指标)
3. [波动率指标](#波动率指标)
4. [成交量指标](#成交量指标)
5. [指标使用指南](#指标使用指南)

---

## 趋势指标

### 移动平均线 (MA)

移动平均线是最基础的趋势跟踪指标，用于平滑价格数据并识别趋势方向。

#### 简单移动平均 (SMA)

**计算公式**:
```
SMA = (P1 + P2 + ... + Pn) / n
```

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `period` | Int | 20 | 计算周期 |

**返回值**: Array[Float] - SMA 值数组

**MoonBit 使用示例**:
```mbt
let prices = [100.0, 102.0, 101.0, 103.0, 105.0]
let sma_values = sma(prices, 10)  // 10 周期 SMA
```

**策略应用**:
- 价格在 SMA 之上：上升趋势
- 价格在 SMA 之下：下降趋势
- 双均线交叉：金叉 (买入) / 死叉 (卖出)

#### 指数移动平均 (EMA)

**计算公式**:
```
EMA = (P_current - EMA_prev) * multiplier + EMA_prev
Multiplier = 2 / (period + 1)
```

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `period` | Int | 20 | 计算周期 |

**返回值**: Array[Float] - EMA 值数组

**MoonBit 使用示例**:
```mbt
let prices = [100.0, 102.0, 101.0, 103.0, 105.0]
let ema_values = ema(prices, 12)  // 12 周期 EMA
```

**特点**:
- 对近期价格赋予更高权重
- 比 SMA 反应更快
- 适合短期交易

---

## 动量指标

### MACD (Moving Average Convergence Divergence)

**版本**: 1.0 | **类别**: 趋势跟踪动量指标

#### 概述

MACD 是趋势跟踪动量指标，显示证券价格两个移动平均线之间的关系。由三部分组成：
- **MACD 线**: 快 EMA - 慢 EMA
- **信号线**: MACD 线的 EMA
- **柱状图**: MACD 线 - 信号线

#### 计算结果结构

```mbt
pub struct MACDResult {
  macd_line   : Array[Float]  // MACD 线
  signal_line : Array[Float]  // 信号线
  histogram   : Array[Float]  // 柱状图
}
```

#### 函数参考

##### `macd()` - 计算 MACD

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `prices` | Array[Float] | - | 收盘价数组 |
| `fast_period` | Int | 12 | 快 EMA 周期 |
| `slow_period` | Int | 26 | 慢 EMA 周期 |
| `signal_period` | Int | 9 | 信号线 EMA 周期 |

**返回值**: `MACDResult` 结构体

**MoonBit 使用示例**:
```mbt
let prices = get_stock_prices("sh.600000")
let result = macd(prices, 12, 26, 9)

// 访问各组件
inspect(result.macd_line)     // MACD 线
inspect(result.signal_line)   // 信号线
inspect(result.histogram)     // 柱状图
```

##### `macd_standard()` - 标准参数 MACD

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `prices` | Array[Float] | 收盘价数组 |

**返回值**: `MACDResult` 结构体

**说明**: 使用标准参数 (12, 26, 9) 计算 MACD

**MoonBit 使用示例**:
```mbt
let prices = get_stock_prices("sh.600000")
let result = macd_standard(prices)
```

##### `bullish_crossover()` - 金叉检测

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `result` | MACDResult | MACD 计算结果 |
| `index` | Int | 检测位置索引 |

**返回值**: `Bool` - true 表示发生金叉

**MoonBit 使用示例**:
```mbt
let result = macd(prices, 12, 26, 9)
let current_idx = result.macd_line.length() - 1

if bullish_crossover(result, current_idx) {
  println("买入信号：MACD 金叉")
}
```

##### `bearish_crossover()` - 死叉检测

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `result` | MACDResult | MACD 计算结果 |
| `index` | Int | 检测位置索引 |

**返回值**: `Bool` - true 表示发生死叉

**MoonBit 使用示例**:
```mbt
if bearish_crossover(result, current_idx) {
  println("卖出信号：MACD 死叉")
}
```

##### `histogram_increasing()` - 柱状图增长检测

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `result` | MACDResult | MACD 计算结果 |
| `index` | Int | 检测位置索引 |

**返回值**: `Bool` - true 表示动能增强

**MoonBit 使用示例**:
```mbt
if histogram_increasing(result, current_idx) {
  println("动能正在增强")
}
```

##### `histogram_decreasing()` - 柱状图减少检测

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `result` | MACDResult | MACD 计算结果 |
| `index` | Int | 检测位置索引 |

**返回值**: `Bool` - true 表示动能减弱

#### 交易信号解释

| 信号类型 | 条件 | 说明 |
|----------|------|------|
| 金叉 (买入) | MACD 线上穿信号线 | 看涨信号 |
| 死叉 (卖出) | MACD 线下穿信号线 | 看跌信号 |
| 顶背离 | 价格创新高，MACD 未创新高 | 潜在反转信号 |
| 底背离 | 价格创新低，MACD 未创新低 | 潜在反转信号 |
| 零轴上方 | MACD > 0 | 上升趋势 |
| 零轴下方 | MACD < 0 | 下降趋势 |

---

### RSI (Relative Strength Index)

**版本**: 1.0 | **类别**: 动量振荡指标

#### 概述

RSI 是动量振荡指标，用于衡量价格变动的速度和幅度，评估超买或超卖状况。

**计算公式**:
```
RSI = 100 - (100 / (1 + RS))
RS = 平均涨幅 / 平均跌幅
```

#### 函数参考

##### `rsi()` - 计算 RSI

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `prices` | Array[Float] | - | 收盘价数组 |
| `period` | Int | 14 | 计算周期 |

**返回值**: Array[Float] - RSI 值数组

**MoonBit 使用示例**:
```mbt
let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0]
let rsi_values = rsi(prices, 14)

// 获取当前 RSI 值
let current_rsi = rsi_values[rsi_values.length() - 1]
```

##### `is_overbought()` - 超买检测

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `rsi_value` | Float | - | 当前 RSI 值 |
| `threshold` | Float | 70.0 | 超买阈值 |

**返回值**: `Bool` - true 表示超买

**MoonBit 使用示例**:
```mbt
if is_overbought(current_rsi, 70.0) {
  println("超买状态，考虑卖出")
}
```

##### `is_oversold()` - 超卖检测

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `rsi_value` | Float | - | 当前 RSI 值 |
| `threshold` | Float | 30.0 | 超卖阈值 |

**返回值**: `Bool` - true 表示超卖

**MoonBit 使用示例**:
```mbt
if is_oversold(current_rsi, 30.0) {
  println("超卖状态，考虑买入")
}
```

#### 交易信号解释

| RSI 范围 | 状态 | 说明 |
|----------|------|------|
| RSI > 70 | 超买 | 可能回调，考虑卖出 |
| RSI < 30 | 超卖 | 可能反弹，考虑买入 |
| RSI = 50 | 中性 | 无明确方向 |
| RSI 顶背离 | 看跌 | 价格新高，RSI 未新高 |
| RSI 底背离 | 看涨 | 价格新低，RSI 未新低 |

---

### KDJ (随机指标)

**版本**: 1.0 | **类别**: 动量振荡指标

#### 概述

KDJ 是随机振荡指标，用于衡量收盘价在价格区间中的相对位置。

#### 函数参考

##### `kdj()` - 计算 KDJ

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `highs` | Array[Float] | - | 最高价数组 |
| `lows` | Array[Float] | - | 最低价数组 |
| `closes` | Array[Float] | - | 收盘价数组 |
| `n_period` | Int | 9 | RSV 计算周期 |
| `k_period` | Int | 3 | K 值 EMA 周期 |
| `d_period` | Int | 3 | D 值 EMA 周期 |

**返回值**: `(Array[Float], Array[Float], Array[Float])` - (K, D, J) 三元组

**MoonBit 使用示例**:
```mbt
let highs = [105.0, 107.0, 106.0, 108.0, 110.0]
let lows = [100.0, 102.0, 101.0, 103.0, 105.0]
let closes = [103.0, 105.0, 104.0, 106.0, 108.0]

let (k_values, d_values, j_values) = kdj(highs, lows, closes, 9, 3, 3)
```

#### 交易信号解释

| 信号类型 | 条件 | 说明 |
|----------|------|------|
| K 线上穿 D 线 | K > D 且之前 K < D | 金叉，买入信号 |
| K 线下穿 D 线 | K < D 且之前 K > D | 死叉，卖出信号 |
| KDJ > 80 | 超买区 | 可能回调 |
| KDJ < 20 | 超卖区 | 可能反弹 |

---

## 波动率指标

### Bollinger Bands (布林带)

**版本**: 1.0 | **类别**: 波动率指标

#### 概述

布林带由三条线组成，用于衡量价格波动性和相对价格水平。

**组成部分**:
- **中轨**: N 周期简单移动平均 (SMA)
- **上轨**: 中轨 + K × 标准差
- **下轨**: 中轨 - K × 标准差

#### 函数参考

##### `bollinger_bands()` - 计算布林带

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `prices` | Array[Float] | - | 收盘价数组 |
| `period` | Int | 20 | SMA 周期 |
| `std_dev_multiplier` | Float | 2.0 | 标准差乘数 |

**返回值**: `(Array[Float], Array[Float], Array[Float])` - (上轨，中轨，下轨)

**MoonBit 使用示例**:
```mbt
let prices = [100.0, 102.0, 101.0, 103.0, 105.0]
let (upper, middle, lower) = bollinger_bands(prices, 20, 2.0)
```

##### `bollinger_bands_default()` - 默认参数布林带

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `prices` | Array[Float] | 收盘价数组 |

**返回值**: `(Array[Float], Array[Float], Array[Float])`

**说明**: 使用标准参数 (period=20, std_dev_multiplier=2.0)

**MoonBit 使用示例**:
```mbt
let (upper, middle, lower) = bollinger_bands_default(prices)
```

##### `bollinger_percent_b()` - %B 指标

**概述**: %B 显示当前价格在布林带中的相对位置。

**计算公式**:
```
%B = (价格 - 下轨) / (上轨 - 下轨)
```

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `price` | Float | 当前价格 |
| `upper` | Float | 上轨值 |
| `lower` | Float | 下轨值 |

**返回值**: `Float` - %B 值

**MoonBit 使用示例**:
```mbt
let percent_b = bollinger_percent_b(105.0, 110.0, 100.0)
// 返回 0.5 (价格在中轨位置)
```

##### `bollinger_band_width()` - 带宽指标

**概述**: 带宽衡量上下轨之间的距离，用于识别波动率压缩。

**计算公式**:
```
Bandwidth = (上轨 - 下轨) / 中轨
```

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `upper` | Float | 上轨值 |
| `lower` | Float | 下轨值 |
| `middle` | Float | 中轨值 |

**返回值**: `Float` - 带宽值 (归一化)

**MoonBit 使用示例**:
```mbt
let width = bollinger_band_width(110.0, 90.0, 100.0)
// 返回 0.2 (20% 带宽)
```

##### `is_bollinger_squeeze()` - 挤压检测

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `upper` | Float | - | 上轨值 |
| `lower` | Float | - | 下轨值 |
| `middle` | Float | - | 中轨值 |
| `threshold` | Float | 0.1 | 挤压阈值 |

**返回值**: `Bool` - true 表示挤压状态

**MoonBit 使用示例**:
```mbt
if is_bollinger_squeeze(102.0, 98.0, 100.0, 0.1) {
  println("布林带挤压，关注突破")
}
```

##### `is_above_upper_band()` - 上轨上方检测

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `price` | Float | 当前价格 |
| `upper` | Float | 上轨值 |

**返回值**: `Bool` - true 表示价格在上轨上方

**MoonBit 使用示例**:
```mbt
if is_above_upper_band(current_price, upper_band) {
  println("价格突破上轨")
}
```

##### `is_below_lower_band()` - 下轨下方检测

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `price` | Float | 当前价格 |
| `lower` | Float | 下轨值 |

**返回值**: `Bool` - true 表示价格在下轨下方

**MoonBit 使用示例**:
```mbt
if is_below_lower_band(current_price, lower_band) {
  println("价格跌破下轨")
}
```

##### `bollinger_position()` - 价格相对位置

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `price` | Float | 当前价格 |
| `upper` | Float | 上轨值 |
| `middle` | Float | 中轨值 |
| `lower` | Float | 下轨值 |

**返回值**: `BollingerPosition` 枚举

**枚举值**:
```mbt
pub enum BollingerPosition {
  AboveUpper    // 价格在上轨上方 (可能超买)
  AboveMiddle   // 价格在中轨和上轨之间
  BelowMiddle   // 价格在中轨和下轨之间
  BelowLower    // 价格在下轨下方 (可能超卖)
}
```

**MoonBit 使用示例**:
```mbt
let position = bollinger_position(price, upper, middle, lower)
match position {
  BollingerPosition::AboveUpper => println("超买区域")
  BollingerPosition::BelowLower => println("超卖区域")
  _ => println("中性区域")
}
```

#### 交易信号解释

| 信号类型 | 条件 | 说明 |
|----------|------|------|
| 挤压突破 | 带宽收窄后价格突破 | 趋势启动信号 |
| 触及上轨 | 价格 >= 上轨 | 可能超买 |
| 触及下轨 | 价格 <= 下轨 | 可能超卖 |
| 中轨支撑 | 价格回踩中轨反弹 | 上升趋势延续 |
| 中轨阻力 | 价格反弹至中轨回落 | 下降趋势延续 |

---

### ATR (Average True Range)

**版本**: 1.0 | **类别**: 波动率指标

#### 概述

ATR 是衡量市场波动性的指标，显示特定时期内的平均价格波动幅度。

#### 函数参考

##### `atr()` - 计算 ATR

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `highs` | Array[Float] | - | 最高价数组 |
| `lows` | Array[Float] | - | 最低价数组 |
| `closes` | Array[Float] | - | 收盘价数组 |
| `period` | Int | 14 | ATR 周期 |

**返回值**: Array[Float] - ATR 值数组

**MoonBit 使用示例**:
```mbt
let highs = [105.0, 107.0, 106.0, 108.0, 110.0]
let lows = [100.0, 102.0, 101.0, 103.0, 105.0]
let closes = [103.0, 105.0, 104.0, 106.0, 108.0]

let atr_values = atr(highs, lows, closes, 14)
```

#### 应用场景

- **止损设置**: 止损距离 = N × ATR
- **头寸规模**: 根据 ATR 调整仓位大小
- **波动性分析**: ATR 上升表示波动加剧

---

## 成交量指标

### OBV (On-Balance Volume)

**版本**: 1.0 | **类别**: 成交量指标

#### 概述

OBV 是将成交量与价格变动相结合的技术指标，用于判断资金流向。

#### 函数参考

##### `obv()` - 计算 OBV

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `closes` | Array[Float] | 收盘价数组 |
| `volumes` | Array[Float] | 成交量数组 |

**返回值**: Array[Float] - OBV 值数组

**MoonBit 使用示例**:
```mbt
let closes = [100.0, 102.0, 101.0, 103.0, 105.0]
let volumes = [1000000.0, 1200000.0, 900000.0, 1100000.0, 1300000.0]

let obv_values = obv(closes, volumes)
```

#### 交易信号解释

| 信号类型 | 条件 | 说明 |
|----------|------|------|
| OBV 上升 | 价格上涨 + OBV 上升 | 确认上升趋势 |
| OBV 下降 | 价格下跌 + OBV 下降 | 确认下降趋势 |
| 顶背离 | 价格新高，OBV 未新高 | 潜在反转信号 |
| 底背离 | 价格新低，OBV 未新低 | 潜在反转信号 |

---

### VWAP (Volume Weighted Average Price)

**版本**: 1.0 | **类别**: 成交量加权指标

#### 概述

VWAP 是成交量加权平均价格，显示特定时期内的平均成交价格。

#### 函数参考

##### `vwap()` - 计算 VWAP

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `highs` | Array[Float] | 最高价数组 |
| `lows` | Array[Float] | 最低价数组 |
| `closes` | Array[Float] | 收盘价数组 |
| `volumes` | Array[Float] | 成交量数组 |

**返回值**: Array[Float] - VWAP 值数组

**MoonBit 使用示例**:
```mbt
let highs = [105.0, 107.0, 106.0, 108.0, 110.0]
let lows = [100.0, 102.0, 101.0, 103.0, 105.0]
let closes = [103.0, 105.0, 104.0, 106.0, 108.0]
let volumes = [1000000.0, 1200000.0, 900000.0, 1100000.0, 1300000.0]

let vwap_values = vwap(highs, lows, closes, volumes)
```

#### 交易应用

- **机构基准**: 机构交易的执行基准
- **趋势确认**: 价格在 VWAP 上方 = 看涨
- **支撑阻力**: VWAP 可作为动态支撑/阻力位

---

## 其他指标

### CCI (Commodity Channel Index)

**版本**: 1.0 | **类别**: 动量振荡指标

#### 函数参考

##### `cci()` - 计算 CCI

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `highs` | Array[Float] | - | 最高价数组 |
| `lows` | Array[Float] | - | 最低价数组 |
| `closes` | Array[Float] | - | 收盘价数组 |
| `period` | Int | 20 | CCI 周期 |

**返回值**: Array[Float] - CCI 值数组

**MoonBit 使用示例**:
```mbt
let cci_values = cci(highs, lows, closes, 20)
```

#### 交易信号解释

| CCI 范围 | 状态 | 说明 |
|----------|------|------|
| CCI > 100 | 超买 | 可能回调 |
| CCI < -100 | 超卖 | 可能反弹 |
| CCI > 200 | 严重超买 | 强烈回调信号 |
| CCI < -200 | 严重超卖 | 强烈反弹信号 |

---

### Williams %R (威廉指标)

**版本**: 1.0 | **类别**: 动量振荡指标

#### 函数参考

##### `williams_r()` - 计算 Williams %R

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `highs` | Array[Float] | - | 最高价数组 |
| `lows` | Array[Float] | - | 最低价数组 |
| `closes` | Array[Float] | - | 收盘价数组 |
| `period` | Int | 14 | 计算周期 |

**返回值**: Array[Float] - Williams %R 值数组 (范围 -100 到 0)

**MoonBit 使用示例**:
```mbt
let wr_values = williams_r(highs, lows, closes, 14)
```

#### 交易信号解释

| Williams %R 范围 | 状态 | 说明 |
|------------------|------|------|
| %R > -20 | 超买 | 可能回调 |
| %R < -80 | 超卖 | 可能反弹 |

---

### ADX (Average Directional Index)

**版本**: 1.0 | **类别**: 趋势强度指标

#### 函数参考

##### `adx()` - 计算 ADX

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `highs` | Array[Float] | - | 最高价数组 |
| `lows` | Array[Float] | - | 最低价数组 |
| `closes` | Array[Float] | - | 收盘价数组 |
| `period` | Int | 14 | ADX 周期 |

**返回值**: `(Array[Float], Array[Float], Array[Float], Array[Float])` - (ADX, +DI, -DI, TR) 四元组

**MoonBit 使用示例**:
```mbt
let (adx_values, plus_di, minus_di, tr_values) = adx(highs, lows, closes, 14)
```

#### 交易信号解释

| ADX 范围 | 趋势强度 | 说明 |
|----------|----------|------|
| ADX < 25 | 弱趋势 | 震荡市场 |
| ADX > 25 | 强趋势 | 趋势市场 |
| ADX > 50 | 非常强 | 强烈趋势 |
| +DI 上穿 -DI | 看涨交叉 | 买入信号 |
| -DI 上穿 +DI | 看跌交叉 | 卖出信号 |

---

### Aroon (阿隆指标)

**版本**: 1.0 | **类别**: 趋势指标

#### 函数参考

##### `aroon()` - 计算 Aroon

**参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `highs` | Array[Float] | - | 最高价数组 |
| `lows` | Array[Float] | - | 最低价数组 |
| `period` | Int | 25 | Aroon 周期 |

**返回值**: `(Array[Float], Array[Float])` - (Aroon Up, Aroon Down) 二元组

**MoonBit 使用示例**:
```mbt
let (aroon_up, aroon_down) = aroon(highs, lows, 25)
```

#### 交易信号解释

| 信号类型 | 条件 | 说明 |
|----------|------|------|
| Aroon Up > 70 | 强上升 | 上升趋势 |
| Aroon Down > 70 | 强下降 | 下降趋势 |
| Up 上穿 Down | 看涨交叉 | 买入信号 |
| Down 上穿 Up | 看跌交叉 | 卖出信号 |
| 两者都 < 30 | 盘整 | 无趋势 |

---

## 指标使用指南

### 指标选择建议

| 市场状态 | 推荐指标 | 说明 |
|----------|----------|------|
| 趋势市场 | MA, MACD, ADX | 趋势跟踪指标 |
| 震荡市场 | RSI, KDJ, Williams %R | 振荡指标 |
| 高波动 | ATR, Bollinger Bands | 波动率指标 |
| 成交量确认 | OBV, VWAP | 成交量指标 |

### 指标组合策略

#### 1. 趋势 + 动量组合

```mbt
// MACD + RSI 组合策略
let macd_result = macd(prices, 12, 26, 9)
let rsi_values = rsi(prices, 14)

if bullish_crossover(macd_result, current_idx) &&
   !is_overbought(rsi_values[current_idx], 70.0) {
  // MACD 金叉且 RSI 未超买，买入信号
  execute_buy()
}
```

#### 2. 波动率突破策略

```mbt
let (upper, middle, lower) = bollinger_bands(prices, 20, 2.0)
let atr_values = atr(highs, lows, closes, 14)

if is_bollinger_squeeze(upper[current], middle[current], lower[current], 0.1) {
  // 布林带挤压，准备突破
  if prices[current] > upper[current] {
    // 向上突破
    execute_buy()
  }
}
```

#### 3. 多指标确认策略

```mbt
// 三指标确认买入信号
let macd_ok = bullish_crossover(macd_result, current_idx)
let rsi_ok = !is_overbought(rsi_values[current_idx], 70.0)
let volume_ok = obv_increasing(obv_values, current_idx)

if macd_ok && rsi_ok && volume_ok {
  // 三个条件都满足
  execute_buy()
}
```

### 指标参数调优建议

| 指标 | 短期交易 | 中期交易 | 长期交易 |
|------|----------|----------|----------|
| SMA/EMA | 5-10 | 20-50 | 100-200 |
| RSI | 7-10 | 14 | 21-30 |
| MACD | 6,13,5 | 12,26,9 | 24,52,18 |
| Bollinger | 10,1.5 | 20,2.0 | 50,2.5 |
| ATR | 7-10 | 14 | 21-30 |

### 常见指标使用错误

1. **过度拟合**: 在历史数据上过度优化参数
2. **指标冗余**: 使用多个高度相关的指标
3. **忽视趋势**: 在强趋势中使用振荡指标
4. **延迟确认**: 等待过多指标确认，错过最佳入场点
5. **参数不变**: 在不同市场条件下使用固定参数

### 最佳实践

1. **理解指标原理**: 了解每个指标的计算方法和适用场景
2. **指标多样化**: 组合使用不同类型的指标
3. **适应市场**: 根据市场状态调整指标选择
4. **回测验证**: 在实际使用前进行充分回测
5. **风险管理**: 指标信号应与风险管理结合

---

## 附录

### A. 指标分类速查

| 类别 | 指标 | 主要用途 |
|------|------|----------|
| 趋势 | MA, EMA, MACD, ADX, Aroon | 识别和跟踪趋势 |
| 动量 | RSI, KDJ, Williams %R, CCI | 识别超买超卖 |
| 波动率 | ATR, Bollinger Bands | 衡量价格波动 |
| 成交量 | OBV, VWAP | 确认价格趋势 |

### B. 常用参数组合

| 策略类型 | 指标配置 |
|----------|----------|
| 日内交易 | SMA(5,10) + RSI(7) + ATR(7) |
| 波段交易 | EMA(10,20) + MACD(12,26,9) + RSI(14) |
| 趋势跟踪 | SMA(20,50) + ADX(14) + Aroon(25) |
| 均值回归 | Bollinger(20,2) + RSI(14) |

### C. 指标计算公式汇总

完整公式请参考各指标的详细说明。

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
