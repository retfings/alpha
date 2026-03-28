/**
 * Trading Models Selection Page
 *
 * Allows users to:
 * - Browse available trading models
 * - Configure model parameters
 * - Link to stock screens
 * - Save trading strategies
 */

// Application state
const state = {
  selectedModel: null,
  models: [],
  screens: [],
  config: {},
  isSaving: false,
};

// Trading model definitions
const tradingModels = [
  {
    id: 'periodic_rebalance',
    name: 'Periodic Rebalancing',
    type: 'rebalancing',
    description: 'Automatically rebalance your portfolio at fixed intervals (weekly, monthly, quarterly). Maintains target allocation by selling overweight positions and buying underweight ones.',
    defaultParams: {
      frequency: 'monthly',
      rebalanceDay: 1,
      maxPositions: 10,
      threshold: 5,
      skipHolidays: true,
    },
  },
  {
    id: 'conditional_trigger',
    name: 'Conditional Trigger',
    type: 'conditional',
    description: 'Execute trades when specific market conditions are met. Set up custom triggers based on technical indicators, price levels, or other market signals.',
    defaultParams: {
      conditions: [],
      requireAll: true,
      minStrength: 50,
      cooldownDays: 5,
      maxPositions: 10,
    },
  },
  {
    id: 'mean_reversion',
    name: 'Mean Reversion',
    type: 'strategy',
    description: 'Buy oversold stocks and sell overbought ones. Based on the principle that prices tend to revert to their historical average over time.',
    defaultParams: {
      indicator: 'rsi_14',
      oversoldThreshold: 30,
      overboughtThreshold: 70,
      exitThreshold: 50,
    },
  },
  {
    id: 'momentum_follow',
    name: 'Momentum Following',
    type: 'strategy',
    description: 'Follow the trend by buying stocks with strong upward momentum and exiting when momentum weakens. "The trend is your friend."',
    defaultParams: {
      lookbackPeriod: 20,
      momentumThreshold: 5,
      exitOnReversal: true,
    },
  },
];

// Initialize page
document.addEventListener('DOMContentLoaded', () => {
  initializeModels();
  setupEventListeners();
  loadSavedScreens();
});

// Initialize model cards
function initializeModels() {
  const container = document.getElementById('model-cards-container');
  if (!container) return;

  state.models = tradingModels;

  container.innerHTML = tradingModels.map(model => `
    <div class="model-card" data-model-id="${model.id}" data-type="${model.type}">
      <div class="model-card-header">
        <h3 class="model-card-name">${model.name}</h3>
        <span class="model-card-type">${model.type}</span>
      </div>
      <p class="model-card-description">${model.description}</p>
      <div class="model-card-params">
        <strong>Default:</strong> ${formatDefaultParams(model.defaultParams)}
      </div>
    </div>
  `).join('');

  // Add click handlers
  container.querySelectorAll('.model-card').forEach(card => {
    card.addEventListener('click', () => selectModel(card.dataset.modelId));
  });
}

// Format default parameters for display
function formatDefaultParams(params) {
  const entries = Object.entries(params).slice(0, 3);
  return entries.map(([k, v]) => `${k}: ${v}`).join(', ');
}

// Select a trading model
function selectModel(modelId) {
  const model = state.models.find(m => m.id === modelId);
  if (!model) return;

  state.selectedModel = model;
  state.config = { ...model.defaultParams };

  // Update UI selection
  document.querySelectorAll('.model-card').forEach(card => {
    card.classList.toggle('selected', card.dataset.modelId === modelId);
  });

  // Show model info
  showModelInfo(model);

  // Show config form
  showConfigForm(model);

  // Show screen selection
  document.getElementById('screen-selection-section').style.display = 'block';

  // Update summary
  updateSummary();
}

// Show model info section
function showModelInfo(model) {
  const section = document.getElementById('model-info-section');
  const nameEl = document.getElementById('selected-model-name');
  const typeEl = document.getElementById('selected-model-type');
  const descEl = document.getElementById('selected-model-description');

  if (!section) return;

  section.style.display = 'block';
  nameEl.textContent = model.name;
  typeEl.textContent = model.type;
  descEl.textContent = model.description;
}

// Show configuration form
function showConfigForm(model) {
  // Hide all forms first
  document.querySelectorAll('.config-form').forEach(form => {
    form.style.display = 'none';
  });
  document.getElementById('config-empty').style.display = 'none';

  // Show appropriate form
  const formId = `${model.id}-form`;
  const form = document.getElementById(formId);

  if (form) {
    form.style.display = 'flex';
    initializeFormValues(model);
  } else {
    // No specific form - show empty state
    document.getElementById('config-empty').style.display = 'flex';
    document.getElementById('config-empty').querySelector('.empty-text').textContent =
      `Configuration for ${model.name} coming soon`;
  }
}

// Initialize form values from model defaults
function initializeFormValues(model) {
  const form = document.getElementById(`${model.id}-form`);
  if (!form) return;

  const params = model.defaultParams;

  // Periodic rebalancing form
  if (model.id === 'periodic_rebalance') {
    setFieldValue('rebalance-frequency', params.frequency);
    setFieldValue('rebalance-day', params.rebalanceDay);
    setFieldValue('max-positions', params.maxPositions);
    setFieldValue('rebalance-threshold', params.threshold);
    setFieldValue('skip-holidays', params.skipHolidays);
  }

  // Conditional trigger form
  if (model.id === 'conditional_trigger') {
    setFieldValue('require-all', params.requireAll.toString());
    setFieldValue('min-strength', params.minStrength);
    setFieldValue('cooldown-days', params.cooldownDays);
    setFieldValue('trigger-max-positions', params.maxPositions);
  }
}

// Set field value helper
function setFieldValue(id, value) {
  const el = document.getElementById(id);
  if (!el) return;

  if (el.type === 'checkbox') {
    el.checked = value;
  } else {
    el.value = value;
  }
}

// Load saved screens
async function loadSavedScreens() {
  // Mock screens for now
  state.screens = [
    { id: 'screen_1', name: 'Value Stocks Screen' },
    { id: 'screen_2', name: 'Growth Stocks Screen' },
    { id: 'screen_3', name: 'Dividend Aristocrats' },
    { id: 'screen_4', name: 'Low PE Ratio' },
  ];

  const select = document.getElementById('screen-select');
  if (!select) return;

  select.innerHTML = `
    <option value="">-- Select a saved screen --</option>
    ${state.screens.map(s => `<option value="${s.id}">${s.name}</option>`).join('')}
  `;
}

// Update strategy summary
function updateSummary() {
  const section = document.getElementById('summary-content');
  const actions = document.getElementById('summary-actions');
  const empty = document.getElementById('summary-empty');

  if (!section || !state.selectedModel) return;

  empty.style.display = 'none';
  actions.style.display = 'flex';

  const model = state.selectedModel;
  const screenSelect = document.getElementById('screen-select');
  const selectedScreen = state.screens.find(s => s.id === screenSelect?.value);

  section.innerHTML = `
    <div class="summary-item">
      <div class="summary-item-label">Model</div>
      <div class="summary-item-value">${model.name}</div>
    </div>
    <div class="summary-item">
      <div class="summary-item-label">Type</div>
      <div class="summary-item-value">${model.type}</div>
    </div>
    <div class="summary-item">
      <div class="summary-item-label">Selected Screen</div>
      <div class="summary-item-value">${selectedScreen?.name || 'Not selected'}</div>
    </div>
    <div class="summary-stats">
      <div class="summary-stat">
        <div class="summary-stat-value">${model.defaultParams.maxPositions || 10}</div>
        <div class="summary-stat-label">Max Positions</div>
      </div>
      <div class="summary-stat">
        <div class="summary-stat-value">${getFrequencyLabel(model.defaultParams.frequency) || 'N/A'}</div>
        <div class="summary-stat-label">Frequency</div>
      </div>
    </div>
  `;
}

// Get frequency label
function getFrequencyLabel(freq) {
  const labels = {
    weekly: 'Weekly',
    biweekly: 'Bi-weekly',
    monthly: 'Monthly',
    quarterly: 'Quarterly',
  };
  return labels[freq] || freq;
}

// Set up event listeners
function setupEventListeners() {
  // Screen select change
  const screenSelect = document.getElementById('screen-select');
  if (screenSelect) {
    screenSelect.addEventListener('change', updateSummary);
  }

  // New screen button
  const btnNewScreen = document.getElementById('btn-new-screen');
  if (btnNewScreen) {
    btnNewScreen.addEventListener('click', () => {
      window.location.href = 'screener.html';
    });
  }

  // Save model button
  const btnSaveModel = document.getElementById('btn-save-model');
  if (btnSaveModel) {
    btnSaveModel.addEventListener('click', saveStrategy);
  }

  // Backtest button
  const btnBacktest = document.getElementById('btn-backtest');
  if (btnBacktest) {
    btnBacktest.addEventListener('click', () => {
      showToast('Backtest feature coming soon', 'info');
    });
  }

  // Simulate button
  const btnSimulate = document.getElementById('btn-simulate');
  if (btnSimulate) {
    btnSimulate.addEventListener('click', () => {
      showToast('Paper trading feature coming soon', 'info');
    });
  }

  // Add condition button (conditional trigger)
  const btnAddCondition = document.getElementById('btn-add-trigger-condition');
  if (btnAddCondition) {
    btnAddCondition.addEventListener('click', addTriggerCondition);
  }

  // Form change listeners
  setupFormListeners();

  // Navigation
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', handleNavigation);
  });
}

// Set up form change listeners
function setupFormListeners() {
  // Periodic rebalancing form
  const periodicForm = document.getElementById('periodic-rebalance-form');
  if (periodicForm) {
    periodicForm.addEventListener('change', (e) => {
      updateConfigFromForm('periodic_rebalance', periodicForm);
      updateSummary();
    });
  }

  // Conditional trigger form
  const conditionalForm = document.getElementById('conditional-trigger-form');
  if (conditionalForm) {
    conditionalForm.addEventListener('change', (e) => {
      updateConfigFromForm('conditional_trigger', conditionalForm);
      updateSummary();
    });
  }
}

// Update config from form
function updateConfigFromForm(modelId, form) {
  const formData = new FormData(form);
  const config = {};

  for (const [key, value] of formData.entries()) {
    if (value === 'true' || value === 'false') {
      config[key] = value === 'true';
    } else if (!isNaN(value) && value !== '') {
      config[key] = parseFloat(value);
    } else {
      config[key] = value;
    }
  }

  state.config = { ...state.config, ...config };
}

// Add trigger condition
function addTriggerCondition() {
  const list = document.getElementById('conditions-list');
  if (!list) return;

  const conditionId = `cond_${Date.now()}`;
  const conditionEl = document.createElement('div');
  conditionEl.className = 'condition-item';
  conditionEl.dataset.conditionId = conditionId;
  conditionEl.innerHTML = `
    <select class="condition-indicator">
      <option value="rsi_14">RSI (14)</option>
      <option value="macd">MACD</option>
      <option value="ma_cross">MA Cross</option>
      <option value="volume_ratio">Volume Ratio</option>
    </select>
    <select class="condition-operator">
      <option value="gte">>=</option>
      <option value="gt">&gt;</option>
      <option value="lte">&lt;=</option>
      <option value="lt">&lt;</option>
      <option value="eq">=</option>
    </select>
    <input type="number" class="condition-value" placeholder="Value" step="0.01">
    <button type="button" class="btn-remove-condition" data-condition-id="${conditionId}">&times;</button>
  `;

  list.appendChild(conditionEl);

  // Add remove handler
  conditionEl.querySelector('.btn-remove-condition').addEventListener('click', () => {
    conditionEl.remove();
  });
}

// Save strategy
async function saveStrategy() {
  if (!state.selectedModel) {
    showToast('Please select a model first', 'warning');
    return;
  }

  const screenSelect = document.getElementById('screen-select');
  if (!screenSelect?.value) {
    showToast('Please select a stock screen', 'warning');
    return;
  }

  showLoading(true);

  try {
    const strategy = {
      name: `${state.selectedModel.name} Strategy`,
      model_id: state.selectedModel.id,
      parameters: state.config,
      screen_id: screenSelect.value,
    };

    // Mock save - replace with actual API call
    await new Promise(resolve => setTimeout(resolve, 1000));

    const strategyId = `strategy_${Date.now()}`;
    localStorage.setItem(`strategy_${strategyId}`, JSON.stringify(strategy));

    showToast('Strategy saved successfully!', 'success');

    // Redirect to strategies page or show confirmation
    setTimeout(() => {
      showLoading(false);
    }, 500);

  } catch (error) {
    console.error('Save error:', error);
    showToast('Failed to save strategy', 'error');
    showLoading(false);
  }
}

// Show/hide loading overlay
function showLoading(show) {
  state.isSaving = show;
  const overlay = document.getElementById('loading-overlay');
  if (overlay) {
    overlay.style.display = show ? 'flex' : 'none';
  }
}

// Handle navigation
function handleNavigation(e) {
  const link = e.target.dataset.link;
  if (!link || link === '#') return;

  if (link === 'trading-models.html') {
    return; // Already on this page
  }

  window.location.href = link;
}

// Show toast notification
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `<span class="toast-message">${message}</span>`;
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
