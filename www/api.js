/**
 * API Service Module
 *
 * Provides functions for interacting with the Quantitative Drawdown Framework API.
 * Features:
 * - Request timeout handling
 * - Automatic retry with exponential backoff
 * - Unified error handling and classification
 * - Request cancellation support
 */

const API_BASE = '/api';

// ============================================================================
// Configuration
// ============================================================================

const API_CONFIG = {
  timeout: 30000,           // Default timeout: 30 seconds
  maxRetries: 3,            // Maximum retry attempts
  retryDelay: 1000,         // Initial retry delay: 1 second
  retryDelayMax: 10000,     // Maximum retry delay: 10 seconds
  retryStatusCodes: [408, 425, 429, 500, 502, 503, 504] // Status codes that trigger retry
};

// ============================================================================
// Error Classes
// ============================================================================

/**
 * Base API Error
 */
export class ApiError extends Error {
  constructor(message, code = 'API_ERROR', status = null, data = null) {
    super(message);
    this.name = 'ApiError';
    this.code = code;
    this.status = status;
    this.data = data;
    this.timestamp = new Date().toISOString();
  }
}

/**
 * Network Error (connection issues, timeout, etc.)
 */
export class NetworkError extends ApiError {
  constructor(message, code = 'NETWORK_ERROR') {
    super(message, code);
    this.name = 'NetworkError';
  }
}

/**
 * Timeout Error
 */
export class TimeoutError extends NetworkError {
  constructor(message = 'Request timed out') {
    super(message, 'TIMEOUT_ERROR');
    this.name = 'TimeoutError';
  }
}

/**
 * HTTP Error (4xx, 5xx responses)
 */
export class HttpError extends ApiError {
  constructor(message, status, code = 'HTTP_ERROR', data = null) {
    super(message, code, status, data);
    this.name = 'HttpError';
  }
}

/**
 * Bad Request Error (400)
 */
export class BadRequestError extends HttpError {
  constructor(message, data = null) {
    super(message, 400, 'BAD_REQUEST', data);
    this.name = 'BadRequestError';
  }
}

/**
 * Unauthorized Error (401)
 */
export class UnauthorizedError extends HttpError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
    this.name = 'UnauthorizedError';
  }
}

/**
 * Forbidden Error (403)
 */
export class ForbiddenError extends HttpError {
  constructor(message = 'Forbidden') {
    super(message, 403, 'FORBIDDEN');
    this.name = 'ForbiddenError';
  }
}

/**
 * Not Found Error (404)
 */
export class NotFoundError extends HttpError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
    this.name = 'NotFoundError';
  }
}

/**
 * Server Error (5xx)
 */
export class ServerError extends HttpError {
  constructor(message, status = 500, data = null) {
    super(message, status, 'SERVER_ERROR', data);
    this.name = 'ServerError';
  }
}

// ============================================================================
// Error Handler
// ============================================================================

/**
 * Classify and create appropriate error from response
 */
function createError(response, message) {
  const status = response?.status;

  switch (status) {
    case 400:
      return new BadRequestError(message || 'Bad request', response?.data);
    case 401:
      return new UnauthorizedError(message || 'Unauthorized');
    case 403:
      return new ForbiddenError(message || 'Forbidden');
    case 404:
      return new NotFoundError(message || 'Resource not found');
    case 408:
      return new TimeoutError(message || 'Request timeout');
    case 429:
      return new HttpError(message || 'Too many requests', status, 'RATE_LIMIT');
    case 500:
      return new ServerError(message || 'Internal server error', 500, response?.data);
    case 502:
      return new ServerError(message || 'Bad gateway', 502);
    case 503:
      return new ServerError(message || 'Service unavailable', 503);
    case 504:
      return new ServerError(message || 'Gateway timeout', 504);
    default:
      return new HttpError(message || `HTTP ${status}`, status, 'HTTP_ERROR');
  }
}

/**
 * Unified error handler
 */
export function handleError(error, context = '') {
  const prefix = context ? `[${context}] ` : '';

  if (error instanceof ApiError) {
    console.error(`${prefix}API Error:`, {
      name: error.name,
      code: error.code,
      status: error.status,
      message: error.message,
      timestamp: error.timestamp
    });
    return error;
  }

  if (error.name === 'AbortError') {
    const err = new NetworkError(`${prefix}Request cancelled`, 'CANCELLED');
    console.error(err.message);
    return err;
  }

  if (error instanceof TypeError && error.message.includes('fetch')) {
    const err = new NetworkError(`${prefix}Network error: ${error.message}`, 'FETCH_ERROR');
    console.error(err.message);
    return err;
  }

  const err = new ApiError(`${prefix}Unknown error: ${error.message}`, 'UNKNOWN_ERROR');
  console.error(err.message, error);
  return err;
}

// ============================================================================
// Response Handler
// ============================================================================

/**
 * API response handler with error processing
 */
async function handleResponse(response, endpoint) {
  let data;

  // Try to parse JSON response
  try {
    data = await response.json();
  } catch {
    data = null;
  }

  if (!response.ok) {
    const message = data?.error || data?.message || `HTTP ${response.status}`;
    throw createError({ status: response.status, data }, message);
  }

  return data;
}

// ============================================================================
// Retry Logic
// ============================================================================

/**
 * Calculate retry delay with exponential backoff and jitter
 */
function calculateRetryDelay(attempt, baseDelay, maxDelay) {
  const exponentialDelay = baseDelay * Math.pow(2, attempt);
  const jitter = Math.random() * 0.3 * exponentialDelay;
  return Math.min(exponentialDelay + jitter, maxDelay);
}

/**
 * Check if status code should trigger retry
 */
function shouldRetry(status) {
  return API_CONFIG.retryStatusCodes.includes(status);
}

// ============================================================================
// Core Fetch Function
// ============================================================================

/**
 * Create fetch with timeout support
 */
function fetchWithTimeout(url, options, timeout) {
  return new Promise((resolve, reject) => {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
      controller.abort();
      reject(new TimeoutError(`Request timeout after ${timeout}ms`));
    }, timeout);

    fetch(url, {
      ...options,
      signal: controller.signal
    })
      .then(response => {
        clearTimeout(timeoutId);
        resolve(response);
      })
      .catch(error => {
        clearTimeout(timeoutId);
        reject(error);
      });
  });
}

/**
 * Fetch with timeout, retry, and error handling
 */
export async function apiFetch(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const config = {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    }
  };

  const timeout = options.timeout ?? API_CONFIG.timeout;
  const maxRetries = options.maxRetries ?? API_CONFIG.maxRetries;

  let lastError = null;
  let attempt = 0;

  while (attempt <= maxRetries) {
    try {
      // Add retry count header for tracking
      if (attempt > 0) {
        config.headers['X-Retry-Count'] = String(attempt);
      }

      const response = await fetchWithTimeout(url, config, timeout);

      // Handle rate limiting with Retry-After header
      if (response.status === 429) {
        const retryAfter = response.headers.get('Retry-After');
        if (retryAfter && attempt < maxRetries) {
          const delay = parseInt(retryAfter, 10) * 1000;
          console.log(`Rate limited. Retrying after ${delay}ms...`);
          await sleep(delay);
          attempt++;
          continue;
        }
      }

      return await handleResponse(response, endpoint);

    } catch (error) {
      lastError = error;

      // Don't retry on client errors (except specific retryable status codes)
      if (error instanceof HttpError && !shouldRetry(error.status)) {
        throw handleError(error, endpoint);
      }

      // Don't retry on timeout if max retries reached
      if (error instanceof TimeoutError && attempt >= maxRetries) {
        throw handleError(error, endpoint);
      }

      // Don't retry on cancellation
      if (error.name === 'AbortError' || error.code === 'CANCELLED') {
        throw handleError(error, endpoint);
      }

      // Calculate delay before retry
      if (attempt < maxRetries) {
        const delay = calculateRetryDelay(attempt, API_CONFIG.retryDelay, API_CONFIG.retryDelayMax);
        console.log(`Request failed (attempt ${attempt + 1}/${maxRetries + 1}). Retrying in ${Math.round(delay)}ms...`);
        await sleep(delay);
      }

      attempt++;
    }
  }

  // All retries exhausted
  throw handleError(lastError, endpoint);
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Sleep for specified milliseconds
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ============================================================================
// Request Queue (for rate limiting)
// ============================================================================

const requestQueue = {
  queue: [],
  processing: false,
  delayBetweenRequests: 100 // ms between requests to avoid rate limiting
};

/**
 * Process queued requests one at a time
 */
async function processQueue() {
  if (requestQueue.processing || requestQueue.queue.length === 0) return;

  requestQueue.processing = true;

  while (requestQueue.queue.length > 0) {
    const request = requestQueue.queue.shift();
    try {
      const result = await request.fn();
      request.resolve(result);
    } catch (error) {
      request.reject(error);
    }

    if (requestQueue.queue.length > 0) {
      await sleep(requestQueue.delayBetweenRequests);
    }
  }

  requestQueue.processing = false;
}

/**
 * Add request to queue
 */
function queuedFetch(endpoint, options = {}) {
  return new Promise((resolve, reject) => {
    requestQueue.queue.push({
      fn: () => apiFetch(endpoint, options),
      resolve,
      reject
    });
    processQueue();
  });
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
 * Get backtest result by ID
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

// ============================================================================
// Stock Strategy API
// ============================================================================

/**
 * Get list of saved strategies
 * @returns {Promise<Array<{id: string, name: string, created_at: string, updated_at: string}>>}
 */
export async function getSavedStrategies() {
  return apiFetch('/strategies/saved');
}

/**
 * Save a new stock strategy
 * @param {Object} strategy - Strategy configuration
 * @returns {Promise<{id: string, message: string}>}
 */
export async function saveStrategy(strategy) {
  return apiFetch('/strategies', {
    method: 'POST',
    body: JSON.stringify(strategy)
  });
}

/**
 * Get strategy by ID
 * @param {string} id - Strategy ID
 * @returns {Promise<Object>} Strategy configuration
 */
export async function getStrategy(id) {
  return apiFetch(`/strategies/${id}`);
}

/**
 * Update existing strategy
 * @param {string} id - Strategy ID
 * @param {Object} strategy - Updated strategy configuration
 * @returns {Promise<{message: string}>}
 */
export async function updateStrategy(id, strategy) {
  return apiFetch(`/strategies/${id}`, {
    method: 'PUT',
    body: JSON.stringify(strategy)
  });
}

/**
 * Delete a strategy
 * @param {string} id - Strategy ID
 * @returns {Promise<{message: string}>}
 */
export async function deleteStrategy(id) {
  return apiFetch(`/strategies/${id}`, {
    method: 'DELETE'
  });
}

/**
 * Get industry list by standard
 * @param {string} standard - Industry standard (sw2014, sw2021, csrc)
 * @returns {Promise<Array<{id: string, name: string, parent_id?: string}>>}
 */
export async function getIndustries(standard) {
  const params = new URLSearchParams();
  if (standard) params.append('standard', standard);
  return apiFetch(`/industries?${params}`);
}

/**
 * Get stock list with filters
 * @param {Object} filters - Filter conditions
 * @returns {Promise<Array<{code: string, name: string, exchange: string}>>}
 */
export async function getStockListWithFilters(filters) {
  return apiFetch('/stocks/filter', {
    method: 'POST',
    body: JSON.stringify(filters)
  });
}

/**
 * Run strategy backtest with conditions
 * @param {Object} config - Backtest configuration
 * @returns {Promise<BacktestResult>}
 */
export async function runStrategyBacktest(config) {
  return apiFetch('/backtest/strategy', {
    method: 'POST',
    body: JSON.stringify(config),
    timeout: 60000 // Longer timeout for backtest
  });
}

/**
 * Get daily stock selection results
 * @param {Object} strategy - Strategy configuration
 * @param {string} date - Target date
 * @returns {Promise<{date: string, stocks: Array}>}
 */
export async function getDailySelection(strategy, date) {
  return apiFetch('/backtest/daily', {
    method: 'POST',
    body: JSON.stringify({ strategy, date })
  });
}

/**
 * Get real-time stock selection
 * @param {Object} strategy - Strategy configuration
 * @returns {Promise<{timestamp: string, stocks: Array}>}
 */
export async function getRealtimeSelection(strategy) {
  return apiFetch('/backtest/realtime', {
    method: 'POST',
    body: JSON.stringify({ strategy })
  });
}

/**
 * Get ranking analysis
 * @param {Object} strategy - Strategy configuration
 * @param {string} period - Analysis period (daily, weekly, monthly)
 * @returns {Promise<{rankings: Array}>}
 */
export async function getRankingAnalysis(strategy, period) {
  return apiFetch('/backtest/ranking', {
    method: 'POST',
    body: JSON.stringify({ strategy, period })
  });
}

// ============================================================================
// Screener API
// ============================================================================

/**
 * Get list of available indicators with metadata
 * @returns {Promise<Array<{id: string, name: string, category: string, unit: string, description: string, formula: string, range: string}>>}
 */
export async function getIndicators() {
  return apiFetch('/screener/indicators');
}

/**
 * Get detailed information about a specific indicator
 * @param {string} indicatorId - Indicator ID (e.g., "roe", "rsi")
 * @returns {Promise<{id: string, name: string, description: string, formula: string, category: string, unit: string, range: string}>}
 */
export async function getIndicatorDetail(indicatorId) {
  return apiFetch(`/screener/indicators/${indicatorId}`);
}

/**
 * Run stock screener with specified conditions
 * @param {Object} config - Screener configuration
 * @param {Array<Object>} config.filters - Array of filter conditions
 * @param {Array<Object>} config.weights - Indicator weights for sorting
 * @param {string} config.sortBy - Sort field
 * @param {string} config.sortOrder - Sort order (asc/desc)
 * @param {number} config.limit - Maximum results
 * @returns {Promise<{results: Array<StockResult>, total: number}>}
 */
export async function runScreener(config) {
  return apiFetch('/screener', {
    method: 'POST',
    body: JSON.stringify(config),
    timeout: 60000
  });
}

/**
 * Get stocks matching specific conditions
 * @param {Object} conditions - Filter conditions
 * @returns {Promise<Array<{code: string, name: string, indicators: Object}>>}
 */
export async function getStocksByConditions(conditions) {
  return apiFetch('/stocks/filter', {
    method: 'POST',
    body: JSON.stringify(conditions)
  });
}

// ============================================================================
// Benchmark API
// ============================================================================

/**
 * Get benchmark index data
 * @param {string} code - Benchmark code (hs300, zz500, zz1000, sh, sz)
 * @param {string} start - Start date
 * @param {string} end - End date
 * @returns {Promise<{code: string, name: string, data: Array}>}
 */
export async function getBenchmarkData(code, start, end) {
  const params = new URLSearchParams();
  params.append('code', code);
  if (start) params.append('start', start);
  if (end) params.append('end', end);
  return apiFetch(`/benchmark?${params}`);
}

// ============================================================================
// Configuration Methods
// ============================================================================

/**
 * Update API configuration
 * @param {Object} config - New configuration
 */
export function configureApi(config) {
  Object.assign(API_CONFIG, config);
}

/**
 * Get current API configuration
 * @returns {Object} Current configuration
 */
export function getApiConfig() {
  return { ...API_CONFIG };
}
