/**
 * Stock Screener Page
 *
 * Main functionality for stock screening with:
 * - Indicator selection and configuration
 * - Filter condition building
 * - Weight-based ranking
 * - Results display and export
 */

import * as indicatorModule from './components/indicator-card.js';
import * as filterModule from './components/filter-controls.js';

// ============================================================================
// Application State
// ============================================================================

const state = {
  selectedIndicators: new Map(), // id -> indicator data
  filters: new Map(), // indicatorId -> filter config
  weights: new Map(), // indicatorId -> weight (0-100)
  currentCategory: 'market',
  searchQuery: '',
  results: [],
  isScreening: false
};

// ============================================================================
// Initialization
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
  initializeIndicators();
  setupEventHandlers();
  renderIndicatorGrid('market');
});

/**
 * Initialize indicator grid with default category
 */
function initializeIndicators() {
  const grid = document.getElementById('indicator-grid');
  if (!grid) return;

  // Render initial category
  renderIndicatorGrid('market');
}

/**
 * Set up all event handlers
 */
function setupEventHandlers() {
  // Category tabs
  document.querySelectorAll('.category-tabs .tab-btn').forEach(btn => {
    btn.addEventListener('click', handleCategoryChange);
  });

  // Indicator search
  const searchInput = document.getElementById('indicator-search');
  if (searchInput) {
    searchInput.addEventListener('input', handleSearch);
  }

  // Clear selected button
  const clearBtn = document.getElementById('btn-clear-selected');
  if (clearBtn) {
    clearBtn.addEventListener('click', clearAllSelected);
  }

  // Add condition button
  const addConditionBtn = document.getElementById('btn-add-condition');
  if (addConditionBtn) {
    addConditionBtn.addEventListener('click', addRandomCondition);
  }

  // Save config button
  const saveConfigBtn = document.getElementById('btn-save-config');
  if (saveConfigBtn) {
    saveConfigBtn.addEventListener('click', saveConfiguration);
  }

  // Run screen button
  const runScreenBtn = document.getElementById('btn-run-screen');
  if (runScreenBtn) {
    runScreenBtn.addEventListener('click', runScreener);
  }

  // Auto balance weights
  const autoBalanceBtn = document.getElementById('btn-auto-balance');
  if (autoBalanceBtn) {
    autoBalanceBtn.addEventListener('click', autoBalanceWeights);
  }

  // Export button
  const exportBtn = document.getElementById('btn-export');
  if (exportBtn) {
    exportBtn.addEventListener('click', exportResults);
  }

  // Add to watchlist button
  const watchlistBtn = document.getElementById('btn-add-to-watchlist');
  if (watchlistBtn) {
    watchlistBtn.addEventListener('click', addToWatchlist);
  }

  // Navigation
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', handleNavigation);
  });
}

// ============================================================================
// Indicator Grid Management
// ============================================================================

/**
 * Render indicator grid for a category
 * @param {string} category - Category to render
 */
function renderIndicatorGrid(category) {
  const grid = document.getElementById('indicator-grid');
  if (!grid) return;

  const indicators = indicatorModule.getIndicatorsByCategory(category);
  grid.innerHTML = '';

  indicators.forEach(indicator => {
    const isSelected = state.selectedIndicators.has(indicator.id);
    const card = indicatorModule.createIndicatorCard(indicator, isSelected);
    grid.appendChild(card);
  });

  // Set up card click handlers
  indicatorModule.setupIndicatorHandlers(grid, handleIndicatorSelect, handleIndicatorDeselect);
}

/**
 * Handle category tab change
 * @param {Event} e - Click event
 */
function handleCategoryChange(e) {
  const category = e.target.dataset.category;
  if (!category) return;

  // Update active tab
  document.querySelectorAll('.category-tabs .tab-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.category === category);
  });

  state.currentCategory = category;
  renderIndicatorGrid(category);
}

/**
 * Handle indicator search
 * @param {Event} e - Input event
 */
function handleSearch(e) {
  const query = e.target.value.trim().toLowerCase();
  state.searchQuery = query;

  const grid = document.getElementById('indicator-grid');
  if (!grid) return;

  if (query) {
    // Search across all categories
    const results = indicatorModule.searchIndicators(query);
    renderSearchResults(grid, results);
  } else {
    // Show current category
    renderIndicatorGrid(state.currentCategory);
  }
}

/**
 * Render search results
 * @param {HTMLElement} grid - Grid container
 * @param {Array} results - Search results
 */
function renderSearchResults(grid, results) {
  grid.innerHTML = '';

  results.forEach(indicator => {
    const isSelected = state.selectedIndicators.has(indicator.id);
    const card = indicatorModule.createIndicatorCard(indicator, isSelected);
    grid.appendChild(card);
  });

  indicatorModule.setupIndicatorHandlers(grid, handleIndicatorSelect, handleIndicatorDeselect);
}

// ============================================================================
// Indicator Selection
// ============================================================================

/**
 * Handle indicator selection
 * @param {string} indicatorId - Selected indicator ID
 */
function handleIndicatorSelect(indicatorId) {
  const indicator = indicatorModule.getIndicatorById(indicatorId);
  if (!indicator) return;

  state.selectedIndicators.set(indicatorId, indicator);
  state.weights.set(indicatorId, 50); // Default weight

  updateSelectedIndicatorsList();
  updateWeightConfig();
  showToast(`已添加指标：${indicator.name}`, 'success');
}

/**
 * Handle indicator deselection
 * @param {string} indicatorId - Deselected indicator ID
 */
function handleIndicatorDeselect(indicatorId) {
  state.selectedIndicators.delete(indicatorId);
  state.filters.delete(indicatorId);
  state.weights.delete(indicatorId);

  updateSelectedIndicatorsList();
  updateWeightConfig();
  removeFilterControl(indicatorId);
  showToast(`已移除指标：${indicatorId}`, 'info');
}

/**
 * Update selected indicators list UI
 */
function updateSelectedIndicatorsList() {
  const container = document.getElementById('selected-indicators');
  const countEl = document.getElementById('selected-count');
  const emptyEl = document.getElementById('selected-empty');

  if (!container) return;

  countEl.textContent = state.selectedIndicators.size;

  // Clear existing tags
  container.innerHTML = '';

  if (state.selectedIndicators.size === 0) {
    container.appendChild(emptyEl);
    emptyEl.style.display = 'flex';
  } else {
    state.selectedIndicators.forEach((indicator, id) => {
      const tag = indicatorModule.createSelectedIndicatorTag(indicator);
      container.appendChild(tag);
    });

    // Set up tag handlers
    indicatorModule.setupTagHandlers(container, handleTagRemove);
  }
}

/**
 * Handle tag removal
 * @param {string} indicatorId - Indicator ID to remove
 */
function handleTagRemove(indicatorId) {
  const indicator = indicatorModule.getIndicatorById(indicatorId);
  if (!indicator) return;

  // Update grid card
  const grid = document.getElementById('indicator-grid');
  const card = grid?.querySelector(`[data-indicator-id="${indicatorId}"]`);
  if (card) {
    card.classList.remove('selected');
  }

  handleIndicatorDeselect(indicatorId);
}

/**
 * Clear all selected indicators
 */
function clearAllSelected() {
  state.selectedIndicators.clear();
  state.filters.clear();
  state.weights.clear();

  // Update grid cards
  const grid = document.getElementById('indicator-grid');
  grid?.querySelectorAll('.indicator-card.selected').forEach(card => {
    card.classList.remove('selected');
  });

  updateSelectedIndicatorsList();
  updateWeightConfig();
  document.getElementById('filters-container').innerHTML = `
    <div class="filters-empty" id="filters-empty">
      <span class="empty-icon">⚙️</span>
      <span class="empty-text">暂无筛选条件，请添加指标后配置</span>
    </div>
  `;

  showToast('已清空所有已选指标', 'info');
}

// ============================================================================
// Filter Configuration
// ============================================================================

/**
 * Add a random condition (placeholder - should show a modal)
 */
function addRandomCondition() {
  if (state.selectedIndicators.size === 0) {
    showToast('请先选择至少一个指标', 'warning');
    return;
  }

  // Add filter for first selected indicator without filter
  for (const [id, indicator] of state.selectedIndicators) {
    if (!state.filters.has(id)) {
      addFilterControl(indicator);
      break;
    }
  }
}

/**
 * Add filter control for an indicator
 * @param {Object} indicator - Indicator data
 */
function addFilterControl(indicator) {
  const container = document.getElementById('filters-container');
  if (!container) return;

  // Remove empty state
  const emptyState = document.getElementById('filters-empty');
  if (emptyState) {
    emptyState.remove();
  }

  const weight = state.weights.get(indicator.id) || 50;

  const filterEl = filterModule.createFilterControl({
    indicatorId: indicator.id,
    indicatorName: indicator.name,
    operator: '>',
    value: '',
    enabled: true,
    weight: weight,
    showWeight: true,
    unit: indicator.unit || ''
  });

  container.appendChild(filterEl);

  // Set up filter handlers
  setupFilterEventHandlers(filterEl);

  // Store filter config
  state.filters.set(indicator.id, {
    indicatorId: indicator.id,
    operator: '>',
    value: '',
    enabled: true,
    weight: weight
  });
}

/**
 * Set up event handlers for a filter control
 * @param {HTMLElement} filterEl - Filter element
 */
function setupFilterEventHandlers(filterEl) {
  const indicatorId = filterEl.dataset.indicatorId;

  // Operator change
  const operatorSelect = filterEl.querySelector('.filter-operator-select');
  if (operatorSelect) {
    operatorSelect.addEventListener('change', (e) => {
      const filter = state.filters.get(indicatorId);
      if (filter) {
        filter.operator = e.target.value;
        state.filters.set(indicatorId, filter);
      }
    });
  }

  // Value change
  const valueInput = filterEl.querySelector('.filter-value-input');
  if (valueInput) {
    valueInput.addEventListener('input', (e) => {
      const filter = state.filters.get(indicatorId);
      if (filter) {
        filter.value = e.target.value;
        state.filters.set(indicatorId, filter);
      }
    });
  }

  // Enable/disable toggle
  const toggle = filterEl.querySelector('.filter-toggle input');
  if (toggle) {
    toggle.addEventListener('change', (e) => {
      const filter = state.filters.get(indicatorId);
      if (filter) {
        filter.enabled = e.target.checked;
        state.filters.set(indicatorId, filter);
      }
    });
  }

  // Remove button
  const removeBtn = filterEl.querySelector('.btn-remove');
  if (removeBtn) {
    removeBtn.addEventListener('click', () => {
      removeFilterControl(indicatorId);
    });
  }
}

/**
 * Remove filter control for an indicator
 * @param {string} indicatorId - Indicator ID
 */
function removeFilterControl(indicatorId) {
  const container = document.getElementById('filters-container');
  const filterEl = container?.querySelector(`[data-indicator-id="${indicatorId}"]`);
  if (filterEl) {
    filterEl.remove();
  }

  state.filters.delete(indicatorId);

  // Show empty state if no filters
  if (state.filters.size === 0) {
    container.innerHTML = `
      <div class="filters-empty" id="filters-empty">
        <span class="empty-icon">⚙️</span>
        <span class="empty-text">暂无筛选条件，请添加指标后配置</span>
      </div>
    `;
  }
}

// ============================================================================
// Weight Configuration
// ============================================================================

/**
 * Update weight configuration panel
 */
function updateWeightConfig() {
  const section = document.getElementById('weight-config-section');
  const list = document.getElementById('weight-config-list');
  const totalDisplay = document.getElementById('total-weight-display');

  if (!section || !list) return;

  if (state.selectedIndicators.size === 0) {
    section.style.display = 'none';
    return;
  }

  section.style.display = 'block';
  list.innerHTML = '';

  let total = 0;

  state.selectedIndicators.forEach((indicator, id) => {
    const weight = state.weights.get(id) || 50;
    total += weight;

    const item = document.createElement('div');
    item.className = 'weight-config-item';
    item.dataset.indicatorId = id;

    item.innerHTML = `
      <span class="weight-indicator-name">${indicator.name}</span>
      <div class="weight-slider-wrapper">
        <input type="range" class="weight-slider" min="0" max="100" value="${weight}">
        <span class="weight-value-display">${weight}%</span>
      </div>
    `;

    list.appendChild(item);

    // Set up slider handler
    const slider = item.querySelector('.weight-slider');
    slider.addEventListener('input', (e) => {
      const newWeight = parseInt(e.target.value, 10);
      state.weights.set(id, newWeight);
      item.querySelector('.weight-value-display').textContent = `${newWeight}%`;
      updateTotalWeight();
    });
  });

  updateTotalWeight(total);
}

/**
 * Update total weight display
 * @param {number} total - Total weight
 */
function updateTotalWeight(total = null) {
  if (total === null) {
    total = Array.from(state.weights.values()).reduce((sum, w) => sum + w, 0);
  }

  const display = document.getElementById('total-weight-display');
  if (display) {
    display.textContent = `${total}%`;
    display.style.color = total === 100 ? '#52c41a' : '#faad14';
  }
}

/**
 * Auto-balance weights to sum to 100%
 */
function autoBalanceWeights() {
  const count = state.selectedIndicators.size;
  if (count === 0) return;

  const equalWeight = Math.round(100 / count);
  let remainder = 100 - (equalWeight * count);

  state.selectedIndicators.forEach((indicator, id) => {
    let weight = equalWeight;
    if (remainder > 0) {
      weight++;
      remainder--;
    }
    state.weights.set(id, weight);
  });

  updateWeightConfig();
  showToast('权重已自动平均分配', 'success');
}

// ============================================================================
// Screening Execution
// ============================================================================

/**
 * Run the stock screener
 */
async function runScreener() {
  if (state.selectedIndicators.size === 0) {
    showToast('请选择至少一个指标', 'warning');
    return;
  }

  if (state.isScreening) {
    showToast('正在筛选中，请稍候...', 'info');
    return;
  }

  state.isScreening = true;
  showLoading(true);

  try {
    // Collect filter conditions
    const filters = Array.from(state.filters.values())
      .filter(f => f.enabled !== false && f.value !== '')
      .map(f => ({
        indicator: f.indicatorId,
        operator: f.operator,
        value: parseFloat(f.value)
      }));

    console.log('Filters being sent:', JSON.stringify(filters, null, 2));

    // Collect weights
    const weights = Object.fromEntries(state.weights);

    // Build API request
    const config = {
      filters: filters,
      weights: weights,
      sort_by: 'score',
      sort_order: 'desc',
      limit: 100
    };

    console.log('Request config:', JSON.stringify(config, null, 2));

    // Call actual API
    await callScreenerApi(config);

    showToast(`筛选完成，找到 ${state.results.length} 只股票`, 'success');
  } catch (error) {
    showToast(`筛选失败：${error.message}`, 'error');
  } finally {
    state.isScreening = false;
    showLoading(false);
  }
}

/**
 * Call screener API
 * @param {Object} config - Screener configuration
 */
async function callScreenerApi(config) {
  const response = await fetch('/api/screener', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config)
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.error || `HTTP ${response.status}`);
  }

  const data = await response.json();

  console.log('API Response:', data);

  // Transform API results to match frontend format
  // Backend returns: code, name, price, volume, amount, turn, ma5, ma10, score
  state.results = data.results.map((stock, index) => ({
    code: stock.code,
    name: stock.name,
    score: stock.score || 0,
    indicators: {
      price: stock.price,
      volume: stock.volume,
      amount: stock.amount,
      turn: stock.turn,
      ma5: stock.ma5,
      ma10: stock.ma10
    }
  })).sort((a, b) => b.score - a.score);

  console.log('Transformed results:', state.results);

  renderResults();
}

/**
 * Generate random indicator values for mock data
 * @returns {Object} Indicator values
 */
function generateRandomIndicators() {
  return {
    pe: (Math.random() * 50).toFixed(2),
    pb: (Math.random() * 10).toFixed(2),
    roe: (Math.random() * 30 - 5).toFixed(2),
    turnover_rate: (Math.random() * 10).toFixed(2)
  }
}

/**
 * Render screening results
 */
function renderResults() {
  const statsEl = document.getElementById('results-stats');
  const tableEl = document.getElementById('results-table');
  const bodyEl = document.getElementById('results-body');
  const emptyEl = document.getElementById('results-empty');
  const actionsEl = document.getElementById('results-actions');
  const countEl = document.getElementById('result-count');
  const timeEl = document.getElementById('screen-time');
  const headerRow = tableEl?.querySelector('thead tr');

  if (!statsEl || !tableEl || !bodyEl) return;

  // Show stats and table
  statsEl.style.display = 'flex';
  tableEl.style.display = 'table';
  emptyEl.style.display = 'none';
  actionsEl.style.display = 'flex';

  // Update stats
  countEl.textContent = state.results.length;
  timeEl.textContent = new Date().toLocaleTimeString();

  // Set up sortable headers
  setupSortableHeaders(headerRow);

  // Render rows
  renderTableRows(bodyEl);

  // Set up detail button handlers
  bodyEl.querySelectorAll('.btn-view-detail').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const code = e.target.dataset.code;
      viewStockDetail(code);
    });
  });
}

/**
 * Set up sortable column headers
 * @param {HTMLElement} headerRow - Table header row
 */
function setupSortableHeaders(headerRow) {
  if (!headerRow) return;

  // Clear existing sort indicators
  headerRow.querySelectorAll('.sort-indicator').forEach(el => el.remove());
  headerRow.querySelectorAll('.sortable').forEach(el => {
    el.classList.remove('sorted-asc', 'sorted-desc');
  });

  // Add click handlers to sortable columns
  const sortableCols = {
    'rank': { key: 'rank', defaultOrder: 'asc' },
    'code': { key: 'code', defaultOrder: 'asc' },
    'score': { key: 'score', defaultOrder: 'desc' }
  };

  Object.entries(sortableCols).forEach(([colClass, config]) => {
    const th = headerRow.querySelector(`.${colClass}`);
    if (!th) return;

    th.classList.add('sortable');
    th.style.cursor = 'pointer';
    th.title = 'Click to sort';

    // Add sort indicator span
    const indicator = document.createElement('span');
    indicator.className = 'sort-indicator';
    indicator.textContent = ' \u2195';
    th.appendChild(indicator);

    th.addEventListener('click', () => handleSort(config.key, config.defaultOrder, th));
  });
}

/**
 * Handle column sort
 * @param {string} key - Sort key
 * @param {string} defaultOrder - Default sort order
 * @param {HTMLElement} th - Clicked header element
 */
function handleSort(key, defaultOrder, th) {
  // Toggle sort state
  const currentOrder = th.classList.contains('sorted-asc') ? 'asc' :
                       th.classList.contains('sorted-desc') ? 'desc' : null;

  let newOrder;
  if (currentOrder === null || currentOrder !== defaultOrder) {
    newOrder = defaultOrder;
  } else {
    newOrder = currentOrder === 'asc' ? 'desc' : 'asc';
  }

  // Update header classes
  const headerRow = th.parentElement;
  headerRow.querySelectorAll('th').forEach(h => {
    h.classList.remove('sorted-asc', 'sorted-desc');
  });
  th.classList.add(newOrder === 'asc' ? 'sorted-asc' : 'sorted-desc');

  // Sort results
  const sorted = [...state.results].sort((a, b) => {
    let valA = a[key] !== undefined ? a[key] : 0;
    let valB = b[key] !== undefined ? b[key] : 0;

    // Handle string comparison for code/name
    if (typeof valA === 'string') {
      valA = valA.toLowerCase();
      valB = valB.toLowerCase();
      if (newOrder === 'asc') {
        return valA.localeCompare(valB);
      } else {
        return valB.localeCompare(valA);
      }
    }

    // Numeric comparison
    if (newOrder === 'asc') {
      return valA - valB;
    } else {
      return valB - valA;
    }
  });

  state.results = sorted;

  // Re-render rows
  const bodyEl = document.getElementById('results-body');
  if (bodyEl) {
    renderTableRows(bodyEl);
  }

  showToast(`Sorted by ${key} (${newOrder === 'asc' ? 'ascending' : 'descending'})`, 'info');
}

/**
 * Render table rows from current state.results
 * @param {HTMLElement} bodyEl - Table body element
 */
function renderTableRows(bodyEl) {
  bodyEl.innerHTML = '';

  state.results.forEach((stock, index) => {
    const row = document.createElement('tr');
    row.innerHTML = `
      <td class="col-rank">${index + 1}</td>
      <td class="col-code">${stock.code}<br><small style="color: #666;">${stock.name || ''}</small></td>
      <td class="col-score"><span class="stock-score ${getScoreClass(stock.score)}">${stock.score.toFixed(1)}</span></td>
      <td class="col-indicators">价格：${stock.indicators.price?.toFixed(2) || '--'} | 成交量：${(stock.indicators.volume / 10000).toFixed(0)} 万股</td>
      <td class="col-action">
        <button class="btn-view-detail" data-code="${stock.code}">详情</button>
        <button class="btn-compare" data-code="${stock.code}">对比</button>
      </td>
    `;
    bodyEl.appendChild(row);
  });
}

/**
 * Get CSS class based on score value
 * @param {number} score - Stock score
 * @returns {string} CSS class name
 */
function getScoreClass(score) {
  if (score >= 90) return 'score-excellent';
  if (score >= 80) return 'score-good';
  if (score >= 70) return 'score-average';
  return 'score-low';
}

/**
 * View stock detail (placeholder)
 * @param {string} code - Stock code
 */
function viewStockDetail(code) {
  showToast(`查看 ${code} 详情功能开发中`, 'info');
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Show toast notification
 * @param {string} message - Message to display
 * @param {string} type - Toast type (success, error, warning, info)
 */
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span class="toast-message">${message}</span>
  `;
  toast.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 12px 24px;
    border-radius: 8px;
    background: ${type === 'success' ? '#f6ffed' : type === 'error' ? '#fff2f0' : type === 'warning' ? '#fffbe6' : '#e6f7ff'};
    border: 1px solid ${type === 'success' ? '#b7eb8f' : type === 'error' ? '#ffccc7' : type === 'warning' ? '#ffe58f' : '#91d5ff'};
    color: ${type === 'success' ? '#52c41a' : type === 'error' ? '#ff4d4f' : type === 'warning' ? '#faad14' : '#1890ff'};
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 10000;
    animation: slideInRight 0.3s ease;
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = 'slideOutRight 0.3s ease forwards';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

/**
 * Show/hide loading overlay
 * @param {boolean} show - Whether to show
 */
function showLoading(show) {
  const overlay = document.getElementById('loading-overlay');
  if (overlay) {
    overlay.style.display = show ? 'flex' : 'none';
  }

  const runBtn = document.getElementById('btn-run-screen');
  if (runBtn) {
    runBtn.classList.toggle('loading', show);
    runBtn.disabled = show;
  }
}

/**
 * Save configuration (placeholder)
 */
function saveConfiguration() {
  const config = {
    indicators: Array.from(state.selectedIndicators.keys()),
    filters: Array.from(state.filters.values()),
    weights: Object.fromEntries(state.weights)
  };

  localStorage.setItem('screenerConfig', JSON.stringify(config));
  showToast('配置已保存', 'success');
}

/**
 * Export results (placeholder)
 */
function exportResults() {
  if (state.results.length === 0) {
    showToast('暂无结果可导出', 'warning');
    return;
  }

  // Generate CSV
  const headers = ['排名', '代码', '名称', '得分', 'PE', 'PB', 'ROE', '换手率'];
  const rows = state.results.map((stock, i) => [
    i + 1,
    stock.code,
    stock.name,
    stock.score.toFixed(1),
    stock.indicators.pe,
    stock.indicators.pb,
    stock.indicators.roe,
    stock.indicators.turnover_rate
  ]);

  const csv = [headers, ...rows].map(row => row.join(',')).join('\n');
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `股票筛选结果_${new Date().toISOString().split('T')[0]}.csv`;
  link.click();

  showToast('导出成功', 'success');
}

/**
 * Add to watchlist (placeholder)
 */
function addToWatchlist() {
  if (state.results.length === 0) {
    showToast('暂无结果可添加', 'warning');
    return;
  }

  showToast(`已将 ${state.results.length} 只股票加入观察列表`, 'success');
}

/**
 * Handle navigation
 * @param {Event} e - Click event
 */
function handleNavigation(e) {
  const link = e.target.dataset.link;
  if (!link || link === '#') return;

  if (link.startsWith('#')) {
    // Handle in-page navigation
    showToast('功能开发中', 'info');
  } else {
    window.location.href = link;
  }
}

// Add animation styles
const style = document.createElement('style');
style.textContent = `
  @keyframes slideInRight {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slideOutRight {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(100%);
      opacity: 0;
    }
  }
`;
document.head.appendChild(style);
