# 股票选择系统架构设计

**版本**: 1.0
**创建日期**: 2026-03-28
**最后更新**: 2026-03-28

---

## 目录

1. [系统概述](#系统概述)
2. [架构原则](#架构原则)
3. [系统分层](#系统分层)
4. [核心模块设计](#核心模块设计)
5. [数据流设计](#数据流设计)
6. [接口设计](#接口设计)
7. [扩展性设计](#扩展性设计)
8. [技术栈](#技术栈)

---

## 系统概述

### 系统定位

股票选择系统是一个基于 MoonBit 的量化选股平台，提供股票筛选、策略配置和回测分析功能。系统支持 CLI 和 Web 两种交互方式。

### 核心功能

| 功能模块 | 描述 | 用户 |
|----------|------|------|
| 股票筛选器 | 基于基本面和技术面的多维度股票筛选 | 投资者 |
| 技术指标库 | 完整的技术指标计算库 | 量化分析师 |
| 策略引擎 | 策略定义、信号生成和执行 | 策略开发者 |
| 回测系统 | 历史数据回测和绩效分析 | 所有用户 |
| 风险管理 | 多层级风控规则引擎 | 风控官员 |

### 系统边界

```
┌─────────────────────────────────────────────────────────────┐
│                       股票选择系统                           │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   CLI 界面   │  │   Web 界面   │  │   API 服务       │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   核心业务层                          │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐    │  │
│  │  │ 筛选器 │ │ 指标库 │ │ 策略层 │ │ 回测引擎   │    │  │
│  │  └────────┘ └────────┘ └────────┘ └────────────┘    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   数据层                              │  │
│  │  ┌────────┐ ┌────────┐ ┌────────┐                    │  │
│  │  │ 数据加载│ │ 数据缓存│ │ 数据导出│                    │  │
│  │  └────────┘ └────────┘ └────────┘                    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       外部系统                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  BaoStock    │  │  交易所数据  │  │  第三方数据源    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 架构原则

### 设计原则

1. **模块化**: 每个模块职责单一，接口清晰
2. **可扩展**: 新指标、新策略易于添加
3. **高性能**: 关键路径优化，支持大数据量
4. **类型安全**: 充分利用 MoonBit 类型系统
5. **测试友好**: 所有核心逻辑可独立测试

### 分层原则

```
┌─────────────────────────────────────┐
│         表现层 (Presentation)        │  ← 用户界面
├─────────────────────────────────────┤
│         应用层 (Application)         │  ← 业务编排
├─────────────────────────────────────┤
│         领域层 (Domain)              │  ← 核心业务逻辑
├─────────────────────────────────────┤
│         基础设施层 (Infrastructure)  │  ← 数据持久化、外部服务
└─────────────────────────────────────┘
```

### 依赖原则

- **依赖倒置**: 高层模块不依赖低层模块，都依赖抽象
- **单向依赖**: 依赖方向指向领域层
- **接口隔离**: 使用细粒度接口而非胖接口

---

## 系统分层

### 表现层 (Presentation Layer)

**职责**: 处理用户交互和界面展示

**组件**:
- CLI 命令行界面
- Web 前端界面
- API 路由处理

**技术实现**:
```
www/
├── index.html              # 主页
├── stock_strategy.html     # 策略配置页
├── app.js                  # 主页应用逻辑
├── stock_strategy.js       # 策略页逻辑
└── api.js                  # API 客户端

alpha/
├── main.mbt                # CLI 入口
├── parsers/
│   └── command_parser.mbt  # 命令解析
└── handlers/
    ├── analyze.mbt         # 分析处理器
    ├── backtest.mbt        # 回测处理器
    └── serve.mbt           # 服务处理器
```

### 应用层 (Application Layer)

**职责**: 编排业务流程，协调领域对象

**组件**:
- 筛选器应用服务
- 回测应用服务
- 报告生成服务

**接口示例**:
```mbt
/// 筛选器应用服务
pub struct ScreenerApp {
  stock_pool : StockPool
  filter_engine : FilterEngine
  result_exporter : ResultExporter
}

pub fn ScreenerApp::run_screen(
  self,
  criteria : ScreeningCriteria,
) -> Result[ScreeningResult, ScreenerError]
```

### 领域层 (Domain Layer)

**职责**: 核心业务逻辑，领域模型

**子模块**:

```
src/
├── data/                   # 数据领域
│   ├── types.mbt           # KLine, StockCode 等类型
│   ├── loader.mbt          # 数据加载
│   └── normalizer.mbt      # 数据标准化
│
├── indicator/              # 指标领域
│   ├── ma.mbt              # 移动平均
│   ├── macd.mbt            # MACD 指标
│   ├── rsi.mbt             # RSI 指标
│   ├── bollinger.mbt       # 布林带
│   └── ...
│
├── strategy/               # 策略领域
│   ├── types.mbt           # Strategy, Signal 类型
│   ├── engine.mbt          # 策略引擎
│   └── builtins/           # 内置策略
│
├── backtest/               # 回测领域
│   ├── types.mbt           # 回测类型
│   ├── engine.mbt          # 回测引擎
│   └── report.mbt          # 报告生成
│
├── risk/                   # 风控领域
│   ├── rules.mbt           # 风控规则
│   └── engine.mbt          # 风控引擎
│
└── drawdown/               # 回撤领域
    ├── types.mbt           # 回撤类型
    └── calculator.mbt      # 回撤计算
```

### 基础设施层 (Infrastructure Layer)

**职责**: 数据持久化、外部服务集成

**组件**:
- 文件 I/O (CSV 读取/写入)
- HTTP 服务器 (FFI)
- 数据下载脚本

**技术实现**:
```
src/ffi/
├── file_io.mbt             # 文件 I/O 封装
└── ffi_test.mbt            # FFI 测试

server/
├── server.mbt              # HTTP 服务器
├── routes.mbt              # 请求路由
└── http_server.c           # C FFI 实现

script/
├── data_download/
│   └── enhanced_downloader.py  # 数据下载
```

---

## 核心模块设计

### 股票筛选器模块

**职责**: 执行多维度股票筛选

**架构**:
```
┌─────────────────────────────────────────────────────────────┐
│                     Screener                                │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │ StockPool   │ → │  Filter     │ → │  Result         │   │
│  │ Config      │   │  Engine     │   │  Exporter       │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
│         │                │                    │              │
│         ▼                ▼                    ▼              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │ - All       │   │ - 基本面    │   │ - CSV           │   │
│  │ - SH/SZ     │   │ - 技术面    │   │ - JSON          │   │
│  │ - Industry  │   │ - 财务面    │   │ - Excel         │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**接口定义**:
```mbt
/// 筛选条件
pub struct ScreeningCriteria {
  stock_pool : StockPoolConfig
  fundamental_filters : Array[FundamentalFilter]
  technical_filters : Array[TechnicalFilter]
  financial_filters : Array[FinancialFilter]
  sort_config : SortConfig?
}

/// 筛选引擎
pub struct FilterEngine {
  indicators : IndicatorRegistry
  calculators : CalculatorRegistry
}

pub fn FilterEngine::apply_filters(
  self,
  stocks : Array[Stock],
  criteria : ScreeningCriteria,
) -> Array[Stock]

/// 筛选结果
pub struct ScreeningResult {
  stocks : Array[Stock]
  total_count : Int
  filter_stats : Map[String, Int]
  execution_time_ms : Int
}
```

### 技术指标模块

**职责**: 提供完整的技术指标计算

**架构**:
```
┌─────────────────────────────────────────────────────────────┐
│                    Indicator Library                        │
├─────────────────────────────────────────────────────────────┤
│  Trend Indicators     │  Momentum Indicators  │  Volatility │
│  ─────────────────    │  ───────────────────  │  ────────── │
│  • SMA/EMA            │  • RSI                │  • ATR      │
│  • MACD               │  • KDJ                │  • Bollinger│
│  • ADX                │  • Williams %R        │  • StdDev   │
│  • Aroon              │  • CCI                │             │
├─────────────────────────────────────────────────────────────┤
│  Volume Indicators                                          │
│  ───────────────────                                        │
│  • OBV               • VWAP          • Money Flow           │
└─────────────────────────────────────────────────────────────┘
```

**指标接口规范**:
```mbt
/// 指标计算接口
pub trait Indicator {
  name : String
  compute : (Array[Float]) -> Array[Float]
  validate_params : () -> Bool
}

/// 示例：RSI 指标实现
pub fn rsi(prices : Array[Float], period : Int) -> Array[Float] {
  // 参数验证
  if prices.length() <= period || period <= 0 {
    return prices.map(fn(_) { Float::from_double(0.0) })
  }

  // 计算逻辑
  // ...

  result
}
```

### 策略引擎模块

**职责**: 策略加载、执行和信号生成

**架构**:
```
┌─────────────────────────────────────────────────────────────┐
│                    Strategy Engine                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │  Strategy   │ → │   Signal    │ → │   Execution     │   │
│  │  Registry   │   │   Generator │   │   Manager       │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
│         │                │                    │              │
│         ▼                ▼                    ▼              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │ - Built-in  │   │ - Signal    │   │ - Position      │   │
│  │ - Custom    │   │ - Scoring   │   │ - Sizing        │   │
│  │ - Composite │   │ - Filtering │   │ - Logging       │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**策略接口**:
```mbt
/// 策略记录类型
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (KLine, StrategyContext, Array[Float]) -> Signal
}

/// 策略上下文
pub struct StrategyContext {
  capital : Float
  position : Float
  current_price : Float
  last_signal : Signal?
}

/// 交易信号
pub struct Signal {
  stock : StockCode
  action : Action
  price : Float
  timestamp : String
  strength : Float
}
```

### 回测引擎模块

**职责**: 执行历史回测，生成绩效报告

**架构**:
```
┌─────────────────────────────────────────────────────────────┐
│                   Backtest Engine                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │   Config    │ → │  Execution  │ → │   Reporting     │   │
│  │   Manager   │   │   Engine    │   │   Generator     │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
│         │                │                    │              │
│         ▼                ▼                    ▼              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │ - Capital   │   │ - Order     │   │ - Metrics       │   │
│  │ - Costs     │   │ - Fill      │   │ - Charts        │   │
│  │ - Benchmark │   │ - Portfolio │   │ - Export        │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**回测流程**:
```
1. 加载配置 → 2. 初始化引擎 → 3. 加载数据
                                      ↓
8. 导出报告 ← 7. 生成统计 ← 6. 更新权益 ← 5. 执行交易 ← 4. 生成信号
```

**回测接口**:
```mbt
/// 回测配置
pub struct BacktestConfig {
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
  benchmark : StockCode?
}

/// 回测结果
pub struct BacktestResult {
  initial_capital : Float
  final_capital : Float
  total_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  total_trades : Int
  win_rate : Float
  trades : Array[Trade]
  equity_curve : Array[EquityPoint]
}

/// 执行回测
pub fn run_backtest(
  engine : BacktestEngine,
  klines : Array[KLine],
  strategy : Strategy,
) -> BacktestResult
```

### 风险管理模块

**职责**: 执行风控规则，控制交易风险

**架构**:
```
┌─────────────────────────────────────────────────────────────┐
│                     Risk Engine                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │   Rule      │ → │   Rule      │ → │   Decision      │   │
│  │   Registry  │   │   Executor  │   │   Aggregator    │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
│         │                │                    │              │
│         ▼                ▼                    ▼              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │
│  │ - Max DD    │   │ - Parallel  │   │ - Accept        │   │
│  │ - Position  │   │ - Sequential│   │ - Reject        │   │
│  │ - Stop Loss │   │ - Priority  │   │ - Modify        │   │
│  └─────────────┘   └─────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**风控规则接口**:
```mbt
/// 风控规则接口
pub struct RiskRule {
  name : String
  check : (Signal, Portfolio) -> RiskDecision
}

/// 风控决策
pub enum RiskDecision {
  Accept        // 接受交易
  Reject        // 拒绝交易
  Modify(Float) // 修改交易规模
}

/// 内置规则
pub fn max_drawdown_rule(threshold : Float) -> RiskRule
pub fn position_limit_rule(max_ratio : Float) -> RiskRule
pub fn stop_loss_rule(threshold : Float) -> RiskRule
pub fn daily_loss_limit_rule(threshold : Float) -> RiskRule
```

---

## 数据流设计

### 筛选数据流

```
┌─────────────────────────────────────────────────────────────┐
│                    Screening Data Flow                      │
└─────────────────────────────────────────────────────────────┘

1. 用户配置筛选条件
       ↓
2. 加载股票池
       ↓
3. 并行加载各股票数据
       ↓
4. 计算技术指标
       ↓
5. 应用筛选条件
       ↓
6. 汇总筛选结果
       ↓
7. 排序并导出
```

**详细流程**:

```mbt
// 1. 用户配置
let criteria = ScreeningCriteria::{
  stock_pool: StockPoolConfig::Industry("银行"),
  fundamental_filters: [max_pe(20), min_roe(0.15)],
  technical_filters: [price_above_ma(20)],
}

// 2. 加载股票池
let stocks = load_stocks_by_industry("银行")

// 3-4. 并行加载数据并计算指标
let stock_data = stocks.map(fn(stock) {
  let klines = load_klines(stock.code)
  let indicators = calculate_indicators(klines)
  {stock, klines, indicators}
})

// 5. 应用筛选
let filtered = stock_data.filter(fn(data) {
  apply_fundamental_filters(data, criteria.fundamental_filters) &&
  apply_technical_filters(data, criteria.technical_filters)
})

// 6-7. 汇总导出
let result = ScreeningResult::{
  stocks: filtered.map(fn(d) { d.stock }),
  total_count: filtered.length(),
}
```

### 回测数据流

```
┌─────────────────────────────────────────────────────────────┐
│                    Backtest Data Flow                       │
└─────────────────────────────────────────────────────────────┘

1. 加载回测配置
       ↓
2. 初始化回测引擎
       ↓
3. 加载历史 K 线数据
       ↓
4. 创建策略实例
       ↓
5. 逐条处理 K 线
   ├── 策略生成信号
   ├── 风控检查
   ├── 执行交易
   └── 更新权益
       ↓
6. 生成回测报告
```

**详细流程**:

```mbt
// 1-2. 配置和初始化
let config = BacktestConfig::{...}
let mut engine = create_backtest_engine(config)

// 3-4. 加载数据和策略
let klines = load_klines("data/sh.600000.csv")
let strategy = create_ma_cross_strategy(10, 30)

// 5. 逐条处理
for kline in klines {
  // 策略生成信号
  let signal = strategy.on_bar(kline, engine.get_context(), history)

  // 风控检查
  if engine.risk_engine.check(signal, engine.portfolio) {
    // 执行交易
    engine.execute_signal(signal)
  }

  // 更新权益
  engine.update_equity(kline)
}

// 6. 生成报告
let result = engine.generate_report()
```

### API 数据流

```
┌─────────────────────────────────────────────────────────────┐
│                      API Data Flow                          │
└─────────────────────────────────────────────────────────────┘

HTTP 请求
   ↓
路由解析
   ↓
参数验证
   ↓
业务处理
   ↓
数据查询
   ↓
响应构建
   ↓
HTTP 响应
```

**请求处理流程**:

```mbt
// 路由解析
let route = parse_request_path(request.path)

// 参数验证
match route {
  Route::GetKlines { code, params } => {
    if !validate_date_range(params.start, params.end) {
      return error_response("INVALID_DATE_RANGE")
    }
  }
  // ...
}

// 业务处理
let klines = load_klines(code)
let filtered = filter_klines(klines, params)

// 响应构建
make_response(200, {
  "stock": code,
  "klines": filtered,
  "count": filtered.length()
})
```

---

## 接口设计

### 内部接口

#### 数据层接口

```mbt
/// 数据加载器接口
pub trait DataLoader {
  load : (String) -> Result[Array[KLine], DataError>
  exists : (String) -> Bool
  get_metadata : (String) -> Result[Metadata, DataError>
}

/// CSV 数据加载器实现
pub struct CsvDataLoader {
  base_path : String
}

impl DataLoader for CsvDataLoader {
  fn load(self, path : String) -> Result[Array[KLine], DataError> {
    let content = read_file(path)
    parse_csv_to_klines(content)
  }
}
```

#### 指标层接口

```mbt
/// 指标注册表
pub struct IndicatorRegistry {
  indicators : Map[String, IndicatorFn]
}

pub fn IndicatorRegistry::register(
  &mut self,
  name : String,
  indicator : IndicatorFn,
)

pub fn IndicatorRegistry::get(
  &self,
  name : String,
) -> Option[IndicatorFn>

/// 指标函数类型
pub type IndicatorFn = (Array[Float], Map[String, Any]) -> Array[Float]
```

#### 策略层接口

```mbt
/// 策略工厂接口
pub trait StrategyFactory {
  create : (Map[String, Any]) -> Strategy
  get_default_params : () -> Map[String, Any]
  get_description : () -> String
}

/// 内置策略工厂
pub struct BuiltinStrategyFactory {
  factories : Map[String, StrategyFactory]
}
```

### 外部接口

#### CLI 接口

```bash
# 股票筛选
moon run cmd/main --cmd stock-screener \
  --industry 银行 \
  --max-pe 20 \
  --min-roe 0.15 \
  --export-csv results.csv

# 回测执行
moon run cmd/main --cmd backtest \
  --strategy ma_cross \
  --stock sh.600000 \
  --start 2023-01-01 \
  --end 2023-12-31

# 启动服务
moon run cmd/main --cmd serve --port 8080
```

#### HTTP API 接口

```http
# 获取股票列表
GET /api/stocks

# 获取 K 线数据
GET /api/stocks/{code}/klines?start=2023-01-01&end=2023-12-31

# 运行回测
POST /api/backtest
Content-Type: application/json

{
  "stock_code": "sh.600000",
  "strategy": "ma_cross",
  "start_date": "2023-01-01",
  "end_date": "2023-12-31"
}

# 获取回撤分析
GET /api/drawdown/{code}
```

---

## 扩展性设计

### 添加新指标

**步骤**:

1. 创建指标文件 `src/indicator/my_indicator.mbt`
2. 实现指标计算函数
3. 添加测试文件 `my_indicator_test.mbt`
4. 在指标注册表中注册

**示例**:

```mbt
/// src/indicator/my_indicator.mbt
pub fn my_indicator(
  prices : Array[Float],
  period : Int,
) -> Array[Float] {
  // 实现计算逻辑
  let result : Array[Float] = []
  // ...
  result
}
```

### 添加新策略

**步骤**:

1. 创建策略文件 `src/strategy/builtins/my_strategy.mbt`
2. 实现 Strategy 记录
3. 添加策略工厂函数
4. 在策略注册表中注册
5. 编写测试

**示例**:

```mbt
/// src/strategy/builtins/my_strategy.mbt
pub fn create_my_strategy(params : MyParams) -> Strategy {
  Strategy::{
    name: "My Strategy",
    on_init: fn(ctx) { ... },
    on_bar: fn(kline, ctx, history) {
      // 实现策略逻辑
      Signal::hold(kline.code, kline.close, kline.date)
    }
  }
}
```

### 添加新的数据源

**步骤**:

1. 实现 DataLoader trait
2. 配置数据源连接
3. 在应用层注册

**示例**:

```mbt
/// src/data/baostock_loader.mbt
pub struct BaoStockDataLoader {
  connection : Connection
}

impl DataLoader for BaoStockDataLoader {
  fn load(self, code : String) -> Result[Array[KLine], DataError> {
    // 从 BaoStock API 加载数据
    let data = fetch_from_baostock(code)
    parse_to_klines(data)
  }
}
```

---

## 技术栈

### 核心技术

| 技术 | 用途 | 版本 |
|------|------|------|
| MoonBit | 核心业务逻辑 | latest |
| JavaScript (ES6+) | 前端交互 | - |
| C (FFI) | HTTP 服务器底层 | - |

### 开发工具

| 工具 | 用途 |
|------|------|
| moon check | 类型检查 |
| moon build | 构建项目 |
| moon test | 运行测试 |
| moon fmt | 代码格式化 |
| moon info | 生成接口文件 |

### 前端技术

| 技术 | 用途 |
|------|------|
| HTML5/CSS3 | 页面结构和样式 |
| Chart.js | 图表可视化 |
| Fetch API | HTTP 通信 |

### 数据源

| 数据源 | 类型 | 用途 |
|--------|------|------|
| BaoStock | API | 实时/历史行情 |
| CSV 文件 | 本地 | 离线数据 |

---

## 附录

### A. 目录结构

```
alpha/
├── alpha/                    # CLI 应用
│   ├── main.mbt              # 入口
│   ├── handlers/             # 命令处理器
│   └── parsers/              # 命令解析
│
├── src/                      # 核心业务
│   ├── data/                 # 数据层
│   ├── indicator/            # 技术指标
│   ├── strategy/             # 策略引擎
│   ├── backtest/             # 回测系统
│   ├── risk/                 # 风控引擎
│   ├── drawdown/             # 回撤计算
│   └── ffi/                  # FFI 封装
│
├── server/                   # HTTP 服务器
├── www/                      # Web 前端
├── data/                     # 数据文件
└── script/                   # Python 工具
```

### B. 关键设计决策

1. **策略使用记录而非 trait**: 简化设计，便于测试
2. **指标纯函数实现**: 无状态，易于并行
3. **风控规则可组合**: 支持多个规则链式调用
4. **回测引擎可配置**: 支持不同场景配置

### C. 性能优化建议

1. **数据预加载**: 批量加载减少 I/O
2. **指标缓存**: 避免重复计算
3. **并行筛选**: 多股票并行处理
4. **流式处理**: 大文件流式读取

---

*文档维护者：doc-eng*
*最后更新：2026-03-28*
