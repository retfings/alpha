# HTTP Server README

## FastAPI HTTP Server

本目录包含量化回撤框架的 HTTP API 服务器实现。

## 快速启动

### 方法 1: 使用启动脚本

```bash
cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha
./script/start-server.sh
```

### 方法 2: 直接使用 uvicorn

```bash
cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha
python -m uvicorn script.server:app --reload --port 8080
```

### 方法 3: 使用 Python

```bash
cd /mnt/c/Users/liujia/Desktop/project/moonbit/alpha/script
python server.py
```

## 依赖安装

```bash
pip install -r requirements.txt
```

或手动安装：

```bash
pip install fastapi uvicorn pydantic
```

## API 端点

### Stocks (股票数据)

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/stocks` | GET | 获取可用股票列表 |
| `/api/stocks/{code}` | GET | 获取股票信息 |
| `/api/stocks/{code}/klines` | GET | 获取 K 线数据 |

### Strategies (策略)

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/strategies` | GET | 获取可用策略列表 |

### Backtest (回测)

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/backtest` | POST | 运行策略回测 |
| `/api/backtest/{id}/result` | GET | 获取回测结果 |

### Analysis (分析)

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/drawdown/{code}` | GET | 计算个股回撤 |
| `/api/portfolio/drawdown` | GET | 获取组合回撤 |

## 使用示例

### 获取股票列表

```bash
curl http://localhost:8080/api/stocks
```

### 获取 K 线数据

```bash
curl "http://localhost:8080/api/stocks/sh.600000/klines?start=2026-01-01&end=2026-03-26"
```

### 运行回测

```bash
curl -X POST http://localhost:8080/api/backtest \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "sh.600000",
    "strategy": "ma_cross",
    "start_date": "2026-01-01",
    "end_date": "2026-03-26",
    "initial_capital": 100000
  }'
```

### 计算回撤

```bash
curl "http://localhost:8080/api/drawdown/sh.600000?start=2026-01-01&end=2026-03-26"
```

## API 文档

启动服务器后访问：
- Swagger UI: http://localhost:8080/docs
- ReDoc: http://localhost:8080/redoc

## 文件结构

```
script/
├── server.py          # FastAPI 服务器主文件
├── requirements.txt   # Python 依赖
├── start-server.sh    # 启动脚本
└── README.md         # 本文档
```

## 技术栈

- **FastAPI**: 现代高性能 Python Web 框架
- **Uvicorn**: ASGI 服务器
- **Pydantic**: 数据验证和序列化

## 注意事项

1. 回测功能当前使用模拟引擎，真实实现需要：
   - 通过 C FFI 调用 MoonBit 回测引擎
   - 或实现 Python 版本的回测引擎

2. 数据文件位于 `data/` 目录，格式为 CSV

3. Web 前端位于 `www/` 目录
