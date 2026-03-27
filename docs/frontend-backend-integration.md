# 前端 - 后端集成指南

本文档描述股票策略系统前端（www/）与后端 API 之间的集成规范，包括数据流、接口契约和通信协议。

## 架构概览

### 系统架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         前端层 (www/)                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  index.html     │  │  stock_         │  │  Dashboard      │ │
│  │  (主页)         │  │  strategy.html  │  │  (控制面板)     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                    │                    │           │
│           └────────────────────┼────────────────────┘           │
│                                │                                │
│                     ┌──────────▼──────────┐                     │
│                     │     api.js          │                     │
│                     │  (API 客户端封装)    │                     │
│                     └──────────┬──────────┘                     │
└────────────────────────────────┼────────────────────────────────┘
                                 │ HTTP/JSON
                                 │
┌────────────────────────────────┼────────────────────────────────┐
│                         后端层 (server/)                         │
│                                │                                │
│                     ┌──────────▼──────────┐                     │
│                     │   server.mbt        │                     │
│                     │   (HTTP 服务器)      │                     │
│                     └──────────┬──────────┘                     │
│                                │                                │
│           ┌────────────────────┼────────────────────┐           │
│           │                    │                    │           │
│  ┌────────▼────────┐  ┌────────▼────────┐  ┌────────▼────────┐ │
│  │  routes.mbt     │  │  backtest/      │  │  data/          │ │
│  │  (路由处理)     │  │  (回测引擎)     │  │  (数据加载)     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 通信模式

- **协议**: HTTP/1.1
- **数据格式**: JSON
- **编码**: UTF-8
- **CORS**: 支持同源请求

---

## 前端架构

### 目录结构

```
www/
├── index.html              # 主页 Dashboard
├── stock_strategy.html     # 股票策略配置页面
├── app.js                  # 主页应用逻辑
├── stock_strategy.js       # 策略页面逻辑
├── api.js                  # API 客户端封装
├── styles.css              # 主页样式
├── stock_strategy.css      # 策略页面样式
└── charts/                 # 图表组件（如使用）
```

### 核心模块

#### api.js - API 客户端

`api.js` 提供统一的 API 访问接口，封装所有后端通信细节。

```javascript
// api.js 核心结构
const API = {
  // 基础配置
  baseURL: '',  // 开发时为空，生产时配置代理

  // 健康检查
  async health() {},

  // 股票相关
  async getStocks() {},
  async getStockInfo(code) {},
  async getKlines(code, params) {},

  // 回测相关
  async runBacktest(config) {},
  async getBacktestResult(id) {},

  // 回撤分析
  async getDrawdown(code, params) {},
  async getPortfolioDrawdown(stocks, weights) {},

  // 工具函数
  _handleError(response) {},
  _buildQueryString(params) {}
};
```

#### 前端数据流

```
用户交互 → 事件处理 → API 调用 → 数据更新 → UI 渲染
    │                                              │
    └────────────────── 反馈 ──────────────────────┘
```

---

## 后端架构

### 目录结构

```
server/
├── server.mbt              # HTTP 服务器主模块
├── routes.mbt              # 请求路由和处理
├── http_server.c           # C FFI HTTP 服务器实现
├── moon.pkg                # 包配置
└── routes/
    ├── backtest.mbt        # 回测路由（待扩展）
    ├── stocks.mbt          # 股票数据路由（待扩展）
    └── drawdown.mbt        # 回撤分析路由（待扩展）
```

### 请求处理流程

```
HTTP 请求 → parse_request_path() → route_request() → Handler → HttpResponse
```

### 响应格式

```moonbit
pub struct HttpResponse {
  status_code : Int
  body : String  // JSON 字符串
}
```

---

## API 接口契约

### 1. 健康检查

**端点**: `GET /api/health`

**前端调用**:
```javascript
// api.js
async health() {
  const response = await fetch('/api/health');
  return response.json();
}

// 使用
const status = await API.health();
console.log('服务状态:', status.status);
```

**后端响应**:
```json
{
  "status": "ok",
  "service": "moonbit-drawdown"
}
```

---

### 2. 获取股票列表

**端点**: `GET /api/stocks`

**前端调用**:
```javascript
// api.js
async getStocks(params = {}) {
  const query = this._buildQueryString(params);
  const response = await fetch(`/api/stocks${query ? '?' + query : ''}`);
  return response.json();
}

// 使用
const stocks = await API.getStocks({ exchange: 'sh', limit: 50 });
stocks.stocks.forEach(stock => {
  console.log(`${stock.code}: ${stock.name}`);
});
```

**后端响应**:
```json
{
  "stocks": [
    { "code": "sh.600000", "name": "Ping An Bank" },
    { "code": "sh.600001", "name": "PAIC" }
  ],
  "total": 2
}
```

---

### 3. 获取 K 线数据

**端点**: `GET /api/stocks/:code/klines`

**前端调用**:
```javascript
// api.js
async getKlines(code, params = {}) {
  const { start, end, frequency = 'daily', limit = 1000 } = params;
  const query = this._buildQueryString({ start, end, frequency, limit });
  const response = await fetch(`/api/stocks/${code}/klines${query ? '?' + query : ''}`);
  return response.json();
}

// 使用 - 在图表中展示 K 线
async function loadChart(stockCode) {
  const data = await API.getKlines(stockCode, {
    start: '2023-01-01',
    end: '2023-12-31'
  });

  // 转换为 Chart.js 格式
  const labels = data.klines.map(k => k.date);
  const prices = data.klines.map(k => k.close);

  renderChart(labels, prices);
}
```

**后端响应**:
```json
{
  "stock": "sh.600000",
  "klines": [
    {
      "date": "2023-01-03",
      "open": 10.50,
      "high": 10.85,
      "low": 10.42,
      "close": 10.78,
      "volume": 1250000,
      "amount": 13425000,
      "turn": 0.0125
    }
  ],
  "count": 1
}
```

---

### 4. 运行回测

**端点**: `POST /api/backtest`

**前端调用**:
```javascript
// api.js
async runBacktest(config) {
  const response = await fetch('/api/backtest', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config)
  });
  return response.json();
}

// 使用 - 在策略页面运行回测
async function runBacktest() {
  const config = {
    stock_code: selectedStock,
    strategy: selectedStrategy,
    start_date: startDate,
    end_date: endDate,
    initial_capital: parseFloat(capitalInput.value),
    commission_rate: 0.0003,
    slippage: 0.001
  };

  showLoading(true);
  try {
    const result = await API.runBacktest(config);
    displayBacktestResult(result);
  } catch (error) {
    showError('回测失败：' + error.message);
  } finally {
    showLoading(false);
  }
}
```

**前端请求示例**:
```json
{
  "stock_code": "sh.600000",
  "strategy": "ma_cross",
  "start_date": "2023-01-01",
  "end_date": "2023-12-31",
  "initial_capital": 100000,
  "commission_rate": 0.0003,
  "slippage": 0.001
}
```

**后端响应** (同步):
```json
{
  "status": "completed",
  "result": {
    "initial_capital": 100000,
    "final_capital": 115000,
    "total_return": 0.15,
    "max_drawdown": -0.085,
    "sharpe_ratio": 1.25,
    "total_trades": 24,
    "win_rate": 0.625,
    "equity_curve": [...],
    "trades": [...]
  }
}
```

---

### 5. 获取回撤分析

**端点**: `GET /api/drawdown/:code`

**前端调用**:
```javascript
// api.js
async getDrawdown(code, params = {}) {
  const query = this._buildQueryString(params);
  const response = await fetch(`/api/drawdown/${code}${query ? '?' + query : ''}`);
  return response.json();
}

// 使用 - 展示回撤分析
async function displayDrawdownAnalysis(stockCode) {
  const data = await API.getDrawdown(stockCode);

  // 更新 UI
  document.getElementById('current-drawdown').textContent =
    (data.drawdown.current * 100).toFixed(2) + '%';
  document.getElementById('max-drawdown').textContent =
    (data.drawdown.max * 100).toFixed(2) + '%';

  // 绘制回撤曲线
  renderDrawdownChart(data.analysis);
}
```

**后端响应**:
```json
{
  "stock": "sh.600000",
  "drawdown": {
    "current": -0.0245,
    "max": -0.1523,
    "avg": -0.0456,
    "peak_date": "2023-08-15",
    "trough_date": "2023-10-20",
    "duration_days": 66,
    "recovered": true
  },
  "analysis": {
    "max_drawdown_periods": [...],
    "drawdown_distribution": {
      "minor_count": 5,
      "moderate_count": 2,
      "significant_count": 1
    }
  }
}
```

---

## 前端实现模式

### 1. 股票策略页面 (stock_strategy.html)

#### 页面结构

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>股票策略配置</title>
  <link rel="stylesheet" href="stock_strategy.css">
</head>
<body>
  <!-- 步骤导航 -->
  <div class="step-nav">
    <div class="step active">1. 择股设置</div>
    <div class="step">2. 交易模型</div>
    <div class="step">3. 大盘择时</div>
    <div class="step">4. 股指对冲</div>
  </div>

  <!-- 择股设置区域 -->
  <div class="step-content" id="step1">
    <!-- 股票池配置 -->
    <div class="filter-section">股票池配置</div>

    <!-- 基础筛选条件 -->
    <div class="filter-grid">
      <div class="filter-item">
        <label>指数成份</label>
        <select id="index-component"></select>
      </div>
    </div>

    <!-- 选股指标 -->
    <div class="indicator-panel">
      <div class="indicator-list"><!-- 指标列表 --></div>
      <div class="condition-table"><!-- 条件表 --></div>
    </div>
  </div>

  <!-- 回测区域 -->
  <div class="backtest-section">
    <button onclick="runBacktest()">开始回测</button>
  </div>

  <script src="api.js"></script>
  <script src="stock_strategy.js"></script>
</body>
</html>
```

#### 交互逻辑

```javascript
// stock_strategy.js
class StockStrategyApp {
  constructor() {
    this.selectedStocks = [];
    this.conditions = [];
    this.backtestConfig = {};
    this.init();
  }

  init() {
    this.bindEvents();
    this.loadStockPools();
  }

  bindEvents() {
    // 添加选股条件
    document.querySelectorAll('.indicator-item').forEach(el => {
      el.addEventListener('click', () => this.addCondition(el.dataset.id));
    });

    // 运行回测
    document.querySelector('.run-backtest-btn')
      .addEventListener('click', () => this.runBacktest());
  }

  async loadStockPools() {
    try {
      const data = await API.getStocks();
      this.renderStockPoolOptions(data.stocks);
    } catch (error) {
      console.error('加载股票池失败:', error);
    }
  }

  addCondition(indicatorId) {
    const condition = {
      id: indicatorId,
      operator: '>',
      value: ''
    };
    this.conditions.push(condition);
    this.renderConditionTable();
  }

  async runBacktest() {
    const config = {
      stock_code: this.selectedStocks[0],
      strategy: this.buildStrategyFromConditions(),
      start_date: document.getElementById('start-date').value,
      end_date: document.getElementById('end-date').value,
      initial_capital: parseFloat(this.capital) || 100000
    };

    this.showLoading(true);
    try {
      const result = await API.runBacktest(config);
      this.displayResult(result);
    } catch (error) {
      this.showError(error.message);
    } finally {
      this.showLoading(false);
    }
  }

  displayResult(result) {
    // 更新结果展示区域
    const metrics = result.result;
    document.getElementById('total-return').textContent =
      (metrics.total_return * 100).toFixed(2) + '%';
    document.getElementById('max-drawdown').textContent =
      (metrics.max_drawdown * 100).toFixed(2) + '%';
    document.getElementById('sharpe-ratio').textContent =
      metrics.sharpe_ratio.toFixed(2);

    // 绘制收益曲线
    this.renderEquityCurve(metrics.equity_curve);
  }
}

// 初始化应用
const app = new StockStrategyApp();
```

---

### 2. 主页 Dashboard (index.html)

#### 核心组件

```javascript
// app.js
class DashboardApp {
  constructor() {
    this.portfolio = null;
    this.backtestResults = [];
    this.init();
  }

  init() {
    this.loadPortfolio();
    this.loadRecentBacktests();
    this.initCharts();
  }

  async loadPortfolio() {
    // 加载组合概览
    const drawdown = await API.getPortfolioDrawdown(['sh.600000', 'sz.000001']);
    this.renderPortfolioCards(drawdown);
  }

  async loadRecentBacktests() {
    // 加载最近回测
    const backtests = await API.getBacktestHistory();
    this.renderBacktestList(backtests);
  }

  renderPortfolioCards(data) {
    // 更新组合卡片
    this.updateCard('total-value', data.portfolio.total_value);
    this.updateCard('max-drawdown', data.portfolio.max_drawdown);
    this.updateCard('current-drawdown', data.portfolio.total_drawdown);
  }

  initCharts() {
    // 初始化图表
    this.equityChart = new Chart(ctx, {
      type: 'line',
      data: { labels: [], datasets: [] },
      options: { /* Chart.js 配置 */ }
    });
  }
}
```

---

## 数据格式规范

### 日期格式

**所有日期使用 ISO 8601 格式**: `YYYY-MM-DD`

```javascript
// 正确
const date = '2023-01-15';

// 错误
const date = '01/15/2023';  // 美式格式
const date = '15/01/2023';  // 欧式格式
```

### 数值精度

```javascript
// 百分比使用小数表示
const returnRate = 0.15;      // 15%
const drawdown = -0.085;      // -8.5%

// 价格保留 2 位小数
const price = 10.50;

// 数量使用整数或适当精度
const quantity = 1000;
```

### 股票代码格式

```javascript
// 上海股票
const shStock = 'sh.600000';

// 深圳股票
const szStock = 'sz.000001';
```

---

## 错误处理

### 前端错误处理

```javascript
// api.js
async _handleError(response) {
  const error = await response.json();

  const errorMap = {
    'INVALID_STOCK_CODE': '无效的股票代码',
    'DATA_NOT_FOUND': '数据未找到',
    'STRATEGY_NOT_FOUND': '策略不存在',
    'INVALID_DATE_RANGE': '日期范围无效',
    'BACKTEST_FAILED': '回测执行失败'
  };

  const message = errorMap[error.code] || error.message || '未知错误';
  throw new Error(message);
}

// 使用
try {
  const result = await API.runBacktest(config);
} catch (error) {
  showErrorToast(error.message);
  console.error('回测错误:', error);
}
```

### 后端错误响应

```json
{
  "status": "error",
  "error": {
    "code": "INVALID_STOCK_CODE",
    "message": "无效的股票代码：xxx.123456"
  }
}
```

---

## 开发环境配置

### 本地开发

```javascript
// 开发时使用代理
// webpack.config.js 或 vite.config.js
export default {
  server: {
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
}
```

### 生产部署

```javascript
// 配置 API 基础 URL
const API_BASE = window.location.origin + '/api';

// 或者使用环境变量
const API_BASE = process.env.API_BASE_URL || '/api';
```

---

## 性能优化

### 1. 数据缓存

```javascript
// api.js - 添加缓存层
class API {
  constructor() {
    this.cache = new Map();
    this.cacheTTL = 5 * 60 * 1000; // 5 分钟
  }

  async getStocks() {
    const cacheKey = 'stocks';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached;

    const data = await fetch('/api/stocks').then(r => r.json());
    this.setCache(cacheKey, data);
    return data;
  }

  getFromCache(key) {
    const item = this.cache.get(key);
    if (item && Date.now() - item.timestamp < this.cacheTTL) {
      return item.data;
    }
    return null;
  }

  setCache(key, data) {
    this.cache.set(key, { data, timestamp: Date.now() });
  }
}
```

### 2. 请求防抖

```javascript
// 防止频繁请求
function debounce(fn, delay) {
  let timer = null;
  return function(...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), delay);
  };
}

// 使用
const searchStocks = debounce(async (query) => {
  const results = await API.searchStocks(query);
  renderSearchResults(results);
}, 300);
```

---

## 安全考虑

### 1. 输入验证

```javascript
// 验证股票代码格式
function validateStockCode(code) {
  const pattern = /^(sh|sz)\.\d{6}$/;
  return pattern.test(code);
}

// 验证日期格式
function validateDate(date) {
  const pattern = /^\d{4}-\d{2}-\d{2}$/;
  return pattern.test(date) && !isNaN(Date.parse(date));
}
```

### 2. XSS 防护

```javascript
// 转义用户输入
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// 使用
document.getElementById('result').innerHTML = escapeHtml(userInput);
```

---

## 测试

### 前端测试

```javascript
// test/api.test.js
describe('API Client', () => {
  beforeEach(() => {
    fetch.mockClear();
  });

  test('getStocks should fetch from /api/stocks', async () => {
    fetch.mockResolvedValue({
      json: () => Promise.resolve({ stocks: [], total: 0 })
    });

    await API.getStocks();

    expect(fetch).toHaveBeenCalledWith('/api/stocks');
  });

  test('runBacktest should POST to /api/backtest', async () => {
    fetch.mockResolvedValue({
      json: () => Promise.resolve({ status: 'completed' })
    });

    const config = {
      stock_code: 'sh.600000',
      strategy: 'ma_cross',
      start_date: '2023-01-01',
      end_date: '2023-12-31'
    };

    await API.runBacktest(config);

    expect(fetch).toHaveBeenCalledWith('/api/backtest', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(config)
    });
  });
});
```

---

## 附录：完整示例

### 完整的策略回测流程

```javascript
// 完整的策略回测示例
class BacktestWorkflow {
  async execute() {
    // 1. 选择股票
    const stockCode = await this.selectStock();

    // 2. 获取历史数据
    const klines = await API.getKlines(stockCode, {
      start: '2023-01-01',
      end: '2023-12-31'
    });

    // 3. 配置策略
    const strategyConfig = {
      ma_short: 5,
      ma_long: 20,
      stop_loss: 0.05,
      take_profit: 0.15
    };

    // 4. 运行回测
    const backtestResult = await API.runBacktest({
      stock_code: stockCode,
      strategy: 'ma_cross',
      strategy_config: strategyConfig,
      start_date: '2023-01-01',
      end_date: '2023-12-31',
      initial_capital: 100000
    });

    // 5. 分析结果
    this.analyzeResult(backtestResult.result);

    // 6. 生成报告
    this.generateReport(backtestResult.result);
  }

  analyzeResult(result) {
    console.log('总收益率:', result.total_return * 100 + '%');
    console.log('最大回撤:', result.max_drawdown * 100 + '%');
    console.log('夏普比率:', result.sharpe_ratio);
    console.log('胜率:', result.win_rate * 100 + '%');
  }
}

// 执行
const workflow = new BacktestWorkflow();
workflow.execute();
```

---

*最后更新：2026-03-27*
