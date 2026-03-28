# Stock Selection API Specification

This document defines the REST API endpoints for the stock selection system, supporting indicator-based screening, weight configuration, trading model selection, and portfolio rebalancing.

## Base URL

```
http://localhost:8080/api
```

## Authentication

Current version does not require authentication.

## Response Format

All API responses follow this format:

```json
{
  "status": "success",
  "data": { ... }
}
```

Error responses:

```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description"
  }
}
```

---

## Stock Indicator Endpoints

### Get Available Indicators

#### `GET /api/indicators`

Retrieve all available stock indicators for screening.

**Request**:
```http
GET /api/indicators HTTP/1.1
Host: localhost:8080
```

**Query Parameters**:

| Parameter | Type   | Default | Description                           |
|-----------|--------|---------|---------------------------------------|
| `category`| string | all     | Filter by category (technical/fundamental/market/sentiment/volatility) |
| `tags`    | string | -       | Filter by tags (comma-separated)      |

**Response**:
```json
{
  "indicators": [
    {
      "id": "ma_20",
      "name": "20-Day Moving Average",
      "category": "technical",
      "description": "Simple moving average over 20 trading days",
      "parameters": {
        "period": { "type": "int", "default": 20, "min": 1, "max": 250 }
      },
      "output_type": "float",
      "tags": ["trend", "moving-average"]
    },
    {
      "id": "pe_ratio",
      "name": "Price-to-Earnings Ratio",
      "category": "fundamental",
      "description": "Current stock price divided by earnings per share",
      "parameters": {},
      "output_type": "float",
      "tags": ["valuation", "fundamental"]
    },
    {
      "id": "rsi_14",
      "name": "14-Day Relative Strength Index",
      "category": "technical",
      "description": "Momentum oscillator measuring speed and magnitude of price changes",
      "parameters": {
        "period": { "type": "int", "default": 14, "min": 2, "max": 100 }
      },
      "output_type": "float",
      "tags": ["momentum", "oscillator"]
    }
  ],
  "total": 3,
  "categories": ["technical", "fundamental", "market", "sentiment", "volatility"]
}
```

**cURL Example**:
```bash
curl "http://localhost:8080/api/indicators?category=technical"
```

---

### Get Indicator Details

#### `GET /api/indicators/:id`

Get detailed information about a specific indicator.

**Path Parameters**:
- `id`: Indicator ID (e.g., `ma_20`, `rsi_14`)

**Request**:
```http
GET /api/indicators/rsi_14 HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "indicator": {
    "id": "rsi_14",
    "name": "14-Day Relative Strength Index",
    "category": "technical",
    "description": "Momentum oscillator measuring speed and magnitude of price changes",
    "formula": "RSI = 100 - (100 / (1 + RS))",
    "parameters": {
      "period": {
        "type": "int",
        "default": 14,
        "min": 2,
        "max": 100,
        "description": "Number of periods for calculation"
      }
    },
    "output_type": "float",
    "output_range": { "min": 0, "max": 100 },
    "interpretation": {
      "oversold_threshold": 30,
      "overbought_threshold": 70
    },
    "tags": ["momentum", "oscillator"],
    "related_indicators": ["stoch", "macd", "williams_r"]
  }
}
```

**cURL Example**:
```bash
curl http://localhost:8080/api/indicators/rsi_14
```

---

### Get Stock Indicator Values

#### `GET /api/stocks/:code/indicators`

Get calculated indicator values for a specific stock.

**Path Parameters**:
- `code`: Stock code (e.g., `sh.600000`)

**Query Parameters**:

| Parameter | Type   | Default | Description                           |
|-----------|--------|---------|---------------------------------------|
| `indicators` | string | all   | Comma-separated list of indicator IDs |
| `start`   | string | -       | Start date (YYYY-MM-DD)               |
| `end`     | string | -       | End date (YYYY-MM-DD)                 |
| `period`  | int    | 250     | Number of historical periods          |

**Request**:
```http
GET /api/stocks/sh.600000/indicators?indicators=ma_20,rsi_14,pe_ratio HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "stock": "sh.600000",
  "as_of_date": "2024-03-28",
  "indicators": {
    "ma_20": {
      "value": 10.52,
      "signal": "bullish",
      "history": [
        { "date": "2024-03-28", "value": 10.52 },
        { "date": "2024-03-27", "value": 10.48 },
        { "date": "2024-03-26", "value": 10.45 }
      ]
    },
    "rsi_14": {
      "value": 45.2,
      "signal": "neutral",
      "history": [
        { "date": "2024-03-28", "value": 45.2 },
        { "date": "2024-03-27", "value": 43.8 },
        { "date": "2024-03-26", "value": 41.5 }
      ]
    },
    "pe_ratio": {
      "value": 5.23,
      "signal": "undervalued",
      "history": [
        { "date": "2024-03-28", "value": 5.23 },
        { "date": "2024-03-27", "value": 5.18 },
        { "date": "2024-03-26", "value": 5.15 }
      ]
    }
  }
}
```

**cURL Example**:
```bash
curl "http://localhost:8080/api/stocks/sh.600000/indicators?indicators=ma_20,rsi_14"
```

---

## Stock Screening Endpoints

### Screen Stocks

#### `POST /api/screen`

Screen stocks based on indicator criteria and ranking rules.

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `indicators` | array | yes | List of indicator filters |
| `filters` | object | no | Additional filters (sector, market cap, etc.) |
| `ranking` | object | no | Sorting and ranking configuration |
| `limit` | int | no | Maximum results to return (default: 100) |

**Request**:
```http
POST /api/screen HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "indicators": [
    {
      "id": "pe_ratio",
      "operator": "lte",
      "value": 20
    },
    {
      "id": "rsi_14",
      "operator": "gte",
      "value": 30
    },
    {
      "id": "ma_20",
      "operator": "above_price",
      "value": null
    }
  ],
  "filters": {
    "sectors": ["banking", "technology"],
    "market_cap": { "min": 10000000000, "max": 500000000000 },
    "exclude_st": true,
    "exclude_new_listing": true
  },
  "ranking": {
    "sort_by": "composite_score",
    "order": "desc"
  },
  "limit": 50
}
```

**Response**:
```json
{
  "screen_id": "scr_20240328_001",
  "timestamp": "2024-03-28T10:30:00Z",
  "results": {
    "total_matches": 45,
    "returned": 45,
    "stocks": [
      {
        "code": "sh.600000",
        "name": "Pudong Development Bank",
        "score": 85.5,
        "rank": 1,
        "indicators": {
          "pe_ratio": 5.23,
          "rsi_14": 45.2,
          "ma_20": 10.52,
          "current_price": 10.85
        },
        "signals": {
          "pe_ratio": "pass",
          "rsi_14": "pass",
          "ma_20": "pass"
        }
      },
      {
        "code": "sh.600001",
        "name": "Baosteel",
        "score": 78.2,
        "rank": 2,
        "indicators": {
          "pe_ratio": 8.5,
          "rsi_14": 52.1,
          "ma_20": 7.32,
          "current_price": 7.45
        },
        "signals": {
          "pe_ratio": "pass",
          "rsi_14": "pass",
          "ma_20": "pass"
        }
      }
    ]
  },
  "criteria_applied": {
    "indicators": 3,
    "filters": 4,
    "excluded_count": 1250
  }
}
```

**cURL Example**:
```bash
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{
    "indicators": [
      {"id": "pe_ratio", "operator": "lte", "value": 20}
    ],
    "limit": 50
  }'
```

---

### Save Screen Criteria

#### `POST /api/screens`

Save a screen configuration for reuse.

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Screen name |
| `description` | string | no | Screen description |
| `criteria` | object | yes | Screen criteria (same as POST /api/screen body) |
| `is_public` | bool | no | Whether screen is public (default: false) |

**Request**:
```http
POST /api/screens HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "Value Stocks Screen",
  "description": "Screen for undervalued stocks with low P/E and strong momentum",
  "criteria": {
    "indicators": [
      {"id": "pe_ratio", "operator": "lte", "value": 15},
      {"id": "pb_ratio", "operator": "lte", "value": 2},
      {"id": "roa", "operator": "gte", "value": 0.05}
    ],
    "filters": {
      "sectors": ["banking", "insurance"],
      "exclude_st": true
    }
  },
  "is_public": false
}
```

**Response**:
```json
{
  "status": "created",
  "screen_id": "usr_screen_001",
  "name": "Value Stocks Screen"
}
```

**cURL Example**:
```bash
curl -X POST http://localhost:8080/api/screens \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Screen",
    "criteria": {"indicators": []}
  }'
```

---

### Get Saved Screens

#### `GET /api/screens`

Get list of saved screen configurations.

**Request**:
```http
GET /api/screens HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "screens": [
    {
      "screen_id": "usr_screen_001",
      "name": "Value Stocks Screen",
      "description": "Screen for undervalued stocks",
      "created_at": "2024-03-28T10:30:00Z",
      "updated_at": "2024-03-28T10:30:00Z",
      "is_public": false,
      "criteria_summary": {
        "indicator_count": 3,
        "filter_count": 2
      }
    }
  ],
  "total": 1
}
```

---

### Get Saved Screen Details

#### `GET /api/screens/:id`

Get details of a specific saved screen.

**Path Parameters**:
- `id`: Screen ID

**Request**:
```http
GET /api/screens/usr_screen_001 HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "screen": {
    "screen_id": "usr_screen_001",
    "name": "Value Stocks Screen",
    "description": "Screen for undervalued stocks with low P/E and strong momentum",
    "criteria": {
      "indicators": [
        {"id": "pe_ratio", "operator": "lte", "value": 15},
        {"id": "pb_ratio", "operator": "lte", "value": 2},
        {"id": "roa", "operator": "gte", "value": 0.05}
      ],
      "filters": {
        "sectors": ["banking", "insurance"],
        "exclude_st": true
      }
    },
    "created_at": "2024-03-28T10:30:00Z",
    "updated_at": "2024-03-28T10:30:00Z",
    "is_public": false,
    "last_run": "2024-03-28T11:00:00Z",
    "last_results_count": 12
  }
}
```

---

### Update Saved Screen

#### `PUT /api/screens/:id`

Update an existing screen configuration.

**Path Parameters**:
- `id`: Screen ID

**Request Body**: Same as POST /api/screens (all fields optional)

**Response**:
```json
{
  "status": "updated",
  "screen_id": "usr_screen_001"
}
```

**cURL Example**:
```bash
curl -X PUT http://localhost:8080/api/screens/usr_screen_001 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Screen Name"}'
```

---

### Delete Saved Screen

#### `DELETE /api/screens/:id`

Delete a saved screen configuration.

**Path Parameters**:
- `id`: Screen ID

**Response**:
```json
{
  "status": "deleted",
  "screen_id": "usr_screen_001"
}
```

**cURL Example**:
```bash
curl -X DELETE http://localhost:8080/api/screens/usr_screen_001
```

---

### Run Saved Screen

#### `POST /api/screens/:id/run`

Run a saved screen and get results.

**Path Parameters**:
- `id`: Screen ID

**Request**:
```http
POST /api/screens/usr_screen_001/run HTTP/1.1
Host: localhost:8080
```

**Response**: Same format as POST /api/screen

---

## Indicator Weight Configuration Endpoints

### Get Weight Configurations

#### `GET /api/weights`

Get all weight configurations for composite scoring.

**Request**:
```http
GET /api/weights HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "configurations": [
    {
      "config_id": "wgt_default",
      "name": "Default Balanced",
      "description": "Equal weight across all categories",
      "is_default": true,
      "weights": {
        "technical": 0.25,
        "fundamental": 0.25,
        "market": 0.25,
        "sentiment": 0.25
      },
      "indicators": {
        "ma_20": 0.10,
        "rsi_14": 0.15,
        "pe_ratio": 0.15,
        "pb_ratio": 0.10,
        "market_cap": 0.10,
        "volume_ratio": 0.15,
        "analyst_rating": 0.15,
        "news_sentiment": 0.10
      },
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-03-15T10:00:00Z"
    }
  ],
  "total": 1
}
```

---

### Create Weight Configuration

#### `POST /api/weights`

Create a new weight configuration.

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Configuration name |
| `description` | string | no | Configuration description |
| `weights` | object | yes | Indicator weights (must sum to 1.0) |

**Request**:
```http
POST /api/weights HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "Value-Focused",
  "description": "Higher weight on fundamental indicators",
  "weights": {
    "pe_ratio": 0.25,
    "pb_ratio": 0.20,
    "roa": 0.15,
    "debt_to_equity": 0.10,
    "ma_20": 0.10,
    "rsi_14": 0.10,
    "volume_ratio": 0.05,
    "market_cap": 0.05
  }
}
```

**Response**:
```json
{
  "status": "created",
  "config_id": "usr_wgt_001",
  "name": "Value-Focused"
}
```

---

### Update Weight Configuration

#### `PUT /api/weights/:id`

Update an existing weight configuration.

**Path Parameters**:
- `id`: Weight configuration ID

**Request Body**: Same as POST /api/weights (all fields optional)

**Response**:
```json
{
  "status": "updated",
  "config_id": "usr_wgt_001"
}
```

---

### Delete Weight Configuration

#### `DELETE /api/weights/:id`

Delete a weight configuration.

**Path Parameters**:
- `id`: Weight configuration ID

**Response**:
```json
{
  "status": "deleted",
  "config_id": "usr_wgt_001"
}
```

---

### Validate Weights

#### `POST /api/weights/validate`

Validate that weights sum to 1.0.

**Request Body**:

```json
{
  "weights": {
    "pe_ratio": 0.3,
    "pb_ratio": 0.3,
    "ma_20": 0.4
  }
}
```

**Response**:
```json
{
  "valid": true,
  "sum": 1.0,
  "message": "Weights are valid"
}
```

Or for invalid weights:

```json
{
  "valid": false,
  "sum": 0.85,
  "message": "Weights must sum to 1.0",
  "adjustment_suggestion": {
    "pe_ratio": 0.353,
    "pb_ratio": 0.353,
    "ma_20": 0.294
  }
}
```

---

## Trading Model Endpoints

### Get Trading Models

#### `GET /api/trading-models`

Get all available trading models.

**Request**:
```http
GET /api/trading-models HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "models": [
    {
      "id": "periodic_rebalance",
      "name": "Periodic Rebalancing",
      "description": "Rebalance portfolio at fixed intervals",
      "type": "rebalancing",
      "parameters": {
        "rebalance_period": {
          "type": "enum",
          "options": ["daily", "weekly", "biweekly", "monthly", "quarterly"],
          "default": "monthly"
        },
        "hold_count": {
          "type": "int",
          "default": 10,
          "min": 1,
          "max": 100
        },
        "rebalance_threshold": {
          "type": "float",
          "default": 0.05,
          "description": "Trigger rebalance if drift exceeds threshold"
        }
      }
    },
    {
      "id": "conditional_trigger",
      "name": "Conditional Trigger",
      "description": "Trade when specific conditions are met",
      "type": "conditional",
      "parameters": {
        "trigger_conditions": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "indicator": {"type": "string"},
              "operator": {"type": "enum", "options": ["gt", "gte", "lt", "lte", "eq", "cross_above", "cross_below"]},
              "value": {"type": "number"}
            }
          }
        },
        "position_size": {
          "type": "float",
          "default": 0.1,
          "description": "Position size as fraction of portfolio"
        },
        "max_positions": {
          "type": "int",
          "default": 10
        }
      }
    },
    {
      "id": "mean_reversion",
      "name": "Mean Reversion",
      "description": "Buy oversold stocks, sell overbought stocks",
      "type": "strategy",
      "parameters": {
        "indicator": {
          "type": "string",
          "default": "rsi_14"
        },
        "oversold_threshold": {
          "type": "float",
          "default": 30
        },
        "overbought_threshold": {
          "type": "float",
          "default": 70
        },
        "exit_threshold": {
          "type": "float",
          "default": 50
        }
      }
    },
    {
      "id": "momentum_follow",
      "name": "Momentum Following",
      "description": "Buy stocks with strong upward momentum",
      "type": "strategy",
      "parameters": {
        "lookback_period": {
          "type": "int",
          "default": 20
        },
        "momentum_threshold": {
          "type": "float",
          "default": 0.05
        },
        "exit_on_reversal": {
          "type": "bool",
          "default": true
        }
      }
    }
  ],
  "total": 4
}
```

---

### Get Trading Model Details

#### `GET /api/trading-models/:id`

Get detailed information about a specific trading model.

**Path Parameters**:
- `id`: Trading model ID

**Request**:
```http
GET /api/trading-models/periodic_rebalance HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "model": {
    "id": "periodic_rebalance",
    "name": "Periodic Rebalancing",
    "description": "Rebalance portfolio at fixed intervals based on screen results",
    "type": "rebalancing",
    "parameters": {
      "rebalance_period": {
        "type": "enum",
        "options": ["daily", "weekly", "biweekly", "monthly", "quarterly"],
        "default": "monthly",
        "description": "How often to rebalance"
      },
      "hold_count": {
        "type": "int",
        "default": 10,
        "min": 1,
        "max": 100,
        "description": "Number of stocks to hold"
      },
      "rebalance_threshold": {
        "type": "float",
        "default": 0.05,
        "min": 0.01,
        "max": 0.20,
        "description": "Trigger rebalance if portfolio drift exceeds this threshold"
      }
    },
    "rebalance_logic": {
      "steps": [
        "1. Run screen to get current top-ranked stocks",
        "2. Compare with current holdings",
        "3. Sell stocks no longer in top N",
        "4. Buy new stocks that entered top N",
        "5. Rebalance existing positions to target weights"
      ]
    },
    "risk_controls": {
      "max_turnover_per_rebalance": 0.5,
      "min_holding_period": 1,
      "respect_trading_limits": true
    }
  }
}
```

---

### Create Trading Strategy

#### `POST /api/trading-strategies`

Create a custom trading strategy based on a model.

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Strategy name |
| `model_id` | string | yes | Base trading model ID |
| `parameters` | object | yes | Model-specific parameters |
| `screen_id` | string | yes | Screen to use for stock selection |
| `weight_config_id` | string | no | Weight configuration for ranking |

**Request**:
```http
POST /api/trading-strategies HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "Monthly Value Rebalance",
  "model_id": "periodic_rebalance",
  "parameters": {
    "rebalance_period": "monthly",
    "hold_count": 15,
    "rebalance_threshold": 0.05
  },
  "screen_id": "usr_screen_001",
  "weight_config_id": "usr_wgt_001"
}
```

**Response**:
```json
{
  "status": "created",
  "strategy_id": "usr_strategy_001",
  "name": "Monthly Value Rebalance"
}
```

---

### Get Trading Strategies

#### `GET /api/trading-strategies`

Get list of user's trading strategies.

**Request**:
```http
GET /api/trading-strategies HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "strategies": [
    {
      "strategy_id": "usr_strategy_001",
      "name": "Monthly Value Rebalance",
      "model_id": "periodic_rebalance",
      "model_name": "Periodic Rebalancing",
      "screen_id": "usr_screen_001",
      "screen_name": "Value Stocks Screen",
      "parameters": {
        "rebalance_period": "monthly",
        "hold_count": 15,
        "rebalance_threshold": 0.05
      },
      "status": "active",
      "created_at": "2024-03-28T10:00:00Z",
      "last_run": "2024-03-28T09:00:00Z",
      "next_run": "2024-04-01T09:00:00Z"
    }
  ],
  "total": 1
}
```

---

### Get Trading Strategy Details

#### `GET /api/trading-strategies/:id`

Get details of a specific trading strategy.

**Path Parameters**:
- `id`: Strategy ID

**Request**:
```http
GET /api/trading-strategies/usr_strategy_001 HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "strategy": {
    "strategy_id": "usr_strategy_001",
    "name": "Monthly Value Rebalance",
    "model_id": "periodic_rebalance",
    "parameters": {
      "rebalance_period": "monthly",
      "hold_count": 15,
      "rebalance_threshold": 0.05
    },
    "screen": {
      "screen_id": "usr_screen_001",
      "name": "Value Stocks Screen"
    },
    "weight_config": {
      "config_id": "usr_wgt_001",
      "name": "Value-Focused"
    },
    "status": "active",
    "created_at": "2024-03-28T10:00:00Z",
    "updated_at": "2024-03-28T10:00:00Z",
    "last_run": {
      "run_at": "2024-03-28T09:00:00Z",
      "action": "rebalanced",
      "stocks_added": 3,
      "stocks_removed": 2,
      "positions_adjusted": 5
    },
    "next_run": "2024-04-01T09:00:00Z",
    "performance": {
      "total_return": 0.0523,
      "vs_benchmark": 0.0215,
      "run_count": 12
    }
  }
}
```

---

### Update Trading Strategy

#### `PUT /api/trading-strategies/:id`

Update an existing trading strategy.

**Path Parameters**:
- `id`: Strategy ID

**Request Body**: Same as POST /api/trading-strategies (all fields optional)

**Response**:
```json
{
  "status": "updated",
  "strategy_id": "usr_strategy_001"
}
```

---

### Delete Trading Strategy

#### `DELETE /api/trading-strategies/:id`

Delete a trading strategy.

**Path Parameters**:
- `id`: Strategy ID

**Response**:
```json
{
  "status": "deleted",
  "strategy_id": "usr_strategy_001"
}
```

---

### Trigger Strategy Run

#### `POST /api/trading-strategies/:id/run`

Manually trigger a strategy run.

**Path Parameters**:
- `id`: Strategy ID

**Request**:
```http
POST /api/trading-strategies/usr_strategy_001/run HTTP/1.1
Host: localhost:8080
```

**Response** (immediate):
```json
{
  "status": "started",
  "run_id": "run_20240328_001"
}
```

**Response** (completed, if sync):
```json
{
  "status": "completed",
  "run_id": "run_20240328_001",
  "result": {
    "action": "rebalanced",
    "stocks_added": [
      {"code": "sh.600010", "name": "Pudong Steel", "weight": 0.067}
    ],
    "stocks_removed": [
      {"code": "sh.600005", "name": "Wuhan Iron", "weight": 0.0}
    ],
    "positions_adjusted": [
      {"code": "sh.600000", "old_weight": 0.08, "new_weight": 0.075}
    ],
    "total_turnover": 0.15,
    "timestamp": "2024-03-28T10:30:00Z"
  }
}
```

---

## Strategy Results Endpoints

### Get Strategy History

#### `GET /api/trading-strategies/:id/history`

Get execution history for a strategy.

**Path Parameters**:
- `id`: Strategy ID

**Query Parameters**:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | int | 20 | Number of results to return |
| `offset` | int | 0 | Offset for pagination |

**Request**:
```http
GET /api/trading-strategies/usr_strategy_001/history?limit=10 HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "strategy_id": "usr_strategy_001",
  "history": [
    {
      "run_id": "run_20240328_001",
      "run_at": "2024-03-28T09:00:00Z",
      "status": "completed",
      "action": "rebalanced",
      "summary": {
        "stocks_added": 3,
        "stocks_removed": 2,
        "positions_adjusted": 5,
        "total_turnover": 0.15
      }
    },
    {
      "run_id": "run_20240228_001",
      "run_at": "2024-02-28T09:00:00Z",
      "status": "completed",
      "action": "rebalanced",
      "summary": {
        "stocks_added": 2,
        "stocks_removed": 2,
        "positions_adjusted": 4,
        "total_turnover": 0.12
      }
    }
  ],
  "total": 12,
  "limit": 10,
  "offset": 0
}
```

---

### Get Strategy Run Details

#### `GET /api/trading-strategies/:id/runs/:run_id`

Get detailed results of a specific strategy run.

**Path Parameters**:
- `id`: Strategy ID
- `run_id`: Run ID

**Request**:
```http
GET /api/trading-strategies/usr_strategy_001/runs/run_20240328_001 HTTP/1.1
Host: localhost:8080
```

**Response**:
```json
{
  "run": {
    "run_id": "run_20240328_001",
    "strategy_id": "usr_strategy_001",
    "run_at": "2024-03-28T09:00:00Z",
    "completed_at": "2024-03-28T09:05:23Z",
    "status": "completed",
    "action": "rebalanced",
    "details": {
      "screen_results": {
        "total_screened": 4500,
        "passed_filters": 45,
        "top_selected": 15
      },
      "portfolio_before": {
        "holdings": 12,
        "cash": 0.08,
        "total_value": 1000000
      },
      "portfolio_after": {
        "holdings": 15,
        "cash": 0.05,
        "total_value": 1023000
      },
      "trades": [
        {
          "action": "buy",
          "stock": "sh.600010",
          "quantity": 5000,
          "price": 12.50,
          "value": 62500,
          "target_weight": 0.067
        },
        {
          "action": "sell",
          "stock": "sh.600005",
          "quantity": 8000,
          "price": 9.25,
          "value": 74000,
          "reason": "no_longer_in_screen"
        }
      ],
      "total_turnover": 0.15,
      "transaction_costs": 285.50
    }
  }
}
```

---

## Error Codes Reference

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `INVALID_INDICATOR` | 400 | Invalid indicator ID |
| `INVALID_OPERATOR` | 400 | Invalid comparison operator |
| `INVALID_WEIGHT_SUM` | 400 | Weights do not sum to 1.0 |
| `SCREEN_NOT_FOUND` | 404 | Saved screen not found |
| `STRATEGY_NOT_FOUND` | 404 | Trading strategy not found |
| `MODEL_NOT_FOUND` | 404 | Trading model not found |
| `INVALID_DATE_RANGE` | 400 | Start date after end date |
| `INSUFFICIENT_DATA` | 400 | Not enough data for calculation |
| `SCREEN_EXECUTION_FAILED` | 500 | Screen execution failed |
| `INTERNAL_ERROR` | 500 | Internal server error |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-03-28 | Initial release |

---

*Last updated: 2024-03-28*
