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

// Dashboard state
let dashboardData = {
  portfolioValue: 0,
  maxDrawdown: 0,
  currentDrawdown: 0,
  sharpeRatio: 0
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
// Application Initialization
// ============================================================================

function initializeApp() {
  setupTabs();
  setupEventHandlers();
  initEquityChart();
  initDrawdownChart();
  initBacktestEquityChart();
  initAnalysisChart();
  loadStockList();
  loadStrategies();
  loadDashboardData();

  console.log('Application initialized');
}

// Start the application
document.addEventListener('DOMContentLoaded', initializeApp);
