/**
 * API Service Module
 *
 * Provides functions for interacting with the Quantitative Drawdown Framework API.
 * All API calls return Promises and include error handling.
 */

const API_BASE = '/api';

/**
 * API response handler with error processing
 */
async function handleResponse(response) {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Request failed' }));
    throw new Error(error.error || `HTTP ${response.status}`);
  }
  return response.json();
}

/**
 * Fetch with timeout and error handling
 */
async function apiFetch(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const config = {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    }
  };

  try {
    const response = await fetch(url, config);
    return await handleResponse(response);
  } catch (error) {
    console.error(`API Error [${endpoint}]:`, error.message);
    throw error;
  }
}

// ============================================================================
// Stock API
// ============================================================================

/**
 * Get list of available stocks
 * @returns {Promise<string[]>} Array of stock codes
 */
export async function getStocks() {
  return apiFetch('/stocks');
}

/**
 * Get stock information
 * @param {string} code - Stock code (e.g., "sh.600000")
 * @returns {Promise<{code: string, name: string, exchange: string}>}
 */
export async function getStockInfo(code) {
  return apiFetch(`/stocks/${code}`);
}

/**
 * Get K-line data for a stock
 * @param {string} code - Stock code
 * @param {string} start - Start date (YYYY-MM-DD)
 * @param {string} end - End date (YYYY-MM-DD)
 * @returns {Promise<{stock_code: string, klines: Array}>}
 */
export async function getKlines(code, start, end) {
  const params = new URLSearchParams();
  if (start) params.append('start', start);
  if (end) params.append('end', end);
  return apiFetch(`/stocks/${code}/klines?${params}`);
}

// ============================================================================
// Strategy API
// ============================================================================

/**
 * Get list of available strategies
 * @returns {Promise<Array<{name: string, description: string}>>}
 */
export async function getStrategies() {
  return apiFetch('/strategies');
}

// ============================================================================
// Backtest API
// ============================================================================

/**
 * Run a backtest
 * @param {Object} config - Backtest configuration
 * @param {string} config.stock_code - Stock code
 * @param {string} config.strategy - Strategy name
 * @param {string} config.start_date - Start date
 * @param {string} config.end_date - End date
 * @param {number} config.initial_capital - Initial capital
 * @param {number} config.commission_rate - Commission rate
 * @param {number} config.slippage - Slippage
 * @returns {Promise<BacktestResult>}
 */
export async function runBacktest(config) {
  return apiFetch('/backtest', {
    method: 'POST',
    body: JSON.stringify({
      stock_code: config.stock_code,
      strategy: config.strategy || 'ma_cross',
      start_date: config.start_date,
      end_date: config.end_date,
      initial_capital: config.initial_capital || 100000,
      commission_rate: config.commission_rate || 0.0003,
      slippage: config.slippage || 0.001
    })
  });
}

/**
 * Get backtest result by ID (placeholder)
 * @param {string} id - Backtest ID
 * @returns {Promise<BacktestResult>}
 */
export async function getBacktestResult(id) {
  return apiFetch(`/backtest/${id}/result`);
}

// ============================================================================
// Drawdown Analysis API
// ============================================================================

/**
 * Get drawdown analysis for a stock
 * @param {string} code - Stock code
 * @param {string} start - Start date
 * @param {string} end - End date
 * @returns {Promise<DrawdownResult>}
 */
export async function getDrawdown(code, start, end) {
  const params = new URLSearchParams();
  if (start) params.append('start', start);
  if (end) params.append('end', end);
  return apiFetch(`/drawdown/${code}?${params}`);
}

/**
 * Get portfolio-level drawdown
 * @returns {Promise<PortfolioDrawdownResult>}
 */
export async function getPortfolioDrawdown() {
  return apiFetch('/portfolio/drawdown');
}

// ============================================================================
// Health Check
// ============================================================================

/**
 * Check API health status
 * @returns {Promise<{status: string, timestamp: string}>}
 */
export async function checkHealth() {
  return apiFetch('/health');
}
