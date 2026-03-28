/**
 * Trading Model Selection UI Component
 *
 * Provides interface for selecting and configuring trading models:
 * - Strategy selection
 * - Parameter configuration
 * - Visual model builder
 * - Model validation
 */

// ============================================================================
// Trading Model Definitions
// ============================================================================

export const tradingModels = {
  // Entry Signals
  entry: [
    {
      id: 'ma_cross',
      name: '均线交叉策略',
      description: '当短期均线上穿长期均线时买入，下穿时卖出',
      icon: '📈',
      category: 'trend',
      parameters: [
        { key: 'shortPeriod', name: '短期周期', type: 'number', default: 5, min: 1, max: 20 },
        { key: 'longPeriod', name: '长期周期', type: 'number', default: 20, min: 10, max: 200 }
      ],
      signals: {
        buy: '短均线上穿长均线',
        sell: '短均线下穿长均线'
      }
    },
    {
      id: 'macd_gold',
      name: 'MACD 金叉策略',
      description: '当 MACD 快线上穿慢线形成金叉时买入',
      icon: '⭐',
      category: 'momentum',
      parameters: [
        { key: 'fastPeriod', name: '快周期', type: 'number', default: 12, min: 5, max: 50 },
        { key: 'slowPeriod', name: '慢周期', type: 'number', default: 26, min: 10, max: 100 },
        { key: 'signalPeriod', name: '信号周期', type: 'number', default: 9, min: 3, max: 30 }
      ],
      signals: {
        buy: 'DIF 上穿 DEA',
        sell: 'DIF 下穿 DEA'
      }
    },
    {
      id: 'kdj_cross',
      name: 'KDJ 交叉策略',
      description: 'K 线上穿 D 线形成金叉时买入',
      icon: '📊',
      category: 'oscillator',
      parameters: [
        { key: 'nPeriod', name: 'N 周期', type: 'number', default: 9, min: 3, max: 30 },
        { key: 'm1Period', name: 'M1 周期', type: 'number', default: 3, min: 1, max: 10 },
        { key: 'm2Period', name: 'M2 周期', type: 'number', default: 3, min: 1, max: 10 }
      ],
      signals: {
        buy: 'K 线上穿 D 线',
        sell: 'K 线下穿 D 线'
      }
    },
    {
      id: 'rsi_oversold',
      name: 'RSI 超卖反弹',
      description: '当 RSI 进入超卖区域后反弹时买入',
      icon: '🔄',
      category: 'mean_reversion',
      parameters: [
        { key: 'period', name: '周期', type: 'number', default: 14, min: 5, max: 30 },
        { key: 'oversoldLevel', name: '超卖水平', type: 'number', default: 30, min: 10, max: 40 },
        { key: 'overboughtLevel', name: '超买水平', type: 'number', default: 70, min: 60, max: 90 }
      ],
      signals: {
        buy: 'RSI 从超卖区上穿',
        sell: 'RSI 从超买区下穿'
      }
    },
    {
      id: 'boll_break',
      name: '布林带突破',
      description: '价格突破布林带上轨时买入',
      icon: '📉',
      category: 'volatility',
      parameters: [
        { key: 'period', name: '周期', type: 'number', default: 20, min: 10, max: 50 },
        { key: 'stdDev', name: '标准差倍数', type: 'number', default: 2, min: 1, max: 3, step: 0.5 }
      ],
      signals: {
        buy: '价格突破上轨',
        sell: '价格跌破下轨'
      }
    },
    {
      id: 'volume_surge',
      name: '成交量激增',
      description: '成交量显著放大时买入',
      icon: '📢',
      category: 'volume',
      parameters: [
        { key: 'maPeriod', name: '均量周期', type: 'number', default: 20, min: 5, max: 60 },
        { key: 'surgeRatio', name: '激增倍数', type: 'number', default: 2, min: 1.5, max: 5, step: 0.5 }
      ],
      signals: {
        buy: '成交量 > 均量 × 激增倍数',
        sell: '成交量回归正常'
      }
    }
  ],

  // Exit Signals
  exit: [
    {
      id: 'fixed_profit',
      name: '固定止盈',
      description: '达到固定收益率时止盈',
      icon: '💰',
      category: 'profit_target',
      parameters: [
        { key: 'profitPercent', name: '止盈比例 (%)', type: 'number', default: 10, min: 1, max: 100, step: 0.5 }
      ]
    },
    {
      id: 'fixed_stop',
      name: '固定止损',
      description: '达到固定亏损率时止损',
      icon: '🛑',
      category: 'stop_loss',
      parameters: [
        { key: 'lossPercent', name: '止损比例 (%)', type: 'number', default: 5, min: 1, max: 50, step: 0.5 }
      ]
    },
    {
      id: 'trailing_stop',
      name: '移动止盈',
      description: '从最高点回撤固定比例时止盈',
      icon: '📊',
      category: 'trailing',
      parameters: [
        { key: 'trailingPercent', name: '回撤比例 (%)', type: 'number', default: 5, min: 1, max: 30, step: 0.5 }
      ]
    },
    {
      id: 'time_exit',
      name: '时间止盈',
      description: '持仓达到固定天数后平仓',
      icon: '⏱️',
      category: 'time_based',
      parameters: [
        { key: 'holdingDays', name: '持仓天数', type: 'number', default: 5, min: 1, max: 60 }
      ]
    },
    {
      id: 'signal_exit',
      name: '信号止盈',
      description: '出现反向交易信号时平仓',
      icon: '🔄',
      category: 'signal_based',
      parameters: []
    }
  ],

  // Position Management
  position: [
    {
      id: 'fixed_position',
      name: '固定仓位',
      description: '每次交易使用固定仓位比例',
      icon: '📦',
      category: 'basic',
      parameters: [
        { key: 'positionPercent', name: '仓位比例 (%)', type: 'number', default: 20, min: 1, max: 100, step: 5 }
      ]
    },
    {
      id: 'kelly',
      name: '凯利公式',
      description: '根据胜率和盈亏比计算最优仓位',
      icon: '🧮',
      category: 'optimal',
      parameters: [
        { key: 'kellyFraction', name: '凯利分数', type: 'number', default: 0.5, min: 0.1, max: 1, step: 0.1 },
        { key: 'maxPosition', name: '最大仓位 (%)', type: 'number', default: 30, min: 10, max: 100 }
      ]
    },
    {
      id: 'volatility_target',
      name: '波动率目标',
      description: '根据波动率调整仓位大小',
      icon: '📊',
      category: 'risk_based',
      parameters: [
        { key: 'targetVol', name: '目标波动率 (%)', type: 'number', default: 15, min: 5, max: 50 },
        { key: 'lookbackPeriod', name: '回望周期', type: 'number', default: 20, min: 10, max: 60 }
      ]
    },
    {
      id: 'risk_parity',
      name: '风险平价',
      description: '各资产风险贡献相等',
      icon: '⚖️',
      category: 'balanced',
      parameters: [
        { key: 'maxPosition', name: '最大仓位 (%)', type: 'number', default: 25, min: 10, max: 100 }
      ]
    }
  ]
};

// Strategy categories
export const strategyCategories = [
  { id: 'trend', name: '趋势跟踪', icon: '📈' },
  { id: 'momentum', name: '动量策略', icon: '⭐' },
  { id: 'mean_reversion', name: '均值回归', icon: '🔄' },
  { id: 'volatility', name: '波动率策略', icon: '📉' },
  { id: 'volume', name: '成交量策略', icon: '📢' }
];

// ============================================================================
// Model Card Component
// ============================================================================

/**
 * Create a trading model card
 * @param {Object} model - Model data
 * @param {boolean} selected - Whether selected
 * @returns {HTMLElement} Card element
 */
export function createModelCard(model, selected = false) {
  const card = document.createElement('div');
  card.className = `model-card${selected ? ' selected' : ''}`;
  card.dataset.modelId = model.id;
  card.dataset.modelCategory = model.category;

  card.innerHTML = `
    <div class="model-card-header">
      <span class="model-icon">${model.icon}</span>
      <span class="model-name">${model.name}</span>
    </div>
    <div class="model-card-description">${model.description}</div>
    <div class="model-card-footer">
      <span class="model-category-badge ${model.category}">${getCategoryName(model.category)}</span>
      ${model.parameters?.length > 0 ? `
        <span class="model-params-count">${model.parameters.length} 个参数</span>
      ` : ''}
    </div>
    ${selected ? '<div class="model-selected-badge">✓ 已选择</div>' : ''}
  `;

  return card;
}

/**
 * Get category name in Chinese
 * @param {string} categoryId - Category ID
 * @returns {string} Category name
 */
function getCategoryName(categoryId) {
  const category = strategyCategories.find(c => c.id === categoryId);
  return category?.name || categoryId;
}

// ============================================================================
// Parameter Editor Component
// ============================================================================

/**
 * Create parameter editor for a model
 * @param {Object} model - Model data
 * @param {Object} values - Current parameter values
 * @returns {HTMLElement} Editor element
 */
export function createParameterEditor(model, values = {}) {
  const editor = document.createElement('div');
  editor.className = 'parameter-editor';
  editor.dataset.modelId = model.id;

  if (!model.parameters || model.parameters.length === 0) {
    editor.innerHTML = `
      <div class="parameter-editor-empty">
        <span>该策略无需配置参数</span>
      </div>
    `;
    return editor;
  }

  const paramsHtml = model.parameters.map(param => {
    const currentValue = values[param.key] ?? param.default;

    if (param.type === 'number') {
      return `
        <div class="parameter-row" data-param="${param.key}">
          <label class="parameter-label">
            <span class="param-name">${param.name}</span>
            <span class="param-default">默认：${param.default}</span>
          </label>
          <div class="parameter-input-wrapper">
            <input type="number"
                   class="parameter-input"
                   value="${currentValue}"
                   min="${param.min}"
                   max="${param.max}"
                   step="${param.step || 1}"
                   data-param="${param.key}">
            <span class="param-unit">${param.key.includes('Percent') ? '%' : ''}</span>
          </div>
        </div>
      `;
    }

    return '';
  }).join('');

  editor.innerHTML = `
    <div class="parameter-editor-header">
      <h4>${model.name} - 参数配置</h4>
      <button class="btn-reset-params" title="重置为默认值">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="1 4 1 10 7 10"></polyline>
          <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"></path>
        </svg>
      </button>
    </div>
    <div class="parameter-editor-body">
      ${paramsHtml}
    </div>
  `;

  return editor;
}

/**
 * Get parameter values from editor
 * @param {HTMLElement} editor - Editor element
 * @returns {Object} Parameter values
 */
export function getParameterValues(editor) {
  const values = {};
  const inputs = editor.querySelectorAll('.parameter-input');

  inputs.forEach(input => {
    const param = input.dataset.param;
    values[param] = parseFloat(input.value) || 0;
  });

  return values;
}

// ============================================================================
// Model Builder Component
// ============================================================================

/**
 * Create visual model builder
 * @param {Object} config - Builder configuration
 * @returns {HTMLElement} Builder element
 */
export function createModelBuilder(config = {}) {
  const builder = document.createElement('div');
  builder.className = 'model-builder';

  builder.innerHTML = `
    <div class="builder-canvas">
      <div class="builder-nodes">
        <div class="node entry-node" data-node-type="entry">
          <div class="node-header node-entry">
            <span class="node-icon">📥</span>
            <span class="node-title">买入信号</span>
          </div>
          <div class="node-content" data-slot="entry">
            <span class="empty-slot">点击添加买入策略</span>
          </div>
        </div>

        <div class="node-connector">
          <svg width="20" height="40" viewBox="0 0 20 40">
            <path d="M10 0 L10 40" stroke="#d9d9d9" stroke-width="2" stroke-dasharray="4 4"/>
          </svg>
        </div>

        <div class="node exit-node" data-node-type="exit">
          <div class="node-header node-exit">
            <span class="node-icon">📤</span>
            <span class="node-title">卖出信号</span>
          </div>
          <div class="node-content" data-slot="exit">
            <span class="empty-slot">点击添加卖出策略</span>
          </div>
        </div>

        <div class="node-connector">
          <svg width="20" height="40" viewBox="0 0 20 40">
            <path d="M10 0 L10 40" stroke="#d9d9d9" stroke-width="2" stroke-dasharray="4 4"/>
          </svg>
        </div>

        <div class="node position-node" data-node-type="position">
          <div class="node-header node-position">
            <span class="node-icon">📦</span>
            <span class="node-title">仓位管理</span>
          </div>
          <div class="node-content" data-slot="position">
            <span class="empty-slot">点击添加仓位策略</span>
          </div>
        </div>
      </div>
    </div>

    <div class="builder-sidebar">
      <div class="sidebar-section">
        <h4>可用策略</h4>
        <div class="strategy-list" id="builder-strategy-list">
          <!-- Dynamically populated -->
        </div>
      </div>
    </div>
  `;

  return builder;
}

/**
 * Add model to builder node
 * @param {HTMLElement} builder - Builder element
 * @param {string} nodeType - Node type (entry/exit/position)
 * @param {Object} model - Model data
 */
export function addModelToNode(builder, nodeType, model) {
  const node = builder.querySelector(`[data-node-type="${nodeType}"] .node-content`);
  if (!node) return;

  node.innerHTML = `
    <div class="selected-model" data-model-id="${model.id}">
      <span class="model-icon">${model.icon}</span>
      <span class="model-name">${model.name}</span>
      <button class="btn-remove-model" title="移除">×</button>
    </div>
    <div class="model-quick-params"></div>
  `;

  // Add parameter editor
  if (model.parameters?.length > 0) {
    const paramContainer = node.querySelector('.model-quick-params');
    const editor = createParameterEditor(model);
    paramContainer.appendChild(editor);
  }
}

// ============================================================================
// Model Selection Panel
// ============================================================================

/**
 * Create model selection panel
 * @param {string} type - Panel type (entry/exit/position)
 * @returns {HTMLElement} Panel element
 */
export function createModelSelectionPanel(type) {
  const panel = document.createElement('div');
  panel.className = 'model-selection-panel';
  panel.dataset.panelType = type;

  const models = tradingModels[type] || [];
  const categories = [...new Set(models.map(m => m.category))];

  let categoriesHtml = '';
  categories.forEach(catId => {
    const catModels = models.filter(m => m.category === catId);
    const category = strategyCategories.find(c => c.id === catId);

    categoriesHtml += `
      <div class="model-category-group">
        <h5 class="category-group-title">
          ${category?.icon || '📦'} ${category?.name || catId}
        </h5>
        <div class="model-grid">
          ${catModels.map(model => createModelCard(model).innerHTML).join('')}
        </div>
      </div>
    `;
  });

  panel.innerHTML = `
    <div class="panel-header">
      <h3>选择${getTypeName(type)}</h3>
      <button class="btn-close-panel">×</button>
    </div>
    <div class="panel-body">
      <div class="category-filter">
        <button class="filter-btn active" data-category="all">全部</button>
        ${categories.map(catId => {
          const cat = strategyCategories.find(c => c.id === catId);
          return `<button class="filter-btn" data-category="${catId}">${cat?.name || catId}</button>`;
        }).join('')}
      </div>
      <div class="models-container">
        ${categoriesHtml}
      </div>
    </div>
  `;

  return panel;
}

/**
 * Get type name in Chinese
 * @param {string} type - Type ID
 * @returns {string} Type name
 */
function getTypeName(type) {
  const names = {
    entry: '买入策略',
    exit: '卖出策略',
    position: '仓位策略'
  };
  return names[type] || type;
}

// ============================================================================
// Strategy Summary Component
// ============================================================================

/**
 * Create strategy summary view
 * @param {Object} config - Strategy configuration
 * @returns {HTMLElement} Summary element
 */
export function createStrategySummary(config) {
  const summary = document.createElement('div');
  summary.className = 'strategy-summary';

  const { entry, exit, position } = config;

  summary.innerHTML = `
    <div class="summary-section">
      <h4>策略配置总览</h4>
      <div class="summary-grid">
        <div class="summary-item">
          <span class="summary-label">买入信号</span>
          <div class="summary-value">
            ${entry ? `${entry.icon} ${entry.name}` : '<span class="not-configured">未配置</span>'}
          </div>
        </div>
        <div class="summary-item">
          <span class="summary-label">卖出信号</span>
          <div class="summary-value">
            ${exit ? `${exit.icon} ${exit.name}` : '<span class="not-configured">未配置</span>'}
          </div>
        </div>
        <div class="summary-item">
          <span class="summary-label">仓位管理</span>
          <div class="summary-value">
            ${position ? `${position.icon} ${position.name}` : '<span class="not-configured">未配置</span>'}
          </div>
        </div>
      </div>
    </div>

    <div class="validation-status">
      <span class="status-indicator ${isValid(config) ? 'valid' : 'invalid'}">
        ${isValid(config) ? '✓ 策略配置完整' : '⚠ 请配置买入和卖出信号'}
      </span>
    </div>
  `;

  return summary;
}

/**
 * Check if strategy configuration is valid
 * @param {Object} config - Strategy configuration
 * @returns {boolean} Is valid
 */
export function isValid(config) {
  return !!(config.entry && config.exit);
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * Setup model builder event handlers
 * @param {HTMLElement} builder - Builder element
 * @param {Object} callbacks - Callback functions
 */
export function setupBuilderHandlers(builder, callbacks = {}) {
  const { onModelSelect, onModelRemove, onParamChange } = callbacks;

  // Model card click
  builder.addEventListener('click', (e) => {
    const card = e.target.closest('.model-card');
    if (card) {
      onModelSelect?.(card.dataset.modelId);
    }

    // Remove model button
    const removeBtn = e.target.closest('.btn-remove-model');
    if (removeBtn) {
      const node = removeBtn.closest('.node-content');
      const modelId = node.querySelector('.selected-model')?.dataset.modelId;
      onModelRemove?.(modelId);
    }
  });

  // Parameter change
  builder.addEventListener('input', (e) => {
    if (e.target.classList.contains('parameter-input')) {
      const param = e.target.dataset.param;
      onParamChange?.(param, parseFloat(e.target.value));
    }
  });

  // Reset params button
  builder.addEventListener('click', (e) => {
    const resetBtn = e.target.closest('.btn-reset-params');
    if (resetBtn) {
      const editor = resetBtn.closest('.parameter-editor');
      const modelId = editor.dataset.modelId;
      const model = Object.values(tradingModels).flat().find(m => m.id === modelId);
      if (model) {
        editor.querySelectorAll('.parameter-input').forEach(input => {
          const param = model.parameters.find(p => p.key === input.dataset.param);
          if (param) {
            input.value = param.default;
          }
        });
      }
    }
  });
}
