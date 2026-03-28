# Stock Screener UI Components

This directory contains reusable UI components for the stock screening system.

## Components Overview

### 1. Indicator Card (`indicator-card.js`, `indicator-card.css`)

Display indicator cards with help tooltips showing calculation formulas and descriptions.

**Usage:**
```javascript
import * as indicatorModule from './components/indicator-card.js';

// Create a single card
const card = indicatorModule.createIndicatorCard(indicatorData, selected);

// Create indicator grid
const grid = indicatorModule.createIndicatorGrid(indicatorList, selectedIds);

// Setup click handlers
indicatorModule.setupIndicatorHandlers(container, onSelect, onDeselect);

// Get indicator by ID
const indicator = indicatorModule.getIndicatorById('ma');
```

**Available Indicator Categories:**
- `market` - Market indicators (price, volume, turnover, etc.)
- `tech` - Technical indicators (MA, MACD, KDJ, RSI, BOLL, etc.)
- `finance` - Financial indicators (PE, PB, ROE, etc.)

### 2. Filter Controls (`filter-controls.js`, `filter-controls.css`)

Build filter condition UI with operators, value inputs, and weight sliders.

**Usage:**
```javascript
import * as filterModule from './components/filter-controls.js';

// Create filter control
const filter = filterModule.createFilterControl({
  indicatorId: 'pe',
  indicatorName: '市盈率',
  operator: '>',
  value: '20',
  enabled: true,
  weight: 50
});

// Setup handlers
filterModule.setupFilterHandlers(container, {
  onOperatorChange: (id, operator) => {},
  onValueChange: (id, values) => {},
  onEnabledChange: (id, enabled) => {},
  onWeightChange: (id, weight) => {},
  onRemove: (id) => {}
});

// Collect filter values
const filters = filterModule.collectFilterValues(container);

// Serialize for API
const apiFilters = filterModule.serializeFilters(filters);
```

**Supported Operators:**
- `>` 大于
- `>=` 大于等于
- `<` 小于
- `<=` 小于等于
- `=` 等于
- `!=` 不等于
- `between` 介于

### 3. Results Display (`results-display.js`, `results-display.css`)

Display sortable, paginated results with export functionality.

**Usage:**
```javascript
import * as resultsModule from './components/results-display.js';

// Create results table
const table = resultsModule.createResultsTable({
  columns: resultsModule.getDefaultStockColumns(),
  data: stockData,
  sortable: true,
  paginated: true,
  pageSize: 20
});

// Create summary cards
const stats = resultsModule.calculateStats(data);
const cards = resultsModule.createSummaryCards(stats);

// Create score distribution chart
const chart = resultsModule.createScoreDistributionChart(data, 'chart-container-id');
```

**Default Columns:**
- Rank (排名)
- Code (代码)
- Name (名称)
- Score (综合得分)
- PE (市盈率)
- PB (市净率)
- ROE (净资产收益率)
- Actions (操作)

### 4. Trading Model Selector (`trading-model-selector.js`, `trading-model-selector.css`)

Visual trading strategy builder with entry/exit signals and position management.

**Usage:**
```javascript
import * as modelModule from './components/trading-model-selector.js';

// Get available models
const entryModels = modelModule.tradingModels.entry;
const exitModels = modelModule.tradingModels.exit;
const positionModels = modelModule.tradingModels.position;

// Create model card
const card = modelModule.createModelCard(modelData, selected);

// Create parameter editor
const editor = modelModule.createParameterEditor(modelData, values);

// Get parameter values
const paramValues = modelModule.getParameterValues(editor);

// Create visual builder
const builder = modelModule.createModelBuilder();

// Create strategy summary
const summary = modelModule.createStrategySummary(config);
```

**Available Strategy Categories:**
- `trend` - 趋势跟踪
- `momentum` - 动量策略
- `mean_reversion` - 均值回归
- `volatility` - 波动率策略
- `volume` - 成交量策略

## Complete Example

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="components/indicator-card.css">
  <link rel="stylesheet" href="components/filter-controls.css">
  <link rel="stylesheet" href="components/results-display.css">
  <style>
    .screener-container {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      padding: 20px;
    }
  </style>
</head>
<body>
  <div class="screener-container">
    <div id="indicator-panel"></div>
    <div id="results-panel"></div>
  </div>

  <script type="module">
    import * as indicatorModule from './components/indicator-card.js';
    import * as resultsModule from './components/results-display.js';

    // Initialize indicators
    const indicators = indicatorModule.getIndicatorsByCategory('tech');
    const indicatorPanel = document.getElementById('indicator-panel');
    indicatorPanel.appendChild(indicatorModule.createIndicatorGrid(indicators));

    // Setup handlers
    indicatorModule.setupIndicatorHandlers(indicatorPanel, (id) => {
      console.log('Selected indicator:', id);
    });

    // Mock results data
    const results = [
      { code: '600000', name: '浦发银行', score: 85.5, pe: 6.2, pb: 0.5, roe: 8.5 },
      { code: '600036', name: '招商银行', score: 92.3, pe: 7.8, pb: 1.2, roe: 15.2 }
    ];

    // Display results
    const resultsPanel = document.getElementById('results-panel');
    const table = resultsModule.createResultsTable({
      columns: resultsModule.getDefaultStockColumns(),
      data: results
    });
    resultsPanel.appendChild(table);
  </script>
</body>
</html>
```

## Styling Guidelines

All components follow the Ant Design color palette:
- Primary: `#1890ff`
- Success: `#52c41a`
- Warning: `#faad14`
- Error: `#ff4d4f`
- Text: `#333`, `#666`, `#999`
- Background: `#fff`, `#fafafa`, `#f5f5f5`
- Border: `#e8e8e8`, `#d9d9d9`

## Browser Compatibility

- Chrome/Edge: Latest 2 versions
- Firefox: Latest 2 versions
- Safari: Latest 2 versions

## API Integration

For backend integration, see the API documentation at `/docs/api-endpoints.md`.

Key endpoints:
- `GET /api/stocks` - Get stock list
- `POST /api/stocks/filter` - Filter stocks
- `GET /api/stocks/:code/klines` - Get K-line data
- `POST /api/backtest` - Run backtest
