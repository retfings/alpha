# 股票筛选器用户指南

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [快速开始](#快速开始)
2. [股票池配置](#股票池配置)
3. [基础筛选](#基础筛选)
4. [技术指标筛选](#技术指标筛选)
5. [财务指标筛选](#财务指标筛选)
6. [选股策略保存](#选股策略保存)
7. [常见问题](#常见问题)

---

## 快速开始

### 1. 启动系统

#### CLI 模式

```bash
# 启动股票筛选器
MOONBIT_CMD=stock-screener moon run alpha
```

#### Web 模式

```bash
# 启动 HTTP 服务器
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run alpha

# 在浏览器中访问
# http://localhost:8080
```

### 2. 基本筛选流程

```
1. 选择股票池 → 2. 设置筛选条件 → 3. 执行筛选 → 4. 查看结果
```

### 3. 快速示例

**CLI 示例** - 筛选市盈率低于 20 的银行股:

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--industry 银行 --max-pe 20" moon run alpha
```

**Web 示例** - 使用 Web 界面:

1. 访问 `http://localhost:8080/stock_strategy.html`
2. 选择"银行"行业
3. 设置市盈率 < 20
4. 点击"执行筛选"

---

## 股票池配置

### 全市场股票池

筛选所有 A 股市场的股票。

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--pool all" moon run alpha
```

### 按交易所筛选

**上海证券交易所 (SH)**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--pool sh" moon run alpha
```

**深圳证券交易所 (SZ)**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--pool sz" moon run alpha
```

### 按板块筛选

**主板**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--board main" moon run alpha
```

**创业板**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--board chinext" moon run alpha
```

**科创板**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--board star" moon run alpha
```

### 自定义股票池

创建自定义股票列表文件 `my_stocks.txt`:

```
sh.600000
sh.600001
sz.000001
```

使用自定义股票池:

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--pool-file my_stocks.txt" moon run alpha
```

### 行业股票池

按行业选择股票池:

```bash
# 银行业
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--industry 银行" moon run alpha

# 医药行业
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--industry 医药生物" moon run alpha

# 科技行业
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--industry 计算机" moon run alpha
```

**获取行业列表**:

```bash
curl http://localhost:8080/api/industries
```

---

## 基础筛选

### 市值筛选

**最小市值** (单位：元):
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-market-cap 10000000000" moon run alpha
# 筛选市值大于 100 亿元的股票
```

**最大市值**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--max-market-cap 500000000000" moon run alpha
# 筛选市值小于 500 亿元的股票
```

**市值范围**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-market-cap 10000000000 --max-market-cap 100000000000" moon run alpha
# 筛选市值在 100 亿到 1000 亿之间的股票
```

### 市盈率 (PE) 筛选

**最大市盈率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--max-pe 20" moon run alpha
# 筛选市盈率低于 20 的股票
```

**最小市盈率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-pe 5" moon run alpha
# 筛选市盈率高于 5 的股票
```

**市盈率范围**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-pe 10 --max-pe 30" moon run alpha
```

**负市盈率处理**:
```bash
# 排除亏损股票 (PE 为负)
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--exclude-losses" moon run alpha
```

### 市净率 (PB) 筛选

**最大市净率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--max-pb 3" moon run alpha
# 筛选市净率低于 3 的股票
```

**市净率范围**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-pb 0.5 --max-pb 2" moon run alpha
# 筛选破净股 (PB < 1) 和低市净率股票
```

### 股价筛选

**最低股价**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-price 10" moon run alpha
# 筛选股价高于 10 元的股票
```

**最高股价**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--max-price 100" moon run alpha
```

### 成交量筛选

**最小成交量** (股):
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-volume 1000000" moon run alpha
# 筛选日均成交量大于 100 万股的股票
```

**最小成交额** (元):
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-turnover 10000000" moon run alpha
# 筛选日均成交额大于 1000 万元的股票
```

### 换手率筛选

**最小换手率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-turnover-rate 0.01" moon run alpha
# 筛选换手率大于 1% 的股票
```

**最大换手率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--max-turnover-rate 0.10" moon run alpha
# 筛选换手率小于 10% 的股票，排除过度炒作
```

### 股息率筛选

**最小股息率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-dividend-yield 0.03" moon run alpha
# 筛选股息率大于 3% 的股票
```

### 综合基础筛选示例

**价值股筛选**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-market-cap 10000000000
  --max-pe 20
  --max-pb 2
  --min-dividend-yield 0.03
  --exclude-losses
" moon run alpha
```

**成长股筛选**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-market-cap 5000000000
  --max-market-cap 100000000000
  --min-pe 20
  --max-pe 50
  --min-revenue-growth 0.20
" moon run alpha
```

---

## 技术指标筛选

### 移动平均线筛选

**价格在均线上方**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --ma-period 20
  --price-above-ma
" moon run alpha
# 筛选价格在 20 日均线上方的股票
```

**均线多头排列**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --ma-bullish
" moon run alpha
# 筛选 5 日>10 日>20 日>60 日的股票
```

**均线金叉**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --ma-cross
  --fast-period 5
  --slow-period 20
" moon run alpha
# 筛选 5 日均线上穿 20 日均线的股票
```

### MACD 筛选

**MACD 金叉**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --macd-bullish
" moon run alpha
```

**MACD 零轴上方**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --macd-above-zero
" moon run alpha
```

**MACD 柱状图放大**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --macd-histogram-increasing
" moon run alpha
```

### RSI 筛选

**RSI 超卖**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --rsi-oversold
  --rsi-threshold 30
" moon run alpha
# 筛选 RSI 低于 30 的股票
```

**RSI 超买**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --rsi-overbought
  --rsi-threshold 70
" moon run alpha
```

**RSI 强势区**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --rsi-min 50
  --rsi-max 70
" moon run alpha
# 筛选 RSI 在 50-70 之间的强势股票
```

### 布林带筛选

**布林带挤压**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --bollinger-squeeze
  --squeeze-threshold 0.1
" moon run alpha
# 筛选布林带带宽小于 10% 的股票
```

**突破上轨**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --price-above-bollinger-upper
" moon run alpha
```

**跌破下轨**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --price-below-bollinger-lower
" moon run alpha
```

### 成交量指标筛选

**OBV 上升**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --obv-increasing
  --obv-period 5
" moon run alpha
# 筛选 5 日 OBV 持续上升的股票
```

**放量上涨**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --volume-price-up
" moon run alpha
# 筛选价格上涨且成交量放大的股票
```

### 综合技术指标筛选示例

**趋势突破策略**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --price-above-ma
  --ma-period 20
  --macd-bullish
  --volume-price-up
" moon run alpha
```

**超卖反弹策略**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --rsi-oversold
  --price-below-bollinger-lower
  --macd-bullish
" moon run alpha
```

---

## 财务指标筛选

### 成长性指标

**营收增长率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-revenue-growth 0.20
" moon run alpha
# 筛选营收增长率大于 20% 的股票
```

**净利润增长率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-profit-growth 0.25
" moon run alpha
```

**净资产收益率 (ROE)**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-roe 0.15
" moon run alpha
# 筛选 ROE 大于 15% 的股票
```

### 盈利性指标

**毛利率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-gross-margin 0.30
" moon run alpha
# 筛选毛利率大于 30% 的股票
```

**净利率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-net-margin 0.10
" moon run alpha
```

### 偿债能力指标

**资产负债率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --max-debt-to-asset 0.60
" moon run alpha
# 筛选资产负债率低于 60% 的股票
```

**流动比率**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-current-ratio 1.5
" moon run alpha
```

### 现金流指标

**经营性现金流**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --positive-operating-cashflow
" moon run alpha
# 筛选经营性现金流为正的股票
```

**现金流与净利润比**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-cashflow-to-profit 1.0
" moon run alpha
```

### 综合财务筛选示例

**优质成长股**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --min-revenue-growth 0.20
  --min-profit-growth 0.25
  --min-roe 0.15
  --min-gross-margin 0.30
  --max-debt-to-asset 0.50
" moon run alpha
```

**价值投资选股**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --max-pe 15
  --max-pb 1.5
  --min-roe 0.10
  --min-dividend-yield 0.04
  --positive-operating-cashflow
" moon run alpha
```

---

## 选股策略保存

### 保存策略配置

**保存为 JSON 文件**:

创建 `my_strategy.json`:

```json
{
  "name": "价值成长策略",
  "description": "筛选低估值高成长的股票",
  "filters": {
    "fundamental": {
      "min_market_cap": 10000000000,
      "max_pe": 25,
      "min_roe": 0.15,
      "min_revenue_growth": 0.20
    },
    "technical": {
      "price_above_ma": true,
      "ma_period": 20,
      "rsi_min": 50
    }
  }
}
```

**加载策略文件**:

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --strategy-file my_strategy.json
" moon run alpha
```

### Web 界面保存策略

1. 在 Web 界面配置筛选条件
2. 点击"保存策略"按钮
3. 输入策略名称和描述
4. 策略保存到本地存储

**加载已保存策略**:

1. 点击"加载策略"按钮
2. 从下拉列表中选择策略
3. 条件自动填充

### 策略分享

**导出策略**:

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --export-strategy my_strategy.json
" moon run alpha
```

**导入策略**:

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --import-strategy shared_strategy.json
" moon run alpha
```

---

## 结果展示与导出

### 结果展示格式

**表格视图** (Web):
- 股票代码
- 股票名称
- 当前价格
- 涨跌幅
- 市值
- 市盈率
- 筛选条件匹配情况

**列表视图** (CLI):
```bash
股票代码      名称        价格     涨跌幅    市值 (亿)   PE
sh.600000    浦发银行    10.25   +2.5%     2850      5.2
sh.600001    邯郸钢铁    8.50    +1.2%     450       8.1
```

### 导出结果

**导出为 CSV**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --export-csv results.csv
" moon run alpha
```

**导出为 Excel**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --export-excel results.xlsx
" moon run alpha
```

**导出为 JSON**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --export-json results.json
" moon run alpha
```

### 结果排序

**按市值排序**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --sort-by market-cap
  --sort-order desc
" moon run alpha
```

**按市盈率排序**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --sort-by pe
  --sort-order asc
" moon run alpha
```

**按涨跌幅排序**:
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --sort-by change-percent
  --sort-order desc
" moon run alpha
```

---

## 定时筛选任务

### 设置定时任务

**每日筛选**:
```bash
# 使用系统 cron
0 9 * * * MOONBIT_CMD=stock-screener MOONBIT_ARGS="--strategy-file daily_strategy.json --export-csv /path/to/results.csv" moon run alpha
```

**每周一筛选**:
```bash
0 9 * * 1 MOONBIT_CMD=stock-screener MOONBIT_ARGS="--strategy-file weekly_strategy.json" moon run alpha
```

### 筛选结果通知

**邮件通知** (需要配置邮件服务):
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --notify-email user@example.com
  --smtp-server smtp.example.com
" moon run alpha
```

---

## 常见问题

### Q1: 为什么筛选结果为空？

**可能原因**:
1. 筛选条件过于严格
2. 数据未更新
3. 股票池选择错误

**解决方法**:
1. 放宽筛选条件
2. 检查数据更新状态
3. 确认股票池配置

### Q2: 如何更新股票数据？

```bash
# 使用数据下载脚本
python script/data_download/enhanced_downloader.py --update
```

### Q3: 筛选速度慢怎么办？

**优化建议**:
1. 缩小股票池范围
2. 减少筛选条件数量
3. 使用缓存数据

### Q4: 如何筛选次新股？

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --listing-days-max 250
" moon run alpha
# 筛选上市不满一年的股票
```

### Q5: 如何筛选 ST 股票？

```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --include-st
" moon run alpha
# 默认排除 ST 股票
```

### Q6: 多条件筛选如何组合？

所有条件默认为"与" (AND) 关系，即股票必须满足所有条件。

```bash
# 同时满足：PE < 20, ROE > 15%, 价格在 20 日均线上方
MOONBIT_CMD=stock-screener MOONBIT_ARGS="
  --max-pe 20
  --min-roe 0.15
  --price-above-ma
  --ma-period 20
" moon run alpha
```

---

## 附录

### A. 命令行参数速查

| 参数 | 说明 | 示例 |
|------|------|------|
| `--pool` | 股票池 | `all`, `sh`, `sz` |
| `--industry` | 行业 | `银行`, `医药生物` |
| `--min-market-cap` | 最小市值 | `10000000000` |
| `--max-pe` | 最大市盈率 | `20` |
| `--min-roe` | 最小 ROE | `0.15` |
| `--price-above-ma` | 价格在均线上方 | - |
| `--macd-bullish` | MACD 金叉 | - |
| `--rsi-oversold` | RSI 超卖 | - |
| `--export-csv` | 导出 CSV | `results.csv` |

### B. 行业代码参考

| 行业名称 | 代码 |
|----------|------|
| 货币金融服务 | J66 |
| 医药制造业 | C27 |
| 计算机通信 | C39 |
| 电气设备 | C38 |

### C. 筛选条件优先级

1. 股票池过滤
2. 基础条件过滤
3. 技术指标过滤
4. 财务指标过滤
5. 结果排序

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
