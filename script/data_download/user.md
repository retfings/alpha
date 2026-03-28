# 股票数据下载工具 - 用户说明书

## 目录

1. [简介](#简介)
2. [安装依赖](#安装依赖)
3. [快速开始](#快速开始)
4. [脚本说明](#脚本说明)
5. [使用示例](#使用示例)
6. [输出文件格式](#输出文件格式)
7. [常见问题](#常见问题)

---

## 简介

本工具集使用 [baostock](http://baostock.com/) API 下载 A 股股票历史行情数据，支持多种数据频率和复权类型。

### 功能特性

- **日线/周线/月线数据** - 支持不同频率的 K 线数据
- **分钟级数据** - 支持 5/15/30/60 分钟级别数据
- **复权处理** - 支持前复权、后复权、无复权
- **增量更新** - 只下载新增数据，节省时间
- **并行下载** - 多线程加速批量下载
- **数据验证** - 自动检测数据质量问题
- **财务指标** - 下载股票财务数据
- **行业分类** - 下载行业分类信息
- **Parquet 格式** - 支持转换为高效压缩格式

### 脚本文件结构

```
script/data_download/
├── baostock_client.py      # Baostock API 封装（类型安全）
├── download_data.py        # 基础下载脚本
├── enhanced_downloader.py  # 增强下载器（推荐）
├── convert_to_parquet.py   # CSV 转 Parquet 工具
├── validate_data.py        # 数据验证工具
├── requirements.txt        # Python 依赖
└── 用户说明书.md           # 本文件
```

---

## 安装依赖

### 步骤 1：安装 Python 依赖

```bash
cd script/data_download
pip install -r requirements.txt
```

或者单独安装：

```bash
pip install baostock
```

### 步骤 2（可选）：安装 Parquet 转换依赖

如需使用 Parquet 格式转换功能：

```bash
pip install pandas pyarrow
```

---

## 快速开始

### 最简单的用法

下载默认股票（浦发银行、平安银行）近 3 年的日线数据：

```bash
python download_data.py
```

### 使用增强下载器（推荐）

下载全部 A 股股票数据：

```bash
python enhanced_downloader.py --all
```

增量更新全部 A 股数据：

```bash
python enhanced_downloader.py --all --incremental
```

---

## 脚本说明

### 1. `download_data.py` - 基础下载脚本

适合简单下载需求。

#### 参数说明

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | `sh.600000 sz.000001` |
| `--all` | | 下载全部 A 股 | 不启用 |
| `--start` | | 开始日期 (YYYY-MM-DD) | 3 年前 |
| `--end` | | 结束日期 (YYYY-MM-DD) | 今天 |
| `--output` | `-o` | 输出目录 | `../data/` |
| `--frequency` | `-f` | 频率：d=日，w=周，m=月，5/15/30/60=分钟 | `d` |
| `--adjustflag` | `-a` | 复权：1=后复权，2=无复权，3=前复权 | `3` |
| `--quiet` | `-q` | 静默模式 | 不启用 |

### 2. `enhanced_downloader.py` - 增强下载器（推荐）

功能更全面，支持增量更新、数据验证、财务数据等。

#### 参数说明

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--stocks` | `-s` | 股票代码列表 | `sh.600000 sz.000001` |
| `--all` | | 下载全部 A 股 | 不启用 |
| `--incremental` | `-i` | 增量更新模式 | 不启用 |
| `--validate` | `-v` | 验证现有数据 | 不启用 |
| `--financials` | | 下载财务指标 | 不启用 |
| `--industries` | | 下载行业分类 | 不启用 |
| `--start` | | 开始日期 (YYYY-MM-DD) | 3 年前 |
| `--end` | | 结束日期 (YYYY-MM-DD) | 今天 |
| `--output` | `-o` | 输出目录 | `../data/` |
| `--frequency` | `-f` | 频率 | `d` |
| `--adjustflag` | `-a` | 复权类型 | `3` |
| `--workers` | `-w` | 并行线程数 | `4` |
| `--quiet` | `-q` | 静默模式 | 不启用 |

### 3. `convert_to_parquet.py` - Parquet 格式转换

将 CSV 文件转换为压缩的 Parquet 格式，节省空间并提高读取性能。

#### 参数说明

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `--all` | | 转换所有 CSV 文件 | 不启用 |
| `--stocks` | `-s` | 转换指定股票 | 全部 |
| `--input` | | 输入文件路径 | - |
| `--output` | `-o` | 输出目录 | 原目录 |
| `--compression` | `-c` | 压缩：snappy/gzip/zstd/none | `snappy` |
| `--remove-csv` | | 转换后删除 CSV | 保留 |
| `--quiet` | `-q` | 静默模式 | 不启用 |

### 4. `validate_data.py` - 数据验证工具

验证已下载数据的质量和完整性。

---

## 使用示例

### 基础下载

```bash
# 下载单只股票（浦发银行）
python download_data.py --stocks sh.600000

# 下载多只股票
python download_data.py --stocks sh.600000 sz.000001 sz.000002

# 下载全部 A 股（约 5000 只）
python download_data.py --all
```

### 指定日期范围

```bash
# 下载 2023 年全年数据
python download_data.py --stocks sh.600000 --start 2023-01-01 --end 2023-12-31

# 下载最近半年数据
python download_data.py --all --start 2025-09-01
```

### 不同频率数据

```bash
# 日线数据（默认）
python download_data.py --stocks sh.600000 -f d

# 周线数据
python download_data.py --stocks sh.600000 -f w

# 月线数据
python download_data.py --stocks sh.600000 -f m

# 5 分钟 K 线
python download_data.py --stocks sh.600000 -f 5

# 15 分钟 K 线
python download_data.py --stocks sh.600000 -f 15
```

### 复权类型设置

```bash
# 前复权（推荐，默认）
python download_data.py --stocks sh.600000 -a 3

# 后复权
python download_data.py --stocks sh.600000 -a 1

# 无复权
python download_data.py --stocks sh.600000 -a 2
```

### 使用增强下载器

```bash
# 全量下载全部 A 股
python enhanced_downloader.py --all

# 增量更新（仅下载新增数据）
python enhanced_downloader.py --all --incremental

# 下载全部 A 股的财务指标
python enhanced_downloader.py --financials --all

# 下载行业分类数据
python enhanced_downloader.py --industries

# 验证已下载数据
python enhanced_downloader.py --validate --all

# 使用 8 线程并行下载
python enhanced_downloader.py --all -w 8

# 静默模式（只输出结果摘要）
python enhanced_downloader.py --all -q
```

### 组合参数

```bash
# 下载全部 A 股 2023 年数据，使用周线、前复权、静默模式
python enhanced_downloader.py --all --start 2023-01-01 --end 2023-12-31 -f w -a 3 -q

# 下载指定股票到自定义目录
python download_data.py -s sh.600000 sz.000001 -o ./my_data/

# 下载 5 分钟数据并转换为 Parquet
python enhanced_downloader.py --all -f 5 -q
python convert_to_parquet.py --all --compression zstd
```

### Parquet 格式转换

```bash
# 转换所有 CSV 文件
python convert_to_parquet.py --all

# 转换指定股票
python convert_to_parquet.py --stocks sh.600000

# 使用 gzip 压缩
python convert_to_parquet.py --all --compression gzip

# 转换后删除原 CSV 文件
python convert_to_parquet.py --all --remove-csv

# 输出到独立目录
python convert_to_parquet.py --all --output ./parquet/
```

---

## 输出文件格式

### K 线数据文件

**目录**: `../data/`

**文件名格式**:
```
{股票代码}_{开始日期}_{结束日期}[ _qfq{复权标识}].csv
```

**示例**:
- `sh_600000_2023-01-01_2023-12-31.csv` (无复权)
- `sh_600000_2023-01-01_2023-12-31_qfq3.csv` (前复权)

**字段说明**:

| 字段 | 说明 |
|------|------|
| date | 日期 |
| time | 时间（分钟级数据包含） |
| open | 开盘价 |
| high | 最高价 |
| low | 最低价 |
| close | 收盘价 |
| volume | 成交量 |
| amount | 成交额 |
| turn | 换手率 |

### 财务指标数据

**目录**: `../data/financials/`

**文件名格式**:
```
{股票代码}_financials_{开始日期}_{结束日期}.csv
```

**主要字段**:

| 字段 | 说明 |
|------|------|
| pubDate | 发布日期 |
| statDate | 统计日期 |
| roEAvg/roeWaa | ROE（平均/加权） |
| netProfitOperatingIncomeRatio | 净利率 |
| grossProfitRatio | 毛利率 |
| debtToAssetRatio | 资产负债率 |
| currentRatio | 流动比率 |
| epsBasic | 基本每股收益 |
| dps | 每股股利 |
| totalOperatingIncome | 营业总收入 |
| netProfit | 净利润 |

### 行业分类数据

**目录**: `../data/industries/`

**文件名格式**:
```
industry_classification_{日期}.csv
```

**字段说明**:

| 字段 | 说明 |
|------|------|
| code | 股票代码 |
| codeName | 股票名称 |
| industryName | 行业名称 |
| industryType | 行业类型 |
| industryCode1/2/3 | 一/二/三级行业代码 |

### 元数据文件

**目录**: `../data/.metadata/`

增强下载器会为每只股票保存元数据（JSON 格式），记录最后更新时间、数据范围等信息。

---

## 股票代码格式

- **上交所股票**: `sh.xxxxxx` (如 `sh.600000` - 浦发银行)
- **深交所股票**: `sz.xxxxxx` (如 `sz.000001` - 平安银行)

### 常见股票代码示例

| 代码 | 名称 |
|------|------|
| sh.600000 | 浦发银行 |
| sh.600036 | 招商银行 |
| sh.600519 | 贵州茅台 |
| sh.601318 | 中国平安 |
| sz.000001 | 平安银行 |
| sz.000858 | 五粮液 |
| sz.300750 | 宁德时代 |

---

## 常见问题

### Q1: 登录失败怎么办？

确保网络连接正常，baostock 服务免费但需要登录。如持续失败，可稍后重试。

### Q2: 下载速度慢？

- 使用增强下载器的并行模式：`-w 8` 或更高
- 增量更新只下载新增数据：`--incremental`
- 静默模式减少输出：`-q`

### Q3: 分钟级数据不完整？

分钟级数据仅包含交易时段（工作日 9:30-11:30, 13:00-15:00），非交易时间无数据。

### Q4: 如何更新已有数据？

使用增强下载器的增量模式：
```bash
python enhanced_downloader.py --all --incremental
```

### Q5: 数据文件太大？

转换为 Parquet 格式可压缩 70-90%：
```bash
python convert_to_parquet.py --all --compression zstd
```

### Q6: 如何验证数据质量？

```bash
python enhanced_downloader.py --validate --all
```

---

## 注意事项

1. 数据由 baostock 免费提供，仅供参考，不保证准确性
2. 大量下载时请控制频率，避免对服务器造成压力
3. 建议定期使用增量更新保持数据最新
4. 财务数据按季度发布，可能存在更新延迟
5. 确保磁盘空间充足（全部 A 股日线数据约需数 GB）

---

## 技术支持

- Baostock 文档：http://baostock.com/
- 项目文档：参见 `docs/` 目录
