# 股票数据下载脚本

使用 [baostock](http://baostock.com/) API 下载 A 股股票历史行情数据。

## 安装依赖

```bash
pip install baostock
```

## 基本用法

### 默认执行（下载近 3 年日线数据，前复权）

```bash
# 默认下载浦发银行 (sh.600000) 和平安银行 (sz.000001) 近 3 年的日线数据（前复权）
python script/download_data.py
```

### 下载单只股票

```bash
# 下载浦发银行 (sh.600000) 的数据
python script/download_data.py --stocks sh.600000
```

### 下载多只股票

```bash
# 同时下载多只股票
python script/download_data.py --stocks sh.600000 sh.600036 sz.000001 sz.000002
```

### 下载 5 分钟级别数据（前复权）

```bash
# 下载 5 分钟 K 线数据（前复权）
python script/download_data.py --stocks sh.600000 --frequency 5
```

## 命令行参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | `sh.600000 sz.000001` |
| `--all` | | 下载全部 A 股股票 | 不启用 |
| `--start` | | 开始日期 (YYYY-MM-DD) | 3 年前 |
| `--end` | | 结束日期 (YYYY-MM-DD) | 今天 |
| `--output` | `-o` | 输出目录 | `./data/` |
| `--frequency` | `-f` | 频率：d=日，w=周，m=月，5/15/30/60=分钟 | `d` |
| `--adjustflag` | `-a` | 复权类型：1=后复权，2=无复权，3=前复权 | `3` |
| `--quiet` | `-q` | 静默模式，不输出进度 | 不启用 |

## 示例

### 下载指定日期范围的数据

```bash
# 下载 2023 年的数据
python script/download_data.py --stocks sh.600000 --start 2023-01-01 --end 2023-12-31
```

### 下载 5 分钟级别数据

```bash
# 下载 5 分钟 K 线数据（前复权）
python script/download_data.py --stocks sh.600000 --frequency 5

# 下载 15 分钟 K 线数据
python script/download_data.py --stocks sh.600000 --frequency 15

# 下载 30 分钟 K 线数据
python script/download_data.py --stocks sh.600000 --frequency 30

# 下载 60 分钟 K 线数据
python script/download_data.py --stocks sh.600000 --frequency 60
```

### 下载周线数据

```bash
# 下载周 K 线数据
python script/download_data.py --stocks sh.600000 --frequency w
```

### 下载月线数据

```bash
# 下载月 K 线数据
python script/download_data.py --stocks sh.600000 --frequency m
```

### 调整复权类型

```bash
# 后复权数据
python script/download_data.py --stocks sh.600000 --adjustflag 1

# 无复权数据
python script/download_data.py --stocks sh.600000 --adjustflag 2

# 前复权数据（默认）
python script/download_data.py --stocks sh.600000 --adjustflag 3
```

### 指定输出目录

```bash
# 保存到自定义目录
python script/download_data.py --stocks sh.600000 --output ./my_data/
```

## 股票代码格式

- 上交所股票：`sh.xxxxxx` (如 `sh.600000`)
- 深交所股票：`sz.xxxxxx` (如 `sz.000001`)

## 输出文件格式

脚本会在输出目录下生成 CSV 文件，文件名格式：
```
{股票代码}_{开始日期}_{结束日期}[ _qfq{复权标识}].csv
```

例如：
- `sh_600000_2023-01-01_2023-12-31.csv` (无复权)
- `sh_600000_2023-01-01_2023-12-31_qfq3.csv` (前复权)

CSV 包含以下字段：
- `date`: 日期
- `time`: 时间（分钟级别数据包含）
- `open`: 开盘价
- `high`: 最高价
- `low`: 最低价
- `close`: 收盘价
- `volume`: 成交量
- `amount`: 成交额
- `turn`: 换手率

## 注意事项

1. 首次运行会自动下载历史数据，可能需要等待
2. 数据由 baostock 免费提供，仅供参考
3. 确保网络连接正常
4. 大量下载时请注意控制请求频率
5. 5 分钟级别数据仅支持交易日内数据，非交易时间无数据
6. 前复权数据更适合技术分析和回测（默认使用前复权）
