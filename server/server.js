#!/usr/bin/env node
/**
 * HTTP Server for Quantitative Drawdown Framework
 *
 * This server provides RESTful API endpoints for:
 * - Stock data retrieval
 * - Backtest execution
 * - Drawdown analysis
 * - Portfolio management
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 8080;
const DATA_DIR = path.join(__dirname, '..', 'data');
const WWW_DIR = path.join(__dirname, '..', 'www');

// Mock stock data (in real implementation, would call MoonBit backend)
const STOCKS = [];

// Scan data directory for available stocks
function scanStocks() {
  try {
    const files = fs.readdirSync(DATA_DIR);
    files.forEach(file => {
      if (file.endsWith('.csv')) {
        const match = file.match(/^(\w+)_(\d+)_(\d{4}-\d{2}-\d{2})_(\d{4}-\d{2}-\d{2})\.csv$/);
        if (match) {
          const [, exchange, code] = match;
          STOCKS.push(`${exchange}.${code}`);
        }
      }
    });
  } catch (error) {
    console.error('Error scanning data directory:', error.message);
  }
}

// Parse CSV file
function parseCSV(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.trim().split('\n');
    const headers = lines[0].split(',');

    return lines.slice(1).map(line => {
      const values = line.split(',');
      const kline = {};
      headers.forEach((header, i) => {
        kline[header.trim()] = values[i]?.trim();
      });
      return kline;
    });
  } catch (error) {
    return null;
  }
}

// Calculate drawdown from price series
function calculateDrawdown(prices) {
  if (prices.length === 0) return { maxDrawdown: 0, series: [] };

  let peak = prices[0];
  let maxDrawdown = 0;
  const series = [];

  prices.forEach((price, i) => {
    if (price > peak) peak = price;
    const drawdown = (peak - price) / peak;
    if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    series.push({ date: i, value: price, drawdown });
  });

  return { maxDrawdown, series };
}

// Mock backtest result
function generateMockBacktest(params) {
  const days = Math.floor(
    (new Date(params.end_date) - new Date(params.start_date)) / (1000 * 60 * 60 * 24)
  );

  const equityCurve = [];
  const trades = [];
  let equity = params.initial_capital;

  // Generate mock equity curve with some volatility
  for (let i = 0; i <= days; i++) {
    const date = new Date(params.start_date);
    date.setDate(date.getDate() + i);
    const dateStr = date.toISOString().split('T')[0];

    // Random walk with slight upward drift
    equity *= (1 + (Math.random() - 0.48) * 0.02);

    equityCurve.push({
      date: dateStr,
      equity: Math.round(equity * 100) / 100,
      drawdown: 0,
      position: equity * 0.8,
      cash: equity * 0.2,
    });
  }

  // Generate mock trades
  const numTrades = Math.floor(days / 10);
  for (let i = 0; i < numTrades; i++) {
    const date = new Date(params.start_date);
    date.setDate(date.getDate() + Math.floor(Math.random() * days));

    trades.push({
      stock: params.stock_code,
      action: i % 2 === 0 ? 'Buy' : 'Sell',
      price: Math.round((50 + Math.random() * 50) * 100) / 100,
      quantity: Math.floor(100 + Math.random() * 900),
      timestamp: date.toISOString().split('T')[0],
      commission: Math.round(Math.random() * 10 * 100) / 100,
    });
  }

  const initialCap = params.initial_capital;
  const finalCap = equityCurve[equityCurve.length - 1]?.equity || initialCap;
  const totalReturn = (finalCap - initialCap) / initialCap;

  return {
    initial_capital: initialCap,
    final_capital: Math.round(finalCap * 100) / 100,
    total_return: Math.round(totalReturn * 10000) / 10000,
    max_drawdown: -Math.round(Math.random() * 0.15 * 10000) / 10000,
    sharpe_ratio: Math.round((Math.random() * 2 + 0.5) * 1000) / 1000,
    total_trades: trades.length,
    equity_curve: equityCurve,
    trades: trades,
    stats: {
      total_return: Math.round(totalReturn * 10000) / 10000,
      annual_return: Math.round(totalReturn * (365 / days) * 10000) / 10000,
      max_drawdown: -Math.round(Math.random() * 0.15 * 10000) / 10000,
      sharpe_ratio: Math.round((Math.random() * 2 + 0.5) * 1000) / 1000,
      win_rate: Math.round((0.45 + Math.random() * 0.2) * 10000) / 10000,
      total_trades: trades.length,
      winning_trades: Math.floor(trades.length * 0.55),
      losing_trades: Math.floor(trades.length * 0.45),
    },
  };
}

// API Routes
const routes = {
  // GET /api/stocks
  'GET /api/stocks': (req, res) => {
    scanStocks();
    res.json(STOCKS.length > 0 ? STOCKS : ['sh.600000', 'sh.600004', 'sh.600006']);
  },

  // GET /api/stocks/:code/klines
  'GET /api/stocks/:code/klines': (req, res, params) => {
    const { code } = params;
    const { start, end } = req.query;

    // Find CSV file for stock
    const [exchange, stockCode] = code.split('.');
    const csvPattern = new RegExp(`${exchange}_${stockCode}_.*\\.csv$`);

    try {
      const files = fs.readdirSync(DATA_DIR);
      const matchingFile = files.find(f => csvPattern.test(f));

      if (!matchingFile) {
        return res.status(404).json({ error: 'Stock data not found' });
      }

      const klines = parseCSV(path.join(DATA_DIR, matchingFile));

      // Filter by date range
      const filtered = klines.filter(k => {
        if (start && k.date < start) return false;
        if (end && k.date > end) return false;
        return true;
      });

      res.json({ stock_code: code, klines: filtered });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // GET /api/strategies
  'GET /api/strategies': (req, res) => {
    res.json([
      { name: 'ma_cross', description: '均线交叉策略' },
      { name: 'momentum', description: '动量策略' },
    ]);
  },

  // POST /api/backtest
  'POST /api/backtest': (req, res) => {
    const body = req.body;

    // Validate required fields
    if (!body.stock_code || !body.strategy || !body.start_date || !body.end_date) {
      return res.status(400).json({
        error: 'Missing required fields: stock_code, strategy, start_date, end_date'
      });
    }

    // Generate mock backtest result
    const result = generateMockBacktest({
      stock_code: body.stock_code,
      strategy: body.strategy,
      start_date: body.start_date,
      end_date: body.end_date,
      initial_capital: body.initial_capital || 100000,
    });

    res.json(result);
  },

  // GET /api/drawdown/:code
  'GET /api/drawdown/:code': (req, res) => {
    const { code } = req.params;
    const { start, end } = req.query;

    // Find CSV file for stock
    const [exchange, stockCode] = code.split('.');
    const csvPattern = new RegExp(`${exchange}_${stockCode}_.*\\.csv$`);

    try {
      const files = fs.readdirSync(DATA_DIR);
      const matchingFile = files.find(f => csvPattern.test(f));

      if (!matchingFile) {
        return res.status(404).json({ error: 'Stock data not found' });
      }

      const klines = parseCSV(path.join(DATA_DIR, matchingFile));

      // Filter by date range
      let filtered = klines;
      if (start) filtered = filtered.filter(k => k.date >= start);
      if (end) filtered = filtered.filter(k => k.date <= end);

      if (filtered.length === 0) {
        return res.status(404).json({ error: 'No data in date range' });
      }

      // Extract prices and dates
      const prices = filtered.map(k => parseFloat(k.close));
      const dates = filtered.map(k => k.date);

      // Calculate drawdown
      const { maxDrawdown, series } = calculateDrawdown(prices);

      // Find peak and trough
      let peakIdx = 0;
      let troughIdx = 0;
      let peakVal = prices[0];
      let troughVal = prices[0];

      series.forEach((point, i) => {
        if (point.value > peakVal) {
          peakVal = point.value;
          peakIdx = i;
        }
        if (point.drawdown === maxDrawdown) {
          troughVal = point.value;
          troughIdx = i;
        }
      });

      res.json({
        stock_code: code,
        start_date: start || dates[0],
        end_date: end || dates[dates.length - 1],
        max_drawdown: -maxDrawdown,
        peak: peakVal,
        trough: troughVal,
        peak_date: dates[peakIdx],
        trough_date: dates[troughIdx],
        duration: Math.abs(troughIdx - peakIdx),
        drawdown_series: series.map(s => ({
          date: s.date,
          value: s.value,
          drawdown: -s.drawdown,
        })),
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  },

  // GET /api/portfolio/drawdown
  'GET /api/portfolio/drawdown': (req, res) => {
    // Mock portfolio drawdown
    res.json({
      max_drawdown: -0.12,
      current_drawdown: -0.05,
      peak_date: '2024-01-15',
      peak_value: 125000,
      drawdown_series: [],
      positions: [],
    });
  },
};

// Request handler
function handleRequest(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const method = req.method;

  // Set JSON content type for API responses
  res.setHeader('Content-Type', 'application/json');

  // Add CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Parse request body for POST requests
  if (method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        req.body = JSON.parse(body);
      } catch (e) {
        req.body = {};
      }
      routeRequest(req, res, method, pathname, parsedUrl);
    });
  } else {
    routeRequest(req, res, method, pathname, parsedUrl);
  }
}

// Route request to appropriate handler
function routeRequest(req, res, method, pathname, parsedUrl) {
  // Check for static file serving (www directory)
  if (!pathname.startsWith('/api')) {
    serveStaticFile(req, res, pathname);
    return;
  }

  req.query = parsedUrl.query;

  // Match route
  let matched = false;

  for (const [routePattern, handler] of Object.entries(routes)) {
    const [routeMethod, routePath] = routePattern.split(' ');

    if (method !== routeMethod) continue;

    // Handle path parameters
    const routeParts = routePath.split('/');
    const pathParts = pathname.split('/');

    if (routeParts.length !== pathParts.length) continue;

    const params = {};
    let matches = true;

    for (let i = 0; i < routeParts.length; i++) {
      if (routeParts[i].startsWith(':')) {
        params[routeParts[i].slice(1)] = pathParts[i];
      } else if (routeParts[i] !== pathParts[i]) {
        matches = false;
        break;
      }
    }

    if (matches) {
      matched = true;
      handler(req, res, params);
      break;
    }
  }

  if (!matched) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Not found' }));
  }
}

// Serve static files
function serveStaticFile(req, res, pathname) {
  // Default to index.html
  let filePath = path.join(WWW_DIR, pathname === '/' ? 'index.html' : pathname);

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'File not found' }));
    return;
  }

  // Set content type based on file extension
  const ext = path.extname(filePath);
  const contentTypes = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
  };

  res.setHeader('Content-Type', contentTypes[ext] || 'text/plain');

  try {
    const content = fs.readFileSync(filePath);
    res.writeHead(200);
    res.end(content);
  } catch (error) {
    res.writeHead(500);
    res.end(JSON.stringify({ error: error.message }));
  }
}

// Start server
const server = http.createServer(handleRequest);

server.listen(PORT, () => {
  console.log(`\n========================================`);
  console.log(`Quantitative Drawdown Framework Server`);
  console.log(`========================================`);
  console.log(`Server running at http://localhost:${PORT}`);
  console.log(`\nAvailable endpoints:`);
  console.log(`  GET  /api/stocks                 - List stocks`);
  console.log(`  GET  /api/stocks/:code/klines    - Get K-line data`);
  console.log(`  GET  /api/strategies             - List strategies`);
  console.log(`  POST /api/backtest               - Run backtest`);
  console.log(`  GET  /api/drawdown/:code         - Get drawdown analysis`);
  console.log(`  GET  /api/portfolio/drawdown     - Get portfolio drawdown`);
  console.log(`\nWeb interface: http://localhost:${PORT}/`);
  console.log(`========================================\n`);

  // Scan stocks on startup
  scanStocks();
  console.log(`Found ${STOCKS.length} stocks in data directory`);
});
