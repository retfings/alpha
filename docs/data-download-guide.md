# 股票数据下载指南

本文档详细介绍如何使用 Baostock API 下载和管理 A 股股票数据。

## 目录

- [概述](#概述)
- [安装与配置](#安装与配置)
- [数据下载工具](#数据下载工具)
- [使用示例](#使用示例)
- [数据格式说明](#数据格式说明)
- [数据验证与质量管理](#数据验证与质量管理)
- [增量更新机制](#增量更新机制)
- [常见问题](#常见问题)

## 概述

本项目使用 [Baostock](http://baostock.com/) 作为主要数据源，提供以下类型的数据下载：

| 数据类型 | 说明 | 输出目录 |
|---------|------|---------|
| K-line 行情数据 | 日线、周线、月线、分钟级别 | `data/` |
| 财务指标数据 | 盈利能力、偿债能力、运营能力等指标 | `data/financials/` |
| 行业分类数据 | 证监会行业分类、股票所属板块 | `data/industries/` |

### 数据下载工具对比

| 工具 | 适用场景 | 特性 |
|------|---------|------|
| `download_data.py` | 简单快速下载 | 基础 K-line 数据下载 |
| `enhanced_downloader.py` | 生产环境使用 | 增量更新、数据验证、并行下载、财务数据、行业数据 |

## 安装与配置

### 1. 安装 Python 依赖

```bash
cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha
pip install -r script/requirements.txt
```

或者直接安装：

```bash
pip install baostock
```

### 2. 验证安装

```bash
python -c "import baostock as bs; print(bs.__version__)"
```

### 3. 目录结构

```
script/
├── baostock_client.py       # Baostock API 封装（类型安全）
├── download_data.py         # 基础下载脚本
├── enhanced_downloader.py   # 增强下载器（推荐）
├── requirements.txt         # Python 依赖
└── download_data.md         # 快速参考文档

data/
├── .metadata/               # 下载元数据（自动生成）
├── financials/              # 财务指标数据（自动生成）
├── industries/              # 行业分类数据（自动生成）
└── *.csv                    # K-line 数据文件
```

## 数据下载工具

### 基础下载脚本 `download_data.py`

适合快速下载少量股票的 K-line 数据。

```bash
# 下载单只股票
python script/download_data.py --stocks sh.600000

# 下载多只股票
python script/download_data.py --stocks sh.600000 sz.000001 sz.000002

# 下载全部 A 股（日线，前复权，近 3 年）
python script/download_data.py --all

# 指定日期范围
python script/download_data.py --all --start 2023-01-01 --end 2023-12-31

# 使用不同复权类型
python script/download_data.py --all -a 1  # 后复权
python script/download_data.py --all -a 2  # 无复权
python script/download_data.py --all -a 3  # 前复权（默认）

# 使用不同频率
python script/download_data.py --all -f w  # 周线
python script/download_data.py --all -f m  # 月线
python script/download_data.py --all -f 5  # 5 分钟线
```

### 增强下载器 `enhanced_downloader.py`（推荐）

生产环境推荐使用增强下载器，支持更多功能。

```bash
# 基础下载
python script/enhanced_downloader.py --all

# 增量更新（仅下载新数据）
python script/enhanced_downloader.py --all --incremental

# 下载财务指标
python script/enhanced_downloader.py --financials --all

# 下载行业分类
python script/enhanced_downloader.py --industries

# 数据验证
python script/enhanced_downloader.py --validate --all

# 组合使用
python script/enhanced_downloader.py --all --incremental --financials
```

## 使用示例

### 示例 1：首次全量下载

```bash
# 下载全部 A 股近 3 年的日线数据（前复权）
python script/enhanced_downloader.py --all -w 4
```

输出示例：
```
Fetching all A-share stock codes...
Found 4823 stocks.
Processing 4823 stocks...
  [OK] sh.600000: Downloaded 732 records
  [OK] sh.600001: Downloaded 730 records
  ...

==================================================
DOWNLOAD SUMMARY
==================================================
  Total stocks:      4823
  Successful:        4820
  Failed:            3
  Total records:     3521456
  Incremental:       0
  Duration:          0:15:32
==================================================
```

### 示例 2：每日增量更新

```bash
# 增量更新全部 A 股数据
python script/enhanced_downloader.py --all --incremental
```

增量更新模式会：
1. 读取 `data/.metadata/` 中的元数据
2. 获取每只股票最后交易日
3. 仅下载该日期之后的新数据
4. 合并到现有文件中
5. 更新元数据

### 示例 3：下载财务指标

```bash
# 下载全部 A 股的财务指标（默认 10 年）
python script/enhanced_downloader.py --financials --all

# 下载指定股票的财务指标
python script/enhanced_downloader.py --financials -s sh.600000 sz.000001
```

财务指标包括：
- 盈利能力：ROE、ROA、毛利率、净利率
- 偿债能力：资产负债率、流动比率、速动比率
- 运营能力：总资产周转率、应收账款周转率、存货周转率
- 成长能力：营收增长率、净利润增长率
- 每股收益：EPS、DPS

### 示例 4：下载行业分类

```bash
# 下载全部 A 股的行业分类数据
python script/enhanced_downloader.py --industries
```

输出文件：`data/industries/industry_classification_YYYYMMDD.csv`

行业分类数据包含：
- 股票代码和名称
- 所属行业名称
- 行业分类代码（一级/二级/三级）

### 示例 5：数据验证

```bash
# 验证全部 A 股数据质量
python script/enhanced_downloader.py --validate --all
```

验证项目：
- 价格范围检查（负值、极端值）
- 日期连续性检查（大间隔检测）
- 价格连续性检查（异常跳变）

输出示例：
```
Validation complete: 4820 valid, 3 invalid
  [INVALID] sh.600000: Row 45: Negative close value: -12.34
  [INVALID] sz.000001: Large gap detected: 2023-05-01 to 2023-06-15 (45 days)
```

## 数据格式说明

### K-line 数据 CSV 格式

```csv
date,open,high,low,close,volume,amount,turn
2024-01-02,10.25,10.50,10.20,10.45,123456,128765.43,0.0234
2024-01-03,10.45,10.60,10.40,10.55,134567,141234.56,0.0256
```

### 财务指标数据 CSV 格式（部分字段）

```csv
pubDate,statDate,roEAvg,roeWaa,roaAvg,netProfitOperatingIncomeRatio,grossProfitRatio,debtToAssetRatio,epsBasic,totalOperatingIncome,netProfit
2024-03-15,2023-12-31,0.1234,0.1156,0.0567,0.1234,0.2345,0.5678,1.23,12345678901,2345678901
```

### 行业分类数据 CSV 格式

```csv
code,codeName,industryName,industryType,industryCode1,industryCode2,industryCode3
sh.600000,浦发银行,货币金融服务,S,06,066,0666
sz.000001,平安银行,货币金融服务,S,06,066,0666
```

### 元数据 JSON 格式

```json
{
  "code": "sh.600000",
  "last_update": "2024-03-27T10:30:00",
  "last_date": "2024-03-26",
  "record_count": 732,
  "file_path": "/path/to/data/sh_600000_2021-01-01_2024-03-26_qfq3.csv"
}
```

## 数据验证与质量管理

增强下载器内置数据验证功能，确保下载数据的质量：

### 验证项目

1. **价格范围验证**
   - 检查负价格
   - 检查极端价格（>1000）
   - 检查无效数值

2. **日期序列验证**
   - 检查日期格式
   - 检查大间隔（日线>10 天，周线>40 天）

3. **价格连续性验证**
   - 检查异常跳变（>50%）

### 验证结果处理

```bash
# 验证并查看问题详情
python script/enhanced_downloader.py --validate --all
```

对于验证失败的股票，建议：
1. 重新下载该股票数据
2. 检查 Baostock 数据源
3. 手动修复或标记

## 增量更新机制

### 工作原理

1. **首次下载**：全量下载历史数据，保存元数据
2. **增量更新**：
   - 读取元数据中的 `last_date`
   - 计算新开始日期 = `last_date + 1 天`
   - 仅下载新开始日期至今的数据
   - 合并到原文件
   - 更新元数据

### 使用示例

```bash
# 首次全量下载
python script/enhanced_downloader.py --all

# 之后每日增量更新
python script/enhanced_downloader.py --all --incremental
```

### 元数据管理

元数据保存在 `data/.metadata/` 目录：

```bash
# 查看某股票元数据
cat data/.metadata/sh_600000.meta.json
```

## 常见问题

### Q1: 登录失败

**问题**：运行时提示 "Baostock login failed"

**解决**：
1. 检查网络连接
2. 确认 baostock 已安装：`pip show baostock`
3. 查看 Baostock 服务状态：http://baostock.com/

### Q2: 下载速度慢

**问题**：下载全部 A 股耗时过长

**解决**：
1. 增加并行工作线程：`-w 8`（默认 4）
2. 使用增量更新模式：`--incremental`
3. 减少下载日期范围：`--start 2023-01-01 --end 2023-12-31`

```bash
# 优化示例
python script/enhanced_downloader.py --all -w 8 --incremental
```

### Q3: 数据验证失败

**问题**：验证发现数据质量问题

**解决**：
1. 重新下载问题股票：
   ```bash
   python script/enhanced_downloader.py -s sh.600000
   ```
2. 删除问题文件后重新下载
3. 检查是否为 Baostock 数据源问题

### Q4: 财务指标数据为空

**问题**：`--financials` 下载无数据

**解决**：
1. 确认股票代码正确
2. 检查日期范围（部分新股可能无财务数据）
3. Baostock 财务数据更新频率为季度，非实时

### Q5: 如何定时执行？

**解决**：使用 cron 或 Task Scheduler

```bash
# Linux/Mac: 每日 8 点执行增量更新
crontab -e
0 8 * * * cd /path/to/project && python script/enhanced_downloader.py --all --incremental -q

# Windows: 使用 Task Scheduler 创建定时任务
```

### Q6: 如何集成到后端？

**解决**：在 MoonBit 后端调用 Python 脚本

```python
# 或在 Python 中直接调用
from enhanced_downloader import EnhancedBaostockDownloader, DownloadConfig

config = DownloadConfig(output_dir="./data", max_workers=4)
with EnhancedBaostockDownloader(config) as d:
    result = d.download_full("sh.600000")
    print(result.success, result.message)
```

## 最佳实践

1. **首次 setup**：全量下载全部 A 股数据
   ```bash
   python script/enhanced_downloader.py --all -w 8
   ```

2. **每日更新**：增量更新 K-line 数据
   ```bash
   python script/enhanced_downloader.py --all --incremental -q
   ```

3. **每周更新**：下载财务指标和行业分类
   ```bash
   python script/enhanced_downloader.py --financials --industries --all
   ```

4. **数据验证**：定期验证数据质量
   ```bash
   python script/enhanced_downloader.py --validate --all
   ```

5. **备份策略**：定期备份 `data/` 目录
   ```bash
   tar -czf data_backup_$(date +%Y%m%d).tar.gz data/
   ```

## 参考文档

- [Baostock 官方文档](http://baostock.com/baostock/index.php)
- [项目架构文档](architecture.md)
- [数据格式说明](data-format.md)
- [API 端点文档](api-endpoints.md)
