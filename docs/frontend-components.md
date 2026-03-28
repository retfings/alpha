# 前端组件文档

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [组件概述](#组件概述)
2. [Indicator Card 组件](#indicator-card-组件)
3. [Filter Controls 组件](#filter-controls-组件)
4. [Results Display 组件](#results-display-组件)
5. [Trading Model Selector 组件](#trading-model-selector-组件)
6. [页面结构](#页面结构)
7. [样式规范](#样式规范)
8. [API 集成](#api 集成)

---

## 组件概述

股票筛选器前端由以下核心组件构成：

| 组件 | 文件 | 说明 |
|------|------|------|
| Indicator Card | `indicator-card.js`, `indicator-card.css` | 指标卡片展示 |
| Filter Controls | `filter-controls.js`, `filter-controls.css` | 筛选条件控制 |
| Results Display | `results-display.js`, `results-display.css` | 结果展示 |
| Trading Model Selector | `trading-model-selector.js`, `trading-model-selector.css` | 交易模型选择器 |

### 组件依赖关系

```
screener.html
├── indicator-card.js (指标卡片)
├── filter-controls.js (筛选控制)
├── results-display.js (结果展示)
└── trading-model-selector.js (模型选择)
```

### 文件位置

```
www/
├── components/
│   ├── indicator-card.js
│   ├── indicator-card.css
│   ├── filter-controls.js
│   ├── filter-controls.css
│   ├── results-display.js
│   ├── results-display.css
│   ├── trading-model-selector.js
│   └── trading-model-selector.css
├── screener.html
├── screener.js
├── screener.css
├── index.html
├── app.js
└── styles.css
```

---

## Indicator Card 组件

### 功能说明

展示技术指标卡片，包含帮助提示（tooltip）显示计算公式和描述。

### API 参考

#### `createIndicatorCard(indicatorData, selected)`

创建单个指标卡片。

**参数**:
- `indicatorData`: 指标数据对象
  - `id`: 指标 ID
  - `name`: 指标名称
  - `category`: 分类 (market/tech/finance)
  - `description`: 描述
  - `formula`: 计算公式
- `selected`: 是否已选中 (boolean)

**返回值**: HTMLDivElement - 卡片 DOM 元素

**示例**:
```javascript
import * as indicatorModule from './components/indicator-card.js';

const card = indicatorModule.createIndicatorCard({
  id: 'ma',
  name: '移动平均线',
  category: 'tech',
  description: '平滑价格数据并识别趋势方向',
  formula: 'SMA = (P1 + P2 + ... + Pn) / n'
}, false);
```

#### `createIndicatorGrid(indicatorList, selectedIds)`

创建指标网格布局。

**参数**:
- `indicatorList`: 指标数组
- `selectedIds`: 已选中的指标 ID 数组

**返回值**: DocumentFragment - 包含所有卡片的片段

**示例**:
```javascript
const indicators = indicatorModule.getIndicatorsByCategory('tech');
const grid = indicatorModule.createIndicatorGrid(indicators, ['ma', 'macd']);
document.getElementById('indicator-panel').appendChild(grid);
```

#### `setupIndicatorHandlers(container, onSelect, onDeselect)`

设置指标点击事件处理器。

**参数**:
- `container`: 容器 DOM 元素
- `onSelect(id)`: 选中回调函数
- `onDeselect(id)`: 取消选中回调函数

**示例**:
```javascript
indicatorModule.setupIndicatorHandlers(
  document.getElementById('indicator-panel'),
  (id) => console.log('选中指标:', id),
  (id) => console.log('取消选中:', id)
);
```

#### `getIndicatorById(id)`

根据 ID 获取指标信息。

**参数**:
- `id`: 指标 ID

**返回值**: 指标数据对象

**示例**:
```javascript
const maIndicator = indicatorModule.getIndicatorById('ma');
console.log(maIndicator.formula); // 输出公式
```

### 指标分类

| 分类 | 说明 | 包含指标 |
|------|------|----------|
| `market` | 市场指标 | 价格、成交量、换手率等 |
| `tech` | 技术指标 | MA、MACD、KDJ、RSI、BOLL 等 |
| `finance` | 财务指标 | PE、PB、ROE 等 |

### 样式类

```css
.indicator-card { }          /* 卡片容器 */
.indicator-card.selected { } /* 选中状态 */
.indicator-name { }          /* 指标名称 */
.indicator-formula { }       /* 公式展示 */
.tooltip { }                 /* 提示框 */
```

---

## Filter Controls 组件

### 功能说明

构建筛选条件 UI，包含操作符选择、值输入和权重滑块。

### API 参考

#### `createFilterControl(config)`

创建单个筛选控件。

**参数**:
```javascript
{
  indicatorId: 'pe',        // 指标 ID
  indicatorName: '市盈率',   // 指标名称
  operator: '>',            // 操作符
  value: '20',              // 值
  enabled: true,            // 是否启用
  weight: 50                // 权重 (0-100)
}
```

**返回值**: HTMLDivElement - 控件 DOM 元素

**示例**:
```javascript
import * as filterModule from './components/filter-controls.js';

const filter = filterModule.createFilterControl({
  indicatorId: 'pe',
  indicatorName: '市盈率',
  operator: '>',
  value: '20',
  enabled: true,
  weight: 50
});
```

#### `setupFilterHandlers(container, callbacks)`

设置筛选控件事件处理器。

**参数**:
- `container`: 容器 DOM 元素
- `callbacks`: 回调函数对象
  - `onOperatorChange(id, operator)`: 操作符变化
  - `onValueChange(id, values)`: 值变化
  - `onEnabledChange(id, enabled)`: 启用状态变化
  - `onWeightChange(id, weight)`: 权重变化
  - `onRemove(id)`: 移除筛选

**示例**:
```javascript
filterModule.setupFilterHandlers(
  document.getElementById('filter-panel'),
  {
    onOperatorChange: (id, op) => updateFilter(id, { operator: op }),
    onValueChange: (id, vals) => updateFilter(id, { values: vals }),
    onEnabledChange: (id, en) => updateFilter(id, { enabled: en }),
    onWeightChange: (id, w) => updateFilter(id, { weight: w }),
    onRemove: (id) => removeFilter(id)
  }
);
```

#### `collectFilterValues(container)`

收集所有筛选值。

**参数**:
- `container`: 容器 DOM 元素

**返回值**: 筛选值数组

**示例**:
```javascript
const filters = filterModule.collectFilterValues(
  document.getElementById('filter-panel')
);
// 返回: [{ indicatorId: 'pe', operator: '>', value: '20', weight: 50 }, ...]
```

#### `serializeFilters(filters)`

序列化筛选器为 API 格式。

**参数**:
- `filters`: 筛选值数组

**返回值**: API 请求体对象

**示例**:
```javascript
const apiFilters = filterModule.serializeFilters(filters);
// 返回: { pe: { operator: '>', value: 20 }, ... }
```

### 支持的操作符

| 操作符 | 说明 | 示例 |
|--------|------|------|
| `>` | 大于 | PE > 20 |
| `>=` | 大于等于 | ROE >= 15 |
| `<` | 小于 | PB < 3 |
| `<=` | 小于等于 | PE <= 30 |
| `=` | 等于 | 行业 = 银行 |
| `!=` | 不等于 | 状态 != ST |
| `between` | 介于 | PE 介于 10-30 |

### 样式类

```css
.filter-control { }          /* 控件容器 */
.filter-operator { }         /* 操作符选择器 */
.filter-value-input { }      /* 值输入框 */
.filter-weight-slider { }    /* 权重滑块 */
.filter-remove-btn { }       /* 移除按钮 */
```

---

## Results Display 组件

### 功能说明

展示可排序、分页的结果，支持导出功能。

### API 参考

#### `createResultsTable(config)`

创建结果表格。

**参数**:
```javascript
{
  columns: [...],           // 列定义
  data: [...],              // 数据数组
  sortable: true,           // 是否可排序
  paginated: true,          // 是否分页
  pageSize: 20              // 每页数量
}
```

**返回值**: HTMLTableElement - 表格元素

**示例**:
```javascript
import * as resultsModule from './components/results-display.js';

const table = resultsModule.createResultsTable({
  columns: resultsModule.getDefaultStockColumns(),
  data: stockData,
  sortable: true,
  paginated: true,
  pageSize: 20
});
```

#### `getDefaultStockColumns()`

获取默认股票列定义。

**返回值**: 列定义数组

**列定义**:
```javascript
[
  { key: 'rank', title: '排名' },
  { key: 'code', title: '代码' },
  { key: 'name', title: '名称' },
  { key: 'score', title: '综合得分' },
  { key: 'pe', title: '市盈率' },
  { key: 'pb', title: '市净率' },
  { key: 'roe', title: '净资产收益率' },
  { key: 'actions', title: '操作' }
]
```

#### `calculateStats(data)`

计算统计数据。

**参数**:
- `data`: 数据数组

**返回值**: 统计数据对象

**示例**:
```javascript
const stats = resultsModule.calculateStats(stockData);
// 返回: { count: 100, avgScore: 75.5, maxScore: 95.2, ... }
```

#### `createSummaryCards(stats)`

创建统计摘要卡片。

**参数**:
- `stats`: 统计数据对象

**返回值**: HTMLDivElement - 卡片容器

**示例**:
```javascript
const cards = resultsModule.createSummaryCards(stats);
document.getElementById('stats-panel').appendChild(cards);
```

#### `createScoreDistributionChart(data, containerId)`

创建得分分布图表（使用 Chart.js）。

**参数**:
- `data`: 数据数组
- `containerId`: 容器元素 ID

**返回值**: Chart 实例

**示例**:
```javascript
const chart = resultsModule.createScoreDistributionChart(
  stockData,
  'chart-container'
);
```

### 样式类

```css
.results-table { }         /* 表格容器 */
.results-header { }        /* 表头 */
.results-row { }           /* 数据行 */
.results-cell { }          /* 单元格 */
.sort-indicator { }        /* 排序指示器 */
.pagination { }            /* 分页控件 */
.export-buttons { }        /* 导出按钮 */
```

---

## Trading Model Selector 组件

### 功能说明

可视化交易策略构建器，包含入场/出场信号和仓位管理配置。

### API 参考

#### `tradingModels`

可用交易模型配置。

**结构**:
```javascript
{
  entry: [...],      // 入场模型
  exit: [...],       // 出场模型
  position: [...]    // 仓位模型
}
```

**示例**:
```javascript
import * as modelModule from './components/trading-model-selector.js';

const entryModels = modelModule.tradingModels.entry;
const exitModels = modelModule.tradingModels.exit;
const positionModels = modelModule.tradingModels.position;
```

#### `createModelCard(modelData, selected)`

创建模型卡片。

**参数**:
- `modelData`: 模型数据对象
  - `id`: 模型 ID
  - `name`: 模型名称
  - `category`: 分类
  - `description`: 描述
  - `parameters`: 参数配置
- `selected`: 是否已选中

**返回值**: HTMLDivElement - 卡片元素

**示例**:
```javascript
const card = modelModule.createModelCard({
  id: 'ma_cross',
  name: '均线交叉策略',
  category: 'trend',
  description: '基于均线交叉的入场信号',
  parameters: {
    fast_period: { type: 'number', default: 10 },
    slow_period: { type: 'number', default: 30 }
  }
}, false);
```

#### `createParameterEditor(modelData, values)`

创建参数编辑器。

**参数**:
- `modelData`: 模型数据对象
- `values`: 当前参数值

**返回值**: HTMLDivElement - 编辑器元素

**示例**:
```javascript
const editor = modelModule.createParameterEditor(
  modelData,
  { fast_period: 10, slow_period: 30 }
);
```

#### `getParameterValues(editor)`

获取参数值。

**参数**:
- `editor`: 参数编辑器 DOM 元素

**返回值**: 参数值对象

**示例**:
```javascript
const params = modelModule.getParameterValues(editor);
// 返回: { fast_period: 10, slow_period: 30 }
```

#### `createModelBuilder()`

创建可视化策略构建器。

**返回值**: HTMLDivElement - 构建器容器

**示例**:
```javascript
const builder = modelModule.createModelBuilder();
document.getElementById('builder-panel').appendChild(builder);
```

#### `createStrategySummary(config)`

创建策略摘要。

**参数**:
- `config`: 策略配置对象

**返回值**: HTMLDivElement - 摘要展示

**示例**:
```javascript
const summary = modelModule.createStrategySummary({
  entry_model: 'ma_cross',
  exit_model: 'stop_loss',
  position_size: 0.8
});
```

### 策略分类

| 分类 | 说明 | 示例模型 |
|------|------|----------|
| `trend` | 趋势跟踪 | 均线交叉、趋势突破 |
| `momentum` | 动量策略 | RSI 动量、MACD 动量 |
| `mean_reversion` | 均值回归 | 布林带回归 |
| `volatility` | 波动率策略 | 波动率突破 |
| `volume` | 成交量策略 | OBV 成交量 |

### 样式类

```css
.model-card { }            /* 模型卡片 */
.model-card.selected { }   /* 选中状态 */
.parameter-editor { }      /* 参数编辑器 */
.parameter-field { }       /* 参数字段 */
.strategy-builder { }      /* 策略构建器 */
.strategy-summary { }      /* 策略摘要 */
```

---

## 页面结构

### screener.html - 股票筛选器主页面

```html
<!DOCTYPE html>
<html>
<head>
  <title>股票筛选器</title>
  <link rel="stylesheet" href="components/indicator-card.css">
  <link rel="stylesheet" href="components/filter-controls.css">
  <link rel="stylesheet" href="components/results-display.css">
  <link rel="stylesheet" href="screener.css">
</head>
<body>
  <div class="screener-container">
    <!-- 左侧面板 -->
    <div class="left-panel">
      <div id="indicator-panel"></div>     <!-- 指标选择 -->
      <div id="filter-panel"></div>        <!-- 筛选条件 -->
      <div id="model-panel"></div>         <!-- 交易模型 -->
    </div>

    <!-- 右侧面板 -->
    <div class="right-panel">
      <div id="stats-panel"></div>         <!-- 统计摘要 -->
      <div id="results-panel"></div>       <!-- 结果展示 -->
    </div>
  </div>

  <script type="module" src="screener.js"></script>
</body>
</html>
```

### index.html - 主页面

```html
<!DOCTYPE html>
<html>
<head>
  <title>量化回测系统</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <nav class="main-nav">
    <a href="index.html">首页</a>
    <a href="screener.html">股票筛选</a>
    <a href="trading-models.html">交易模型</a>
  </nav>

  <main class="main-content">
    <!-- 主要内容 -->
  </main>

  <script type="module" src="app.js"></script>
</body>
</html>
```

### trading-models.html - 交易模型配置页面

```html
<!DOCTYPE html>
<html>
<head>
  <title>交易模型</title>
  <link rel="stylesheet" href="components/trading-model-selector.css">
  <link rel="stylesheet" href="trading-models.css">
</head>
<body>
  <div class="model-builder-container">
    <div id="entry-model-panel"></div>     <!-- 入场模型 -->
    <div id="exit-model-panel"></div>      <!-- 出场模型 -->
    <div id="position-panel"></div>        <!-- 仓位管理 -->
    <div id="strategy-summary-panel"></div><!-- 策略摘要 -->
  </div>

  <script type="module" src="trading-models.js"></script>
</body>
</html>
```

---

## 样式规范

### 颜色调色板

使用 Ant Design 颜色系统：

| 用途 | 颜色值 |
|------|--------|
| Primary | `#1890ff` |
| Success | `#52c41a` |
| Warning | `#faad14` |
| Error | `#ff4d4f` |
| Text Primary | `#333` |
| Text Secondary | `#666` |
| Text Disabled | `#999` |
| Background | `#fff`, `#fafafa`, `#f5f5f5` |
| Border | `#e8e8e8`, `#d9d9d9` |

### 组件样式约定

```css
/* 卡片容器 */
.component-card {
  background: #fff;
  border: 1px solid #e8e8e8;
  border-radius: 4px;
  padding: 16px;
  margin-bottom: 16px;
  transition: all 0.3s;
}

.component-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.component-card.selected {
  border-color: #1890ff;
  background: #e6f7ff;
}

/* 按钮样式 */
.btn-primary {
  background: #1890ff;
  color: #fff;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary:hover {
  background: #40a9ff;
}

/* 输入框样式 */
.input-control {
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  padding: 6px 12px;
  font-size: 14px;
}

.input-control:focus {
  border-color: #1890ff;
  outline: none;
}
```

### 响应式设计

```css
/* 桌面布局 */
.screener-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

/* 平板布局 */
@media (max-width: 1024px) {
  .screener-container {
    grid-template-columns: 1fr;
  }
}

/* 移动布局 */
@media (max-width: 768px) {
  .left-panel, .right-panel {
    padding: 8px;
  }
}
```

---

## API 集成

### 核心 API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `GET /api/stocks` | GET | 获取股票列表 |
| `POST /api/stocks/filter` | POST | 筛选股票 |
| `GET /api/stocks/:code/klines` | GET | 获取 K 线数据 |
| `POST /api/backtest` | POST | 运行回测 |
| `GET /api/indicators` | GET | 获取指标列表 |
| `POST /api/screen` | POST | 执行筛选 |

### API.js 封装

```javascript
// www/api.js 封装了所有 API 调用

// 获取股票列表
api.getStocks({ exchange, limit, offset });

// 筛选股票
api.filterStocks(filters);

// 获取 K 线数据
api.getKlines(code, { start, end, frequency });

// 运行回测
api.runBacktest({
  stock_code,
  strategy,
  start_date,
  end_date,
  initial_capital
});

// 获取指标列表
api.getIndicators();

// 执行筛选
api.screenStocks(criteria);
```

### 使用示例

```javascript
import * as api from './api.js';

// 获取股票列表
const stocks = await api.getStocks({ exchange: 'sh', limit: 100 });

// 筛选股票
const filtered = await api.filterStocks({
  industry: '银行',
  min_pe: 5,
  max_pe: 20
});

// 获取 K 线数据
const klines = await api.getKlines('sh.600000', {
  start: '2023-01-01',
  end: '2023-12-31',
  frequency: 'daily'
});

// 运行回测
const result = await api.runBacktest({
  stock_code: 'sh.600000',
  strategy: 'ma_cross',
  start_date: '2023-01-01',
  end_date: '2023-12-31',
  initial_capital: 100000
});
```

---

## 浏览器兼容性

| 浏览器 | 最低版本 |
|--------|----------|
| Chrome | 最新 2 个版本 |
| Edge | 最新 2 个版本 |
| Firefox | 最新 2 个版本 |
| Safari | 最新 2 个版本 |

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
