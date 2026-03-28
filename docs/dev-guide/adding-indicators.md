# 添加新指标指南

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [概述](#概述)
2. 指标开发步骤
3. [指标实现示例](#指标实现示例)
4. [测试指南](#测试指南)
5. [注册指标](#注册指标)
6. [最佳实践](#最佳实践)
7. [常见问题](#常见问题)

---

## 概述

本指南介绍如何在系统中添加新的技术指标。系统采用模块化设计，添加新指标只需遵循以下步骤。

### 指标分类

在开始之前，确定你的指标属于哪一类：

| 类别 | 说明 | 示例 |
|------|------|------|
| 趋势指标 | 跟踪价格趋势 | MA, EMA, MACD |
| 动量指标 | 衡量价格动量 | RSI, KDJ, Williams %R |
| 波动率指标 | 衡量价格波动 | ATR, Bollinger Bands |
| 成交量指标 | 分析成交量 | OBV, VWAP |

### 前置要求

- MoonBit 基础知识
- 了解技术指标原理
- 熟悉项目结构

---

## 指标开发步骤

### 步骤 1: 创建指标文件

在 `src/indicator/` 目录下创建新文件：

```
src/indicator/my_indicator.mbt
```

**文件命名规范**:
- 使用小写字母和下划线
- 名称应清晰描述指标功能
- 例如：`rsi.mbt`, `bollinger.mbt`, `my_custom.mbt`

### 步骤 2: 添加文件头注释

```mbt
/// 我的自定义指标
///
/// 简短描述指标用途和计算方法

use src/data/types
```

### 步骤 3: 定义结果结构 (如需要)

如果指标返回多个值，定义结构体：

```mbt
/// 指标结果结构
pub struct MyIndicatorResult {
  line1 : Array[Float]
  line2 : Array[Float]
  signal : Array[Float]
} derive(Show)
```

### 步骤 4: 实现主计算函数

```mbt
/// 计算我的指标
///
/// 详细描述：
/// - 计算方法
/// - 参数说明
/// - 返回值说明
///
/// 参数:
/// - prices: 收盘价数组
/// - period: 计算周期
///
/// 返回值:
/// - 指标值数组
///
/// 示例:
/// ```mbt check-disabled
/// let prices = [100.0, 102.0, 101.0, 103.0, 105.0]
/// let result = my_indicator(prices, 14)
/// ```
pub fn my_indicator(
  prices : Array[Float],
  period : Int,
) -> Array[Float] {
  // 参数验证
  if prices.length() < period || period <= 0 {
    return prices.map(fn(_) { Float::from_double(0.0) })
  }

  // 计算逻辑
  let result : Array[Float] = []

  // ... 实现计算 ...

  result
}
```

### 步骤 5: 实现辅助函数

添加常用的辅助函数：

```mbt
/// 检查是否超买
pub fn is_overbought(value : Float, threshold : Float) -> Bool {
  value > threshold
}

/// 检查是否超卖
pub fn is_oversold(value : Float, threshold : Float) -> Bool {
  value < threshold
}
```

### 步骤 6: 添加默认参数版本 (可选)

```mbt
/// 使用默认参数计算
pub fn my_indicator_default(prices : Array[Float]) -> Array[Float] {
  my_indicator(prices, 14)  // 默认周期 14
}
```

---

## 指标实现示例

### 示例 1: 简单移动平均 (SMA)

```mbt
/// 简单移动平均 (Simple Moving Average)
///
/// SMA 是最基础的趋势指标，计算 N 周期收盘价的平均值

///|
/// 计算 SMA
///
/// 参数:
/// - values: 价格数组
/// - period: 周期数
///
/// 返回值:
/// - SMA 值数组，前 (period-1) 个值为 0
pub fn sma(values : Array[Float], period : Int) -> Array[Float] {
  if values.length() < period || period <= 0 {
    return values.map(fn(_) { Float::from_double(0.0) })
  }

  let result : Array[Float] = []
  let len = values.length()

  // 使用滑动窗口优化计算
  let mut window_sum : Float = Float::from_double(0.0)
  let mut i = 0

  // 计算初始窗口和
  while i < period {
    window_sum = window_sum + values[i]
    i = i + 1
  }

  // 添加前导零
  i = 0
  while i < period - 1 {
    result.push(Float::from_double(0.0))
    i = i + 1
  }

  // 添加第一个 SMA 值
  result.push(window_sum / Float::from_int(period))

  // 滑动窗口计算后续值
  i = period
  while i < len {
    window_sum = window_sum + values[i] - values[i - period]
    result.push(window_sum / Float::from_int(period))
    i = i + 1
  }

  result
}
```

### 示例 2: 相对强弱指标 (RSI)

```mbt
/// 相对强弱指标 (Relative Strength Index)
///
/// RSI 是动量振荡指标，用于评估超买或超卖状况

///|
/// 计算 RSI
///
/// 公式:
/// RSI = 100 - (100 / (1 + RS))
/// RS = 平均涨幅 / 平均跌幅
///
/// 参数:
/// - prices: 收盘价数组
/// - period: 周期 (通常 14)
///
/// 返回值:
/// - RSI 值数组 (0-100 范围)
pub fn rsi(prices : Array[Float], period : Int) -> Array[Float] {
  if prices.length() <= period || period <= 0 {
    return prices.map(fn(_) { Float::from_double(0.0) })
  }

  let result : Array[Float] = []
  let len = prices.length()

  // 计算涨跌幅
  let gains : Array[Float] = []
  let losses : Array[Float] = []

  let mut i = 1
  while i < len {
    let change = prices[i] - prices[i - 1]
    if change > 0.0 {
      gains.push(change)
      losses.push(Float::from_double(0.0))
    } else {
      gains.push(Float::from_double(0.0))
      losses.push(-change)
    }
    i = i + 1
  }

  // 计算初始平均
  let mut avg_gain : Float = Float::from_double(0.0)
  let mut avg_loss : Float = Float::from_double(0.0)

  i = 0
  while i < period {
    if i < gains.length() {
      avg_gain = avg_gain + gains[i]
      avg_loss = avg_loss + losses[i]
    }
    i = i + 1
  }

  avg_gain = avg_gain / Float::from_int(period)
  avg_loss = avg_loss / Float::from_int(period)

  // 添加前导零
  i = 0
  while i < period {
    result.push(Float::from_double(0.0))
    i = i + 1
  }

  // 计算第一个 RSI
  let rsi_value = if avg_loss == Float::from_double(0.0) {
    Float::from_double(100.0)
  } else {
    let rs = avg_gain / avg_loss
    Float::from_double(100.0) -
    Float::from_double(100.0) / (Float::from_double(1.0) + rs)
  }
  result.push(rsi_value)

  // 计算后续 RSI (使用平滑平均)
  i = period
  while i < gains.length() {
    avg_gain = (avg_gain * Float::from_int(period - 1) + gains[i]) /
      Float::from_int(period)
    avg_loss = (avg_loss * Float::from_int(period - 1) + losses[i]) /
      Float::from_int(period)

    let rsi_val = if avg_loss == Float::from_double(0.0) {
      Float::from_double(100.0)
    } else {
      let rs = avg_gain / avg_loss
      Float::from_double(100.0) -
      Float::from_double(100.0) / (Float::from_double(1.0) + rs)
    }
    result.push(rsi_val)

    i = i + 1
  }

  result
}

///|
/// 检查 RSI 超买
pub fn is_overbought(rsi_value : Float, threshold : Float) -> Bool {
  rsi_value > threshold
}

///|
/// 检查 RSI 超卖
pub fn is_oversold(rsi_value : Float, threshold : Float) -> Bool {
  rsi_value < threshold
}
```

### 示例 3: 布林带 (多返回值)

```mbt
/// 布林带 (Bollinger Bands)
///
/// 波动率指标，由三条线组成

///|
/// 计算布林带
///
/// 参数:
/// - prices: 收盘价数组
/// - period: 周期 (通常 20)
/// - std_dev_multiplier: 标准差乘数 (通常 2.0)
///
/// 返回值:
/// - (上轨，中轨，下轨) 三元组
pub fn bollinger_bands(
  prices : Array[Float],
  period : Int,
  std_dev_multiplier : Float,
) -> (Array[Float], Array[Float], Array[Float]) {
  let zero = Float::from_double(0.0)
  let period_float = Float::from_int(period)

  if prices.length() < period || period <= 0 {
    let empty = prices.map(fn(_) { zero })
    return (empty, empty, empty)
  }

  let upper : Array[Float] = []
  let middle : Array[Float] = []
  let lower : Array[Float] = []
  let len = prices.length()

  let mut i = 0
  while i < len {
    if i < period - 1 {
      upper.push(zero)
      middle.push(zero)
      lower.push(zero)
    } else {
      // 计算 SMA
      let mut sum : Float = zero
      let mut j = i - period + 1
      while j <= i {
        sum = sum + prices[j]
        j = j + 1
      }
      let sma = sum / period_float
      middle.push(sma)

      // 计算标准差
      let mut sum_sq : Float = zero
      j = i - period + 1
      while j <= i {
        let diff = prices[j] - sma
        sum_sq = sum_sq + diff * diff
        j = j + 1
      }
      let std = Float::sqrt(sum_sq / period_float)
      let band_width = std_dev_multiplier * std

      upper.push(sma + band_width)
      lower.push(sma - band_width)
    }
    i = i + 1
  }

  (upper, middle, lower)
}

///|
/// 默认参数布林带
pub fn bollinger_bands_default(
  prices : Array[Float],
) -> (Array[Float], Array[Float], Array[Float]) {
  bollinger_bands(prices, 20, Float::from_double(2.0))
}
```

---

## 测试指南

### 创建测试文件

在 `src/indicator/` 目录创建测试文件：

```
src/indicator/my_indicator_test.mbt
```

### 编写单元测试

```mbt
/// 我的指标测试

use src/indicator/my_indicator
use src/test_util  // 假设有测试工具模块

/// 测试正常计算
@test fn test_my_indicator_normal {
  let prices = [100.0, 102.0, 101.0, 103.0, 105.0, 104.0, 106.0, 108.0, 110.0, 109.0]
  let result = my_indicator(prices, 3)

  // 验证结果长度
  assert_eq(result.length(), prices.length())

  // 验证前导零
  assert_eq(result[0], 0.0)
  assert_eq(result[1], 0.0)

  // 验证第一个有效值
  let expected_first = (100.0 + 102.0 + 101.0) / 3.0
  assert_float_eq(result[2], expected_first, 0.0001)
}

/// 测试数据不足情况
@test fn test_my_indicator_insufficient_data {
  let prices = [100.0, 102.0]
  let result = my_indicator(prices, 5)  // 周期大于数据长度

  // 应该返回全零数组
  assert_eq(result.length(), prices.length())
  assert_true(result.all(fn(x) { x == 0.0 }))
}

/// 测试周期为 0
@test fn test_my_indicator_zero_period {
  let prices = [100.0, 102.0, 101.0]
  let result = my_indicator(prices, 0)

  // 应该返回全零数组
  assert_true(result.all(fn(x) { x == 0.0 }))
}

/// 测试边界值
@test fn test_my_indicator_single_value {
  let prices = [100.0]
  let result = my_indicator(prices, 1)

  // 周期为 1 时，SMA 应等于价格本身
  assert_float_eq(result[0], 100.0, 0.0001)
}

/// 测试辅助函数
@test fn test_is_overbought {
  assert_true(is_overbought(75.0, 70.0))
  assert_false(is_overbought(65.0, 70.0))
  assert_false(is_overbought(70.0, 70.0))  // 等于阈值不算超买
}

@test fn test_is_oversold {
  assert_true(is_oversold(25.0, 30.0))
  assert_false(is_oversold(35.0, 30.0))
  assert_false(is_oversold(30.0, 30.0))  // 等于阈值不算超卖
}
```

### 运行测试

```bash
# 运行单个测试文件
moon test src/indicator/my_indicator_test.mbt

# 运行所有指标测试
moon test indicator

# 运行测试并显示详细输出
moon test indicator --verbose
```

### 测试覆盖率

```bash
# 生成覆盖率报告
moon test --coverage
```

---

## 注册指标

### 在指标注册表中注册

如果系统有指标注册表，添加新指标：

```mbt
/// src/indicator/registry.mbt

pub fn register_all_indicators(registry : &mut IndicatorRegistry) {
  // ... 现有注册 ...

  // 注册新指标
  registry.register("my_indicator", my_indicator)
  registry.register("my_indicator_default", my_indicator_default)
}
```

### 更新文档

1. **更新指标参考文档**:
   - 在 `docs/user-guide/indicator-reference.md` 添加新指标说明

2. **更新 API 文档**:
   - 在 `docs/dev-guide/api-reference.md` 添加 API 端点

3. **添加使用示例**:
   - 在策略示例中展示如何使用新指标

---

## 最佳实践

### 代码规范

1. **文档注释**:
   - 每个函数都有清晰的注释
   - 包含参数说明、返回值说明、使用示例

2. **参数验证**:
   ```mbt
   if prices.length() < period || period <= 0 {
     return prices.map(fn(_) { Float::from_double(0.0) })
   }
   ```

3. **性能优化**:
   - 使用滑动窗口避免重复计算
   - 避免不必要的数组拷贝

4. **错误处理**:
   - 对边界情况返回合理默认值
   - 不抛出异常，使用零值或空数组

### 测试规范

1. **覆盖边界情况**:
   - 数据不足
   - 周期为 0 或负数
   - 单元素数组

2. **验证数值精度**:
   ```mbt
   assert_float_eq(result[0], expected, 0.0001)
   ```

3. **测试辅助函数**:
   - 不要只测试主函数

### 命名规范

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 主函数 | 小写，下划线分隔 | `rsi`, `bollinger_bands` |
| 辅助函数 | 动词开头 | `is_overbought`, `calculate_signal` |
| 结构体 | 大写驼峰 | `MACDResult`, `BollingerPosition` |
| 测试函数 | `test_` 前缀 | `test_rsi_normal` |

---

## 常见问题

### Q1: 如何处理数据不足的情况？

**答**: 返回与输入等长的零值数组：

```mbt
if prices.length() < period {
  return prices.map(fn(_) { Float::from_double(0.0) })
}
```

### Q2: 如何选择前导零的数量？

**答**: 通常为 `period - 1`，因为需要 `period` 个数据点才能计算第一个值。

### Q3: 如何测试浮点数比较？

**答**: 使用容差比较：

```mbt
fn assert_float_eq(actual : Float, expected : Float, tolerance : Float) {
  assert_true(Float::abs(actual - expected) < tolerance)
}
```

### Q4: 指标计算太慢怎么办？

**优化建议**:
1. 使用滑动窗口而非重新计算
2. 避免重复计算相同值
3. 预分配数组容量

```mbt
// 优化前：O(n*p)
for i in range(len) {
  sum = 0
  for j in range(i-period, i) {
    sum += prices[j]
  }
}

// 优化后：O(n)
window_sum = sum(prices[0:period])
for i in range(period, len) {
  window_sum += prices[i] - prices[i-period]
}
```

### Q5: 如何处理除零错误？

**答**: 在除法前检查除数：

```mbt
let result = if divisor == 0.0 {
  Float::from_double(0.0)
} else {
  dividend / divisor
}
```

### Q6: 指标返回多个值怎么办？

**答**: 使用元组或结构体：

```mbt
// 元组方式
pub fn bollinger_bands(...) -> (Array[Float], Array[Float], Array[Float])

// 结构体方式
pub struct MACDResult {
  macd_line : Array[Float]
  signal_line : Array[Float]
  histogram : Array[Float]
}
```

---

## 检查清单

在提交新指标前，确保完成以下项目：

- [ ] 指标文件已创建并命名正确
- [ ] 有完整的文档注释
- [ ] 实现了参数验证
- [ ] 添加了辅助函数
- [ ] 创建了测试文件
- [ ] 测试覆盖边界情况
- [ ] 所有测试通过
- [ ] 在注册表中注册 (如需要)
- - 更新了指标参考文档
- [ ] 代码已格式化 (`moon fmt`)

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
