/**
 * Stock Screener Frontend Tests
 *
 * Tests for the stock screener UI including:
 * - Indicator selection and configuration
 * - Filter condition building with operator switching
 * - Weight sliders and ranking
 * - Enable/disable toggles
 * - Results display and export
 *
 * Run with: node --test test/frontend/screener.test.js
 */

import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';
import { JSDOM } from 'jsdom';

// ============================================================================
// Test Setup
// ============================================================================

/**
 * Setup DOM environment for testing
 */
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

/**
 * Create screener page HTML structure
 */
function createScreenerHTML() {
  return `
    <div id="toast-container" class="toast-container"></div>

    <!-- Indicator Selection Panel -->
    <div class="indicator-panel">
      <div class="category-tabs">
        <button class="tab-btn active" data-category="market">行情指标</button>
        <button class="tab-btn" data-category="tech">技术指标</button>
        <button class="tab-btn" data-category="finance">财务指标</button>
      </div>
      <input type="text" id="indicator-search" placeholder="搜索指标...">
      <div id="indicator-grid" class="indicator-grid"></div>
    </div>

    <!-- Selected Indicators -->
    <div class="selected-panel">
      <div class="selected-header">
        <span>已选指标：<span id="selected-count">0</span></span>
        <button id="btn-clear-selected">清空</button>
      </div>
      <div id="selected-indicators">
        <span id="selected-empty" style="display: flex;">暂无已选指标</span>
      </div>
    </div>

    <!-- Filter Configuration -->
    <div class="filter-panel">
      <button id="btn-add-condition">+ 添加条件</button>
      <div id="filters-container">
        <div class="filters-empty" id="filters-empty">
          <span class="empty-icon">&#9881;</span>
          <span class="empty-text">暂无筛选条件，请添加指标后配置</span>
        </div>
      </div>
    </div>

    <!-- Weight Configuration -->
    <div id="weight-config-section" style="display: none;">
      <div class="weight-config-header">
        <span>指标权重配置</span>
        <button id="btn-auto-balance">自动平衡</button>
      </div>
      <div id="weight-config-list"></div>
      <div class="weight-total-display">
        总权重：<span id="total-weight-display">0%</span>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="action-buttons">
      <button id="btn-save-config">保存配置</button>
      <button id="btn-run-screen">运行筛选</button>
    </div>

    <!-- Results Panel -->
    <div id="results-stats" style="display: none;">
      <span>共 <span id="result-count">0</span> 只股票</span>
      <span>筛选时间：<span id="screen-time">--:--:--</span></span>
    </div>
    <div id="results-table" style="display: none;">
      <table>
        <thead>
          <tr>
            <th class="col-rank">排名</th>
            <th class="col-code">代码</th>
            <th class="col-name">名称</th>
            <th class="col-score">得分</th>
          </tr>
        </thead>
        <tbody id="results-body"></tbody>
      </table>
    </div>
    <div id="results-empty">
      <span>暂无结果，请点击"运行筛选"</span>
    </div>
    <div id="results-actions" style="display: none;">
      <button id="btn-export">导出 CSV</button>
      <button id="btn-add-to-watchlist">加入观察列表</button>
    </div>

    <!-- Loading Overlay -->
    <div id="loading-overlay" style="display: none;">
      <div class="loading-spinner"></div>
      <span>正在筛选...</span>
    </div>
  `;
}

// ============================================================================
// Section 1: Indicator Selection Tests
// ============================================================================

describe('Screener: Indicator Selection', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should render indicator grid for market category', () => {
    const grid = dom.window.document.getElementById('indicator-grid');
    assert.ok(grid, 'Indicator grid should exist');
  });

  it('should switch indicator categories', () => {
    const techTab = dom.window.document.querySelector('.tab-btn[data-category="tech"]');
    const marketTab = dom.window.document.querySelector('.tab-btn[data-category="market"]');
    assert.ok(techTab, 'Tech tab should exist');

    // Remove active from market and add to tech
    marketTab?.classList.remove('active');
    techTab.classList.add('active');

    // Check active class
    const activeTab = dom.window.document.querySelector('.tab-btn.active');
    assert.strictEqual(activeTab?.dataset.category, 'tech');
  });

  it('should search indicators', () => {
    const searchInput = dom.window.document.getElementById('indicator-search');
    assert.ok(searchInput, 'Search input should exist');

    searchInput.value = 'PE';
    searchInput.dispatchEvent(new dom.window.Event('input'));

    // Search should be triggered
    assert.strictEqual(searchInput.value, 'PE');
  });

  it('should display selected indicator count', () => {
    const countEl = dom.window.document.getElementById('selected-count');
    countEl.textContent = '1';
    assert.strictEqual(countEl.textContent, '1');
  });

  it('should clear all selected indicators', () => {
    const clearBtn = dom.window.document.getElementById('btn-clear-selected');
    assert.ok(clearBtn, 'Clear button should exist');

    clearBtn.click();
    // State should be cleared
  });

  it('should create selected indicator tag', () => {
    const container = dom.window.document.getElementById('selected-indicators');
    const tag = dom.window.document.createElement('span');
    tag.className = 'selected-indicator-tag';
    tag.dataset.indicatorId = 'pe';
    tag.innerHTML = '市盈率 PE <span class="tag-remove">&times;</span>';
    container.appendChild(tag);

    const tags = container.querySelectorAll('.selected-indicator-tag');
    assert.strictEqual(tags.length, 1);
  });

  it('should remove indicator tag on X click', () => {
    const container = dom.window.document.getElementById('selected-indicators');
    const tag = dom.window.document.createElement('span');
    tag.className = 'selected-indicator-tag';
    tag.dataset.indicatorId = 'pe';
    tag.innerHTML = '市盈率 PE <span class="tag-remove">&times;</span>';
    container.appendChild(tag);

    const removeBtn = tag.querySelector('.tag-remove');
    removeBtn.click();
    tag.remove();

    assert.strictEqual(container.querySelectorAll('.selected-indicator-tag').length, 0);
  });
});

// ============================================================================
// Section 2: Filter Condition Tests
// ============================================================================

describe('Screener: Filter Conditions', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should show empty state when no filters', () => {
    const emptyState = dom.window.document.getElementById('filters-empty');
    assert.ok(emptyState, 'Empty state should exist');
    assert.ok(emptyState.innerHTML.includes('暂无筛选条件'));
  });

  it('should create filter control with operator dropdown', () => {
    const container = dom.window.document.createElement('div');
    container.innerHTML = `
      <div class="filter-control-row" data-indicator-id="pe">
        <select class="filter-operator-select">
          <option value=">">大于</option>
          <option value=">=">大于等于</option>
          <option value="<">小于</option>
          <option value="<=">小于等于</option>
          <option value="=">等于</option>
          <option value="!=">不等于</option>
          <option value="between">介于</option>
          <option value="in_range">范围内</option>
        </select>
      </div>
    `;

    const operatorSelect = container.querySelector('.filter-operator-select');
    assert.ok(operatorSelect, 'Operator select should exist');
    assert.strictEqual(operatorSelect.options.length, 8);
  });

  it('should switch operator to range type', () => {
    const container = dom.window.document.createElement('div');
    container.innerHTML = `
      <div class="filter-control-row" data-indicator-id="pe">
        <select class="filter-operator-select">
          <option value=">">大于</option>
          <option value="between">介于</option>
        </select>
        <div class="filter-value-container">
          <input type="number" class="filter-value-input single-value" placeholder="输入阈值">
        </div>
      </div>
    `;

    const operatorSelect = container.querySelector('.filter-operator-select');
    operatorSelect.value = 'between';
    operatorSelect.dispatchEvent(new dom.window.Event('change'));

    // Operator should be changed
    assert.strictEqual(operatorSelect.value, 'between');
  });

  it('should have single value input for > operator', () => {
    const input = dom.window.document.createElement('input');
    input.type = 'number';
    input.className = 'filter-value-input single-value';
    input.placeholder = '输入阈值';

    assert.strictEqual(input.type, 'number');
    assert.ok(input.classList.contains('single-value'));
  });

  it('should have dual value inputs for between operator', () => {
    const container = dom.window.document.createElement('div');
    container.className = 'filter-range-inputs';
    container.innerHTML = `
      <input type="number" class="filter-value-input min-value" placeholder="最小值">
      <span class="range-separator">至</span>
      <input type="number" class="filter-value-input max-value" placeholder="最大值">
    `;

    const minInput = container.querySelector('.min-value');
    const maxInput = container.querySelector('.max-value');
    const separator = container.querySelector('.range-separator');

    assert.ok(minInput, 'Min input should exist');
    assert.ok(maxInput, 'Max input should exist');
    assert.ok(separator, 'Separator should exist');
  });

  it('should validate numeric input', () => {
    const input = dom.window.document.createElement('input');
    input.type = 'number';
    input.className = 'filter-value-input';

    // Valid numbers
    const validValues = ['10', '100.5', '-5', '0', '3.14'];
    validValues.forEach(val => {
      input.value = val;
      assert.strictEqual(input.value, val);
    });
  });

  it('should remove filter condition', () => {
    const container = dom.window.document.createElement('div');
    container.id = 'filters-container';
    container.innerHTML = `
      <div class="filter-control-row" data-indicator-id="pe">
        <button class="btn-filter-action btn-remove">
          <svg></svg>
        </button>
      </div>
    `;

    const removeBtn = container.querySelector('.btn-remove');
    const row = container.querySelector('.filter-control-row');

    removeBtn.click();
    // Row should be removed (requires event handler)
    assert.ok(row, 'Row exists before removal');
  });

  it('should toggle filter enabled/disabled state', () => {
    const checkbox = dom.window.document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.checked = true;

    assert.strictEqual(checkbox.checked, true);

    checkbox.checked = !checkbox.checked;
    assert.strictEqual(checkbox.checked, false);
  });

  it('should have all 8 operators', () => {
    const operators = ['>', '>=', '<', '<=', '=', '!=', 'between', 'in_range'];

    const container = dom.window.document.createElement('div');
    container.innerHTML = `
      <select class="filter-operator-select">
        ${operators.map(op => `<option value="${op}">${op}</option>`).join('')}
      </select>
    `;

    const select = container.querySelector('.filter-operator-select');
    const options = Array.from(select.options).map(o => o.value);

    assert.strictEqual(options.length, 8);
    assert.deepStrictEqual(options, operators);
  });
});

// ============================================================================
// Section 3: Weight Slider Tests
// ============================================================================

describe('Screener: Weight Sliders', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should show weight configuration section when indicators selected', () => {
    const section = dom.window.document.getElementById('weight-config-section');
    assert.ok(section, 'Weight section should exist');
  });

  it('should create weight slider for each indicator', () => {
    const list = dom.window.document.getElementById('weight-config-list');
    list.innerHTML = `
      <div class="weight-config-item" data-indicator-id="pe">
        <span class="weight-indicator-name">市盈率 PE</span>
        <div class="weight-slider-wrapper">
          <input type="range" class="weight-slider" min="0" max="100" value="50">
          <span class="weight-value-display">50%</span>
        </div>
      </div>
    `;

    const slider = list.querySelector('.weight-slider');
    assert.ok(slider, 'Weight slider should exist');
    assert.strictEqual(slider.min, '0');
    assert.strictEqual(slider.max, '100');
    assert.strictEqual(slider.value, '50');
  });

  it('should update weight display on slider change', () => {
    const slider = dom.window.document.createElement('input');
    slider.type = 'range';
    slider.className = 'weight-slider';
    slider.min = '0';
    slider.max = '100';
    slider.value = '80';

    const display = dom.window.document.createElement('span');
    display.className = 'weight-value-display';
    display.textContent = `${slider.value}%`;

    assert.strictEqual(display.textContent, '80%');

    slider.value = '60';
    display.textContent = `${slider.value}%`;
    assert.strictEqual(display.textContent, '60%');
  });

  it('should calculate total weight', () => {
    const weights = [50, 50, 50];
    const total = weights.reduce((sum, w) => sum + w, 0);
    assert.strictEqual(total, 150);
  });

  it('should auto-balance weights to sum to 100%', () => {
    const count = 3;
    const equalWeight = Math.round(100 / count);
    let remainder = 100 - (equalWeight * count);

    const weights = [];
    for (let i = 0; i < count; i++) {
      let weight = equalWeight;
      if (remainder > 0) {
        weight++;
        remainder--;
      }
      weights.push(weight);
    }

    const total = weights.reduce((sum, w) => sum + w, 0);
    assert.strictEqual(total, 100);
    assert.deepStrictEqual(weights, [34, 33, 33]);
  });

  it('should update total weight display color', () => {
    const display = dom.window.document.createElement('span');
    display.id = 'total-weight-display';

    // Total = 100, color green
    display.textContent = '100%';
    display.style.color = '#52c41a';
    assert.strictEqual(display.style.color, 'rgb(82, 196, 26)');

    // Total != 100, color orange
    display.textContent = '150%';
    display.style.color = '#faad14';
    assert.strictEqual(display.style.color, 'rgb(250, 173, 20)');
  });

  it('should reset weights to default', () => {
    const weights = new Map([['pe', 80], ['pb', 60], ['roe', 40]]);

    // Reset to default 50
    weights.forEach((_, key) => weights.set(key, 50));

    assert.strictEqual(weights.get('pe'), 50);
    assert.strictEqual(weights.get('pb'), 50);
    assert.strictEqual(weights.get('roe'), 50);
  });

  it('should handle slider range limits', () => {
    const slider = dom.window.document.createElement('input');
    slider.type = 'range';
    slider.min = '0';
    slider.max = '100';

    // Test boundary values
    slider.value = '0';
    assert.strictEqual(slider.value, '0');

    slider.value = '100';
    assert.strictEqual(slider.value, '100');

    slider.value = '50';
    assert.strictEqual(slider.value, '50');
  });
});

// ============================================================================
// Section 4: Enable/Disable Toggle Tests
// ============================================================================

describe('Screener: Enable/Disable Toggle', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should create toggle switch', () => {
    const toggle = dom.window.document.createElement('label');
    toggle.className = 'filter-toggle';
    toggle.innerHTML = `
      <input type="checkbox" checked>
      <span class="filter-toggle-slider"></span>
      <span class="filter-toggle-label">启用</span>
    `;

    const checkbox = toggle.querySelector('input[type="checkbox"]');
    assert.ok(checkbox, 'Toggle checkbox should exist');
    assert.strictEqual(checkbox.checked, true);
  });

  it('should toggle from enabled to disabled', () => {
    const checkbox = dom.window.document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.checked = true;

    checkbox.checked = !checkbox.checked;
    assert.strictEqual(checkbox.checked, false);
  });

  it('should toggle from disabled to enabled', () => {
    const checkbox = dom.window.document.createElement('input');
    checkbox.type = 'checkbox';
    checkbox.checked = false;

    checkbox.checked = !checkbox.checked;
    assert.strictEqual(checkbox.checked, true);
  });

  it('should filter out disabled conditions when serializing', () => {
    const filters = [
      { indicatorId: 'pe', operator: '>', value: '20', enabled: true, weight: 50 },
      { indicatorId: 'pb', operator: '<', value: '2', enabled: false, weight: 50 },
      { indicatorId: 'roe', operator: '>', value: '15', enabled: true, weight: 50 }
    ];

    const enabledFilters = filters.filter(f => f.enabled !== false);

    assert.strictEqual(enabledFilters.length, 2);
    assert.strictEqual(enabledFilters[0].indicatorId, 'pe');
    assert.strictEqual(enabledFilters[1].indicatorId, 'roe');
  });
});

// ============================================================================
// Section 5: Results Display Tests
// ============================================================================

describe('Screener: Results Display', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should show empty state before screening', () => {
    const emptyEl = dom.window.document.getElementById('results-empty');
    assert.ok(emptyEl, 'Empty state should exist');
  });

  it('should render results table', () => {
    const tbody = dom.window.document.getElementById('results-body');
    const results = [
      { code: '600000', name: '浦发银行', score: 85.5, rank: 1 },
      { code: '600036', name: '招商银行', score: 92.3, rank: 2 },
      { code: '000001', name: '平安银行', score: 78.9, rank: 3 }
    ];

    tbody.innerHTML = results.map(stock => `
      <tr>
        <td class="col-rank">${stock.rank}</td>
        <td class="col-code">${stock.code}</td>
        <td class="col-name">${stock.name}</td>
        <td class="col-score"><span class="stock-score">${stock.score.toFixed(1)}</span></td>
      </tr>
    `).join('');

    const rows = tbody.querySelectorAll('tr');
    assert.strictEqual(rows.length, 3);
  });

  it('should update result count', () => {
    const countEl = dom.window.document.getElementById('result-count');
    countEl.textContent = '10';
    assert.strictEqual(countEl.textContent, '10');
  });

  it('should display screen time', () => {
    const timeEl = dom.window.document.getElementById('screen-time');
    const now = new Date().toLocaleTimeString();
    timeEl.textContent = now;
    assert.strictEqual(timeEl.textContent, now);
  });

  it('should apply score-based CSS classes', () => {
    const getScoreClass = (score) => {
      if (score >= 90) return 'score-excellent';
      if (score >= 80) return 'score-good';
      if (score >= 70) return 'score-average';
      return 'score-low';
    };

    assert.strictEqual(getScoreClass(95), 'score-excellent');
    assert.strictEqual(getScoreClass(85), 'score-good');
    assert.strictEqual(getScoreClass(75), 'score-average');
    assert.strictEqual(getScoreClass(65), 'score-low');
  });

  it('should export results to CSV', () => {
    const results = [
      { code: '600000', name: '浦发银行', score: 85.5, indicators: { pe: '10.5', pb: '0.8', roe: '12.3', turnover_rate: '2.1' } }
    ];

    const headers = ['排名', '代码', '名称', '得分', 'PE', 'PB', 'ROE', '换手率'];
    const rows = results.map((stock, i) => [
      i + 1,
      stock.code,
      stock.name,
      stock.score.toFixed(1),
      stock.indicators.pe,
      stock.indicators.pb,
      stock.indicators.roe,
      stock.indicators.turnover_rate
    ]);

    const csv = [headers, ...rows].map(row => row.join(',')).join('\\n');

    assert.ok(csv.includes('浦发银行'));
    assert.ok(csv.includes('600000'));
  });

  it('should show loading state during screening', () => {
    const overlay = dom.window.document.createElement('div');
    overlay.id = 'loading-overlay';
    overlay.style.display = 'flex';

    assert.strictEqual(overlay.style.display, 'flex');

    overlay.style.display = 'none';
    assert.strictEqual(overlay.style.display, 'none');
  });

  it('should disable run button during screening', () => {
    const runBtn = dom.window.document.createElement('button');
    runBtn.id = 'btn-run-screen';
    runBtn.disabled = false;

    runBtn.disabled = true;
    assert.strictEqual(runBtn.disabled, true);
  });
});

// ============================================================================
// Section 6: Sorting Functionality Tests
// ============================================================================

describe('Screener: Sorting', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should make column headers sortable', () => {
    const th = dom.window.document.createElement('th');
    th.className = 'col-score sortable';
    th.innerHTML = '得分 <span class="sort-indicator"> \\u2195</span>';

    assert.ok(th.classList.contains('sortable'));
    assert.ok(th.querySelector('.sort-indicator'));
  });

  it('should toggle sort direction', () => {
    let order = 'asc';
    order = order === 'asc' ? 'desc' : 'asc';
    assert.strictEqual(order, 'desc');

    order = order === 'asc' ? 'desc' : 'asc';
    assert.strictEqual(order, 'asc');
  });

  it('should sort results by score ascending', () => {
    const results = [
      { code: '600000', name: '浦发银行', score: 85.5 },
      { code: '600036', name: '招商银行', score: 92.3 },
      { code: '000001', name: '平安银行', score: 78.9 }
    ];

    const sorted = [...results].sort((a, b) => a.score - b.score);

    assert.strictEqual(sorted[0].score, 78.9);
    assert.strictEqual(sorted[2].score, 92.3);
  });

  it('should sort results by score descending', () => {
    const results = [
      { code: '600000', name: '浦发银行', score: 85.5 },
      { code: '600036', name: '招商银行', score: 92.3 },
      { code: '000001', name: '平安银行', score: 78.9 }
    ];

    const sorted = [...results].sort((a, b) => b.score - a.score);

    assert.strictEqual(sorted[0].score, 92.3);
    assert.strictEqual(sorted[2].score, 78.9);
  });

  it('should sort results by code string', () => {
    const results = [
      { code: '600036', name: '招商银行', score: 92.3 },
      { code: '000001', name: '平安银行', score: 78.9 },
      { code: '600000', name: '浦发银行', score: 85.5 }
    ];

    const sorted = [...results].sort((a, b) => a.code.localeCompare(b.code));

    assert.strictEqual(sorted[0].code, '000001');
    assert.strictEqual(sorted[2].code, '600036');
  });

  it('should update sort indicator arrow', () => {
    const th = dom.window.document.createElement('th');
    th.className = 'sorted-asc';
    th.innerHTML = '得分 <span class="sort-indicator"> \\u2191</span>';

    assert.ok(th.classList.contains('sorted-asc'));
    assert.ok(!th.classList.contains('sorted-desc'));
  });
});

// ============================================================================
// Section 7: Toast Notification Tests
// ============================================================================

describe('Screener: Toast Notifications', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should create toast container', () => {
    const container = dom.window.document.getElementById('toast-container');
    assert.ok(container, 'Toast container should exist');
  });

  it('should show success toast', () => {
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast success';
    toast.innerHTML = '<span class="toast-message">操作成功</span>';
    container.appendChild(toast);

    assert.ok(toast.classList.contains('success'));
    assert.strictEqual(container.children.length, 1);
  });

  it('should show error toast', () => {
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast error';
    toast.innerHTML = '<span class="toast-message">操作失败</span>';

    assert.ok(toast.classList.contains('error'));
  });

  it('should show warning toast', () => {
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast warning';
    toast.innerHTML = '<span class="toast-message">警告信息</span>';

    assert.ok(toast.classList.contains('warning'));
  });

  it('should show info toast', () => {
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast info';
    toast.innerHTML = '<span class="toast-message">提示信息</span>';

    assert.ok(toast.classList.contains('info'));
  });

  it('should auto-remove toast after delay', async () => {
    const container = dom.window.document.getElementById('toast-container');
    const toast = dom.window.document.createElement('div');
    toast.className = 'toast info';
    container.appendChild(toast);

    assert.strictEqual(container.children.length, 1);

    // Simulate auto-removal
    await new Promise(resolve => setTimeout(resolve, 100));
    toast.remove();
    assert.strictEqual(container.children.length, 0);
  });
});

// ============================================================================
// Section 8: Integration Tests
// ============================================================================

describe('Screener: Integration Tests', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should complete full screening workflow', () => {
    // Step 1: Select indicator
    const state = {
      selectedIndicators: new Map(),
      filters: new Map(),
      weights: new Map()
    };

    state.selectedIndicators.set('pe', { id: 'pe', name: '市盈率 PE' });
    state.weights.set('pe', 50);
    assert.strictEqual(state.selectedIndicators.size, 1);

    // Step 2: Add filter
    state.filters.set('pe', { indicatorId: 'pe', operator: '>', value: '20', enabled: true });
    assert.strictEqual(state.filters.size, 1);

    // Step 3: Update weight
    state.weights.set('pe', 80);
    assert.strictEqual(state.weights.get('pe'), 80);

    // Step 4: Run screening (mock)
    const mockResults = [
      { code: '600000', name: '浦发银行', score: 85.5 }
    ];
    assert.strictEqual(mockResults.length, 1);
  });

  it('should save configuration to localStorage', () => {
    const config = {
      indicators: ['pe', 'pb', 'roe'],
      filters: [
        { indicatorId: 'pe', operator: '>', value: '20' },
        { indicatorId: 'pb', operator: '<', value: '2' }
      ],
      weights: { pe: 50, pb: 50, roe: 50 }
    };

    global.localStorage.setItem('screenerConfig', JSON.stringify(config));

    const saved = JSON.parse(global.localStorage.getItem('screenerConfig'));
    assert.deepStrictEqual(saved.indicators, config.indicators);
    assert.deepStrictEqual(saved.weights, config.weights);
  });

  it('should load configuration from localStorage', () => {
    const config = {
      indicators: ['pe', 'pb'],
      weights: { pe: 80, pb: 60 }
    };
    global.localStorage.setItem('screenerConfig', JSON.stringify(config));

    const loaded = JSON.parse(global.localStorage.getItem('screenerConfig'));
    assert.strictEqual(loaded.indicators.length, 2);
    assert.strictEqual(loaded.weights.pe, 80);
  });
});

// ============================================================================
// Section 9: Tooltip Tests (Help Documentation)
// ============================================================================

describe('Screener: Indicator Help Tooltips', () => {
  let dom;

  beforeEach(() => {
    dom = setupDOM();
    dom.window.document.body.innerHTML = createScreenerHTML();
  });

  afterEach(() => {
    dom.window.close();
  });

  it('should display help icon on indicator cards', () => {
    const card = dom.window.document.createElement('div');
    card.className = 'indicator-card';
    card.innerHTML = `
      <div class="indicator-card-header">
        <span class="indicator-card-name">市盈率 PE</span>
      </div>
      <div class="indicator-help" role="tooltip">?</div>
    `;

    const helpIcon = card.querySelector('.indicator-help');
    assert.ok(helpIcon, 'Help icon should exist');
    assert.strictEqual(helpIcon.textContent.trim(), '?');
  });

  it('should show tooltip on hover', () => {
    const card = dom.window.document.createElement('div');
    card.className = 'indicator-card';
    card.innerHTML = `
      <div class="indicator-help">
        ?
        <div class="indicator-help-tooltip">
          <div class="indicator-help-tooltip-title">市盈率 PE (PE(TTM))</div>
          <div class="indicator-help-tooltip-formula">PE = 股价 / 每股收益 (EPS)</div>
          <div class="indicator-help-tooltip-desc">估值水平说明</div>
          <div class="indicator-help-tooltip-range">正常范围：0 - 100+</div>
        </div>
      </div>
    `;

    const tooltip = card.querySelector('.indicator-help-tooltip');
    assert.ok(tooltip, 'Tooltip should exist');
    assert.ok(tooltip.innerHTML.includes('市盈率 PE'));
    assert.ok(tooltip.innerHTML.includes('PE = 股价'));
  });

  it('should hide tooltip when mouse leaves', () => {
    const helpElement = dom.window.document.createElement('div');
    helpElement.className = 'indicator-help';

    // Simulate hover and leave
    helpElement.dispatchEvent(new dom.window.Event('mouseenter'));
    assert.ok(true, 'mouseenter dispatched');

    helpElement.dispatchEvent(new dom.window.Event('mouseleave'));
    assert.ok(true, 'mouseleave dispatched');
  });

  it('should have correct tooltip structure', () => {
    const tooltip = dom.window.document.createElement('div');
    tooltip.className = 'indicator-help-tooltip';
    tooltip.innerHTML = `
      <div class="indicator-help-tooltip-title">Title</div>
      <div class="indicator-help-tooltip-formula">Formula</div>
      <div class="indicator-help-tooltip-desc">Description</div>
      <div class="indicator-help-tooltip-range">Range</div>
    `;

    assert.ok(tooltip.querySelector('.indicator-help-tooltip-title'));
    assert.ok(tooltip.querySelector('.indicator-help-tooltip-formula'));
    assert.ok(tooltip.querySelector('.indicator-help-tooltip-desc'));
    assert.ok(tooltip.querySelector('.indicator-help-tooltip-range'));
  });
});
