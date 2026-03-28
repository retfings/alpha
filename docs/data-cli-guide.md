# 股票数据下载 CLI 工具使用指南

## 概述

`data_cli.py` 是一个基于 BaoStock API 的股票数据下载命令行工具，支持下载 A 股市场的各类金融数据，包括 K 线数据、财务数据、分红数据、行业分类等，并将数据保存为 CSV 格式。

## 安装依赖

```bash
cd script/data_download
pip install -r requirements.txt
```

依赖包包括：
- `baostock`: 证券数据 API
- `pandas`: 数据处理和 CSV 导出
- `argparse`: 命令行参数解析（Python 标准库）

## 快速开始

### 1. 下载 K 线数据

```bash
# 下载日线数据（默认不复权）
python data_cli.py download-kline --code sh.600000

# 下载指定时间范围的日线数据
python data_cli.py download-kline --code sh.600000 --start 2023-01-01 --end 2023-12-31

# 下载周线数据（后复权）
python data_cli.py download-kline --code sh.600000 --frequency w --adjust 1

# 下载月线数据（前复权）
python data_cli.py download-kline --code sh.600000 --frequency m --adjust 2

# 下载 15 分钟 K 线数据
python data_cli.py download-kline --code sh.600000 --frequency 15
```

**参数说明**：
- `--code`: 股票/指数代码，格式为 `sh.600000` 或 `sz.000001`
- `--start`: 开始日期，格式 `YYYY-MM-DD`
- `--end`: 结束日期，格式 `YYYY-MM-DD`
- `--frequency`: 数据频率
  - `d`: 日 K 线（默认）
  - `w`: 周 K 线
  - `m`: 月 K 线
  - `5/15/30/60`: 分钟 K 线
- `--adjust`: 复权类型
  - `1`: 后复权
  - `2`: 前复权
  - `3`: 不复权（默认）

**输出字段**：
| 字段 | 说明 |
|------|------|
| date | 交易日期 |
| code | 证券代码 |
| open | 开盘价 |
| high | 最高价 |
| low | 最低价 |
| close | 收盘价 |
| volume | 成交量（股） |
| amount | 成交额（元） |
| adjustflag | 复权状态 |
| turn | 换手率 |
| tradestatus | 交易状态 |
| pctChg | 涨跌幅 |
| peTTM | 滚动市盈率 |
| pbMRQ | 市净率 |
| psTTM | 滚动市销率 |
| pcfNcfTTM | 滚动市现率 |

### 2. 下载财务数据

```bash
# 下载最近一年的财务数据
python data_cli.py download-financials --code sh.600000

# 下载指定年份的财务数据
python data_cli.py download-financials --code sh.600000 --year 2023

# 下载指定季度的财务数据
python data_cli.py download-financials --code sh.600000 --year 2023 --quarter 4
```

**参数说明**：
- `--code`: 股票代码
- `--year`: 年份（可选）
- `--quarter`: 季度（可选）
  - `1`: 第一季度财报
  - `2`: 半年度财报
  - `3`: 第三季度财报
  - `4`: 年度财报

**输出字段**：
财务数据包含三类指标：

**盈利能力**（data_type='profit'）：
| 字段 | 说明 |
|------|------|
| roeAvg | 净资产收益率 (%) |
| npMargin | 销售净利率 (%) |
| gpMargin | 销售毛利率 (%) |
| netProfit | 净利润 (万元) |
| epsTTM | 每股收益 (元) |
| MBRevenue | 主营营业收入 (万元) |

**营运能力**（data_type='operation'）：
| 字段 | 说明 |
|------|------|
| NRTurnRatio | 应收账款周转率 |
| NRTurnDays | 应收账款周转天数 |
| INVTurnRatio | 存货周转率 |
| INVTurnDays | 存货周转天数 |

**成长能力**（data_type='growth'）：
| 字段 | 说明 |
|------|------|
| YOYEquity | 净资产同比增长率 (%) |
| YOYAsset | 总资产同比增长率 (%) |
| YOYNI | 净利润同比增长率 (%) |
| YOYOperation | 营业总收入同比增长率 (%) |

### 3. 下载分红数据

```bash
# 下载全部分红数据
python data_cli.py download-dividend --code sh.600000

# 下载指定年份的分红数据
python data_cli.py download-dividend --code sh.600000 --year 2023

# 下载除权除息年份数据
python data_cli.py download-dividend --code sh.600000 --year 2023 --type operate
```

**参数说明**：
- `--code`: 股票代码
- `--year`: 年份（可选）
- `--type`: 年份类型
  - `report`: 预案公告年份（默认）
  - `operate`: 除权除息年份
  - `dividend`: 分红年份

**输出字段**：
| 字段 | 说明 |
|------|------|
| dividPreNoticeDate | 预批露公告日期 |
| dividOperateDate | 除权除息日期 |
| dividPayDate | 派息日期 |
| dividCashPsBeforeTax | 每股股利税前 (元) |
| dividStocksPs | 每股送股比例 |
| dividReserveToStockPs | 每股公积金转增比例 |

### 4. 下载指数数据

```bash
# 下载上证指数日线数据
python data_cli.py download-index --code sh.000001

# 下载沪深 300 指数月线数据
python data_cli.py download-index --code sh.000300 --frequency m

# 下载深证成指指定时间范围数据
python data_cli.py download-index --code sz.399001 --start 2023-01-01 --end 2023-12-31
```

**常用指数代码**：
| 代码 | 名称 |
|------|------|
| sh.000001 | 上证指数 |
| sh.000016 | 上证 50 |
| sh.000300 | 沪深 300 |
| sh.000905 | 中证 500 |
| sz.399001 | 深证成指 |
| sz.399106 | 深证综指 |

**输出字段**：
| 字段 | 说明 |
|------|------|
| date | 交易日期 |
| open | 开盘价 |
| high | 最高价 |
| low | 最低价 |
| close | 收盘价 |
| preclose | 前收盘价 |
| volume | 成交量 |
| amount | 成交额 |
| pctChg | 涨跌幅 |

### 5. 下载估值数据

```bash
# 下载日线估值数据
python data_cli.py download-valuation --code sh.600000

# 下载周线估值数据
python data_cli.py download-valuation --code sh.600000 --frequency w

# 下载指定时间范围的估值数据
python data_cli.py download-valuation --code sh.600000 --start 2023-01-01 --end 2023-12-31
```

**输出字段**：
| 字段 | 说明 |
|------|------|
| date | 交易日期 |
| close | 收盘价 |
| peTTM | 滚动市盈率 |
| pbMRQ | 市净率 |
| psTTM | 滚动市销率 |
| pcfNcfTTM | 滚动市现率 |

### 6. 下载所有数据

一次性下载某只股票的所有可用数据：

```bash
python data_cli.py download-all --code sh.600000
```

该命令会下载：
1. 最近一年的 K 线数据
2. 最近一年的财务数据
3. 全部分红数据
4. 行业分类数据
5. 最近一年的估值数据

### 7. 列出股票列表

```bash
# 列出所有股票
python data_cli.py list-stocks

# 按行业筛选（如银行）
python data_cli.py list-stocks --industry 银行

# 筛选医药行业
python data_cli.py list-stocks --industry 医药
```

**输出字段**：
| 字段 | 说明 |
|------|------|
| code | 证券代码 |
| code_name | 证券名称 |
| industry | 所属行业 |
| industryClassification | 行业分类 |

## 输出目录

所有 CSV 文件默认保存到 `./data` 目录，可通过 `-o` 参数指定：

```bash
python data_cli.py download-kline --code sh.600000 -o ./output/kline_data
```

文件命名规则：
- K 线数据：`{code}_kline_{frequency}_{adjust}_{start}_{end}.csv`
- 财务数据：`{code}_financials.csv`
- 分红数据：`{code}_dividend_{year}_{type}.csv`
- 指数数据：`{code}_index_{frequency}_{start}_{end}.csv`
- 估值数据：`{code}_valuation_{frequency}_{start}_{end}.csv`
- 行业数据：`industry_classification.csv`
- 股票列表：`stock_list.csv`

## 常用股票代码

| 代码 | 名称 | 代码 | 名称 |
|------|------|------|------|
| sh.600000 | 浦发银行 | sz.000001 | 平安银行 |
| sh.600036 | 招商银行 | sz.000002 | 万科 A |
| sh.601318 | 中国平安 | sz.300750 | 宁德时代 |
| sh.600519 | 贵州茅台 | sz.000858 | 五粮液 |
| sh.688981 | 中芯国际 | sz.002594 | 比亚迪 |

## 常见问题

### 1. 代码格式错误

**错误**: `无效的代码格式：600000`

**解决**: 股票代码必须包含交易所前缀：
- 上交所股票：`sh.600000`
- 深交所股票：`sz.000001`

### 2. BaoStock 登录失败

**错误**: `BaoStock 登录失败`

**解决**:
- 检查网络连接
- 确认 BaoStock 服务正常运行
- 尝试重新安装：`pip uninstall baostock && pip install baostock`

### 3. 数据为空

**错误**: `未获取到数据`

**可能原因**:
- 股票代码不存在
- 时间范围内无交易数据（如停牌）
- 指数代码格式不正确

### 4. CSV 文件乱码

CSV 文件使用 UTF-8 with BOM 编码（`utf-8-sig`），Excel 可直接正常打开。如在其他工具中使用，请确保支持 UTF-8 编码。

## 数据用途

本工具下载的数据可用于：
- 量化策略回测
- 技术分析和基本面分析
- 投资组合构建
- 风险管理和 drawdown 分析
- 学术研究和教学

## 注意事项

1. **数据频率**: BaoStock 提供免费数据服务，数据可能存在延迟，不适用于实时交易
2. **使用限制**: 请遵守 BaoStock 的使用条款，不要高频请求数据
3. **数据准确性**: 投资决策前请通过多个数据源验证
4. **存储管理**: 历史数据文件较大，定期清理不需要的数据

## 完整命令参考

```bash
# 显示帮助
python data_cli.py --help

# 显示子命令帮助
python data_cli.py download-kline --help
python data_cli.py download-financials --help
```

## 示例脚本

批量下载多只股票的数据：

```bash
#!/bin/bash
# batch_download.sh

STOCKS="sh.600000 sh.600036 sh.601318 sh.600519 sz.000001 sz.000002"

for stock in $STOCKS; do
    echo "Downloading data for $stock..."
    python data_cli.py download-all --code $stock -o ./batch_data
done

echo "All downloads completed!"
```

执行：
```bash
chmod +x batch_download.sh
./batch_download.sh
```
