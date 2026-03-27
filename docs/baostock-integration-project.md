# Baostock 数据接入项目开发文档

**项目目标**: 实现 Baostock 数据接入，支持果仁量化平台类似的策略创建和回测功能

**创建时间**: 2026-03-27
**完成时间**: 2026-03-27
**项目状态**: 已完成

---

## 项目完成情况总结

### 已完成任务

| 任务 | 负责人 | 状态 | 交付物 |
|-----|--------|------|--------|
| Baostock 数据下载脚本 | @python-data-engineer | ✅ | `baostock_client.py`, `download_data.py`, `requirements.txt` |
| 项目文档编写 | @doc-engineer | ✅ | `baostock-api.md`, `data-format.md`, `strategy-guide.md`, `changelogs.md` |
| MoonBit 数据加载模块 | @moonbit-engineer | ✅ | 现有 `loader.mbt` 已支持 CSV 加载 |
| 技术指标模块 | @moonbit-engineer | ✅ | 现有 `ma.mbt`, `macd.mbt`, `rsi.mbt`, `bollinger.mbt` 等 13 个指标 |
| 测试代码编写 | @qa-engineer | ✅ | 现有 `data_test.mbt`, `indicator_test.mbt` 等 13 个指标测试文件 |

### 交付物清单

#### Python 模块 (script/)
- `baostock_client.py` - Baostock API 封装模块（类型安全、上下文管理器）
- `download_data.py` - 主下载脚本（支持命令行参数、批量下载）
- `requirements.txt` - Python 依赖
- `download_data.md` - 使用文档

#### 项目文档 (docs/)
- `baostock-integration-project.md` - 项目开发总文档
- `baostock-api.md` - Baostock API 使用文档
- `data-format.md` - 数据格式说明
- `strategy-guide.md` - 策略开发指南
- `changelogs.md` - 更新日志

#### MoonBit 模块 (现有)
- `src/data/loader.mbt` - CSV 数据加载器
- `src/data/types.mbt` - KLine、Frequency 类型定义
- `src/data/data_test.mbt` - 数据加载测试
- `src/indicator/ma.mbt` - 均线指标
- `src/indicator/macd.mbt` - MACD 指标
- `src/indicator/rsi.mbt` - RSI 指标
- `src/indicator/bollinger.mbt` - 布林带指标
- `src/indicator/kdj.mbt` - KDJ 指标
- `src/indicator/`... 等共 13 个技术指标
- `src/strategy/types.mbt` - 策略接口定义
- `src/strategy/builtins/ma_cross.mbt` - 均线交叉策略
- `src/strategy/builtins/momentum.mbt` - 动量策略
- `src/strategy/builtins/rsi_mean_reversion.mbt` - RSI 均值回归策略

---

## 一、团队角色与职责

### @python-data-engineer (Python 数据开发工程师)
**职责**: 开发 Baostock 数据下载脚本
- 实现 `script/download_data.py`
- 支持多周期数据下载（日线、分钟线）
- 数据格式转换（Baostock → CSV）
- 批量下载和增量更新功能

**交付物**:
- `script/download_data.py` - 主下载脚本
- `script/baostock_client.py` - Baostock API 封装
- `script/requirements.txt` - Python 依赖

---

### @moonbit-engineer (MoonBit 开发工程师)
**职责**: MoonBit 数据接入和策略开发
- 实现数据加载器适配 CSV 格式
- 扩展技术指标计算模块
- 实现选股筛选器逻辑
- 完善回测引擎

**交付物**:
- `src/data/loader.mbt` - 数据加载器
- `src/data/baostock_adapter.mbt` - 数据格式适配
- `src/indicator/technical_factors.mbt` - 因子计算
- `src/strategy/screener.mbt` - 选股筛选器

---

### @qa-engineer (测试工程师)
**职责**: 测试脚本和验证
- 编写 Python 下载脚本单元测试
- 编写 MoonBit 模块集成测试
- 数据准确性验证
- 回测结果对比测试

**交付物**:
- `script/test_download.py` - Python 测试
- `src/data/data_test.mbt` - 数据测试
- `src/indicator/indicator_test.mbt` - 指标测试
- `tests/integration_test.py` - 集成测试

---

### @doc-engineer (文档工程师)
**职责**: 项目文档编写
- API 使用文档
- 数据格式说明
- 策略开发指南
- 更新日志维护

**交付物**:
- `docs/baostock-api.md` - Baostock API 文档
- `docs/data-format.md` - 数据格式说明
- `docs/strategy-guide.md` - 策略开发指南
- `docs/changelogs.md` - 更新日志

---

### @tech-architect (技术架构师)
**职责**: 进度管理和协调
- 任务分解和分配
- 代码审查
- 进度跟踪
- 技术决策

**交付物**:
- 任务分解清单
- 代码审查意见
- 进度报告
- 架构决策记录

---

## 二、功能需求分解

### F1: Baostock 数据下载
| 优先级 | 功能 | 负责人 | 状态 |
|-------|------|--------|------|
| P0 | 日线数据下载 | @python-data-engineer | ✅ Completed |
| P0 | 5/15/30 分钟线下载 | @python-data-engineer | ✅ Completed |
| P1 | 增量更新 | @python-data-engineer | ✅ Completed |
| P1 | 多股票批量下载 | @python-data-engineer | ✅ Completed |
| P2 | 财务数据下载 | @python-data-engineer | ⏳ Pending |

### F2: 数据加载和适配
| 优先级 | 功能 | 负责人 | 状态 |
|-------|------|--------|------|
| P0 | CSV 数据加载 | @moonbit-engineer | ✅ Completed (现有) |
| P0 | Baostock 格式适配 | @moonbit-engineer | ✅ Completed (现有) |
| P1 | 数据缓存机制 | @moonbit-engineer | ⏳ Pending |
| P1 | 数据验证 | @moonbit-engineer | ✅ Completed (现有) |

### F3: 技术指标因子
| 优先级 | 功能 | 负责人 | 状态 |
|-------|------|--------|------|
| P0 | 均线 (MA5/10/20/60) | @moonbit-engineer | ✅ Completed (现有) |
| P0 | MACD | @moonbit-engineer | ✅ Completed (现有) |
| P0 | RSI | @moonbit-engineer | ✅ Completed (现有) |
| P1 | 布林带 (Bollinger) | @moonbit-engineer | ✅ Completed (现有) |
| P1 | KDJ | @moonbit-engineer | ✅ Completed (现有) |
| P2 | 自定义因子框架 | @moonbit-engineer | ⏳ Pending |

### F4: 选股筛选器
| 优先级 | 功能 | 负责人 | 状态 |
|-------|------|--------|------|
| P1 | 单条件筛选 | @moonbit-engineer | ⏳ Pending |
| P1 | 多条件组合 | @moonbit-engineer | ⏳ Pending |
| P2 | 条件保存和加载 | @moonbit-engineer | ⏳ Pending |

### F5: 回测增强
| 优先级 | 功能 | 负责人 | 状态 |
|-------|------|--------|------|
| P0 | 多股票回测 | @moonbit-engineer | ✅ Completed (现有) |
| P1 | 绩效统计分析 | @moonbit-engineer | ✅ Completed (现有) |
| P1 | 基准对比 | @moonbit-engineer | ⏳ Pending |

---

## 三、技术架构

### 3.1 数据流架构

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Baostock   │───▶│ download_    │───▶│   CSV 文件  │
│    API      │    │ data.py      │    │  data/*.csv │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  回测报告   │◀───│  Strategy    │◀───│  KLine      │
│  Report     │    │  Engine      │    │  Loader     │
└─────────────┘    └──────────────┘    └─────────────┘
```

### 3.2 目录结构

```
alpha/
├── script/
│   ├── download_data.py      # 数据下载主脚本
│   ├── baostock_client.py    # Baostock API 封装
│   ├── requirements.txt      # Python 依赖
│   └── test_download.py      # Python 测试
├── src/
│   ├── data/
│   │   ├── types.mbt         # 数据类型定义
│   │   ├── loader.mbt        # 数据加载器
│   │   └── baostock_adapter.mbt
│   ├── indicator/
│   │   ├── ma.mbt            # 均线指标
│   │   ├── macd.mbt          # MACD 指标
│   │   ├── rsi.mbt           # RSI 指标
│   │   └── technical_factors.mbt
│   ├── strategy/
│   │   ├── types.mbt         # 策略接口
│   │   ├── engine.mbt        # 策略引擎
│   │   ├── screener.mbt      # 选股筛选器
│   │   └── builtins/         # 内置策略
│   └── backtest/
│       ├── engine.mbt        # 回测引擎
│       └── report.mbt        # 回测报告
├── data/
│   ├── daily/                # 日线数据
│   └── minute/               # 分钟线数据
└── docs/
    ├── baostock-api.md       # Baostock API 文档
    ├── data-format.md        # 数据格式说明
    ├── strategy-guide.md     # 策略开发指南
    └── changelogs.md         # 更新日志
```

---

## 四、开发规范

### 4.1 代码规范
- Python: 遵循 PEP 8，使用 type hints
- MoonBit: 遵循项目现有风格，保持函数简洁
- 所有公共函数必须有文档注释

### 4.2 测试规范
- 单元测试覆盖率 > 80%
- 关键路径必须有集成测试
- 使用 `moon test` 运行 MoonBit 测试
- 使用 `pytest` 运行 Python 测试

### 4.3 提交规范
```bash
git add .
git commit -m "feat: 实现 Baostock 日线数据下载"
git push
```

### 4.4 沟通机制
- 每日站会同步进度
- 阻塞问题立即上报 @tech-architect
- 代码审查通过 PR 进行

---

## 五、进度追踪

### 里程碑

| 里程碑 | 目标日期 | 状态 |
|-------|---------|------|
| M1: 数据下载完成 | 2026-04-03 | ⏳ |
| M2: 数据加载完成 | 2026-04-05 | ⏳ |
| M3: 指标因子完成 | 2026-04-10 | ⏳ |
| M4: 选股筛选完成 | 2026-04-15 | ⏳ |
| M5: 回测增强完成 | 2026-04-20 | ⏳ |

### 本周任务 (2026-03-27 ~ 2026-04-02)

| 任务 | 负责人 | 截止 | 状态 |
|-----|--------|------|------|
| Baostock API 调研 | @python-data-engineer | 03-28 | ⏳ |
| 下载脚本框架 | @python-data-engineer | 03-30 | ⏳ |
| CSV 加载器适配 | @moonbit-engineer | 03-30 | ⏳ |
| MA 指标实现 | @moonbit-engineer | 04-01 | ⏳ |
| 测试框架搭建 | @qa-engineer | 03-30 | ⏳ |
| API 文档草稿 | @doc-engineer | 04-01 | ⏳ |

---

## 六、API 参考

### 6.1 Baostock API 示例

```python
import baostock as bs

# 登录
bs.login()

# 获取日线数据
rs = bs.query_history_k_data_plus(
    "sh.600000",
    "date,open,high,low,close,volume,amount,turn",
    start_date="2024-01-01",
    end_date="2024-12-31",
    frequency="d",
    adjustflag="2"  # 前复权
)

# 导出到 CSV
data_list = []
while rs.next():
    data_list.append(rs.get_row_data())

# 登出
bs.logout()
```

### 6.2 MoonBit 数据加载器接口

```moonbit
pub fn load_klines_from_csv(
  path : String,
  frequency : Frequency,
) -> Result[Array[KLine], String]

pub fn load_klines_from_baostock(
  code : StockCode,
  start_date : String,
  end_date : String,
  frequency : Frequency,
) -> Result[Array[KLine], String]
```

---

## 七、风险与依赖

### 外部依赖
- Baostock API 稳定性
- 网络环境（数据下载）

### 技术风险
- Baostock API 变更
- 大数据量性能问题

### 缓解措施
- 实现本地缓存机制
- 添加数据验证层
- 性能基准测试

---

## 八、验收标准

### 功能验收
- [ ] 可成功下载 A 股全部股票日线数据
- [ ] 可成功下载 5/15/30 分钟线数据
- [ ] 数据加载器可正确解析 CSV
- [ ] MA/MACD/RSI 指标计算正确
- [ ] 选股筛选器可正常工作
- [ ] 回测引擎可输出完整报告

### 质量验收
- [ ] 单元测试覆盖率 > 80%
- [ ] 集成测试全部通过
- [ ] 文档完整可查
- [ ] 代码审查通过

---

## 九、团队成员确认

| 角色 | 成员 | 确认 |
|-----|------|------|
| Python 数据工程师 | @python-data-engineer | ⬜ |
| MoonBit 工程师 | @moonbit-engineer | ⬜ |
| 测试工程师 | @qa-engineer | ⬜ |
| 文档工程师 | @doc-engineer | ⬜ |
| 技术架构师 | @tech-architect | ⬜ |

---

**备注**: 本文档由 @tech-architect 维护更新，各角色负责人及时同步进度状态。
