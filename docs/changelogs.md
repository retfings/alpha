# Change Log

Automated log of file changes from git commits.

## [2026-03-27] Enhanced Baostock Data Tools

**Author:** Data Engineer

**Description:**
Enhanced Baostock data integration with new tools for incremental updates, data validation, and comprehensive documentation.

**New files:**
- `script/enhanced_downloader.py` (新增) - Enhanced downloader with incremental updates
- `script/validate_data.py` (新增) - Data quality validation tool
- `docs/baostock-data-guide.md` (新增) - Comprehensive data download guide

**Features added:**

### script/enhanced_downloader.py
- Incremental update support (download only new data since last update)
- Parallel download with configurable workers (default: 4)
- Automatic retry on failure (3 attempts with exponential backoff)
- Progress tracking and detailed reporting
- Metadata tracking in `.metadata/` directory
- Batch download support for all A-share stocks
- Multiple data frequencies (daily, weekly, monthly, minute-level)
- Forward/backward/no adjustment support

### script/validate_data.py
- Price range validation (negative values, extreme values)
- Date sequence validation (missing dates, large gaps)
- Price continuity validation (extreme jumps)
- Volume validation
- Statistics computation
- Detailed validation reports
- Batch validation support

### docs/baostock-data-guide.md
- Quick start guide
- Installation instructions
- Download scripts comparison
- Initial download workflows
- Incremental update procedures
- Data validation guide
- Troubleshooting section
- Best practices for data management
- Command reference

**Usage examples:**

```bash
# Initial download of all A-shares
python script/enhanced_downloader.py --all

# Incremental update (download only new data)
python script/enhanced_downloader.py --incremental --all

# Validate all downloaded data
python script/validate_data.py --all --report

# Download specific stocks
python script/enhanced_downloader.py --stocks sh.600000 sz.000001

# Download 5-minute data
python script/enhanced_downloader.py --stocks sh.600000 --frequency 5
```

---

## [2026-03-27] 文档开发完成

**Author:** Doc Engineer

**Commit:** docs: add comprehensive documentation for Baostock integration

**Description:**
完成 Baostock 数据接入项目的所有文档编写工作，包括 API 使用文档、数据格式说明、策略开发指南。

**Changed files:**
- `docs/baostock-api.md` (新增) - Baostock API 使用文档
- `docs/data-format.md` (新增) - 数据格式说明文档
- `docs/strategy-guide.md` (新增) - 策略开发指南
- `docs/changelogs.md` (更新) - 更新日志记录

**文档内容概述:**

### docs/baostock-api.md
- Baostock 安装说明
- API 函数参考（登录/登出、数据查询）
- 支持的数据类型和字段说明
- 频率参数对照表（日线、分钟线）
- 复权参数说明（前复权、后复权、无复权）
- 使用示例（单只股票、批量下载、CSV 导出）
- 项目集成脚本使用说明

### docs/data-format.md
- CSV 文件格式规范
- 文件命名规则
- KLine 数据结构详解
- Frequency 枚举说明
- 存储目录结构
- 数据加载示例（MoonBit、Python）
- 数据验证方法

### docs/strategy-guide.md
- 策略开发入门流程
- Strategy 接口详细说明
- 信号类型（Action、Signal）
- 回调函数（on_init、on_bar）
- 内置策略示例：
  - 均线交叉策略 (MA Cross)
  - 动量策略 (Momentum)
  - RSI 均值回归策略
- 回测使用指南（CLI、MoonBit 代码）
- 回测结果解析
- 策略开发最佳实践

---

## [2026-03-27 03:09:00] 0ad8430
## [2026-03-27 06:15:11] 9a91000

**Author:** DevUser

**Commit:** feat: add drawdown analysis types and comprehensive indicators

**Changed files:**
- `docs/changelogs.md`
- `docs/test-coverage-report.md`
- `script/test.sh`
- `src/drawdown/types.mbt`
- `src/ffi/file_io.c`
- `src/indicator/atr.mbt`
- `src/indicator/atr_test.mbt`
- `src/indicator/cci.mbt`
- `src/indicator/cci_test.mbt`
- `src/indicator/kdj.mbt`
- `src/indicator/kdj_test.mbt`
- `src/indicator/ma.mbt`
- `src/indicator/obv.mbt`
- `src/indicator/obv_test.mbt`
- `src/indicator/williams_r.mbt`
- `src/indicator/williams_r_test.mbt`
- `src/portfolio/manager.mbt`
- `src/portfolio/portfolio_test.mbt`

---


## [2026-03-27 06:11:44] cc9daf5

**Author:** DevUser

**Commit:** docs: update changelogs.md

**Changed files:**
- `docs/changelogs.md`

---


## [2026-03-27 06:11:17] 74a09d5

**Author:** DevUser

**Commit:** fix: resolve syntax errors in risk/rules.mbt documentation examples

**Changed files:**
- `docs/api-reference.md`
- `docs/architecture.md`
- `docs/changelogs.md`
- `docs/code-quality-review.md`
- `docs/test-coverage-report.md`
- `script/requirements.txt`
- `script/server.py`
- `script/start-server.sh`
- `src/backtest/engine.mbt`
- `src/data/data_wbtest.mbt`
- `src/risk/moon.pkg`
- `src/risk/rules.mbt`
- `src/strategy/pkg.generated.mbti`

---



**Author:** Unknown

**Commit:** docs: update optimization roadmap with completed work (Task #38)

**Changed files:**
- `docs/optimization-roadmap.md`

---

## [2026-03-27 02:59:00] 17b977e

**Author:** Unknown

**Commit:** refactor: final code quality improvements (Task #29)

**Changed files:**
- Multiple source files

---

## [2026-03-27 02:44:00] 8475386

**Author:** Unknown

**Commit:** test: add missing backtest module tests (Task #40)

**Changed files:**
- Test files for backtest module

---

## [2026-03-27 02:30:00] da4f174

**Author:** Unknown

**Commit:** fix: remove unused functions and clean up imports

**Changed files:**
- Source files cleanup

---

## [2026-03-27 02:00:00] 05701df

**Author:** Unknown

**Commit:** docs: add performance optimization code review

**Changed files:**
- `docs/PERFORMANCE_OPTIMIZATION_REVIEW.md`

---
