# HTTP API 参考文档

本文档提供 HTTP API 服务器的完整端点参考，包括请求/响应格式、参数说明和使用示例。

## 概述

### 启动服务器

使用 MoonBit 内置 HTTP 服务器启动服务：

```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run alpha
```

**参数**:
- `--port`: 服务器端口（默认：8080）

启动成功后，访问 `http://localhost:8080/api/health` 检查服务状态。

### 基础 URL

```
http://localhost:8080
```

### 认证

当前版本不需要认证。

### 响应格式

所有 API 响应使用 JSON 格式：

```json
{
  "status": "success",
  "data": { ... }
}
```

### 错误响应

```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述"
  }
}
```

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 404 | 资源未找到 |
| 500 | 服务器内部错误 |

---

## API 端点

### 健康检查

#### `GET /api/health`

检查服务器健康状态。

**请求**:
```http
GET /api/health HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "status": "ok",
  "service": "moonbit-drawdown"
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/health
```

---

### 股票列表

#### `GET /api/stocks`

获取可用股票列表。

**请求**:
```http
GET /api/stocks HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "stocks": [
    {
      "code": "sh.600000",
      "name": "Ping An Bank"
    },
    {
      "code": "sz.000001",
      "name": "Ping An Bank SZ"
    }
  ],
  "total": 2
}
```

**查询参数**:

| 参数 | 类型 | 说明 |
|------|------|------|
| `exchange` | string | 交易所筛选（sh/sz） |
| `limit` | int | 返回数量限制 |
| `offset` | int | 偏移量 |

**带参数示例**:
```bash
curl "http://localhost:8080/api/stocks?exchange=sh&limit=10"
```

---

### 股票详情

#### `GET /api/stocks/:code`

获取单个股票的详细信息。

**路径参数**:
- `code`: 股票代码（格式：`market.code`，如 `sh.600000`）

**请求**:
```http
GET /api/stocks/sh.600000 HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "stock": {
    "code": "sh.600000",
    "name": "Ping An Bank",
    "exchange": "SH",
    "sector": "金融",
    "industry": "银行"
  }
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/stocks/sh.600000
```

---

### K 线数据

#### `GET /api/stocks/:code/klines`

获取股票的 K 线数据。

**路径参数**:
- `code`: 股票代码

**查询参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `start` | string | - | 开始日期（YYYY-MM-DD） |
| `end` | string | - | 结束日期（YYYY-MM-DD） |
| `frequency` | string | `daily` | 频率（daily/weekly/monthly/5min/15min/30min/60min） |
| `limit` | int | 1000 | 返回数量限制 |
| `fields` | string | `all` | 返回字段（comma-separated） |

**请求**:
```http
GET /api/stocks/sh.600000/klines?start=2023-01-01&end=2023-12-31 HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "stock": "sh.600000",
  "klines": [
    {
      "date": "2023-01-03",
      "open": 10.50,
      "high": 10.85,
      "low": 10.42,
      "close": 10.78,
      "volume": 1250000,
      "amount": 13425000,
      "turn": 0.0125
    },
    {
      "date": "2023-01-04",
      "open": 10.80,
      "high": 11.02,
      "low": 10.75,
      "close": 10.95,
      "volume": 1380000,
      "amount": 15081000,
      "turn": 0.0138
    }
  ],
  "count": 2
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `date` | string | 日期 |
| `time` | string | 时间（分钟线需要） |
| `open` | float | 开盘价 |
| `high` | float | 最高价 |
| `low` | float | 最低价 |
| `close` | float | 收盘价 |
| `volume` | float | 成交量 |
| `amount` | float | 成交额 |
| `turn` | float | 换手率 |

**cURL 示例**:
```bash
# 获取日线数据
curl "http://localhost:8080/api/stocks/sh.600000/klines?start=2023-01-01&end=2023-12-31"

# 获取 5 分钟线数据
curl "http://localhost:8080/api/stocks/sh.600000/klines?frequency=5min&start=2023-01-01"

# 限制返回数量
curl "http://localhost:8080/api/stocks/sh.600000/klines?limit=100"
```

---

### 运行回测

#### `POST /api/backtest`

运行策略回测。

**请求体参数**:

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `stock_code` | string | - | 是 | 股票代码 |
| `strategy` | string | - | 是 | 策略名称 |
| `start_date` | string | - | 是 | 开始日期 |
| `end_date` | string | - | 是 | 结束日期 |
| `initial_capital` | float | 100000 | 否 | 初始资金 |
| `commission_rate` | float | 0.0003 | 否 | 手续费率 |
| `slippage` | float | 0.001 | 否 | 滑点 |
| `benchmark` | string | null | 否 | 基准代码 |
| `risk_rules` | array | [] | 否 | 风控规则配置 |

**请求**:
```http
POST /api/backtest HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "stock_code": "sh.600000",
  "strategy": "ma_cross",
  "start_date": "2023-01-01",
  "end_date": "2023-12-31",
  "initial_capital": 100000,
  "commission_rate": 0.0003,
  "slippage": 0.001
}
```

**响应** (异步模式):
```json
{
  "status": "started",
  "backtest_id": "bt_20240327_001"
}
```

**响应** (同步模式):
```json
{
  "status": "completed",
  "result": {
    "initial_capital": 100000,
    "final_capital": 115000,
    "total_return": 0.15,
    "max_drawdown": -0.085,
    "sharpe_ratio": 1.25,
    "total_trades": 24,
    "win_rate": 0.625,
    "profit_factor": 1.85,
    "annual_return": 0.15,
    "sortino_ratio": 1.45,
    "stats": {
      "winning_trades": 15,
      "losing_trades": 9,
      "avg_win": 0.025,
      "avg_loss": -0.012,
      "avg_trade_duration": 5.5
    },
    "trades": [
      {
        "stock": "sh.600000",
        "action": "buy",
        "price": 10.50,
        "quantity": 9500,
        "timestamp": "2023-01-10",
        "commission": 29.93
      }
    ],
    "equity_curve": [
      {
        "date": "2023-01-03",
        "equity": 100000,
        "drawdown": 0,
        "position": 0,
        "cash": 100000
      }
    ]
  }
}
```

**可用策略**:

| 策略名 | 说明 |
|--------|------|
| `ma_cross` | 均线交叉策略 |
| `momentum` | 动量策略 |
| `rsi_mean_reversion` | RSI 均值回归策略 |

**风控规则配置**:

```json
{
  "risk_rules": [
    {
      "name": "max_drawdown",
      "params": {
        "threshold": 0.2
      }
    },
    {
      "name": "position_limit",
      "params": {
        "max_ratio": 0.95
      }
    },
    {
      "name": "stop_loss",
      "params": {
        "threshold": 0.05
      }
    }
  ]
}
```

**cURL 示例**:
```bash
curl -X POST http://localhost:8080/api/backtest \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "sh.600000",
    "strategy": "ma_cross",
    "start_date": "2023-01-01",
    "end_date": "2023-12-31",
    "initial_capital": 100000
  }'
```

---

### 获取回测结果

#### `GET /api/backtest/:id`

获取回测结果（异步模式）。

**路径参数**:
- `id`: 回测 ID

**请求**:
```http
GET /api/backtest/bt_20240327_001 HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "backtest_id": "bt_20240327_001",
  "status": "completed",
  "created_at": "2023-03-27T10:30:00Z",
  "completed_at": "2023-03-27T10:30:05Z",
  "result": {
    "initial_capital": 100000,
    "final_capital": 115000,
    "total_return": 0.15,
    "max_drawdown": -0.085,
    "sharpe_ratio": 1.25
  }
}
```

**状态值**:
- `pending`: 等待执行
- `running`: 正在执行
- `completed`: 执行完成
- `failed`: 执行失败

**cURL 示例**:
```bash
curl http://localhost:8080/api/backtest/bt_20240327_001
```

---

### 个股回撤分析

#### `GET /api/drawdown/:code`

计算并获取个股的回撤分析。

**路径参数**:
- `code`: 股票代码

**查询参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `start` | string | - | 开始日期 |
| `end` | string | - | 结束日期 |
| `metric` | string | `all` | 分析指标（max_drawdown/current_drawdown/avg_drawdown/all） |

**请求**:
```http
GET /api/drawdown/sh.600000?start=2023-01-01&end=2023-12-31 HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "stock": "sh.600000",
  "drawdown": {
    "current": -0.0245,
    "max": -0.1523,
    "avg": -0.0456,
    "peak_date": "2023-08-15",
    "trough_date": "2023-10-20",
    "duration_days": 66,
    "recovered": true
  },
  "analysis": {
    "max_drawdown_periods": [
      {
        "peak": 15.85,
        "trough": 13.43,
        "drawdown": -0.1523,
        "peak_date": "2023-08-15",
        "trough_date": "2023-10-20",
        "duration": 66,
        "recovered": true,
        "recovery_date": "2023-12-05"
      }
    ],
    "drawdown_distribution": {
      "minor_count": 5,
      "moderate_count": 2,
      "significant_count": 1,
      "severe_count": 0
    }
  }
}
```

**回撤级别分类**:

| 级别 | 回撤范围 | 说明 |
|------|----------|------|
| `normal` | < 5% | 正常波动 |
| `minor` | 5% - 10% | 轻度回撤 |
| `moderate` | 10% - 20% | 中度回撤 |
| `significant` | 20% - 30% | 显著回撤 |
| `severe` | > 30% | 严重回撤 |

**cURL 示例**:
```bash
# 获取最大回撤
curl "http://localhost:8080/api/drawdown/sh.600000?metric=max_drawdown"

# 获取全部分析
curl "http://localhost:8080/api/drawdown/sh.600000?metric=all"

# 指定日期范围
curl "http://localhost:8080/api/drawdown/sh.600000?start=2023-01-01&end=2023-06-30"
```

---

### 组合回撤分析

#### `GET /api/portfolio/drawdown`

计算投资组合的整体回撤。

**查询参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `stocks` | string | - | 股票代码列表（comma-separated） |
| `weights` | string | `equal` | 权重配置（equal 或 comma-separated） |

**请求**:
```http
GET /api/portfolio/drawdown?stocks=sh.600000,sz.000001&weights=0.6,0.4 HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "portfolio": {
    "stocks": [
      {"code": "sh.600000", "weight": 0.6},
      {"code": "sz.000001", "weight": 0.4}
    ],
    "total_drawdown": -0.0532,
    "max_drawdown": -0.1245,
    "avg_drawdown": -0.0312
  },
  "contribution": [
    {
      "stock": "sh.600000",
      "weight": 0.6,
      "drawdown_contribution": -0.0320
    },
    {
      "stock": "sz.000001",
      "weight": 0.4,
      "drawdown_contribution": -0.0212
    }
  ]
}
```

**cURL 示例**:
```bash
# 等权重组合
curl "http://localhost:8080/api/portfolio/drawdown?stocks=sh.600000,sz.000001"

# 自定义权重
curl "http://localhost:8080/api/portfolio/drawdown?stocks=sh.600000,sz.000001&weights=0.7,0.3"
```

---

## WebSocket API (待实现)

### 实时监控

#### `WS /ws/monitor/:code`

实时监控股票回撤。

**路径参数**:
- `code`: 股票代码

**连接示例**:
```javascript
const ws = new WebSocket('ws://localhost:8080/ws/monitor/sh.600000');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('更新:', data);
  // {
  //   "type": "drawdown_update",
  //   "stock": "sh.600000",
  //   "current_price": 10.85,
  //   "current_drawdown": -0.0245,
  //   "alert_level": "normal"
  // }
};
```

---

## 股票策略 API

### 获取股票列表（增强版）

#### `GET /api/stocks/filter`

获取筛选后的股票列表。

**查询参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `industry` | string | - | 行业筛选 |
| `exchange` | string | - | 交易所筛选（sh/sz） |
| `min_market_cap` | float | - | 最小市值 |
| `max_market_cap` | float | - | 最大市值 |
| `min_pe_ratio` | float | - | 最小市盈率 |
| `max_pe_ratio` | float | - | 最大市盈率 |
| `limit` | int | `100` | 返回数量限制 |

**请求**:
```http
GET /api/stocks/filter?industry=银行&exchange=sh HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "stocks": [
    {
      "code": "sh.600000",
      "name": "浦发银行",
      "exchange": "SH",
      "industry": "银行",
      "market_cap": 285000000000,
      "pe_ratio": 5.23
    },
    {
      "code": "sh.600001",
      "name": "邯郸钢铁",
      "exchange": "SH",
      "industry": "钢铁",
      "market_cap": 45000000000,
      "pe_ratio": 8.12
    }
  ],
  "total": 2,
  "filters": {
    "industry": "银行",
    "exchange": "sh"
  }
}
```

**cURL 示例**:
```bash
# 按行业筛选
curl "http://localhost:8080/api/stocks/filter?industry=银行"

# 按交易所和市值筛选
curl "http://localhost:8080/api/stocks/filter?exchange=sh&min_market_cap=100000000000"
```

---

### 获取行业列表

#### `GET /api/industries`

获取所有行业分类列表。

**请求**:
```http
GET /api/industries HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "industries": [
    {
      "code": "J66",
      "name": "货币金融服务",
      "count": 45
    },
    {
      "code": "C26",
      "name": "化学原料和化学制品制造业",
      "count": 128
    }
  ],
  "total": 97
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/industries
```

---

### 获取行业成分股

#### `GET /api/industries/:industry/stocks`

获取某个行业的所有成分股。

**路径参数**:
- `industry`: 行业代码或名称

**查询参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `limit` | int | `100` | 返回数量限制 |
| `offset` | int | `0` | 偏移量 |

**请求**:
```http
GET /api/industries/货币金融服务业/stocks HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "industry": "货币金融服务业",
  "stocks": [
    {
      "code": "sh.600000",
      "name": "浦发银行",
      "weight": 0.085
    },
    {
      "code": "sh.600001",
      "name": "工商银行",
      "weight": 0.125
    }
  ],
  "total": 45
}
```

**cURL 示例**:
```bash
# 获取银行业成分股
curl "http://localhost:8080/api/industries/银行/stocks"

# 获取保险业成分股
curl "http://localhost:8080/api/industries/保险业/stocks"
```

---

### 策略列表

#### `GET /api/strategies`

获取所有可用策略列表。

**请求**:
```http
GET /api/strategies HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "strategies": [
    {
      "name": "ma_cross",
      "description": "均线交叉策略 - 当快均线上穿慢均线时买入，下穿时卖出",
      "default_parameters": {
        "fast_period": 10,
        "slow_period": 30
      },
      "category": "trend_following"
    },
    {
      "name": "momentum",
      "description": "动量策略 - 买入近期表现强劲的股票",
      "default_parameters": {
        "lookback_period": 20,
        "threshold": 0.05
      },
      "category": "momentum"
    },
    {
      "name": "rsi_mean_reversion",
      "description": "RSI 均值回归策略 - 超卖时买入，超买时卖出",
      "default_parameters": {
        "rsi_period": 14,
        "oversold": 30,
        "overbought": 70
      },
      "category": "mean_reversion"
    }
  ],
  "total": 3
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/strategies
```

---

### 获取策略详情

#### `GET /api/strategies/:id`

获取单个策略的详细信息。

**路径参数**:
- `id`: 策略名称

**请求**:
```http
GET /api/strategies/ma_cross HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "id": "ma_cross",
  "name": "均线交叉策略",
  "description": "均线交叉策略 - 当快均线上穿慢均线时买入，下穿时卖出",
  "parameters": {
    "fast_period": 10,
    "slow_period": 30
  },
  "category": "trend_following",
  "is_builtin": true
}
```

**cURL 示例**:
```bash
# 获取均线交叉策略详情
curl http://localhost:8080/api/strategies/ma_cross

# 获取动量策略详情
curl http://localhost:8080/api/strategies/momentum
```

---

### 创建自定义策略

#### `POST /api/strategies`

创建用户自定义策略。

**请求体**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 策略名称 |
| `description` | string | 否 | 策略描述 |
| `strategy_type` | string | 是 | 策略类型 |
| `parameters` | object | 是 | 策略参数配置 |

**请求**:
```http
POST /api/strategies HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "my_ma_strategy",
  "description": "自定义均线策略",
  "strategy_type": "ma_cross",
  "parameters": {
    "fast_period": 5,
    "slow_period": 20
  }
}
```

**响应**:
```json
{
  "status": "created",
  "strategy_id": "usr_ma_001",
  "name": "my_ma_strategy"
}
```

**cURL 示例**:
```bash
curl -X POST http://localhost:8080/api/strategies \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my_strategy",
    "strategy_type": "ma_cross",
    "parameters": {"fast_period": 5, "slow_period": 20}
  }'
```

---

### 更新策略

#### `PUT /api/strategies/:id`

更新现有策略配置。

**路径参数**:
- `id`: 策略 ID

**请求体**:

```json
{
  "name": "updated_strategy_name",
  "parameters": {
    "fast_period": 8,
    "slow_period": 25
  }
}
```

**响应**:
```json
{
  "status": "updated",
  "strategy_id": "usr_ma_001"
}
```

**cURL 示例**:
```bash
curl -X PUT http://localhost:8080/api/strategies/usr_ma_001 \
  -H "Content-Type: application/json" \
  -d '{"parameters": {"fast_period": 8}}'
```

---

### 删除策略

#### `DELETE /api/strategies/:id`

删除自定义策略。

**路径参数**:
- `id`: 策略 ID

**响应**:
```json
{
  "status": "deleted",
  "strategy_id": "usr_ma_001"
}
```

**cURL 示例**:
```bash
curl -X DELETE http://localhost:8080/api/strategies/usr_ma_001
```

---

## 选股指标 API

### 获取所有指标列表

#### `GET /api/indicators`

获取所有可用的选股指标。

**请求**:
```http
GET /api/indicators HTTP/1.1
Host: localhost:8080
```

**响应**:
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
      "id": "macd",
      "name": "MACD",
      "category": "technical",
      "unit": "price"
    },
    {
      "id": "rsi",
      "name": "RSI",
      "category": "technical",
      "unit": "index"
    },
    {
      "id": "kdj",
      "name": "KDJ",
      "category": "technical",
      "unit": "index"
    }
  ],
  "total": 8
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/indicators
```

---

### 按分类获取指标

#### `GET /api/indicators/:category`

按分类获取指标列表，支持的分类：`financial`（财务）、`technical`（技术）、`market`（市场）。

**路径参数**:
- `category`: 指标分类

**请求**:
```http
GET /api/indicators/technical HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "category": "technical",
  "indicators": [
    {
      "id": "macd",
      "name": "MACD",
      "category": "technical",
      "unit": "price",
      "description": "Moving Average Convergence Divergence"
    },
    {
      "id": "rsi",
      "name": "RSI",
      "category": "technical",
      "unit": "index",
      "description": "Relative Strength Index"
    },
    {
      "id": "kdj",
      "name": "KDJ",
      "category": "technical",
      "unit": "index",
      "description": "Stochastic Oscillator"
    },
    {
      "id": "ma",
      "name": "Moving Average",
      "category": "technical",
      "unit": "price",
      "description": "Simple/Exponential Moving Average"
    },
    {
      "id": "bollinger",
      "name": "Bollinger Bands",
      "category": "technical",
      "unit": "price",
      "description": "Volatility bands"
    },
    {
      "id": "atr",
      "name": "ATR",
      "category": "technical",
      "unit": "price",
      "description": "Average True Range"
    }
  ],
  "total": 6
}
```

**cURL 示例**:
```bash
# 获取技术指标
curl http://localhost:8080/api/indicators/technical

# 获取财务指标
curl http://localhost:8080/api/indicators/financial

# 获取市场指标
curl http://localhost:8080/api/indicators/market

# 获取所有指标
curl http://localhost:8080/api/indicators/all
```

---

### 获取指标详情

#### `GET /api/indicators/:id`

获取单个指标的详细信息。

**路径参数**:
- `id`: 指标 ID

**请求**:
```http
GET /api/indicators/roe HTTP/1.1
Host: localhost:8080
```

**响应**:
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

**cURL 示例**:
```bash
# 获取 ROE 详情
curl http://localhost:8080/api/indicators/roe

# 获取 MACD 详情
curl http://localhost:8080/api/indicators/macd

# 获取 RSI 详情
curl http://localhost:8080/api/indicators/rsi
```

---

### 执行选股筛选

#### `POST /api/screen`

执行选股筛选，返回符合条件的股票列表。

**请求体参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `min_roe` | float | 否 | 最小 ROE (%) |
| `min_np_margin` | float | 否 | 最小净利率 (%) |
| `min_eps` | float | 否 | 最小每股收益 |
| `min_price` | float | 否 | 最小价格 |
| `max_price` | float | 否 | 最大价格 |
| `min_volume` | float | 否 | 最小成交量 |
| `min_health` | string | 否 | 最小健康评级 |
| `sort_by` | string | 否 | 排序字段 |
| `sort_order` | string | 否 | 排序顺序 (asc/desc) |
| `limit` | int | 否 | 返回数量限制 |

**请求**:
```http
POST /api/screen HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "min_roe": 15.0,
  "min_np_margin": 10.0,
  "sort_by": "roe",
  "sort_order": "desc",
  "limit": 20
}
```

**响应**:
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

**cURL 示例**:
```bash
# 筛选 ROE > 15% 的股票
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{"min_roe": 15.0}'

# 综合筛选
curl -X POST http://localhost:8080/api/screen \
  -H "Content-Type: application/json" \
  -d '{
    "min_roe": 15.0,
    "min_np_margin": 10.0,
    "min_eps": 2.0,
    "sort_by": "roe",
    "sort_order": "desc",
    "limit": 20
  }'
```

---

### 获取交易模型列表

#### `GET /api/trading-models`

获取所有可用的交易模型。

**请求**:
```http
GET /api/trading-models HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "models": [
    {
      "id": "score_rank",
      "name": "综合评分排序模型",
      "description": "Based on multi-factor scoring and ranking",
      "model_type": "scoring",
      "parameters": ["weights", "normalize_method", "rank_method"],
      "output": "ranked_stock_list"
    },
    {
      "id": "cluster_select",
      "name": "聚类选股模型",
      "description": "Groups stocks using clustering algorithms, selects from best clusters",
      "model_type": "clustering",
      "parameters": ["n_clusters", "features", "selection_ratio"],
      "output": "cluster_assignments"
    },
    {
      "id": "ml_classifier",
      "name": "机器学习分类模型",
      "description": "ML-based classification for buy/hold/sell signals",
      "model_type": "classification",
      "parameters": ["model_type", "features", "thresholds"],
      "output": "signal_labels"
    },
    {
      "id": "factor_weighted",
      "name": "因子加权模型",
      "description": "Weighted combination of multiple factors",
      "model_type": "factor",
      "parameters": ["factor_weights", "normalization", "decay"],
      "output": "composite_scores"
    },
    {
      "id": "rule_based",
      "name": "规则筛选模型",
      "description": "Rule-based filtering with logical conditions",
      "model_type": "rule_engine",
      "parameters": ["rules", "logic_operator", "min_matches"],
      "output": "filtered_stocks"
    }
  ],
  "total": 5
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/trading-models
```

---

### 设置指标权重

#### `POST /api/weights`

设置选股指标的权重配置。

**请求体参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `weights` | array | 是 | 权重配置列表 |

**权重配置项**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `indicator` | string | 指标 ID |
| `weight` | float | 权重值 (0-1) |
| `direction` | string | 方向 (asc/desc/neutral) |

**请求**:
```http
POST /api/weights HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "weights": [
    {
      "indicator": "roe",
      "weight": 0.3,
      "direction": "asc"
    },
    {
      "indicator": "np_margin",
      "weight": 0.2,
      "direction": "asc"
    },
    {
      "indicator": "pe_ratio",
      "weight": 0.2,
      "direction": "desc"
    },
    {
      "indicator": "rsi",
      "weight": 0.15,
      "direction": "neutral"
    },
    {
      "indicator": "macd",
      "weight": 0.15,
      "direction": "asc"
    }
  ]
}
```

**响应**:
```json
{
  "status": "configured",
  "message": "Weights saved successfully",
  "note": "Persistence not yet implemented"
}
```

**cURL 示例**:
```bash
curl -X POST http://localhost:8080/api/weights \
  -H "Content-Type: application/json" \
  -d '{
    "weights": [
      {"indicator": "roe", "weight": 0.3, "direction": "asc"},
      {"indicator": "np_margin", "weight": 0.2, "direction": "asc"}
    ]
  }'
```

---

### 获取当前权重配置

#### `GET /api/weights`

获取当前的指标权重配置。

**请求**:
```http
GET /api/weights HTTP/1.1
Host: localhost:8080
```

**响应**:
```json
{
  "weights": [
    {
      "indicator": "roe",
      "weight": 0.3,
      "direction": "asc"
    },
    {
      "indicator": "np_margin",
      "weight": 0.2,
      "direction": "asc"
    },
    {
      "indicator": "eps",
      "weight": 0.2,
      "direction": "asc"
    },
    {
      "indicator": "pe_ratio",
      "weight": 0.15,
      "direction": "desc"
    },
    {
      "indicator": "rsi",
      "weight": 0.15,
      "direction": "neutral"
    }
  ]
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/weights
```

---

## 批量操作 (待实现)

### 批量回测

#### `POST /api/backtest/batch`

批量运行多个回测。

**请求体**:

```json
{
  "backtests": [
    {
      "stock_code": "sh.600000",
      "strategy": "ma_cross",
      "start_date": "2023-01-01",
      "end_date": "2023-12-31"
    },
    {
      "stock_code": "sz.000001",
      "strategy": "momentum",
      "start_date": "2023-01-01",
      "end_date": "2023-12-31"
    }
  ]
}
```

**响应**:
```json
{
  "status": "accepted",
  "batch_id": "batch_20240327_001",
  "count": 2
}
```

---

## 错误码参考

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `INVALID_STOCK_CODE` | 400 | 无效的股票代码 |
| `DATA_NOT_FOUND` | 404 | 数据未找到 |
| `INVALID_DATE_RANGE` | 400 | 日期范围无效 |
| `STRATEGY_NOT_FOUND` | 404 | 策略未找到 |
| `INSUFFICIENT_DATA` | 400 | 数据不足 |
| `BACKTEST_FAILED` | 500 | 回测执行失败 |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |

---

## 使用示例

### JavaScript/Node.js

```javascript
const API_BASE = 'http://localhost:8080/api';

// 获取 K 线数据
async function getKlines(stockCode, startDate, endDate) {
  const response = await fetch(
    `${API_BASE}/stocks/${stockCode}/klines?start=${startDate}&end=${endDate}`
  );
  return response.json();
}

// 运行回测
async function runBacktest(config) {
  const response = await fetch(`${API_BASE}/backtest`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config)
  });
  return response.json();
}

// 获取回撤分析
async function getDrawdown(stockCode) {
  const response = await fetch(`${API_BASE}/drawdown/${stockCode}`);
  return response.json();
}

// 使用示例
(async () => {
  const klines = await getKlines('sh.600000', '2023-01-01', '2023-12-31');
  console.log('K 线数据:', klines.count, '条');

  const backtest = await runBacktest({
    stock_code: 'sh.600000',
    strategy: 'ma_cross',
    start_date: '2023-01-01',
    end_date: '2023-12-31',
    initial_capital: 100000
  });
  console.log('回测结果:', backtest.result);

  const drawdown = await getDrawdown('sh.600000');
  console.log('最大回撤:', drawdown.drawdown.max * 100 + '%');
})();
```

### Python

```python
import requests

API_BASE = 'http://localhost:8080/api'

def get_klines(stock_code, start_date, end_date):
    """获取 K 线数据"""
    response = requests.get(
        f'{API_BASE}/stocks/{stock_code}/klines',
        params={'start': start_date, 'end': end_date}
    )
    return response.json()

def run_backtest(config):
    """运行回测"""
    response = requests.post(
        f'{API_BASE}/backtest',
        json=config,
        headers={'Content-Type': 'application/json'}
    )
    return response.json()

def get_drawdown(stock_code):
    """获取回撤分析"""
    response = requests.get(f'{API_BASE}/drawdown/{stock_code}')
    return response.json()

# 使用示例
if __name__ == '__main__':
    # 获取 K 线数据
    klines = get_klines('sh.600000', '2023-01-01', '2023-12-31')
    print(f"K 线数据：{klines['count']} 条")

    # 运行回测
    backtest_config = {
        'stock_code': 'sh.600000',
        'strategy': 'ma_cross',
        'start_date': '2023-01-01',
        'end_date': '2023-12-31',
        'initial_capital': 100000
    }
    result = run_backtest(backtest_config)
    print(f"总收益率：{result['result']['total_return'] * 100:.2f}%")

    # 获取回撤分析
    drawdown = get_drawdown('sh.600000')
    print(f"最大回撤：{drawdown['drawdown']['max'] * 100:.2f}%")
```

---

## 股票筛选 API

完整的股票筛选系统 API 规范，请参阅：
- [股票筛选系统 API 规范](api/stock-screener-api.md) - 完整的 API 接口设计文档

### 实现状态

**后端实现**: 🟢 已完成 (2026-03-28)
- 核心代码：`src/server/routes/screen.mbt`
- 路由配置：`src/server/routes/router.mbt`
- 编译状态：`moon build` 通过

### 已实现的端点

#### 1. 股票筛选端点

| 端点 | 方法 | 状态 | 说明 |
|------|------|------|------|
| `/api/screen/stocks` | GET/POST | 🟢 已完成 | 执行筛选，返回结果 |
| `/api/screen/config` | POST | 🟢 已完成 | 保存筛选配置 |
| `/api/screen/config` | GET | 🟢 已完成 | 获取筛选配置列表 |
| `/api/screen/config/:id` | GET | 🟢 已完成 | 获取特定配置详情 |
| `/api/screen/weights` | PUT | 🟢 已完成 | 更新指标权重 |

#### 2. 指标元数据端点

| 端点 | 方法 | 状态 | 说明 |
|------|------|------|------|
| `/api/indicators/market` | GET | 🟢 已完成 | 获取行情指标列表 |
| `/api/indicators/technical` | GET | 🟢 已完成 | 获取技术指标列表 |
| `/api/indicators/financial` | GET | 🟢 已完成 | 获取财务指标列表 |
| `/api/indicators/descriptions` | GET | 🟢 已完成 | 获取所有指标说明 |
| `/api/indicators/:id` | GET | 🟢 已完成 | 获取单个指标详情 |

#### 3. 交易模型端点

| 端点 | 方法 | 状态 | 说明 |
|------|------|------|------|
| `/api/trading-model/config` | POST | 🟢 已完成 | 配置交易模型 |
| `/api/trading-model/config` | GET | 🟢 已完成 | 获取交易模型配置列表 |
| `/api/trading-model/config/:id` | GET | 🟢 已完成 | 获取特定配置详情 |
| `/api/trading-model/simulate` | POST | 🟢 已完成 | 模拟交易结果 |

### 支持的指标类型

#### 行情指标 (Market Indicators)
- 价格 (price)
- 成交量 (volume)
- 成交额 (turnover)
- 换手率 (turnover_rate)
- 涨跌幅 (change_percent)

#### 技术指标 (Technical Indicators)
- MACD (12, 26, 9)
- RSI (14)
- KDJ (9, 3, 3)
- MA (可配置周期)
- Bollinger (20, 2.0)
- ATR (14)

#### 财务指标 (Financial Indicators)
- ROE (净资产收益率)
- 净利率 (np_margin)
- 毛利率 (gross_margin)
- EPS (每股收益)
- 营收 (revenue)
- 股本 (share_capital)

### 筛选条件参数

| 参数 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `min_roe` | float | 最小 ROE (%) | `15.0` |
| `min_np_margin` | float | 最小净利率 (%) | `10.0` |
| `min_eps` | float | 最小每股收益 | `2.0` |
| `min_price` | float | 最小价格 | `10.0` |
| `max_price` | float | 最大价格 | `100.0` |
| `min_volume` | float | 最小成交量 | `1000000.0` |
| `sort_by` | string | 排序字段 | `"score"` |
| `sort_order` | string | 排序顺序 | `"desc"` |
| `limit` | int | 结果数量限制 | `50` |

### 交易模型配置

#### 周期调仓模型

```json
{
  "model_type": "periodic",
  "period": "weekly",
  "rebalance_day": 1,
  "stock_count": 10,
  "filters": [
    {"indicator": "roe", "operator": ">", "value": 15}
  ]
}
```

**支持周期**:
- `weekly` - 周调仓
- `monthly` - 月调仓
- `quarterly` - 季度调仓

#### 条件触发模型

```json
{
  "model_type": "condition",
  "entry_conditions": [
    {"indicator": "macd", "signal": "bullish_crossover"}
  ],
  "exit_conditions": [
    {"indicator": "rsi", "operator": ">", "value": 70}
  ],
  "position_limit": 0.8
}
```

### API 调用示例

#### cURL 示例

```bash
# 执行股票筛选
curl -X POST http://localhost:8080/api/screen/stocks \
  -H "Content-Type: application/json" \
  -d '{
    "min_roe": 15.0,
    "min_np_margin": 10.0,
    "sort_by": "score",
    "sort_order": "desc",
    "limit": 20
  }'

# 获取行情指标列表
curl http://localhost:8080/api/indicators/market

# 获取技术指标列表
curl http://localhost:8080/api/indicators/technical

# 配置交易模型
curl -X POST http://localhost:8080/api/trading-model/config \
  -H "Content-Type: application/json" \
  -d '{
    "model_type": "periodic",
    "period": "weekly",
    "stock_count": 10
  }'
```

#### JavaScript 示例

```javascript
const API_BASE = 'http://localhost:8080/api';

// 执行股票筛选
async function screenStocks(criteria) {
  const response = await fetch(`${API_BASE}/screen/stocks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(criteria)
  });
  return response.json();
}

// 获取指标列表
async function getIndicators(category) {
  const response = await fetch(`${API_BASE}/indicators/${category}`);
  return response.json();
}

// 配置交易模型
async function configureTradingModel(config) {
  const response = await fetch(`${API_BASE}/trading-model/config`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config)
  });
  return response.json();
}

// 使用示例
(async () => {
  // 筛选 ROE > 15% 的股票
  const results = await screenStocks({
    min_roe: 15.0,
    limit: 20
  });
  console.log('筛选结果:', results.total, '只股票');

  // 获取技术指标列表
  const indicators = await getIndicators('technical');
  console.log('技术指标:', indicators.total, '个');

  // 配置周调仓模型
  const model = await configureTradingModel({
    model_type: 'periodic',
    period: 'weekly',
    stock_count: 10
  });
  console.log('模型配置 ID:', model.config_id);
})();
```

#### Python 示例

```python
import requests

API_BASE = 'http://localhost:8080/api'

def screen_stocks(criteria):
    """执行股票筛选"""
    response = requests.post(
        f'{API_BASE}/screen/stocks',
        json=criteria,
        headers={'Content-Type': 'application/json'}
    )
    return response.json()

def get_indicators(category):
    """获取指标列表"""
    response = requests.get(f'{API_BASE}/indicators/{category}')
    return response.json()

def configure_trading_model(config):
    """配置交易模型"""
    response = requests.post(
        f'{API_BASE}/trading-model/config',
        json=config,
        headers={'Content-Type': 'application/json'}
    )
    return response.json()

# 使用示例
if __name__ == '__main__':
    # 筛选高 ROE 股票
    results = screen_stocks({
        'min_roe': 15.0,
        'min_np_margin': 10.0,
        'limit': 20
    })
    print(f"筛选结果：{results['total']} 只股票")

    # 获取技术指标
    indicators = get_indicators('technical')
    print(f"技术指标：{indicators['total']} 个")

    # 配置交易模型
    model = configure_trading_model({
        'model_type': 'periodic',
        'period': 'monthly',
        'stock_count': 10
    })
    print(f"模型配置 ID: {model['config_id']}")
```

---

## 更新日志

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 1.4 | 2026-03-28 | **后端实现完成**：8 个端点全部实现，编译通过，支持 N 日指标计算和周期调仓 |
| 1.3 | 2026-03-28 | 更新股票筛选系统 API 规范，新增端点：/api/screen/stocks, /api/screen/config, /api/screen/weights, /api/indicators/market, /api/indicators/technical, /api/indicators/financial, /api/indicators/descriptions, /api/trading-model/config, /api/trading-model/simulate |
| 1.2 | 2026-03-28 | 新增股票筛选 API 完整文档，包括技术指标、交易模型和权重配置 |
| 1.1 | 2026-03-28 | 新增选股指标 API：/api/indicators, /api/screen, /api/trading-models, /api/weights |
| 1.0 | 2026-03-27 | 初始版本，包含核心 API 端点 |

---

*最后更新：2026-03-28*
