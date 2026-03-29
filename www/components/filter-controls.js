/**
 * Filter Controls Component
 *
 * Provides filtering UI elements for stock screening:
 * - Operator selection (>, =, <, between, range)
 * - Value inputs
 * - Range selectors
 * - Enable/disable toggles
 * - Weight sliders for ranking
 */

// ============================================================================
// Operator Definitions
// ============================================================================

export const operators = [
  { value: '>', label: '大于', symbol: '>' },
  { value: '>=', label: '大于等于', symbol: '≥' },
  { value: '<', label: '小于', symbol: '<' },
  { value: '<=', label: '小于等于', symbol: '≤' },
  { value: '=', label: '等于', symbol: '=' },
  { value: '!=', label: '不等于', symbol: '≠' },
  { value: 'between', label: '介于', symbol: '∈' },
  { value: 'in_range', label: '范围内', symbol: '↔' }
];

// ============================================================================
// Filter Control Builder
// ============================================================================

/**
 * Create a complete filter control row
 * @param {Object} options - Filter configuration
 * @returns {HTMLElement} Filter control element
 */
export function createFilterControl(options = {}) {
  const {
    indicatorId,
    indicatorName,
    operator = '>',
    value = '',
    minValue = '',
    maxValue = '',
    enabled = true,
    weight = 50,
    showWeight = false,
    unit = ''
  } = options;

  const container = document.createElement('div');
  container.className = 'filter-control-row';
  container.dataset.indicatorId = indicatorId || '';

  const operatorOptions = operators.map(op =>
    `<option value="${op.value}"${op.value === operator ? ' selected' : ''}>${op.label}</option>`
  ).join('');

  const isRangeOperator = operator === 'between' || operator === 'in_range';

  container.innerHTML = `
    <div class="filter-control-header">
      <span class="filter-indicator-name">${indicatorName || '选择指标'}</span>
      <label class="filter-toggle">
        <input type="checkbox" ${enabled ? 'checked' : ''}>
        <span class="filter-toggle-slider"></span>
      </label>
    </div>
    <div class="filter-control-body">
      <select class="filter-operator-select">
        ${operatorOptions}
      </select>
      <div class="filter-value-container">
        ${isRangeOperator ? `
          <div class="filter-range-inputs">
            <input type="number" class="filter-value-input min-value" value="${minValue}" placeholder="最小值">
            <span class="range-separator">至</span>
            <input type="number" class="filter-value-input max-value" value="${maxValue}" placeholder="最大值">
          </div>
        ` : `
          <input type="number" class="filter-value-input single-value" value="${value}" placeholder="输入阈值${unit}">
        `}
      </div>
      ${showWeight ? `
        <div class="filter-weight-container">
          <label class="weight-label">
            <span class="weight-icon">⚖</span>
            <input type="range" class="weight-slider" min="0" max="100" value="${weight}">
            <span class="weight-value">${weight}%</span>
          </label>
        </div>
      ` : ''}
    </div>
    <div class="filter-control-actions">
      <button class="btn-filter-action btn-config" title="配置">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="3"></circle>
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
        </svg>
      </button>
      <button class="btn-filter-action btn-remove" title="删除">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="3 6 5 6 21 6"></polyline>
          <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
        </svg>
      </button>
    </div>
  `;

  // Update value input visibility based on operator
  const operatorSelect = container.querySelector('.filter-operator-select');
  const valueContainer = container.querySelector('.filter-value-container');

  operatorSelect.addEventListener('change', (e) => {
    const isRange = e.target.value === 'between' || e.target.value === 'in_range';

    // Save existing values before recreating inputs
    const existingSingle = valueContainer.querySelector('.single-value');
    const existingMin = valueContainer.querySelector('.min-value');
    const existingMax = valueContainer.querySelector('.max-value');
    const singleValue = existingSingle ? existingSingle.value : '';
    const minValue = existingMin ? existingMin.value : '';
    const maxValue = existingMax ? existingMax.value : '';

    if (isRange) {
      valueContainer.innerHTML = `
        <div class="filter-range-inputs">
          <input type="number" class="filter-value-input min-value" value="${minValue || singleValue}" placeholder="最小值">
          <span class="range-separator">至</span>
          <input type="number" class="filter-value-input max-value" value="${maxValue || singleValue}" placeholder="最大值">
        </div>
      `;
    } else {
      // When switching from range to single, use min value as default
      const defaultValue = minValue || singleValue;
      valueContainer.innerHTML = `
        <input type="number" class="filter-value-input single-value" value="${defaultValue}" placeholder="输入阈值${unit}">
      `;
    }
  });

  return container;
}

/**
 * Create a compact filter chip for quick filtering
 * @param {Object} options - Filter configuration
 * @returns {HTMLElement} Filter chip element
 */
export function createFilterChip(options = {}) {
  const {
    indicatorId,
    indicatorName,
    operator = '>',
    value = '',
    enabled = true
  } = options;

  const chip = document.createElement('span');
  chip.className = `filter-chip${enabled ? '' : ' disabled'}`;
  chip.dataset.indicatorId = indicatorId || '';

  const opSymbol = operators.find(op => op.value === operator)?.symbol || operator;

  chip.innerHTML = `
    <span class="chip-indicator">${indicatorName}</span>
    <span class="chip-condition">${opSymbol} ${value}</span>
    <button class="chip-remove">&times;</button>
  `;

  return chip;
}

/**
 * Create a range slider filter
 * @param {Object} options - Range configuration
 * @returns {HTMLElement} Range slider element
 */
export function createRangeSlider(options = {}) {
  const {
    indicatorId,
    indicatorName,
    minValue = 0,
    maxValue = 100,
    valueMin = 0,
    valueMax = 100,
    step = 1,
    enabled = true
  } = options;

  const container = document.createElement('div');
  container.className = 'range-slider-filter';
  container.dataset.indicatorId = indicatorId || '';

  container.innerHTML = `
    <div class="range-slider-header">
      <span class="range-slider-label">${indicatorName || '范围筛选'}</span>
      <label class="filter-toggle">
        <input type="checkbox" ${enabled ? 'checked' : ''}>
        <span class="filter-toggle-slider"></span>
      </label>
    </div>
    <div class="range-slider-body">
      <div class="range-values">
        <input type="number" class="range-min-input" value="${valueMin}" min="${minValue}" max="${maxValue}">
        <span class="range-separator">-</span>
        <input type="number" class="range-max-input" value="${valueMax}" min="${minValue}" max="${maxValue}">
      </div>
      <div class="range-slider-track">
        <div class="range-slider-fill" style="left: 0%; right: 0%;"></div>
        <input type="range" class="range-slider-min" min="${minValue}" max="${maxValue}" step="${step}" value="${valueMin}">
        <input type="range" class="range-slider-max" min="${minValue}" max="${maxValue}" step="${step}" value="${valueMax}">
      </div>
    </div>
  `;

  return container;
}

/**
 * Create a multi-select filter
 * @param {Object} options - Multi-select configuration
 * @returns {HTMLElement} Multi-select element
 */
export function createMultiSelectFilter(options = {}) {
  const {
    indicatorId,
    indicatorName,
    options: selectOptions = [],
    selectedValues = [],
    enabled = true
  } = options;

  const container = document.createElement('div');
  container.className = 'multi-select-filter';
  container.dataset.indicatorId = indicatorId || '';

  const optionsHtml = selectOptions.map(opt =>
    `<label class="multi-select-option">
      <input type="checkbox" value="${opt.value}" ${selectedValues.includes(opt.value) ? 'checked' : ''}>
      <span>${opt.label}</span>
    </label>`
  ).join('');

  container.innerHTML = `
    <div class="multi-select-header">
      <span class="multi-select-label">${indicatorName || '多选筛选'}</span>
      <label class="filter-toggle">
        <input type="checkbox" ${enabled ? 'checked' : ''}>
        <span class="filter-toggle-slider"></span>
      </label>
    </div>
    <div class="multi-select-options">
      ${optionsHtml}
    </div>
  `;

  return container;
}

/**
 * Create weight configuration panel
 * @param {Object} options - Weight configuration
 * @returns {HTMLElement} Weight panel element
 */
export function createWeightPanel(options = {}) {
  const {
    indicators = [],
    defaultWeight = 50
  } = options;

  const panel = document.createElement('div');
  panel.className = 'weight-config-panel';

  const itemsHtml = indicators.map(ind => `
    <div class="weight-config-item" data-indicator-id="${ind.id}">
      <span class="weight-indicator-name">${ind.name}</span>
      <div class="weight-slider-wrapper">
        <input type="range" class="weight-slider" min="0" max="100" value="${ind.weight ?? defaultWeight}">
        <span class="weight-value-display">${ind.weight ?? defaultWeight}%</span>
      </div>
    </div>
  `).join('');

  panel.innerHTML = `
    <div class="weight-panel-header">
      <h4>指标权重配置</h4>
      <span class="weight-total">总权重：<span id="total-weight">${indicators.reduce((sum, ind) => sum + (ind.weight ?? defaultWeight), 0)}%</span></span>
    </div>
    <div class="weight-panel-body">
      ${itemsHtml}
    </div>
    <div class="weight-panel-footer">
      <button class="btn-reset-weights">重置权重</button>
      <button class="btn-equalize-weights">平均分配</button>
    </div>
  `;

  return panel;
}

// ============================================================================
// Filter Group Management
// ============================================================================

/**
 * Create a filter group container
 * @param {string} groupName - Group name
 * @param {Array} filters - Array of filter configs
 * @returns {HTMLElement} Filter group element
 */
export function createFilterGroup(groupName, filters = []) {
  const group = document.createElement('div');
  group.className = 'filter-group';

  const filtersHtml = filters.map(filter => {
    const filterEl = createFilterControl(filter);
    return `<div class="filter-group-item">${filterEl.outerHTML}</div>`;
  }).join('');

  group.innerHTML = `
    <div class="filter-group-header">
      <h4 class="filter-group-title">${groupName}</h4>
      <button class="btn-add-filter">+ 添加筛选</button>
    </div>
    <div class="filter-group-body">
      ${filtersHtml}
    </div>
  `;

  return group;
}

/**
 * Collect filter values from a container
 * @param {HTMLElement} container - Container element
 * @returns {Array} Array of filter configurations
 */
export function collectFilterValues(container) {
  const filters = [];
  const rows = container.querySelectorAll('.filter-control-row');

  rows.forEach(row => {
    const indicatorId = row.dataset.indicatorId;
    const operator = row.querySelector('.filter-operator-select')?.value || '>';
    const isEnabled = row.querySelector('input[type="checkbox"]')?.checked ?? true;

    let value = null;
    let minValue = null;
    let maxValue = null;

    const singleValue = row.querySelector('.single-value');
    const minInput = row.querySelector('.min-value');
    const maxInput = row.querySelector('.max-value');

    if (singleValue) {
      value = singleValue.value;
    } else if (minInput && maxInput) {
      minValue = minInput.value;
      maxValue = maxInput.value;
    }

    const weightSlider = row.querySelector('.weight-slider');
    const weight = weightSlider ? parseInt(weightSlider.value, 10) : 50;

    filters.push({
      indicatorId,
      operator,
      value,
      minValue,
      maxValue,
      enabled: isEnabled,
      weight
    });
  });

  return filters;
}

/**
 * Set filter values from configuration
 * @param {HTMLElement} container - Container element
 * @param {Array} filters - Array of filter configurations
 */
export function setFilterValues(container, filters) {
  filters.forEach(filter => {
    const row = container.querySelector(`.filter-control-row[data-indicator-id="${filter.indicatorId}"]`);
    if (!row) return;

    const operatorSelect = row.querySelector('.filter-operator-select');
    if (operatorSelect && filter.operator) {
      operatorSelect.value = filter.operator;
    }

    const checkbox = row.querySelector('input[type="checkbox"]');
    if (checkbox !== null) {
      checkbox.checked = filter.enabled !== false;
    }

    if (filter.value !== undefined && filter.value !== null) {
      const singleValue = row.querySelector('.single-value');
      if (singleValue) {
        singleValue.value = filter.value;
      }
    }

    if (filter.minValue !== undefined || filter.maxValue !== undefined) {
      const minInput = row.querySelector('.min-value');
      const maxInput = row.querySelector('.max-value');
      if (minInput && filter.minValue !== undefined) {
        minInput.value = filter.minValue;
      }
      if (maxInput && filter.maxValue !== undefined) {
        maxInput.value = filter.maxValue;
      }
    }

    if (filter.weight !== undefined) {
      const weightSlider = row.querySelector('.weight-slider');
      if (weightSlider) {
        weightSlider.value = filter.weight;
        const weightDisplay = row.querySelector('.weight-value');
        if (weightDisplay) {
          weightDisplay.textContent = `${filter.weight}%`;
        }
      }
    }
  });
}

// ============================================================================
// Event Handler Setup
// ============================================================================

/**
 * Set up event handlers for filter controls
 * @param {HTMLElement} container - Container element
 * @param {Object} callbacks - Callback functions
 */
export function setupFilterHandlers(container, callbacks = {}) {
  const {
    onOperatorChange,
    onValueChange,
    onEnabledChange,
    onWeightChange,
    onRemove,
    onConfig
  } = callbacks;

  // Operator change
  container.addEventListener('change', (e) => {
    if (e.target.classList.contains('filter-operator-select')) {
      const row = e.target.closest('.filter-control-row');
      onOperatorChange?.(row.dataset.indicatorId, e.target.value);
    }

    if (e.target.classList.contains('weight-slider')) {
      const row = e.target.closest('.filter-control-row');
      const valueDisplay = row.querySelector('.weight-value');
      if (valueDisplay) {
        valueDisplay.textContent = `${e.target.value}%`;
      }
      onWeightChange?.(row.dataset.indicatorId, parseInt(e.target.value, 10));
    }

    // Toggle checkbox in filter-toggle
    if (e.target.type === 'checkbox' && e.target.closest('.filter-toggle')) {
      const row = e.target.closest('.filter-control-row');
      onEnabledChange?.(row.dataset.indicatorId, e.target.checked);
    }
  });

  // Value input
  container.addEventListener('input', (e) => {
    if (e.target.classList.contains('filter-value-input') ||
        e.target.classList.contains('min-value') ||
        e.target.classList.contains('max-value')) {
      const row = e.target.closest('.filter-control-row');
      onValueChange?.(row.dataset.indicatorId, getFilterValues(row));
    }

    // Range slider inputs
    if (e.target.classList.contains('range-min-input') ||
        e.target.classList.contains('range-max-input')) {
      const row = e.target.closest('.range-slider-filter');
      onValueChange?.(row.dataset.indicatorId, {
        min: row.querySelector('.range-min-input')?.value,
        max: row.querySelector('.range-max-input')?.value
      });
    }
  });

  // Remove button
  container.addEventListener('click', (e) => {
    const removeBtn = e.target.closest('.btn-remove');
    if (removeBtn) {
      const row = removeBtn.closest('.filter-control-row');
      const indicatorId = row.dataset.indicatorId;
      row.remove();
      onRemove?.(indicatorId);
    }

    // Config button
    const configBtn = e.target.closest('.btn-config');
    if (configBtn) {
      const row = configBtn.closest('.filter-control-row');
      onConfig?.(row.dataset.indicatorId);
    }

    // Chip remove
    const chipRemove = e.target.closest('.chip-remove');
    if (chipRemove) {
      const chip = chipRemove.closest('.filter-chip');
      const indicatorId = chip.dataset.indicatorId;
      chip.remove();
      onRemove?.(indicatorId);
    }
  });
}

/**
 * Get filter values from a single row
 * @param {HTMLElement} row - Filter row element
 * @returns {Object} Filter values
 */
function getFilterValues(row) {
  const singleValue = row.querySelector('.single-value');
  const minInput = row.querySelector('.min-value');
  const maxInput = row.querySelector('.max-value');

  if (singleValue) {
    return { value: singleValue.value };
  } else if (minInput && maxInput) {
    return { min: minInput.value, max: maxInput.value };
  }
  return {};
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Validate filter configuration
 * @param {Object} filter - Filter configuration
 * @returns {Object} Validation result
 */
export function validateFilter(filter) {
  const errors = [];

  if (!filter.indicatorId) {
    errors.push('缺少指标 ID');
  }

  if (filter.operator === 'between' || filter.operator === 'in_range') {
    if (!filter.minValue && filter.minValue !== 0) {
      errors.push('范围筛选需要最小值');
    }
    if (!filter.maxValue && filter.maxValue !== 0) {
      errors.push('范围筛选需要最大值');
    }
    if (filter.minValue !== undefined && filter.maxValue !== undefined &&
        Number(filter.minValue) > Number(filter.maxValue)) {
      errors.push('最小值不能大于最大值');
    }
  } else {
    if (filter.value === '' && filter.value !== 0) {
      errors.push('请输入筛选值');
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Serialize filters to API format
 * @param {Array} filters - Array of filter configurations
 * @returns {Object} API-ready filter object
 */
export function serializeFilters(filters) {
  return filters
    .filter(f => f.enabled !== false)
    .map(f => ({
      field: f.indicatorId,
      operator: f.operator,
      value: f.operator === 'between' || f.operator === 'in_range'
        ? [f.minValue, f.maxValue]
        : f.value,
      weight: f.weight || 50
    }));
}
