# Baostock API 使用文档

**最后更新**: 2026-03-27

本文档介绍如何使用 Baostock API 下载 A 股股票数据，供量化回撤框架使用。

---

## 目录

- [安装说明](#安装说明)
- [API 函数参考](#api-函数参考)
- [支持的数据类型和字段](#支持的数据类型和字段)
- [使用示例](#使用示例)

---

## 安装说明

### 1. 安装 Python 环境

确保已安装 Python 3.8 或更高版本:

```bash
python3 --version
```

### 2. 安装 Baostock 库

使用 pip 安装:

```bash
pip install baostock
```

或使用项目提供的 `requirements.txt`:

```bash
cd script
pip install -r requirements.txt
```

### 3. 验证安装

```python
import baostock as bs
print(bs.__version__)
```

---

## API 函数参考

### 登录/登出

#### `bs.login()`

登录 Baostock 系统。

**返回值**:
- `Login` 对象，包含 `error_code` 和 `error_msg`

**示例**:
```python
lg = bs.login()
if lg.error_code != "0":
    print(f"Login failed: {lg.error_msg}")
else:
    print("Login successful")
```

#### `bs.logout()`

登出 Baostock 系统，释放连接资源。

**示例**:
```python
bs.logout()
```

---

### 股票列表查询

#### `bs.query_stock_basic()`

查询 A 股股票基本信息。

**参数**: 无

**返回字段**:
- `code` - 股票代码
- `code_name` - 股票名称
- `ipoDate` - 上市日期
- `type` - 股票类型 (1=股票，2=指数)

**示例**:
```python
rs = bs.query_stock_basic()
stocks = []
while rs.next():
    stocks.append(rs.get_row_data())
```

---

### K 线数据查询

#### `bs.query_history_k_data_plus()`

查询历史 K 线数据 (核心函数)。

**参数**:
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `code` | str | 是 | 股票代码，如 "sh.600000" |
| `fields` | str | 是 | 字段列表，逗号分隔 |
| `start_date` | str | 是 | 开始日期，格式 "YYYY-MM-DD" |
| `end_date` | str | 是 | 结束日期，格式 "YYYY-MM-DD" |
| `frequency` | str | 否 | 数据频率，默认 "d" |
| `adjustflag` | str | 否 | 复权类型，默认 "2" |

**frequency 参数**:
- `d` - 日线
- `w` - 周线
- `m` - 月线
- `5` - 5 分钟线
- `15` - 15 分钟线
- `30` - 30 分钟线
- `60` - 60 分钟线

**adjustflag 参数**:
- `1` - 后复权
- `2` - 无复权 (默认)
- `3` - 前复权

**返回字段说明**:
```python
fields = "date,time,open,high,low,close,volume,amount,turn"
```

**示例**:
```python
rs = bs.query_history_k_data_plus(
    code="sh.600000",
    fields="date,open,high,low,close,volume,amount,turn",
    start_date="2024-01-01",
    end_date="2024-12-31",
    frequency="d",
    adjustflag="3"  # 前复权
)
```

---

### 数据读取

#### `rs.next()`

移动到下一行数据。

**返回值**:
- `True` - 还有数据
- `False` - 已到最后

#### `rs.get_row_data()`

获取当前行数据。

**返回值**:
- `list[str]` - 当前行所有字段值

#### `rs.fields`

获取字段名列表。

**返回值**:
- `list[str]` - 字段名列表

---

## 支持的数据类型和字段

### 日线数据字段

| 字段名 | 说明 | 类型 | 示例 |
|--------|------|------|------|
| `date` | 日期 | str | "2024-01-02" |
| `open` | 开盘价 | float | 10.50 |
| `high` | 最高价 | float | 11.20 |
| `low` | 最低价 | float | 10.30 |
| `close` | 收盘价 | float | 10.80 |
| `volume` | 成交量 | float | 1000000 |
| `amount` | 成交额 | float | 10800000 |
| `turn` | 换手率 | float | 0.05 |
| `turnoverRatio` | 换手率 (另一种计算) | float | 0.052 |
| `adjustedFactor` | 复权因子 | float | 1.25 |

### 分钟线数据字段

| 字段名 | 说明 | 类型 |
|--------|------|------|
| `date` | 日期 | str |
| `time` | 时间 | str |
| `open` | 开盘价 | float |
| `high` | 最高价 | float |
| `low` | 最低价 | float |
| `close` | 收盘价 | float |
| `volume` | 成交量 | float |
| `amount` | 成交额 | float |
| `turn` | 换手率 | float |

### 频率对照表

| 频率代码 | 频率名称 | 适用场景 |
|----------|----------|----------|
| `d` | 日线 | 中长线策略 |
| `w` | 周线 | 长期趋势分析 |
| `m` | 月线 | 宏观趋势分析 |
| `5` | 5 分钟线 | 短线交易策略 |
| `15` | 15 分钟线 | 日内交易策略 |
| `30` | 30 分钟线 | 日内交易策略 |
| `60` | 60 分钟线 | 短线趋势分析 |

---

## 使用示例

### 示例 1: 下载单只股票日线数据

```python
import baostock as bs

# 登录
lg = bs.login()
if lg.error_code != "0":
    print(f"登录失败：{lg.error_msg}")
    exit(1)

# 查询数据
rs = bs.query_history_k_data_plus(
    code="sh.600000",
    fields="date,open,high,low,close,volume,amount,turn",
    start_date="2024-01-01",
    end_date="2024-12-31",
    frequency="d",
    adjustflag="3"  # 前复权
)

# 读取数据
data_list = []
while rs.next():
    data_list.append(rs.get_row_data())

print(f"共获取 {len(data_list)} 条数据")

# 登出
bs.logout()
```

### 示例 2: 保存数据到 CSV

```python
import csv
import baostock as bs

bs.login()

rs = bs.query_history_k_data_plus(
    code="sz.000001",
    fields="date,open,high,low,close,volume,amount,turn",
    start_date="2024-01-01",
    end_date="2024-12-31",
    frequency="d"
)

with open("sz_000001_2024.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(rs.fields)  # 写入表头
    while rs.next():
        writer.writerow(rs.get_row_data())

bs.logout()
```

### 示例 3: 批量下载多只股票

```python
import baostock as bs
import csv
import os

stock_codes = ["sh.600000", "sz.000001", "sh.600030"]
start_date = "2024-01-01"
end_date = "2024-12-31"
output_dir = "../data"

os.makedirs(output_dir, exist_ok=True)

lg = bs.login()
if lg.error_code != "0":
    print(f"登录失败：{lg.error_msg}")
    exit(1)

for code in stock_codes:
    print(f"正在下载 {code}...")

    rs = bs.query_history_k_data_plus(
        code=code,
        fields="date,open,high,low,close,volume,amount,turn",
        start_date=start_date,
        end_date=end_date,
        frequency="d",
        adjustflag="3"
    )

    # 文件名格式：exchange_code_start_end.csv
    filename = f"{code.replace('.', '_')}_{start_date}_{end_date}.csv"
    filepath = os.path.join(output_dir, filename)

    with open(filepath, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(rs.fields)
        while rs.next():
            writer.writerow(rs.get_row_data())

    print(f"  已保存至：{filepath}")

bs.logout()
print("批量下载完成")
```

### 示例 4: 下载 5 分钟线数据

```python
import baostock as bs
import csv

bs.login()

# 5 分钟线需要 time 字段
rs = bs.query_history_k_data_plus(
    code="sh.600000",
    fields="date,time,open,high,low,close,volume,amount,turn",
    start_date="2024-01-01",
    end_date="2024-01-31",
    frequency="5",  # 5 分钟线
    adjustflag="3"
)

with open("sh_600000_5min.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(rs.fields)
    while rs.next():
        writer.writerow(rs.get_row_data())

bs.logout()
```

---

## 项目集成脚本

项目提供了封装好的下载脚本 `script/download_data.py`:

### 基本用法

```bash
# 下载默认股票 (sh.600000, sz.000001)
python script/download_data.py

# 下载指定股票
python script/download_data.py --stocks sh.600000 sz.000001

# 下载全部 A 股股票
python script/download_data.py --all

# 指定日期范围
python script/download_data.py --start 2024-01-01 --end 2024-12-31

# 指定输出目录
python script/download_data.py -o ./data

# 使用 5 分钟线
python script/download_data.py -f 5

# 使用后复权
python script/download_data.py -a 1
```

### 命令行参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | sh.600000, sz.000001 |
| `--all` | - | 下载全部 A 股 | false |
| `--start` | - | 开始日期 | 3 年前 |
| `--end` | - | 结束日期 | 今天 |
| `--output` | `-o` | 输出目录 | ../data |
| `--frequency` | `-f` | 数据频率 | d |
| `--adjustflag` | `-a` | 复权类型 | 3 (前复权) |
| `--quiet` | `-q` | 静默模式 | false |

---

## 常见问题

### Q: 登录失败怎么办？

A: 检查网络连接，Baostock 需要访问其服务器。如果网络问题，可考虑使用离线数据源。

### Q: 数据字段为空怎么办？

A: 可能原因:
- 股票代码错误
- 日期范围超出上市日期
- 该股票在查询日期停牌

### Q: 分钟线数据不完整？

A: 分钟线数据仅在交易时段产生，非交易时间和休市日没有数据。

---

## 参考资料

- [Baostock 官方文档](http://www.baostock.com)
- [Baostock GitHub](https://github.com/baostock/baostock)
