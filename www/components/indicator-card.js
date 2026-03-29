/**
 * Indicator Card Component
 *
 * Reusable component for displaying technical, market, and financial indicators
 * with help tooltips showing calculation formulas and descriptions.
 */

// ============================================================================
// Indicator Data Definitions
// ============================================================================

export const indicators = {
  // Market Indicators - 只保留 API 支持的字段
  market: [
    {
      id: 'price',
      name: '收盘价',
      symbol: 'CLOSE',
      category: 'market',
      description: '当日收盘价，反映股票在当前交易日的最终市场定价。',
      formula: 'CLOSE = 当日最后一笔交易价格',
      range: '无限制，取决于股票基本面和市场情绪',
      unit: '元'
    },
    {
      id: 'volume',
      name: '成交量',
      symbol: 'VOL',
      category: 'market',
      description: '当日成交的股票数量，反映市场参与度和交易热度。',
      formula: 'VOL = 当日成交股数',
      range: '无上限，通常以手为单位 (1 手=100 股)',
      unit: '手'
    },
    {
      id: 'amount',
      name: '成交额',
      symbol: 'AMT',
      category: 'market',
      description: '当日成交的总金额，反映资金流入规模。',
      formula: '成交额 = Σ(成交价格 × 成交数量)',
      range: '无上限，通常以万元为单位',
      unit: '万元'
    },
    {
      id: 'turn',
      name: '换手率',
      symbol: 'TURN',
      category: 'market',
      description: '成交量与流通股本的比率，反映股票流通性和市场活跃度。',
      formula: '换手率 = (成交量 / 流通股本) × 100%',
      range: '0% - 50%+, 一般 3%-7% 为活跃',
      unit: '%'
    }
  ],

  // Technical Indicators - 只保留 API 支持的字段
  tech: [
    {
      id: 'ma5',
      name: '5 日均线',
      symbol: 'MA5',
      category: 'tech',
      description: '5 日移动平均线，将最近 5 日的收盘价相加后平均，反映短期价格趋势。',
      formula: 'MA5 = (P₁ + P₂ + P₃ + P₄ + P₅) / 5',
      range: '无限制，跟随价格变动',
      unit: '元'
    },
    {
      id: 'ma10',
      name: '10 日均线',
      symbol: 'MA10',
      category: 'tech',
      description: '10 日移动平均线，将最近 10 日的收盘价相加后平均，反映中期价格趋势。',
      formula: 'MA10 = (P₁ + P₂ + ... + P₁₀) / 10',
      range: '无限制，跟随价格变动',
      unit: '元'
    }
  ],

  // Financial Indicators - 暂不支持
  finance: []
};

// ============================================================================
// Component Factory Functions
// ============================================================================

/**
 * Create an indicator card element
 * @param {Object} indicator - Indicator data object
 * @param {boolean} selected - Whether the indicator is selected
 * @returns {HTMLElement} The indicator card element
 */
export function createIndicatorCard(indicator, selected = false) {
  const card = document.createElement('div');
  card.className = `indicator-card${selected ? ' selected' : ''}`;
  card.dataset.indicatorId = indicator.id;
  card.dataset.indicatorName = indicator.name;
  card.dataset.indicatorCategory = indicator.category;

  card.innerHTML = `
    <div class="indicator-card-header">
      <span class="indicator-card-name">${indicator.name}</span>
      <span class="indicator-card-symbol">${indicator.symbol}</span>
    </div>
    <div class="indicator-card-description">${indicator.description}</div>
    <div style="display: flex; align-items: center; justify-content: space-between; margin-top: 4px;">
      <span class="indicator-badge ${indicator.category}">${indicator.category}</span>
      <div class="indicator-help" role="tooltip" aria-label="View details">
        ?
        <div class="indicator-help-tooltip">
          <div class="indicator-help-tooltip-title">${indicator.name} (${indicator.symbol})</div>
          <div class="indicator-help-tooltip-formula">${indicator.formula}</div>
          <div class="indicator-help-tooltip-desc">${indicator.description}</div>
          ${indicator.range ? `<div class="indicator-help-tooltip-range">正常范围：${indicator.range}</div>` : ''}
        </div>
      </div>
    </div>
  `;

  return card;
}

/**
 * Create a grid of indicator cards
 * @param {Array} indicatorList - List of indicator data objects
 * @param {Set} selectedIds - Set of selected indicator IDs
 * @returns {HTMLElement} The container element with all cards
 */
export function createIndicatorGrid(indicatorList, selectedIds = new Set()) {
  const container = document.createElement('div');
  container.className = 'indicator-grid';

  indicatorList.forEach(indicator => {
    const card = createIndicatorCard(indicator, selectedIds.has(indicator.id));
    container.appendChild(card);
  });

  return container;
}

/**
 * Create a selected indicator tag
 * @param {Object} indicator - Indicator data object
 * @returns {HTMLElement} The tag element
 */
export function createSelectedIndicatorTag(indicator) {
  const tag = document.createElement('span');
  tag.className = 'selected-indicator-tag';
  tag.dataset.indicatorId = indicator.id;

  tag.innerHTML = `
    ${indicator.name}
    <span class="tag-remove">&times;</span>
  `;

  return tag;
}

/**
 * Create a filter control for an indicator
 * @param {Object} indicator - Indicator data object
 * @param {Object} options - Filter configuration
 * @returns {HTMLElement} The filter control element
 */
export function createFilterControl(indicator, options = {}) {
  const {
    operator = '>',
    value = '',
    enabled = true,
    weight = 50,
    showWeight = true
  } = options;

  const container = document.createElement('div');
  container.className = 'filter-control';
  container.dataset.indicatorId = indicator.id;

  const operatorOptions = operators.map(op =>
    `<option value="${op.value}"${op.value === operator ? ' selected' : ''}>${op.label}</option>`
  ).join('');

  container.innerHTML = `
    <label class="filter-control-label">${indicator.name}</label>
    <select class="filter-operator">
      ${operatorOptions}
    </select>
    <input type="text" class="filter-value-input" value="${value}" placeholder="输入阈值">
    <label class="filter-toggle">
      <input type="checkbox" ${enabled ? 'checked' : ''}>
      <span class="filter-toggle-slider"></span>
      <span class="filter-toggle-label">启用</span>
    </label>
    ${showWeight ? `
      <div class="weight-slider-container">
        <span style="font-size: 12px; color: #666;">权重:</span>
        <input type="range" class="weight-slider" min="0" max="100" value="${weight}">
        <span class="weight-value">${weight}%</span>
      </div>
    ` : ''}
  `;

  return container;
}

/**
 * Create a range filter control
 * @param {Object} indicator - Indicator data object
 * @param {Object} options - Range configuration
 * @returns {HTMLElement} The range filter element
 */
export function createRangeFilter(indicator, options = {}) {
  const {
    minValue = '',
    maxValue = '',
    enabled = true
  } = options;

  const container = document.createElement('div');
  container.className = 'filter-control';
  container.dataset.indicatorId = indicator.id;

  container.innerHTML = `
    <label class="filter-control-label">${indicator.name}</label>
    <div class="filter-range-inputs">
      <input type="number" class="filter-value-input" value="${minValue}" placeholder="最小值">
      <span class="filter-range-separator">-</span>
      <input type="number" class="filter-value-input" value="${maxValue}" placeholder="最大值">
    </div>
    <label class="filter-toggle">
      <input type="checkbox" ${enabled ? 'checked' : ''}>
      <span class="filter-toggle-slider"></span>
      <span class="filter-toggle-label">启用</span>
    </label>
  `;

  return container;
}

// Comparison operators
const operators = [
  { value: '>', label: '大于' },
  { value: '>=', label: '大于等于' },
  { value: '<', label: '小于' },
  { value: '<=', label: '小于等于' },
  { value: '=', label: '等于' },
  { value: '!=', label: '不等于' },
  { value: 'between', label: '介于' }
];

// ============================================================================
// Event Handler Setup
// ============================================================================

/**
 * Set up event handlers for indicator cards
 * @param {HTMLElement} container - Container element
 * @param {Function} onSelect - Callback when indicator is selected
 * @param {Function} onDeselect - Callback when indicator is deselected
 */
export function setupIndicatorHandlers(container, onSelect, onDeselect) {
  // Prevent multiple event listeners on same container
  if (container._indicatorHandlersAttached) {
    return;
  }
  container._indicatorHandlersAttached = true;

  container.addEventListener('click', (e) => {
    // Ignore clicks on help tooltip
    if (e.target.closest('.indicator-help') || e.target.closest('.indicator-help-tooltip')) {
      return;
    }

    const card = e.target.closest('.indicator-card');
    if (!card) return;

    const indicatorId = card.dataset.indicatorId;
    const isSelected = card.classList.contains('selected');

    if (isSelected) {
      card.classList.remove('selected');
      onDeselect?.(indicatorId);
    } else {
      card.classList.add('selected');
      onSelect?.(indicatorId);
    }
  });
}

/**
 * Set up event handlers for selected indicator tags
 * @param {HTMLElement} container - Container element
 * @param {Function} onRemove - Callback when tag is removed
 */
export function setupTagHandlers(container, onRemove) {
  container.addEventListener('click', (e) => {
    const tag = e.target.closest('.selected-indicator-tag');
    const removeBtn = e.target.closest('.tag-remove');

    if (removeBtn && tag) {
      tag.remove();
      onRemove?.(tag.dataset.indicatorId);
    }
  });
}

/**
 * Set up event handlers for weight sliders
 * @param {HTMLElement} container - Container element
 * @param {Function} onWeightChange - Callback when weight changes
 */
export function setupWeightSliderHandlers(container, onWeightChange) {
  container.addEventListener('input', (e) => {
    const slider = e.target.closest('.weight-slider');
    if (!slider) return;

    const valueDisplay = slider.parentElement.querySelector('.weight-value');
    if (valueDisplay) {
      valueDisplay.textContent = `${slider.value}%`;
    }

    const control = slider.closest('.filter-control');
    onWeightChange?.(control.dataset.indicatorId, parseInt(slider.value, 10));
  });
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Get indicator by ID
 * @param {string} id - Indicator ID
 * @returns {Object|null} Indicator data or null
 */
export function getIndicatorById(id) {
  for (const category of Object.values(indicators)) {
    const indicator = category.find(i => i.id === id);
    if (indicator) return indicator;
  }
  return null;
}

/**
 * Get indicators by category
 * @param {string} category - Category name
 * @returns {Array} List of indicators
 */
export function getIndicatorsByCategory(category) {
  return indicators[category] || [];
}

/**
 * Search indicators by name or description
 * @param {string} query - Search query
 * @returns {Array} Matching indicators
 */
export function searchIndicators(query) {
  const lowerQuery = query.toLowerCase();
  const results = [];

  for (const category of Object.values(indicators)) {
    const matches = category.filter(indicator =>
      indicator.name.toLowerCase().includes(lowerQuery) ||
      indicator.description.toLowerCase().includes(lowerQuery) ||
      indicator.symbol.toLowerCase().includes(lowerQuery)
    );
    results.push(...matches);
  }

  return results;
}

/**
 * Get all indicators as a flat array
 * @returns {Array} All indicators
 */
export function getAllIndicators() {
  return Object.values(indicators).flat();
}
