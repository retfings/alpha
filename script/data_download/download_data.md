# 股票数据下载脚本

使用 [baostock](http://baostock.com/) API 下载 A 股股票历史行情数据。

## 安装依赖

```bash
# 安装 Python 依赖
pip install -r script/requirements.txt
```

或者单独安装：

```bash
pip install baostock
```

## 模块结构

```
script/
├── baostock_client.py       # Baostock API 封装模块（类型安全）
├── download_data.py         # 主下载脚本（命令行入口）
├── enhanced_downloader.py   # 增强下载器（支持增量更新、验证、财务数据等）
└── requirements.txt         # Python 依赖
```

### `baostock_client.py` API

提供类型安全的 Baostock API 封装：

```python
from baostock_client import BaostockClient, get_default_date_range

# 使用上下文管理器（自动登录/登出）
with BaostockClient() as client:
    result = client.query_history_k_data(
        stock_code="sh.600000",
        start_date="2024-01-01",
        end_date="2024-12-31",
        frequency="d",
        adjust_flag="3"  # 前复权
    )

    if result.success:
        client.save_to_csv(result, "./data/sh_600000.csv")
```

### `enhanced_downloader.py` API

提供增强的数据下载功能：

```python
from enhanced_downloader import EnhancedBaostockDownloader, DownloadConfig

config = DownloadConfig(
    output_dir="./data",
    frequency="d",
    adjustflag="3",
    max_workers=4,
)

with EnhancedBaostockDownloader(config) as downloader:
    # 批量下载
    report = downloader.batch_download(["sh.600000", "sz.000001"])

    # 增量更新
    report = downloader.batch_download(["sh.600000"], incremental=True)

    # 下载财务指标
    report = downloader.download_all_financials(["sh.600000"])

    # 下载行业分类
    report = downloader.download_industry_classification()

    # 数据验证
    result = downloader.validate_stock("sh.600000")
```

## 基本用法

### 默认执行（下载近 3 年日线数据，前复权）

```bash
# 默认下载浦发银行 (sh.600000) 和平安银行 (sz.000001) 近 3 年的日线数据（前复权）
python script/download_data.py
```

### 使用增强下载器

```bash
# 使用增强下载器下载全部 A 股
python script/enhanced_downloader.py --all

# 增量更新全部 A 股数据
python script/enhanced_downloader.py --all --incremental

# 下载全部 A 股的财务指标
python script/enhanced_downloader.py --financials --all

# 下载行业分类数据
python script/enhanced_downloader.py --industries

# 验证全部 A 股数据质量
python script/enhanced_downloader.py --validate --all

# 下载指定股票的财务指标
python script/enhanced_downloader.py --financials -s sh.600000 sz.000001

# 使用 5 分钟级别数据下载全部 A 股（静默模式）
python script/enhanced_downloader.py --all -f 5 -q
```

### 下载全部 A 股

```bash
# 下载全部 A 股股票近 3 年的日线数据（前复权）
python script/download_data.py --all

# 下载全部 A 股股票，指定日期范围
python script/download_data.py --all --start 2023-01-01 --end 2023-12-31

# 下载全部 A 股股票，指定输出目录和复权类型
python script/download_data.py --all -o ./my_data/ -a 1

# 下载全部 A 股股票，使用 5 分钟级别数据
python script/download_data.py --all -f 5 -q
```

> `--all` 可以结合 `--start`, `--end`, `-o`, `-f`, `-a`, `-q` 等参数使用。

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

### `download_data.py` 参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | `sh.600000 sz.000001` |
| `--all` | | 下载全部 A 股股票（可与 `--start`, `--end`, `-o`, `-f`, `-a`, `-q` 组合使用） | 不启用 |
| `--start` | | 开始日期 (YYYY-MM-DD) | 3 年前 |
| `--end` | | 结束日期 (YYYY-MM-DD) | 今天 |
| `--output` | `-o` | 输出目录 | `./data/` |
| `--frequency` | `-f` | 频率：d=日，w=周，m=月，5/15/30/60=分钟 | `d` |
| `--adjustflag` | `-a` | 复权类型：1=后复权，2=无复权，3=前复权 | `3` |
| `--quiet` | `-q` | 静默模式，不输出进度 | 不启用 |

### `enhanced_downloader.py` 参数

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | `sh.600000 sz.000001` |
| `--all` | | 下载全部 A 股股票 | 不启用 |
| `--incremental` | `-i` | 使用增量更新模式 | 不启用 |
| `--validate` | `-v` | 验证现有数据质量 | 不启用 |
| `--financials` | | 下载财务指标数据 | 不启用 |
| `--industries` | | 下载行业分类数据 | 不启用 |
| `--start` | | 开始日期 (YYYY-MM-DD) | 3 年前 |
| `--end` | | 结束日期 (YYYY-MM-DD) | 今天 |
| `--output` | `-o` | 输出目录 | `./data/` |
| `--frequency` | `-f` | 频率：d=日，w=周，m=月，5/15/30/60=分钟 | `d` |
| `--adjustflag` | `-a` | 复权类型：1=后复权，2=无复权，3=前复权 | `3` |
| `--workers` | `-w` | 并行下载工作线程数 | `4` |
| `--quiet` | `-q` | 静默模式 | 不启用 |

## 示例

### 下载全部 A 股，指定日期范围

```bash
# 下载全部 A 股 2023 年的数据
python script/download_data.py --all --start 2023-01-01 --end 2023-12-31
```

### 下载全部 A 股，指定复权类型

```bash
# 下载全部 A 股，使用后复权
python script/download_data.py --all -a 1

# 下载全部 A 股，使用无复权
python script/download_data.py --all -a 2
```

### 下载全部 A 股，使用不同频率

```bash
# 下载全部 A 股的周线数据
python script/download_data.py --all -f w

# 下载全部 A 股的 5 分钟级别数据（静默模式）
python script/download_data.py --all -f 5 -q
```

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

### K-line 数据文件格式

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

### 财务指标数据文件格式

输出目录：`data/financials/`

文件名格式：
```
{股票代码}_financials_{开始日期}_{结束日期}.csv
```

例如：
- `sh_600000_financials_2020-01-01_2024-12-31.csv`

CSV 包含以下字段（部分）：
- `pubDate`: 发布日期
- `statDate`: 统计日期
- `roEAvg`: 平均 ROE
- `roeWaa`: 加权 ROE
- `roaAvg`: 平均 ROA
- `netProfitOperatingIncomeRatio`: 净利率
- `grossProfitRatio`: 毛利率
- `totalAssetTurnoverRatio`: 总资产周转率
- `debtToAssetRatio`: 资产负债率
- `currentRatio`: 流动比率
- `quickRatio`: 速动比率
- `epsBasic`: 基本每股收益
- `dps`: 每股股利
- `totalOperatingIncome`: 营业总收入
- `netProfit`: 净利润
- `totalAsset`: 总资产
- `totalLiability`: 总负债

### 行业分类数据文件格式

输出目录：`data/industries/`

文件名格式：
```
industry_classification_{日期}.csv
```

例如：
- `industry_classification_20240327.csv`

CSV 包含以下字段：
- `code`: 股票代码
- `codeName`: 股票名称
- `industryName`: 行业名称
- `industryType`: 行业类型
- `industryCode1/2/3`: 行业分类代码（一级/二级/三级）

### 元数据文件格式

增强下载器会在 `data/.metadata/` 目录下保存元数据文件：

文件名格式：
```
{股票代码安全格式}.meta.json
```

例如：
- `sh_600000.meta.json`

元数据包含：
- `code`: 股票代码
- `last_update`: 最后更新时间（ISO 格式）
- `last_date`: 数据中最后交易日
- `record_count`: 记录数
- `file_path`: 数据文件路径

## 注意事项

1. 首次运行会自动下载历史数据，可能需要等待
2. 数据由 baostock 免费提供，仅供参考
3. 确保网络连接正常
4. 大量下载时请注意控制请求频率
5. 5 分钟级别数据仅支持交易日内数据，非交易时间无数据
6. 前复权数据更适合技术分析和回测（默认使用前复权）
7. `--all` 选项使用 BaoStock 官方 API 获取全部 A 股，无需手动扫描代码段
