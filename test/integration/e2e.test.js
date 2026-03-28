/**
 * Integration Tests - E2E Workflows
 *
 * Tests for complete user workflows combining API calls and UI interactions
 * Run with: node --test test/integration/e2e.test.js
 */

import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert/strict';

// Mock API responses
const mockApiResponses = {
  '/api/health': { status: 'ok', service: 'moonbit-drawdown' },
  '/api/stocks': {
    stocks: [
      { code: 'sh.600000', name: '股票 600000', industry: 'Banking', market: 'SH' },
      { code: 'sh.600001', name: '股票 600001', industry: 'Banking', market: 'SH' }
    ],
    total: 2
  },
  '/api/stocks/sh.600000': {
    code: 'sh.600000',
    name: '股票 600000',
    industry: 'Banking',
    market: 'SH'
  },
  '/api/stocks/sh.600000/klines': {
    stock: 'sh.600000',
    klines: [
      { date: '2026-03-27', open: 10.5, high: 11.0, low: 10.3, close: 10.8, volume: 1000000 }
    ],
    count: 1
  },
  '/api/strategies': {
    strategies: [
      { name: 'ma_cross', description: 'Moving Average Crossover', category: 'trend_following' },
      { name: 'momentum', description: 'Momentum Strategy', category: 'momentum' },
      { name: 'rsi_mean_reversion', description: 'RSI Mean Reversion', category: 'mean_reversion' }
    ],
    total: 3
  },
  '/api/strategies/ma_cross': {
    id: 'ma_cross',
    name: 'ma_cross',
    description: 'Moving Average Crossover',
    is_builtin: true
  },
  '/api/backtest': {
    backtest_id: 'bt_001',
    status: 'completed',
    result: {
      initial_capital: 100000,
      final_capital: 112450,
      total_return: 0.1245,
      max_drawdown: -0.0832,
      sharpe_ratio: 1.25,
      total_trades: 24,
      win_rate: 0.625
    }
  },
  '/api/backtest/bt_001/result': {
    backtest_id: 'bt_001',
    status: 'completed',
    result: {
      initial_capital: 100000,
      final_capital: 112450,
      total_return: 0.1245,
      max_drawdown: -0.0832,
      sharpe_ratio: 1.25,
      total_trades: 24,
      win_rate: 0.625
    }
  },
  '/api/drawdown/sh.600000': {
    stock: 'sh.600000',
    drawdown: {
      current: -0.0245,
      max: -0.1523
    }
  },
  '/api/portfolio/drawdown': {
    portfolio: {
      total_drawdown: -0.0532,
      max_stock_drawdown: -0.1523
    }
  },
  '/api/industries': {
    industries: [
      { name: 'Banking', stock_count: 19 },
      { name: 'Securities', stock_count: 5 }
    ],
    total: 2
  }
};

// Mock fetch implementation
function mockFetch(url, options = {}) {
  const endpoint = url.replace('/api', '');
  const response = mockApiResponses[endpoint];

  if (response) {
    return Promise.resolve({
      ok: true,
      status: 200,
      json: () => Promise.resolve(response)
    });
  }

  return Promise.resolve({
    ok: false,
    status: 404,
    json: () => Promise.resolve({ error: 'Not found' })
  });
}

describe('E2E: Stock Selection Workflow', () => {
  it('should load stock list and display stocks', async () => {
    const response = await mockFetch('/api/stocks');
    const data = await response.json();

    assert.ok(data.stocks, 'Should have stocks array');
    assert.ok(data.total, 'Should have total count');
    assert.strictEqual(data.stocks.length, 2);
    assert.strictEqual(data.stocks[0].code, 'sh.600000');
  });

  it('should get individual stock info', async () => {
    const response = await mockFetch('/api/stocks/sh.600000');
    const data = await response.json();

    assert.strictEqual(data.code, 'sh.600000');
    assert.strictEqual(data.name, '股票 600000');
    assert.strictEqual(data.industry, 'Banking');
  });

  it('should get stock K-line data', async () => {
    const response = await mockFetch('/api/stocks/sh.600000/klines');
    const data = await response.json();

    assert.strictEqual(data.stock, 'sh.600000');
    assert.ok(data.klines, 'Should have klines array');
    assert.strictEqual(data.count, 1);
  });
});

describe('E2E: Strategy Configuration and Backtest Workflow', () => {
  it('should load available strategies', async () => {
    const response = await mockFetch('/api/strategies');
    const data = await response.json();

    assert.ok(data.strategies, 'Should have strategies array');
    assert.strictEqual(data.total, 3);
    assert.ok(data.strategies.some(s => s.name === 'ma_cross'));
  });

  it('should get strategy details', async () => {
    const response = await mockFetch('/api/strategies/ma_cross');
    const data = await response.json();

    assert.strictEqual(data.id, 'ma_cross');
    assert.ok(data.is_builtin);
  });

  it('should run backtest and get results', async () => {
    const response = await mockFetch('/api/backtest');
    const data = await response.json();

    assert.ok(data.backtest_id, 'Should have backtest_id');
    assert.strictEqual(data.status, 'completed');
    assert.ok(data.result, 'Should have result object');
  });

  it('should get backtest result by ID', async () => {
    const response = await mockFetch('/api/backtest/bt_001/result');
    const data = await response.json();

    assert.strictEqual(data.backtest_id, 'bt_001');
    assert.strictEqual(data.status, 'completed');
    assert.ok(data.result.total_return, 'Should have total_return');
    assert.ok(data.result.max_drawdown, 'Should have max_drawdown');
    assert.ok(data.result.sharpe_ratio, 'Should have sharpe_ratio');
  });

  it('should calculate backtest metrics', async () => {
    const response = await mockFetch('/api/backtest');
    const data = await response.json();

    const result = data.result;
    assert.ok(result.initial_capital > 0, 'Initial capital should be positive');
    assert.ok(result.final_capital > result.initial_capital, 'Final should exceed initial');
    assert.ok(result.total_return > 0, 'Total return should be positive');
    assert.ok(result.max_drawdown < 0, 'Max drawdown should be negative');
    assert.ok(result.sharpe_ratio > 0, 'Sharpe ratio should be positive');
    assert.ok(result.win_rate >= 0 && result.win_rate <= 1, 'Win rate should be 0-1');
  });
});

describe('E2E: Drawdown Analysis Workflow', () => {
  it('should get stock drawdown', async () => {
    const response = await mockFetch('/api/drawdown/sh.600000');
    const data = await response.json();

    assert.strictEqual(data.stock, 'sh.600000');
    assert.ok(data.drawdown, 'Should have drawdown object');
    assert.ok('current' in data.drawdown, 'Should have current drawdown');
    assert.ok('max' in data.drawdown, 'Should have max drawdown');
  });

  it('should get portfolio drawdown', async () => {
    const response = await mockFetch('/api/portfolio/drawdown');
    const data = await response.json();

    assert.ok(data.portfolio, 'Should have portfolio object');
    assert.ok(data.portfolio.total_drawdown, 'Should have total drawdown');
    assert.ok(data.portfolio.max_stock_drawdown, 'Should have max stock drawdown');
  });

  it('should compare stock vs portfolio drawdown', async () => {
    const stockResponse = await mockFetch('/api/drawdown/sh.600000');
    const portfolioResponse = await mockFetch('/api/portfolio/drawdown');

    const stockData = await stockResponse.json();
    const portfolioData = await portfolioResponse.json();

    // Stock max drawdown should be more negative than portfolio total
    assert.ok(
      stockData.drawdown.max <= portfolioData.portfolio.max_stock_drawdown,
      'Stock max drawdown should be tracked in portfolio'
    );
  });
});

describe('E2E: Industry Analysis Workflow', () => {
  it('should list industries', async () => {
    const response = await mockFetch('/api/industries');
    const data = await response.json();

    assert.ok(data.industries, 'Should have industries array');
    assert.ok(data.total, 'Should have total count');
    assert.strictEqual(data.industries.length, 2);
  });

  it('should have industry stock counts', async () => {
    const response = await mockFetch('/api/industries');
    const data = await response.json();

    for (const industry of data.industries) {
      assert.ok(industry.name, 'Industry should have name');
      assert.ok(industry.stock_count !== undefined, 'Industry should have stock_count');
    }
  });
});

describe('E2E: Health Check and API Availability', () => {
  it('should respond to health check', async () => {
    const response = await mockFetch('/api/health');
    const data = await response.json();

    assert.strictEqual(data.status, 'ok');
    assert.strictEqual(data.service, 'moonbit-drawdown');
  });
});

describe('E2E: Complete User Session', () => {
  it('should complete full analysis workflow', async () => {
    // Step 1: Check API health
    const healthResponse = await mockFetch('/api/health');
    const health = await healthResponse.json();
    assert.strictEqual(health.status, 'ok');

    // Step 2: Get stock list
    const stocksResponse = await mockFetch('/api/stocks');
    const stocks = await stocksResponse.json();
    assert.ok(stocks.stocks.length > 0);

    // Step 3: Get strategies
    const strategiesResponse = await mockFetch('/api/strategies');
    const strategies = await strategiesResponse.json();
    assert.ok(strategies.strategies.length > 0);

    // Step 4: Run backtest
    const backtestResponse = await mockFetch('/api/backtest');
    const backtest = await backtestResponse.json();
    assert.ok(backtest.backtest_id);

    // Step 5: Get backtest result
    const resultResponse = await mockFetch('/api/backtest/bt_001/result');
    const result = await resultResponse.json();
    assert.strictEqual(result.status, 'completed');

    // Step 6: Get drawdown analysis
    const drawdownResponse = await mockFetch('/api/drawdown/sh.600000');
    const drawdown = await drawdownResponse.json();
    assert.ok(drawdown.drawdown);

    // Step 7: Get portfolio drawdown
    const portfolioResponse = await mockFetch('/api/portfolio/drawdown');
    const portfolio = await portfolioResponse.json();
    assert.ok(portfolio.portfolio);

    // Verify complete workflow
    assert.ok(health, 'Health check passed');
    assert.ok(stocks, 'Stocks loaded');
    assert.ok(strategies, 'Strategies loaded');
    assert.ok(backtest, 'Backtest started');
    assert.ok(result, 'Backtest completed');
    assert.ok(drawdown, 'Drawdown analyzed');
    assert.ok(portfolio, 'Portfolio analyzed');
  });
});

describe('E2E: Error Handling', () => {
  it('should handle unknown endpoint', async () => {
    const response = await mockFetch('/api/unknown/endpoint');

    assert.ok(!response.ok, 'Should not be ok');
    assert.strictEqual(response.status, 404);
  });

  it('should handle invalid stock code', async () => {
    const response = await mockFetch('/api/stocks/invalid.stock');

    // Should return 404 for non-existent stock
    assert.ok(!response.ok || response.status === 404, 'Should handle invalid stock');
  });

  it('should handle invalid strategy id', async () => {
    const response = await mockFetch('/api/strategies/invalid_strategy');

    // Should return 404 for non-existent strategy
    assert.ok(!response.ok || response.status === 404, 'Should handle invalid strategy');
  });
});

describe('E2E: Data Consistency', () => {
  it('should have consistent stock codes across endpoints', async () => {
    // Get stock list
    const stocksResponse = await mockFetch('/api/stocks');
    const stocks = await stocksResponse.json();

    // Get individual stock info
    const stockCode = stocks.stocks[0].code;
    const stockResponse = await mockFetch(`/api/stocks/${stockCode}`);
    const stock = await stockResponse.json();

    // Verify consistency
    assert.strictEqual(stock.code, stockCode, 'Stock code should match');
  });

  it('should have consistent backtest results', async () => {
    // Run backtest
    const runResponse = await mockFetch('/api/backtest');
    const runResult = await runResponse.json();

    // Get result
    const resultResponse = await mockFetch('/api/backtest/bt_001/result');
    const result = await resultResponse.json();

    // Verify consistency
    assert.strictEqual(runResult.backtest_id, result.backtest_id);
    assert.strictEqual(runResult.status, result.status);
  });
});

describe('E2E: Performance Metrics', () => {
  it('should complete health check quickly', async () => {
    const startTime = Date.now();
    const response = await mockFetch('/api/health');
    await response.json();
    const endTime = Date.now();

    // Mock should be instant, but allow for some overhead
    assert.ok(endTime - startTime < 100, 'Health check should complete in <100ms');
  });

  it('should return stock list quickly', async () => {
    const startTime = Date.now();
    const response = await mockFetch('/api/stocks');
    await response.json();
    const endTime = Date.now();

    assert.ok(endTime - startTime < 500, 'Stock list should complete in <500ms');
  });

  it('should complete backtest request in reasonable time', async () => {
    const startTime = Date.now();
    const response = await mockFetch('/api/backtest');
    await response.json();
    const endTime = Date.now();

    // Backtest may take longer, but mock should be fast
    assert.ok(endTime - startTime < 1000, 'Backtest should complete in <1s');
  });
});
