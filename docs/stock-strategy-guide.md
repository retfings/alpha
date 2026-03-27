# 股票策略页面使用文档

## 概述

股票策略页面是一个用于配置选股条件、设置筛选规则并运行回测的 Web 界面。该页面模仿了专业量化交易平台的交互设计，提供了直观的可视化配置方式。

## 快速开始

### 启动服务器

```bash
# 进入项目目录
cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha

# 启动服务器（默认端口 8000）
python run_server.py

# 或者指定端口
python run_server.py 3000
```

服务器启动后会自动打开浏览器访问股票策略页面。如果没有自动打开，可以手动访问：
- **股票策略页面**: http://localhost:8000/stock_strategy.html
- **主页 Dashboard**: http://localhost:8000/index.html

### 系统要求

- Python 3.6+
- 现代浏览器（Chrome、Firefox、Edge、Safari）

## 功能说明

### 1. 步骤导航

页面顶部提供 4 个步骤的流程导航：
1. **择股设置** - 配置股票池和选股条件
2. **交易模型** - 设置交易策略模型（待实现）
3. **大盘择时** - 配置大盘择时策略（待实现）
4. **股指对冲** - 设置对冲策略（待实现）

### 2. 择股设置

#### 股票池配置

- **我的股票池**: 选择自定义组合、关注列表或全部股票
- **系统股票池**: 选择沪深 300、中证 500、中证 1000 等

#### 基础筛选条件

| 条件 | 说明 |
|------|------|
| 指数成份 | 按指数成份股筛选 |
| 上市板块 | 主板/中小板/创业板 |
| 行业标准 | 申万 2014/2021/证监会分类 |
| 一级/二级行业 | 具体行业分类 |
| ST 股票 | 包含/排除/仅 ST 股票 |
| 交易所 | 上交所/深交所/北交所 |
| 地域板块 | 东部/中部/西部 |
| 企业性质 | 国企/民营/外资 |
| 融资融券 | 是否融资融券标的 |
| 科创板 | 包含/排除科创板 |
| 过滤停牌 | 排除停牌股票 |

#### 选股指标

提供 7 大类指标：

1. **行情** - 价格、成交量、换手率、成交额等
2. **技术指标** - MA、EMA、MACD、KDJ、RSI、BOLL 等
3. **财务指标** - PE、PB、ROE、ROA、毛利率等
4. **财报条目** - 营业收入、净利润、现金流等
5. **公司** - 员工人数、成立日期、注册资本
6. **分析师** - 评级、目标价、盈利预测
7. **大盘指标** - 市场 PE、PB、成交额

### 3. 选股条件

点击左侧指标列表中的任意指标，会添加到右侧条件表中。每个条件包含：

- **指标**: 选择的指标名称
- **比较符**: 大于/小于/等于/介于等
- **范围**: 可选的范围限制
- **值**: 具体的数值

### 4. 策略回测

在页面底部的回测区域配置回测参数：

- **回测时间**: 设置开始和结束日期
- **收益基准**: 沪深 300/中证 500/上证指数等
- **交易成本**: 千分之一/二/三或零成本
- **排除时间段**: 排除特定时间段

点击「开始回测」运行回测。

## 文件结构

```
www/
├── stock_strategy.html    # 股票策略页面 HTML
├── stock_strategy.css     # 样式文件
├── stock_strategy.js      # 交互逻辑
├── index.html             # 主页 Dashboard
├── app.js                 # 主页应用逻辑
├── api.js                 # API 接口封装
└── styles.css             # 主页样式

项目根目录/
├── run_server.py          # Python 启动脚本
└── docs/
    └── stock-strategy-guide.md  # 本文档
```

## API 接口（待实现）

当前前端页面使用模拟数据，完整功能需要后端支持以下 API：

### 策略管理

#### 获取已保存的策略列表
```
GET /api/strategies/saved
```

#### 保存策略
```
POST /api/strategies
Content-Type: application/json

{
  "name": "策略名称",
  "stock_pool": { ... },
  "filters": { ... },
  "conditions": [ ... ],
  "backtest": { ... }
}
```

#### 获取策略详情
```
GET /api/strategies/:id
```

#### 更新策略
```
PUT /api/strategies/:id
Content-Type: application/json

{
  "name": "更新后的策略名称",
  ...
}
```

#### 删除策略
```
DELETE /api/strategies/:id
```

### 行业数据

#### 获取行业列表
```
GET /api/industries?standard=sw2014
```

参数：
- `standard`: 行业标准（sw2014, sw2021, csrc）

返回：
```json
[
  { "id": "agricultura", "name": "农林牧渔", "parent_id": null },
  { "id": "food", "name": "食品饮料", "parent_id": null }
]
```

### 股票筛选

#### 获取股票列表（带筛选）
```
POST /api/stocks/filter
Content-Type: application/json

{
  "exchange": "sh",
  "industry": "food",
  "exclude_st": true,
  ...
}
```

### 回测接口

#### 运行策略回测
```
POST /api/backtest/strategy
Content-Type: application/json

{
  "conditions": [
    { "field": "pe", "operator": "<", "value": "20" },
    { "field": "roe", "operator": ">", "value": "0.15" }
  ],
  "start_date": "2025-01-01",
  "end_date": "2026-03-27",
  "benchmark": "hs300",
  "transaction_cost": 0.0002,
  "exclude_period": false
}
```

#### 每日选股
```
POST /api/backtest/daily
Content-Type: application/json

{
  "strategy": { ... },
  "date": "2026-03-27"
}
```

#### 实时选股
```
POST /api/backtest/realtime
Content-Type: application/json

{
  "strategy": { ... }
}
```

#### 排名分析
```
POST /api/backtest/ranking
Content-Type: application/json

{
  "strategy": { ... },
  "period": "monthly"
}
```

### 基准指数

#### 获取基准指数数据
```
GET /api/benchmark?code=hs300&start=2025-01-01&end=2026-03-27
```

参数：
- `code`: 基准代码（hs300, zz500, zz1000, sh, sz）
- `start`: 开始日期
- `end`: 结束日期

## 扩展开发

### 添加新的选股指标

编辑 `stock_strategy.js`，在 `indicatorData` 对象中添加：

```javascript
const indicatorData = {
  // ... 现有指标
  tech: [
    // 现有技术指标
    { id: 'new_indicator', name: '新指标名称' }
  ]
};
```

### 添加新的筛选条件

编辑 `stock_strategy.html`，在 `.filter-grid` 中添加：

```html
<div class="filter-item">
  <label>新条件：</label>
  <select id="new-filter" class="form-select">
    <option value="all">全部</option>
    <option value="option1">选项 1</option>
  </select>
</div>
```

### 自定义回测逻辑

编辑 `stock_strategy.js` 中的 `runBacktest()` 函数，添加实际的 API 调用：

```javascript
async function runBacktest() {
  const config = { ... };

  const response = await fetch('/api/backtest', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config)
  });

  const result = await response.json();
  // 处理回测结果
}
```

## 常见问题

### Q: 页面样式显示异常？
A: 确保浏览器支持 CSS Grid 和 Flexbox 布局，建议使用最新版 Chrome 或 Firefox。

### Q: 回测没有反应？
A: 当前版本回测功能需要后端 API 支持，前端仅做演示。

### Q: 如何保存策略？
A: 点击右上角「保存」按钮，会弹出输入框输入策略名称。当前版本保存到本地控制台，实际使用需要对接后端 API。

## 更新日志

- **v0.1.0** (2026-03-27)
  - 初始版本
  - 实现择股设置页面
  - 实现选股条件配置
  - 实现回测界面框架
