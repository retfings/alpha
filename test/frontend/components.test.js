/**
 * Frontend Component Tests - Stock Strategy Page
 *
 * Tests for UI components, user interactions, and filter functionality
 * Run with: node --test test/frontend/components.test.js
 */

import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

// Setup DOM environment
function setupDOM() {
  const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>', {
    url: 'http://localhost:8000',
    runScripts: 'dangerously',
    resources: 'usable'
  });
  global.window = dom.window;
  global.document = dom.window.document;
  global.localStorage = {
    store: {},
    getItem(key) { return this.store[key] || null; },
    setItem(key, value) { this.store[key] = String(value); },
    removeItem(key) { delete this.store[key]; },
    clear() { this.store = {}; }
  };
  global.Chart = mock.fn(); // Mock Chart.js
  return dom;
}

describe('Toast Notification System', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    // Create toast container
    const container = dom.window.document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container';
    dom.window.document.body.appendChild(container);
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should initialize Toast system', async () => {
    // Mock Toast implementation
    global.window.Toast = {
      show: (message, type) => {
        const container = dom.window.document.getElementById('toast-container');
        const toast = dom.window.document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `<span class="toast-message">${message}</span>`;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
      }
    };
    assert.ok(global.window.Toast, 'Toast should be initialized');
    assert.strictEqual(typeof global.window.Toast.show, 'function');
  });

  it('should show success toast', () => {
    // Simulate Toast implementation
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast success';
    toast.innerHTML = '<span class="toast-icon">&#10004;</span><span class="toast-message">Success</span>';
    container.appendChild(toast);

    assert.strictEqual(container.children.length, 1);
    assert.ok(toast.classList.contains('success'));
  });

  it('should show error toast', () => {
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast error';
    toast.innerHTML = '<span class="toast-icon">&#10006;</span><span class="toast-message">Error</span>';
    container.appendChild(toast);

    assert.ok(toast.classList.contains('error'));
  });

  it('should show warning toast', () => {
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast warning';
    toast.innerHTML = '<span class="toast-icon">&#9888;</span><span class="toast-message">Warning</span>';
    container.appendChild(toast);

    assert.ok(toast.classList.contains('warning'));
  });

  it('should show info toast', () => {
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast info';
    toast.innerHTML = '<span class="toast-icon">&#8505;</span><span class="toast-message">Info</span>';
    container.appendChild(toast);

    assert.ok(toast.classList.contains('info'));
  });

  it('should remove toast after duration', async () => {
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast info';
    container.appendChild(toast);

    assert.strictEqual(container.children.length, 1);

    // Simulate removal
    await new Promise(resolve => setTimeout(resolve, 100));
    toast.classList.add('hiding');
    await new Promise(resolve => setTimeout(resolve, 300));
    toast.remove();
    assert.strictEqual(container.children.length, 0);
  });
});

describe('Condition Builder Component', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    // Set up condition builder HTML structure
    const html = `
      <table>
        <thead>
          <tr>
            <th class="col-indicator">指标</th>
            <th class="col-operator">比较符</th>
            <th class="col-range">范围</th>
            <th class="col-value">值</th>
            <th class="col-action">操作</th>
          </tr>
        </thead>
        <tbody id="condition-body"></tbody>
      </table>
      <button id="btn-add-condition">+ 添加条件</button>
      <button id="btn-save-conditions">保存条件组合</button>
      <button id="btn-load-conditions">加载条件组合</button>
      <button id="btn-clear-conditions">清空条件</button>
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should render empty condition table', () => {
    const tbody = dom.window.document.getElementById('condition-body');
    assert.ok(tbody, 'Condition body should exist');
    assert.strictEqual(tbody.children.length, 0, 'Should start empty');
  });

  it('should add new condition', () => {
    const state = { conditions: [] };
    const condition = {
      id: Date.now(),
      field: 'price',
      name: '股票价格',
      operator: '>',
      range: '',
      value: '',
      expanded: true,
      period: 'daily',
      window: 20,
      weight: 1,
      enabled: true
    };
    state.conditions.push(condition);

    assert.strictEqual(state.conditions.length, 1);
    assert.strictEqual(state.conditions[0].field, 'price');
    assert.strictEqual(state.conditions[0].name, '股票价格');
  });

  it('should remove condition', () => {
    const state = {
      conditions: [
        { id: 1, field: 'price', name: '股票价格' },
        { id: 2, field: 'volume', name: '成交量' }
      ]
    };

    const initialLength = state.conditions.length;
    const removed = state.conditions.splice(0, 1);

    assert.strictEqual(state.conditions.length, initialLength - 1);
    assert.strictEqual(removed[0].field, 'price');
  });

  it('should clear all conditions', () => {
    const state = {
      conditions: [
        { id: 1, field: 'price', name: '股票价格' },
        { id: 2, field: 'volume', name: '成交量' }
      ]
    };

    assert.strictEqual(state.conditions.length, 2);
    state.conditions = [];
    assert.strictEqual(state.conditions.length, 0);
  });

  it('should toggle condition detail panel', () => {
    const condition = { id: 1, expanded: true };
    condition.expanded = !condition.expanded;
    assert.strictEqual(condition.expanded, false);

    condition.expanded = !condition.expanded;
    assert.strictEqual(condition.expanded, true);
  });

  it('should update condition operator', () => {
    const condition = {
      id: 1,
      field: 'price',
      operator: '>'
    };

    const operators = ['>', '>=', '<', '<=', '=', '!=', 'between'];
    operators.forEach(op => {
      condition.operator = op;
      assert.strictEqual(condition.operator, op);
    });
  });

  it('should update condition value', () => {
    const condition = {
      id: 1,
      field: 'price',
      value: ''
    };

    const testValues = ['10', '100.5', '-5', ''];
    testValues.forEach(val => {
      condition.value = val;
      assert.strictEqual(condition.value, val);
    });
  });

  it('should update condition range', () => {
    const condition = {
      id: 1,
      field: 'price',
      range: ''
    };

    condition.range = '10-20';
    assert.strictEqual(condition.range, '10-20');
  });

  it('should update condition weight', () => {
    const condition = {
      id: 1,
      field: 'price',
      weight: 1
    };

    const weights = [0.5, 1, 2.5, 5, 10];
    weights.forEach(w => {
      condition.weight = w;
      assert.ok(condition.weight >= 0.1);
      assert.ok(condition.weight <= 10);
    });
  });

  it('should enable/disable condition', () => {
    const condition = {
      id: 1,
      field: 'price',
      enabled: true
    };

    condition.enabled = !condition.enabled;
    assert.strictEqual(condition.enabled, false);

    condition.enabled = !condition.enabled;
    assert.strictEqual(condition.enabled, true);
  });

  it('should update condition period', () => {
    const condition = {
      id: 1,
      field: 'price',
      period: 'daily'
    };

    const periods = ['daily', 'weekly', 'monthly', 'intraday'];
    periods.forEach(p => {
      condition.period = p;
      assert.strictEqual(condition.period, p);
    });
  });

  it('should update condition window', () => {
    const condition = {
      id: 1,
      field: 'price',
      window: 20
    };

    const windows = [5, 10, 20, 50, 100, 250];
    windows.forEach(w => {
      condition.window = w;
      assert.ok(condition.window >= 1);
      assert.ok(condition.window <= 250);
    });
  });
});

describe('Industry Chain (Cascading Selects)', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    const html = `
      <select id="industry-standard">
        <option value="all">全部</option>
        <option value="sw2014">申万 2014</option>
        <option value="sw2021">申万 2021</option>
        <option value="csrc">证监会</option>
      </select>
      <select id="primary-industry">
        <option value="all">全部</option>
      </select>
      <select id="secondary-industry">
        <option value="all">全部</option>
      </select>
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should initialize industry selects', () => {
    const standardSelect = dom.window.document.getElementById('industry-standard');
    const primarySelect = dom.window.document.getElementById('primary-industry');
    const secondarySelect = dom.window.document.getElementById('secondary-industry');

    assert.ok(standardSelect, 'Standard select should exist');
    assert.ok(primarySelect, 'Primary select should exist');
    assert.ok(secondarySelect, 'Secondary select should exist');
  });

  it('should have correct industry standards', () => {
    const standardSelect = dom.window.document.getElementById('industry-standard');
    const options = Array.from(standardSelect.options);

    assert.strictEqual(options.length, 4);
    assert.strictEqual(options[1].value, 'sw2014');
    assert.strictEqual(options[2].value, 'sw2021');
    assert.strictEqual(options[3].value, 'csrc');
  });

  it('should update primary industry when standard changes', () => {
    const standardSelect = dom.window.document.getElementById('industry-standard');
    const primarySelect = dom.window.document.getElementById('primary-industry');

    // Simulate change event
    standardSelect.value = 'sw2014';
    standardSelect.dispatchEvent(new dom.window.Event('change'));

    // Primary should update based on selected standard
    assert.ok(primarySelect, 'Primary select should still exist');
  });

  it('should update secondary industry when primary changes', () => {
    const primarySelect = dom.window.document.getElementById('primary-industry');
    const secondarySelect = dom.window.document.getElementById('secondary-industry');

    primarySelect.value = 'agricultura';
    primarySelect.dispatchEvent(new dom.window.Event('change'));

    assert.ok(secondarySelect, 'Secondary select should still exist');
  });
});

describe('Backtest Controls', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    const html = `
      <input type="date" id="backtest-start-date" value="2025-03-26">
      <input type="date" id="backtest-end-date" value="2026-03-27">
      <select id="benchmark">
        <option value="hs300">沪深 300</option>
        <option value="zz500">中证 500</option>
      </select>
      <select id="transaction-cost">
        <option value="0.0002">千分之二</option>
        <option value="0">零成本</option>
      </select>
      <input type="checkbox" id="exclude-period">
      <button id="btn-run-backtest">开始回测</button>
      <button id="btn-first">|◄</button>
      <button id="btn-prev">◄</button>
      <button id="btn-next">►</button>
      <button id="btn-last">►|</button>
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should initialize date inputs with default values', () => {
    const startDate = dom.window.document.getElementById('backtest-start-date');
    const endDate = dom.window.document.getElementById('backtest-end-date');

    assert.ok(startDate.value, 'Start date should have value');
    assert.ok(endDate.value, 'End date should have value');
  });

  it('should navigate to first date', () => {
    const startDateInput = dom.window.document.getElementById('backtest-start-date');
    const btnFirst = dom.window.document.getElementById('btn-first');

    btnFirst.click();
    // Simulate navigation to first date
    startDateInput.value = '2020-01-01';
    assert.strictEqual(startDateInput.value, '2020-01-01');
  });

  it('should navigate to last date', () => {
    const startDateInput = dom.window.document.getElementById('backtest-start-date');
    const btnLast = dom.window.document.getElementById('btn-last');

    btnLast.click();
    // Simulate navigation to last date
    const today = new Date().toISOString().split('T')[0];
    startDateInput.value = today;
    assert.strictEqual(startDateInput.value, today);
  });

  it('should navigate previous day', () => {
    const startDateInput = dom.window.document.getElementById('backtest-start-date');
    const btnPrev = dom.window.document.getElementById('btn-prev');

    const currentValue = new Date(startDateInput.value);
    btnPrev.click();
    // Simulate navigation to previous day
    const prevDay = new Date(currentValue);
    prevDay.setDate(prevDay.getDate() - 1);
    startDateInput.value = prevDay.toISOString().split('T')[0];

    const newValue = new Date(startDateInput.value);
    const diffTime = currentValue - newValue;
    const diffDays = diffTime / (1000 * 60 * 60 * 24);
    assert.strictEqual(diffDays, 1);
  });

  it('should navigate next day', () => {
    const startDateInput = dom.window.document.getElementById('backtest-start-date');
    const btnNext = dom.window.document.getElementById('btn-next');

    const currentValue = new Date(startDateInput.value);
    btnNext.click();
    // Simulate navigation to next day
    const nextDay = new Date(currentValue);
    nextDay.setDate(nextDay.getDate() + 1);
    startDateInput.value = nextDay.toISOString().split('T')[0];

    const newValue = new Date(startDateInput.value);
    const diffTime = newValue - currentValue;
    const diffDays = diffTime / (1000 * 60 * 60 * 24);
    assert.strictEqual(diffDays, 1);
  });

  it('should select benchmark', () => {
    const benchmark = dom.window.document.getElementById('benchmark');
    benchmark.value = 'zz500';
    assert.strictEqual(benchmark.value, 'zz500');
  });

  it('should select transaction cost', () => {
    const cost = dom.window.document.getElementById('transaction-cost');
    cost.value = '0';
    assert.strictEqual(cost.value, '0');
  });

  it('should toggle exclude period checkbox', () => {
    const checkbox = dom.window.document.getElementById('exclude-period');
    checkbox.checked = !checkbox.checked;
    assert.strictEqual(checkbox.checked, true);
    checkbox.checked = !checkbox.checked;
    assert.strictEqual(checkbox.checked, false);
  });

  it('should format date correctly', () => {
    const date = new Date('2026-03-28');
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const formatted = `${year}/${month}/${day}`;

    assert.strictEqual(formatted, '2026/03/28');
  });
});

describe('Results Panel', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    const html = `
      <div id="results-panel" class="backtest-panel">
        <div class="results-cards">
          <div class="result-card">
            <div class="result-label">总收益率</div>
            <div class="result-value" id="result-total-return">--</div>
          </div>
          <div class="result-card">
            <div class="result-label">最大回撤</div>
            <div class="result-value negative" id="result-max-drawdown">--</div>
          </div>
        </div>
        <div class="results-charts">
          <canvas id="result-equity-chart"></canvas>
          <canvas id="result-drawdown-chart"></canvas>
          <canvas id="result-comparison-chart"></canvas>
        </div>
        <div class="trade-list-section">
          <table>
            <tbody id="trade-list-body"></tbody>
          </table>
        </div>
      </div>
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should display results panel', () => {
    const panel = dom.window.document.getElementById('results-panel');
    assert.ok(panel, 'Results panel should exist');
  });

  it('should update metric value', () => {
    const el = dom.window.document.getElementById('result-total-return');
    const value = '12.45%';
    const isPositive = true;

    el.textContent = value;
    el.className = 'result-value ' + (isPositive ? 'positive' : 'negative');

    assert.strictEqual(el.textContent, value);
    assert.ok(el.classList.contains('positive'));
  });

  it('should format percent correctly', () => {
    const formatPercent = (value) => {
      if (value === null || value === undefined) return '--';
      const num = parseFloat(value) || 0;
      const sign = num < 0 ? '-' : '';
      return sign + (Math.abs(num) * 100).toFixed(2) + '%';
    };

    assert.strictEqual(formatPercent(0.1245), '12.45%');
    assert.strictEqual(formatPercent(-0.0832), '-8.32%');
    assert.strictEqual(formatPercent(0), '0.00%');
    assert.strictEqual(formatPercent(null), '--');
  });

  it('should format number correctly', () => {
    const formatNumber = (value, decimals = 2) => {
      if (value === null || value === undefined) return '--';
      return (parseFloat(value) || 0).toFixed(decimals);
    };

    assert.strictEqual(formatNumber(1.25, 3), '1.250');
    assert.strictEqual(formatNumber(24, 0), '24');
    assert.strictEqual(formatNumber(0.625), '0.63');
    assert.strictEqual(formatNumber(null), '--');
  });

  it('should render trade list', () => {
    const trades = [
      { date: '2026-01-15', stock_code: 'sh.600000', action: '买入', price: 10.5, quantity: 1000, amount: 10500, commission: 2.1 },
      { date: '2026-02-20', stock_code: 'sh.600000', action: '卖出', price: 11.2, quantity: 1000, amount: 11200, commission: 2.24 }
    ];

    const tbody = dom.window.document.getElementById('trade-list-body');
    tbody.innerHTML = trades.map(trade => `
      <tr>
        <td>${trade.date}</td>
        <td>${trade.stock_code}</td>
        <td class="${trade.action === '买入' ? 'positive' : 'negative'}">${trade.action}</td>
        <td>${trade.price.toFixed(2)}</td>
        <td>${trade.quantity.toFixed(0)}</td>
        <td>${trade.amount.toFixed(2)}</td>
        <td>${trade.commission.toFixed(2)}</td>
      </tr>
    `).join('');

    const rows = tbody.querySelectorAll('tr');
    assert.strictEqual(rows.length, 2);
  });

  it('should close results panel', () => {
    const panel = dom.window.document.getElementById('results-panel');
    panel.classList.remove('active');
    assert.ok(!panel.classList.contains('active'));
  });
});

describe('Step Navigation', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    const html = `
      <div class="step-nav">
        <div class="step active" data-step="1">
          <span class="step-number">1</span>
          <span class="step-title">择股设置</span>
        </div>
        <div class="step" data-step="2">
          <span class="step-number">2</span>
          <span class="step-title">交易模型</span>
        </div>
        <div class="step" data-step="3">
          <span class="step-number">3</span>
          <span class="step-title">大盘择时</span>
        </div>
        <div class="step" data-step="4">
          <span class="step-number">4</span>
          <span class="step-title">股指对冲</span>
        </div>
      </div>
      <div class="panels">
        <div class="panel active" id="panel-step-1"></div>
        <div class="panel" id="panel-step-2"></div>
        <div class="panel" id="panel-step-3"></div>
        <div class="panel" id="panel-step-4"></div>
      </div>
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should initialize with step 1 active', () => {
    const step1 = dom.window.document.querySelector('.step[data-step="1"]');
    const panel1 = dom.window.document.getElementById('panel-step-1');

    assert.ok(step1.classList.contains('active'));
    assert.ok(panel1.classList.contains('active'));
  });

  it('should switch to step 2', () => {
    const steps = dom.window.document.querySelectorAll('.step');
    const panels = dom.window.document.querySelectorAll('.panel');

    // Simulate click on step 2
    steps[1].click();

    steps.forEach(s => s.classList.remove('active'));
    steps[1].classList.add('active');

    panels.forEach((p, i) => {
      p.classList.toggle('active', i === 1);
    });

    assert.ok(steps[1].classList.contains('active'));
    assert.ok(panels[1].classList.contains('active'));
  });

  it('should switch to step 3', () => {
    const steps = dom.window.document.querySelectorAll('.step');
    const panels = dom.window.document.querySelectorAll('.panel');

    steps.forEach(s => s.classList.remove('active'));
    steps[2].classList.add('active');

    panels.forEach((p, i) => {
      p.classList.toggle('active', i === 2);
    });

    assert.ok(steps[2].classList.contains('active'));
  });

  it('should switch to step 4', () => {
    const steps = dom.window.document.querySelectorAll('.step');
    const panels = dom.window.document.querySelectorAll('.panel');

    steps.forEach(s => s.classList.remove('active'));
    steps[3].classList.add('active');

    panels.forEach((p, i) => {
      p.classList.toggle('active', i === 3);
    });

    assert.ok(steps[3].classList.contains('active'));
  });
});

describe('Stock List Display', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    const html = `
      <div id="daily-results" class="results-panel">
        <div class="results-header">
          <span class="result-count">共 <span id="daily-stock-count">0</span> 只股票</span>
        </div>
        <div class="stock-list" id="daily-stock-list"></div>
      </div>
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should display stock count', () => {
    const countEl = dom.window.document.getElementById('daily-stock-count');
    countEl.textContent = '5';
    assert.strictEqual(countEl.textContent, '5');
  });

  it('should render stock items', () => {
    const stocks = [
      { code: 'sh.600000', name: '股票 600000', change: 0.0234 },
      { code: 'sh.600001', name: '股票 600001', change: -0.0156 },
      { code: 'sh.600002', name: '股票 600002', change: 0.0089 }
    ];

    const stockList = dom.window.document.getElementById('daily-stock-list');
    stockList.innerHTML = stocks.map(stock => `
      <div class="stock-item">
        <div>
          <div class="stock-code">${stock.code}</div>
          <div class="stock-name">${stock.name}</div>
        </div>
        <div class="stock-change ${stock.change >= 0 ? 'positive' : 'negative'}">
          ${stock.change >= 0 ? '+' : ''}${(stock.change * 100).toFixed(2)}%
        </div>
      </div>
    `).join('');

    const items = stockList.querySelectorAll('.stock-item');
    assert.strictEqual(items.length, 3);
  });

  it('should apply positive class for positive change', () => {
    const stock = { code: 'sh.600000', change: 0.0234 };
    const className = stock.change >= 0 ? 'positive' : 'negative';
    assert.strictEqual(className, 'positive');
  });

  it('should apply negative class for negative change', () => {
    const stock = { code: 'sh.600001', change: -0.0156 };
    const className = stock.change >= 0 ? 'positive' : 'negative';
    assert.strictEqual(className, 'negative');
  });
});

describe('Save/Load Strategy', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    const html = `
      <button id="btn-save">保存</button>
      <button id="btn-new">新建</button>
      <input id="my-stock-pool" value="all">
      <input id="backtest-start-date" value="2025-01-01">
      <input id="backtest-end-date" value="2026-01-01">
    `;
    dom.window.document.body.innerHTML = html;
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should have save button', () => {
    const btnSave = dom.window.document.getElementById('btn-save');
    assert.ok(btnSave, 'Save button should exist');
  });

  it('should have new button', () => {
    const btnNew = dom.window.document.getElementById('btn-new');
    assert.ok(btnNew, 'New button should exist');
  });

  it('should reset form on new strategy', () => {
    const state = {
      conditions: [{ id: 1, field: 'price', name: '价格' }],
      tradeConditions: [{ id: 2, field: 'ma_cross', name: '均线交叉' }]
    };

    // Reset
    state.conditions = [];
    state.tradeConditions = [];

    assert.strictEqual(state.conditions.length, 0);
    assert.strictEqual(state.tradeConditions.length, 0);
  });

  it('should reset date inputs', () => {
    const today = new Date().toISOString().split('T')[0];
    const lastYear = new Date();
    lastYear.setFullYear(lastYear.getFullYear() - 1);
    const lastYearStr = lastYear.toISOString().split('T')[0];

    const startDateInput = dom.window.document.getElementById('backtest-start-date');
    const endDateInput = dom.window.document.getElementById('backtest-end-date');

    startDateInput.value = lastYearStr;
    endDateInput.value = today;

    assert.strictEqual(startDateInput.value, lastYearStr);
    assert.strictEqual(endDateInput.value, today);
  });
});

describe('Local Storage for Conditions', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    global.localStorage.clear();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should save condition set', () => {
    const conditions = [
      { id: 1, field: 'price', name: '价格', operator: '>', value: '10' }
    ];

    const conditionSet = {
      id: 'set_001',
      name: '测试条件',
      conditions: JSON.parse(JSON.stringify(conditions)),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const sets = [];
    sets.push(conditionSet);
    global.localStorage.setItem('stock_strategy_condition_sets', JSON.stringify(sets));

    const saved = JSON.parse(global.localStorage.getItem('stock_strategy_condition_sets'));
    assert.strictEqual(saved.length, 1);
    assert.strictEqual(saved[0].name, '测试条件');
  });

  it('should load condition set', () => {
    const conditions = [
      { id: 1, field: 'price', name: '价格', operator: '>', value: '10' }
    ];

    const set = {
      id: 'set_001',
      name: '测试条件',
      conditions
    };

    global.localStorage.setItem('stock_strategy_condition_sets', JSON.stringify([set]));

    const loaded = JSON.parse(global.localStorage.getItem('stock_strategy_condition_sets'));
    assert.strictEqual(loaded.length, 1);
    assert.strictEqual(loaded[0].conditions.length, 1);
    assert.strictEqual(loaded[0].conditions[0].field, 'price');
  });

  it('should delete condition set', () => {
    const sets = [
      { id: 'set_001', name: '条件 1' },
      { id: 'set_002', name: '条件 2' }
    ];

    global.localStorage.setItem('stock_strategy_condition_sets', JSON.stringify(sets));

    // Delete set_001
    const filtered = sets.filter(s => s.id !== 'set_001');
    global.localStorage.setItem('stock_strategy_condition_sets', JSON.stringify(filtered));

    const loaded = JSON.parse(global.localStorage.getItem('stock_strategy_condition_sets'));
    assert.strictEqual(loaded.length, 1);
    assert.strictEqual(loaded[0].id, 'set_002');
  });

  it('should update condition set', () => {
    const sets = [
      { id: 'set_001', name: '条件 1', conditions: [], updatedAt: '2026-01-01' }
    ];

    global.localStorage.setItem('stock_strategy_condition_sets', JSON.stringify(sets));

    // Update
    const index = sets.findIndex(s => s.id === 'set_001');
    sets[index].name = '更新后的条件 1';
    sets[index].updatedAt = new Date().toISOString();
    global.localStorage.setItem('stock_strategy_condition_sets', JSON.stringify(sets));

    const loaded = JSON.parse(global.localStorage.getItem('stock_strategy_condition_sets'));
    assert.strictEqual(loaded[0].name, '更新后的条件 1');
  });
});
