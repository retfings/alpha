# MoonBit 量化回撤框架 - API 参考文档

本文档提供框架核心模块的完整 API 参考，包括类型定义、函数说明和使用示例。

## 目录

- [数据类型模块 (data)](#数据类型模块-data)
- [回撤计算模块 (drawdown)](#回撤计算模块-drawdown)
- [投资组合模块 (portfolio)](#投资组合模块-portfolio)
- [风险管理模块 (risk)](#风险管理模块-risk)
- [策略引擎模块 (strategy)](#策略引擎模块-strategy)
- [技术指标模块 (indicator)](#技术指标模块-indicator)
- [回测引擎模块 (backtest)](#回测引擎模块-backtest)

---

## 数据类型模块 (data)

**包路径**: `username/alpha/src/data`

### 核心类型

#### KLine (K 线数据类型)

```moonbit
pub struct KLine {
  code : String           // 股票代码
  date : String           // 日期 (格式："YYYY-MM-DD")
  time : String?          // 时间 (分钟线需要，日线为 None)
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
- `KLine::daily(code, date, open, high, low, close, volume, amount, turn)` - 创建日线 K 线

**Trait 实现**: `Eq`, `Show`, `ToJson`

#### Frequency (数据频率枚举)

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

#### AdjustFactor (复权因子)

```moonbit
pub struct AdjustFactor {
  date : String       // 除权除息日
  ratio : Float       // 配股比例
  dividend : Float    // 每股分红
  rights_ratio : Float // 配股比例
  rights_price : Float // 配股价格
}
```

### 数据加载函数

#### load_klines_from_csv

```moonbit
pub fn load_klines_from_csv(String) -> Result[Array[KLine], String]
```

从 CSV 文件加载 K 线数据。

**参数**:
- `file_path` - CSV 文件路径

**返回**:
- `Ok(Array[KLine])` - K 线数组
- `Err(String)` - 错误信息

**示例**:
```moonbit
match data::load_klines_from_csv("data/sh.600000.csv") {
  Ok(klines) => {
    io::println("加载成功：" + String::from_int(klines.length()))
  }
  Err(e) => {
    io::println("加载失败：" + e)
  }
}
```

#### parse_csv_content

```moonbit
pub fn parse_csv_content(String) -> Result[Array[KLine], String]
```

解析 CSV 字符串内容为 K 线数组。

### 数据处理函数

#### calculate_returns

```moonbit
pub fn calculate_returns(Array[KLine]) -> Array[Float]
```

计算 K 线序列的收益率（简单收益率）。

**返回**: 收益率数组，长度比输入少 1

#### calculate_log_returns

```moonbit
pub fn calculate_log_returns(Array[KLine]) -> Array[Float]
```

计算 K 线序列的对数收益率。

#### resample_klines

```moonbit
pub fn resample_klines(Array[KLine], Frequency) -> Array[KLine]
```

重采样 K 线到指定频率。

**参数**:
- `klines` - 原始 K 线数组
- `freq` - 目标频率

**示例**:
```moonbit
// 将日线重采样为周线
let weekly = data::resample_klines(daily_klines, data::Frequency::Weekly)
```

#### trim_klines_to_range

```moonbit
pub fn trim_klines_to_range(Array[KLine], String, String) -> Array[KLine]
```

裁剪 K 线到指定日期范围。

**参数**:
- `klines` - K 线数组
- `start_date` - 开始日期
- `end_date` - 结束日期

#### sort_klines_by_date

```moonbit
pub fn sort_klines_by_date(Array[KLine]) -> Array[KLine]
```

按日期对 K 线进行排序（升序）。

#### filter_invalid_klines

```moonbit
pub fn filter_invalid_klines(Array[KLine]) -> Array[KLine]
```

过滤掉无效的 K 线（如零价格、零成交量等）。

### 复权处理函数

#### apply_forward_adjustment

```moonbit
pub fn apply_forward_adjustment(Array[KLine], Float) -> Array[KLine]
```

应用前复权到 K 线序列。

#### apply_backward_adjustment

```moonbit
pub fn apply_backward_adjustment(Array[KLine], Float) -> Array[KLine]
```

应用后复权到 K 线序列。

### 波动率计算函数

#### calculate_rolling_volatility

```moonbit
pub fn calculate_rolling_volatility(Array[Float], Int) -> Array[Float]
```

计算滚动波动率。

**参数**:
- `returns` - 收益率数组
- `window` - 滚动窗口大小

**返回**: 滚动波动率数组

#### annualize_volatility

```moonbit
pub fn annualize_volatility(Float, Int) -> Float
```

将日波动率年化。

**参数**:
- `daily_volatility` - 日波动率
- `trading_days` - 年交易日数（通常用 252）

**返回**: 年化波动率

---

## 技术指标模块 (indicator)

**包路径**: `username/alpha/src/indicator`

所有指标函数都接受数据数组并返回计算结果数组。

### 趋势类指标

#### sma (简单移动平均)

```moonbit
pub fn sma(Array[Float], Int) -> Array[Float]
```

**参数**:
- `data` - 输入数据（通常为收盘价）
- `period` - 周期

**返回**: SMA 数组（前 `period-1` 个元素为 0 或无效值）

#### ema (指数移动平均)

```moonbit
pub fn ema(Array[Float], Int) -> Array[Float]
```

### 摆动类指标

#### rsi (相对强弱指标)

```moonbit
pub fn rsi(Array[Float], Int) -> Array[Float]
```

**参数**:
- `prices` - 价格序列
- `period` - 周期（通常用 14）

**返回**: RSI 数组（值域 0-100）

#### kdj (随机指标)

```moonbit
pub fn kdj(Array[@data.KLine], Int, Int, Int) -> (Array[Float], Array[Float], Array[Float])
```

**参数**:
- `klines` - K 线数组
- `n` - 周期（通常用 9）
- `m1` - K 的平滑周期（通常用 3）
- `m2` - D 的平滑周期（通常用 3）

**返回**: `(K 值数组，D 值数组，J 值数组)`

#### williams_r (威廉指标)

```moonbit
pub fn williams_r(Array[@data.KLine], Int) -> Array[Float]
```

### 趋势确认指标

#### macd (平滑异同移动平均)

```moonbit
pub fn macd(Array[Float], Int, Int, Int) -> (Array[Float], Array[Float], Array[Float])
```

**参数**:
- `prices` - 价格序列
- `fast_period` - 快线周期（通常用 12）
- `slow_period` - 慢线周期（通常用 26）
- `signal_period` - 信号线周期（通常用 9）

**返回**: `(DIF 数组，DEA 数组，MACD 柱状图数组)`

#### bollinger_bands (布林带)

```moonbit
pub fn bollinger_bands(Array[Float], Int, Float) -> (Array[Float], Array[Float], Array[Float])
```

**参数**:
- `prices` - 价格序列
- `period` - 周期（通常用 20）
- `std_dev` - 标准差倍数（通常用 2.0）

**返回**: `(上轨数组，中轨数组，下轨数组)`

### 成交量指标

#### obv (能量潮)

```moonbit
pub fn obv(Array[@data.KLine]) -> Array[Float]
```

### 波动率指标

#### atr (平均真实波幅)

```moonbit
pub fn atr(Array[@data.KLine], Int) -> Array[Float]
```

**参数**:
- `klines` - K 线数组
- `period` - 周期（通常用 14）

### 其他指标

#### cci (商品通道指数)

```moonbit
pub fn cci(Array[@data.KLine], Int) -> Array[Float]
```

**使用示例**:
```moonbit
// 计算 MACD
let closes = klines.map(fn(k) { k.close })
let (dif, dea, macd_hist) = indicator::macd(closes, 12, 26, 9)

// 计算 RSI
let rsi_values = indicator::rsi(closes, 14)

// 判断超买超卖
let last_rsi = rsi_values[rsi_values.length() - 1]
if last_rsi > 70.0 {
  io::println("超买信号")
} else if last_rsi < 30.0 {
  io::println("超卖信号")
}

// 布林带突破
let (upper, middle, lower) = indicator::bollinger_bands(closes, 20, 2.0)
if current_price > upper[last] {
  io::println("上轨突破")
}
```

---

## 投资组合模块 (portfolio)

**包路径**: `username/alpha/src/portfolio`

### 核心类型

#### Position (持仓)

```moonbit
pub struct Position {
  stock : String        // 股票代码
  mut quantity : Float  // 持仓数量
  mut avg_cost : Float  // 平均成本
  mut current_price : Float  // 当前价格
}
```

**方法**:
- `value()` - 持仓市值
- `pnl()` - 持仓盈亏（绝对值）
- `pnl_pct()` - 持仓盈亏比例

**Trait 实现**: `Eq`, `Show`

#### Portfolio (投资组合)

```moonbit
pub struct Portfolio {
  positions : Array[Position]  // 持仓列表
  mut cash : Float             // 现金
  initial_capital : Float      // 初始资金
}
```

**方法**:
- `buy(stock, quantity, price)` - 买入
- `sell(stock, quantity, price)` - 卖出
- `get_position(stock)` - 获取持仓
- `has_position(stock)` - 是否持有
- `position_count()` - 持仓数量
- `total_value()` - 组合总市值
- `position_value()` - 持仓总市值
- `position_ratio()` - 仓位比例
- `get_total_exposure()` - 总敞口
- `total_pnl()` - 总盈亏
- `total_pnl_pct()` - 总盈亏比例
- `calculate_position_pnl()` - 计算持仓盈亏
- `calculate_daily_pnl(current_prices, prev_prices)` - 计算日盈亏
- `update_prices(price_func)` - 更新持仓价格

**Trait 实现**: `Show`

### 投资组合函数

#### create_portfolio

```moonbit
pub fn create_portfolio(Float) -> Portfolio
```

创建新的投资组合。

**参数**: `initial_capital` - 初始资金

**返回**: 新的 Portfolio 实例

**示例**:
```moonbit
// 创建初始资金为 100 万的组合
let mut portfolio = portfolio::create_portfolio(1_000_000.0)

// 买入股票
portfolio.buy("sh.600000", 1000, 10.5)

// 查询持仓
match portfolio.get_position("sh.600000") {
  Some(pos) => {
    io::println("持仓市值：" + String::from_float(pos.value()))
  }
  None => io::println("无持仓")
}

// 获取组合信息
io::println("总市值：" + String::from_float(portfolio.total_value()))
io::println("仓位：" + String::from_float(portfolio.position_ratio() * 100) + "%")
```

---

## 风险管理模块 (risk)

**包路径**: `username/alpha/src/risk`

### 核心类型

#### RiskAction (风控动作)

```moonbit
pub enum RiskAction {
  Allow                    // 允许交易
  Reject                   // 拒绝交易
  ReducePosition(Float)    // 减仓（参数为建议减仓比例）
  StopTrading              // 停止交易
}
```

**Trait 实现**: `Eq`, `Show`

#### RiskResult (风控结果)

```moonbit
pub struct RiskResult {
  passed : Bool       // 是否通过
  message : String    // 结果说明
  action : RiskAction // 执行动作
}
```

#### RiskRule (风控规则)

```moonbit
pub struct RiskRule {
  name : String                           // 规则名称
  priority : Int                          // 优先级（数字越小优先级越高）
  check_fn : (Float, Float, Float) -> RiskResult  // 检查函数
}
```

**Trait 实现**: `Show`

#### RiskEngine (风控引擎)

```moonbit
pub struct RiskEngine {
  rules : Array[RiskRule]    // 规则列表
  mut stopped : Bool         // 是否已停止交易
  violations : Array[String] // 违规记录
}
```

**方法**:
- `add_rule(rule)` - 添加规则
- `check(current_drawdown, daily_loss, position_ratio)` - 执行检查

### 风控引擎函数

#### create_risk_engine

```moonbit
pub fn create_risk_engine() -> RiskEngine
```

创建风控引擎实例。

### 内置风控规则

#### max_drawdown_rule

```moonbit
pub fn max_drawdown_rule(Float) -> RiskRule
```

最大回撤规则：当回撤超过阈值时停止交易。

**参数**: `max_drawdown` - 最大回撤阈值（如 0.2 表示 20%）

#### position_limit_rule

```moonbit
pub fn position_limit_rule(Float) -> RiskRule
```

仓位限制规则：当仓位超过阈值时拒绝新开仓。

**参数**: `max_position_ratio` - 最大仓位比例（如 0.9 表示 90%）

#### daily_loss_limit_rule

```moonbit
pub fn daily_loss_limit_rule(Float) -> RiskRule
```

日损限制规则：当日亏损超过阈值时停止交易。

**参数**: `max_daily_loss` - 最大日损比例

#### stop_loss_rule

```moonbit
pub fn stop_loss_rule(String, Float) -> RiskRule
```

止损规则：当个股/组合亏损超过阈值时减仓。

**参数**:
- `stock_code` - 股票代码（空字符串表示组合级别）
- `stop_loss_ratio` - 止损阈值

#### single_stock_limit_rule

```moonbit
pub fn single_stock_limit_rule(Float) -> RiskRule
```

单股集中度限制规则：当单股持仓超过阈值时减仓。

**参数**: `max_single_ratio` - 单股最大持仓比例

#### take_profit_rule

```moonbit
pub fn take_profit_rule(Float) -> RiskRule
```

止盈规则：当盈利超过阈值时部分减仓锁定利润。

**参数**: `take_profit_ratio` - 止盈阈值

#### total_exposure_limit_rule

```moonbit
pub fn total_exposure_limit_rule(Float) -> RiskRule
```

总敞口限制规则：限制组合总风险敞口。

### 辅助函数

#### risk_result_pass

```moonbit
pub fn risk_result_pass(String) -> RiskResult
```

创建通过的风控结果。

#### risk_result_fail

```moonbit
pub fn risk_result_fail(String, RiskAction) -> RiskResult
```

创建失败的风控结果。

#### risk_action_* 系列函数

```moonbit
pub fn risk_action_allow() -> RiskAction
pub fn risk_action_reject() -> RiskAction
pub fn risk_action_reduce_position(Float) -> RiskAction
pub fn risk_action_stop_trading() -> RiskAction
```

创建对应的风控动作。

**使用示例**:
```moonbit
// 创建风控引擎
let mut risk_engine = risk::create_risk_engine()

// 添加规则
risk_engine.add_rule(risk::max_drawdown_rule(0.2))
risk_engine.add_rule(risk::position_limit_rule(0.9))
risk_engine.add_rule(risk::single_stock_limit_rule(0.3))

// 执行检查
let result = risk_engine.check(
  current_drawdown=0.15,  // 当前回撤 15%
  daily_loss=0.02,        // 日损 2%
  position_ratio=0.85     // 仓位 85%
)

if !result.passed {
  io::println("风控未通过：" + result.message)
}
```

---

## 回撤计算模块 (drawdown)

**包路径**: `username/alpha/src/drawdown`

### 核心类型

#### DrawdownInfo (回撤信息)

```moonbit
pub struct DrawdownInfo {
  peak : Float          // 峰值
  trough : Float        // 谷底
  peak_date : String    // 峰值日期
  trough_date : String  // 谷底日期
  drawdown : Float      // 回撤幅度（负值）
  duration : Int        // 回撤持续天数
  recovered : Bool      // 是否已恢复
}
```

**Trait 实现**: `Eq`, `Show`, `ToJson`

#### DrawdownLevel (回撤级别)

```moonbit
pub enum DrawdownLevel {
  Normal       // 正常（回撤 < 5%）
  Minor        // 轻度（5% - 10%）
  Moderate     // 中度（10% - 20%）
  Significant  // 显著（20% - 30%）
  Severe       // 严重（> 30%）
}
```

#### DrawdownAlert (回撤预警配置)

```moonbit
pub struct DrawdownAlert {
  warning_threshold : Float   // 预警阈值（如 -0.05）
  critical_threshold : Float  // 临界阈值（如 -0.10）
  max_threshold : Float       // 最大阈值（如 -0.20）
}
```

#### DrawdownMonitor (回撤监控器)

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
- `update(value, date)` - 更新监控器
- `get_drawdown()` - 获取当前回撤
- `get_alert_level()` - 获取预警级别
- `is_alert_triggered()` - 是否触发预警
- `get_info()` - 获取回撤详情
- `reset()` - 重置监控器

### 回撤计算函数

#### calculate_max_drawdown

```moonbit
pub fn calculate_max_drawdown(Array[Float]) -> Float
```

计算序列的最大回撤值。

**参数**: `values` - 净值/价格序列

**返回**: 最大回撤（负值）

**示例**:
```moonbit
let equity_curve = [1.0, 1.1, 1.05, 1.2, 0.9, 1.0]
let max_dd = drawdown::calculate_max_drawdown(equity_curve)
// 输出：-0.25 (从 1.2 跌到 0.9，回撤 25%)
```

#### calculate_max_drawdown_detailed

```moonbit
pub fn calculate_max_drawdown_detailed(Array[Float], Array[String]) -> DrawdownInfo?
```

计算最大回撤并返回详细信息。

**参数**:
- `values` - 净值/价格序列
- `dates` - 对应的日期序列

**返回**: `DrawdownInfo` 结构体，包含峰值、谷底、日期等详细信息

#### calculate_current_drawdown

```moonbit
pub fn calculate_current_drawdown(Array[Float]) -> Float
```

计算当前回撤（序列最后一个值相对于历史峰值的回撤）。

#### calculate_drawdown_series

```moonbit
pub fn calculate_drawdown_series(Array[Float]) -> Array[Float]
```

计算每个时间点的回撤，返回回撤序列。

**返回**: 与输入等长的回撤数组

#### calculate_drawdown_from_klines

```moonbit
pub fn calculate_drawdown_from_klines(Array[@data.KLine]) -> Float
```

直接从 K 线序列计算最大回撤（使用收盘价）。

#### find_top_drawdowns

```moonbit
pub fn find_top_drawdowns(Array[Float], Array[String], Int) -> Array[DrawdownInfo]
```

找出前 N 个最大的回撤事件。

**参数**:
- `values` - 净值序列
- `dates` - 日期序列
- `n` - 返回数量

**返回**: `DrawdownInfo` 数组，按回撤幅度排序

### 回撤统计函数

#### get_drawdown_stats

```moonbit
pub fn get_drawdown_stats(Array[Float]) -> DrawdownStats
```

获取回撤统计信息。

**返回**:
```moonbit
pub struct DrawdownStats {
  max_drawdown : Float     // 最大回撤
  current_drawdown : Float // 当前回撤
  avg_drawdown : Float     // 平均回撤
  drawdown_count : Int     // 回撤事件次数
}
```

### 回撤预警函数

#### check_drawdown_alert

```moonbit
pub fn check_drawdown_alert(Float, DrawdownAlert) -> String
```

检查当前回撤是否触发预警。

**参数**:
- `current_drawdown` - 当前回撤值
- `alert_config` - 预警配置

**返回**: 预警级别字符串 ("normal", "warning", "critical", "max")

#### classify_drawdown

```moonbit
pub fn classify_drawdown(Float) -> DrawdownLevel
```

将回撤值分类到对应的级别。

#### default_alert_config

```moonbit
pub fn default_alert_config() -> DrawdownAlert
```

获取默认预警配置：
- warning: -5%
- critical: -10%
- max: -20%

#### create_monitor

```moonbit
pub fn create_monitor(Float, Float) -> DrawdownMonitor
```

创建回撤监控器。

**参数**:
- `warning_threshold` - 预警阈值
- `critical_threshold` - 临界阈值

**使用示例**:
```moonbit
// 创建监控器
let mut monitor = drawdown::create_monitor(-0.05, -0.10)

// 更新监控
monitor.update(1.0, "2024-01-01")
monitor.update(1.1, "2024-01-02")
monitor.update(0.95, "2024-01-03")  // 回撤触发

// 检查状态
if monitor.is_alert_triggered() {
  io::println("预警触发：" + monitor.get_alert_level())
}
```

---

## 策略引擎模块 (strategy)

**包路径**: `username/alpha/src/strategy`

### 核心类型

#### Action (交易动作)

```moonbit
pub enum Action {
  Buy
  Sell
  Hold
}
```

**Trait 实现**: `Eq`, `Show`, `ToJson`

#### Signal (交易信号)

```moonbit
pub struct Signal {
  stock : String        // 股票代码
  action : Action       // 交易动作
  price : Float         // 信号价格
  timestamp : String    // 时间戳
  strength : Float      // 信号强度 (0.0 - 1.0)
}
```

**构造方法**:
- `Signal::buy(stock, price, timestamp, strength)`
- `Signal::sell(stock, price, timestamp, strength)`
- `Signal::hold(stock, price, timestamp)`
- `Signal::with_action(stock, action, price, timestamp, strength)`

**Trait 实现**: `Show`, `ToJson`

#### StrategyContext (策略上下文)

```moonbit
pub struct StrategyContext {
  capital : Float         // 可用资金
  position : Float        // 当前仓位
  current_price : Float   // 当前价格
  last_signal : Signal?   // 上一个信号
}
```

**Trait 实现**: `Show`, `ToJson`

#### Strategy (策略)

```moonbit
pub struct Strategy {
  name : String
  on_init : (StrategyContext) -> Unit
  on_bar : (@data.KLine, StrategyContext, Array[Float]) -> Signal
}
```

#### StrategyEngine (策略引擎)

```moonbit
pub struct StrategyEngine {
  capital : Float
  position : Float
  last_price : Float
  signals : Array[Signal]
  results : Array[StrategyResult]
}
```

#### StrategyResult (策略结果)

```moonbit
pub struct StrategyResult {
  signal : Signal
}
```

**Trait 实现**: `Show`, `ToJson`

**Note**: 简化版本，仅包含信号信息。执行细节由回测引擎跟踪。

### 策略引擎函数

#### create_strategy_engine

```moonbit
pub fn create_strategy_engine(Float) -> StrategyEngine
```

创建策略引擎。

**参数**: `initial_capital` - 初始资金

#### process_bar

```moonbit
pub fn process_bar(StrategyEngine, Strategy, @data.KLine, Array[Float]) -> StrategyResult
```

处理单根 K 线，生成交易信号。

**参数**:
- `engine` - 策略引擎
- `strategy` - 策略实例
- `kline` - K 线数据
- `indicator_values` - 指标值数组（可选）

**返回**: `StrategyResult`

#### get_engine_stats

```moonbit
pub fn get_engine_stats(StrategyEngine) -> (Float, Float, Int)
```

获取引擎统计信息。

**返回**: `(总盈亏，当前仓位，信号数量)`

#### default_backtest_config

```moonbit
pub fn default_backtest_config() -> BacktestConfig
```

获取默认回测配置：
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

**示例 - 定义策略**:
```moonbit
// 简单的均线交叉策略
pub fn ma_cross_strategy() -> Strategy {
  Strategy {
    name: "MA Cross",
    on_init: fn(ctx) {
      // 初始化逻辑
      io::println("策略初始化")
    },
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

## 回测引擎模块 (backtest)

**包路径**: `username/alpha/src/backtest`

### 核心类型

#### BacktestEngine (回测引擎)

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

#### BacktestResult (回测结果)

```moonbit
pub struct BacktestResult {
  initial_capital : Float     // 初始资金
  final_capital : Float       // 最终资金
  total_return : Float        // 总收益率
  max_drawdown : Float        // 最大回撤
  sharpe_ratio : Float        // 夏普比率
  total_trades : Int          // 总交易数
  equity_curve : Array[EquityPoint]
  trades : Array[Trade]
  stats : BacktestStats
}
```

**Trait 实现**: `Show`, `ToJson`

#### BacktestStats (回测统计)

```moonbit
pub struct BacktestStats {
  total_return : Float       // 总收益率
  annual_return : Float      // 年化收益率
  max_drawdown : Float       // 最大回撤
  sharpe_ratio : Float       // 夏普比率
  sortino_ratio : Float      // 索提诺比率
  win_rate : Float           // 胜率
  profit_factor : Float      // 盈亏比
  total_trades : Int         // 总交易数
  winning_trades : Int       // 盈利交易数
  losing_trades : Int        // 亏损交易数
  avg_win : Float            // 平均盈利
  avg_loss : Float           // 平均亏损
  avg_trade_duration : Float // 平均持仓时间
}
```

**Trait 实现**: `Show`, `ToJson`

#### EquityPoint (权益点)

```moonbit
pub struct EquityPoint {
  date : String
  equity : Float
  drawdown : Float
  position : Float
  cash : Float
}
```

**Trait 实现**: `Show`, `ToJson`

#### Trade (交易记录)

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

**Trait 实现**: `Show`, `ToJson`

#### ReportConfig (报告配置)

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

#### ReportFormat (报告格式)

```moonbit
pub enum ReportFormat {
  Html
  Text
}
```

### 回测引擎函数

#### create_backtest_engine

```moonbit
pub fn create_backtest_engine(@strategy.BacktestConfig) -> BacktestEngine
```

创建回测引擎实例。

#### run_backtest

```moonbit
pub fn run_backtest(BacktestEngine, Array[@data.KLine], @strategy.Strategy) -> BacktestResult
```

运行回测。

**参数**:
- `engine` - 回测引擎
- `klines` - K 线数据
- `strategy` - 策略实例

**返回**: `BacktestResult`

### 报告生成函数

#### generate_report

```moonbit
pub fn generate_report(BacktestResult, ReportConfig) -> String
```

生成报告字符串。

#### print_report

```moonbit
pub fn print_report(BacktestResult, ReportFormat) -> Unit
```

打印报告到控制台。

#### save_report_to_file

```moonbit
pub fn save_report_to_file(BacktestResult, String, ReportFormat) -> Result[Unit, String]
```

保存报告到文件。

### 辅助函数

#### action_to_string

```moonbit
pub fn action_to_string(@strategy.Action) -> String
```

将 Action 转换为字符串。

#### default_report_config

```moonbit
pub fn default_report_config() -> ReportConfig
```

获取默认报告配置。

#### create_trade_log

```moonbit
pub fn create_trade_log() -> TradeLog
```

创建交易日志。

**TradeLog 方法**:
- `add(date, stock, action, price, quantity, pnl?, commentary)` - 添加日志条目

**使用示例**:
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

// 加载数据
let klines = data::load_klines_from_csv("data/sh.600000.csv")

// 运行回测
let result = backtest::run_backtest(engine, klines, my_strategy)

// 打印结果
backtest::print_report(result, backtest::ReportFormat::Text)

// 保存 HTML 报告
match backtest::save_report_to_file(result, "report.html", backtest::ReportFormat::Html) {
  Ok(_) => io::println("报告已保存"),
  Err(e) => io::println("保存失败：" + e)
}

// 访问详细统计
io::println("总收益率：" + String::from_float(result.stats.total_return * 100) + "%")
io::println("夏普比率：" + String::from_float(result.stats.sharpe_ratio))
io::println("最大回撤：" + String::from_float(result.stats.max_drawdown * 100) + "%")
io::println("胜率：" + String::from_float(result.stats.win_rate * 100) + "%")
```

---

## 完整使用示例

### 回测单个策略

```moonbit
import username/alpha/src/data
import username/alpha/src/strategy
import username/alpha/src/backtest
import username/alpha/src/indicator

fn main {
  // 1. 加载数据
  let klines = match data::load_klines_from_csv("data/sh.600000.csv") {
    Ok(d) => d,
    Err(e) => {
      io::println("加载数据失败：" + e)
      return
    }
  }

  // 2. 计算指标
  let closes = klines.map(fn(k) { k.close })
  let ma5 = indicator::sma(closes, 5)
  let ma20 = indicator::sma(closes, 20)

  // 3. 定义策略
  let strategy = Strategy {
    name: "MA Cross",
    on_init: fn(_) { io::println("策略启动") },
    on_bar: fn(kline, ctx, _) {
      let idx = klines.index_of(kline)
      if ma5[idx] > ma20[idx] && ctx.position == 0.0 {
        Signal::buy(kline.code, kline.close, kline.date, 0.8)
      } else if ma5[idx] < ma20[idx] && ctx.position > 0.0 {
        Signal::sell(kline.code, kline.close, kline.date, 0.8)
      } else {
        Signal::hold(kline.code, kline.close, kline.date)
      }
    }
  }

  // 4. 配置回测
  let config = strategy::default_backtest_config()
  let engine = backtest::create_backtest_engine(config)

  // 5. 运行回测
  let result = backtest::run_backtest(engine, klines, strategy)

  // 6. 输出报告
  backtest::print_report(result, backtest::ReportFormat::Text)
}
```

---

## 附录

### 错误处理约定

- 所有可能失败的函数返回 `Result[T, String]`
- `Ok(value)` 表示成功
- `Err(message)` 表示失败，包含错误信息

### 数值精度

- 价格相关计算使用 `Float` 类型
- 百分比值用小数表示（如 0.05 表示 5%）
- 回撤值为负数（如 -0.1 表示回撤 10%）

### 日期格式

所有日期字符串使用 `YYYY-MM-DD` 格式。
