# 股票筛选系统 API 规范

**版本**: 1.1
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

本文档定义了股票筛选系统的完整 API 接口规范，包括筛选配置、指标元数据、权重配置和交易模型接口。

---

## 目录

1. [概述](#概述)
2. [股票筛选 API](#股票筛选-api)
3. [指标元数据 API](#指标元数据-api)
4. [交易模型 API](#交易模型-api)
5. [请求/响应格式](#请求响应格式)
6. [错误码参考](#错误码参考)
7. [使用示例](#使用示例)

---

## 概述

股票筛选系统 API 允许用户基于技术指标、财务指标和自定义条件筛选股票，支持配置保存、权重调整和交易模型集成。

### 基础 URL

```
http://localhost:8080/api
```

### 启动服务器

```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run alpha
```

### 认证

当前版本不需要认证。

### 指标分类

| 分类 | 说明 | 示例 |
|------|------|------|
| market (行情指标) | 实时市场数据 | 价格、成交量、换手率 |
| technical (技术指标) | 技术分析指标 | MACD, RSI, KDJ, MA |
| financial (财务指标) | 公司财务数据 | ROE, 净利润率，EPS |

---

## 股票筛选 API

### 执行筛选

#### `GET /api/screen/stocks`

执行筛选，返回符合条件的股票列表。

**查询参数**:

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `min_roe` | float | - | 最小 ROE (%) |
| `min_np_margin` | float | - | 最小净利率 (%) |
| `min_eps` | float | - | 最小每股收益 |
| `min_price` | float | - | 最小价格 |
| `max_price` | float | - | 最大价格 |
| `min_volume` | float | - | 最小成交量 |
| `sort_by` | string | `score` | 排序字段 |
| `sort_order` | string | `desc` | 排序顺序 (asc/desc) |
| `limit` | int | `100` | 返回数量限制 |

**请求**:

```http
GET /api/screen/stocks?min_roe=15.0&min_eps=2.0&limit=50 HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "screen_id": "scr_20260328_001",
  "timestamp": "2026-03-28T10:30:00Z",
  "results": {
    "total_matches": 45,
    "returned": 45,
    "stocks": [
      {
        "code": "sh.600001",
        "name": "Stock 600001",
        "score": 90.0,
        "rank": 1,
        "indicators": {
          "roe": 25.0,
          "np_margin": 18.0,
          "eps": 3.5,
          "price": 15.8,
          "volume": 1500000.0
        },
        "health": "Excellent"
      }
    ]
  }
}
```

**cURL 示例**:

```bash
curl "http://localhost:8080/api/screen/stocks?min_roe=15.0&min_eps=2.0&limit=50"
```

---

### 保存筛选配置

#### `POST /api/screen/config`

保存筛选配置以便重复使用。

**请求体参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 配置名称 |
| `description` | string | 否 | 配置描述 |
| `filters` | object | 是 | 筛选条件 |
| `weights` | object | 否 | 指标权重 |
| `is_public` | bool | 否 | 是否公开 (默认：false) |

**请求**:

```http
POST /api/screen/config HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "高 ROE 成长股",
  "description": "筛选高 ROE 且利润率增长强劲的股票",
  "filters": {
    "min_roe": 20.0,
    "min_np_margin": 15.0,
    "min_eps": 1.5
  },
  "weights": {
    "roe": 0.4,
    "np_margin": 0.3,
    "eps": 0.3
  },
  "is_public": false
}
```

**响应**:

```json
{
  "status": "created",
  "config_id": "cfg_20260328_001",
  "name": "高 ROE 成长股"
}
```

---

### 获取筛选配置

#### `GET /api/screen/config`

获取已保存的筛选配置列表。

**请求**:

```http
GET /api/screen/config HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "configs": [
    {
      "config_id": "cfg_20260328_001",
      "name": "高 ROE 成长股",
      "description": "筛选高 ROE 且利润率增长强劲的股票",
      "created_at": "2026-03-28T10:30:00Z",
      "updated_at": "2026-03-28T10:30:00Z",
      "is_public": false,
      "criteria_summary": {
        "filter_count": 3,
        "weight_count": 3
      }
    }
  ],
  "total": 1
}
```

#### `GET /api/screen/config/:id`

获取特定筛选配置的详细信息。

**路径参数**: `id` - 配置 ID

**请求**:

```http
GET /api/screen/config/cfg_20260328_001 HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "config": {
    "config_id": "cfg_20260328_001",
    "name": "高 ROE 成长股",
    "filters": {
      "min_roe": 20.0,
      "min_np_margin": 15.0,
      "min_eps": 1.5
    },
    "weights": {
      "roe": 0.4,
      "np_margin": 0.3,
      "eps": 0.3
    },
    "last_run": "2026-03-28T11:00:00Z",
    "last_results_count": 12
  }
}
```

---

### 更新权重配置

#### `PUT /api/screen/weights`

更新指标权重配置。

**请求体参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `weights` | array | 是 | 权重配置列表 |
| `name` | string | 否 | 配置名称 |
| `description` | string | 否 | 配置描述 |

**权重配置项**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `indicator` | string | 指标 ID |
| `weight` | float | 权重值 (0-1) |
| `direction` | string | 方向 (asc/desc/neutral) |

**请求**:

```http
PUT /api/screen/weights HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "name": "价值导向型",
  "weights": [
    {"indicator": "roe", "weight": 0.30, "direction": "asc"},
    {"indicator": "np_margin", "weight": 0.20, "direction": "asc"},
    {"indicator": "pe_ratio", "weight": 0.25, "direction": "desc"},
    {"indicator": "pb_ratio", "weight": 0.15, "direction": "desc"},
    {"indicator": "rsi", "weight": 0.10, "direction": "neutral"}
  ]
}
```

**响应**:

```json
{
  "status": "updated",
  "config_id": "wgt_usr_001",
  "validation": {"sum": 1.0, "valid": true}
}
```

---

## 指标元数据 API

### 获取行情指标

#### `GET /api/indicators/market`

获取行情指标列表（价格、成交量等市场数据）。

**请求**:

```http
GET /api/indicators/market HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "category": "market",
  "indicators": [
    {
      "id": "price",
      "name": "价格",
      "description": "当前市场价格",
      "unit": "CNY",
      "range": "0-inf"
    },
    {
      "id": "volume",
      "name": "成交量",
      "description": "交易股数",
      "unit": "shares",
      "range": "0-inf"
    },
    {
      "id": "market_cap",
      "name": "市值",
      "description": "总市值",
      "unit": "CNY",
      "range": "0-inf"
    },
    {
      "id": "pe_ratio",
      "name": "市盈率",
      "description": "股价与每股收益之比",
      "unit": "ratio",
      "range": "0-inf"
    },
    {
      "id": "pb_ratio",
      "name": "市净率",
      "description": "股价与每股净资产之比",
      "unit": "ratio",
      "range": "0-inf"
    },
    {
      "id": "dividend_yield",
      "name": "股息率",
      "description": "年度股息占股价百分比",
      "unit": "%",
      "range": "0-20%"
    },
    {
      "id": "turnover_rate",
      "name": "换手率",
      "description": "成交量占流通股本百分比",
      "unit": "%",
      "range": "0-100%"
    }
  ],
  "total": 7
}
```

---

### 获取技术指标

#### `GET /api/indicators/technical`

获取技术指标列表（MA、MACD、RSI、KDJ 等）。

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
      "id": "ma",
      "name": "移动平均线",
      "description": "简单或指数移动平均",
      "unit": "price",
      "parameters": {"period": {"type": "int", "default": 20}}
    },
    {
      "id": "macd",
      "name": "MACD",
      "description": "指数平滑异同移动平均线",
      "unit": "price",
      "parameters": {"fast": 12, "slow": 26, "signal": 9}
    },
    {
      "id": "rsi",
      "name": "RSI",
      "description": "相对强弱指数",
      "unit": "index",
      "range": "0-100",
      "parameters": {"period": 14}
    },
    {
      "id": "kdj",
      "name": "KDJ",
      "description": "随机指标",
      "unit": "index",
      "range": "0-100",
      "parameters": {"k_period": 9, "d_period": 3}
    },
    {
      "id": "bollinger",
      "name": "布林带",
      "description": "波动率带",
      "unit": "price",
      "parameters": {"period": 20, "std_dev": 2.0}
    },
    {
      "id": "atr",
      "name": "ATR",
      "description": "平均真实波幅",
      "unit": "price",
      "parameters": {"period": 14}
    }
  ],
  "total": 6
}
```

---

### 获取财务指标

#### `GET /api/indicators/financial`

获取财务指标列表（ROE、EPS、利润率等）。

**请求**:

```http
GET /api/indicators/financial HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "category": "financial",
  "indicators": [
    {
      "id": "roe",
      "name": "ROE",
      "description": "净资产收益率",
      "unit": "%",
      "range": "0-50%"
    },
    {
      "id": "np_margin",
      "name": "净利率",
      "description": "净利润占营收百分比",
      "unit": "%",
      "range": "0-30%"
    },
    {
      "id": "eps",
      "name": "每股收益",
      "description": "净利润除以总股本",
      "unit": "CNY",
      "range": "0-100"
    },
    {
      "id": "roa",
      "name": "ROA",
      "description": "总资产收益率",
      "unit": "%",
      "range": "0-30%"
    },
    {
      "id": "debt_to_equity",
      "name": "资产负债率",
      "description": "总负债除以股东权益",
      "unit": "ratio",
      "range": "0-5"
    },
    {
      "id": "revenue_growth",
      "name": "营收增长率",
      "description": "同比增长率",
      "unit": "%",
      "range": "-100-500%"
    }
  ],
  "total": 6
}
```

---

### 获取指标说明

#### `GET /api/indicators/descriptions`

获取所有指标的详细说明。

**请求**:

```http
GET /api/indicators/descriptions HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "indicators": {
    "market": [
      {
        "id": "price",
        "name": "价格",
        "description": "当前市场价格",
        "formula": "市场价格",
        "interpretation": "高价不一定代表优质投资"
      },
      {
        "id": "pe_ratio",
        "name": "市盈率",
        "description": "股价与每股收益之比",
        "formula": "P/E = 价格 / EPS",
        "interpretation": "低市盈率可能表示低估，高市盈率可能表示增长预期"
      }
    ],
    "technical": [
      {
        "id": "rsi",
        "name": "RSI",
        "description": "相对强弱指数",
        "formula": "RSI = 100 - (100 / (1 + RS))",
        "interpretation": ">70 超买，<30 超卖"
      },
      {
        "id": "macd",
        "name": "MACD",
        "description": "指数平滑异同移动平均线",
        "formula": "MACD 线=12EMA-26EMA, 信号线=9EMA of MACD",
        "interpretation": "金叉买入，死叉卖出"
      }
    ],
    "financial": [
      {
        "id": "roe",
        "name": "ROE",
        "description": "净资产收益率",
        "formula": "ROE = 净利润 / 股东权益 × 100%",
        "interpretation": ">15% 为优秀"
      }
    ]
  },
  "total_categories": 3,
  "total_indicators": 15
}
```

---

## 交易模型 API

### 配置交易模型

#### `POST /api/trading-model/config`

配置交易模型参数。

**请求体参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `model_id` | string | 是 | 交易模型 ID |
| `name` | string | 是 | 配置名称 |
| `parameters` | object | 是 | 模型参数 |
| `screen_config_id` | string | 否 | 关联筛选配置 ID |
| `weight_config_id` | string | 否 | 关联权重配置 ID |

**请求**:

```http
POST /api/trading-model/config HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "model_id": "score_rank",
  "name": "评分排序策略",
  "parameters": {
    "normalize_method": "minmax",
    "rank_method": "weighted"
  },
  "screen_config_id": "cfg_20260328_001",
  "weight_config_id": "wgt_usr_001"
}
```

**响应**:

```json
{
  "status": "created",
  "config_id": "tmc_20260328_001",
  "name": "评分排序策略"
}
```

---

### 获取交易模型配置

#### `GET /api/trading-model/config`

获取已保存的交易模型配置列表。

**请求**:

```http
GET /api/trading-model/config HTTP/1.1
Host: localhost:8080
```

**响应**:

```json
{
  "configs": [
    {
      "config_id": "tmc_20260328_001",
      "name": "评分排序策略",
      "model_id": "score_rank",
      "parameters": {
        "normalize_method": "minmax",
        "rank_method": "weighted"
      },
      "screen_config_id": "cfg_20260328_001",
      "weight_config_id": "wgt_usr_001",
      "created_at": "2026-03-28T10:30:00Z"
    }
  ],
  "total": 1
}
```

#### `GET /api/trading-model/config/:id`

获取特定交易模型配置的详细信息。

**路径参数**: `id` - 配置 ID

**响应**:

```json
{
  "config": {
    "config_id": "tmc_20260328_001",
    "name": "评分排序策略",
    "model_id": "score_rank",
    "last_run": "2026-03-28T11:00:00Z",
    "last_results": {
      "stocks_processed": 4500,
      "signals_generated": 45
    }
  }
}
```

---

### 模拟交易结果

#### `POST /api/trading-model/simulate`

模拟交易结果。

**请求体参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `config_id` | string | 是 | 交易模型配置 ID |
| `start_date` | string | 是 | 模拟开始日期 |
| `end_date` | string | 是 | 模拟结束日期 |
| `initial_capital` | float | 否 | 初始资金 (默认：100000) |
| `transaction_cost` | float | 否 | 交易费率 (默认：0.001) |

**请求**:

```http
POST /api/trading-model/simulate HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "config_id": "tmc_20260328_001",
  "start_date": "2025-01-01",
  "end_date": "2025-12-31",
  "initial_capital": 100000,
  "transaction_cost": 0.001
}
```

**响应**:

```json
{
  "simulation_id": "sim_20260328_001",
  "status": "completed",
  "period": {"start": "2025-01-01", "end": "2025-12-31", "trading_days": 245},
  "results": {
    "initial_capital": 100000,
    "final_capital": 125300,
    "total_return": 0.253,
    "max_drawdown": -0.085,
    "sharpe_ratio": 1.45,
    "total_trades": 48,
    "win_rate": 0.625
  },
  "equity_curve": [
    {"date": "2025-01-02", "equity": 100000, "drawdown": 0},
    {"date": "2025-01-03", "equity": 101200, "drawdown": 0}
  ],
  "trades": [
    {"date": "2025-01-06", "action": "buy", "stock": "sh.600001", "quantity": 1000, "price": 15.50}
  ]
}
```

---

## 请求/响应格式

### Content-Type

所有请求和响应使用 JSON 格式：

```
Content-Type: application/json
```

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 404 | 资源未找到 |
| 500 | 服务器内部错误 |

### 错误响应格式

```json
{
  "error": "错误描述信息"
}
```

---

## 错误码参考

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `INVALID_INDICATOR` | 400 | 无效的指标 ID |
| `INVALID_OPERATOR` | 400 | 无效的操作符 |
| `INVALID_WEIGHT_SUM` | 400 | 权重之和不等于 1.0 |
| `INVALID_DATE_RANGE` | 400 | 日期范围无效 |
| `INSUFFICIENT_DATA` | 400 | 数据不足 |
| `CONFIG_NOT_FOUND` | 404 | 配置未找到 |
| `MODEL_NOT_FOUND` | 404 | 模型未找到 |
| `SCREEN_NOT_FOUND` | 404 | 筛选配置未找到 |
| `SCREEN_EXECUTION_FAILED` | 500 | 筛选执行失败 |
| `SIMULATION_FAILED` | 500 | 模拟执行失败 |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |

---

## 使用示例

### 完整筛选流程

```bash
# 1. 获取技术指标
curl "http://localhost:8080/api/indicators/technical"

# 2. 获取财务指标
curl "http://localhost:8080/api/indicators/financial"

# 3. 执行筛选
curl "http://localhost:8080/api/screen/stocks?min_roe=15.0&min_eps=2.0&limit=50"

# 4. 保存筛选配置
curl -X POST "http://localhost:8080/api/screen/config" \
  -H "Content-Type: application/json" \
  -d '{"name": "高 ROE 筛选", "filters": {"min_roe": 15.0, "min_eps": 2.0}}'

# 5. 获取当前权重
curl "http://localhost:8080/api/screen/weights"

# 6. 更新权重
curl -X PUT "http://localhost:8080/api/screen/weights" \
  -H "Content-Type: application/json" \
  -d '{"weights": [{"indicator": "roe", "weight": 0.3, "direction": "asc"}]}'

# 7. 获取交易模型
curl "http://localhost:8080/api/trading-models"

# 8. 配置交易模型
curl -X POST "http://localhost:8080/api/trading-model/config" \
  -H "Content-Type: application/json" \
  -d '{"model_id": "score_rank", "name": "我的策略"}'

# 9. 运行模拟
curl -X POST "http://localhost:8080/api/trading-model/simulate" \
  -H "Content-Type: application/json" \
  -d '{"config_id": "tmc_xxx", "start_date": "2025-01-01", "end_date": "2025-12-31"}'
```

### JavaScript 示例

```javascript
const API_BASE = 'http://localhost:8080/api';

// 执行筛选
async function screenStocks(criteria) {
  const params = new URLSearchParams();
  if (criteria.min_roe) params.append('min_roe', criteria.min_roe);
  if (criteria.limit) params.append('limit', criteria.limit);

  const response = await fetch(`${API_BASE}/screen/stocks?${params}`);
  return response.json();
}

// 获取指标
async function getIndicators(category) {
  const response = await fetch(`${API_BASE}/indicators/${category}`);
  return response.json();
}

// 更新权重
async function updateWeights(weights) {
  const response = await fetch(`${API_BASE}/screen/weights`, {
    method: 'PUT',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({weights})
  });
  return response.json();
}
```

---

*最后更新：2026-03-28*
*文档维护者：API Architecture Team*
