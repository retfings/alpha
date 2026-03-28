# 测试计划

**项目:** MoonBit 量化回撤框架 - 股票筛选器
**日期:** 2026-03-28
**版本:** 1.0.0

---

## 目录

1. [测试目标](#测试目标)
2. [测试范围](#测试范围)
3. [API 测试](#api-测试)
4. [前端测试](#前端测试)
5. [集成测试](#集成测试)
6. [测试环境](#测试环境)
7. [测试执行](#测试执行)
8. [缺陷管理](#缺陷管理)

---

## 测试目标

本测试计划旨在验证股票筛选器功能的正确性、稳定性和用户体验：

- ✅ 验证所有 API 端点的功能正确性
- ✅ 确保前端组件按预期工作
- ✅ 验证端到端工作流程的完整性
- ✅ 发现并记录缺陷
- ✅ 确保代码质量符合标准

---

## 测试范围

### 包含的功能

| 模块 | 功能 | 测试类型 |
|------|------|----------|
| API | 股票列表端点 | 单元测试 |
| API | 个股信息端点 | 单元测试 |
| API | K 线数据端点 | 单元测试 |
| API | 行业相关端点 | 单元测试 |
| API | 筛选过滤端点 | 单元测试 |
| 前端 | 条件构建器 | 组件测试 |
| 前端 | 权重配置 | 组件测试 |
| 前端 | 筛选功能 | 组件测试 |
| 前端 | 用户交互 | 交互测试 |
| 集成 | 完整工作流程 | E2E 测试 |

### 不包含的功能

- 性能压力测试（后续阶段）
- 安全测试（单独计划）
- 兼容性测试（单独计划）

---

## API 测试

### 测试文件

- `test/api/stock-selection-test.mbt`

### 测试覆盖

#### 1. 基础端点测试 (10 tests)

```
✓ GET /api/stocks - 返回股票列表
✓ GET /api/stocks - 响应包含必需字段
✓ GET /api/stocks - total 计数正确
```

#### 2. 个股信息端点测试 (3 tests)

```
✓ GET /api/stocks/:code - 返回个股信息
✓ GET /api/stocks/:code - 响应包含完整字段
✓ GET /api/stocks/:code - 不存在的股票返回 404
```

#### 3. K 线数据端点测试 (3 tests)

```
✓ GET /api/stocks/:code/klines - 返回 K 线数据
✓ GET /api/stocks/:code/klines - K 线包含 OHLCV 字段
✓ GET /api/stocks/:code/klines - 无效股票代码处理
```

#### 4. 行业相关端点测试 (4 tests)

```
✓ GET /api/industries - 返回行业列表
✓ GET /api/industries - 行业包含股票数量
✓ GET /api/industries/:name/stocks - 返回行业股票
✓ GET /api/industries/:name/stocks - 所有股票属于该行业
```

#### 5. 筛选功能测试 (5 tests)

```
✓ filter_stocks - 空筛选条件返回全部
✓ filter_stocks - 按行业筛选
✓ filter_stocks - 按市场筛选
✓ filter_stocks - 按状态筛选
✓ filter_stocks - 多条件组合筛选
```

#### 6. 权重排序功能测试 (3 tests)

```
✓ get_all_stocks - 股票列表非空
✓ get_all_industries - 行业列表无重复
✓ scan_stock_files - 股票代码格式正确
```

#### 7. 错误处理和边界情况测试 (5 tests)

```
✓ handle_get_stock - 空股票代码返回 404
✓ handle_get_klines - 空股票代码处理
✓ get_industry_for_code - 未知代码返回通用行业
✓ get_stocks_by_industry - 不存在的行业返回空列表
✓ handle_filter_stocks - 空查询处理
```

#### 8. 响应 Schema 验证 (5 tests)

```
✓ 股票列表响应格式验证
✓ 个股信息响应格式验证
✓ K 线数据响应格式验证
✓ 错误响应格式验证
✓ 行业列表响应格式验证
```

#### 9. 辅助函数测试 (4 tests)

```
✓ get_industry_for_code - 银行板块代码范围
✓ get_industry_for_code - 券商板块代码范围
✓ get_industry_for_code - 保险板块代码范围
✓ get_name_for_code - 名称格式一致
```

#### 10. 性能相关测试 (3 tests)

```
✓ get_all_stocks - 大量股票处理
✓ filter_stocks - 多条件筛选性能
✓ get_stocks_by_industry - 大行业处理
```

**API 测试总计：45 tests**

---

## 前端测试

### 测试文件

- `test/frontend/components.test.js` - 组件测试
- `test/frontend/weight-filter.test.js` - 权重和筛选测试

### 测试覆盖

#### 1. 权重配置组件 (16 tests)

```javascript
// 权重输入验证
✓ 应该接受有效权重值 (0.1-10)
✓ 应该拒绝无效权重值
✓ 应该支持小数权重
✓ 应该支持整数权重

// 权重计算
✓ 应该计算总权重
✓ 应该排除禁用条件的权重
✓ 应该计算加权分数
✓ 应该归一化权重

// 权重调整
✓ 应该增加权重
✓ 应该减少权重
✓ 应该限制最大权重
✓ 应该限制最小权重
```

#### 2. 筛选功能组件 (10 tests)

```javascript
// 操作符测试
✓ 应该包含所有操作符
✓ 应该验证大于操作符
✓ 应该验证大于等于操作符
✓ 应该验证小于操作符
✓ 应该验证等于操作符
✓ 应该验证不等于操作符
✓ 应该验证介于操作符

// 条件组合测试
✓ 应该支持 AND 逻辑
✓ 应该支持多条件筛选

// 范围筛选测试
✓ 应该筛选价格范围内的股票
✓ 应该筛选成交量范围内的股票
```

#### 3. 用户交互测试 (9 tests)

```javascript
// 条件添加测试
✓ 应该添加新条件
✓ 应该删除条件
✓ 应该清空所有条件

// 条件编辑测试
✓ 应该更新操作符
✓ 应该更新值
✓ 应该更新范围

// 拖拽排序测试
✓ 应该交换条件顺序
✓ 应该将条件移动到最后
```

#### 4. 组件状态管理 (7 tests)

```javascript
// 条件状态
✓ 应该展开条件详情
✓ 应该收起条件详情
✓ 应该启用/禁用条件

// 面板状态
✓ 应该切换活动面板

// 步骤导航状态
✓ 应该追踪当前步骤
✓ 应该限制步骤范围
```

#### 5. 数据验证 (6 tests)

```javascript
// 股票代码验证
✓ 应该验证有效的股票代码格式
✓ 应该拒绝无效的股票代码格式

// 数值范围验证
✓ 应该验证价格在合理范围内
✓ 应该验证涨跌幅在合理范围内

// 日期格式验证
✓ 应该验证日期格式
✓ 应该解析日期
```

**前端测试总计：48 tests**

---

## 集成测试

### 测试文件

- `test/integration/e2e.test.js`

### 测试覆盖

#### 1. 端到端工作流程 (10 tests)

```javascript
// 股票选择工作流
✓ 应该加载股票列表并显示
✓ 应该获取个股信息
✓ 应该获取 K 线数据

// 策略配置和回测工作流
✓ 应该加载可用策略
✓ 应该获取策略详情
✓ 应该运行回测
✓ 应该获取回测结果
✓ 应该计算回测指标

// 回撤分析工作流
✓ 应该获取个股回撤
✓ 应该获取组合回撤
```

#### 2. API + 前端集成 (8 tests)

```javascript
// 行业分析工作流
✓ 应该列出行业
✓ 应该获取行业股票计数

// 健康检查
✓ 应该响应健康检查

// 完整用户会话
✓ 应该完成完整分析工作流

// 错误处理
✓ 应该处理未知端点
✓ 应该处理无效股票代码
✓ 应该处理无效策略 ID

// 数据一致性
✓ 应该保持股票代码一致性
✓ 应该保持回测结果一致性

// 性能指标
✓ 应该快速完成健康检查
✓ 应该快速返回股票列表
✓ 应该在合理时间内完成回测
```

**集成测试总计：23 tests**

---

## 测试环境

### 硬件要求

| 资源 | 最低要求 | 推荐配置 |
|------|----------|----------|
| CPU | 2 cores | 4 cores |
| 内存 | 4 GB | 8 GB |
| 存储 | 1 GB | 2 GB |

### 软件要求

| 软件 | 版本 | 用途 |
|------|------|------|
| MoonBit CLI | latest | 后端测试 |
| Node.js | >=18.0.0 | 前端测试 |
| npm | >=9.0.0 | 依赖管理 |

### 依赖安装

```bash
# MoonBit 测试（无需额外依赖）
moon test

# JavaScript 测试依赖
npm install --save-dev jsdom
```

---

## 测试执行

### 执行命令

#### MoonBit 后端测试

```bash
# 运行所有测试
moon test

# 运行特定测试文件
moon test test/api/stock-selection-test.mbt
moon test src/server/routes/stocks_test.mbt
moon test src/server/routes/strategies_test.mbt
moon test src/server/routes/backtest_test.mbt
moon test src/server/routes/router_test.mbt

# 运行并生成覆盖率报告
moon test --coverage
```

#### JavaScript 前端测试

```bash
# 运行组件测试
node --test test/frontend/components.test.js

# 运行权重和筛选测试
node --test test/frontend/weight-filter.test.js

# 运行所有前端测试
node --test test/frontend/*.test.js
```

#### JavaScript 集成测试

```bash
# 运行集成测试
node --test test/integration/e2e.test.js

# 运行所有测试
node --test test/**/*.test.js
```

### 测试执行流程

```
1. 代码检查
   └─> moon check

2. 运行后端测试
   └─> moon test

3. 运行前端测试
   └─> node --test test/frontend/*.test.js

4. 运行集成测试
   └─> node --test test/integration/*.test.js

5. 生成报告
   └─> 查看测试结果摘要
```

---

## 缺陷管理

### 缺陷严重程度分类

| 级别 | 描述 | 响应时间 |
|------|------|----------|
| P0 - 严重 | 系统崩溃、数据丢失 | 立即 |
| P1 - 高 | 主要功能失效 | 24 小时 |
| P2 - 中 | 部分功能异常 | 3 天 |
| P3 - 低 | UI 问题、小缺陷 | 1 周 |

### 缺陷报告模板

```markdown
## 缺陷标题

**严重程度:** P1/P2/P3
**发现日期:** YYYY-MM-DD
**发现者:** [姓名]

### 复现步骤
1. 步骤 1
2. 步骤 2
3. 步骤 3

### 期望行为
[描述期望的结果]

### 实际行为
[描述实际观察到的结果]

### 环境信息
- OS: [操作系统]
- Browser: [浏览器版本]
- MoonBit: [版本号]

### 截图/日志
[附加相关文件]
```

### 缺陷跟踪

缺陷将在项目 issue tracker 中跟踪，标签包括：
- `bug` - 缺陷
- `test` - 测试相关
- `api` - API 相关
- `frontend` - 前端相关

---

## 测试交付物

### 测试代码

```
test/
├── api/
│   └── stock-selection-test.mbt      # API 测试 (45 tests)
├── frontend/
│   ├── components.test.js            # 组件测试 (56 tests)
│   └── weight-filter.test.js         # 权重筛选测试 (48 tests)
├── integration/
│   └── e2e.test.js                   # 集成测试 (23 tests)
├── TESTING_SUMMARY.md                # 测试总结
└── test-plan.md                      # 测试计划（本文档）
```

### 测试报告

- `docs/test-report.md` - 详细测试报告
- `test/TESTING_SUMMARY.md` - 测试执行摘要

### 测试统计

| 类别 | 测试数量 | 状态 |
|------|----------|------|
| API 测试 | 45 + 130 | ✅ 完成 |
| 前端测试 | 48 + 56 | ✅ 完成 |
| 集成测试 | 23 | ✅ 完成 |
| **总计** | **302** | **✅ 完成** |

---

## 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 编译错误阻止测试执行 | 中 | 高 | 优先修复构建问题 |
| 测试环境配置复杂 | 低 | 中 | 提供详细文档 |
| 测试覆盖率不足 | 低 | 中 | 持续添加测试用例 |
| 测试维护成本高 | 中 | 低 | 保持测试简洁 |

---

## 附录

### A. 测试模式说明

项目使用两种测试模式：

1. **黑盒测试** (`*_test.mbt`)
   - 测试公共 API
   - 验证外部行为
   - 不依赖内部实现

2. **白盒测试** (`*_wbtest.mbt`)
   - 测试内部函数
   - 验证实现细节
   - 使用 `using` 导入内部模块

### B. 参考文档

- [MoonBit 测试文档](https://moonbitlang.com/docs/testing)
- [Node.js Test Runner](https://nodejs.org/api/test.html)
- [项目架构文档](docs/architecture.md)
- [API 端点文档](docs/api-endpoints.md)

### C. 联系方式

- 测试负责人：[姓名]
- 开发负责人：[姓名]
- 项目管理：[姓名]

---

**文档版本历史:**

| 版本 | 日期 | 作者 | 变更 |
|------|------|------|------|
| 1.0.0 | 2026-03-28 | QA Team | 初始版本 |
