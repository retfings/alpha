/**
 * Quantitative Drawdown Framework - Frontend Application
 *
 * Main application logic for the web interface.
 * Uses ES6 modules to import API functions.
 */

import * as api from './api.js';

// ============================================================================
// Global State
// ============================================================================

let equityChart = null;
let drawdownChart = null;
let backtestEquityChart = null;
let analysisChart = null;
let screenerChart = null;

// Dashboard state
let dashboardData = {
  portfolioValue: 0,
  maxDrawdown: 0,
  currentDrawdown: 0,
  sharpeRatio: 0
};

// Screener state
let screenerState = {
  indicators: [],
  results: [],
  filters: {}
};

// ============================================================================
// Utility Functions
// ============================================================================

function showLoading() {
  const loading = document.getElementById('loading');
  if (loading) loading.style.display = 'flex';
}

function hideLoading() {
  const loading = document.getElementById('loading');
  if (loading) loading.style.display = 'none';
}

function formatPercent(value) {
  const num = parseFloat(value) || 0;
  const sign = num < 0 ? '-' : '';
  return sign + (Math.abs(num) * 100).toFixed(2) + '%';
}

function formatNumber(value, decimals = 2) {
  return (parseFloat(value) || 0).toFixed(decimals);
}

function formatDate(dateStr) {
  if (!dateStr) return '--';
  try {
    return new Date(dateStr).toLocaleDateString('zh-CN');
  } catch {
    return dateStr;
  }
}

function formatCurrency(value) {
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY'
  }).format(value);
}

// ============================================================================
// Tab Navigation
// ============================================================================

function setupTabs() {
  const navBtns = document.querySelectorAll('.nav-btn');
  const tabs = document.querySelectorAll('.tab');

  navBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.dataset.tab;

      navBtns.forEach(b => b.classList.remove('active'));
      tabs.forEach(t => t.classList.remove('active'));

      btn.classList.add('active');
      const targetTab = document.getElementById(tabId);
      if (targetTab) targetTab.classList.add('active');

      // Refresh charts when tab becomes visible
      if (tabId === 'dashboard') {
        loadDashboardData();
      }
    });
  });
}

// ============================================================================
// Chart Initialization
// ============================================================================

function initEquityChart() {
  const canvas = document.getElementById('equity-chart');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  equityChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [],
      datasets: [{
        label: '组合价值',
        data: [],
        borderColor: '#2563eb',
        backgroundColor: 'rgba(37, 99, 235, 0.1)',
        fill: true,
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          display: true,
          title: { display: true, text: '日期' }
        },
        y: {
          display: true,
          title: { display: true, text: '价值 (CNY)' }
        }
      }
    }
  });
}

function initDrawdownChart() {
  const canvas = document.getElementById('drawdown-chart');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  drawdownChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [],
      datasets: [{
        label: '回撤',
        data: [],
        borderColor: '#ef4444',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        fill: true,
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          display: true,
          title: { display: true, text: '日期' }
        },
        y: {
          display: true,
          title: { display: true, text: '回撤 (%)' },
          ticks: {
            callback: (value) => formatPercent(value)
          }
        }
      }
    }
  });
}

function initBacktestEquityChart() {
  const canvas = document.getElementById('backtest-equity-chart');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  backtestEquityChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [],
      datasets: [{
        label: '回测权益',
        data: [],
        borderColor: '#10b981',
        backgroundColor: 'rgba(16, 185, 129, 0.1)',
        fill: true,
        tension: 0.1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          display: true,
          title: { display: true, text: '日期' }
        },
        y: {
          display: true,
          title: { display: true, text: '价值 (CNY)' }
        }
      }
    }
  });
}

function initAnalysisChart() {
  const canvas = document.getElementById('analysis-chart');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  analysisChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: '收盘价',
          data: [],
          borderColor: '#2563eb',
          backgroundColor: 'rgba(37, 99, 235, 0.1)',
          fill: false,
          tension: 0.1,
          yAxisID: 'y'
        },
        {
          label: '回撤',
          data: [],
          borderColor: '#ef4444',
          backgroundColor: 'rgba(239, 68, 68, 0.1)',
          fill: false,
          tension: 0.1,
          yAxisID: 'y1'
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: true }
      },
      scales: {
        x: {
          display: true,
          title: { display: true, text: '日期' }
        },
        y: {
          display: true,
          position: 'left',
          title: { display: true, text: '价格 (CNY)' }
        },
        y1: {
          display: true,
          position: 'right',
          title: { display: true, text: '回撤 (%)' },
          ticks: {
            callback: (value) => formatPercent(value)
          },
          grid: { drawOnChartArea: false }
        }
      }
    }
  });
}

// ============================================================================
// Data Loading
// ============================================================================

async function loadStockList() {
  try {
    const stocks = await api.getStocks();
    const backtestSelect = document.getElementById('backtest-stock');
    const analysisSelect = document.getElementById('analysis-stock');

    // Clear existing options except the first placeholder
    if (backtestSelect) {
      backtestSelect.innerHTML = '<option value="">选择股票</option>';
      stocks.slice(0, 100).forEach(stock => {
        const option = document.createElement('option');
        option.value = stock;
        option.textContent = stock;
        backtestSelect.appendChild(option);
      });
    }

    if (analysisSelect) {
      analysisSelect.innerHTML = '<option value="">选择股票</option>';
      stocks.slice(0, 100).forEach(stock => {
        const option = document.createElement('option');
        option.value = stock;
        option.textContent = stock;
        analysisSelect.appendChild(option);
      });
    }
  } catch (error) {
    console.error('Failed to load stocks:', error);
    showError('加载股票列表失败');
  }
}

async function loadStrategies() {
  try {
    const strategies = await api.getStrategies();
    const strategySelect = document.getElementById('backtest-strategy');

    if (strategySelect) {
      strategySelect.innerHTML = '';
      strategies.forEach(strategy => {
        const option = document.createElement('option');
        option.value = strategy.name;
        option.textContent = strategy.description;
        strategySelect.appendChild(option);
      });
    }
  } catch (error) {
    console.error('Failed to load strategies:', error);
  }
}

async function loadDashboardData() {
  // Load mock dashboard data (in production, this would come from API)
  try {
    // Try to get portfolio drawdown
    const portfolioData = await api.getPortfolioDrawdown();

    updateDashboardMetrics({
      portfolioValue: portfolioData.peak_value || 100000,
      maxDrawdown: portfolioData.max_drawdown || 0,
      currentDrawdown: portfolioData.current_drawdown || 0,
      sharpeRatio: 1.5
    });

    // Update charts with sample data
    updateDashboardCharts(portfolioData);
  } catch (error) {
    console.log('Dashboard data not available, using mock data');
    // Use mock data
    updateDashboardMetrics({
      portfolioValue: 100000,
      maxDrawdown: -0.15,
      currentDrawdown: -0.05,
      sharpeRatio: 1.2
    });
  }
}

function updateDashboardMetrics(metrics) {
  const valueEl = document.getElementById('portfolio-value');
  const maxDdEl = document.getElementById('max-drawdown');
  const curDdEl = document.getElementById('current-drawdown');
  const sharpeEl = document.getElementById('sharpe-ratio');

  if (valueEl) valueEl.textContent = formatCurrency(metrics.portfolioValue);
  if (maxDdEl) {
    maxDdEl.textContent = formatPercent(metrics.maxDrawdown);
    maxDdEl.className = 'metric negative';
  }
  if (curDdEl) {
    curDdEl.textContent = formatPercent(metrics.currentDrawdown);
    curDdEl.className = 'metric negative';
  }
  if (sharpeEl) sharpeEl.textContent = formatNumber(metrics.sharpeRatio, 2);
}

function updateDashboardCharts(portfolioData) {
  // Update drawdown chart if data available
  if (drawdownChart && portfolioData.drawdown_series) {
    drawdownChart.data.labels = portfolioData.drawdown_series.map(p => p.date);
    drawdownChart.data.datasets[0].data = portfolioData.drawdown_series.map(p => p.drawdown);
    drawdownChart.update();
  }
}

// ============================================================================
// Backtest Functions
// ============================================================================

async function handleBacktest(config) {
  showLoading();

  try {
    const result = await api.runBacktest(config);
    displayBacktestResults(result);
    showSuccess('回测完成');
  } catch (error) {
    console.error('Backtest error:', error);
    showError('回测失败：' + error.message);
  } finally {
    hideLoading();
  }
}

function displayBacktestResults(result) {
  const resultsDiv = document.getElementById('backtest-results');
  if (resultsDiv) resultsDiv.style.display = 'block';

  // Update metrics
  updateMetric('bt-total-return', result.total_return, true);
  updateMetric('bt-annual-return', result.annual_return, true);
  updateMetric('bt-max-drawdown', result.max_drawdown, false);
  updateMetricText('bt-sharpe-ratio', formatNumber(result.sharpe_ratio, 3));
  updateMetricText('bt-total-trades', result.total_trades || 0);
  updateMetricText('bt-win-rate', formatPercent(result.win_rate || 0));

  // Update equity curve chart
  if (backtestEquityChart && result.equity_curve) {
    backtestEquityChart.data.labels = result.equity_curve.map(p => p.date);
    backtestEquityChart.data.datasets[0].data = result.equity_curve.map(p => p.equity);
    backtestEquityChart.update();
  }

  // Update trades table
  const tradesBody = document.getElementById('trades-body');
  if (tradesBody && result.trades) {
    tradesBody.innerHTML = '';
    result.trades.forEach(trade => {
      const row = document.createElement('tr');
      const actionClass = trade.action === 'Buy' ? 'positive' : 'negative';
      row.innerHTML = `
        <td>${trade.timestamp}</td>
        <td class="${actionClass}">${trade.action}</td>
        <td>${formatNumber(trade.price)}</td>
        <td>${formatNumber(trade.quantity, 0)}</td>
        <td>${formatNumber(trade.commission)}</td>
      `;
      tradesBody.appendChild(row);
    });
  }
}

// ============================================================================
// Analysis Functions
// ============================================================================

async function handleDrawdownAnalysis(stockCode, startDate, endDate) {
  showLoading();

  try {
    const result = await api.getDrawdown(stockCode, startDate, endDate);
    displayAnalysisResults(result);
    showSuccess('分析完成');
  } catch (error) {
    console.error('Analysis error:', error);
    showError('分析失败：' + error.message);
  } finally {
    hideLoading();
  }
}

function displayAnalysisResults(result) {
  const resultsDiv = document.getElementById('analysis-results');
  if (resultsDiv) resultsDiv.style.display = 'block';

  // Update metrics
  updateMetricText('an-max-drawdown', formatPercent(result.max_drawdown));
  document.getElementById('an-max-drawdown')?.classList.add('negative');
  updateMetricText('an-peak-date', formatDate(result.peak_date));
  updateMetricText('an-trough-date', formatDate(result.trough_date));
  updateMetricText('an-duration', result.duration + ' 天');

  // Update chart
  if (analysisChart && result.drawdown_series) {
    analysisChart.data.labels = result.drawdown_series.map(p => p.date);
    analysisChart.data.datasets[0].data = result.drawdown_series.map(p => p.value);
    analysisChart.data.datasets[1].data = result.drawdown_series.map(p => p.drawdown);
    analysisChart.update();
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

function updateMetric(elementId, value, isPercent) {
  const el = document.getElementById(elementId);
  if (!el) return;

  const numValue = parseFloat(value) || 0;
  if (isPercent) {
    el.textContent = formatPercent(numValue);
    el.className = 'metric ' + (numValue >= 0 ? 'positive' : 'negative');
  } else {
    el.textContent = formatPercent(numValue);
    el.className = 'metric negative';
  }
}

function updateMetricText(elementId, text) {
  const el = document.getElementById(elementId);
  if (el) el.textContent = text;
}

function showError(message) {
  // Could use a toast notification here
  alert('错误：' + message);
}

function showSuccess(message) {
  // Could use a toast notification here
  console.log('Success:', message);
}

// ============================================================================
// Event Handlers
// ============================================================================

function setupEventHandlers() {
  // Backtest form
  const backtestForm = document.getElementById('backtest-form');
  if (backtestForm) {
    backtestForm.addEventListener('submit', (e) => {
      e.preventDefault();

      const stockCode = document.getElementById('backtest-stock')?.value;
      const strategy = document.getElementById('backtest-strategy')?.value;
      const startDate = document.getElementById('backtest-start')?.value;
      const endDate = document.getElementById('backtest-end')?.value;
      const initialCapital = parseFloat(document.getElementById('backtest-capital')?.value || 100000);

      if (!stockCode) {
        showError('请选择股票代码');
        return;
      }

      handleBacktest({
        stock_code: stockCode,
        strategy,
        start_date: startDate,
        end_date: endDate,
        initial_capital: initialCapital
      });
    });
  }

  // Analysis form
  const analysisForm = document.getElementById('analysis-form');
  if (analysisForm) {
    analysisForm.addEventListener('submit', (e) => {
      e.preventDefault();

      const stockCode = document.getElementById('analysis-stock')?.value;
      const startDate = document.getElementById('analysis-start')?.value;
      const endDate = document.getElementById('analysis-end')?.value;

      if (!stockCode) {
        showError('请选择股票代码');
        return;
      }

      handleDrawdownAnalysis(stockCode, startDate, endDate);
    });
  }

  // Settings form (placeholder)
  const settingsForm = document.getElementById('settings-form');
  if (settingsForm) {
    settingsForm.addEventListener('submit', (e) => {
      e.preventDefault();
      showSuccess('设置已保存');
    });
  }
}

// ============================================================================
// Stock Screener Functions
// ============================================================================

/**
 * Initialize screener UI event handlers
 */
function setupScreenerHandlers() {
  // Operator select change - show/hide range inputs
  document.querySelectorAll('.operator-select').forEach(select => {
    select.addEventListener('change', (e) => {
      const indicatorItem = e.target.closest('.indicator-item');
      const valueInputs = indicatorItem.querySelectorAll('.value-input');
      const singleValue = valueInputs[0];
      const minValue = indicatorItem.querySelector('.min-value');
      const maxValue = indicatorItem.querySelector('.max-value');

      if (e.target.value === 'range') {
        singleValue.style.display = 'none';
        minValue.style.display = 'block';
        maxValue.style.display = 'block';
      } else {
        singleValue.style.display = 'block';
        minValue.style.display = 'none';
        maxValue.style.display = 'none';
      }
    });
  });

  // Weight slider change
  document.querySelectorAll('.weight-slider').forEach(slider => {
    slider.addEventListener('input', (e) => {
      const weightValue = e.target.closest('.indicator-weight').querySelector('.weight-value');
      weightValue.textContent = e.target.value;
    });
  });

  // Toggle indicator enable/disable
  document.querySelectorAll('.indicator-toggle').forEach(toggle => {
    toggle.addEventListener('change', (e) => {
      const indicatorItem = e.target.closest('.indicator-item');
      if (!e.target.checked) {
        indicatorItem.classList.add('disabled');
      } else {
        indicatorItem.classList.remove('disabled');
      }
    });
  });

  // Reset filters button
  const resetBtn = document.getElementById('reset-filters');
  if (resetBtn) {
    resetBtn.addEventListener('click', resetScreenerFilters);
  }

  // Run screener button
  const runBtn = document.getElementById('run-screener');
  if (runBtn) {
    runBtn.addEventListener('click', runScreener);
  }

  // Export results button
  const exportBtn = document.getElementById('export-results');
  if (exportBtn) {
    exportBtn.addEventListener('click', exportScreenerResults);
  }

  // Sort change
  const sortSelect = document.getElementById('sort-by');
  if (sortSelect) {
    sortSelect.addEventListener('change', (e) => {
      sortScreenerResults(e.target.value);
    });
  }
}

/**
 * Reset all screener filters to defaults
 */
function resetScreenerFilters() {
  // Reset all toggles to checked
  document.querySelectorAll('.indicator-toggle').forEach(toggle => {
    toggle.checked = true;
    toggle.closest('.indicator-item').classList.remove('disabled');
  });

  // Reset all operators to '>'
  document.querySelectorAll('.operator-select').forEach(select => {
    select.value = 'gt';
    // Trigger change event to hide range inputs
    select.dispatchEvent(new Event('change'));
  });

  // Reset all value inputs
  document.querySelectorAll('.value-input').forEach(input => {
    input.value = '';
  });

  // Reset all weights to default
  document.querySelectorAll('.weight-slider').forEach(slider => {
    const defaultValue = slider.getAttribute('data-default') || '1';
    slider.value = defaultValue;
    const weightValue = slider.closest('.indicator-weight').querySelector('.weight-value');
    weightValue.textContent = defaultValue;
  });

  // Clear results
  screenerState.results = [];
  updateScreenerResults([]);
}

/**
 * Collect current filter configuration from UI
 */
function collectScreenerConfig() {
  const filters = [];
  const weights = {};

  document.querySelectorAll('.indicator-item').forEach(item => {
    const indicatorId = item.dataset.indicator;
    const isEnabled = item.querySelector('.indicator-toggle').checked;
    const operator = item.querySelector('.operator-select').value;
    const weight = parseInt(item.querySelector('.weight-slider').value, 10);

    if (!isEnabled) return;

    let value = null;
    let minValue = null;
    let maxValue = null;

    const singleValue = item.querySelector('.value-input:not(.min-value):not(.max-value)');
    const minInput = item.querySelector('.min-value');
    const maxInput = item.querySelector('.max-value');

    if (operator === 'range') {
      minValue = minInput.value ? parseFloat(minInput.value) : null;
      maxValue = maxInput.value ? parseFloat(maxInput.value) : null;
      if (minValue !== null || maxValue !== null) {
        filters.push({
          indicator: indicatorId,
          operator: 'range',
          min: minValue,
          max: maxValue
        });
      }
    } else {
      value = singleValue.value ? parseFloat(singleValue.value) : null;
      if (value !== null) {
        filters.push({
          indicator: indicatorId,
          operator: operator,
          value: value
        });
      }
    }

    weights[indicatorId] = weight;
  });

  return { filters, weights };
}

/**
 * Run stock screener with current configuration
 */
async function runScreener() {
  showLoading();

  try {
    const config = collectScreenerConfig();
    const sortBy = document.getElementById('sort-by')?.value || 'score_desc';

    // Mock data for demonstration (in production, this would call the API)
    const mockResults = generateMockScreenerResults(config);

    screenerState.results = mockResults;
    screenerState.filters = config;

    // Apply sorting
    sortScreenerResults(sortBy);

    showSuccess('选股完成');
  } catch (error) {
    console.error('Screener error:', error);
    showError('选股失败：' + error.message);
  } finally {
    hideLoading();
  }
}

/**
 * Generate mock screener results for demonstration
 */
function generateMockScreenerResults(config) {
  // Mock stock data
  const mockStocks = [
    { code: 'sh.600000', name: '浦发银行', price: 8.52, roe: 12.5, np_margin: 28.3, eps: 1.25, rsi: 45.2, macd: 0.0234, kdj: 52.3, volume: 25000000 },
    { code: 'sh.600001', name: '邯郸钢铁', price: 3.45, roe: 8.2, np_margin: 5.1, eps: 0.32, rsi: 62.8, macd: -0.0123, kdj: 71.2, volume: 18000000 },
    { code: 'sh.600002', name: '齐鲁石化', price: 5.67, roe: 15.8, np_margin: 12.4, eps: 0.89, rsi: 38.5, macd: 0.0456, kdj: 35.8, volume: 12000000 },
    { code: 'sh.600003', name: '东北高速', price: 4.23, roe: 6.5, np_margin: 18.2, eps: 0.45, rsi: 55.1, macd: 0.0089, kdj: 48.6, volume: 9500000 },
    { code: 'sh.600004', name: '白云机场', price: 12.89, roe: 18.3, np_margin: 32.5, eps: 1.85, rsi: 72.4, macd: 0.1234, kdj: 82.1, volume: 32000000 },
    { code: 'sh.600005', name: '武钢股份', price: 4.56, roe: 10.2, np_margin: 8.7, eps: 0.52, rsi: 48.9, macd: -0.0056, kdj: 42.3, volume: 21000000 },
    { code: 'sh.600006', name: '东风汽车', price: 7.34, roe: 14.6, np_margin: 6.8, eps: 0.78, rsi: 58.2, macd: 0.0312, kdj: 61.5, volume: 15000000 },
    { code: 'sh.600007', name: '上港集团', price: 6.12, roe: 22.1, np_margin: 42.3, eps: 1.12, rsi: 41.6, macd: -0.0178, kdj: 38.9, volume: 28000000 },
    { code: 'sh.600008', name: '首创股份', price: 3.89, roe: 9.8, np_margin: 15.6, eps: 0.41, rsi: 67.3, macd: 0.0201, kdj: 69.8, volume: 11000000 },
    { code: 'sh.600009', name: '上海机场', price: 45.67, roe: 25.4, np_margin: 38.9, eps: 2.35, rsi: 52.8, macd: 0.5678, kdj: 55.2, volume: 8500000 },
  ];

  // Apply filters
  let filtered = mockStocks.filter(stock => {
    for (const filter of config.filters) {
      const stockValue = stock[filter.indicator];
      if (stockValue === undefined) continue;

      if (filter.operator === 'range') {
        if (filter.min !== null && stockValue < filter.min) return false;
        if (filter.max !== null && stockValue > filter.max) return false;
      } else if (filter.operator === 'gt') {
        if (stockValue <= filter.value) return false;
      } else if (filter.operator === 'lt') {
        if (stockValue >= filter.value) return false;
      } else if (filter.operator === 'eq') {
        if (Math.abs(stockValue - filter.value) > 0.0001) return false;
      }
    }
    return true;
  });

  // Calculate weighted scores
  filtered = filtered.map(stock => {
    let score = 0;
    let totalWeight = 0;

    // Technical indicators scoring
    if (config.weights.rsi > 0) {
      score += (stock.rsi / 100) * config.weights.rsi;
      totalWeight += config.weights.rsi;
    }
    if (config.weights.macd > 0) {
      score += (stock.macd > 0 ? 1 : 0) * config.weights.macd;
      totalWeight += config.weights.macd;
    }
    if (config.weights.kdj > 0) {
      score += (stock.kdj / 100) * config.weights.kdj;
      totalWeight += config.weights.kdj;
    }

    // Fundamental indicators scoring
    if (config.weights.roe > 0) {
      score += Math.min(stock.roe / 30, 1) * config.weights.roe;
      totalWeight += config.weights.roe;
    }
    if (config.weights.np_margin > 0) {
      score += Math.min(stock.np_margin / 50, 1) * config.weights.np_margin;
      totalWeight += config.weights.np_margin;
    }
    if (config.weights.eps > 0) {
      score += Math.min(stock.eps / 3, 1) * config.weights.eps;
      totalWeight += config.weights.eps;
    }

    return {
      ...stock,
      score: totalWeight > 0 ? (score / totalWeight) * 100 : 0
    };
  });

  return filtered;
}

/**
 * Update screener results display
 */
function updateScreenerResults(results) {
  const tbody = document.getElementById('screener-results-body');
  const countEl = document.getElementById('result-count');

  if (!tbody) return;

  if (results.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="11" class="empty-state">
          <div class="empty-state-icon">📊</div>
          <h4>暂无结果</h4>
          <p>配置筛选条件后点击"运行选股"</p>
        </td>
      </tr>
    `;
    if (countEl) countEl.textContent = '0';
    return;
  }

  tbody.innerHTML = results.map(stock => `
    <tr data-code="${stock.code}">
      <td>${stock.code}</td>
      <td>${stock.name}</td>
      <td>${formatNumber(stock.price, 2)}</td>
      <td class="${stock.rsi > 70 ? 'negative' : stock.rsi < 30 ? 'positive' : ''}">${formatNumber(stock.rsi, 1)}</td>
      <td class="${stock.macd > 0 ? 'positive' : 'negative'}">${formatNumber(stock.macd, 4)}</td>
      <td>${formatNumber(stock.kdj, 1)}</td>
      <td class="${stock.roe > 15 ? 'positive' : stock.roe < 5 ? 'negative' : ''}">${formatNumber(stock.roe, 1)}</td>
      <td class="${stock.np_margin > 20 ? 'positive' : stock.np_margin < 5 ? 'negative' : ''}">${formatNumber(stock.np_margin, 1)}</td>
      <td>${formatNumber(stock.eps, 2)}</td>
      <td class="score-cell" style="color: ${getScoreColor(stock.score)}">${formatNumber(stock.score, 1)}</td>
      <td class="action-cell">
        <button class="btn-sm btn-analyze" onclick="analyzeStock('${stock.code}')">分析</button>
        <button class="btn-sm" onclick="addToWatchlist('${stock.code}')">自选</button>
      </td>
    </tr>
  `).join('');

  if (countEl) countEl.textContent = results.length;

  // Update chart
  updateScreenerChart(results);
}

/**
 * Get color based on score
 */
function getScoreColor(score) {
  if (score >= 70) return 'var(--success-color)';
  if (score >= 50) return 'var(--warning-color)';
  return 'var(--danger-color)';
}

/**
 * Sort screener results
 */
function sortScreenerResults(sortBy) {
  const [field, order] = sortBy.split('_');
  const desc = order === 'desc';

  screenerState.results.sort((a, b) => {
    let aVal = a[field];
    let bVal = b[field];

    if (aVal === undefined) aVal = 0;
    if (bVal === undefined) bVal = 0;

    return desc ? bVal - aVal : aVal - bVal;
  });

  updateScreenerResults(screenerState.results);
}

/**
 * Export screener results to CSV
 */
function exportScreenerResults() {
  if (screenerState.results.length === 0) {
    showError('无结果可导出');
    return;
  }

  const headers = ['代码', '名称', '价格', 'RSI', 'MACD', 'KDJ', 'ROE(%)', '净利率 (%)', 'EPS', '综合评分'];
  const rows = screenerState.results.map(stock => [
    stock.code,
    stock.name,
    stock.price,
    stock.rsi,
    stock.macd,
    stock.kdj,
    stock.roe,
    stock.np_margin,
    stock.eps,
    stock.score
  ]);

  const csv = [
    headers.join(','),
    ...rows.map(row => row.join(','))
  ].join('\n');

  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `选股结果_${new Date().toISOString().split('T')[0]}.csv`;
  link.click();

  showSuccess('导出成功');
}

/**
 * Initialize screener chart
 */
function initScreenerChart() {
  const canvas = document.getElementById('screener-chart');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  screenerChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: [],
      datasets: [{
        label: '综合评分',
        data: [],
        backgroundColor: [],
        borderColor: [],
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        x: {
          display: true,
          title: { display: true, text: '股票' }
        },
        y: {
          display: true,
          title: { display: true, text: '评分' },
          min: 0,
          max: 100
        }
      }
    }
  });
}

/**
 * Update screener chart with results
 */
function updateScreenerChart(results) {
  if (!screenerChart) return;

  const topResults = results.slice(0, 10);

  screenerChart.data.labels = topResults.map(s => s.name);
  screenerChart.data.datasets[0].data = topResults.map(s => s.score);
  screenerChart.data.datasets[0].backgroundColor = topResults.map(s => {
    if (s.score >= 70) return 'rgba(16, 185, 129, 0.7)';
    if (s.score >= 50) return 'rgba(245, 158, 11, 0.7)';
    return 'rgba(239, 68, 68, 0.7)';
  });
  screenerChart.data.datasets[0].borderColor = topResults.map(s => {
    if (s.score >= 70) return 'rgb(16, 185, 129)';
    if (s.score >= 50) return 'rgb(245, 158, 11)';
    return 'rgb(239, 68, 68)';
  });

  screenerChart.update();
}

/**
 * Analyze a specific stock (opens analysis tab)
 */
function analyzeStock(code) {
  // Switch to analysis tab
  const analysisTab = document.querySelector('[data-tab="analysis"]');
  if (analysisTab) {
    analysisTab.click();
  }

  // Set the stock in analysis form
  const analysisStock = document.getElementById('analysis-stock');
  if (analysisStock) {
    analysisStock.value = code;
  }

  showSuccess(`已切换到分析页面 - ${code}`);
}

/**
 * Add stock to watchlist
 */
function addToWatchlist(code) {
  showSuccess(`已添加 ${code} 到自选`);
}

// Export functions for global access (used in inline onclick handlers)
window.analyzeStock = analyzeStock;
window.addToWatchlist = addToWatchlist;

// ============================================================================
// Application Initialization
// ============================================================================

function initializeApp() {
  setupTabs();
  setupEventHandlers();
  setupScreenerHandlers();
  initEquityChart();
  initDrawdownChart();
  initBacktestEquityChart();
  initAnalysisChart();
  initScreenerChart();
  loadStockList();
  loadStrategies();
  loadDashboardData();

  console.log('Application initialized');
}

// Start the application
document.addEventListener('DOMContentLoaded', initializeApp);
