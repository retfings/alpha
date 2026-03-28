# Baostock Data Download Guide

**Last Updated**: 2026-03-27

Complete guide for downloading, updating, and validating stock data using Baostock API.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Download Scripts Overview](#download-scripts-overview)
4. [Initial Data Download](#initial-data-download)
5. [Incremental Updates](#incremental-updates)
6. [Data Validation](#data-validation)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Quick Start

```bash
# 1. Install dependencies
pip install -r script/requirements.txt

# 2. Download all A-share stocks (daily data, last 3 years, forward-adjusted)
python script/enhanced_downloader.py --all

# 3. Validate downloaded data
python script/validate_data.py --all --report

# 4. Incremental update (download only new data since last update)
python script/enhanced_downloader.py --incremental --all
```

---

## Installation

### Prerequisites

- Python 3.8 or higher
- pip package manager
- Internet connection (Baostock API requires network access)

### Step 1: Install Python Dependencies

```bash
cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha
pip install -r script/requirements.txt
```

The `requirements.txt` contains:
```
baostock
```

### Step 2: Verify Installation

```python
import baostock as bs
print(bs.__version__)
```

### Step 3: Test Connection

```bash
# Download a single stock to test
python script/enhanced_downloader.py --stocks sh.600000
```

---

## Download Scripts Overview

The project provides three main scripts for data management:

| Script | Purpose | Use Case |
|--------|---------|----------|
| `download_data.py` | Basic download script | Simple one-time downloads |
| `enhanced_downloader.py` | Advanced downloader with incremental updates | Production data management |
| `validate_data.py` | Data quality validation | Quality assurance checks |

### Feature Comparison

| Feature | download_data.py | enhanced_downloader.py |
|---------|------------------|------------------------|
| Basic download | ✅ | ✅ |
| Incremental updates | ❌ | ✅ |
| Parallel download | ❌ | ✅ |
| Auto-retry | ❌ | ✅ |
| Data validation | ❌ | ✅ |
| Metadata tracking | ❌ | ✅ |
| Progress report | Basic | Detailed |

**Recommendation**: Use `enhanced_downloader.py` for all production workflows.

---

## Initial Data Download

### Download All A-Share Stocks

```bash
# Full download of all A-share stocks (daily data, last 3 years)
python script/enhanced_downloader.py --all

# With custom date range
python script/enhanced_downloader.py --all --start 2023-01-01 --end 2024-12-31

# With custom output directory
python script/enhanced_downloader.py --all -o ./my_data/
```

### Download Specific Stocks

```bash
# Single stock
python script/enhanced_downloader.py --stocks sh.600000

# Multiple stocks
python script/enhanced_downloader.py --stocks sh.600000 sz.000001 sh.600036

# Using short form
python script/enhanced_downloader.py -s sh.600000 sz.000001
```

### Download Different Data Frequencies

```bash
# Daily data (default)
python script/enhanced_downloader.py --stocks sh.600000 -f d

# Weekly data
python script/enhanced_downloader.py --stocks sh.600000 -f w

# Monthly data
python script/enhanced_downloader.py --stocks sh.600000 -f m

# 5-minute data (intraday)
python script/enhanced_downloader.py --stocks sh.600000 -f 5

# 15-minute data
python script/enhanced_downloader.py --stocks sh.600000 -f 15
```

### Adjust Data Settings

```bash
# Forward-adjusted data (recommended for backtesting)
python script/enhanced_downloader.py --stocks sh.600000 -a 3

# Backward-adjusted data
python script/enhanced_downloader.py --stocks sh.600000 -a 1

# No adjustment
python script/enhanced_downloader.py --stocks sh.600000 -a 2
```

### Parallel Download Configuration

```bash
# Increase parallel workers (default: 4)
python script/enhanced_downloader.py --all --workers 8

# Reduce for slower connections
python script/enhanced_downloader.py --all --workers 2
```

### Quiet Mode (CI/CD, Scripts)

```bash
# Suppress progress output
python script/enhanced_downloader.py --all --quiet
```

### Download Financial Data

```bash
# Download financial indicators for all stocks
python script/enhanced_downloader.py --financials --all

# Download for specific stocks
python script/enhanced_downloader.py --financials --stocks sh.600000 sz.000001
```

**Output**: Saves to `data/financials/{stock_code}_financials_{start}_{end}.csv`

**Financial indicators include**:
- **Profitability**: ROE, ROA, gross profit margin, net profit margin
- **Growth**: Revenue growth, profit growth, asset growth
- **Solvency**: Debt-to-asset ratio, current ratio, quick ratio
- **Efficiency**: Asset turnover, inventory turnover, receivables turnover
- **Per-share**: EPS, DPS, operating cash flow per share
- **Balance sheet**: Total assets, liabilities, equity
- **Income statement**: Revenue, operating cost, expenses

### Download Industry Classification

```bash
# Download industry classification for all A-shares
python script/enhanced_downloader.py --industries
```

**Output**: Saves to `data/industries/industry_classification_YYYYMMDD.csv`

**Industry data includes**:
- Stock code and name
- Industry name
- Industry type (CSRC standard)
- Industry codes (levels 1, 2, 3)

---

## Incremental Updates

Incremental updates download only new data since the last download, saving time and bandwidth.

### How It Works

1. The downloader tracks metadata for each stock in `.metadata/` directory
2. On incremental update, it:
   - Reads the last downloaded date from metadata
   - Downloads only data after that date
   - Merges new data with existing files
   - Updates metadata

### First-Time Incremental Update

```bash
# Initial full download
python script/enhanced_downloader.py --all

# Subsequent incremental updates
python script/enhanced_downloader.py --incremental --all
```

### Daily Update Workflow

For daily updates (run after market close):

```bash
#!/bin/bash
# daily_update.sh
python script/enhanced_downloader.py --incremental --all -q
python script/validate_data.py --all --quiet
```

### Incremental Update with Specific End Date

```bash
# Update to a specific date
python script/enhanced_downloader.py --incremental --all --end 2024-12-31
```

### Metadata Location

Metadata is stored in:
```
data/.metadata/
├── sh_600000.meta.json
├── sz_000001.meta.json
└── ...
```

Each metadata file contains:
```json
{
  "code": "sh.600000",
  "last_update": "2026-03-27T10:30:00",
  "last_date": "2026-03-26",
  "record_count": 500,
  "file_path": "/path/to/data/sh_600000_2023-01-01_2026-03-26.csv"
}
```

---

## Data Validation

### Run Validation

```bash
# Validate all stocks
python script/validate_data.py --all

# Validate specific stocks
python script/validate_data.py --stocks sh.600000 sz.000001

# Generate detailed report
python script/validate_data.py --all --report

# Save report to file
python script/validate_data.py --all --report --output validation_report.txt
```

### Validation Checks

The validator performs these checks:

| Check | Type | Description |
|-------|------|-------------|
| Price Range | Error | Negative prices |
| Price Range | Warning | Extreme prices (>1000) |
| Date Sequence | Warning | Large gaps in trading days |
| Price Continuity | Warning | Extreme price jumps (>50%) |
| Volume | Error | Negative volume |

### Validation Output

```
Validating sh.600000... OK (500 rows, 0 errors, 2 warnings)
Validating sz.000001... ISSUES (450 rows, 1 errors, 0 warnings)

==================================================
VALIDATION SUMMARY
==================================================
  Total stocks:     5000
  Valid:            4998
  Invalid:          2
  Total errors:     3
  Total warnings:   15
==================================================
```

### Understanding Validation Results

**Errors** (must fix):
- Negative prices or volumes
- Invalid date formats
- Missing critical fields

**Warnings** (review recommended):
- Large gaps in data (may indicate missing data)
- Extreme price jumps (may be stock split or data error)
- Extreme prices (may be legitimate for high-priced stocks)

### Fixing Data Issues

For missing data:
```bash
# Re-download specific stocks
python script/enhanced_downloader.py --stocks sh.600000 --start 2024-01-01 --end 2024-12-31
```

For corrupted files:
```bash
# Delete and re-download
rm data/sh_600000_*.csv
rm data/.metadata/sh_600000.meta.json
python script/enhanced_downloader.py --stocks sh.600000
```

---

## Troubleshooting

### Login Failed

**Error**: `Baostock login failed: connection timeout`

**Solutions**:
1. Check internet connection
2. Baostock servers may be temporarily unavailable (try again later)
3. Check firewall settings

```bash
# Test connection
ping www.baostock.com

# Retry with delay
python script/enhanced_downloader.py --all --workers 1
```

### No Data Downloaded

**Error**: `No data available for this range`

**Possible causes**:
- Stock code is incorrect
- Date range is outside trading history
- Stock was suspended during the period

**Solutions**:
1. Verify stock code format: `sh.600000` or `sz.000001`
2. Check stock's IPO date
3. Try a different date range

```bash
# Check stock info
python -c "import baostock as bs; bs.login(); print(bs.query_stock_basic().get_row_data())"
```

### Memory Issues with Large Downloads

**Error**: `MemoryError` or system becomes unresponsive

**Solutions**:
1. Reduce parallel workers
2. Download in batches

```bash
# Reduce workers
python script/enhanced_downloader.py --all --workers 2

# Batch download (create script)
cat > batch_download.sh << 'EOF'
#!/bin/bash
stocks=(sh.600000 sh.600001 sh.600002 ...)
for stock in "${stocks[@]}"; do
    python script/enhanced_downloader.py --stocks "$stock"
done
EOF
chmod +x batch_download.sh
./batch_download.sh
```

### CSV Files Are Empty

**Cause**: Query returned no data

**Solutions**:
1. Check if the stock exists
2. Verify date range
3. Check Baostock API status

```bash
# Manual test query
python << 'EOF'
import baostock as bs
bs.login()
rs = bs.query_history_k_data_plus(
    code="sh.600000",
    fields="date,open,high,low,close",
    start_date="2024-01-01",
    end_date="2024-12-31",
    frequency="d",
    adjustflag="3"
)
print(f"Error code: {rs.error_code}")
print(f"Error message: {rs.error_msg}")
print(f"Records: {len([rs.get_row_data() for _ in iter(rs.next, False)])}")
bs.logout()
EOF
```

### Incremental Update Not Working

**Symptoms**: Full download happens instead of incremental

**Solutions**:
1. Check metadata directory exists
2. Verify metadata files are not corrupted

```bash
# Check metadata
ls -la data/.metadata/

# If missing, run full download first
python script/enhanced_downloader.py --all

# Manually fix metadata
cat data/.metadata/sh_600000.meta.json
```

---

## Best Practices

### 1. Regular Update Schedule

For active trading strategies:
```bash
# Weekday daily update (after market close at 3:30 PM)
30 15 * * 1-5 cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha && \
    python script/enhanced_downloader.py --incremental --all -q && \
    python script/validate_data.py --all -q
```

### 2. Data Backup

```bash
# Weekly backup
0 2 * * 0 tar -czf /backup/stock_data_$(date +\%Y\%m\%d).tar.gz data/*.csv
```

### 3. Disk Space Management

Monitor data directory size:
```bash
du -sh data/
```

For large datasets, consider:
- Using Parquet format (compressed)
- Archiving old data
- Selective download (only stocks you need)

### 4. Rate Limiting

Baostock doesn't officially document rate limits. Best practices:
- Use `--workers 4` or less for batch downloads
- Add delays between requests for large batches
- Avoid downloading during peak hours (9:30-11:30, 13:00-15:00 Beijing time)

### 5. Data Quality Monitoring

Set up alerts for validation failures:
```bash
#!/bin/bash
# check_data_quality.sh
python script/validate_data.py --all --report --output /tmp/validation.txt
if grep -q "Invalid" /tmp/validation.txt; then
    echo "Data validation failed!" | mail -s "Stock Data Alert" admin@example.com
fi
```

### 6. Version Control for Metadata

Track metadata changes:
```bash
cd data/.metadata
git add *.meta.json
git commit -m "Update stock metadata"
git push
```

---

## FAQ (Frequently Asked Questions)

### Q1: 如何下载全部 A 股股票数据？

```bash
python script/enhanced_downloader.py --all
```

这会自动获取所有 A 股股票代码并下载日线数据（最近 3 年，前复权）。

### Q2: 如何更新最新的数据？

使用增量更新模式：

```bash
# 增量更新全部股票
python script/enhanced_downloader.py --incremental --all

# 增量更新指定股票
python script/enhanced_downloader.py --incremental --stocks sh.600000
```

### Q3: 如何下载特定行业或板块的股票？

首先下载行业分类数据：

```bash
python script/enhanced_downloader.py --industries
```

然后从行业分类文件中筛选出目标行业的股票代码，再进行批量下载。

### Q4: 数据文件在哪里？

默认保存在 `data/` 目录：
- 日线数据：`data/*.csv`
- 财务数据：`data/financials/*.csv`
- 行业分类：`data/industries/*.csv`
- 元数据：`data/.metadata/*.json`

### Q5: 如何检查数据质量？

```bash
python script/validate_data.py --all --report
```

### Q6: 下载速度慢怎么办？

1. 增加并行 worker 数量（默认 4）：
   ```bash
   python script/enhanced_downloader.py --all --workers 8
   ```

2. 在网络状况较差时减少 worker：
   ```bash
   python script/enhanced_downloader.py --all --workers 2
   ```

### Q7: 如何下载历史全部数据？

```bash
# 下载 10 年历史数据
python script/enhanced_downloader.py --all --start 2016-01-01 --end 2026-12-31
```

### Q8: 财务数据如何下载？

```bash
# 下载全部股票财务指标
python script/enhanced_downloader.py --financials --all

# 下载指定股票财务指标
python script/enhanced_downloader.py --financials --stocks sh.600000 sz.000001
```

### Q9: 如何验证下载的数据完整性？

```bash
# 验证全部数据
python script/validate_data.py --all

# 生成详细报告
python script/validate_data.py --all --report --output validation_report.txt
```

### Q10: 元数据文件有什么用？

元数据文件记录每只股票的最后更新日期和记录数，用于增量更新。位置：`data/.metadata/`

```json
{
  "code": "sh.600000",
  "last_update": "2026-03-27T22:13:58",
  "last_date": "2026-03-27",
  "record_count": 539
}
```

### Q11: 如何处理下载失败？

```bash
# 自动重试 3 次（内置功能）
# 手动重试特定股票
python script/enhanced_downloader.py --stocks sh.600000 --retry
```

### Q12: 如何定期自动更新数据？

设置 cron 定时任务（Linux/Mac）：

```bash
# 每个交易日下午 4 点更新
crontab -e
# 添加：
0 16 * * 1-5 cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha && \
    python script/enhanced_downloader.py --incremental --all -q
```

---

## Additional Usage Examples

### Example 1: 下载银行板块全部股票

```bash
# 1. 下载行业分类
python script/enhanced_downloader.py --industries

# 2. 从行业分类中筛选银行板块代码
# 3. 批量下载
python script/enhanced_downloader.py --stocks sh.600000 sh.600016 sh.600036
```

### Example 2: 下载分钟级数据

```bash
# 5 分钟 K 线
python script/enhanced_downloader.py --stocks sh.600000 --frequency 5

# 15 分钟 K 线
python script/enhanced_downloader.py --stocks sh.600000 --frequency 15

# 60 分钟 K 线
python script/enhanced_downloader.py --stocks sh.600000 --frequency 60
```

### Example 3: 批量下载并验证

```bash
#!/bin/bash
# download_and_validate.sh
set -e

echo "Downloading data..."
python script/enhanced_downloader.py --all --incremental -q

echo "Validating data..."
python script/validate_data.py --all --quiet

echo "Done!"
```

### Example 4: 数据备份脚本

```bash
#!/bin/bash
# backup_data.sh
DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/stock_data"

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/data_$DATE.tar.gz" data/*.csv
echo "Backup completed: $BACKUP_DIR/data_$DATE.tar.gz"
```

### Example 5: 查看数据目录大小

```bash
# 查看数据目录总大小
du -sh data/

# 查看各类型数据大小
du -sh data/*.csv | head -10
du -sh data/financials/
du -sh data/industries/
du -sh data/.metadata/
```

### Example 6: 导出到 Parquet（需要 pyarrow）

```bash
# 安装依赖
pip install pandas pyarrow

# 转换全部 CSV 文件
python script/convert_to_parquet.py --all

# 转换指定股票
python script/convert_to_parquet.py --stocks sh.600000 sz.000001

# 使用 gzip 压缩
python script/convert_to_parquet.py --all --compression gzip

# 保存到子目录
python script/convert_to_parquet.py --all --output parquet/

# 转换后删除原 CSV 文件
python script/convert_to_parquet.py --all --remove-csv
```

**Parquet 格式优势**：
- 更高的压缩率（通常比 CSV 小 50-80%）
- 更快的读取速度
- 保留数据类型信息
- 支持列式存储（适合分析）

**Parquet 转换脚本选项**：

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--all` | 转换全部 CSV | false |
| `--stocks` | 转换指定股票 | - |
| `--compression` | 压缩方式 (snappy/gzip/zstd) | snappy |
| `--output` | 输出目录 | 同 CSV 目录 |
| `--remove-csv` | 删除原 CSV | false |

---

## Command Reference

### enhanced_downloader.py

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--all` | | Download all A-shares | false |
| `--stocks` | `-s` | Stock codes | sh.600000 sz.000001 |
| `--incremental` | `-i` | Incremental update | false |
| `--validate` | `-v` | Validate only | false |
| `--start` | | Start date (YYYY-MM-DD) | 3 years ago |
| `--end` | | End date (YYYY-MM-DD) | today |
| `--output` | `-o` | Output directory | ../data |
| `--frequency` | `-f` | d/w/m/5/15/30/60 | d |
| `--adjustflag` | `-a` | 1/2/3 (back/none/forward) | 3 |
| `--workers` | `-w` | Parallel workers | 4 |
| `--quiet` | `-q` | No progress output | false |

### validate_data.py

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--all` | | Validate all stocks | false |
| `--stocks` | `-s` | Stock codes | sh.600000 sz.000001 |
| `--report` | | Generate report | false |
| `--output` | | Report output path | stdout |
| `--data-dir` | | Data directory | ../data |
| `--quiet` | `-q` | No progress output | false |

---

## API Reference

### Baostock Data Fields

**Daily Fields**:
```
date, open, high, low, close, volume, amount, turn
```

**Minute Fields**:
```
date, time, open, high, low, close, volume, amount, turn
```

### Adjust Flag Values

| Value | Type | Chinese | Use Case |
|-------|------|---------|----------|
| 1 | Backward-adjusted | 后复权 | Historical analysis |
| 2 | No adjustment | 无复权 | Raw data |
| 3 | Forward-adjusted | 前复权 | **Backtesting (recommended)** |

---

## Additional Resources

- [Baostock Official Documentation](http://www.baostock.com)
- [Baostock GitHub](https://github.com/baostock/baostock)
- [Project Architecture](docs/architecture.md)
- [Data Format Specification](docs/data-format.md)

---

## Support

For issues related to:
- **Baostock API**: Check Baostock official documentation
- **Download scripts**: Review error messages and troubleshooting section
- **Data format**: See `docs/data-format.md`
- **MoonBit integration**: See `src/data/loader.mbt`
