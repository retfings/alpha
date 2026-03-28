# 数据格式说明文档

**最后更新**: 2026-03-27

本文档说明量化回撤框架使用的数据格式，包括 CSV 文件格式、KLine 数据结构、频率枚举和存储目录结构。

---

## 目录

- [CSV 文件格式说明](#csv-文件格式说明)
- [KLine 数据结构](#kline-数据结构)
- [Frequency 枚举说明](#frequency-枚举说明)
- [存储目录结构](#存储目录结构)

---

## CSV 文件格式说明

### 文件命名规范

CSV 文件采用以下命名格式:

```
{exchange}_{code}_{start_date}_{end_date}[{adjust_suffix}].csv
```

**字段说明**:
| 字段 | 说明 | 示例 |
|------|------|------|
| `exchange` | 交易所代码 | `sh`, `sz` |
| `code` | 股票代码 | `600000`, `000001` |
| `start_date` | 开始日期 | `2024-01-01` |
| `end_date` | 结束日期 | `2024-12-31` |
| `adjust_suffix` | 复权后缀 (可选) | `_qfq3` (前复权) |

**文件名示例**:
- `sh_600000_2024-01-01_2024-12-31.csv` - 浦发银行 2024 年日线数据 (无复权)
- `sz_000001_2024-01-01_2024-12-31_qfq3.csv` - 平安银行 2024 年日线数据 (前复权)
- `sh_600000_2024-01-01_2024-01-31_5min.csv` - 浦发银行 5 分钟线数据

---

### CSV 文件结构

#### 日线数据格式

```csv
date,open,high,low,close,volume,amount,turn
2024-01-02,10.50,11.20,10.30,10.80,1000000,10800000,0.05
2024-01-03,10.80,11.50,10.60,11.00,1200000,13200000,0.06
2024-01-04,11.00,11.30,10.80,10.90,900000,9810000,0.045
```

#### 分钟线数据格式

```csv
date,time,open,high,low,close,volume,amount,turn
2024-01-02,09:30,10.50,10.55,10.48,10.52,50000,526000,0.0025
2024-01-02,09:35,10.52,10.58,10.50,10.55,45000,474750,0.00225
```

---

### 字段说明

| 字段名 | 数据类型 | 说明 | 取值范围 |
|--------|----------|------|----------|
| `date` | string | 交易日期 | YYYY-MM-DD |
| `time` | string | 交易时间 (分钟线) | HH:MM |
| `open` | float | 开盘价 | > 0 |
| `high` | float | 最高价 | >= open, low |
| `low` | float | 最低价 | <= open, high |
| `close` | float | 收盘价 | > 0 |
| `volume` | float | 成交量 (股/手) | >= 0 |
| `amount` | float | 成交额 (元) | >= 0 |
| `turn` | float | 换手率 (%) | 0.0 - 1.0 |

---

### 数据质量要求

1. **日期连续性**: 数据应按交易日顺序排列，跳过周末和节假日
2. **价格合理性**: OHLC 应满足 `high >= low` 且 `high >= open, close` 且 `low <= open, close`
3. **非空值**: 所有数值字段不应为空
4. **无重复**: 同一日期/时间不应有重复记录

---

## KLine 数据结构

### MoonBit 类型定义

```moonbit
pub struct KLine {
  code : StockCode      // 股票代码 (e.g., "sh.600000")
  date : String         // 日期 (格式："YYYY-MM-DD")
  time : String?        // 时间 (分钟线需要，日线为 None)
  open : Float          // 开盘价
  high : Float          // 最高价
  low : Float           // 最低价
  close : Float         // 收盘价
  volume : Float        // 成交量
  amount : Float        // 成交额
  turn : Float          // 换手率
} derive(Eq, ToJson, Show)
```

### 字段详细说明

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `code` | StockCode | 股票代码，格式 "交易所.代码" | `"sh.600000"` |
| `date` | String | 交易日期 | `"2024-01-02"` |
| `time` | String? | 时间戳 (仅分钟线) | `Some("09:30")` |
| `open` | Float | 开盘价格 | `10.50` |
| `high` | Float | 期间最高价 | `11.20` |
| `low` | Float | 期间最低价 | `10.30` |
| `close` | Float | 收盘价格 | `10.80` |
| `volume` | Float | 成交数量 | `1000000.0` |
| `amount` | Float | 成交金额 (元) | `10800000.0` |
| `turn` | Float | 换手率 (小数) | `0.05` (5%) |

---

### 构造方法

#### 日线 K 线构造

```moonbit
pub fn KLine::daily(
  code : StockCode,
  date : String,
  open : Float,
  high : Float,
  low : Float,
  close : Float,
  volume : Float,
  amount : Float,
  turn : Float,
) -> KLine
```

**示例**:
```moonbit
let kline = KLine::daily(
  "sh.600000",
  "2024-01-02",
  10.5,
  11.2,
  10.3,
  10.8,
  1000000.0,
  10800000.0,
  0.05,
)
```

#### 完整构造 (支持分钟线)

```moonbit
pub fn KLine::create(
  code : StockCode,
  date : String,
  open : Float,
  high : Float,
  low : Float,
  close : Float,
  volume : Float,
  amount : Float,
  turn : Float,
  time? : String,
) -> KLine
```

**示例**:
```moonbit
// 日线 (time 为 None)
let daily_kline = KLine::create(
  "sh.600000", "2024-01-02",
  10.5, 11.2, 10.3, 10.8,
  1000000.0, 10800000.0, 0.05,
)

// 5 分钟线
let minute_kline = KLine::create(
  "sh.600000", "2024-01-02",
  10.50, 10.55, 10.48, 10.52,
  50000.0, 526000.0, 0.0025,
  time = Some("09:30"),
)
```

---

### 辅助类型

#### StockCode (股票代码)

```moonbit
pub type StockCode = String
```

格式：`"sh.600000"`, `"sz.000001"`

#### TimeSeries (时间序列)

```moonbit
pub type TimeSeries[T] = Array[(Int64, T)]
```

用于将时间戳与任意类型值配对。

---

## Frequency 枚举说明

### 定义

```moonbit
pub enum Frequency {
  Daily       // 日线
  Weekly      // 周线
  Monthly     // 月线
  Minute5     // 5 分钟线
  Minute15    // 15 分钟线
  Minute30    // 30 分钟线
  Minute60    // 60 分钟线
} derive(Eq, Show)
```

---

### 频率对照表

| 枚举值 | Baostock 代码 | 数据粒度 | 适用场景 |
|--------|---------------|----------|----------|
| `Daily` | `d` | 每日 1 条 | 中长线策略、趋势分析 |
| `Weekly` | `w` | 每周 1 条 | 长期趋势、宏观分析 |
| `Monthly` | `m` | 每月 1 条 | 宏观经济周期分析 |
| `Minute5` | `5` | 5 分钟 1 条 | 短线交易、高频策略 |
| `Minute15` | `15` | 15 分钟 1 条 | 日内交易策略 |
| `Minute30` | `30` | 30 分钟 1 条 | 短线趋势分析 |
| `Minute60` | `60` | 60 分钟 1 条 | 小时级别趋势 |

---

### 使用示例

```moonbit
// 在策略中指定频率
let frequency = Frequency::Daily

// 在数据加载时使用
match load_klines(code, start_date, Frequency::Minute5) {
  Some(klines) => ...
  None => ...
}

// 频率判断
fn is_intraday(freq : Frequency) -> Bool {
  match freq {
    Frequency::Minute5 => true
    Frequency::Minute15 => true
    Frequency::Minute30 => true
    Frequency::Minute60 => true
    _ => false
  }
}
```

---

## 存储目录结构

### 标准目录结构

```
alpha/
└── data/
    ├── daily/              # 日线数据
    │   ├── sh_600000_2024-01-01_2024-12-31.csv
    │   ├── sz_000001_2024-01-01_2024-12-31.csv
    │   └── ...
    ├── minute/             # 分钟线数据
    │   ├── 5min/
    │   │   ├── sh_600000_2024-01-01_2024-01-31.csv
    │   │   └── ...
    │   ├── 15min/
    │   │   └── ...
    │   └── ...
    └── adjusted/           # 复权数据 (可选)
        ├── qfq/            # 前复权
        │   └── ...
        └── hfq/            # 后复权
            └── ...
```

---

### 简化目录结构 (当前使用)

```
alpha/
└── data/
    ├── sh_600000_2024-01-01_2024-12-31.csv
    ├── sz_000001_2024-01-01_2024-12-31.csv
    ├── sh_600000_2024-01-01_2024-01-31_5min.csv
    └── ...
```

---

### 目录创建脚本

使用项目提供的下载脚本会自动创建目录:

```bash
# 下载到默认目录
python script/download_data.py --stocks sh.600000

# 指定输出目录
python script/download_data.py -o ./data/daily --stocks sh.600000
```

---

### 文件路径解析

```moonbit
// 从文件名提取股票代码
pub fn extract_stock_code_from_filename(String) -> String?

// 示例
extract_stock_code_from_filename("sh_600000_2024.csv")
  // Returns: Some("sh.600000")

extract_stock_code_from_filename("/data/sz_000001_2024.csv")
  // Returns: Some("sz.000001")
```

---

## 数据加载示例

### MoonBit 加载 CSV

```moonbit
use src/data/loader

// 从 CSV 文件加载
match loader.load_klines_from_csv("data/sh_600000_2024.csv") {
  Ok(klines) => {
    io::println("Loaded " + String::from_int(klines.length()) + " bars")
    // 处理 K 线数据
  }
  Err(e) => {
    io::println("Error: " + e)
  }
}
```

### Python 加载 CSV

```python
import csv
from datetime import datetime

def load_klines_from_csv(filepath):
    klines = []
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            kline = {
                'code': '',
                'date': row['date'],
                'open': float(row['open']),
                'high': float(row['high']),
                'low': float(row['low']),
                'close': float(row['close']),
                'volume': float(row['volume']),
                'amount': float(row['amount']),
                'turn': float(row['turn']),
            }
            klines.append(kline)
    return klines
```

---

## 数据验证

### CSV 格式验证

```python
def validate_csv(filepath):
    required_fields = ['date', 'open', 'high', 'low', 'close', 'volume', 'amount', 'turn']

    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)

        # 检查表头
        for field in required_fields:
            if field not in reader.fieldnames:
                return False, f"Missing field: {field}"

        # 检查数据
        for i, row in enumerate(reader, 1):
            # 日期格式验证
            try:
                datetime.strptime(row['date'], '%Y-%m-%d')
            except ValueError:
                return False, f"Invalid date at row {i}"

            # 价格合理性验证
            if not (float(row['high']) >= float(row['low'])):
                return False, f"high < low at row {i}"

    return True, "Valid"
```

---

## 参考资料

- [Baostock API 文档](http://www.baostock.com)
- [CSV 格式规范](https://tools.ietf.org/html/rfc4180)
