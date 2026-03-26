# MoonBit 量化回测框架 - API 参考手册

**版本**: 1.0
**生成日期**: 2026-03-27
**最后更新**: 2026-03-27

---

## 目录

### 第一部分：概述
- [项目简介](#项目简介)
- [快速开始](#快速开始)
- [架构概览](#架构概览)

### 第二部分：核心模块 API
- [数据类型模块 (data)](#第二部分核心模块-api)
- [技术指标模块 (indicator)](#技术指标模块-indicator)
- [投资组合模块 (portfolio)](#投资组合模块-portfolio)
- [风险管理模块 (risk)](#风险管理模块-risk)
- [回撤计算模块 (drawdown)](#回撤计算模块-drawdown)
- [策略引擎模块 (strategy)](#策略引擎模块-strategy)
- [回测引擎模块 (backtest)](#回测引擎模块-backtest)

### 第三部分：使用指南
- [策略开发指南](#第三部分使用指南)
- [回测执行流程](#回测执行流程)
- [最佳实践](#最佳实践)

### 第四部分：附录
- [错误处理](#第四部分附录)
- [数值精度](#数值精度)
- [日期格式](#日期格式)
- [术语表](#术语表)

---

## 项目简介

MoonBit 量化回测框架是使用 MoonBit 语言开发的类型安全量化交易回测框架。

### 核心特性

- **类型安全**: 利用 MoonBit 的类型系统确保策略和回测逻辑的正确性
- **高性能**: 优化的指标计算和回测引擎
- **可扩展**: 模块化架构，易于添加新的策略和指标
- **实时风控**: 内置多种风险管理规则
- **详细报告**: 生成 HTML/Text 格式的回测报告

### 主要功能

| 功能模块 | 描述 |
|----------|------|
| 数据加载 | CSV 格式 K 线数据加载和处理 |
| 技术指标 | SMA/EMA、RSI、MACD、布林带等 |
| 策略引擎 | 策略定义、信号生成 |
| 回测引擎 | 历史数据回测、绩效统计 |
| 风险管理 | 最大回撤、仓位限制、止损规则 |
| 投资组合 | 持仓管理、盈亏计算 |
| 报告生成 | HTML/Text 格式报告 |

---

## 快速开始

### 安装 MoonBit

```bash
moon up
```

### 构建项目

```bash
moon check    # 类型检查
moon build    # 构建项目
moon test     # 运行测试
```

### 运行回测

```bash
moon run cmd/main backtest --strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31
```

---

## 架构概览

### 模块依赖图

```
cmd/main (CLI 入口)
    │
    ▼
src/backtest (回测引擎)
    │
    ├── src/strategy (策略引擎)
    ├── src/portfolio (投资组合)
    ├── src/risk (风险管理)
    └── src/data (数据层)
            │
            └── src/indicator (技术指标)
```

### 数据流

```
CSV 数据 → KLine 数组 → 指标计算 → 策略信号 → 交易执行 → 绩效统计
```

---

## 第二部分：核心模块 API

### 数据类型模块 (data)

**包路径**: `username/alpha/src/data`

#### 类型定义

##### KLine (K 线数据)

```moonbit
pub struct KLine {
  code : String           // 股票代码
  date : String           // 日期 (格式："YYYY-MM-DD")
  time : String?          // 时间 (分钟线需要)
  open : Float            // 开盘价
  high : Float            // 最高价
  low : Float             // 最低价
  close : Float           // 收盘价
  volume : Float          // 成交量
  amount : Float          // 成交额
  turn : Float            // 换手率
}
```

**构造方法**:
```moonbit
KLine::daily(code, date, open, high, low, close, volume, amount, turn) -> KLine
```

**Trait 实现**: `Eq`, `Show`, `ToJson`

##### Frequency (数据频率)

```moonbit
pub enum Frequency {
  Daily      // 日线
  Weekly     // 周线
  Monthly    // 月线
  Minute5    // 5 分钟线
  Minute15   // 15 分钟线
  Minute30   // 30 分钟线
  Minute60   // 60 分钟线
}
```

##### AdjustFactor (复权因子)

```moonbit
pub struct AdjustFactor {
  date : String
  ratio : Float
  dividend : Float
  rights_ratio : Float
  rights_price : Float
}
```

#### 数据加载函数

##### load_klines_from_csv

```moonbit
pub fn load_klines_from_csv(String) -> Result[Array[KLine], String]
```

从 CSV 文件加载 K 线数据。

**示例**:
```moonbit
match data::load_klines_from_csv("data/sh.600000.csv") {
  Ok(klines) => io::println("加载 " + klines.length() + " 条数据"),
  Err(e) => io::println("加载失败：" + e)
}
```

##### parse_csv_content

```moonbit
pub fn parse_csv_content(String) -> Result[Array[KLine], String]
```

解析 CSV 字符串内容。

#### 数据处理函数

##### calculate_returns

```moonbit
pub fn calculate_returns(Array[KLine]) -> Array[Float]
```

计算简单收益率。

##### calculate_log_returns

```moonbit
pub fn calculate_log_returns(Array[KLine]) -> Array[Float]
```

计算对数收益率。

##### resample_klines

```moonbit
pub fn resample_klines(Array[KLine], Frequency) -> Array[KLine]
```

重采样 K 线到指定频率。

**示例**:
```moonbit
let weekly = data::resample_klines(daily_klines, data::Frequency::Weekly)
```

##### trim_klines_to_range

```moonbit
pub fn trim_klines_to_range(Array[KLine], String, String) -> Array[KLine]
```

裁剪 K 线到指定日期范围。

##### sort_klines_by_date

```moonbit
pub fn sort_klines_by_date(Array[KLine]) -> Array[KLine]
```

按日期升序排序。

##### filter_invalid_klines

```moonbit
pub fn filter_invalid_klines(Array[KLine]) -> Array[KLine]
```

过滤无效 K 线。

#### 复权处理

##### apply_forward_adjustment

```moonbit
pub fn apply_forward_adjustment(Array[KLine], Float) -> Array[KLine]
```

应用前复权。

##### apply_backward_adjustment

```moonbit
pub fn apply_backward_adjustment(Array[KLine], Float) -> Array[KLine]
```

应用后复权。

#### 波动率计算

##### calculate_rolling_volatility

```moonbit
pub fn calculate_rolling_volatility(Array[Float], Int) -> Array[Float]
```

计算滚动波动率。

##### annualize_volatility

```moonbit
pub fn annualize_volatility(Float, Int) -> Float
```

年化波动率。

**参数**:
- `daily_volatility` - 日波动率
- `trading_days` - 年交易日数（通常 252）

---

### 技术指标模块 (indicator)

**包路径**: `username/alpha/src/indicator`

#### 趋势类指标

##### sma (简单移动平均)

```moonbit
pub fn sma(Array[Float], Int) -> Array[Float]
```

**参数**:
- `data` - 输入数据
- `period` - 周期

**返回**: SMA 数组

##### ema (指数移动平均)

```moonbit
pub fn ema(Array[Float], Int) -> Array[Float]
```

#### 摆动类指标

##### rsi (相对强弱指标)

```moonbit
pub fn rsi(Array[Float], Int) -> Array[Float]
```

**参数**:
- `prices` - 价格序列
- `period` - 周期（通常 14）

**返回**: RSI 数组（0-100）

##### kdj (随机指标)

```moonbit
pub fn kdj(Array[@data.KLine], Int, Int, Int) -> (Array[Float], Array[Float], Array[Float])
```

**参数**:
- `klines` - K 线数组
- `n` - 周期（通常 9）
- `m1` - K 的平滑周期（通常 3）
- `m2` - D 的平滑周期（通常 3）

**返回**: `(K 值，D 值，J 值)`

##### williams_r (威廉指标)

```moonbit
pub fn williams_r(Array[@data.KLine], Int) -> Array[Float]
```

#### 趋势确认指标

##### macd

```moonbit
pub fn macd(Array[Float], Int, Int, Int) -> (Array[Float], Array[Float], Array[Float])
```

**参数**:
- `prices` - 价格序列
- `fast_period` - 快线周期（通常 12）
- `slow_period` - 慢线周期（通常 26）
- `signal_period` - 信号线周期（通常 9）

**返回**: `(DIF, DEA, MACD 柱)`

##### bollinger_bands (布林带)

```moonbit
pub fn bollinger_bands(Array[Float], Int, Float) -> (Array[Float], Array[Float], Array[Float])
```

**参数**:
- `prices` - 价格序列
- `period` - 周期（通常 20）
- `std_dev` - 标准差倍数（通常 2.0）

**返回**: `(上轨，中轨，下轨)`

#### 成交量指标

##### obv (能量潮)

```moonbit
pub fn obv(Array[@data.KLine]) -> Array[Float]
```

#### 波动率指标

##### atr (平均真实波幅)

```moonbit
pub fn atr(Array[@data.KLine], Int) -> Array[Float]
```

#### 其他指标

##### cci (商品通道指数)

```moonbit
pub fn cci(Array[@data.KLine], Int) -> Array[Float]
```

#### 使用示例

```moonbit
// 计算 MACD
let closes = klines.map(fn(k) { k.close })
let (dif, dea, macd_hist) = indicator::macd(closes, 12, 26, 9)

// 计算 RSI
let rsi_values = indicator::rsi(closes, 14)

// 判断超买超卖
if rsi_values[last] > 70.0 {
  io::println("超买")
} else if rsi_values[last] < 30.0 {
  io::println("超卖")
}
```

---

### 投资组合模块 (portfolio)

**包路径**: `username/alpha/src/portfolio`

#### 类型定义

##### Position (持仓)

```moonbit
pub struct Position {
  stock : String
  mut quantity : Float
  mut avg_cost : Float
  mut current_price : Float
}
```

**方法**:
- `value() -> Float` - 持仓市值
- `pnl() -> Float` - 持仓盈亏
- `pnl_pct() -> Float` - 盈亏比例

##### Portfolio (投资组合)

```moonbit
pub struct Portfolio {
  positions : Array[Position]
  mut cash : Float
  initial_capital : Float
}
```

**方法**:
- `buy(stock, quantity, price) -> Bool`
- `sell(stock, quantity, price) -> Bool`
- `get_position(stock) -> Position?`
- `has_position(stock) -> Bool`
- `position_count() -> Int`
- `total_value() -> Float`
- `position_value() -> Float`
- `position_ratio() -> Float`
- `get_total_exposure() -> Float`
- `total_pnl() -> Float`
- `total_pnl_pct() -> Float`
- `calculate_position_pnl() -> Float`
- `calculate_daily_pnl(current, prev) -> Float`
- `update_prices(price_func) -> Unit`

#### 函数

##### create_portfolio

```moonbit
pub fn create_portfolio(Float) -> Portfolio
```

创建投资组合。

**示例**:
```moonbit
let mut portfolio = portfolio::create_portfolio(1_000_000.0)
portfolio.buy("sh.600000", 1000, 10.5)
io::println("总市值：" + portfolio.total_value())
```

---

### 风险管理模块 (risk)

**包路径**: `username/alpha/src/risk`

#### 类型定义

##### RiskAction (风控动作)

```moonbit
pub enum RiskAction {
  Allow                    // 允许
  Reject                   // 拒绝
  ReducePosition(Float)    // 减仓
  StopTrading              // 停止交易
}
```

##### RiskResult (风控结果)

```moonbit
pub struct RiskResult {
  passed : Bool
  message : String
  action : RiskAction
}
```

##### RiskRule (风控规则)

```moonbit
pub struct RiskRule {
  name : String
  priority : Int
  check_fn : (Float, Float, Float) -> RiskResult
}
```

##### RiskEngine (风控引擎)

```moonbit
pub struct RiskEngine {
  rules : Array[RiskRule]
  mut stopped : Bool
  violations : Array[String]
}
```

**方法**:
- `add_rule(rule) -> Unit`
- `check(drawdown, daily_loss, position) -> RiskResult`

#### 内置风控规则

##### max_drawdown_rule

```moonbit
pub fn max_drawdown_rule(Float) -> RiskRule
```

最大回撤规则。

##### position_limit_rule

```moonbit
pub fn position_limit_rule(Float) -> RiskRule
```

仓位限制规则。

##### daily_loss_limit_rule

```moonbit
pub fn daily_loss_limit_rule(Float) -> RiskRule
```

日损限制规则。

##### stop_loss_rule

```moonbit
pub fn stop_loss_rule(String, Float) -> RiskRule
```

止损规则。

##### single_stock_limit_rule

```moonbit
pub fn single_stock_limit_rule(Float) -> RiskRule
```

单股集中度限制。

##### take_profit_rule

```moonbit
pub fn take_profit_rule(Float) -> RiskRule
```

止盈规则。

#### 辅助函数

```moonbit
pub fn risk_result_pass(String) -> RiskResult
pub fn risk_result_fail(String, RiskAction) -> RiskResult
pub fn risk_action_allow() -> RiskAction
pub fn risk_action_reject() -> RiskAction
pub fn risk_action_reduce_position(Float) -> RiskAction
pub fn risk_action_stop_trading() -> RiskAction
```

#### 使用示例

```moonbit
let mut risk_engine = risk::create_risk_engine()
risk_engine.add_rule(risk::max_drawdown_rule(0.2))
risk_engine.add_rule(risk::position_limit_rule(0.9))

let result = risk_engine.check(0.15, 0.02, 0.85)
if !result.passed {
  io::println("风控未通过：" + result.message)
}
```

---

### 回撤计算模块 (drawdown)

**包路径**: `username/alpha/src/drawdown`

#### 类型定义

##### DrawdownInfo (回撤信息)

```moonbit
pub struct DrawdownInfo {
  peak : Float
  trough : Float
  peak_date : String
  trough_date : String
  drawdown : Float
  duration : Int
  recovered : Bool
}
```

##### DrawdownLevel (回撤级别)

```moonbit
pub enum DrawdownLevel {
  Normal       // < 5%
  Minor        // 5-10%
  Moderate     // 10-20%
  Significant  // 20-30%
  Severe       // > 30%
}
```

##### DrawdownAlert (回撤预警)

```moonbit
pub struct DrawdownAlert {
  warning_threshold : Float
  critical_threshold : Float
  max_threshold : Float
}
```

##### DrawdownMonitor (回撤监控器)

```moonbit
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
```

**方法**:
- `update(value, date) -> Unit`
- `get_drawdown() -> Float`
- `get_alert_level() -> String`
- `is_alert_triggered() -> Bool`
- `get_info() -> DrawdownInfo`
- `reset() -> Unit`

#### 回撤计算函数

##### calculate_max_drawdown

```moonbit
pub fn calculate_max_drawdown(Array[Float]) -> Float
```

计算最大回撤。

##### calculate_max_drawdown_detailed

```moonbit
pub fn calculate_max_drawdown_detailed(Array[Float], Array[String]) -> DrawdownInfo?
```

计算最大回撤（详细）。

##### calculate_current_drawdown

```moonbit
pub fn calculate_current_drawdown(Array[Float]) -> Float
```

计算当前回撤。

##### calculate_drawdown_series

```moonbit
pub fn calculate_drawdown_series(Array[Float]) -> Array[Float]
```

计算回撤序列。

##### find_top_drawdowns

```moonbit
pub fn find_top_drawdowns(Array[Float], Array[String], Int) -> Array[DrawdownInfo]
```

找出前 N 个最大回撤。

#### 回撤统计

##### get_drawdown_stats

```moonbit
pub fn get_drawdown_stats(Array[Float]) -> DrawdownStats
```

**DrawdownStats**:
```moonbit
pub struct DrawdownStats {
  max_drawdown : Float
  current_drawdown : Float
  avg_drawdown : Float
  drawdown_count : Int
}
```

#### 预警函数

##### check_drawdown_alert

```moonbit
pub fn check_drawdown_alert(Float, DrawdownAlert) -> String
```

##### classify_drawdown

```moonbit
pub fn classify_drawdown(Float) -> DrawdownLevel
```

##### default_alert_config

```moonbit
pub fn default_alert_config() -> DrawdownAlert
```

##### create_monitor

```moonbit
pub fn create_monitor(Float, Float) -> DrawdownMonitor
```

#### 使用示例

```moonbit
let equity = [1.0, 1.1, 1.05, 1.2, 0.9, 1.0]
let max_dd = drawdown::calculate_max_drawdown(equity)
io::println("最大回撤：" + max_dd * 100 + "%")

let mut monitor = drawdown::create_monitor(-0.05, -0.10)
monitor.update(1.0, "2024-01-01")
monitor.update(1.1, "2024-01-02")
```

---

### 策略引擎模块 (strategy)

**包路径**: `username/alpha/src/strategy`

#### 类型定义

##### Action (交易动作)

```moonbit
pub enum Action {
  Buy
  Sell
  Hold
}
```

##### Signal (交易信号)

```moonbit
pub struct Signal {
  stock : String
  action : Action
  price : Float
  timestamp : String
  strength : Float
}
```

**构造方法**:
- `Signal::buy(stock, price, timestamp, strength)`
- `Signal::sell(stock, price, timestamp, strength)`
- `Signal::hold(stock, price, timestamp)`

##### StrategyContext (策略上下文)

```moonbit
pub struct StrategyContext {
  capital : Float
  position : Float
  current_price : Float
  last_signal : Signal?
}
```

##### Strategy (策略)

```moonbit
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext, Array[Float]) -> Signal
}
```

##### StrategyEngine (策略引擎)

```moonbit
pub struct StrategyEngine {
  capital : Float
  position : Float
  last_price : Float
  signals : Array[Signal]
  results : Array[StrategyResult]
}
```

##### StrategyResult (策略结果)

```moonbit
pub struct StrategyResult {
  signal : Signal
  executed : Bool
  exec_price : Float
  exec_volume : Float
}
```

##### BacktestConfig (回测配置)

```moonbit
pub struct BacktestConfig {
  start_date : String
  end_date : String
  initial_capital : Float
  commission_rate : Float
  slippage : Float
  benchmark : String?
}
```

#### 函数

##### create_strategy_engine

```moonbit
pub fn create_strategy_engine(Float) -> StrategyEngine
```

##### process_bar

```moonbit
pub fn process_bar(StrategyEngine, Strategy, @data.KLine, Array[Float]) -> StrategyResult
```

##### get_engine_stats

```moonbit
pub fn get_engine_stats(StrategyEngine) -> (Float, Float, Int)
```

##### default_backtest_config

```moonbit
pub fn default_backtest_config() -> BacktestConfig
```

#### 策略示例

```moonbit
pub fn ma_cross_strategy() -> Strategy {
  Strategy {
    name: "MA Cross",
    on_init: fn(_) { io::println("策略初始化") },
    on_bar: fn(kline, ctx, indicators) {
      let ma5 = indicators[0]
      let ma20 = indicators[1]
      if ma5 > ma20 && ctx.position == 0.0 {
        Signal::buy(kline.code, kline.close, kline.date, 0.8)
      } else if ma5 < ma20 && ctx.position > 0.0 {
        Signal::sell(kline.code, kline.close, kline.date, 0.8)
      } else {
        Signal::hold(kline.code, kline.close, kline.date)
      }
    }
  }
}
```

---

### 回测引擎模块 (backtest)

**包路径**: `username/alpha/src/backtest`

#### 类型定义

##### BacktestEngine (回测引擎)

```moonbit
pub struct BacktestEngine {
  config : @strategy.BacktestConfig
  portfolio : @portfolio.Portfolio
  risk_engine : @risk.RiskEngine
  trades : Array[Trade]
  equity_curve : Array[EquityPoint]
  current_date : String
  current_equity : Float
  peak_equity : Float
  max_drawdown : Float
}
```

##### BacktestResult (回测结果)

```moonbit
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
```

##### BacktestStats (回测统计)

```moonbit
pub struct BacktestStats {
  total_return : Float
  annual_return : Float
  max_drawdown : Float
  sharpe_ratio : Float
  sortino_ratio : Float
  win_rate : Float
  profit_factor : Float
  total_trades : Int
  winning_trades : Int
  losing_trades : Int
  avg_win : Float
  avg_loss : Float
  avg_trade_duration : Float
}
```

##### EquityPoint (权益点)

```moonbit
pub struct EquityPoint {
  date : String
  equity : Float
  drawdown : Float
  position : Float
  cash : Float
}
```

##### Trade (交易记录)

```moonbit
pub struct Trade {
  stock : String
  action : @strategy.Action
  price : Float
  quantity : Float
  timestamp : String
  commission : Float
}
```

##### ReportConfig (报告配置)

```moonbit
pub struct ReportConfig {
  title : String
  author : String
  date : String
  format : ReportFormat
  include_equity_curve : Bool
  include_trades : Bool
  include_stats : Bool
}
```

##### ReportFormat (报告格式)

```moonbit
pub enum ReportFormat {
  Html
  Text
}
```

#### 回测函数

##### create_backtest_engine

```moonbit
pub fn create_backtest_engine(@strategy.BacktestConfig) -> BacktestEngine
```

##### run_backtest

```moonbit
pub fn run_backtest(BacktestEngine, Array[@data.KLine], @strategy.Strategy) -> BacktestResult
```

#### 报告生成

##### generate_report

```moonbit
pub fn generate_report(BacktestResult, ReportConfig) -> String
```

##### print_report

```moonbit
pub fn print_report(BacktestResult, ReportFormat) -> Unit
```

##### save_report_to_file

```moonbit
pub fn save_report_to_file(BacktestResult, String, ReportFormat) -> Result[Unit, String]
```

#### 辅助函数

```moonbit
pub fn action_to_string(@strategy.Action) -> String
pub fn default_report_config() -> ReportConfig
pub fn create_trade_log() -> TradeLog
```

#### 完整回测示例

```moonbit
// 配置回测
let config = @strategy.BacktestConfig {
  start_date: "2023-01-01",
  end_date: "2023-12-31",
  initial_capital: 1_000_000.0,
  commission_rate: 0.0003,
  slippage: 0.001,
  benchmark: None,
}

// 创建引擎
let engine = backtest::create_backtest_engine(config)

// 运行回测
let result = backtest::run_backtest(engine, klines, strategy)

// 打印报告
backtest::print_report(result, backtest::ReportFormat::Text)

// 保存报告
match backtest::save_report_to_file(result, "report.html", backtest::ReportFormat::Html) {
  Ok(_) => io::println("报告已保存"),
  Err(e) => io::println("保存失败：" + e)
}
```

---

## 第三部分：使用指南

### 策略开发指南

#### 策略结构

所有策略都遵循统一的结构：

```moonbit
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext, Array[Float]) -> Signal
}
```

#### 策略开发步骤

1. **定义策略逻辑**
   - 确定入场条件
   - 确定出场条件
   - 确定信号强度

2. **实现策略代码**
   ```moonbit
   pub fn my_strategy() -> Strategy {
     Strategy {
       name: "My Strategy",
       on_init: fn(ctx) { /* 初始化 */ },
       on_bar: fn(kline, ctx, indicators) { /* 策略逻辑 */ }
     }
   }
   ```

3. **测试策略**
   ```moonbit
   moon test
   ```

4. **运行回测**
   ```bash
   moon run cmd/main backtest --strategy my_strategy
   ```

#### 常用策略模式

##### 趋势跟踪

```moonbit
// 均线交叉
if ma5 > ma20 { Buy } else if ma5 < ma20 { Sell }
```

##### 均值回归

```moonbit
// 布林带突破
if price < lower_band { Buy } else if price > upper_band { Sell }
```

##### 动量策略

```moonbit
// RSI 超卖超买
if rsi < 30 { Buy } else if rsi > 70 { Sell }
```

---

### 回测执行流程

```
1. 加载数据 (load_klines_from_csv)
       ↓
2. 计算指标 (indicator::*)
       ↓
3. 创建策略 (Strategy)
       ↓
4. 配置回测 (BacktestConfig)
       ↓
5. 创建引擎 (create_backtest_engine)
       ↓
6. 运行回测 (run_backtest)
       ↓
7. 生成报告 (print_report)
```

---

### 最佳实践

#### 代码组织

- 将策略放在 `src/strategy/builtins/` 目录
- 为策略文件添加清晰的文档注释
- 使用有意义的变量和函数名称

#### 测试

- 为每个策略编写单元测试
- 测试边界条件（零资本、极端价格）
- 使用快照测试验证报告格式

#### 性能

- 避免在 `on_bar` 中重复计算指标
- 使用指标缓存层
- 预计算常用数据

#### 风险管理

- 始终使用风控规则
- 设置合理的回撤阈值
- 监控单股集中度

---

## 第四部分：附录

### 错误处理

所有可能失败的函数返回 `Result[T, String]`：

```moonbit
match data::load_klines_from_csv("data.csv") {
  Ok(klines) => { /* 成功处理 */ },
  Err(e) => { /* 错误处理 */ }
}
```

### 数值精度

- 价格计算使用 `Float` 类型
- 百分比用小数表示（0.05 = 5%）
- 回撤值为负数（-0.1 = -10%）

### 日期格式

所有日期使用 `YYYY-MM-DD` 格式：

```moonbit
"2023-01-01"  // 正确
"01/01/2023"  // 错误
```

### 术语表

| 术语 | 英文 | 说明 |
|------|------|------|
| K 线 | Candlestick | 开盘价、最高价、最低价、收盘价 |
| 回撤 | Drawdown | 从峰值到谷值的跌幅 |
| 夏普比率 | Sharpe Ratio | 风险调整后收益指标 |
| 移动平均 | Moving Average | 一定期间内平均价格 |
| 相对强弱指标 | RSI | 动量 oscillator |
| 布林带 | Bollinger Bands | 波动率通道指标 |

---

## 索引

### A
- Action (类型)
- apply_backward_adjustment()
- apply_forward_adjustment()
- annualize_volatility()
- atr()

### B
- BacktestConfig (类型)
- BacktestEngine (类型)
- BacktestResult (类型)
- BacktestStats (类型)
- bollinger_bands()

### C
- calculate_current_drawdown()
- calculate_drawdown_series()
- calculate_log_returns()
- calculate_max_drawdown()
- calculate_returns()
- calculate_rolling_volatility()
- cci()
- classify_drawdown()
- create_backtest_engine()
- create_monitor()
- create_portfolio()
- create_risk_engine()
- create_strategy_engine()

### D
- daily_loss_limit_rule()
- data 模块
- drawdown 模块
- DrawdownAlert (类型)
- DrawdownInfo (类型)
- DrawdownLevel (类型)
- DrawdownMonitor (类型)

### E
- ema()

### F
- filter_invalid_klines()
- Frequency (类型)

### K
- KLine (类型)
- kdj()

### L
- load_klines_from_csv()

### M
- macd()
- max_drawdown_rule()

### O
- obv()

### P
- parse_csv_content()
- portfolio 模块
- Position (类型)
- Portfolio (类型)
- position_limit_rule()

### R
- resample_klines()
- risk 模块
- RiskAction (类型)
- RiskEngine (类型)
- RiskResult (类型)
- RiskRule (类型)
- rsi()
- run_backtest()

### S
- single_stock_limit_rule()
- sma()
- sort_klines_by_date()
- stop_loss_rule()
- strategy 模块
- Strategy (类型)
- StrategyContext (类型)
- StrategyEngine (类型)
- StrategyResult (类型)

### T
- take_profit_rule()
- trim_klines_to_range()

### W
- williams_r()

---

*文档版本：1.0*
*最后更新：2026-03-27*
*MoonBit 量化回测框架*
