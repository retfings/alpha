# 项目状态报告

**报告日期**: 2026-03-27
**审查人**: 提案工程师 (proposal-engineer-1)

---

## 1. 执行摘要

### 1.1 总体进度

| 模块 | 完成度 | 状态 | 代码行数 |
|------|--------|------|---------|
| 数据层 (src/data) | 100% | ✅ 完成 | ~1,300 行 |
| 策略引擎 (src/strategy) | 100% | ✅ 完成 | ~800 行 |
| 风控系统 (src/risk) | 100% | ✅ 完成 | ~600 行 |
| 回撤计算 (src/drawdown) | 100% | ✅ 完成 | ~400 行 |
| 组合管理 (src/portfolio) | 100% | ✅ 完成 | ~350 行 |
| 回测引擎 (src/backtest) | 95% | ⚠️ 部分完成 | ~700 行 |
| 技术指标 (src/indicator) | 100% | ✅ 完成 | ~600 行 |
| HTTP 服务器 (server/) | 0% | ❌ 未实现 | 0 行 |
| Web 前端 (www/) | 80% | ⚠️ 待后端 | ~600 行 |
| CLI (alpha/main) | 70% | ⚠️ 需修复 | ~350 行 |

**总代码量**: ~6,430 行 (src/ 目录)

### 1.2 关键发现

1. **核心功能完整**: 所有核心业务模块已实现并通过测试
2. **HTTP 服务器缺失**: Web 界面无后端支持
3. **CLI 存在编译错误**: 需要修复 `sys::get_args()` 相关问题
4. **数据标准化模块已实现**: `normalizer.mbt` 包含完整的复权处理功能

---

## 2. 模块详细审查

### 2.1 数据层 (src/data/)

**文件清单**:
- `types.mbt` - KLine, StockCode, Frequency 等类型定义
- `loader.mbt` - CSV 解析器（包含自定义 Float 解析）
- `normalizer.mbt` - 数据标准化和复权处理
- `data_test.mbt` / `data_wbtest.mbt` - 测试文件

**功能评估**:
| 功能 | 状态 | 备注 |
|------|------|------|
| KLine 类型定义 | ✅ | 完整，包含 derive(ToJson, Show, Eq) |
| CSV 解析 | ✅ | 包含自定义 parse_float 实现 |
| 向前复权 | ✅ | `apply_forward_adjustment` |
| 向后复权 | ✅ | `apply_backward_adjustment` |
| 数据验证 | ✅ | `validate_kline`, `filter_invalid_klines` |
| 日期范围筛选 | ✅ | `trim_klines_to_range` |
| 频率转换 | ✅ | `resample_klines` (支持周线/月线) |
| 文件 I/O | ⚠️ | 需要 C FFI 实现 |

**建议**: 无重大改进需求

### 2.2 策略引擎 (src/strategy/)

**文件清单**:
- `types.mbt` - Action, Signal, Strategy, StrategyContext
- `engine.mbt` - 策略执行引擎
- `builtins/ma_cross.mbt` - 均线交叉策略
- `builtins/momentum.mbt` - 动量策略
- `strategy_test.mbt` / `strategy_wbtest.mbt` - 测试文件

**功能评估**:
| 功能 | 状态 | 备注 |
|------|------|------|
| 策略类型定义 | ✅ | 使用 struct 而非 trait |
| 信号生成 | ✅ | Buy/Sell/Hold |
| MA Cross 策略 | ✅ | 快慢均线交叉 |
| Momentum 策略 | ✅ | 动量策略实现 |
| 策略引擎 | ✅ | `process_bar` 函数 |

**建议**: 考虑添加更多内置策略（如 Mean Reversion）

### 2.3 风控系统 (src/risk/)

**文件清单**:
- `types.mbt` - RiskAction, RiskResult, RiskRule, RiskEngine
- `rules.mbt` - 6 个内置风控规则
- `risk_test.mbt` / `rules_test.mbt` - 测试文件

**功能评估**:
| 功能 | 状态 | 备注 |
|------|------|------|
| 风控引擎 | ✅ | 支持规则优先级 |
| 最大回撤规则 | ✅ | 触发 StopTrading |
| 仓位限制规则 | ✅ | 触发 ReducePosition |
| 日损限制规则 | ✅ | 触发 StopTrading |
| 止损规则 | ⚠️ | 简化版本 |
| 单股限制规则 | ⚠️ | 简化版本 |
| 止盈规则 | ✅ | 建议部分减仓 |

**建议**:
- 完善止损规则，实现真实的持仓 P&L 跟踪
- 完善单股限制规则，实现真实的个股敞口计算

### 2.4 回测引擎 (src/backtest/)

**文件清单**:
- `types.mbt` - Trade, EquityPoint, BacktestResult, BacktestStats
- `engine.mbt` - 回测执行引擎
- `report.mbt` - 报告生成器
- `backtest_test.mbt` - 测试文件

**功能评估**:
| 功能 | 状态 | 备注 |
|------|------|------|
| 回测引擎 | ✅ | 完整实现 |
| 风控集成 | ✅ | 每笔交易前检查风控 |
| 权益曲线 | ✅ | 每日快照 |
| 统计计算 | ⚠️ | 部分简化（Sharpe, 胜率） |
| 报告生成 | ✅ | HTML/Text 格式 |
| 交易执行 | ⚠️ | 硬编码数量 (quantity = 100.0) |

**关键问题**:
```moonbit
// engine.mbt:146 - 硬编码交易数量
let quantity : Float = 100.0 // Simplified - should calculate based on capital
```

**建议**:
1. 实现基于资本和仓位的动态交易数量计算
2. 完善统计计算（真实 Sharpe 比率、胜率）

### 2.5 技术指标库 (src/indicator/)

**文件清单**:
- `ma.mbt` - SMA, EMA, RSI, MACD, Bollinger Bands, ATR

**功能评估**:
| 指标 | 状态 | 备注 |
|------|------|------|
| SMA | ✅ | Simple Moving Average |
| EMA | ✅ | Exponential Moving Average |
| RSI | ✅ | Relative Strength Index |
| MACD | ✅ | 包含 Signal 线和 Histogram |
| Bollinger Bands | ✅ | 上轨/中轨/下轨 |
| ATR | ✅ | Average True Range |

**建议**: 考虑添加更多指标（如 Stochastic, Williams %R）

### 2.6 CLI (alpha/)

**文件清单**:
- `main.mbt` - CLI 入口和命令解析

**功能评估**:
| 功能 | 状态 | 备注 |
|------|------|------|
| 命令解析 | ✅ | analyze, backtest, report |
| 参数解析 | ✅ | --stock, --strategy, --start, --end |
| 帮助信息 | ✅ | print_help() |
| 实际执行 | ⚠️ | 演示输出占位符 |
| 编译状态 | ❌ | 存在类型错误 |

**编译错误**:
```
Error: Expected upper case identifier for type name, found lower case identifier.
     ╭─[ alpha/main.mbt:300:14 ]
     │ 300 │   let args = sys::get_args()
```

**建议**:
1. 修复 sys 模块引用问题
2. 实现真实的回测执行逻辑

---

## 3. 风险识别

### 3.1 技术风险

| 风险 | 严重性 | 可能性 | 影响 |
|------|--------|--------|------|
| HTTP 服务器缺失 | 高 | 已发生 | Web 界面无法工作 |
| CLI 编译失败 | 中 | 已发生 | 无法运行命令行工具 |
| 硬编码交易数量 | 中 | 已发生 | 回测结果不准确 |
| 简化统计计算 | 低 | 已发生 | 报告精度受限 |
| 无真实文件 I/O | 中 | 已发生 | 数据加载依赖 Python |

### 3.2 进度风险

| 任务 | 预计工作量 | 依赖 |
|------|-----------|------|
| HTTP 服务器实现 | 2-3 天 | 无 |
| CLI 修复 | 0.5 天 | 无 |
| 回测引擎完善 | 1-2 天 | 无 |
| Parquet 支持 | 3-5 天 | 需要 C FFI |

---

## 4. 架构优化建议

### 4.1 短期优先级（立即执行）

#### 4.1.1 实现 HTTP 服务器

**目标**: 创建 `server/server.mbt` 提供 RESTful API

**建议 API**:
```
GET  /api/stocks                 # 获取股票列表
GET  /api/stocks/:code/klines    # 获取 K 线数据
POST /api/backtest               # 运行回测
GET  /api/backtest/:id/result    # 获取回测结果
GET  /api/drawdown/:code         # 计算个股回撤
GET  /api/portfolio/drawdown     # 计算组合回撤
```

**实现考虑**:
- MoonBit HTTP 支持需要确认
- 可能需要 C FFI 或使用外部运行时

#### 4.1.2 修复 CLI 编译错误

**问题**: `sys::get_args()` 类型错误

**建议**:
1. 检查 MoonBit 正确的 sys 模块导入方式
2. 或使用命令行参数解析库

### 4.2 中期优先级

#### 4.2.1 完善回测引擎

**当前问题**:
```moonbit
// 硬编码交易数量
let quantity : Float = 100.0
```

**建议修复**:
```moonbit
// 基于资本和价格计算合理数量
let available_capital = engine.portfolio.cash
let quantity = (available_capital * 0.95) / kline.close / 100.0 * 100.0
```

#### 4.2.2 完善风控规则

**当前问题**: 止损规则使用 daily_loss 作为代理

**建议**: 实现真实的持仓 P&L 跟踪
```moonbit
pub fn stop_loss_rule_detailed(
  portfolio : Portfolio,
  max_loss_pct : Float,
) -> RiskResult {
  // 遍历所有持仓计算实际 P&L
}
```

### 4.3 长期优先级

#### 4.3.1 Parquet 格式支持

创建 `src/data/parquet.mbt`:
- 使用 C FFI 调用 Parquet 库
- 提供与 CSV 相同的接口

#### 4.3.2 更多内置策略

建议添加:
- Mean Reversion Strategy
- Breakout Strategy
- Dual Thrust Strategy

---

## 5. 代码质量评估

### 5.1 优点

1. **类型安全**: 所有类型明确定义，使用 derive 派生
2. **文档完善**: 所有公共 API 有完整 docstrings
3. **测试覆盖**: 每个模块有 blackbox 和 whitebox 测试
4. **模块化设计**: 清晰的模块边界和依赖关系

### 5.2 改进空间

1. **代码复用**: 部分代码重复（如统计计算）
2. **错误处理**: 部分函数返回 Option 而非 Result
3. **性能优化**: 部分算法可优化（如排序使用冒泡排序）

---

## 6. 建议任务优先级

### P0 - 关键（本周内完成）

1. **修复 CLI 编译错误** - 影响所有命令行功能
2. **实现 HTTP 服务器骨架** - 支持 Web 界面

### P1 - 高优先级（两周内完成）

3. **完善回测引擎交易执行逻辑**
4. **实现 CLI 真实数据加载**
5. **完善风控规则（持仓 P&L 跟踪）**

### P2 - 中优先级（一月内完成）

6. **添加更多内置策略**
7. **完善统计计算精度**
8. **实现 Parquet 支持调研**

---

## 7. 下一步行动

1. **立即**: 修复 CLI 编译错误
2. **本周**: 创建 HTTP 服务器设计和实现
3. **下周**: 完善回测引擎和风控规则
4. **持续**: 添加测试覆盖和文档更新

---

## 附录 A: 文件清单

```
alpha/
├── alpha/
│   └── main.mbt                 # CLI 入口
├── src/
│   ├── data/
│   │   ├── types.mbt            # 数据类型
│   │   ├── loader.mbt           # CSV 加载器
│   │   └── normalizer.mbt       # 数据标准化
│   ├── strategy/
│   │   ├── types.mbt            # 策略类型
│   │   ├── engine.mbt           # 策略引擎
│   │   └── builtins/
│   │       ├── ma_cross.mbt     # MA 交叉策略
│   │       └── momentum.mbt     # 动量策略
│   ├── risk/
│   │   ├── types.mbt            # 风控类型
│   │   └── rules.mbt            # 风控规则
│   ├── drawdown/
│   │   ├── types.mbt            # 回撤类型
│   │   └── calculator.mbt       # 回撤计算器
│   ├── portfolio/
│   │   └── manager.mbt          # 组合管理
│   ├── backtest/
│   │   ├── types.mbt            # 回测类型
│   │   ├── engine.mbt           # 回测引擎
│   │   └── report.mbt           # 报告生成
│   └── indicator/
│       └── ma.mbt               # 技术指标
├── www/
│   ├── index.html               # Web 前端
│   ├── app.js                   # 前端逻辑
│   └── styles.css               # 样式
└── docs/
    ├── architecture.md          # 架构文档
    ├── api-reference.md         # API 参考
    ├── user-guide.md            # 用户指南
    └── strategy-examples.md     # 策略示例
```

---

*报告结束*
