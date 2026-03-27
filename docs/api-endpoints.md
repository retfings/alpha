# HTTP API 参考文档

本文档提供 HTTP API 服务器的完整端点参考，包括请求/响应格式、参数说明和使用示例。

## 概述

### 启动服务器

```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run cmd/main
```

**参数**:
- `--port`: 服务器端口（默认：8080）

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

## 更新日志

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| 1.0 | 2026-03-27 | 初始版本，包含核心 API 端点 |

---

*最后更新：2026-03-27*
