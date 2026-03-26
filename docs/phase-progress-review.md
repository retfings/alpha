# Phase 进度审查报告

**审查日期**: 2026-03-27
**审查人**: 提案工程师 (proposal-engineer-1)
**参考文档**: docs/architecture.md

---

## 1. Phase 完成状态总览

| Phase | 描述 | 计划内容 | 完成状态 |
|-------|------|----------|----------|
| Phase 1 | 基础框架 | 4 项 | ✅ **100%** |
| Phase 2 | 策略引擎 | 4 项 | ✅ **100%** |
| Phase 3 | 风控系统 | 4 项 | ✅ **100%** |
| Phase 4 | HTTP 服务器 | 3 项 | ❌ **0%** |
| Phase 5 | Web 界面 | 3 项 | ⚠️ **60%** |
| Phase 6 | 完善优化 | 5 项 | ⏳ **20%** |

**总体进度**: 65% (核心功能完成，Web 集成待完善)

---

## 2. Phase 详细审查

### Phase 1 - 基础框架 ✅ 100%

**计划内容**:
- [x] 数据类型定义
- [x] CSV 数据加载器
- [x] 基础回撤计算器
- [x] 简单 CLI 命令

**实现文件**:
```
src/data/types.mbt        # KLine, StockCode, Frequency
src/data/loader.mbt       # CSV 解析器
src/data/normalizer.mbt   # 数据标准化（额外实现）
src/drawdown/calculator.mbt
src/drawdown/types.mbt
cmd/main/main.mbt         # CLI 入口
```

**评估**:
- 所有计划内容已完成
- 额外实现了 `normalizer.mbt`（数据复权处理）
- CLI 存在编译错误需要修复（不影响核心框架）

**状态**: 完成

---

### Phase 2 - 策略引擎 ✅ 100%

**计划内容**:
- [x] 策略接口定义
- [x] 回测引擎核心
- [x] 1-2 个内置策略示例
- [x] 回测报告生成

**实现文件**:
```
src/strategy/types.mbt        # Action, Signal, Strategy, StrategyContext
src/strategy/engine.mbt       # 策略执行引擎
src/strategy/builtins/ma_cross.mbt    # 均线交叉策略
src/strategy/builtins/momentum.mbt    # 动量策略
src/backtest/engine.mbt       # 回测引擎核心
src/backtest/types.mbt        # Trade, EquityPoint, BacktestResult
src/backtest/report.mbt       # 报告生成器
```

**评估**:
- 策略接口使用 struct 而非 trait（MoonBit 推荐方式）
- 实现了 2 个内置策略（超出预期的 1-2 个）
- 回测报告支持 HTML 和 Text 格式

**状态**: 完成

---

### Phase 3 - 风控系统 ✅ 100%

**计划内容**:
- [x] 风控规则引擎
- [x] 内置风控规则
- [x] 与回测引擎集成
- [x] 测试覆盖

**实现文件**:
```
src/risk/types.mbt        # RiskEngine, RiskRule, RiskResult, RiskAction
src/risk/rules.mbt        # 6 个内置规则
src/risk/rules_test.mbt   # 14 个单元测试
```

**内置规则**:
| 规则 | 触发条件 | 动作 |
|------|----------|------|
| max_drawdown_rule | 回撤 ≥ 20% | StopTrading |
| position_limit_rule | 仓位 ≥ 95% | ReducePosition |
| daily_loss_limit_rule | 日损 ≥ 5% | StopTrading |
| stop_loss_rule | 持仓损失 ≥ 阈值 | ReducePosition |
| single_stock_limit_rule | 单股敞口 ≥ 20% | ReducePosition |
| take_profit_rule | 日盈 ≥ 10% | ReducePosition(0.5) |

**评估**:
- 所有计划内容已完成
- 实现了 6 个规则（超出基础需求）
- 测试覆盖率良好

**状态**: 完成

---

### Phase 4 - HTTP 服务器 ❌ 0%

**计划内容**:
- [ ] 简单 HTTP API 服务器
- [ ] RESTful API 实现
- [ ] 与核心引擎集成

**实现文件**:
```
server/moon.pkg           # 仅配置文件，无实现
```

**计划 API**:
```
GET  /api/stocks                 # 获取股票列表
GET  /api/stocks/:code/klines    # 获取 K 线数据
POST /api/backtest               # 运行回测
GET  /api/backtest/:id/result    # 获取回测结果
GET  /api/drawdown/:code         # 计算个股回撤
GET  /api/portfolio/drawdown     # 计算组合回撤
```

**评估**:
- 仅创建了 moon.pkg 配置文件
- 无实际服务器实现代码
- 前端 www/ 目录已就绪但无后端支持

**风险**: 高 - Web 界面无法工作

**建议**: 评估 MoonBit HTTP 实现可行性，考虑以下方案：
1. 使用 MoonBit + C FFI 实现 HTTP 服务器
2. 使用独立的轻量级 HTTP 服务器（如 Python Flask/FastAPI）
3. 使用 Node.js Express 等成熟方案

**状态**: 未开始

---

### Phase 5 - Web 界面 ⚠️ 60%

**计划内容**:
- [x] 静态页面框架
- [x] 图表可视化
- [ ] API 对接

**实现文件**:
```
www/index.html     # 242 行 - Dashboard/回测/分析/设置 4 个 Tab
www/app.js         # 474 行 - 前端逻辑和 Chart.js 集成
www/styles.css     # 335 行 - 样式定义
```

**功能清单**:
| 功能 | 状态 | 备注 |
|------|------|------|
| Dashboard | ✅ | 组合价值、回撤、夏普比率卡片 |
| 权益曲线图表 | ✅ | Chart.js 集成 |
| 回撤曲线图表 | ✅ | Chart.js 集成 |
| 回测配置表单 | ✅ | 策略选择、日期范围 |
| 设置页面 | ✅ | 风控参数配置 |
| API 调用 | ❌ | 等待后端实现 |

**评估**:
- 前端 UI 框架完整
- 图表可视化已就绪
- 所有 API 调用都是占位符（等待后端）

**状态**: 部分完成（等待 Phase 4）

---

### Phase 6 - 完善与优化 ⏳ 20%

**计划内容**:
- [ ] Parquet 格式支持
- [x] 更多技术指标
- [ ] 更多内置策略
- [ ] 性能优化
- [x] 文档完善

**已完成内容**:

1. **技术指标库** (`src/indicator/ma.mbt`):
   - SMA (简单移动平均)
   - EMA (指数移动平均)
   - RSI (相对强弱指数)
   - MACD (移动平均收敛发散)
   - Bollinger Bands (布林带)
   - ATR (平均真实波幅)

2. **文档**:
   - `docs/architecture.md` - 架构设计
   - `docs/api-reference.md` - API 参考
   - `docs/user-guide.md` - 用户指南
   - `docs/strategy-examples.md` - 策略示例

**待完成内容**:

| 任务 | 优先级 | 工作量 |
|------|--------|--------|
| Parquet 支持 | 低 | 3-5 天 |
| 更多策略 | 中 | 2-3 天/策略 |
| 性能优化 | 中 | 待定 |

**建议新增策略**:
- Mean Reversion (均值回归)
- Breakout (突破策略)
- Dual Thrust (双 thrust 趋势策略)

**状态**: 进行中

---

## 3. 架构风险评估

### 3.1 设计缺陷

| 问题 | 严重性 | 描述 |
|------|--------|------|
| 无真实持仓 P&L 跟踪 | 中 | 止损规则使用 daily_loss 作为代理 |
| 硬编码交易数量 | 中 | 回测中 quantity = 100.0 固定值 |
| 简化统计计算 | 低 | Sharpe 比率、胜率计算简化 |

### 3.2 性能问题

| 问题 | 影响 | 建议 |
|------|------|------|
| 冒泡排序 | 低 | `sort_klines_by_date` 使用 O(n²) 算法 |
| 重复遍历 | 低 | 部分函数多次遍历同一数组 |

### 3.3 技术债务

| 债务 | 累积原因 | 建议 |
|------|----------|------|
| CLI 编译错误 | MoonBit sys 模块 API 变更 | 优先修复 |
| 文件 I/O 依赖 C FFI | MoonBit 标准库限制 | 评估外部运行时方案 |

---

## 4. 优先级调整建议

### 当前状态

```
Phase 1 ✅ → Phase 2 ✅ → Phase 3 ✅ → Phase 4 ❌ → Phase 5 ⚠️
                                          ↓
                                    Phase 6 ⏳
```

### 建议调整

**P0 - 紧急（本周）**:
1. 修复 CLI 编译错误 - 影响命令行工具可用性
2. 实现 HTTP 服务器骨架 - 打通前后端

**P1 - 高优先级（两周内）**:
3. 完善回测引擎交易逻辑 - 动态计算交易数量
4. 完善风控持仓 P&L 跟踪 - 实现真实的止损规则

**P2 - 中优先级（一月内）**:
5. 添加更多内置策略
6. 性能优化

**P3 - 低优先级（按需）**:
7. Parquet 格式支持

---

## 5. 技术方案优化建议

### 5.1 HTTP 服务器方案

**方案 A - MoonBit 原生** (推荐评估)
```
优点: 技术栈统一
缺点: 需要 C FFI，开发周期长
```

**方案 B - Python FastAPI** (快速落地)
```
优点: 开发快速，可直接调用现有 Python 数据脚本
缺点: 需要 Python 运行时
```

**方案 C - Node.js Express** (成熟稳定)
```
优点: 生态成熟，前端团队协作方便
缺点: 需要 Node.js 运行时
```

**建议**: 短期采用方案 B 快速落地，长期评估方案 A

### 5.2 回测引擎改进

**当前实现**:
```moonbit
let quantity : Float = 100.0 // 硬编码
```

**建议改进**:
```moonbit
// 基于可用资本和风险管理计算
let available = engine.portfolio.cash * 0.95  // 95% 仓位上限
let quantity = (available / kline.close / 100.0) * 100.0  // 向下取整到 100 股倍数
```

### 5.3 风控系统增强

**当前限制**: 止损规则使用简化版本

**建议实现**:
```moonbit
pub fn calculate_position_pnl(
  portfolio : Portfolio,
  stock : StockCode,
) -> Float {
  // 遍历持仓计算真实 P&L
}
```

---

## 6. 下一步行动

| 序号 | 行动 | 负责人 | 截止日期 |
|------|------|--------|----------|
| 1 | 修复 CLI 编译错误 | bugfix-engineer | TBD |
| 2 | 实现 HTTP 服务器骨架 | backend-engineer | TBD |
| 3 | 完善回测交易逻辑 | strategy-engineer | TBD |
| 4 | 实现持仓 P&L 跟踪 | risk-engineer | TBD |

---

## 7. 总结

### 已完成
- Phase 1-3 核心功能 100% 完成
- 技术指标库完整（6 个指标）
- 文档体系完善

### 待完成
- Phase 4 HTTP 服务器 0% - **关键阻塞**
- Phase 5 Web 界面 60% - 等待后端
- Phase 6 部分进行中

### 关键风险
1. **HTTP 服务器缺失** - Web 界面无法工作
2. **CLI 编译错误** - 命令行工具不可用

### 建议
1. 优先实现 HTTP 服务器（可采用 Python FastAPI 快速落地）
2. 立即修复 CLI 编译错误
3. 完善回测引擎和风控规则的核心逻辑

---

*报告结束*
