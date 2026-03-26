# 股票数据下载脚本

使用 [baostock](http://baostock.com/) API 下载 A 股股票历史行情数据。

## 安装依赖

```bash
pip install baostock
```

## 基本用法

### 下载单只股票

```bash
# 下载浦发银行 (sh.600000) 过去一年的数据
python script/download_data.py --stocks sh.600000
```

### 下载多只股票

```bash
# 同时下载多只股票
python script/download_data.py --stocks sh.600000 sh.600036 sz.000001 sz.000002
```

## 命令行参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | `sh.600000 sz.000001` |
| `--start` | | 开始日期 (YYYY-MM-DD) | 一年前 |
| `--end` | | 结束日期 (YYYY-MM-DD) | 今天 |
| `--output` | `-o` | 输出目录 | `./data/` |
| `--frequency` | `-f` | 频率：d=日，w=周，m=月 | `d` |

## 示例

### 下载指定日期范围的数据

```bash
# 下载 2023 年的数据
python script/download_data.py --stocks sh.600000 --start 2023-01-01 --end 2023-12-31
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
{股票代码}_{开始日期}_{结束日期}.csv
```

例如：`sh_600000_2023-01-01_2023-12-31.csv`

CSV 包含以下字段：
- `date`: 日期
- `time`: 时间
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
