// Quantitative Drawdown Framework - Frontend Application

// API Base URL
const API_BASE = '/api';

// Global state
let equityChart = null;
let drawdownChart = null;
let backtestEquityChart = null;
let analysisChart = null;

// Utility functions
function showLoading() {
  document.getElementById('loading').style.display = 'flex';
}

function hideLoading() {
  document.getElementById('loading').style.display = 'none';
}

function formatPercent(value) {
  return (value * 100).toFixed(2) + '%';
}

function formatNumber(value, decimals = 2) {
  return parseFloat(value).toFixed(decimals);
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('zh-CN');
}

// Tab navigation
function setupTabs() {
  const navBtns = document.querySelectorAll('.nav-btn');
  const tabs = document.querySelectorAll('.tab');

  navBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.dataset.tab;

      // Update active states
      navBtns.forEach(b => b.classList.remove('active'));
      tabs.forEach(t => t.classList.remove('active'));

      btn.classList.add('active');
      document.getElementById(tabId).classList.add('active');
    });
  });
}

// Load stock list
async function loadStockList() {
  try {
    const response = await fetch(`${API_BASE}/stocks`);
    const stocks = await response.json();

    const backtestSelect = document.getElementById('backtest-stock');
    const analysisSelect = document.getElementById('analysis-stock');

    stocks.forEach(stock => {
      const option1 = document.createElement('option');
      option1.value = stock;
      option1.textContent = stock;
      backtestSelect.appendChild(option1);

      const option2 = document.createElement('option');
      option2.value = stock;
      option2.textContent = stock;
      analysisSelect.appendChild(option2);
    });
  } catch (error) {
    console.error('Failed to load stocks:', error);
  }
}

// Load strategies
async function loadStrategies() {
  try {
    const response = await fetch(`${API_BASE}/strategies`);
    const strategies = await response.json();

    const strategySelect = document.getElementById('backtest-strategy');
    strategies.forEach(strategy => {
      const option = document.createElement('option');
      option.value = strategy.name;
      option.textContent = strategy.description;
      strategySelect.appendChild(option);
    });
  } catch (error) {
    console.error('Failed to load strategies:', error);
  }
}

// Initialize charts
function initEquityChart() {
  const ctx = document.getElementById('equity-chart').getContext('2d');
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
        legend: {
          display: true
        }
      },
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: '日期'
          }
        },
        y: {
          display: true,
          title: {
            display: true,
            text: '价值 (CNY)'
          }
        }
      }
    }
  });
}

function initDrawdownChart() {
  const ctx = document.getElementById('drawdown-chart').getContext('2d');
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
        legend: {
          display: true
        }
      },
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: '日期'
          }
        },
        y: {
          display: true,
          title: {
            display: true,
            text: '回撤 (%)'
          },
          ticks: {
            callback: (value) => (value * 100).toFixed(0) + '%'
          }
        }
      }
    }
  });
}

function initBacktestEquityChart() {
  const ctx = document.getElementById('backtest-equity-chart').getContext('2d');
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
        legend: {
          display: true
        }
      },
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: '日期'
          }
        },
        y: {
          display: true,
          title: {
            display: true,
            text: '价值 (CNY)'
          }
        }
      }
    }
  });
}

function initAnalysisChart() {
  const ctx = document.getElementById('analysis-chart').getContext('2d');
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
        legend: {
          display: true
        }
      },
      scales: {
        x: {
          display: true,
          title: {
            display: true,
            text: '日期'
          }
        },
        y: {
          display: true,
          position: 'left',
          title: {
            display: true,
            text: '价格 (CNY)'
          }
        },
        y1: {
          display: true,
          position: 'right',
          title: {
            display: true,
            text: '回撤 (%)'
          },
          ticks: {
            callback: (value) => (value * 100).toFixed(0) + '%'
          },
          grid: {
            drawOnChartArea: false
          }
        }
      }
    }
  });
}

// Run backtest
async function runBacktest(stockCode, strategy, startDate, endDate, initialCapital) {
  showLoading();

  try {
    const response = await fetch(`${API_BASE}/backtest`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        stock_code: stockCode,
        strategy: strategy,
        start_date: startDate,
        end_date: endDate,
        initial_capital: initialCapital
      })
    });

    const result = await response.json();

    if (response.ok) {
      displayBacktestResults(result);
    } else {
      alert('回测失败：' + (result.error || '未知错误'));
    }
  } catch (error) {
    console.error('Backtest error:', error);
    alert('回测失败：' + error.message);
  } finally {
    hideLoading();
  }
}

// Display backtest results
function displayBacktestResults(result) {
  document.getElementById('backtest-results').style.display = 'block';

  // Update metrics
  const totalReturn = result.total_return || 0;
  document.getElementById('bt-total-return').textContent = formatPercent(totalReturn);
  document.getElementById('bt-total-return').className = 'metric ' + (totalReturn >= 0 ? 'positive' : 'negative');

  document.getElementById('bt-annual-return').textContent = formatPercent(result.annual_return || 0);
  document.getElementById('bt-max-drawdown').textContent = formatPercent(result.max_drawdown || 0);
  document.getElementById('bt-max-drawdown').className = 'metric negative';
  document.getElementById('bt-sharpe-ratio').textContent = formatNumber(result.sharpe_ratio || 0, 3);
  document.getElementById('bt-total-trades').textContent = result.total_trades || 0;
  document.getElementById('bt-win-rate').textContent = formatPercent(result.win_rate || 0);

  // Update chart
  if (backtestEquityChart) {
    const equityCurve = result.equity_curve || [];
    backtestEquityChart.data.labels = equityCurve.map(p => p.date);
    backtestEquityChart.data.datasets[0].data = equityCurve.map(p => p.equity);
    backtestEquityChart.update();
  }

  // Update trades table
  const tradesBody = document.getElementById('trades-body');
  tradesBody.innerHTML = '';
  const trades = result.trades || [];
  trades.forEach(trade => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td>${trade.timestamp}</td>
      <td>${trade.action}</td>
      <td>${formatNumber(trade.price)}</td>
      <td>${formatNumber(trade.quantity, 0)}</td>
      <td>${formatNumber(trade.commission)}</td>
    `;
    tradesBody.appendChild(row);
  });
}

// Analyze drawdown
async function analyzeDrawdown(stockCode, startDate, endDate) {
  showLoading();

  try {
    const response = await fetch(
      `${API_BASE}/drawdown/${encodeURIComponent(stockCode)}?start=${startDate}&end=${endDate}`
    );
    const result = await response.json();

    if (response.ok) {
      displayAnalysisResults(result);
    } else {
      alert('分析失败：' + (result.error || '未知错误'));
    }
  } catch (error) {
    console.error('Analysis error:', error);
    alert('分析失败：' + error.message);
  } finally {
    hideLoading();
  }
}

// Display analysis results
function displayAnalysisResults(result) {
  document.getElementById('analysis-results').style.display = 'block';

  // Update metrics
  document.getElementById('an-max-drawdown').textContent = formatPercent(result.drawdown || 0);
  document.getElementById('an-max-drawdown').className = 'metric negative';
  document.getElementById('an-peak-date').textContent = formatDate(result.peak_date);
  document.getElementById('an-trough-date').textContent = formatDate(result.trough_date);
  document.getElementById('an-duration').textContent = result.duration + ' 天';

  // Update chart
  if (analysisChart) {
    // Fetch K-line data for the chart
    fetchKlinesForAnalysis(result);
  }
}

async function fetchKlinesForAnalysis(drawdownInfo) {
  // This would fetch K-line data and update the chart
  // For now, just update with placeholder data
  analysisChart.data.labels = [drawdownInfo.peak_date, drawdownInfo.trough_date];
  analysisChart.data.datasets[0].data = [drawdownInfo.peak, drawdownInfo.trough];
  analysisChart.data.datasets[1].data = [0, drawdownInfo.drawdown];
  analysisChart.update();
}

// Setup event handlers
function setupEventHandlers() {
  // Backtest form
  document.getElementById('backtest-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const stockCode = document.getElementById('backtest-stock').value;
    const strategy = document.getElementById('backtest-strategy').value;
    const startDate = document.getElementById('backtest-start').value;
    const endDate = document.getElementById('backtest-end').value;
    const initialCapital = parseFloat(document.getElementById('backtest-capital').value);

    if (!stockCode) {
      alert('请选择股票代码');
      return;
    }

    runBacktest(stockCode, strategy, startDate, endDate, initialCapital);
  });

  // Analysis form
  document.getElementById('analysis-form').addEventListener('submit', (e) => {
    e.preventDefault();
    const stockCode = document.getElementById('analysis-stock').value;
    const startDate = document.getElementById('analysis-start').value;
    const endDate = document.getElementById('analysis-end').value;

    if (!stockCode) {
      alert('请选择股票代码');
      return;
    }

    analyzeDrawdown(stockCode, startDate, endDate);
  });

  // Settings form
  document.getElementById('settings-form').addEventListener('submit', (e) => {
    e.preventDefault();
    alert('设置已保存（功能开发中）');
  });
}

// Initialize application
document.addEventListener('DOMContentLoaded', () => {
  setupTabs();
  setupEventHandlers();
  initEquityChart();
  initDrawdownChart();
  initBacktestEquityChart();
  initAnalysisChart();
  loadStockList();
  loadStrategies();
});
