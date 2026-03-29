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
  filters: {},
  pagination: {
    page: 1,
    page_size: 10,
    total: 0,
    total_pages: 1
  }
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
    const response = await api.getStrategies();
    const strategies = response.strategies || [];
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

  // Pagination - previous page button
  const prevBtn = document.getElementById('prev-page');
  if (prevBtn) {
    prevBtn.addEventListener('click', () => {
      if (screenerState.pagination.page > 1) {
        goToPage(screenerState.pagination.page - 1);
      }
    });
  }

  // Pagination - next page button
  const nextBtn = document.getElementById('next-page');
  if (nextBtn) {
    nextBtn.addEventListener('click', () => {
      if (screenerState.pagination.page < screenerState.pagination.total_pages) {
        goToPage(screenerState.pagination.page + 1);
      }
    });
  }

  // Pagination - page size change
  const pageSizeSelect = document.getElementById('page-size');
  if (pageSizeSelect) {
    pageSizeSelect.addEventListener('change', (e) => {
      changePageSize(e.target.value);
    });
  }

  // Trading model select change
  const modelSelect = document.getElementById('trading-model-select');
  if (modelSelect) {
    modelSelect.addEventListener('change', (e) => {
      updateModelDescription(e.target.value);
    });
  }

  // Rebalance frequency change - show/hide day selector
  const rebalanceFreq = document.getElementById('rebalance-frequency');
  const rebalanceDayLabel = document.getElementById('rebalance-day-label');
  if (rebalanceFreq && rebalanceDayLabel) {
    rebalanceFreq.addEventListener('change', (e) => {
      if (e.target.value === 'daily') {
        rebalanceDayLabel.style.display = 'none';
      } else if (e.target.value === 'monthly') {
        rebalanceDayLabel.style.display = 'flex';
        // Update day options for monthly
        const daySelect = document.getElementById('rebalance-day');
        daySelect.innerHTML = '';
        for (let i = 1; i <= 28; i++) {
          const option = document.createElement('option');
          option.value = i;
          option.textContent = '每月' + i + '日';
          daySelect.appendChild(option);
        }
      } else {
        rebalanceDayLabel.style.display = 'flex';
        // Update day options for weekly/biweekly
        const daySelect = document.getElementById('rebalance-day');
        daySelect.innerHTML = '';
        const days = [
          { value: '1', text: '周一' },
          { value: '2', text: '周二' },
          { value: '3', text: '周三' },
          { value: '4', text: '周四' },
          { value: '5', text: '周五' }
        ];
        days.forEach(d => {
          const option = document.createElement('option');
          option.value = d.value;
          option.textContent = d.text;
          daySelect.appendChild(option);
        });
      }
    });
  }

  // Trigger condition change - enable/disable cooldown
  const triggerCondition = document.getElementById('trigger-condition');
  const cooldownDays = document.getElementById('cooldown-days');
  if (triggerCondition && cooldownDays) {
    triggerCondition.addEventListener('change', (e) => {
      cooldownDays.disabled = e.target.value === 'none';
    });
  }

  // Reset trading model button
  const resetTradingModelBtn = document.getElementById('reset-trading-model');
  if (resetTradingModelBtn) {
    resetTradingModelBtn.addEventListener('click', resetTradingModel);
  }

  // Save trading model button
  const saveTradingModelBtn = document.getElementById('save-trading-model');
  if (saveTradingModelBtn) {
    saveTradingModelBtn.addEventListener('click', saveTradingModel);
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
    const pageSize = parseInt(document.getElementById('page-size')?.value) || 10;

    // Build request body matching backend ScreenerRequest format
    const requestBody = {
      filters: config.filters,
      weights: config.weights,
      sort_by: 'score',
      sort_order: 'desc',
      page: 1,
      page_size: pageSize
    };

    // Call actual backend API
    const response = await api.runScreener(requestBody);
    const results = response.results || [];

    screenerState.results = results;
    screenerState.filters = config;
    screenerState.pagination = {
      page: 1,
      page_size: pageSize,
      total: response.total || 0,
      total_pages: response.total_pages || 1
    };

    // Apply sorting
    sortScreenerResults(sortBy);

    // Update pagination UI
    updatePaginationUI();

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
  // Mock stock data from K-line (only price, volume, amount, turn, MA indicators)
  const mockStocks = [
    { code: 'sh.600000', name: '浦发银行', price: 8.52, volume: 25000000, amount: 213000000, turn: 0.85, ma5: 8.45, ma10: 8.38 },
    { code: 'sh.600001', name: '邯郸钢铁', price: 3.45, volume: 18000000, amount: 62100000, turn: 1.25, ma5: 3.42, ma10: 3.38 },
    { code: 'sh.600002', name: '齐鲁石化', price: 5.67, volume: 12000000, amount: 68040000, turn: 0.92, ma5: 5.72, ma10: 5.65 },
    { code: 'sh.600003', name: '东北高速', price: 4.23, volume: 9500000, amount: 40185000, turn: 0.68, ma5: 4.28, ma10: 4.32 },
    { code: 'sh.600004', name: '白云机场', price: 12.89, volume: 32000000, amount: 412480000, turn: 1.85, ma5: 12.75, ma10: 12.58 },
    { code: 'sh.600005', name: '武钢股份', price: 4.56, volume: 21000000, amount: 95760000, turn: 1.12, ma5: 4.52, ma10: 4.48 },
    { code: 'sh.600006', name: '东风汽车', price: 7.34, volume: 15000000, amount: 110100000, turn: 0.95, ma5: 7.28, ma10: 7.22 },
    { code: 'sh.600007', name: '上港集团', price: 6.12, volume: 28000000, amount: 171360000, turn: 1.35, ma5: 6.18, ma10: 6.25 },
    { code: 'sh.600008', name: '首创股份', price: 3.89, volume: 11000000, amount: 42790000, turn: 0.78, ma5: 3.85, ma10: 3.82 },
    { code: 'sh.600009', name: '上海机场', price: 45.67, volume: 8500000, amount: 388195000, turn: 2.15, ma5: 45.32, ma10: 44.85 },
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

  // Calculate weighted scores based on K-line indicators
  filtered = filtered.map(stock => {
    let score = 0;
    let totalWeight = 0;

    // Price scoring (higher price = higher score for simplicity)
    if (config.weights.price > 0) {
      score += (stock.price / 50) * config.weights.price;
      totalWeight += config.weights.price;
    }

    // Volume scoring (higher volume = more active = higher score)
    if (config.weights.volume > 0) {
      score += Math.min(stock.volume / 50000000, 1) * config.weights.volume;
      totalWeight += config.weights.volume;
    }

    // Amount scoring
    if (config.weights.amount > 0) {
      score += Math.min(stock.amount / 500000000, 1) * config.weights.amount;
      totalWeight += config.weights.amount;
    }

    // Turnover rate scoring (moderate turnover is best)
    if (config.weights.turn > 0) {
      const turnScore = stock.turn >= 0.5 && stock.turn <= 3 ? 1 : 0.5;
      score += turnScore * config.weights.turn;
      totalWeight += config.weights.turn;
    }

    // MA5 trend scoring (price above MA5 = bullish)
    if (config.weights.ma5_trend > 0) {
      score += (stock.price > stock.ma5 ? 1 : 0) * config.weights.ma5_trend;
      totalWeight += config.weights.ma5_trend;
    }

    // MA10 trend scoring (price above MA10 = bullish)
    if (config.weights.ma10_trend > 0) {
      score += (stock.price > stock.ma10 ? 1 : 0) * config.weights.ma10_trend;
      totalWeight += config.weights.ma10_trend;
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
        <td colspan="9" class="empty-state">
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
      <td>${formatNumber(stock.price, 2)}</td>
      <td>${formatNumber(stock.volume, 0)}</td>
      <td>${formatNumber(stock.amount / 10000, 0)}万</td>
      <td>${formatNumber((stock.turn || 0) * 100, 2)}%</td>
      <td>${formatNumber(stock.ma5 || 0, 2)}</td>
      <td>${formatNumber(stock.ma10 || 0, 2)}</td>
      <td class="score-cell" style="color: ${getScoreColor(stock.score)}">${formatNumber(stock.score, 1)}</td>
      <td class="action-cell">
        <button class="btn-sm btn-analyze" onclick="analyzeStock('${stock.code}')">分析</button>
        <button class="btn-sm" onclick="addToWatchlist('${stock.code}')">自选</button>
      </td>
    </tr>
  `).join('');

  if (countEl) countEl.textContent = screenerState.pagination.total;
}

/**
 * Update pagination UI
 */
function updatePaginationUI() {
  const currentPageEl = document.getElementById('current-page');
  const totalPagesEl = document.getElementById('total-pages');
  const prevBtn = document.getElementById('prev-page');
  const nextBtn = document.getElementById('next-page');

  const { page, total_pages } = screenerState.pagination;

  if (currentPageEl) currentPageEl.textContent = page;
  if (totalPagesEl) totalPagesEl.textContent = total_pages || 1;

  if (prevBtn) {
    prevBtn.disabled = page <= 1;
    prevBtn.style.opacity = page <= 1 ? '0.5' : '1';
    prevBtn.style.cursor = page <= 1 ? 'not-allowed' : 'pointer';
  }

  if (nextBtn) {
    nextBtn.disabled = page >= total_pages;
    nextBtn.style.opacity = page >= total_pages ? '0.5' : '1';
    nextBtn.style.cursor = page >= total_pages ? 'not-allowed' : 'pointer';
  }
}

/**
 * Go to specific page
 */
async function goToPage(page) {
  const totalPages = screenerState.pagination.total_pages;
  if (page < 1 || page > totalPages) return;

  showLoading();

  try {
    const config = screenerState.filters;
    const sortBy = document.getElementById('sort-by')?.value || 'score_desc';
    const pageSize = screenerState.pagination.page_size;

    const requestBody = {
      filters: config.filters,
      weights: config.weights,
      sort_by: 'score',
      sort_order: 'desc',
      page: page,
      page_size: pageSize
    };

    const response = await api.runScreener(requestBody);
    const results = response.results || [];

    screenerState.results = results;
    screenerState.pagination.page = page;
    screenerState.pagination.total_pages = response.total_pages || 1;

    sortScreenerResults(sortBy);
    updatePaginationUI();

    showSuccess(`第 ${page} 页加载完成`);
  } catch (error) {
    console.error('Page load error:', error);
    showError('加载失败：' + error.message);
  } finally {
    hideLoading();
  }
}

/**
 * Change page size
 */
async function changePageSize(newPageSize) {
  showLoading();

  try {
    const config = screenerState.filters;
    const sortBy = document.getElementById('sort-by')?.value || 'score_desc';

    const requestBody = {
      filters: config.filters,
      weights: config.weights,
      sort_by: 'score',
      sort_order: 'desc',
      page: 1,
      page_size: parseInt(newPageSize) || 10
    };

    const response = await api.runScreener(requestBody);
    const results = response.results || [];

    screenerState.results = results;
    screenerState.pagination.page = 1;
    screenerState.pagination.page_size = parseInt(newPageSize) || 10;
    screenerState.pagination.total_pages = response.total_pages || 1;

    sortScreenerResults(sortBy);
    updatePaginationUI();

    showSuccess('每页条数已更新');
  } catch (error) {
    console.error('Page size change error:', error);
    showError('加载失败：' + error.message);
  } finally {
    hideLoading();
  }
}

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

  const headers = ['代码', '收盘价', '成交量', '成交额', '换手率 (%)', '5 日均线', '10 日均线', '综合评分'];
  const rows = screenerState.results.map(stock => [
    stock.code,
    stock.price,
    stock.volume,
    stock.amount,
    stock.turn || 0,
    stock.ma5 || 0,
    stock.ma10 || 0,
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
// Trading Model Functions
// ============================================================================

/**
 * Model descriptions for each trading model
 */
const MODEL_DESCRIPTIONS = {
  score_rank: '根据综合评分对股票进行排序，选择排名靠前的股票。适合大多数量化策略。',
  cluster_select: '使用聚类算法将股票分组，从不同簇中选择代表性股票。适合分散化投资。',
  ml_classifier: '利用机器学习模型预测股票涨跌概率，选择高概率股票。需要历史数据训练。',
  factor_weighted: '基于多因子模型加权计算，考虑估值、成长、动量等因子。适合因子投资。',
  rule_based: '根据预设规则筛选股票，如"ROE>15% 且 MACD 金叉"。适合规则明确的策略。'
};

/**
 * Update model description based on selected model
 */
function updateModelDescription(modelId) {
  const descEl = document.getElementById('model-description');
  if (descEl) {
    descEl.textContent = MODEL_DESCRIPTIONS[modelId] || '未知模型';
  }
}

/**
 * Reset trading model configuration to defaults
 */
function resetTradingModel() {
  // Reset model select
  const modelSelect = document.getElementById('trading-model-select');
  if (modelSelect) modelSelect.value = 'score_rank';
  updateModelDescription('score_rank');

  // Reset rebalancing config
  const rebalanceFreq = document.getElementById('rebalance-frequency');
  const rebalanceDay = document.getElementById('rebalance-day');
  const positionCount = document.getElementById('position-count');
  const weightMethod = document.getElementById('weight-method');

  if (rebalanceFreq) rebalanceFreq.value = 'weekly';
  if (rebalanceDay) {
    rebalanceDay.innerHTML = '';
    for (let i = 1; i <= 5; i++) {
      const option = document.createElement('option');
      option.value = i;
      option.textContent = ['周一', '周二', '周三', '周四', '周五'][i - 1];
      if (i === 5) option.selected = true;
      rebalanceDay.appendChild(option);
    }
  }
  if (positionCount) positionCount.value = 10;
  if (weightMethod) weightMethod.value = 'equal';

  // Reset trigger config
  const triggerCondition = document.getElementById('trigger-condition');
  const cooldownDays = document.getElementById('cooldown-days');
  const stopLoss = document.getElementById('stop-loss');
  const takeProfit = document.getElementById('take-profit');
  const enableDynamicStop = document.getElementById('enable-dynamic-stop');
  const enableTrailingStop = document.getElementById('enable-trailing-stop');

  if (triggerCondition) triggerCondition.value = 'none';
  if (cooldownDays) {
    cooldownDays.value = 5;
    cooldownDays.disabled = true;
  }
  if (stopLoss) stopLoss.value = 10;
  if (takeProfit) takeProfit.value = 20;
  if (enableDynamicStop) enableDynamicStop.checked = true;
  if (enableTrailingStop) enableTrailingStop.checked = false;

  // Reset risk management
  const maxPosition = document.getElementById('max-position');
  const singleStockLimit = document.getElementById('single-stock-limit');
  const sectorLimit = document.getElementById('sector-limit');
  const maxDrawdownLimit = document.getElementById('max-drawdown-limit');

  if (maxPosition) maxPosition.value = 80;
  if (singleStockLimit) singleStockLimit.value = 20;
  if (sectorLimit) sectorLimit.value = 30;
  if (maxDrawdownLimit) maxDrawdownLimit.value = 15;

  showSuccess('交易模型配置已重置');
}

/**
 * Collect trading model configuration from UI
 */
function collectTradingModelConfig() {
  return {
    model: {
      id: document.getElementById('trading-model-select')?.value || 'score_rank',
      parameters: {}
    },
    rebalancing: {
      frequency: document.getElementById('rebalance-frequency')?.value || 'weekly',
      day: parseInt(document.getElementById('rebalance-day')?.value || '5', 10),
      positionCount: parseInt(document.getElementById('position-count')?.value || '10', 10),
      weightMethod: document.getElementById('weight-method')?.value || 'equal'
    },
    triggers: {
      condition: document.getElementById('trigger-condition')?.value || 'none',
      cooldownDays: parseInt(document.getElementById('cooldown-days')?.value || '5', 10),
      stopLoss: parseFloat(document.getElementById('stop-loss')?.value || '10', 10),
      takeProfit: parseFloat(document.getElementById('take-profit')?.value || '20', 10),
      enableDynamicStop: document.getElementById('enable-dynamic-stop')?.checked || false,
      enableTrailingStop: document.getElementById('enable-trailing-stop')?.checked || false
    },
    risk: {
      maxPosition: parseFloat(document.getElementById('max-position')?.value || '80', 10),
      singleStockLimit: parseFloat(document.getElementById('single-stock-limit')?.value || '20', 10),
      sectorLimit: parseFloat(document.getElementById('sector-limit')?.value || '30', 10),
      maxDrawdownLimit: parseFloat(document.getElementById('max-drawdown-limit')?.value || '15', 10)
    }
  };
}

/**
 * Save trading model configuration
 */
function saveTradingModel() {
  const config = collectTradingModelConfig();

  // Validate configuration
  if (config.rebalancing.positionCount < 1 || config.rebalancing.positionCount > 50) {
    showError('持仓数量必须在 1-50 之间');
    return;
  }

  if (config.risk.maxPosition < 10 || config.risk.maxPosition > 100) {
    showError('最大仓位必须在 10-100% 之间');
    return;
  }

  if (config.triggers.stopLoss <= 0 || config.triggers.stopLoss > 50) {
    showError('止损阈值必须在 1-50% 之间');
    return;
  }

  if (config.triggers.takeProfit <= 0 || config.triggers.takeProfit > 100) {
    showError('止盈阈值必须在 5-100% 之间');
    return;
  }

  // Save to localStorage for persistence
  localStorage.setItem('tradingModelConfig', JSON.stringify(config));

  console.log('Trading model configuration saved:', config);
  showSuccess('交易模型配置已保存');
}

/**
 * Load saved trading model configuration
 */
function loadTradingModelConfig() {
  try {
    const saved = localStorage.getItem('tradingModelConfig');
    if (saved) {
      const config = JSON.parse(saved);

      // Restore model selection
      const modelSelect = document.getElementById('trading-model-select');
      if (modelSelect && config.model?.id) {
        modelSelect.value = config.model.id;
        updateModelDescription(config.model.id);
      }

      // Restore rebalancing config
      if (config.rebalancing) {
        const freq = document.getElementById('rebalance-frequency');
        if (freq && config.rebalancing.frequency) freq.value = config.rebalancing.frequency;

        const positionCount = document.getElementById('position-count');
        if (positionCount && config.rebalancing.positionCount) {
          positionCount.value = config.rebalancing.positionCount;
        }

        const weightMethod = document.getElementById('weight-method');
        if (weightMethod && config.rebalancing.weightMethod) {
          weightMethod.value = config.rebalancing.weightMethod;
        }
      }

      // Restore trigger config
      if (config.triggers) {
        const condition = document.getElementById('trigger-condition');
        if (condition && config.triggers.condition) condition.value = config.triggers.condition;

        const cooldown = document.getElementById('cooldown-days');
        if (cooldown && config.triggers.cooldownDays !== undefined) {
          cooldown.value = config.triggers.cooldownDays;
          cooldown.disabled = config.triggers.condition === 'none';
        }

        const stopLoss = document.getElementById('stop-loss');
        if (stopLoss && config.triggers.stopLoss !== undefined) {
          stopLoss.value = config.triggers.stopLoss;
        }

        const takeProfit = document.getElementById('take-profit');
        if (takeProfit && config.triggers.takeProfit !== undefined) {
          takeProfit.value = config.triggers.takeProfit;
        }

        const dynamicStop = document.getElementById('enable-dynamic-stop');
        if (dynamicStop && config.triggers.enableDynamicStop !== undefined) {
          dynamicStop.checked = config.triggers.enableDynamicStop;
        }

        const trailingStop = document.getElementById('enable-trailing-stop');
        if (trailingStop && config.triggers.enableTrailingStop !== undefined) {
          trailingStop.checked = config.triggers.enableTrailingStop;
        }
      }

      // Restore risk config
      if (config.risk) {
        const maxPosition = document.getElementById('max-position');
        if (maxPosition && config.risk.maxPosition !== undefined) {
          maxPosition.value = config.risk.maxPosition;
        }

        const singleLimit = document.getElementById('single-stock-limit');
        if (singleLimit && config.risk.singleStockLimit !== undefined) {
          singleLimit.value = config.risk.singleStockLimit;
        }

        const sectorLimit = document.getElementById('sector-limit');
        if (sectorLimit && config.risk.sectorLimit !== undefined) {
          sectorLimit.value = config.risk.sectorLimit;
        }

        const maxDdLimit = document.getElementById('max-drawdown-limit');
        if (maxDdLimit && config.risk.maxDrawdownLimit !== undefined) {
          maxDdLimit.value = config.risk.maxDrawdownLimit;
        }
      }

      console.log('Trading model configuration loaded from storage');
    }
  } catch (error) {
    console.error('Failed to load trading model config:', error);
  }
}

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
  loadTradingModelConfig();

  console.log('Application initialized');
}

// Start the application
document.addEventListener('DOMContentLoaded', initializeApp);
