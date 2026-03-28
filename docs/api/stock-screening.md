# Stock Screening API Reference

**Version**: 1.0
**Created**: 2026-03-28
**Last Updated**: 2026-03-28

---

## Table of Contents

1. [Overview](#overview)
2. [Screening Endpoints](#screening-endpoints)
3. [Indicator Endpoints](#indicator-endpoints)
4. [Request/Response Formats](#requestresponse-formats)
5. [Examples](#examples)

---

## Overview

The Stock Screening API allows you to filter stocks based on technical indicators, financial metrics, and custom criteria.

### Base URL

```
http://localhost:8080/api
```

### Starting the Server

```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run cmd/main
```

### Authentication

Currently, no authentication is required.

---

## Screening Endpoints

### `POST /api/screen`

Screen stocks based on specified criteria.

#### Request Body

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `min_roe` | float | - | No | Minimum ROE (%) |
| `min_np_margin` | float | - | No | Minimum net profit margin (%) |
| `min_eps` | float | - | No | Minimum EPS |
| `min_price` | float | - | No | Minimum price |
| `max_price` | float | - | No | Maximum price |
| `min_volume` | float | - | No | Minimum volume |
| `min_health` | string | - | No | Minimum health rating |
| `sort_by` | string | `score` | No | Field to sort by |
| `sort_order` | string | `desc` | No | Sort order (`asc` or `desc`) |
| `limit` | int | 100 | No | Maximum results |

#### Request Example

```http
POST /api/screen HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "min_roe": 15.0,
  "min_eps": 2.0,
  "min_price": 10.0,
  "max_price": 50.0,
  "sort_by": "roe",
  "sort_order": "desc",
  "limit": 50
}
```

#### Response

```json
{
  "results": [
    {
      "code": "sh.600001",
      "name": "Stock 600001",
      "roe": 25.0,
      "np_margin": 18.0,
      "eps": 3.5,
      "price": 15.8,
      "volume": 1500000.0,
      "health": "Excellent",
      "score": 90.0
    },
    {
      "code": "sh.600003",
      "name": "Stock 600003",
      "roe": 18.5,
      "np_margin": 15.0,
      "eps": 2.8,
      "price": 12.3,
      "volume": 1200000.0,
      "health": "Good",
      "score": 80.0
    }
  ],
  "total": 2
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `results` | array | Array of ScreenResult objects |
| `total` | int | Total number of matching stocks |

#### ScreenResult Object

| Field | Type | Description |
|-------|------|-------------|
| `code` | string | Stock code |
| `name` | string | Stock name |
| `roe` | float | Return on Equity (%) |
| `np_margin` | float | Net Profit Margin (%) |
| `eps` | float | Earnings Per Share |
| `price` | float | Current price |
| `volume` | float | Trading volume |
| `health` | string | Health rating |
| `score` | float | Overall score |

#### cURL Example

```bash
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{
    "min_roe": 15.0,
    "min_eps": 2.0,
    "limit": 50
  }'
```

---

## Indicator Endpoints

### `GET /api/indicators`

Get list of all available indicators.

#### Request

```http
GET /api/indicators HTTP/1.1
Host: localhost:8080
```

#### Response

```json
{
  "indicators": [
    {
      "id": "roe",
      "name": "ROE",
      "category": "financial",
      "unit": "%"
    },
    {
      "id": "np_margin",
      "name": "Net Profit Margin",
      "category": "financial",
      "unit": "%"
    },
    {
      "id": "eps",
      "name": "EPS",
      "category": "financial",
      "unit": "CNY"
    },
    {
      "id": "price",
      "name": "Price",
      "category": "market",
      "unit": "CNY"
    },
    {
      "id": "volume",
      "name": "Volume",
      "category": "market",
      "unit": "shares"
    },
    {
      "id": "turnover_rate",
      "name": "Turnover Rate",
      "category": "market",
      "unit": "%"
    }
  ],
  "total": 6
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `indicators` | array | Array of indicator objects |
| `total` | int | Total number of indicators |

#### Indicator Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Indicator identifier |
| `name` | string | Display name |
| `category` | string | Category (`financial` or `market`) |
| `unit` | string | Unit of measurement |

#### cURL Example

```bash
curl http://localhost:8080/api/indicators
```

---

### `GET /api/indicators/:id`

Get detailed information about a specific indicator.

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Indicator identifier |

#### Request

```http
GET /api/indicators/roe HTTP/1.1
Host: localhost:8080
```

#### Response (ROE Example)

```json
{
  "id": "roe",
  "name": "Return on Equity",
  "description": "Net income divided by shareholders equity",
  "formula": "ROE = Net Income / Shareholders Equity",
  "category": "financial",
  "unit": "%",
  "range": "0-50%"
}
```

#### Response (Net Profit Margin Example)

```json
{
  "id": "np_margin",
  "name": "Net Profit Margin",
  "description": "Net income as percentage of revenue",
  "formula": "NP Margin = Net Income / Revenue",
  "category": "financial",
  "unit": "%",
  "range": "0-30%"
}
```

#### Response (EPS Example)

```json
{
  "id": "eps",
  "name": "Earnings Per Share",
  "description": "Net income divided by outstanding shares",
  "formula": "EPS = Net Income / Shares Outstanding",
  "category": "financial",
  "unit": "CNY",
  "range": "0-100"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Indicator identifier |
| `name` | string | Display name |
| `description` | string | Detailed description |
| `formula` | string | Calculation formula |
| `category` | string | Category |
| `unit` | string | Unit of measurement |
| `range` | string | Typical value range |

#### cURL Examples

```bash
# Get ROE indicator details
curl http://localhost:8080/api/indicators/roe

# Get EPS indicator details
curl http://localhost:8080/api/indicators/eps

# Get non-existent indicator (returns 404)
curl http://localhost:8080/api/indicators/unknown
```

#### Error Response (404)

```json
{
  "error": "Indicator not found"
}
```

---

## Request/Response Formats

### Content-Type

All requests and responses use JSON format:

```
Content-Type: application/json
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |

### Error Response Format

```json
{
  "error": "Error message description"
}
```

---

## Examples

### JavaScript/Node.js

```javascript
const API_BASE = 'http://localhost:8080/api';

// Screen stocks
async function screenStocks(criteria) {
  const response = await fetch(`${API_BASE}/screen`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(criteria)
  });
  return response.json();
}

// Get all indicators
async function getIndicators() {
  const response = await fetch(`${API_BASE}/indicators`);
  return response.json();
}

// Get indicator details
async function getIndicatorDetail(id) {
  const response = await fetch(`${API_BASE}/indicators/${id}`);
  return response.json();
}

// Usage example
(async () => {
  // Get available indicators
  const indicators = await getIndicators();
  console.log('Available indicators:', indicators.total);

  // Screen for high ROE stocks
  const results = await screenStocks({
    min_roe: 15.0,
    min_eps: 2.0,
    limit: 20
  });
  console.log('Screening results:', results.total, 'stocks');

  // Get ROE details
  const roe = await getIndicatorDetail('roe');
  console.log('ROE formula:', roe.formula);
})();
```

### Python

```python
import requests

API_BASE = 'http://localhost:8080/api'

def screen_stocks(criteria):
    """Screen stocks based on criteria"""
    response = requests.post(
        f'{API_BASE}/screen',
        json=criteria,
        headers={'Content-Type': 'application/json'}
    )
    return response.json()

def get_indicators():
    """Get all available indicators"""
    response = requests.get(f'{API_BASE}/indicators')
    return response.json()

def get_indicator_detail(indicator_id):
    """Get detailed indicator information"""
    response = requests.get(f'{API_BASE}/indicators/{indicator_id}')
    return response.json()

# Usage example
if __name__ == '__main__':
    # Get available indicators
    indicators = get_indicators()
    print(f"Available indicators: {indicators['total']}")

    # Screen for high ROE stocks
    results = screen_stocks({
        'min_roe': 15.0,
        'min_eps': 2.0,
        'limit': 20
    })
    print(f"Screening results: {results['total']} stocks")

    # Get ROE details
    roe = get_indicator_detail('roe')
    print(f"ROE formula: {roe['formula']}")
```

### cURL Examples

```bash
# List all indicators
curl http://localhost:8080/api/indicators

# Get indicator details
curl http://localhost:8080/api/indicators/roe

# Screen stocks with filters
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{
    "min_roe": 15.0,
    "min_np_margin": 10.0,
    "min_eps": 1.5,
    "sort_by": "roe",
    "sort_order": "desc",
    "limit": 20
  }'

# Screen with price range
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{
    "min_price": 10.0,
    "max_price": 50.0,
    "min_volume": 1000000.0
  }'
```

---

## Migration Guide

### From CLI to API

If you're migrating from CLI-based screening to the API:

| CLI Parameter | API Field |
|---------------|-----------|
| `--min-roe` | `min_roe` |
| `--min-eps` | `min_eps` |
| `--sort` | `sort_by` |
| `--limit` | `limit` |

### CLI Example
```bash
MOONBIT_CMD=stock-screener MOONBIT_ARGS="--min-roe 15 --limit 20" moon run cmd/main
```

### API Equivalent
```bash
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{"min_roe": 15.0, "limit": 20}'
```

---

*Last Updated: 2026-03-28*
*Document Maintainer: doc-eng*
