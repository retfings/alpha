/**
 * 股票策略页面交互逻辑
 * Stock Strategy Page Interaction Logic
 *
 * Features:
 * - 4-step strategy configuration (stock selection, trading model, market timing, index hedging)
 * - Condition builder for stock filtering
 * - Backtest with results visualization
 * - Daily selection, realtime selection, and ranking analysis
 * - Toast notifications for user feedback
 */

import * as api from './api.js';

// ============================================================================
// Global State
// ============================================================================

const state = {
  conditions: [],
  tradeConditions: [],
  selectedIndicators: new Set(),
  currentTab: 'market',
  conditionType: 'filter',
  currentStep: 1,
  chartInstances: new Map()
};

// ============================================================================
// Indicator Data Configuration
// ============================================================================

const indicatorData = {
  market: [
    { id: 'price', name: '股票价格' },
    { id: 'turnover_rate', name: '换手率' },
    { id: 'hk_holdings', name: '港资持股' },
    { id: 'price_range', name: '股价振幅' },
    { id: 'amount', name: '成交额' },
    { id: 'limit_flag', name: '涨跌停标记' },
    { id: 'intraday', name: '日内行情' },
    { id: 'volume', name: '成交量' },
    { id: 'market_cap', name: '股本和市值' },
    { id: '15min', name: '15 分钟行情' },
    { id: 'list_days', name: '上市天数' },
    { id: 'trade_days', name: '交易天数' },
    { id: 'price_change', name: '股价涨幅' },
    { id: 'relative_change', name: '股价相对涨幅' },
    { id: 'net_inflow', name: '资金净流入' },
    { id: 'margin', name: '融资融券' },
    { id: 'new_stock', name: '新股指标' },
    { id: 'ah_premium', name: 'AH 股溢价率' }
  ],
  tech: [
    { id: 'ma', name: '均线 MA' },
    { id: 'ema', name: '指数均线 EMA' },
    { id: 'macd', name: 'MACD' },
    { id: 'kdj', name: 'KDJ' },
    { id: 'rsi', name: 'RSI' },
    { id: 'boll', name: '布林带 BOLL' },
    { id: 'atr', name: 'ATR 波动率' }
  ],
  finance: [
    { id: 'pe', name: '市盈率 PE' },
    { id: 'pb', name: '市净率 PB' },
    { id: 'ps', name: '市销率 PS' },
    { id: 'roe', name: '净资产收益率 ROE' },
    { id: 'roa', name: '总资产收益率 ROA' },
    { id: 'debt_ratio', name: '资产负债率' },
    { id: 'gross_margin', name: '毛利率' },
    { id: 'net_margin', name: '净利率' }
  ],
  report: [
    { id: 'revenue', name: '营业收入' },
    { id: 'profit', name: '净利润' },
    { id: 'cash_flow', name: '现金流' },
    { id: 'asset', name: '总资产' }
  ],
  company: [
    { id: 'employee', name: '员工人数' },
    { id: 'founding_date', name: '成立日期' },
    { id: 'registered_capital', name: '注册资本' }
  ],
  analyst: [
    { id: 'rating', name: '评级' },
    { id: 'target_price', name: '目标价' },
    { id: 'forecast', name: '盈利预测' }
  ],
  'market-index': [
    { id: 'market_pe', name: '市场 PE' },
    { id: 'market_pb', name: '市场 PB' },
    { id: 'turnover', name: '市场成交额' }
  ]
};

// Trading signal indicators for Step 2
const tradeSignalData = {
  entry: [
    { id: 'ma_cross', name: '均线交叉' },
    { id: 'macd_gold', name: 'MACD 金叉' },
    { id: 'kdj_cross', name: 'KDJ 交叉' },
    { id: 'rsi_oversold', name: 'RSI 超卖' },
    { id: 'boll_break', name: '布林带突破' },
    { id: 'volume_surge', name: '成交量激增' },
    { id: 'price_breakout', name: '价格突破' },
    { id: 'gap_up', name: '跳空高开' }
  ],
  exit: [
    { id: 'ma_cross_exit', name: '均线交叉 (出)' },
    { id: 'macd_death', name: 'MACD 死叉' },
    { id: 'kdj_cross_exit', name: 'KDJ 交叉 (出)' },
    { id: 'rsi_overbought', name: 'RSI 超买' },
    { id: 'boll_break_exit', name: '布林带跌破' },
    { id: 'volume_drop', name: '成交量萎缩' }
  ],
  stop: [
    { id: 'fixed_stop', name: '固定止损' },
    { id: 'trail_stop', name: '移动止盈' },
    { id: 'time_stop', name: '时间止盈' },
    { id: 'signal_stop', name: '信号止盈' }
  ],
  position: [
    { id: 'fixed_position', name: '固定仓位' },
    { id: 'kelly', name: '凯利公式' },
    { id: 'risk_parity', name: '风险平价' },
    { id: 'volatility_target', name: '波动率目标' }
  ]
};

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

// Local industry data (fallback)
const localIndustries = {
  sw2014: [
    { id: 'agricultura', name: '农林牧渔' },
    { id: 'food', name: '食品饮料' },
    { id: 'textile', name: '纺织服装' },
    { id: 'light', name: '轻工制造' },
    { id: 'medicine', name: '医药生物' }
  ],
  sw2021: [
    { id: 'agricultura2', name: '农林牧渔' },
    { id: 'food2', name: '食品饮料' },
    { id: 'household', name: '家用电器' }
  ],
  csrc: [
    { id: 'agricultura3', name: '农、林、牧、渔业' },
    { id: 'mining', name: '采矿业' },
    { id: 'manufacturing', name: '制造业' }
  ]
};

// ============================================================================
// Toast Notification System
// ============================================================================

const Toast = {
  container: null,

  init() {
    this.container = document.getElementById('toast-container');
  },

  show(message, type = 'info', duration = 3000) {
    if (!this.container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
      <span class="toast-icon">${this.getIcon(type)}</span>
      <span class="toast-message">${message}</span>
      <button class="toast-close">&times;</button>
    `;

    // Close button handler
    toast.querySelector('.toast-close').addEventListener('click', () => {
      this.remove(toast);
    });

    this.container.appendChild(toast);

    // Auto remove after duration
    if (duration > 0) {
      setTimeout(() => this.remove(toast), duration);
    }

    return toast;
  },

  remove(toast) {
    toast.classList.add('hiding');
    setTimeout(() => toast.remove(), 300);
  },

  getIcon(type) {
    const icons = {
      success: '&#10004;',
      error: '&#10006;',
      warning: '&#9888;',
      info: '&#8505;'
    };
    return icons[type] || icons.info;
  },

  success(message) {
    return this.show(message, 'success');
  },

  error(message) {
    return this.show(message, 'error');
  },

  warning(message) {
    return this.show(message, 'warning');
  },

  info(message) {
    return this.show(message, 'info');
  }
};

// ============================================================================
// Application Initialization
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
  // Initialize toast system
  Toast.init();

  // Initialize all components
  initTabs();
  initIndicatorTabs();
  initConditionTabs();
  initIndicatorList();
  initAddCondition();
  initEnhancedConditionBuilder(); // Enhanced features: drag-drop, save/load, expand/collapse
  initBacktestControls();
  initSaveButton();
  initNewButton();
  initIndustryChain();
  initTradeSignals();
  initResultsPanel();
  initDailySelection();
  initRealtimeSelection();
  initRankingAnalysis();

  // Initial render
  renderConditions();
});

// ============================================================================
// Step Navigation
// ============================================================================

function initTabs() {
  const steps = document.querySelectorAll('.step');
  steps.forEach((step, index) => {
    step.addEventListener('click', () => {
      steps.forEach(s => s.classList.remove('active'));
      step.classList.add('active');

      // Update panel
      document.querySelectorAll('.panel').forEach((panel, i) => {
        panel.classList.toggle('active', i === index);
      });

      state.currentStep = index + 1;
    });
  });
}

// ============================================================================
// Indicator Tabs (Step 1)
// ============================================================================

function initIndicatorTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      tabBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.currentTab = btn.dataset.tab;
      updateIndicatorList();
    });
  });
}

function updateIndicatorList() {
  const indicatorList = document.querySelector('.indicator-group');
  if (!indicatorList) return;

  const indicators = indicatorData[state.currentTab] || [];
  indicatorList.innerHTML = indicators.map(ind => `
    <div class="indicator-item" data-field="${ind.id}">
      <span>${ind.name}</span>
      <span class="indicator-arrow">&or;</span>
    </div>
  `).join('');

  // Rebind click events
  document.querySelectorAll('.indicator-item').forEach(item => {
    item.addEventListener('click', () => {
      const field = item.dataset.field;
      const name = item.querySelector('span').textContent;
      addCondition(field, name);
    });
  });
}

// ============================================================================
// Condition Type Tabs
// ============================================================================

function initConditionTabs() {
  const tabBtns = document.querySelectorAll('.condition-tab-btn');
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      tabBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.conditionType = btn.dataset.type;
      renderConditions();
    });
  });
}

// ============================================================================
// Indicator List Initialization
// ============================================================================

function initIndicatorList() {
  document.querySelectorAll('.indicator-item').forEach(item => {
    item.addEventListener('click', () => {
      const field = item.dataset.field;
      const name = item.querySelector('span').textContent;
      addCondition(field, name);
    });
  });
}

// ============================================================================
// Condition Management
// ============================================================================

function addCondition(field, name) {
  const condition = {
    id: Date.now(),
    field,
    name,
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
  renderConditions();
  Toast.info(`已添加条件：${name}`);
}

function renderConditions() {
  const tbody = document.getElementById('condition-body');
  if (!tbody) return;

  if (state.conditions.length === 0) {
    tbody.innerHTML = `
      <tr class="empty-row">
        <td colspan="6" style="text-align: center; padding: 24px; color: #999;">
          点击选择选股指标，生成股票筛选条件
        </td>
      </tr>
    `;
    return;
  }

  // Render with drag-and-drop and expand/collapse support
  tbody.innerHTML = state.conditions.map((cond, index) => renderConditionWithDetail(cond, index)).join('');

  // Attach drag-and-drop event listeners
  document.querySelectorAll('tr.condition-row').forEach((row, index) => {
    row.addEventListener('dragstart', (e) => handleDragStart(e, index));
    row.addEventListener('dragover', handleDragOver);
    row.addEventListener('dragenter', (e) => handleDragEnter(e));
    row.addEventListener('dragleave', (e) => handleDragLeave(e));
    row.addEventListener('drop', (e) => handleDrop(e, index));
    row.addEventListener('dragend', handleDragEnd);
  });

  // Bind operator change events
  document.querySelectorAll('.condition-operator').forEach(select => {
    select.addEventListener('change', (e) => {
      const index = parseInt(e.target.dataset.index);
      state.conditions[index].operator = e.target.value;
    });
  });

  // Bind range input events
  document.querySelectorAll('.condition-range').forEach(input => {
    input.addEventListener('input', (e) => {
      const index = parseInt(e.target.dataset.index);
      state.conditions[index].range = e.target.value;
    });
  });

  // Bind value input events
  document.querySelectorAll('.condition-value').forEach(input => {
    input.addEventListener('input', (e) => {
      const index = parseInt(e.target.dataset.index);
      state.conditions[index].value = e.target.value;
    });
  });

  // Bind detail panel field change events
  document.querySelectorAll('.condition-detail-panel select, .condition-detail-panel input').forEach(field => {
    field.addEventListener('change', (e) => {
      const index = parseInt(e.target.dataset.conditionIndex);
      const fieldName = e.target.dataset.field;
      let value = e.target.value;

      // Convert types
      if (fieldName === 'window' || fieldName === 'weight') {
        value = parseFloat(value);
      } else if (fieldName === 'enabled') {
        value = value === 'true';
      }

      state.conditions[index][fieldName] = value;
    });
  });

  // Bind remove button events
  document.querySelectorAll('.btn-remove-condition').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const index = parseInt(e.target.dataset.index);
      const removed = state.conditions.splice(index, 1);
      if (removed.length > 0) {
        Toast.info(`已删除：${removed[0].name}`);
      }
      renderConditions();
    });
  });

  // Bind config button events
  document.querySelectorAll('.btn-config-condition').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const index = parseInt(e.target.dataset.index);
      toggleConditionDetail(state.conditions[index].id);
    });
  });
}

function initAddCondition() {
  const btn = document.getElementById('btn-add-condition');
  if (btn) {
    btn.addEventListener('click', () => {
      addCondition('price', '股票价格');
    });
  }
}

// ============================================================================
// Enhanced Condition Builder Features
// ============================================================================

// Local storage keys
const STORAGE_KEYS = {
  SAVED_CONDITIONS: 'stock_strategy_conditions',
  SAVED_CONDITION_SETS: 'stock_strategy_condition_sets'
};

/**
 * Initialize enhanced condition builder (expand/collapse, drag-drop, save/load)
 */
function initEnhancedConditionBuilder() {
  initDragAndDrop();
  initConditionSaveLoad();
}

// ----------------------------------------------------------------------------
// Expand/Collapse Feature
// ----------------------------------------------------------------------------

/**
 * Toggle condition detail panel
 */
function toggleConditionDetail(conditionId) {
  const detailPanel = document.getElementById(`condition-detail-${conditionId}`);
  if (!detailPanel) return;

  const isCollapsed = detailPanel.style.display === 'none';
  detailPanel.style.display = isCollapsed ? 'block' : 'none';

  // Update arrow icon
  const arrowEl = document.getElementById(`arrow-${conditionId}`);
  if (arrowEl) {
    arrowEl.textContent = isCollapsed ? '∧' : '∨';
  }
}

/**
 * Render condition with expand/collapse support
 */
function renderConditionWithDetail(cond, index) {
  const isExpanded = cond.expanded !== false;

  return `
    <tr data-id="${cond.id}" class="condition-row" draggable="true">
      <td class="drag-handle" style="cursor: grab; width: 30px;">⋮⋮</td>
      <td>
        <span style="cursor: pointer;" onclick="toggleConditionDetail(${cond.id})">
          ${cond.name}
        </span>
        <span id="arrow-${cond.id}" style="font-size: 12px; color: #999; margin-left: 4px;">${isExpanded ? '∧' : '∨'}</span>
      </td>
      <td>
        <select class="condition-operator" data-index="${index}">
          ${operators.map(op => `
            <option value="${op.value}" ${cond.operator === op.value ? 'selected' : ''}>
              ${op.label}
            </option>
          `).join('')}
        </select>
      </td>
      <td>
        <input type="text" class="condition-range" data-index="${index}"
               value="${cond.range || ''}" placeholder="全部">
      </td>
      <td>
        <input type="text" class="condition-value" data-index="${index}"
               value="${cond.value || ''}" placeholder="输入值">
      </td>
      <td>
        <button class="btn-config-condition" data-index="${index}"
                style="background:none;border:none;color:#1890ff;cursor:pointer;margin-right:8px;"
                title="配置">
          ⚙
        </button>
        <button class="btn-remove-condition" data-index="${index}"
                style="background:none;border:none;color:#ff4d4f;cursor:pointer;"
                title="删除">
          ×
        </button>
      </td>
    </tr>
    <tr id="condition-detail-${cond.id}" class="condition-detail-row" style="${isExpanded ? '' : 'display: none;'}">
      <td colspan="7" style="padding: 16px; background: #fafafa;">
        <div class="condition-detail-panel">
          <h5 style="margin: 0 0 12px 0; font-size: 13px; color: #333;">详细配置 - ${cond.name}</h5>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
            <div>
              <label style="font-size: 12px; color: #666;">数据周期：</label>
              <select class="form-select" data-field="period" data-condition-index="${index}" style="width: 100%;">
                <option value="daily" ${cond.period === 'daily' ? 'selected' : ''}>日线</option>
                <option value="weekly" ${cond.period === 'weekly' ? 'selected' : ''}>周线</option>
                <option value="monthly" ${cond.period === 'monthly' ? 'selected' : ''}>月线</option>
                <option value="intraday" ${cond.period === 'intraday' ? 'selected' : ''}>分时</option>
              </select>
            </div>
            <div>
              <label style="font-size: 12px; color: #666;">计算窗口：</label>
              <input type="number" class="form-select" data-field="window" data-condition-index="${index}"
                     value="${cond.window || 20}" min="1" max="250"
                     style="width: 100%;">
            </div>
            <div>
              <label style="font-size: 12px; color: #666;">权重：</label>
              <input type="number" class="form-select" data-field="weight" data-condition-index="${index}"
                     value="${cond.weight || 1}" min="0.1" max="10" step="0.1"
                     style="width: 100%;">
            </div>
            <div>
              <label style="font-size: 12px; color: #666;">是否启用：</label>
              <select class="form-select" data-field="enabled" data-condition-index="${index}" style="width: 100%;">
                <option value="true" ${cond.enabled !== false ? 'selected' : ''}>是</option>
                <option value="false" ${cond.enabled === false ? 'selected' : ''}>否</option>
              </select>
            </div>
          </div>
        </div>
      </td>
    </tr>
  `;
}

// ----------------------------------------------------------------------------
// Drag and Drop Feature
// ----------------------------------------------------------------------------

let dragSrcIndex = null;

/**
 * Initialize drag and drop for conditions
 */
function initDragAndDrop() {
  // Event handlers are attached during render
}

/**
 * Handle drag start
 */
function handleDragStart(e, index) {
  dragSrcIndex = index;
  e.target.style.opacity = '0.4';
  e.dataTransfer.effectAllowed = 'move';
  e.dataTransfer.setData('text/plain', index);
}

/**
 * Handle drag over
 */
function handleDragOver(e) {
  if (e.preventDefault) {
    e.preventDefault();
  }
  e.dataTransfer.dropEffect = 'move';
  return false;
}

/**
 * Handle drag enter
 */
function handleDragEnter(e) {
  const row = e.target.closest('tr.condition-row');
  if (row) {
    row.style.background = '#e6f7ff';
  }
}

/**
 * Handle drag leave
 */
function handleDragLeave(e) {
  const row = e.target.closest('tr.condition-row');
  if (row) {
    row.style.background = '';
  }
}

/**
 * Handle drop
 */
function handleDrop(e, targetIndex) {
  e.stopPropagation();

  const row = e.target.closest('tr.condition-row');
  if (row) {
    row.style.background = '';
  }

  if (dragSrcIndex === null || dragSrcIndex === targetIndex) {
    return false;
  }

  // Reorder conditions array
  const movedCondition = state.conditions[dragSrcIndex];
  state.conditions.splice(dragSrcIndex, 1);
  state.conditions.splice(targetIndex, 0, movedCondition);

  // Re-render
  renderConditions();

  Toast.info(`条件已移动到第 ${targetIndex + 1} 位`);

  dragSrcIndex = null;
  return false;
}

/**
 * Handle drag end
 */
function handleDragEnd(e) {
  e.target.style.opacity = '1';

  // Clean up any remaining highlight
  document.querySelectorAll('tr.condition-row').forEach(row => {
    row.style.background = '';
  });
}

// ----------------------------------------------------------------------------
// Save/Load Conditions Feature
// ----------------------------------------------------------------------------

/**
 * Initialize condition save/load UI
 */
function initConditionSaveLoad() {
  // Add save/load buttons to the condition builder UI
  const conditionHeader = document.querySelector('.condition-header');
  if (conditionHeader) {
    // Check if buttons already exist
    if (!document.getElementById('btn-save-conditions')) {
      const buttonGroup = document.createElement('div');
      buttonGroup.style.cssText = 'display: flex; gap: 8px; margin-top: 12px;';
      buttonGroup.innerHTML = `
        <button id="btn-save-conditions" class="btn-save" style="padding: 6px 12px; font-size: 13px;">
          保存条件组合
        </button>
        <button id="btn-load-conditions" class="btn-new" style="padding: 6px 12px; font-size: 13px;">
          加载条件组合
        </button>
        <button id="btn-clear-conditions" class="btn-new" style="padding: 6px 12px; font-size: 13px; color: #ff4d4f; border-color: #ff4d4f;">
          清空条件
        </button>
      `;
      conditionHeader.appendChild(buttonGroup);

      // Bind events
      document.getElementById('btn-save-conditions').addEventListener('click', showSaveConditionModal);
      document.getElementById('btn-load-conditions').addEventListener('click', showLoadConditionModal);
      document.getElementById('btn-clear-conditions').addEventListener('click', clearAllConditions);
    }
  }
}

/**
 * Save conditions to local storage
 */
function saveConditionsToStorage(name, conditions) {
  try {
    const sets = getSavedConditionSets();
    const existingIndex = sets.findIndex(s => s.name === name);

    const conditionSet = {
      id: Date.now().toString(),
      name,
      conditions: JSON.parse(JSON.stringify(conditions)),
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    if (existingIndex >= 0) {
      sets[existingIndex] = conditionSet;
      sets[existingIndex].updatedAt = new Date().toISOString();
    } else {
      sets.push(conditionSet);
    }

    localStorage.setItem(STORAGE_KEYS.SAVED_CONDITION_SETS, JSON.stringify(sets));
    return true;
  } catch (error) {
    console.error('Failed to save conditions:', error);
    return false;
  }
}

/**
 * Load conditions from local storage
 */
function loadConditionsFromStorage(id) {
  try {
    const sets = getSavedConditionSets();
    const conditionSet = sets.find(s => s.id === id);

    if (!conditionSet) {
      Toast.error('条件组合不存在');
      return false;
    }

    state.conditions = JSON.parse(JSON.stringify(conditionSet.conditions));
    renderConditions();
    Toast.success(`已加载条件组合：${conditionSet.name}`);
    return true;
  } catch (error) {
    console.error('Failed to load conditions:', error);
    Toast.error('加载失败：' + error.message);
    return false;
  }
}

/**
 * Get all saved condition sets
 */
function getSavedConditionSets() {
  try {
    const data = localStorage.getItem(STORAGE_KEYS.SAVED_CONDITION_SETS);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

/**
 * Delete a saved condition set
 */
function deleteConditionSet(id) {
  try {
    const sets = getSavedConditionSets();
    const filtered = sets.filter(s => s.id !== id);
    localStorage.setItem(STORAGE_KEYS.SAVED_CONDITION_SETS, JSON.stringify(filtered));
    return true;
  } catch (error) {
    console.error('Failed to delete condition set:', error);
    return false;
  }
}

/**
 * Show save condition modal
 */
function showSaveConditionModal() {
  if (state.conditions.length === 0) {
    Toast.warning('请先添加条件');
    return;
  }

  const name = prompt('请输入条件组合名称:');
  if (!name) return;

  if (saveConditionsToStorage(name, state.conditions)) {
    Toast.success(`条件组合 "${name}" 已保存`);
  } else {
    Toast.error('保存失败');
  }
}

/**
 * Show load condition modal
 */
function showLoadConditionModal() {
  const sets = getSavedConditionSets();

  if (sets.length === 0) {
    Toast.info('暂无保存的条件组合');
    return;
  }

  const options = sets.map((s, index) => {
    const date = new Date(s.updatedAt).toLocaleDateString('zh-CN');
    return `${index + 1}. ${s.name} (${s.conditions.length}个条件) - 更新于${date}`;
  }).join('\n');

  const choice = prompt(`已保存的条件组合:\n${options}\n\n请输入序号加载 (或输入 "d:序号" 删除):`);
  if (!choice) return;

  if (choice.toLowerCase().startsWith('d:')) {
    // Delete mode
    const index = parseInt(choice.slice(2)) - 1;
    if (index >= 0 && index < sets.length) {
      if (confirm(`确定删除 "${sets[index].name}" 吗？`)) {
        deleteConditionSet(sets[index].id);
        Toast.success('已删除');
      }
    }
  } else {
    // Load mode
    const index = parseInt(choice) - 1;
    if (index >= 0 && index < sets.length) {
      loadConditionsFromStorage(sets[index].id);
    } else {
      Toast.error('无效的序号');
    }
  }
}

/**
 * Clear all conditions
 */
function clearAllConditions() {
  if (state.conditions.length === 0) {
    Toast.info('当前没有条件');
    return;
  }

  if (confirm('确定清空所有条件吗？此操作不可恢复。')) {
    state.conditions = [];
    renderConditions();
    Toast.info('已清空所有条件');
  }
}

// ----------------------------------------------------------------------------
// Export/Import Conditions
// ----------------------------------------------------------------------------

/**
 * Export conditions to JSON file
 */
function exportConditions() {
  if (state.conditions.length === 0) {
    Toast.warning('没有条件可导出');
    return;
  }

  const data = {
    version: '1.0',
    exportedAt: new Date().toISOString(),
    conditions: state.conditions
  };

  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `condition-set-${new Date().toISOString().split('T')[0]}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);

  Toast.success('条件已导出');
}

/**
 * Import conditions from JSON file
 */
function importConditions(jsonString) {
  try {
    const data = JSON.parse(jsonString);

    if (!data.conditions || !Array.isArray(data.conditions)) {
      throw new Error('无效的文件格式');
    }

    state.conditions = data.conditions;
    renderConditions();
    Toast.success(`成功导入 ${state.conditions.length} 个条件`);
    return true;
  } catch (error) {
    Toast.error('导入失败：' + error.message);
    return false;
  }
}

// ============================================================================
// Trade Signals (Step 2)
// ============================================================================

function initTradeSignals() {
  // Initialize trade signal tabs
  const step2Tabs = document.querySelectorAll('#panel-step-2 .tab-btn');
  let currentTradeTab = 'entry';

  step2Tabs.forEach(btn => {
    btn.addEventListener('click', () => {
      step2Tabs.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentTradeTab = btn.dataset.tab;
      updateTradeSignalList();
    });
  });

  // Initialize trade signal list
  updateTradeSignalList();

  // Add trade condition button
  const btnAddTrade = document.getElementById('btn-add-trade');
  if (btnAddTrade) {
    btnAddTrade.addEventListener('click', () => {
      addTradeCondition('ma_cross', '均线交叉');
    });
  }
}

function updateTradeSignalList() {
  const step2Group = document.querySelector('#panel-step-2 .indicator-group');
  if (!step2Group) return;

  // Find the active tab in step 2
  const activeTab = document.querySelector('#panel-step-2 .tab-btn.active');
  const tabType = activeTab ? activeTab.dataset.tab : 'entry';

  const signals = tradeSignalData[tabType] || [];
  step2Group.innerHTML = signals.map(signal => `
    <div class="indicator-item" data-field="${signal.id}">
      <span>${signal.name}</span>
      <span class="indicator-arrow">&or;</span>
    </div>
  `).join('');

  // Bind click events
  document.querySelectorAll('#panel-step-2 .indicator-item').forEach(item => {
    item.addEventListener('click', () => {
      const field = item.dataset.field;
      const name = item.querySelector('span').textContent;
      addTradeCondition(field, name);
    });
  });
}

function addTradeCondition(field, name) {
  const condition = {
    id: Date.now(),
    field,
    name,
    params: {}
  };
  state.tradeConditions.push(condition);
  renderTradeConditions();
  Toast.info(`已添加交易信号：${name}`);
}

function renderTradeConditions() {
  const tbody = document.getElementById('trade-condition-body');
  if (!tbody) return;

  if (state.tradeConditions.length === 0) {
    tbody.innerHTML = `
      <tr class="empty-row">
        <td colspan="4">点击选择技术指标，生成交易条件</td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = state.tradeConditions.map((cond, index) => `
    <tr data-id="${cond.id}">
      <td>${cond.name}</td>
      <td>
        <input type="text" class="trade-param" data-index="${index}"
               placeholder="参数" style="width: 100%; padding: 4px 8px; border: 1px solid #d9d9d9; border-radius: 4px;">
      </td>
      <td>
        <input type="text" class="trade-value" data-index="${index}"
               placeholder="阈值" style="width: 100%; padding: 4px 8px; border: 1px solid #d9d9d9; border-radius: 4px;">
      </td>
      <td>
        <button class="btn-remove-trade" data-index="${index}"
                style="background:none;border:none;color:#ff4d4f;cursor:pointer;">
          删除
        </button>
      </td>
    </tr>
  `).join('');

  // Bind events
  document.querySelectorAll('.btn-remove-trade').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const index = parseInt(e.target.dataset.index);
      state.tradeConditions.splice(index, 1);
      renderTradeConditions();
    });
  });
}

// ============================================================================
// Backtest Controls
// ============================================================================

function initBacktestControls() {
  // Backtest tabs
  const backtestTabs = document.querySelectorAll('.backtest-tab-btn');
  backtestTabs.forEach(btn => {
    btn.addEventListener('click', () => {
      backtestTabs.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      document.querySelectorAll('.backtest-panel').forEach(panel => {
        panel.classList.remove('active');
      });

      const panelId = btn.dataset.tab + '-panel';
      const panel = document.getElementById(panelId);
      if (panel) panel.classList.add('active');
    });
  });

  // Date navigation buttons
  const btnFirst = document.getElementById('btn-first');
  const btnPrev = document.getElementById('btn-prev');
  const btnNext = document.getElementById('btn-next');
  const btnLast = document.getElementById('btn-last');

  const startDateInput = document.getElementById('backtest-start-date');
  const endDateInput = document.getElementById('backtest-end-date');

  if (btnFirst && startDateInput) {
    btnFirst.addEventListener('click', () => {
      startDateInput.value = '2020/01/01';
    });
  }

  if (btnPrev && startDateInput) {
    btnPrev.addEventListener('click', () => {
      const date = new Date(startDateInput.value);
      date.setDate(date.getDate() - 1);
      startDateInput.value = formatDate(date);
    });
  }

  if (btnNext && startDateInput) {
    btnNext.addEventListener('click', () => {
      const date = new Date(startDateInput.value);
      date.setDate(date.getDate() + 1);
      startDateInput.value = formatDate(date);
    });
  }

  if (btnLast && startDateInput) {
    btnLast.addEventListener('click', () => {
      startDateInput.value = new Date().toISOString().split('T')[0];
    });
  }

  // Run backtest button
  const btnRun = document.getElementById('btn-run-backtest');
  if (btnRun) {
    btnRun.addEventListener('click', runBacktest);
  }
}

function formatDate(date) {
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}/${month}/${day}`;
}

async function runBacktest() {
  const startDate = document.getElementById('backtest-start-date')?.value;
  const endDate = document.getElementById('backtest-end-date')?.value;
  const benchmark = document.getElementById('benchmark')?.value;
  const cost = document.getElementById('transaction-cost')?.value;
  const excludePeriod = document.getElementById('exclude-period')?.checked;

  const config = {
    conditions: state.conditions,
    trade_conditions: state.tradeConditions,
    start_date: startDate,
    end_date: endDate,
    benchmark,
    transaction_cost: parseFloat(cost) || 0.0002,
    exclude_period: excludePeriod
  };

  // Update button state
  const btn = document.getElementById('btn-run-backtest');
  if (btn) {
    btn.classList.add('loading');
    btn.disabled = true;
  }

  try {
    // Call API to run backtest
    const result = await api.runStrategyBacktest(config);
    console.log('Backtest result:', result);

    // Display results
    displayBacktestResults(result);

    Toast.success('回测完成！');
  } catch (error) {
    console.error('Backtest error:', error);
    Toast.error('回测失败：' + (error.message || '未知错误'));
  } finally {
    if (btn) {
      btn.classList.remove('loading');
      btn.disabled = false;
    }
  }
}

// ============================================================================
// Results Visualization
// ============================================================================

let equityChart = null;
let drawdownChart = null;
let comparisonChart = null;

function initResultsPanel() {
  // Close results button
  const btnClose = document.getElementById('btn-close-results');
  if (btnClose) {
    btnClose.addEventListener('click', () => {
      document.getElementById('results-panel').classList.remove('active');
      document.getElementById('backtest-panel').classList.add('active');
    });
  }
}

function displayBacktestResults(result) {
  // Switch to results panel
  document.querySelectorAll('.backtest-panel').forEach(panel => {
    panel.classList.remove('active');
  });
  document.getElementById('results-panel').classList.add('active');

  // Update metrics
  updateMetric('result-total-return', formatPercent(result.total_return), result.total_return >= 0);
  updateMetric('result-annual-return', formatPercent(result.annual_return), result.annual_return >= 0);
  updateMetric('result-benchmark-return', formatPercent(result.benchmark_return), result.benchmark_return >= 0);
  updateMetric('result-excess-return', formatPercent(result.excess_return), result.excess_return >= 0);
  updateMetric('result-sharpe-ratio', formatNumber(result.sharpe_ratio, 3), result.sharpe_ratio > 0);
  updateMetric('result-max-drawdown', formatPercent(result.max_drawdown), false);
  updateMetric('result-total-trades', String(result.total_trades || 0), true);
  updateMetric('result-win-rate', formatPercent(result.win_rate || 0), (result.win_rate || 0) >= 0.5);

  // Update charts
  renderEquityChart(result.equity_curve);
  renderDrawdownChart(result.drawdown_series);
  renderComparisonChart(result.comparison_data);

  // Update trade list
  renderTradeList(result.trades);
}

function updateMetric(elementId, value, isPositive) {
  const el = document.getElementById(elementId);
  if (el) {
    el.textContent = value;
    el.className = 'result-value ' + (isPositive ? 'positive' : 'negative');
  }
}

function formatPercent(value) {
  if (value === null || value === undefined) return '--';
  const num = parseFloat(value) || 0;
  const sign = num < 0 ? '-' : '';
  return sign + (Math.abs(num) * 100).toFixed(2) + '%';
}

function formatNumber(value, decimals = 2) {
  if (value === null || value === undefined) return '--';
  return (parseFloat(value) || 0).toFixed(decimals);
}

function renderEquityChart(data) {
  const canvas = document.getElementById('result-equity-chart');
  if (!canvas || !window.Chart) return;

  // Destroy existing chart
  if (equityChart) equityChart.destroy();

  const ctx = canvas.getContext('2d');
  equityChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: data?.map(d => d.date) || [],
      datasets: [{
        label: '权益',
        data: data?.map(d => d.value) || [],
        borderColor: '#1890ff',
        backgroundColor: 'rgba(24, 144, 255, 0.1)',
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
        x: { display: false },
        y: {
          display: true,
          title: { display: true, text: '净值' }
        }
      }
    }
  });
}

function renderDrawdownChart(data) {
  const canvas = document.getElementById('result-drawdown-chart');
  if (!canvas || !window.Chart) return;

  if (drawdownChart) drawdownChart.destroy();

  const ctx = canvas.getContext('2d');
  drawdownChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: data?.map(d => d.date) || [],
      datasets: [{
        label: '回撤',
        data: data?.map(d => d.drawdown) || [],
        borderColor: '#ff4d4f',
        backgroundColor: 'rgba(255, 77, 79, 0.1)',
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
        x: { display: false },
        y: {
          display: true,
          title: { display: true, text: '回撤' },
          ticks: {
            callback: (value) => (value * 100).toFixed(0) + '%'
          }
        }
      }
    }
  });
}

function renderComparisonChart(data) {
  const canvas = document.getElementById('result-comparison-chart');
  if (!canvas || !window.Chart) return;

  if (comparisonChart) comparisonChart.destroy();

  const ctx = canvas.getContext('2d');
  comparisonChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: data?.map(d => d.date) || [],
      datasets: [
        {
          label: '策略',
          data: data?.map(d => d.strategy) || [],
          borderColor: '#1890ff',
          fill: false,
          tension: 0.1
        },
        {
          label: '基准',
          data: data?.map(d => d.benchmark) || [],
          borderColor: '#52c41a',
          fill: false,
          tension: 0.1
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: true, position: 'top' }
      },
      scales: {
        x: {
          display: true,
          title: { display: true, text: '日期' }
        },
        y: {
          display: true,
          title: { display: true, text: '累计收益' },
          ticks: {
            callback: (value) => (value * 100).toFixed(0) + '%'
          }
        }
      }
    }
  });
}

function renderTradeList(trades) {
  const tbody = document.getElementById('trade-list-body');
  if (!tbody) return;

  if (!trades || trades.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: #999;">暂无交易记录</td></tr>';
    return;
  }

  tbody.innerHTML = trades.map(trade => `
    <tr>
      <td>${trade.date || '--'}</td>
      <td>${trade.stock_code || '--'}</td>
      <td class="${trade.action === '买入' ? 'positive' : 'negative'}">${trade.action || '--'}</td>
      <td>${formatNumber(trade.price)}</td>
      <td>${formatNumber(trade.quantity, 0)}</td>
      <td>${formatNumber(trade.amount)}</td>
      <td>${formatNumber(trade.commission)}</td>
    </tr>
  `).join('');
}

// ============================================================================
// Daily Selection
// ============================================================================

function initDailySelection() {
  const btnRun = document.getElementById('btn-run-daily');
  if (btnRun) {
    btnRun.addEventListener('click', async () => {
      const date = document.getElementById('daily-date')?.value;

      const btn = document.getElementById('btn-run-daily');
      if (btn) {
        btn.classList.add('loading');
        btn.disabled = true;
      }

      try {
        const result = await api.getDailySelection(state.conditions, date);
        displayDailyResults(result, date);
        Toast.success('查询完成');
      } catch (error) {
        console.error('Daily selection error:', error);
        Toast.error('查询失败：' + (error.message || '未知错误'));
      } finally {
        if (btn) {
          btn.classList.remove('loading');
          btn.disabled = false;
        }
      }
    });
  }
}

function displayDailyResults(result, date) {
  const resultsDiv = document.getElementById('daily-results');
  const stockList = document.getElementById('daily-stock-list');
  const countEl = document.getElementById('daily-stock-count');
  const dateEl = document.getElementById('daily-result-date');

  if (!resultsDiv || !stockList) return;

  resultsDiv.style.display = 'block';
  dateEl.textContent = date;

  const stocks = result?.stocks || [];
  countEl.textContent = stocks.length;

  stockList.innerHTML = stocks.map(stock => `
    <div class="stock-item">
      <div>
        <div class="stock-code">${stock.code}</div>
        <div class="stock-name">${stock.name || ''}</div>
      </div>
      <div class="stock-change ${stock.change >= 0 ? 'positive' : 'negative'}">
        ${stock.change >= 0 ? '+' : ''}${(stock.change * 100).toFixed(2)}%
      </div>
    </div>
  `).join('');
}

// ============================================================================
// Realtime Selection
// ============================================================================

function initRealtimeSelection() {
  const btnRun = document.getElementById('btn-run-realtime');
  if (btnRun) {
    btnRun.addEventListener('click', async () => {
      const btn = document.getElementById('btn-run-realtime');
      const lastRefreshEl = document.getElementById('last-refresh');

      if (btn) {
        btn.classList.add('loading');
        btn.disabled = true;
      }

      try {
        const result = await api.getRealtimeSelection(state.conditions);
        displayRealtimeResults(result);

        // Update refresh time
        const now = new Date();
        lastRefreshEl.textContent = now.toLocaleTimeString('zh-CN');

        Toast.success('获取成功');
      } catch (error) {
        console.error('Realtime selection error:', error);
        Toast.error('获取失败：' + (error.message || '未知错误'));
      } finally {
        if (btn) {
          btn.classList.remove('loading');
          btn.disabled = false;
        }
      }
    });
  }
}

function displayRealtimeResults(result) {
  const resultsDiv = document.getElementById('realtime-results');
  const stockList = document.getElementById('realtime-stock-list');
  const countEl = document.getElementById('realtime-stock-count');

  if (!resultsDiv || !stockList) return;

  resultsDiv.style.display = 'block';

  const stocks = result?.stocks || [];
  countEl.textContent = stocks.length;

  stockList.innerHTML = stocks.map(stock => `
    <div class="stock-item">
      <div>
        <div class="stock-code">${stock.code}</div>
        <div class="stock-name">${stock.name || ''}</div>
      </div>
      <div class="stock-change ${stock.change >= 0 ? 'positive' : 'negative'}">
        ${stock.change >= 0 ? '+' : ''}${(stock.change * 100).toFixed(2)}%
      </div>
    </div>
  `).join('');
}

// ============================================================================
// Ranking Analysis
// ============================================================================

function initRankingAnalysis() {
  const btnRun = document.getElementById('btn-run-ranking');
  if (btnRun) {
    btnRun.addEventListener('click', async () => {
      const period = document.getElementById('ranking-period')?.value || 'daily';

      const btn = document.getElementById('btn-run-ranking');
      if (btn) {
        btn.classList.add('loading');
        btn.disabled = true;
      }

      try {
        const result = await api.getRankingAnalysis(state.conditions, period);
        displayRankingResults(result);
        Toast.success('分析完成');
      } catch (error) {
        console.error('Ranking analysis error:', error);
        Toast.error('分析失败：' + (error.message || '未知错误'));
      } finally {
        if (btn) {
          btn.classList.remove('loading');
          btn.disabled = false;
        }
      }
    });
  }
}

function displayRankingResults(result) {
  const resultsDiv = document.getElementById('ranking-results');
  const tbody = document.getElementById('ranking-body');

  if (!resultsDiv || !tbody) return;

  resultsDiv.style.display = 'block';

  const rankings = result?.rankings || [];

  if (rankings.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #999;">暂无数据</td></tr>';
    return;
  }

  tbody.innerHTML = rankings.map((item, index) => `
    <tr>
      <td>${index + 1}</td>
      <td>
        <div>${item.code}</div>
        <div style="font-size: 12px; color: #999;">${item.name || ''}</div>
      </div>
      </td>
      <td class="${item.return >= 0 ? 'positive' : 'negative'}">
        ${(item.return * 100).toFixed(2)}%
      </td>
      <td class="${item.excess_return >= 0 ? 'positive' : 'negative'}">
        ${(item.excess_return * 100).toFixed(2)}%
      </td>
      <td>${(item.sharpe || 0).toFixed(2)}</td>
      <td class="negative">${(item.max_drawdown * 100).toFixed(2)}%</td>
    </tr>
  `).join('');
}

// ============================================================================
// Save & New Strategy
// ============================================================================

function initSaveButton() {
  const btnSave = document.getElementById('btn-save');
  if (btnSave) {
    btnSave.addEventListener('click', saveStrategy);
  }
}

async function saveStrategy() {
  const strategyName = prompt('请输入策略名称:');
  if (!strategyName) return;

  const config = {
    name: strategyName,
    stock_pool: {
      my: document.getElementById('my-stock-pool')?.value,
      system: document.getElementById('system-stock-pool')?.value
    },
    filters: {
      index_component: document.getElementById('index-component')?.value,
      list_board: document.getElementById('list-board')?.value,
      industry_standard: document.getElementById('industry-standard')?.value,
      primary_industry: document.getElementById('primary-industry')?.value,
      secondary_industry: document.getElementById('secondary-industry')?.value,
      st_stock: document.getElementById('st-stock')?.value,
      exchange: document.getElementById('exchange')?.value,
      region_board: document.getElementById('region-board')?.value,
      enterprise_type: document.getElementById('enterprise-type')?.value,
      margin_trading: document.getElementById('margin-trading')?.value,
      star_market: document.getElementById('star-market')?.value,
      exclude_suspended: document.getElementById('exclude-suspended')?.checked
    },
    conditions: state.conditions,
    trade_conditions: state.tradeConditions,
    backtest: {
      start_date: document.getElementById('backtest-start-date')?.value,
      end_date: document.getElementById('backtest-end-date')?.value,
      benchmark: document.getElementById('benchmark')?.value,
      transaction_cost: document.getElementById('transaction-cost')?.value,
      exclude_period: document.getElementById('exclude-period')?.checked
    }
  };

  try {
    const result = await api.saveStrategy(config);
    console.log('Strategy saved:', result);
    Toast.success(`策略 "${strategyName}" 已保存！`);
  } catch (error) {
    console.error('Save error:', error);
    Toast.error('保存失败：' + (error.message || '未知错误'));
  }
}

function initNewButton() {
  const btnNew = document.getElementById('btn-new');
  if (btnNew) {
    btnNew.addEventListener('click', () => {
      if (confirm('确定要新建策略吗？当前未保存的更改将丢失。')) {
        resetForm();
        Toast.info('已新建空白策略');
      }
    });
  }
}

function resetForm() {
  state.conditions = [];
  state.tradeConditions = [];
  renderConditions();
  renderTradeConditions();

  // Reset all selects
  document.querySelectorAll('select').forEach(select => {
    select.selectedIndex = 0;
  });

  // Reset checkboxes
  document.querySelectorAll('input[type="checkbox"]').forEach(cb => {
    cb.checked = false;
  });

  // Reset dates
  const today = new Date().toISOString().split('T')[0];
  const lastYear = new Date();
  lastYear.setFullYear(lastYear.getFullYear() - 1);

  const startDateInput = document.getElementById('backtest-start-date');
  const endDateInput = document.getElementById('backtest-end-date');

  if (startDateInput) startDateInput.value = lastYear.toISOString().split('T')[0];
  if (endDateInput) endDateInput.value = today;
}

// ============================================================================
// Industry Chain (Cascading Selects)
// ============================================================================

function initIndustryChain() {
  const standardSelect = document.getElementById('industry-standard');
  const primarySelect = document.getElementById('primary-industry');
  const secondarySelect = document.getElementById('secondary-industry');

  if (standardSelect && primarySelect) {
    standardSelect.addEventListener('change', async () => {
      try {
        const industries = await api.getIndustries(standardSelect.value);
        primarySelect.innerHTML = '<option value="all">全部</option>' +
          industries.map(ind => `<option value="${ind.id}">${ind.name}</option>`).join('');
        secondarySelect.innerHTML = '<option value="all">全部</option>';
      } catch (error) {
        console.error('Failed to load industries:', error);
        // Use local fallback data
        const industries = getIndustriesByStandard(standardSelect.value);
        primarySelect.innerHTML = '<option value="all">全部</option>' +
          industries.map(ind => `<option value="${ind.id}">${ind.name}</option>`).join('');
      }
    });
  }

  if (primarySelect && secondarySelect) {
    primarySelect.addEventListener('change', async () => {
      try {
        const industries = await api.getIndustries(standardSelect.value);
        const childIndustries = industries.filter(ind => ind.parent_id === primarySelect.value);
        secondarySelect.innerHTML = '<option value="all">全部</option>' +
          childIndustries.map(ind => `<option value="${ind.id}">${ind.name}</option>`).join('');
      } catch (error) {
        console.error('Failed to load secondary industries:', error);
      }
    });
  }
}

function getIndustriesByStandard(standard) {
  return localIndustries[standard] || [];
}
