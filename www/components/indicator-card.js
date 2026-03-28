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
  // Market Indicators
  market: [
    {
      id: 'price',
      name: '股票价格',
      symbol: 'CLOSE',
      category: 'market',
      description: '当日收盘价，反映股票在当前交易日的最终市场定价。',
      formula: 'CLOSE = 当日最后一笔交易价格',
      range: '无限制，取决于股票基本面和市场情绪',
      unit: '元'
    },
    {
      id: 'turnover_rate',
      name: '换手率',
      symbol: 'TURNOVER',
      category: 'market',
      description: '成交量与流通股本的比率，反映股票流通性和市场活跃度。高换手率通常表示交易活跃。',
      formula: '换手率 = (成交量 / 流通股本) × 100%',
      range: '0% - 50%+, 一般 3%-7% 为活跃',
      unit: '%'
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
      id: 'market_cap',
      name: '总市值',
      symbol: 'CAPITAL',
      category: 'market',
      description: '公司股票的市场总价值，等于股价乘以总股本。',
      formula: '总市值 = 股价 × 总股本',
      range: '从小微企业的几亿到大型企业的万亿',
      unit: '亿元'
    },
    {
      id: 'pe_ratio',
      name: '市盈率 PE',
      symbol: 'PE',
      category: 'market',
      description: '股价与每股收益的比率，衡量股票估值水平。低 PE 可能表示低估，高 PE 可能表示高增长预期。',
      formula: 'PE = 股价 / 每股收益 (EPS)',
      range: '通常 0-50，成长股可更高',
      unit: '倍'
    },
    {
      id: 'price_range',
      name: '股价振幅',
      symbol: 'RANGE',
      category: 'market',
      description: '当日最高价与最低价之间的差额占前一收盘价的百分比，反映价格波动程度。',
      formula: '振幅 = (最高价 - 最低价) / 前收盘 × 100%',
      range: '0% - 20%+, 涨停板限制下通常≤10%',
      unit: '%'
    },
    {
      id: 'price_change',
      name: '股价涨幅',
      symbol: 'CHANGE',
      category: 'market',
      description: '当日收盘价相对前收盘价的涨跌幅度。',
      formula: '涨幅 = (当日收盘 - 前收盘) / 前收盘 × 100%',
      range: '-10% 至 +10% (ST 股±5%，科创板/创业板±20%)',
      unit: '%'
    },
    {
      id: 'net_inflow',
      name: '资金净流入',
      symbol: 'NETFLOW',
      category: 'market',
      description: '当日主力资金净流入金额，反映大资金动向。',
      formula: '净流入 = 主力买入 - 主力卖出',
      range: '负值表示净流出，正值表示净流入',
      unit: '万元'
    },
    {
      id: 'hk_holdings',
      name: '港资持股',
      symbol: 'HK_HOLD',
      category: 'market',
      description: '香港投资者持有的股份比例，反映外资对该股票的偏好。',
      formula: '港资持股 = 港资持股数 / 总股本 × 100%',
      range: '0% - 30%+',
      unit: '%'
    },
    {
      id: 'limit_flag',
      name: '涨跌停标记',
      symbol: 'LIMIT',
      category: 'market',
      description: '标记股票是否达到涨跌停限制。',
      formula: 'LIMIT = 1 if 涨幅>=10% else 0',
      range: '0 (非涨停), 1 (涨停), -1 (跌停)',
      unit: ''
    },
    {
      id: 'list_days',
      name: '上市天数',
      symbol: 'LISTDAYS',
      category: 'market',
      description: '股票自 IPO 以来的交易天数。',
      formula: 'LISTDAYS = 当前日期 - 上市日期',
      range: '0 - 8000+',
      unit: '天'
    }
  ],

  // Technical Indicators
  tech: [
    {
      id: 'ma',
      name: '均线 MA',
      symbol: 'MA(n)',
      category: 'tech',
      description: '移动平均线，将一定时期内的收盘价相加后平均，用以观察价格趋势。常用周期有 5 日、10 日、20 日、60 日等。',
      formula: 'MA(n) = (P₁ + P₂ + ... + Pₙ) / n',
      range: '无限制，跟随价格变动',
      unit: '元'
    },
    {
      id: 'ema',
      name: '指数均线 EMA',
      symbol: 'EMA(n)',
      category: 'tech',
      description: '指数移动平均线，对近期价格赋予更高权重，比简单均线更敏感。',
      formula: 'EMA = 价格 (k) × (2/(n+1)) + EMA(前一日) × (1 - 2/(n+1))',
      range: '无限制，跟随价格变动',
      unit: '元'
    },
    {
      id: 'macd',
      name: 'MACD',
      symbol: 'MACD(12,26,9)',
      category: 'tech',
      description: '平滑异同移动平均线，由快线 (DIF)、慢线 (DEA) 和柱状图组成。金叉 (DIF 上穿 DEA) 为买入信号，死叉为卖出信号。',
      formula: 'DIF = EMA(12) - EMA(26); DEA = EMA(DIF, 9); MACD 柱 = 2 × (DIF - DEA)',
      range: 'DIF/DEA: 无限制; 柱状图：无限制',
      unit: '元'
    },
    {
      id: 'kdj',
      name: 'KDJ 随机指标',
      symbol: 'KDJ(9,3,3)',
      category: 'tech',
      description: '随机指标，由 K 线、D 线、J 线组成。K、D 值在 0-100 之间，J 值可超过此范围。金叉买入，死叉卖出。',
      formula: 'RSV = (C - L₉) / (H₉ - L₉) × 100; K = SMA(RSV, 3); D = SMA(K, 3); J = 3K - 2D',
      range: 'K/D: 0-100; J: 可超出',
      unit: ''
    },
    {
      id: 'rsi',
      name: 'RSI 相对强弱',
      symbol: 'RSI(n)',
      category: 'tech',
      description: '相对强弱指数，衡量价格变动速度和幅度。RSI>70 为超买，RSI<30 为超卖。',
      formula: 'RSI = 100 - 100 / (1 + RS); RS = 平均涨幅 / 平均跌幅',
      range: '0 - 100',
      unit: ''
    },
    {
      id: 'boll',
      name: '布林带 BOLL',
      symbol: 'BOLL(20,2)',
      category: 'tech',
      description: '由上轨、中轨、下轨组成。中轨为 20 日均线，上下轨为中轨±2 倍标准差。价格触及上轨可能回落，触及下轨可能反弹。',
      formula: '中轨 = MA(20); 上轨 = 中轨 + 2×STD(20); 下轨 = 中轨 - 2×STD(20)',
      range: '无限制，跟随价格变动',
      unit: '元'
    },
    {
      id: 'atr',
      name: 'ATR 平均真实波幅',
      symbol: 'ATR(n)',
      category: 'tech',
      description: '衡量价格波动性的指标，数值越大表示波动越剧烈。常用于止损位设置。',
      formula: 'TR = Max(H-L, |H-Cₚ|, |L-Cₚ|); ATR = SMA(TR, n)',
      range: '0 - 无上限',
      unit: '元'
    },
    {
      id: 'adx',
      name: 'ADX 趋势强度',
      symbol: 'ADX(14)',
      category: 'tech',
      description: '平均趋向指标，衡量趋势强弱而非方向。ADX>25 表示强趋势，ADX<20 表示震荡。',
      formula: 'ADX = SMA(|+DI - -DI| / (+DI + -DI), 14) × 100',
      range: '0 - 100',
      unit: ''
    },
    {
      id: 'aroon',
      name: 'Aroon 指标',
      symbol: 'AROON(25)',
      category: 'tech',
      description: '由 Aroon Up 和 Aroon Down 组成，衡量趋势强度和方向。Aroon Up>70 表示上升趋势，Aroon Down>70 表示下降趋势。',
      formula: 'Aroon Up = (25 - 25 日内新高天数) / 25 × 100; Aroon Down = (25 - 25 日内新低天数) / 25 × 100',
      range: '0 - 100',
      unit: ''
    },
    {
      id: 'cci',
      name: 'CCI 顺势指标',
      symbol: 'CCI(20)',
      category: 'tech',
      description: '衡量价格与统计平均值的偏离程度。CCI>100 为超买，CCI<-100 为超卖。',
      formula: 'CCI = (TP - SMA(TP, n)) / (0.015 × MAD)',
      range: '-∞ to +∞, 通常 -200 到 +200',
      unit: ''
    },
    {
      id: 'williams_r',
      name: 'Williams %R',
      symbol: 'W%R(14)',
      category: 'tech',
      description: '威廉指标，衡量收盘价在近期价格区间中的位置。<-80 为超卖，>-20 为超买。',
      formula: 'W%R = (Hₙ - C) / (Hₙ - Lₙ) × -100',
      range: '-100 - 0',
      unit: ''
    },
    {
      id: 'vwap',
      name: 'VWAP 成交量加权平均价',
      symbol: 'VWAP',
      category: 'tech',
      description: '成交量加权平均价格，反映机构平均持仓成本。价格高于 VWAP 表示 bullish，低于表示 bearish。',
      formula: 'VWAP = Σ(价格 × 成交量) / Σ(成交量)',
      range: '无限制，跟随价格变动',
      unit: '元'
    },
    {
      id: 'obv',
      name: 'OBV 能量潮',
      symbol: 'OBV',
      category: 'tech',
      description: '累积成交量指标，将成交量与价格变化结合。价格上涨日成交量为正，下跌日为负。',
      formula: 'OBV = 前 OBV + VOL (if C>Cₚ) else 前 OBV - VOL (if C<Cₚ)',
      range: '无限制',
      unit: '手'
    }
  ],

  // Financial Indicators
  finance: [
    {
      id: 'pe',
      name: '市盈率 PE',
      symbol: 'PE(TTM)',
      category: 'finance',
      description: '股价与每股收益的比率，衡量估值水平。PE 越低表示回本年限越短，但成长股 PE 通常较高。',
      formula: 'PE = 股价 / 每股收益 (EPS)',
      range: '0 - 100+, 价值股通常<20, 成长股>30',
      unit: '倍'
    },
    {
      id: 'pb',
      name: '市净率 PB',
      symbol: 'PB',
      category: 'finance',
      description: '股价与每股净资产的比率，衡量相对于账面价值的溢价程度。PB<1 可能表示低估。',
      formula: 'PB = 股价 / 每股净资产',
      range: '0 - 20+, 银行股通常<1.5',
      unit: '倍'
    },
    {
      id: 'ps',
      name: '市销率 PS',
      symbol: 'PS(TTM)',
      category: 'finance',
      description: '市值与营业收入的比率，适用于未盈利或周期性企业。',
      formula: 'PS = 总市值 / 营业收入',
      range: '0 - 50+, SaaS 企业通常>10',
      unit: '倍'
    },
    {
      id: 'roe',
      name: '净资产收益率 ROE',
      symbol: 'ROE',
      category: 'finance',
      description: '净利润与净资产的比率，衡量股东权益的回报率。ROE>15% 通常表示优秀的盈利能力。',
      formula: 'ROE = 净利润 / 净资产 × 100%',
      range: '-100% - 50%+, 优秀企业>15%',
      unit: '%'
    },
    {
      id: 'roa',
      name: '总资产收益率 ROA',
      symbol: 'ROA',
      category: 'finance',
      description: '净利润与总资产的比率，衡量资产使用效率。',
      formula: 'ROA = 净利润 / 总资产 × 100%',
      range: '-50% - 30%+, 优秀企业>5%',
      unit: '%'
    },
    {
      id: 'debt_ratio',
      name: '资产负债率',
      symbol: 'DEBT_RATIO',
      category: 'finance',
      description: '总负债与总资产的比率，衡量财务杠杆和风险水平。过高表示财务风险大。',
      formula: '资产负债率 = 总负债 / 总资产 × 100%',
      range: '0% - 100%, 通常 40%-60% 合理',
      unit: '%'
    },
    {
      id: 'gross_margin',
      name: '毛利率',
      symbol: 'GROSS_MARGIN',
      category: 'finance',
      description: '毛利与营业收入的比率，衡量产品或服务的盈利能力。',
      formula: '毛利率 = (营业收入 - 营业成本) / 营业收入 × 100%',
      range: '0% - 90%+, 软件企业通常>70%',
      unit: '%'
    },
    {
      id: 'net_margin',
      name: '净利率',
      symbol: 'NET_MARGIN',
      category: 'finance',
      description: '净利润与营业收入的比率，反映企业最终盈利能力。',
      formula: '净利率 = 净利润 / 营业收入 × 100%',
      range: '-50% - 50%+, 优秀企业>10%',
      unit: '%'
    },
    {
      id: 'current_ratio',
      name: '流动比率',
      symbol: 'CURRENT_RATIO',
      category: 'finance',
      description: '流动资产与流动负债的比率，衡量短期偿债能力。',
      formula: '流动比率 = 流动资产 / 流动负债',
      range: '0 - 5+, 通常>1.5 较安全',
      unit: '倍'
    },
    {
      id: 'revenue_growth',
      name: '营收增长率',
      symbol: 'REV_GROWTH',
      category: 'finance',
      description: '营业收入同比增长率，衡量业务扩张速度。',
      formula: '营收增长率 = (本期营收 - 同期营收) / 同期营收 × 100%',
      range: '-100% - 500%+',
      unit: '%'
    },
    {
      id: 'profit_growth',
      name: '利润增长率',
      symbol: 'PROFIT_GROWTH',
      category: 'finance',
      description: '净利润同比增长率，衡量盈利增长速度。',
      formula: '利润增长率 = (本期利润 - 同期利润) / 同期利润 × 100%',
      range: '-100% - 1000%+',
      unit: '%'
    }
  ]
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
  container.addEventListener('click', (e) => {
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
