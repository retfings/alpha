# 开发者指南

**版本**: 1.0
**创建日期**: 2026-03-27
**最后更新**: 2026-03-27

---

## 目录

1. [环境搭建](#环境搭建)
2. [代码规范](#代码规范)
3. [测试指南](#测试指南)
4. [调试技巧](#调试技巧)
5. [提交规范](#提交规范)

---

## 环境搭建

### 1. 系统要求

| 组件 | 最低版本 | 推荐版本 |
|------|----------|----------|
| MoonBit | latest | latest |
| Python | 3.6 | 3.9+ |
| Node.js (可选) | 14 | 18+ |
| Git | 2.0 | 2.30+ |

### 2. 安装 MoonBit

```bash
# Linux/macOS
curl https://get.moonbitlang.com | bash

# Windows
# 下载安装程序：https://www.moonbitlang.com/downloads

# 验证安装
moon --version
```

### 3. 克隆项目

```bash
git clone <repository-url>
cd alpha
```

### 4. 安装依赖

```bash
# 更新 MoonBit 依赖
moon update

# 安装 Python 依赖（用于数据下载）
cd script
pip install -r requirements.txt
```

### 5. 配置 Git Hooks

```bash
# 启用项目预提交钩子
git config core.hooksPath .githooks

# 验证钩子已启用
ls -la .githooks/
```

### 6. 验证环境

```bash
# 类型检查
moon check

# 运行测试
moon test

# 构建项目
moon build
```

### 7. IDE 配置

#### VS Code

1. 安装 MoonBit 扩展
2. 配置 `settings.json`:

```json
{
  "moonbit.path": "/path/to/moon",
  "editor.formatOnSave": true,
  "files.exclude": {
    "**/*.mbti": false
  }
}
```

### 8. 目录结构说明

```
alpha/
├── cmd/main/           # CLI 入口
├── src/                # 核心业务逻辑
│   ├── data/           # 数据层
│   ├── strategy/       # 策略引擎
│   ├── drawdown/       # 回撤计算
│   ├── risk/           # 风控管理
│   ├── portfolio/      # 投资组合
│   ├── indicator/      # 技术指标
│   └── backtest/       # 回测引擎
├── server/             # HTTP API 服务器
├── www/                # Web 前端
├── data/               # CSV 数据文件
├── script/             # Python 脚本
├── docs/               # 文档
├── test/               # 测试文件
├── .githooks/          # Git 钩子
└── moon.mod.json       # MoonBit 模块配置
```

---

## 代码规范

### MoonBit 代码规范

#### 1. 命名规范

```moonbit
// 类型名：PascalCase
pub struct KLine { ... }
pub enum Frequency { ... }

// 函数名：snake_case
pub fn load_klines_from_csv(path : String) -> Result[Array[KLine], String]

// 变量名：snake_case
let stock_code = "sh.600000"
let mut current_price = 10.5

// 常量名：UPPER_SNAKE_CASE
pub const DEFAULT_CAPITAL : Float = 100000.0

// 字段名：snake_case
pub struct BacktestConfig {
  start_date : String,
  end_date : String,
  initial_capital : Float,
}
```

#### 2. 函数规范

**函数应该短小精悍** (建议不超过 50 行):

```moonbit
/// 计算移动平均
/// 参数:
///   data - 输入数据数组
///   period - 周期
/// 返回:
///   SMA 数组
pub fn sma(data : Array[Float], period : Int) -> Array[Float] {
  if data.length() < period {
    return []
  }

  let result = []
  let mut i = 0
  while i <= data.length() - period {
    let sum = data.slice(i, i + period).fold(0.0, fn(acc, x) { acc + x })
    result.push(sum / Float::from_int(period))
    i = i + 1
  }
  result
}
```

**单一职责原则**: 一个函数只做一件事

```moonbit
// 好的设计
pub fn calculate_return(buy_price : Float, sell_price : Float) -> Float {
  (sell_price - buy_price) / buy_price
}

pub fn calculate_profit(return_rate : Float, capital : Float) -> Float {
  return_rate * capital
}

// 不好的设计 - 混合了多个职责
pub fn process_trade(...) -> Float {
  // 计算收益
  // 执行交易
  // 更新持仓
  // ...
}
```

#### 3. 注释规范

**公共 API 必须有文档注释**:

```moonbit
/// 从 CSV 文件加载 K 线数据
///
/// # 参数
/// - `file_path`: CSV 文件路径
///
/// # 返回
/// - `Ok(Array[KLine])`: K 线数组
/// - `Err(String)`: 错误信息
///
/// # 示例
/// ```moonbit
/// match data::load_klines_from_csv("data/sh.600000.csv") {
///   Ok(klines) => io::println("加载成功"),
///   Err(e) => io::println("加载失败：" + e)
/// }
/// ```
pub fn load_klines_from_csv(file_path : String) -> Result[Array[KLine], String]
```

**行内注释解释"为什么"而不是"是什么"**:

```moonbit
// 好的注释 - 解释原因
// 使用前复权价格以确保回测准确性
let adjusted_close = kline.close * adjustment_factor

// 不好的注释 - 重复代码
// 将收盘价乘以复权因子
let adjusted_close = kline.close * adjustment_factor
```

#### 4. 错误处理

**使用 Result 类型显式处理错误**:

```moonbit
pub fn load_and_process_data(path : String) -> Result[Array[KLine], String] {
  match data::load_klines_from_csv(path) {
    Ok(klines) => {
      match validate_klines(klines) {
        Ok(valid) => Ok(valid)
        Err(e) => Err("数据验证失败：" + e)
      }
    }
    Err(e) => Err("数据加载失败：" + e)
  }
}
```

**提供有意义的错误信息**:

```moonbit
// 好的错误信息
Err("加载 K 线失败：文件 'data/sh.600000.csv' 不存在")

// 不好的错误信息
Err("错误")
```

#### 5. 代码组织

**相关文件组织在同一目录**:

```
src/indicator/
├── ma.mbt           # 移动平均相关
├── macd.mbt         # MACD 相关
├── rsi.mbt          # RSI 相关
└── indicator_test.mbt  # 指标测试
```

**使用多个文件组织大模块**:

```moonbit
// data/types.mbt - 类型定义
pub struct KLine { ... }
pub enum Frequency { ... }

// data/loader.mbt - 数据加载
pub fn load_klines_from_csv(...) { ... }
pub fn parse_csv_content(...) { ... }

// data/processor.mbt - 数据处理
pub fn calculate_returns(...) { ... }
pub fn resample_klines(...) { ... }
```

---

### JavaScript 代码规范

#### 1. 命名规范

```javascript
// 类名：PascalCase
class StockStrategyApp { }

// 函数名：camelCase
async function loadStockPools() { }

// 变量名：camelCase
const selectedStocks = [];
let currentPrice = 10.5;

// 常量：UPPER_SNAKE_CASE
const API_BASE_URL = '/api';
const DEFAULT_CAPITAL = 100000;

// 私有属性：_前缀
this._cache = new Map();
```

#### 2. 异步代码

**使用 async/await 而非回调**:

```javascript
// 推荐
async function runBacktest() {
  try {
    const result = await API.runBacktest(config);
    displayResult(result);
  } catch (error) {
    showError(error.message);
  }
}

// 不推荐
function runBacktest() {
  API.runBacktest(config)
    .then(result => displayResult(result))
    .catch(error => showError(error.message));
}
```

#### 3. 错误处理

**始终捕获并处理错误**:

```javascript
async function loadData() {
  try {
    const data = await API.getStocks();
    return data;
  } catch (error) {
    console.error('加载股票失败:', error);
    throw new Error('无法加载股票数据，请检查网络连接');
  }
}
```

**提供用户友好的错误信息**:

```javascript
// 好的错误处理
catch (error) {
  if (error.code === 'DATA_NOT_FOUND') {
    showError('未找到相关数据，请检查股票代码');
  } else if (error.code === 'NETWORK_ERROR') {
    showError('网络连接失败，请检查网络');
  } else {
    showError('操作失败：' + error.message);
  }
}
```

---

## 测试指南

### MoonBit 测试

#### 1. 测试文件命名

```
// 黑盒测试
src/indicator/ma_test.mbt

// 白盒测试
src/indicator/ma_wbtest.mbt
```

#### 2. 编写单元测试

```moonbit
// ma_test.mbt
import retfings/alpha/src/indicator

test "sma basic calculation" {
  let data = [1.0, 2.0, 3.0, 4.0, 5.0]
  let result = indicator::sma(data, 3)

  assert_eq(result.length(), 3)
  assert_eq_float(result[0], 2.0)  // (1+2+3)/3
  assert_eq_float(result[1], 3.0)  // (2+3+4)/3
  assert_eq_float(result[2], 4.0)  // (3+4+5)/3
}

test "sma empty array" {
  let result = indicator::sma([], 5)
  assert_eq(result.length(), 0)
}

test "sma period larger than data" {
  let data = [1.0, 2.0]
  let result = indicator::sma(data, 5)
  assert_eq(result.length(), 0)
}
```

#### 3. 快照测试

```moonbit
test "backtest report snapshot" {
  let result = run_sample_backtest()
  let report = generate_report(result)

  snapshot(report)
}
```

#### 4. 运行测试

```bash
# 运行所有测试
moon test

# 运行特定目录的测试
moon test src/indicator

# 运行匹配的测试
moon test -F "*sma*"

# 更新快照测试
moon test --update
```

### JavaScript 测试

#### 1. 使用 Jest 测试

```javascript
// test/api.test.js
describe('API Client', () => {
  beforeEach(() => {
    fetch.mockClear();
  });

  test('getStocks should fetch from /api/stocks', async () => {
    fetch.mockResolvedValue({
      json: () => Promise.resolve({ stocks: [], total: 0 })
    });

    await API.getStocks();

    expect(fetch).toHaveBeenCalledWith('/api/stocks');
  });

  test('runBacktest should POST to /api/backtest', async () => {
    fetch.mockResolvedValue({
      json: () => Promise.resolve({ status: 'completed' })
    });

    const config = {
      stock_code: 'sh.600000',
      strategy: 'ma_cross',
      start_date: '2023-01-01',
      end_date: '2023-12-31'
    };

    await API.runBacktest(config);

    expect(fetch).toHaveBeenCalledWith('/api/backtest', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(config)
    });
  });
});
```

---

## 调试技巧

### MoonBit 调试

#### 1. 使用 io::println

```moonbit
pub fn debug_strategy(kline, ctx) {
  io::println("=== Debug Strategy ===")
  io::println("Date: " + kline.date)
  io::println("Price: " + String::from_float(kline.close))
  io::println("Position: " + String::from_float(ctx.position))
  io::println("====================")
}
```

#### 2. 类型检查

```bash
# 快速类型检查（不生成代码）
moon check

# 查看详细类型错误
moon check --verbose
```

#### 3. 使用 moon fmt 格式化

```bash
# 格式化所有代码
moon fmt

# 检查格式（不修改）
moon fmt --check
```

### JavaScript 调试

#### 1. 浏览器开发者工具

```javascript
// 调试输出
console.log('当前配置:', config);
console.table(stocks);

// 断点调试
debugger;  // 代码执行到此会暂停

// 性能分析
console.time('backtest');
await runBacktest();
console.timeEnd('backtest');
```

#### 2. 网络请求调试

```javascript
// 记录所有 API 请求
const originalFetch = window.fetch;
window.fetch = async (...args) => {
  console.log('API 请求:', args[0], args[1]);
  const response = await originalFetch(...args);
  const clone = response.clone();
  clone.json().then(data => console.log('API 响应:', data));
  return response;
};
```

---

## 提交规范

### Git 提交格式

```
<type>: <description>

[optional body]

[optional footer]
```

### Type 类型

| Type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 重构 |
| `test` | 测试相关 |
| `chore` | 构建/工具/配置 |

### 提交示例

```bash
# 新功能
git commit -m "feat: 实现 RSI 均值回归策略"

# Bug 修复
git commit -m "fix: 修复回撤计算边界条件错误"

# 文档更新
git commit -m "docs: 添加 API 端点文档"

# 重构
git commit -m "refactor: 重构数据加载模块"

# 测试
git commit -m "test: 添加指标计算单元测试"
```

### 提交前检查清单

```bash
# 1. 类型检查
moon check

# 2. 运行测试
moon test

# 3. 格式化代码
moon fmt

# 4. 生成接口文件
moon info

# 5. 查看变更
git status
git diff

# 6. 提交
git add .
git commit -m "type: description"

# 7. 推送
git push
```

---

## 常见问题

### Q: MoonBit 编译错误如何处理？

A: 先运行 `moon check` 查看详细错误信息，根据错误提示修复类型问题。

### Q: 如何调试策略逻辑？

A: 在策略的 `on_bar` 函数中添加 `io::println` 输出关键信息，或使用小规模数据测试。

### Q: 测试覆盖率如何查看？

A: 查看 `docs/test-coverage-report.md` 获取测试覆盖分析报告。

### Q: 如何添加新的技术指标？

A:
1. 在 `src/indicator/` 创建新文件
2. 实现指标计算函数
3. 编写单元测试
4. 在模块导出中添加导入

---

*文档维护者：doc-eng*
*最后更新：2026-03-27*
