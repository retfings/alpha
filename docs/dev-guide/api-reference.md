# API 参考文档

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [API 概述](#api-概述)
2. [股票筛选 API](#股票筛选-api)
3. [技术指标 API](#技术指标-api)
4. [回测 API](#回测-api)
5. [行情数据 API](#行情数据-api)
6. [错误码参考](#错误码参考)

---

## API 概述

### 基础信息

**基础 URL**:
```
http://localhost:8080/api
```

**启动服务器**:
```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run alpha
```

### 认证

当前版本不需要认证。

### 响应格式

所有 API 响应使用 JSON 格式：

**成功响应**:
```json
{
  "status": "success",
  "data": { ... }
}
```

**错误响应**:
```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": { ... }  // 可选
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

## 股票筛选 API

### 执行筛选

执行多维度股票筛选。

**端点**: `POST /api/screener/screen`

**请求体**:
```json
{
  "stock_pool": {
    "type": "industry",
    "value": "银行"
  },
  "fundamental_filters": [
    {
      "type": "max_pe",
      "value": 20
    },
    {
      "type": "min_roe",
      "value": 0.15
    }
  ],
  "technical_filters": [
    {
      "type": "price_above_ma",
      "period": 20
    }
  ],
  "sort": {
    "field": "market_cap",
    "order": "desc"
  }
}
```

**筛选器类型**:

| 类型 | 说明 | 参数 |
|------|------|------|
| `max_pe` | 最大市盈率 | `value`: 市盈率上限 |
| `min_pe` | 最小市盈率 | `value`: 市盈率下限 |
| `max_pb` | 最大市净率 | `value`: 市净率上限 |
| `min_pb` | 最小市净率 | `value`: 市净率下限 |
| `min_market_cap` | 最小市值 | `value`: 市值下限 (元) |
| `max_market_cap` | 最大市值 | `value`: 市值上限 (元) |
| `min_roe` | 最小 ROE | `value`: ROE 下限 |
| `min_revenue_growth` | 最小营收增长 | `value`: 增长率下限 |
| `price_above_ma` | 价格在均线上方 | `period`: 均线周期 |
| `macd_bullish` | MACD 金叉 | - |
| `rsi_oversold` | RSI 超卖 | `threshold`: 超卖阈值 |

**响应**:
```json
{
  "status": "success",
  "data": {
    "stocks": [
      {
        "code": "sh.600000",
        "name": "浦发银行",
        "price": 10.25,
        "change_percent": 2.5,
        "market_cap": 285000000000,
        "pe_ratio": 5.23,
        "pb_ratio": 0.52,
        "roe": 0.089
      }
    ],
    "total_count": 15,
    "filter_stats": {
      "initial_count": 4500,
      "after_fundamental": 120,
      "after_technical": 15
    },
    "execution_time_ms": 250
  }
}
```

**cURL 示例**:
```bash
curl -X POST http://localhost:8080/api/screener/screen \
  -H "Content-Type: application/json" \
  -d '{
    "stock_pool": {"type": "industry", "value": "银行"},
    "fundamental_filters": [
      {"type": "max_pe", "value": 20},
      {"type": "min_roe", "value": 0.15}
    ]
  }'
```

### 获取行业列表

**端点**: `GET /api/industries`

**响应**:
```json
{
  "status": "success",
  "data": {
    "industries": [
      {
        "code": "J66",
        "name": "货币金融服务",
        "count": 45
      },
      {
        "code": "C27",
        "name": "医药制造业",
        "count": 128
      }
    ],
    "total": 97
  }
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/industries
```

### 获取行业成分股

**端点**: `GET /api/industries/:industry/stocks`

**路径参数**:
- `industry`: 行业代码或名称

**查询参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `limit` | int | 100 | 返回数量限制 |
| `offset` | int | 0 | 偏移量 |

**响应**:
```json
{
  "status": "success",
  "data": {
    "industry": "货币金融服务",
    "stocks": [
      {
        "code": "sh.600000",
        "name": "浦发银行",
        "weight": 0.085
      }
    ],
    "total": 45
  }
}
```

**cURL 示例**:
```bash
curl "http://localhost:8080/api/industries/银行/stocks"
```

---

## 技术指标 API

### 计算单个指标

**端点**: `POST /api/indicator/calculate`

**请求体**:
```json
{
  "stock_code": "sh.600000",
  "indicator": "rsi",
  "params": {
    "period": 14
  },
  "start_date": "2023-01-01",
  "end_date": "2023-12-31"
}
```

**支持的指标**:

| 指标 | 说明 | 参数 |
|------|------|------|
| `sma` | 简单移动平均 | `period`: 周期 |
| `ema` | 指数移动平均 | `period`: 周期 |
| `macd` | MACD 指标 | `fast_period`, `slow_period`, `signal_period` |
| `rsi` | RSI 指标 | `period`: 周期 |
| `bollinger` | 布林带 | `period`, `std_dev_multiplier` |
| `atr` | 平均真实波幅 | `period`: 周期 |
| `kdj` | KDJ 指标 | `n_period`, `k_period`, `d_period` |

**响应**:
```json
{
  "status": "success",
  "data": {
    "stock_code": "sh.600000",
    "indicator": "rsi",
    "values": [
      {
        "date": "2023-01-03",
        "value": 45.23
      },
      {
        "date": "2023-01-04",
        "value": 48.56
      }
    ],
    "params": {
      "period": 14
    }
  }
}
```

**cURL 示例**:
```bash
curl -X POST http://localhost:8080/api/indicator/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "sh.600000",
    "indicator": "rsi",
    "params": {"period": 14}
  }'
```

### 计算多个指标

**端点**: `POST /api/indicator/calculate-multi`

**请求体**:
```json
{
  "stock_code": "sh.600000",
  "indicators": [
    {
      "name": "sma",
      "params": {"period": 20}
    },
    {
      "name": "rsi",
      "params": {"period": 14}
    },
    {
      "name": "macd",
      "params": {"fast_period": 12, "slow_period": 26, "signal_period": 9}
    }
  ],
  "start_date": "2023-01-01",
  "end_date": "2023-12-31"
}
```

**响应**:
```json
{
  "status": "success",
  "data": {
    "stock_code": "sh.600000",
    "results": {
      "sma": [...],
      "rsi": [...],
      "macd": {...}
    }
  }
}
```

### 获取指标信号

**端点**: `GET /api/indicator/signals`

**查询参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| `stock_code` | string | 股票代码 |
| `indicator` | string | 指标名称 |
| `signal_type` | string | 信号类型 |

**信号类型**:
- `macd_bullish`: MACD 金叉
- `macd_bearish`: MACD 死叉
- `rsi_oversold`: RSI 超卖
- `rsi_overbought`: RSI 超买
- `price_above_ma`: 价格在均线上方
- `price_below_ma`: 价格在均线下方

**响应**:
```json
{
  "status": "success",
  "data": {
    "stock_code": "sh.600000",
    "signals": [
      {
        "type": "macd_bullish",
        "date": "2023-03-15",
        "price": 10.25,
        "strength": 0.75
      }
    ]
  }
}
```

**cURL 示例**:
```bash
curl "http://localhost:8080/api/indicator/signals?stock_code=sh.600000&indicator=macd&signal_type=bullish"
```

---

## 回测 API

### 运行回测

**端点**: `POST /api/backtest/run`

**请求体**:
```json
{
  "stock_code": "sh.600000",
  "strategy": "ma_cross",
  "start_date": "2023-01-01",
  "end_date": "2023-12-31",
  "initial_capital": 100000,
  "commission_rate": 0.0003,
  "slippage": 0.001,
  "risk_rules": [
    {
      "type": "max_drawdown",
      "threshold": 0.20
    },
    {
      "type": "position_limit",
      "max_ratio": 0.95
    }
  ]
}
```

**内置策略**:

| 策略 | 说明 | 参数 |
|------|------|------|
| `ma_cross` | 均线交叉 | `fast_period`, `slow_period` |
| `momentum` | 动量策略 | `rsi_period`, `overbought`, `oversold` |
| `rsi_mean_reversion` | RSI 均值回归 | `rsi_period`, `oversold` |

**响应** (同步模式):
```json
{
  "status": "success",
  "data": {
    "backtest_id": "bt_20260328_001",
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
      "equity_curve": [
        {
          "date": "2023-01-03",
          "equity": 100000,
          "drawdown": 0,
          "position": 0,
          "cash": 100000
        }
      ],
      "trades": [
        {
          "stock": "sh.600000",
          "action": "buy",
          "price": 10.50,
          "quantity": 9500,
          "timestamp": "2023-01-10",
          "commission": 29.93
        }
      ]
    }
  }
}
```

**响应** (异步模式):
```json
{
  "status": "started",
  "data": {
    "backtest_id": "bt_20260328_001",
    "estimated_completion": "2026-03-28T10:30:05Z"
  }
}
```

**cURL 示例**:
```bash
curl -X POST http://localhost:8080/api/backtest/run \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "sh.600000",
    "strategy": "ma_cross",
    "start_date": "2023-01-01",
    "end_date": "2023-12-31",
    "initial_capital": 100000
  }'
```

### 获取回测结果

**端点**: `GET /api/backtest/result/:id`

**路径参数**:
- `id`: 回测 ID

**响应**:
```json
{
  "status": "success",
  "data": {
    "backtest_id": "bt_20260328_001",
    "status": "completed",
    "created_at": "2026-03-28T10:30:00Z",
    "completed_at": "2026-03-28T10:30:05Z",
    "result": {
      "initial_capital": 100000,
      "final_capital": 115000,
      "total_return": 0.15,
      "max_drawdown": -0.085
    }
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
curl http://localhost:8080/api/backtest/result/bt_20260328_001
```

### 获取回测详情

**端点**: `GET /api/backtest/detail/:id`

**返回完整的回测详情**,包括所有交易记录和权益曲线数据。

**响应**:
```json
{
  "status": "success",
  "data": {
    "backtest_id": "bt_20260328_001",
    "config": {
      "stock_code": "sh.600000",
      "strategy": "ma_cross",
      "start_date": "2023-01-01",
      "end_date": "2023-12-31"
    },
    "result": {
      // 完整结果
    },
    "analytics": {
      "monthly_returns": [...],
      "drawdown_periods": [...],
      "trade_distribution": {...}
    }
  }
}
```

---

## 行情数据 API

### 获取股票列表

**端点**: `GET /api/stocks`

**查询参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `exchange` | string | - | 交易所 (sh/sz) |
| `industry` | string | - | 行业 |
| `limit` | int | 100 | 返回数量限制 |
| `offset` | int | 0 | 偏移量 |

**响应**:
```json
{
  "status": "success",
  "data": {
    "stocks": [
      {
        "code": "sh.600000",
        "name": "浦发银行",
        "exchange": "SH",
        "industry": "银行",
        "market_cap": 285000000000,
        "pe_ratio": 5.23
      }
    ],
    "total": 45,
    "has_more": true
  }
}
```

**cURL 示例**:
```bash
curl "http://localhost:8080/api/stocks?exchange=sh&limit=10"
```

### 获取股票详情

**端点**: `GET /api/stocks/:code`

**路径参数**:
- `code`: 股票代码

**响应**:
```json
{
  "status": "success",
  "data": {
    "stock": {
      "code": "sh.600000",
      "name": "浦发银行",
      "exchange": "SH",
      "sector": "金融",
      "industry": "银行",
      "listing_date": "1999-11-10",
      "market_cap": 285000000000,
      "pe_ratio": 5.23,
      "pb_ratio": 0.52,
      "dividend_yield": 0.045
    }
  }
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/stocks/sh.600000
```

### 获取 K 线数据

**端点**: `GET /api/stocks/:code/klines`

**路径参数**:
- `code`: 股票代码

**查询参数**:
| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `start` | string | - | 开始日期 (YYYY-MM-DD) |
| `end` | string | - | 结束日期 (YYYY-MM-DD) |
| `frequency` | string | daily | 频率 |
| `limit` | int | 1000 | 返回数量限制 |
| `fields` | string | all | 返回字段 |

**频率选项**:
- `daily`: 日线
- `weekly`: 周线
- `monthly`: 月线
- `5min`: 5 分钟线
- `15min`: 15 分钟线
- `30min`: 30 分钟线
- `60min`: 60 分钟线

**响应**:
```json
{
  "status": "success",
  "data": {
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
      }
    ],
    "count": 1
  }
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `date` | string | 日期 |
| `time` | string | 时间 (分钟线) |
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

# 获取 5 分钟线
curl "http://localhost:8080/api/stocks/sh.600000/klines?frequency=5min&limit=100"
```

### 获取实时行情

**端点**: `GET /api/quote/:code`

**路径参数**:
- `code`: 股票代码

**响应**:
```json
{
  "status": "success",
  "data": {
    "stock": "sh.600000",
    "quote": {
      "price": 10.25,
      "change": 0.25,
      "change_percent": 2.5,
      "open": 10.00,
      "high": 10.35,
      "low": 9.95,
      "prev_close": 10.00,
      "volume": 1500000,
      "amount": 15375000,
      "bid": 10.24,
      "ask": 10.26,
      "bid_size": 1000,
      "ask_size": 800,
      "timestamp": "2026-03-28T15:00:00+08:00"
    }
  }
}
```

**cURL 示例**:
```bash
curl http://localhost:8080/api/quote/sh.600000
```

---

## 错误码参考

### 通用错误

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `INVALID_REQUEST` | 400 | 请求格式无效 |
| `MISSING_PARAMETER` | 400 | 缺少必填参数 |
| `INVALID_PARAMETER` | 400 | 参数值无效 |

### 数据相关错误

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `STOCK_NOT_FOUND` | 404 | 股票代码不存在 |
| `DATA_NOT_FOUND` | 404 | 数据未找到 |
| `INSUFFICIENT_DATA` | 400 | 数据不足 |
| `INVALID_DATE_RANGE` | 400 | 日期范围无效 |
| `DATA_LOAD_ERROR` | 500 | 数据加载失败 |

### 策略相关错误

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `STRATEGY_NOT_FOUND` | 404 | 策略未找到 |
| `STRATEGY_CONFIG_ERROR` | 400 | 策略配置错误 |
| `STRATEGY_EXECUTION_ERROR` | 500 | 策略执行失败 |

### 回测相关错误

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `BACKTEST_NOT_FOUND` | 404 | 回测未找到 |
| `BACKTEST_FAILED` | 500 | 回测执行失败 |
| `BACKTEST_TIMEOUT` | 504 | 回测超时 |

### 系统错误

| 错误码 | HTTP 状态 | 说明 |
|--------|----------|------|
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |
| `SERVICE_UNAVAILABLE` | 503 | 服务不可用 |

---

## 客户端示例

### JavaScript 示例

```javascript
const API_BASE = 'http://localhost:8080/api';

// 执行股票筛选
async function screenStocks(criteria) {
  const response = await fetch(`${API_BASE}/screener/screen`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(criteria)
  });
  return response.json();
}

// 计算指标
async function calculateIndicator(stockCode, indicator, params) {
  const response = await fetch(`${API_BASE}/indicator/calculate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      stock_code: stockCode,
      indicator: indicator,
      params: params
    })
  });
  return response.json();
}

// 运行回测
async function runBacktest(config) {
  const response = await fetch(`${API_BASE}/backtest/run`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(config)
  });
  return response.json();
}

// 使用示例
(async () => {
  // 筛选银行股
  const screenResult = await screenStocks({
    stock_pool: { type: 'industry', value: '银行' },
    fundamental_filters: [
      { type: 'max_pe', value: 20 },
      { type: 'min_roe', value: 0.15 }
    ]
  });
  console.log('筛选结果:', screenResult.data.stocks);

  // 计算 RSI
  const rsiResult = await calculateIndicator('sh.600000', 'rsi', { period: 14 });
  console.log('RSI 值:', rsiResult.data.values);

  // 运行回测
  const backtestResult = await runBacktest({
    stock_code: 'sh.600000',
    strategy: 'ma_cross',
    start_date: '2023-01-01',
    end_date: '2023-12-31',
    initial_capital: 100000
  });
  console.log('回测收益率:', backtestResult.data.result.total_return);
})();
```

### Python 示例

```python
import requests

API_BASE = 'http://localhost:8080/api'

def screen_stocks(criteria):
    """执行股票筛选"""
    response = requests.post(
        f'{API_BASE}/screener/screen',
        json=criteria
    )
    return response.json()

def calculate_indicator(stock_code, indicator, params):
    """计算技术指标"""
    response = requests.post(
        f'{API_BASE}/indicator/calculate',
        json={
            'stock_code': stock_code,
            'indicator': indicator,
            'params': params
        }
    )
    return response.json()

def run_backtest(config):
    """运行回测"""
    response = requests.post(
        f'{API_BASE}/backtest/run',
        json=config
    )
    return response.json()

# 使用示例
if __name__ == '__main__':
    # 筛选银行股
    result = screen_stocks({
        'stock_pool': {'type': 'industry', 'value': '银行'},
        'fundamental_filters': [
            {'type': 'max_pe', 'value': 20},
            {'type': 'min_roe', 'value': 0.15}
        ]
    })
    print(f"筛选结果：{result['data']['total_count']} 只股票")

    # 计算 RSI
    rsi = calculate_indicator('sh.600000', 'rsi', {'period': 14})
    print(f"RSI 值：{rsi['data']['values'][-1]['value']}")

    # 运行回测
    backtest = run_backtest({
        'stock_code': 'sh.600000',
        'strategy': 'ma_cross',
        'start_date': '2023-01-01',
        'end_date': '2023-12-31',
        'initial_capital': 100000
    })
    print(f"总收益率：{backtest['data']['result']['total_return'] * 100:.2f}%")
```

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
