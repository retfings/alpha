/**
 * Results Display Component
 *
 * Provides sortable, paginated results display for stock screening:
 * - Sortable columns
 * - Pagination
 * - Export options
 * - Chart visualization
 */

// ============================================================================
// Results Table Component
// ============================================================================

/**
 * Create a sortable results table
 * @param {Object} options - Table configuration
 * @returns {HTMLElement} Table element
 */
export function createResultsTable(options = {}) {
  const {
    columns = [],
    data = [],
    sortable = true,
    paginated = true,
    pageSize = 20
  } = options;

  const container = document.createElement('div');
  container.className = 'results-display-container';

  container.innerHTML = `
    <div class="results-toolbar">
      <div class="results-info">
        <span class="results-count">共 <strong>${data.length}</strong> 条结果</span>
      </div>
      <div class="results-actions">
        <button class="btn-action btn-export-csv" title="导出 CSV">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
            <polyline points="7 10 12 15 17 10"></polyline>
            <line x1="12" y1="15" x2="12" y2="3"></line>
          </svg>
          CSV
        </button>
        <button class="btn-action btn-export-excel" title="导出 Excel">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="16" y1="13" x2="8" y2="13"></line>
            <line x1="16" y1="17" x2="8" y2="17"></line>
            <polyline points="10 9 9 9 8 9"></polyline>
          </svg>
          Excel
        </button>
        <button class="btn-action btn-print" title="打印">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="6 9 6 2 18 2 18 9"></polyline>
            <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
            <rect x="6" y="14" width="12" height="8"></rect>
          </svg>
        </button>
      </div>
    </div>
    <div class="table-wrapper">
      <table class="results-table">
        <thead>
          <tr class="table-header-row"></tr>
        </thead>
        <tbody class="table-body"></tbody>
      </table>
    </div>
    ${paginated ? `
      <div class="results-pagination">
        <div class="pagination-info">
          第 <span class="current-page">1</span> 页，共 <span class="total-pages">1</span> 页
        </div>
        <div class="pagination-controls">
          <button class="btn-page btn-first" title="首页">◄◄</button>
          <button class="btn-page btn-prev" title="上一页">◄</button>
          <input type="number" class="page-input" min="1" value="1">
          <button class="btn-page btn-next" title="下一页">►</button>
          <button class="btn-page btn-last" title="末页">►►</button>
        </div>
        <div class="page-size-selector">
          每页
          <select class="page-size-select">
            <option value="10">10</option>
            <option value="20" selected>20</option>
            <option value="50">50</option>
            <option value="100">100</option>
          </select>
          条
        </div>
      </div>
    ` : ''}
  `;

  const table = container.querySelector('.results-table');
  const headerRow = table.querySelector('.table-header-row');

  // Render headers
  columns.forEach((col, index) => {
    const th = document.createElement('th');
    th.className = `column-${col.key}${col.align ? ` align-${col.align}` : ''}`;
    if (col.width) th.style.width = col.width;

    const content = document.createElement('span');
    content.className = 'column-title';
    content.textContent = col.title;

    th.appendChild(content);

    if (sortable && col.sortable !== false) {
      th.classList.add('sortable');
      th.dataset.sortKey = col.sortKey || col.key;

      const sortIcon = document.createElement('span');
      sortIcon.className = 'sort-icon';
      sortIcon.innerHTML = '⇅';
      th.appendChild(sortIcon);

      th.addEventListener('click', () => {
        handleSort(container, col.sortKey || col.key, col.sortFn);
      });
    }

    headerRow.appendChild(th);
  });

  // Store table state
  container.dataset.currentPage = '1';
  container.dataset.pageSize = String(pageSize);
  container.dataset.sortField = '';
  container.dataset.sortDirection = 'none';

  // Store full data
  container._fullData = data;
  container._columns = columns;

  // Render initial page
  renderTablePage(container);

  if (paginated) {
    setupPaginationHandlers(container);
  }

  // Setup export handlers
  setupExportHandlers(container);

  return container;
}

/**
 * Handle column sorting
 * @param {HTMLElement} container - Table container
 * @param {string} field - Sort field
 * @param {Function} customSortFn - Custom sort function
 */
function handleSort(container, field, customSortFn) {
  const currentField = container.dataset.sortField;
  const currentDirection = container.dataset.sortDirection;

  let newDirection = 'asc';
  if (currentField === field) {
    if (currentDirection === 'asc') {
      newDirection = 'desc';
    } else if (currentDirection === 'desc') {
      newDirection = 'none';
    }
  }

  container.dataset.sortField = field;
  container.dataset.sortDirection = newDirection;

  // Update sort icons
  container.querySelectorAll('.sort-icon').forEach(icon => {
    icon.textContent = '⇅';
    icon.style.color = '';
  });

  const activeHeader = container.querySelector(`[data-sort-key="${field}"] .sort-icon`);
  if (activeHeader) {
    activeHeader.textContent = newDirection === 'asc' ? '↑' : newDirection === 'desc' ? '↓' : '⇅';
    activeHeader.style.color = newDirection !== 'none' ? '#1890ff' : '';
  }

  // Sort data
  let sortedData = [...container._fullData];

  if (newDirection !== 'none') {
    if (customSortFn) {
      sortedData.sort((a, b) => customSortFn(a, b, newDirection));
    } else {
      sortedData.sort((a, b) => {
        const aVal = a[field];
        const bVal = b[field];

        if (typeof aVal === 'number' && typeof bVal === 'number') {
          return newDirection === 'asc' ? aVal - bVal : bVal - aVal;
        }

        const comparison = String(aVal).localeCompare(String(bVal), 'zh-CN');
        return newDirection === 'asc' ? comparison : -comparison;
      });
    }
  }

  container._currentData = sortedData;
  container.dataset.currentPage = '1';
  renderTablePage(container);
}

/**
 * Render table page
 * @param {HTMLElement} container - Table container
 */
function renderTablePage(container) {
  const currentPage = parseInt(container.dataset.currentPage, 10);
  const pageSize = parseInt(container.dataset.pageSize, 10);
  const data = container._currentData || container._fullData;

  const startIndex = (currentPage - 1) * pageSize;
  const endIndex = startIndex + pageSize;
  const pageData = data.slice(startIndex, endIndex);

  const tbody = container.querySelector('.table-body');
  tbody.innerHTML = '';

  pageData.forEach((row, index) => {
    const tr = document.createElement('tr');
    tr.className = index % 2 === 0 ? 'table-row-even' : 'table-row-odd';

    container._columns.forEach(col => {
      const td = document.createElement('td');
      td.className = `column-${col.key}${col.align ? ` align-${col.align}` : ''}`;

      if (col.render) {
        td.innerHTML = col.render(row[col.key], row, index);
      } else {
        td.textContent = row[col.key] ?? '';
      }

      tr.appendChild(td);
    });

    tbody.appendChild(tr);
  });

  // Update pagination
  updatePagination(container, data.length);
}

/**
 * Update pagination display
 * @param {HTMLElement} container - Table container
 * @param {number} totalItems - Total number of items
 */
function updatePagination(container, totalItems) {
  const pageSize = parseInt(container.dataset.pageSize, 10);
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const currentPage = parseInt(container.dataset.currentPage, 10);

  const currentPageEl = container.querySelector('.current-page');
  const totalPagesEl = container.querySelector('.total-pages');
  const pageInput = container.querySelector('.page-input');

  if (currentPageEl) currentPageEl.textContent = currentPage;
  if (totalPagesEl) totalPagesEl.textContent = totalPages;
  if (pageInput) {
    pageInput.max = totalPages;
    pageInput.value = currentPage;
  }

  // Update button states
  container.querySelector('.btn-first').disabled = currentPage === 1;
  container.querySelector('.btn-prev').disabled = currentPage === 1;
  container.querySelector('.btn-next').disabled = currentPage === totalPages;
  container.querySelector('.btn-last').disabled = currentPage === totalPages;
}

/**
 * Setup pagination handlers
 * @param {HTMLElement} container - Table container
 */
function setupPaginationHandlers(container) {
  container.querySelector('.btn-first')?.addEventListener('click', () => {
    container.dataset.currentPage = '1';
    renderTablePage(container);
  });

  container.querySelector('.btn-prev')?.addEventListener('click', () => {
    const currentPage = parseInt(container.dataset.currentPage, 10);
    if (currentPage > 1) {
      container.dataset.currentPage = String(currentPage - 1);
      renderTablePage(container);
    }
  });

  container.querySelector('.btn-next')?.addEventListener('click', () => {
    const currentPage = parseInt(container.dataset.currentPage, 10);
    const pageSize = parseInt(container.dataset.pageSize, 10);
    const totalPages = Math.ceil((container._currentData?.length || container._fullData.length) / pageSize);

    if (currentPage < totalPages) {
      container.dataset.currentPage = String(currentPage + 1);
      renderTablePage(container);
    }
  });

  container.querySelector('.btn-last')?.addEventListener('click', () => {
    const pageSize = parseInt(container.dataset.pageSize, 10);
    const totalPages = Math.ceil((container._currentData?.length || container._fullData.length) / pageSize);
    container.dataset.currentPage = String(totalPages);
    renderTablePage(container);
  });

  container.querySelector('.page-input')?.addEventListener('change', (e) => {
    const page = parseInt(e.target.value, 10);
    const pageSize = parseInt(container.dataset.pageSize, 10);
    const totalPages = Math.ceil((container._currentData?.length || container._fullData.length) / pageSize);

    if (page >= 1 && page <= totalPages) {
      container.dataset.currentPage = String(page);
      renderTablePage(container);
    } else {
      e.target.value = container.dataset.currentPage;
    }
  });

  container.querySelector('.page-size-select')?.addEventListener('change', (e) => {
    container.dataset.pageSize = e.target.value;
    container.dataset.currentPage = '1';
    renderTablePage(container);
  });
}

/**
 * Setup export handlers
 * @param {HTMLElement} container - Table container
 */
function setupExportHandlers(container) {
  container.querySelector('.btn-export-csv')?.addEventListener('click', () => {
    exportToCSV(container);
  });

  container.querySelector('.btn-export-excel')?.addEventListener('click', () => {
    exportToExcel(container);
  });

  container.querySelector('.btn-print')?.addEventListener('click', () => {
    window.print();
  });
}

/**
 * Export table to CSV
 * @param {HTMLElement} container - Table container
 */
function exportToCSV(container) {
  const data = container._currentData || container._fullData;
  const columns = container._columns;

  const headers = columns.map(col => col.title);
  const rows = data.map(row =>
    columns.map(col => {
      const value = row[col.key];
      return typeof value === 'string' && value.includes(',') ? `"${value}"` : value;
    })
  );

  const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `筛选结果_${new Date().toISOString().split('T')[0]}.csv`;
  link.click();
}

/**
 * Export table to Excel (simple XLS format)
 * @param {HTMLElement} container - Table container
 */
function exportToExcel(container) {
  const data = container._currentData || container._fullData;
  const columns = container._columns;

  let html = '<table><thead><tr>';
  columns.forEach(col => {
    html += `<th>${col.title}</th>`;
  });
  html += '</tr></thead><tbody>';

  data.forEach(row => {
    html += '<tr>';
    columns.forEach(col => {
      html += `<td>${row[col.key] ?? ''}</td>`;
    });
    html += '</tr>';
  });

  html += '</tbody></table>';

  const blob = new Blob(['\ufeff' + html], { type: 'application/vnd.ms-excel' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `筛选结果_${new Date().toISOString().split('T')[0]}.xls`;
  link.click();
}

// ============================================================================
// Score Distribution Chart
// ============================================================================

/**
 * Create score distribution chart
 * @param {Array} data - Data with scores
 * @param {string} containerId - Container element ID
 * @returns {Object} Chart instance
 */
export function createScoreDistributionChart(data, containerId) {
  const ctx = document.getElementById(containerId);
  if (!ctx) return null;

  // Create histogram bins
  const bins = {};
  for (let i = 0; i <= 10; i++) {
    bins[i * 10] = 0;
  }

  data.forEach(item => {
    const score = parseFloat(item.score) || 0;
    const bin = Math.floor(score / 10) * 10;
    if (bins[bin] !== undefined) {
      bins[bin]++;
    }
  });

  const labels = Object.keys(bins).map(k => `${k}-${parseInt(k) + 9}`);
  const values = Object.values(bins);

  return new Chart(ctx, {
    type: 'bar',
    data: {
      labels: labels,
      datasets: [{
        label: '股票数量',
        data: values,
        backgroundColor: 'rgba(24, 144, 255, 0.6)',
        borderColor: 'rgba(24, 144, 255, 1)',
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          callbacks: {
            title: (items) => `得分区间：${items[0].label}`,
            label: (item) => `股票数量：${item.raw}`
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0
          }
        }
      }
    }
  });
}

// ============================================================================
// Results Summary Cards
// ============================================================================

/**
 * Create results summary cards
 * @param {Object} stats - Statistics object
 * @returns {HTMLElement} Cards container
 */
export function createSummaryCards(stats) {
  const container = document.createElement('div');
  container.className = 'results-summary-cards';

  const cardDefs = [
    { key: 'totalCount', label: '总数量', icon: '📊' },
    { key: 'avgScore', label: '平均得分', icon: '🎯', formatter: v => v?.toFixed(1) },
    { key: 'maxScore', label: '最高得分', icon: '🏆', formatter: v => v?.toFixed(1) },
    { key: 'minScore', label: '最低得分', icon: '📉', formatter: v => v?.toFixed(1) },
    { key: 'avgPE', label: '平均 PE', icon: '💰', formatter: v => v?.toFixed(2) },
    { key: 'avgROE', label: '平均 ROE', icon: '📈', formatter: v => v?.toFixed(1) + '%' }
  ];

  cardDefs.forEach(def => {
    const card = document.createElement('div');
    card.className = 'summary-card';

    const value = stats[def.key];
    const displayValue = def.formatter ? def.formatter(value) : (value ?? '--');

    card.innerHTML = `
      <div class="card-icon">${def.icon}</div>
      <div class="card-content">
        <div class="card-label">${def.label}</div>
        <div class="card-value">${displayValue}</div>
      </div>
    `;

    container.appendChild(card);
  });

  return container;
}

/**
 * Calculate statistics from results data
 * @param {Array} data - Results data
 * @returns {Object} Statistics
 */
export function calculateStats(data) {
  if (!data || data.length === 0) {
    return {
      totalCount: 0,
      avgScore: 0,
      maxScore: 0,
      minScore: 0,
      avgPE: 0,
      avgROE: 0
    };
  }

  const scores = data.map(d => parseFloat(d.score) || 0);
  const pes = data.map(d => parseFloat(d.indicators?.pe) || 0).filter(v => v > 0);
  const roes = data.map(d => parseFloat(d.indicators?.roe) || 0);

  return {
    totalCount: data.length,
    avgScore: scores.reduce((a, b) => a + b, 0) / scores.length,
    maxScore: Math.max(...scores),
    minScore: Math.min(...scores),
    avgPE: pes.length > 0 ? pes.reduce((a, b) => a + b, 0) / pes.length : 0,
    avgROE: roes.reduce((a, b) => a + b, 0) / roes.length
  };
}

// ============================================================================
// Column Definitions
// ============================================================================

/**
 * Get default column definitions for stock results
 * @returns {Array} Column definitions
 */
export function getDefaultStockColumns() {
  return [
    {
      key: 'rank',
      title: '排名',
      width: '60px',
      align: 'center',
      sortable: false,
      render: (val, row, idx) => {
        if (idx === 0) return '<span style="color: #faad14">🥇</span>';
        if (idx === 1) return '<span style="color: #bfbfbf">🥈</span>';
        if (idx === 2) return '<span style="color: #d48806">🥉</span>';
        return String(idx + 1);
      }
    },
    {
      key: 'code',
      title: '代码',
      width: '100px',
      sortable: true
    },
    {
      key: 'name',
      title: '名称',
      width: '120px',
      sortable: true
    },
    {
      key: 'score',
      title: '综合得分',
      width: '100px',
      align: 'right',
      sortable: true,
      render: (val) => `<span class="score-value">${parseFloat(val).toFixed(1)}</span>`
    },
    {
      key: 'pe',
      title: 'PE',
      width: '70px',
      align: 'right',
      sortable: true,
      render: (val) => `<span class="indicator-value">${val ?? '--'}</span>`
    },
    {
      key: 'pb',
      title: 'PB',
      width: '70px',
      align: 'right',
      sortable: true,
      render: (val) => `<span class="indicator-value">${val ?? '--'}</span>`
    },
    {
      key: 'roe',
      title: 'ROE',
      width: '80px',
      align: 'right',
      sortable: true,
      render: (val) => `<span class="indicator-value">${val ?? '--'}%</span>`
    },
    {
      key: 'actions',
      title: '操作',
      width: '100px',
      align: 'center',
      sortable: false,
      render: (val, row) => `
        <button class="btn-view-detail" data-code="${row.code}">详情</button>
      `
    }
  ];
}
