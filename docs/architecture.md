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
│   │       ├── momentum.mbt   # 动量策略
│   │       └── rsi_mean_reversion.mbt # RSI 均值回归策略
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
│   │   ├── types.mbt          # 风控类型
│   │   ├── trailing_stop.mbt  # 追踪止损（动态止损）
│   │   └── kelly_criterion.mbt # 凯利公式仓位优化
│   │
│   ├── portfolio/             # 组合管理
│   │   ├── moon.pkg
│   │   ├── manager.mbt        # 组合管理器
│   │   ├── position.mbt       # 持仓管理
│   │   └── types.mbt          # 组合类型
│   │
│   ├── indicator/             # 技术指标库
│   │   ├── moon.pkg
│   │   ├── ma.mbt             # 移动平均 (MA/SMA/EMA) 和 MACD
│   │   ├── atr.mbt            # ATR (Average True Range)
│   │   ├── adx.mbt            # ADX (Average Directional Index)
│   │   ├── aroon.mbt          # Aroon (阿隆指标)
│   │   ├── cci.mbt            # CCI (Commodity Channel Index)
│   │   ├── kdj.mbt            # KDJ (Stochastic Oscillator)
│   │   ├── obv.mbt            # OBV (On-Balance Volume)
│   │   ├── rsi.mbt            # RSI (Relative Strength Index)
│   │   ├── williams_r.mbt     # Williams %R
│   │   ├── bollinger.mbt      # 布林带 (Bollinger Bands)
│   │   ├── vwap.mbt           # VWAP (成交量加权平均价)
│   │   └── ...                # 更多技术指标
│   │
│   └── backtest/              # 回测引擎
│       ├── moon.pkg
│       ├── engine.mbt         # 回测执行引擎
│       ├── types.mbt          # 回测配置/结果类型
│       ├── report.mbt         # 回测报告生成
│       └── walk_forward.mbt   #  walk-forward 分析引擎
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
pub struct KLine {
  code : String
  date : String
  time : String?
  open : Float
  high : Float
  low : Float
  close : Float
  volume : Float
  amount : Float
  turn : Float
}

pub type StockCode = String  // 格式："sh.600000"

pub type TimeSeries[T] = Array[(Int64, T)]  // 时间序列

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
pub struct DrawdownInfo {
  peak : Float          // 峰值
  trough : Float        // 谷底
  peak_date : String    // 峰值日期
  trough_date : String  // 谷底日期
  drawdown : Float      // 回撤幅度（百分比）
  duration : Int        // 回撤持续天数
  recovered : Bool      // 是否已恢复
}

pub struct DrawdownAlert {
  warning_threshold : Float    // 预警阈值（如 -0.05）
  critical_threshold : Float   // 临界阈值（如 -0.10）
  max_threshold : Float        // 最大阈值（如 -0.20）
}

pub struct DrawdownMonitor {
  mut peak_value : Float
  mut peak_date : String
  mut current_value : Float
  mut current_drawdown : Float
  warning_threshold : Float
  critical_threshold : Float
  mut alert_triggered : Bool
  mut last_alert_level : String
}

pub enum DrawdownLevel {
  Normal       // 正常（回撤 < 5%）
  Minor        // 轻度（5% - 10%）
  Moderate     // 中度（10% - 20%）
  Significant  // 显著（20% - 30%）
  Severe       // 严重（> 30%）
}

pub fn calculate_max_drawdown(Array[Float]) -> Float
pub fn calculate_max_drawdown_detailed(Array[Float], Array[String]) -> DrawdownInfo?
pub fn calculate_drawdown_series(Array[Float]) -> Array[Float]
pub fn calculate_current_drawdown(Array[Float]) -> Float
pub fn find_top_drawdowns(Array[Float], Array[String], Int) -> Array[DrawdownInfo]
pub fn get_drawdown_stats(Array[Float]) -> DrawdownStats
pub fn check_drawdown_alert(Float, DrawdownAlert) -> String
pub fn classify_drawdown(Float) -> DrawdownLevel
pub fn create_monitor(Float, Float) -> DrawdownMonitor
pub fn default_alert_config() -> DrawdownAlert
```

#### 2.5 投资组合 (`src/portfolio/manager.mbt`)

```moonbit
pub struct Position {
  stock : String           // 股票代码
  mut quantity : Float     // 持仓数量
  mut avg_cost : Float     // 平均成本
  mut current_price : Float // 当前价格
}

pub struct Portfolio {
  positions : Array[Position]  // 持仓列表
  mut cash : Float             // 现金
  initial_capital : Float      // 初始资金
}

// Portfolio 方法
pub fn Portfolio::buy(String, Float, Float) -> Bool
pub fn Portfolio::sell(String, Float, Float) -> Bool
pub fn Portfolio::get_position(String) -> Position?
pub fn Portfolio::has_position(String) -> Bool
pub fn Portfolio::position_count() -> Int
pub fn Portfolio::total_value() -> Float
pub fn Portfolio::position_value() -> Float
pub fn Portfolio::position_ratio() -> Float
pub fn Portfolio::get_total_exposure() -> Float
pub fn Portfolio::total_pnl() -> Float
pub fn Portfolio::total_pnl_pct() -> Float
pub fn Portfolio::calculate_position_pnl() -> Float
pub fn Portfolio::calculate_daily_pnl(Map[String, Float], Map[String, Float]) -> Float
pub fn Portfolio::update_prices((String) -> Float) -> Unit

pub fn create_portfolio(Float) -> Portfolio
```

#### 3. 策略接口 (`src/strategy/types.mbt`)

```moonbit
pub struct Signal {
  stock : String
  action : Action
  price : Float
  timestamp : String
  strength : Float      // 信号强度 0.0 - 1.0
}

pub enum Action {
  Buy
  Sell
  Hold
}

pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (KLine, StrategyContext, Array[Float]) -> Signal
}

pub struct StrategyContext {
  capital : Float
  position : Float
  current_price : Float
  last_signal : Signal?
}
```

#### 4. 风控规则 (`src/risk/rules.mbt`)

```moonbit
pub struct RiskRule {
  name : String
  priority : Int
  check_fn : (Float, Float, Float) -> RiskResult
}

pub struct RiskResult {
  passed : Bool
  message : String
  action : RiskAction
}

pub enum RiskAction {
  Allow
  Reject
  ReducePosition(Float)  // 建议减仓比例
  StopTrading
}

// 内置风控规则
pub fn max_drawdown_rule(Float) -> RiskRule
pub fn position_limit_rule(Float) -> RiskRule
pub fn stop_loss_rule(String, Float) -> RiskRule
pub fn single_stock_limit_rule(Float) -> RiskRule
```

#### 5. 回测引擎 (`src/backtest/engine.mbt`)

```moonbit
pub struct BacktestConfig {
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
  benchmark : String?
}

pub struct BacktestResult {
  initial_capital : Float
  final_capital : Float
  total_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  total_trades : Int
  equity_curve : Array[EquityPoint]
  trades : Array[Trade]
  stats : BacktestStats
}

pub fn run_backtest(
  BacktestEngine,
  Array[KLine],
  Strategy
) -> BacktestResult
```

#### 5.5 Walk-Forward 分析引擎 (`src/backtest/walk_forward.mbt`)

```moonbit
pub enum WfMode {
  Rolling    // 滚动窗口模式
  Anchored   // 锚定增长模式
}

pub struct WalkForwardConfig {
  window_size : Int      // 窗口大小（bar 数）
  step_size : Int        // 滚动步长
  oos_ratio : Float      // 样本外比例 (0.0-1.0)
  mode : WfMode          // 滚动或锚定模式
  min_oos_bars : Int     // 最小样本外 bar 数
}

pub struct WfResult {
  window_index : Int
  in_sample_start : Int
  in_sample_end : Int
  oos_start : Int
  oos_end : Int
  is_profit : Float      // 样本内收益
  oos_profit : Float     // 样本外收益
  is_sharpe : Float      // 样本内夏普比率
  oos_sharpe : Float     // 样本外夏普比率
  is_max_dd : Float      // 样本内最大回撤
  oos_max_dd : Float     // 样本外最大回撤
  is_trades : Int        // 样本内交易数
  oos_trades : Int       // 样本外交易数
}

pub struct WfSummary {
  total_windows : Int       // 总窗口数
  successful_windows : Int  // 盈利窗口数
  avg_is_profit : Float     // 平均样本内收益
  avg_oos_profit : Float    // 平均样本外收益
  avg_is_sharpe : Float     // 平均样本内夏普
  avg_oos_sharpe : Float    // 平均样本外夏普
  oos_success_rate : Float  // 样本外成功率
  degradation_ratio : Float // 退化比率 (OOS Sharpe / IS Sharpe)
  robustness_score : Float  // 稳健性评分 (0-100)
}

// Walk-Forward 核心函数
pub fn generate_walk_forward_windows(Int, Int, Int, Float) -> Array[(Int, Int, Int, Int)]
pub fn generate_anchored_windows(Int, Int, Int, Float) -> Array[(Int, Int, Int, Int)]
pub fn generate_wf_windows(WalkForwardConfig, Int) -> Array[(Int, Int, Int, Int)]
pub fn analyze_wf_results(Array[WfResult]) -> WfSummary
pub fn passes_wf_validation(WfSummary) -> Bool
pub fn calculate_sharpe(Array[Float], Float) -> Float
pub fn calculate_max_dd(Array[Float]) -> Float
pub fn calculate_profit(Array[Float]) -> Float
```

#### 5.6 凯利公式仓位优化 (`src/risk/kelly_criterion.mbt`)

```moonbit
pub enum KellyMode {
  Full      // 全凯利 (100%)
  Half      // 半凯利 (50%)
  Quarter   // 四分之一凯利 (25%)
  Custom    // 自定义比例
}

// 凯利公式核心计算
pub fn kelly_fraction(win_rate : Float, win_loss_ratio : Float) -> Float
// Kelly % = W - [(1 - W) / R]

pub fn half_kelly(win_rate : Float, win_loss_ratio : Float) -> Float
pub fn quarter_kelly(win_rate : Float, win_loss_ratio : Float) -> Float

pub fn kelly_position_size(
  win_rate : Float,
  win_loss_ratio : Float,
  capital : Float,
  mode : KellyMode,
  custom_fraction : Float
) -> Float

pub fn calculate_win_rate(wins : Int, losses : Int) -> Float
pub fn calculate_win_loss_ratio(
  total_wins : Float,
  total_losses : Float,
  wins : Int,
  losses : Int
) -> Float
pub fn kelly_from_trades(
  total_wins : Float,
  total_losses : Float,
  wins : Int,
  losses : Int
) -> Float

pub fn kelly_with_cap(kelly_value : Float, max_pct : Float) -> Float
pub fn expected_growth_rate(kelly_fraction : Float, win_rate : Float, win_loss_ratio : Float) -> Float
pub fn is_strategy_suitable_for_kelly(win_rate : Float, win_loss_ratio : Float) -> Bool
```

### CLI 设计 (`cmd/main/main.mbt`)

```
moonbit-drawdown - 量化回撤分析工具

USAGE:
    MOONBIT_CMD=<command> MOONBIT_ARGS="<args>" moon run cmd/main

COMMANDS:
    analyze         分析股票/组合回撤
    backtest        运行策略回测
    monitor         实时监控模式
    report          生成分析报告
    list-strategies 列出所有可用策略
    serve           启动 HTTP API 服务器
    help            显示帮助信息

EXAMPLES:
    # 回测单个策略
    MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31" moon run cmd/main

    # 分析股票最大回撤
    MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000 --metric max_drawdown" moon run cmd/main

    # 批量分析多只股票
    MOONBIT_CMD=analyze MOONBIT_ARGS="--stocks sh.600000,sz.000001 --metrics all" moon run cmd/main

    # 生成报告
    MOONBIT_CMD=report MOONBIT_ARGS="--format html" moon run cmd/main

    # 启动服务器
    MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run cmd/main
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

### 已完成阶段

1. **Phase 1 - 基础框架** ✅
   - 数据类型定义 (`src/data/types.mbt`)
   - CSV 数据加载器 (`src/data/loader.mbt`)
   - 基础回撤计算器 (`src/drawdown/calculator.mbt`)
   - 简单 CLI 命令 (`cmd/main/main.mbt`)

2. **Phase 2 - 策略引擎** ✅
   - 策略接口定义 (`src/strategy/types.mbt`)
   - 回测引擎核心 (`src/backtest/engine.mbt`)
   - 内置策略：均线交叉、动量策略、RSI 均值回归 (`src/strategy/builtins/`)
   - 回测报告生成 (`src/backtest/report.mbt`)

3. **Phase 3 - 风控系统** ✅
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
   - 追踪止损 (`src/risk/trailing_stop.mbt`)
     - `TrailingStop` - 动态止损计算
     - 基于最高价/最低价的追踪止损逻辑
   - 凯利公式仓位优化 (`src/risk/kelly_criterion.mbt`)
     - `kelly_fraction` - 凯利公式核心计算
     - `half_kelly`, `quarter_kelly` - 保守仓位模式
     - `kelly_position_size` - 根据凯利比例计算仓位
   - 与回测引擎集成 (`src/backtest/engine.mbt`)
     - 回测过程中实时检查风控规则
     - 根据风控结果决定是否执行交易信号
   - 测试覆盖 (`src/risk/rules_test.mbt`, `src/risk/trailing_stop_test.mbt`, `src/risk/kelly_criterion_test.mbt`)
     - 30+ 单元测试覆盖所有规则与引擎功能

4. **Phase 4 - HTTP 服务器** ✅
   - 简单 HTTP API 服务器 (`server/server.mbt`)
   - RESTful API 实现
   - 与核心引擎集成

5. **Phase 5 - 技术指标库** ✅
   - 移动平均系列：SMA, EMA, MACD
   - 震荡指标：RSI, KDJ, Williams %R, CCI
   - 趋势指标：ADX, Aroon
   - 波动率指标：ATR, Bollinger Bands
   - 成交量指标：OBV, VWAP
   - 测试覆盖：800+ 单元测试

6. **Phase 6 - Walk-Forward 分析** ✅
   - Walk-Forward 分析引擎 (`src/backtest/walk_forward.mbt`)
     - 滚动窗口模式 (`WfMode::Rolling`)
     - 锚定增长模式 (`WfMode::Anchored`)
     - 样本内/样本外自动划分
     - 稳健性评分系统
   - 回测统计指标
     - 夏普比率计算
     - 最大回撤计算
     - 收益计算
   - Walk-Forward 验证标准
     - 样本外成功率 >= 50%
     - 退化比率 >= 0.5
     - 平均样本外收益 > 0
   - 测试覆盖：20+ 单元测试

### 进行中阶段

7. **Phase 7 - Web 界面** 🚧
   - 静态页面框架
   - 图表可视化
   - API 对接

### 计划中阶段

8. **Phase 8 - 完善与优化**
   - Parquet 格式支持
   - 更多技术指标
   - 更多内置策略
   - 性能优化
   - 文档完善

## 参考资料

- MoonBit 官方文档：https://www.moonbitlang.com
- BaoStock API 文档：https://www.baostock.com
- 量化交易基础（回撤、夏普比率等计算方法）
