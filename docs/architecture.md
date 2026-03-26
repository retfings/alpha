# 量化回撤框架架构设计

## Context / 背景

用户正在使用 MoonBit 语言构建一个量化回撤框架，需要支持 Web 和 CLI 两种交互方式。当前项目是一个基础的 MoonBit 模块结构，已有：
- 基础项目框架（`moon.mod.json`）
- 一个简单的 CLI 入口（`cmd/main/main.mbt`）
- 空的库文件（`alpha.mbt`）
- 配套的 Python 数据下载脚本（基于 BaoStock API）
- 已下载的 A 股股票数据（CSV 格式）

## 问题分析

量化回撤框架需要解决的核心问题：
1. **数据层**：如何高效加载和处理股票数据（CSV/数据库）
2. **策略层**：如何定义和回测交易策略
3. **回撤计算**：如何计算和监控账户/组合回撤
4. **风控层**：如何设置和执行风险控制规则
5. **展示层**：如何提供 CLI 和 Web 两种交互界面

## 架构设计

### 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌─────────────────────────────┐ ┌───────────────────────────┐ │
│  │         CLI Interface        │ │       Web Interface       │ │
│  │    (cmd/main/main.mbt)      │ │   (www/ - static files)   │ │
│  └─────────────────────────────┘ └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                         │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────┐ │
│  │ Backtest App  │ │ Monitor App   │ │ Report Generator      │ │
│  └───────────────┘ └───────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Domain Layer                             │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────┐ │
│  │   Strategy    │ │  Drawdown     │ │    Risk Management    │ │
│  │   Engine      │ │  Calculator   │ │    Engine             │ │
│  └───────────────┘ └───────────────┘ └───────────────────────┘ │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────┐ │
│  │   Portfolio   │ │    Order      │ │    Performance        │ │
│  │   Manager     │ │    Executor   │ │    Analyzer           │ │
│  └───────────────┘ └───────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Data Layer                              │
│  ┌───────────────┐ ┌───────────────┐ ┌───────────────────────┐ │
│  │  CSV Loader   │ │  Data         │ │    Technical          │ │
│  │               │ │  Normalizer   │ │    Indicator Lib      │ │
│  └───────────────┘ └───────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 目录结构

```
alpha/
├── moon.mod.json              # MoonBit 模块配置
├── moon.pkg                   # 根包配置
├── alpha.mbt                  # 根包入口（公共 API 导出）
│
├── cmd/
│   └── main/
│       ├── moon.pkg           # CLI 应用包配置
│       └── main.mbt           # CLI 入口，命令解析
│
├── src/                       # 核心业务逻辑
│   ├── data/                  # 数据层
│   │   ├── moon.pkg
│   │   ├── loader.mbt         # CSV/Parquet 数据加载器
│   │   ├── types.mbt          # 数据类型定义（K 线、Tick 等）
│   │   ├── normalizer.mbt     # 数据标准化（复权处理等）
│   │   └── parquet.mbt        # Parquet 格式支持（未来扩展）
│   │
│   ├── strategy/              # 策略层
│   │   ├── moon.pkg
│   │   ├── types.mbt          # 策略接口/类型定义
│   │   ├── engine.mbt         # 策略引擎（信号生成）
│   │   ├── registry.mbt       # 策略注册表
│   │   └── builtins/          # 内置策略
│   │       ├── moon.pkg
│   │       ├── ma_cross.mbt   # 均线交叉策略
│   │       └── momentum.mbt   # 动量策略
│   │
│   ├── drawdown/              # 回撤计算核心
│   │   ├── moon.pkg
│   │   ├── calculator.mbt     # 回撤计算器
│   │   ├── types.mbt          # 回撤类型定义
│   │   └── monitor.mbt        # 实时监控器
│   │
│   ├── risk/                  # 风控层
│   │   ├── moon.pkg
│   │   ├── rules.mbt          # 风控规则（止损、仓位等）
│   │   ├── engine.mbt         # 风控引擎
│   │   └── types.mbt          # 风控类型
│   │
│   ├── portfolio/             # 组合管理
│   │   ├── moon.pkg
│   │   ├── manager.mbt        # 组合管理器
│   │   ├── position.mbt       # 持仓管理
│   │   └── types.mbt          # 组合类型
│   │
│   ├── indicator/             # 技术指标库
│   │   ├── moon.pkg
│   │   ├── ma.mbt             # 均线类
│   │   ├── macd.mbt           # MACD
│   │   ├── rsi.mbt            # RSI
│   │   ├── bollinger.mbt      # 布林带
│   │   └── atr.mbt            # ATR
│   │
│   └── backtest/              # 回测引擎
│       ├── moon.pkg
│       ├── engine.mbt         # 回测执行引擎
│       ├── types.mbt          # 回测配置/结果类型
│       └── report.mbt         # 回测报告生成
│
├── server/                    # HTTP 服务器
│   ├── moon.pkg
│   └── server.mbt             # 简单 HTTP API 服务器
│
├── www/                       # Web 前端（静态文件）
│   ├── index.html             # 主页面
│   ├── app.js                 # 前端逻辑
│   ├── styles.css             # 样式
│   └── charts/                # 图表组件（Chart.js / D3.js）
│
├── script/                    # Python 工具脚本
│   ├── download_data.py       # 数据下载（已有）
│   └── generate_report.py     # 报告生成（可选）
│
├── data/                      # 数据目录（已有）
│   └── *.csv                  # 股票数据文件
│
├── test/                      # 测试目录
│   ├── data_test.mbt          # 数据层测试
│   ├── strategy_test.mbt      # 策略层测试
│   ├── drawdown_test.mbt      # 回撤计算测试
│   └── backtest_test.mbt      # 回测引擎测试
│
└── docs/                      # 文档目录
    ├── architecture.md        # 架构设计文档
    ├── user-guide.md          # 用户指南
    ├── api-reference.md       # API 参考
    └── strategy-examples.md   # 策略示例
```

### 核心模块设计

#### 1. 数据类型定义 (`src/data/types.mbt`)

```moonbit
pub type KLine = {
  date: String,
  time: Option[String],     // 分钟级别数据需要
  open: Float,
  high: Float,
  low: Float,
  close: Float,
  volume: Float,
  amount: Float,
  turn: Float,
}

pub type StockCode = String  // 格式："sh.600000"

pub type TimeSeries[T] = List[(Int64, T)]  // 时间序列

pub enum Frequency {
  Daily,
  Weekly,
  Monthly,
  Minute5,
  Minute15,
  Minute30,
  Minute60,
}
```

#### 2. 回撤计算 (`src/drawdown/calculator.mbt`)

```moonbit
pub type DrawdownInfo = {
  peak: Float,           // 峰值
  trough: Float,         // 谷底
  peak_date: String,     // 峰值日期
  trough_date: String,   // 谷底日期
  drawdown: Float,       // 回撤幅度（百分比）
  duration: Int,         // 回撤持续天数
  recovered: Bool,       // 是否已恢复
}

pub fn calculate_max_drawdown(values: List[Float]) -> DrawdownInfo
pub fn calculate_drawdown_series(values: List[Float]) -> List[Float]
pub fn calculate_current_drawdown(values: List[Float]) -> Float
pub fn find_top_drawdowns(values: List[Float], n: Int) -> List[DrawdownInfo]
```

#### 3. 策略接口 (`src/strategy/types.mbt`)

```moonbit
pub type Signal = {
  stock: StockCode,
  action: Action,
  price: Float,
  timestamp: String,
  strength: Float,      // 信号强度 0.0 - 1.0
}

pub enum Action {
  Buy,
  Sell,
  Hold,
}

pub trait Strategy {
  fn name: String
  fn on_bar: (self, kline: KLine, ctx: StrategyContext) -> Signal
  fn on_init: (self, ctx: StrategyContext) -> Unit
}

pub type StrategyContext = {
  capital: Float,
  position: Position,
  market_data: Map[StockCode, KLine],
  indicators: Map[String, IndicatorValue],
}
```

#### 4. 风控规则 (`src/risk/rules.mbt`)

```moonbit
pub type RiskRule = {
  name: String,
  check: (Portfolio) -> RiskResult,
}

pub type RiskResult = {
  passed: Bool,
  message: String,
  action: RiskAction,
}

pub enum RiskAction {
  Allow,
  Reject,
  ReducePosition(Float),  // 建议减仓比例
  StopTrading,
}

// 内置风控规则
pub fn max_drawdown_rule(max_pct: Float) -> RiskRule
pub fn position_limit_rule(max_pct: Float) -> RiskRule
pub fn stop_loss_rule(stop_pct: Float) -> RiskRule
pub fn single_stock_limit_rule(max_pct: Float) -> RiskRule
```

#### 5. 回测引擎 (`src/backtest/engine.mbt`)

```moonbit
pub type BacktestConfig = {
  start_date: String,
  end_date: String,
  initial_capital: Float,
  commission_rate: Float,
  slippage: Float,
  benchmark: Option[StockCode],
}

pub type BacktestResult = {
  total_return: Float,
  annual_return: Float,
  max_drawdown: Float,
  sharpe_ratio: Float,
  win_rate: Float,
  total_trades: Int,
  equity_curve: List[EquityPoint],
  trades: List[Trade],
}

pub fn run_backtest(
  strategy: Strategy,
  data: Map[StockCode, List[KLine]],
  config: BacktestConfig,
) -> BacktestResult
```

### CLI 设计 (`cmd/main/main.mbt`)

```
moonbit-drawdown - 量化回撤分析工具

USAGE:
    moon run cmd/main [COMMAND] [OPTIONS]

COMMANDS:
    backtest        运行策略回测
    analyze         分析股票/组合回撤
    monitor         实时监控模式
    report          生成分析报告
    list-strategies 列出所有可用策略
    help            显示帮助信息

EXAMPLES:
    # 回测单个策略
    moon run cmd/main backtest --strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31

    # 分析股票最大回撤
    moon run cmd/main analyze --stock sh.600000 --metric max_drawdown

    # 批量分析多只股票
    moon run cmd/main analyze --stocks sh.600000,sz.000001 --metrics all

    # 生成报告
    moon run cmd/main report --output report.html
```

### Web 界面设计 (`www/`)

- **Dashboard**: 组合概览、实时回撤监控
- **Backtest**: 策略配置和回测结果可视化
- **Analysis**: 个股/组合回撤分析图表
- **Settings**: 风控参数配置

前端技术栈：
- 纯静态 HTML/CSS/JS（轻量级）
- Chart.js / D3.js 用于图表
- 通过 HTTP API 与后端交互

### HTTP API 设计 (`server/`)

使用 MoonBit 实现简单 HTTP 服务器，提供以下 API：

```
GET  /api/stocks                 # 获取股票列表
GET  /api/stocks/:code/klines    # 获取 K 线数据
POST /api/backtest               # 运行回测
GET  /api/backtest/:id/result    # 获取回测结果
GET  /api/drawdown/:code         # 计算个股回撤
GET  /api/portfolio/drawdown     # 计算组合回撤
```

## 技术决策（已确认）

1. **Web 后端**：使用简单 HTTP 服务器（用 MoonBit 或其他语言实现）
2. **数据存储**：当前使用 CSV，未来扩展支持 Parquet 格式
3. **策略定义**：使用纯 MoonBit 编码（类型安全，直接调用框架 API）

## 实现优先级

1. **Phase 1 - 基础框架**
   - 数据类型定义
   - CSV 数据加载器
   - 基础回撤计算器
   - 简单 CLI 命令

2. **Phase 2 - 策略引擎**
   - 策略接口定义
   - 回测引擎核心
   - 1-2 个内置策略示例
   - 回测报告生成

3. **Phase 3 - 风控系统** （已完成）
   - 风控规则引擎 (`src/risk/types.mbt`)
     - `RiskEngine` - 风控引擎状态管理
     - `RiskRule` - 规则定义（名称、优先级、检查函数）
     - `RiskResult` - 规则评估结果
     - `RiskAction` - 规则执行动作（Allow/Reject/ReducePosition/StopTrading）
   - 内置风控规则 (`src/risk/rules.mbt`)
     - `max_drawdown_rule` - 最大回撤规则（触发停止交易）
     - `position_limit_rule` - 仓位限制规则（触发减仓）
     - `daily_loss_limit_rule` - 日损限制规则（触发停止交易）
     - `stop_loss_rule` - 止损规则（触发减仓）
     - `single_stock_limit_rule` - 单股限制规则（触发减仓）
     - `take_profit_rule` - 止盈规则（触发部分减仓）
   - 与回测引擎集成 (`src/backtest/engine.mbt`)
     - 回测过程中实时检查风控规则
     - 根据风控结果决定是否执行交易信号
   - 测试覆盖 (`src/risk/rules_test.mbt`)
     - 14 个单元测试覆盖所有规则与引擎功能

4. **Phase 4 - HTTP 服务器**
   - 简单 HTTP API 服务器
   - RESTful API 实现
   - 与核心引擎集成

5. **Phase 5 - Web 界面**
   - 静态页面框架
   - 图表可视化
   - API 对接

6. **Phase 6 - 完善与优化**
   - Parquet 格式支持
   - 更多技术指标
   - 更多内置策略
   - 性能优化
   - 文档完善

## 参考资料

- MoonBit 官方文档：https://www.moonbitlang.com
- BaoStock API 文档：https://www.baostock.com
- 量化交易基础（回撤、夏普比率等计算方法）
