# 测试计划文档

**版本**: 1.0
**创建日期**: 2026-03-27
**最后更新**: 2026-03-27

---

## 目录

1. [测试策略](#测试策略)
2. [前端测试](#前端测试)
3. [后端测试](#后端测试)
4. [数据测试](#数据测试)
5. [集成测试](#集成测试)
6. [测试报告](#测试报告)

---

## 测试策略

### 测试金字塔

```
        /#\       E2E 测试 (10%)
       /###\      集成测试 (20%)
      /#####\    单元测试 (70%)
     /#######\
```

### 测试工具

| 层级 | 工具 | 位置 |
|------|------|------|
| 单元测试 | MoonBit 内置测试 | `*_test.mbt`, `*_wbtest.mbt` |
| 集成测试 | MoonBit + Python | `tests/integration/` |
| E2E 测试 | pytest + Selenium | `tests/e2e/` |

### 运行测试

```bash
# 运行所有测试
moon test

# 运行特定目录测试
moon test src/strategy

# 更新快照测试
moon test --update

# 运行匹配过滤器的测试
moon test -F "ma_cross"
```

---

## 前端测试

### 测试范围

| 模块 | 测试类型 | 优先级 |
|------|---------|--------|
| `api.js` | 单元测试 | P0 |
| `app.js` | 单元测试 | P0 |
| `stock_strategy.js` | 单元测试 | P0 |
| 页面交互 | E2E 测试 | P1 |

### 单元测试示例

#### 测试 `api.js`

```javascript
// tests/frontend/api.test.js

import { describe, it, expect } from '@jest/globals';
import { API } from '../../www/api.js';

describe('API Client', () => {
  describe('getStocks()', () => {
    it('should return stock list', async () => {
      const stocks = await API.getStocks();
      expect(stocks).toBeInstanceOf(Array);
      expect(stocks.length).toBeGreaterThan(0);
    });

    it('should handle API errors', async () => {
      // Mock failed response
      global.fetch = jest.fn(() =>
        Promise.reject(new Error('Network error'))
      );

      await expect(API.getStocks()).rejects.toThrow('Network error');
    });
  });

  describe('runBacktest()', () => {
    it('should accept valid config', async () => {
      const config = {
        stock_code: 'sh.600000',
        strategy: 'ma_cross',
        start_date: '2023-01-01',
        end_date: '2023-12-31'
      };

      const result = await API.runBacktest(config);
      expect(result.status).toBe('completed');
    });

    it('should reject invalid config', async () => {
      const config = {
        stock_code: '',  // Invalid
        strategy: 'ma_cross'
      };

      await expect(API.runBacktest(config))
        .rejects.toThrow('Invalid stock code');
    });
  });
});
```

#### 测试 `stock_strategy.js`

```javascript
// tests/frontend/stock_strategy.test.js

describe('Stock Strategy Module', () => {
  describe('validateStep1()', () => {
    it('should pass with valid stock code', () => {
      const result = validateStep1({ stock_code: 'sh.600000' });
      expect(result.valid).toBe(true);
    });

    it('should fail with empty stock code', () => {
      const result = validateStep1({ stock_code: '' });
      expect(result.valid).toBe(false);
      expect(result.error).toContain('股票代码不能为空');
    });

    it('should fail with invalid format', () => {
      const result = validateStep1({ stock_code: 'invalid' });
      expect(result.valid).toBe(false);
      expect(result.error).toContain('股票代码格式错误');
    });
  });

  describe('buildBacktestConfig()', () => {
    it('should build complete config', () => {
      const steps = {
        step1: { stock_code: 'sh.600000' },
        step2: { strategy: 'ma_cross', params: { fast: 10, slow: 30 } },
        step3: { start: '2023-01-01', end: '2023-12-31', capital: 100000 }
      };

      const config = buildBacktestConfig(steps);
      expect(config.stock_code).toBe('sh.600000');
      expect(config.strategy).toBe('ma_cross');
      expect(config.initial_capital).toBe(100000);
    });
  });
});
```

### E2E 测试示例

```python
# tests/e2e/test_stock_strategy.py

import pytest
from selenium import webdriver
from selenium.webdriver.common.by import By

@pytest.fixture
def driver():
    driver = webdriver.Chrome()
    yield driver
    driver.quit()

def test_stock_strategy_flow(driver):
    """测试完整的股票策略流程"""
    # 1. 打开策略页面
    driver.get('http://localhost:8080/stock_strategy.html')

    # 2. Step 1: 输入股票代码
    driver.find_element(By.ID, 'stock-code-input').send_keys('sh.600000')
    driver.find_element(By.ID, 'btn-step-1-next').click()

    # 3. Step 2: 选择策略
    driver.find_element(By.ID, 'strategy-select').send_keys('ma_cross')
    driver.find_element(By.ID, 'btn-step-2-next').click()

    # 4. Step 3: 设置日期范围
    driver.find_element(By.ID, 'start-date').send_keys('2023-01-01')
    driver.find_element(By.ID, 'end-date').send_keys('2023-12-31')
    driver.find_element(By.ID, 'btn-run-backtest').click()

    # 5. 等待结果
    WebDriverWait(driver, 30).until(
        EC.visibility_of_element_located((By.ID, 'results-panel'))
    )

    # 6. 验证结果显示
    result_value = driver.find_element(By.ID, 'total-return').text
    assert '%' in result_value
```

---

## 后端测试

### 测试范围

| 模块 | 测试类型 | 优先级 |
|------|---------|--------|
| `src/data/` | 单元测试 | P0 |
| `src/strategy/` | 单元测试 + 快照 | P0 |
| `src/backtest/` | 单元测试 + 快照 | P0 |
| `src/drawdown/` | 单元测试 | P0 |
| `server/` | 集成测试 | P1 |

### 单元测试示例

#### 测试数据加载

```moonbit
// src/data/kline_test.mbt

test "load CSV data" {
  let csv_data = "date,open,high,low,close,volume
2023-01-01,10.5,10.8,10.4,10.7,1000000
2023-01-02,10.7,11.0,10.6,10.9,1200000"

  let klines = KLine.from_csv(csv_data)

  assert_eq(klines.length(), 2)
  assert_eq(klines[0].date, "2023-01-01")
  assert_eq(klines[0].close, 10.7)
}

test "handle empty CSV" {
  let klines = KLine.from_csv("")
  assert_eq(klines.length(), 0)
}

test "handle invalid data" {
  let invalid_csv = "date,open,high,low,close,volume
invalid,not_a_number,10.8,10.4,10.7,1000000"

  let result = Result.try(KLine.from_csv(invalid_csv))
  assert(result.is_error())
}
```

#### 测试策略逻辑

```moonbit
// src/strategy/ma_cross_test.mbt

test "generate buy signal on golden cross" {
  let strategy = MACrossStrategy::{fast: 10, slow: 30}
  let klines = get_test_klines()  // 预定义测试数据

  let signals = strategy.generate_signals(klines)

  // 第 35 天发生金叉
  assert_eq(signals[35].action, Action::Buy)
  assert_eq(signals[35].price, 10.50)
}

test "generate sell signal on death cross" {
  let strategy = MACrossStrategy::{fast: 10, slow: 30}
  let klines = get_test_klines_with_death_cross()

  let signals = strategy.generate_signals(klines)

  assert_eq(signals[50].action, Action::Sell)
}

test "no signal without crossover" {
  let strategy = MACrossStrategy::{fast: 10, slow: 30}
  let klines = get_uptrend_klines()  // 持续上涨无交叉

  let signals = strategy.generate_signals(klines)

  for signal in signals {
    assert_eq(signal.action, Action::Hold)
  }
}
```

#### 快照测试

```moonbit
// src/backtest/backtest_wbtest.mbt

test_snapshot "backtest ma_cross strategy" {
  let engine = BacktestEngine::{
    strategy: get_ma_cross_strategy(),
    klines: load_test_klines("sh_600000_2023.csv"),
    initial_capital: 100000.0
  }

  let result = engine.run()

  snapshot(result)
}
```

快照文件 (`*.snap`):
```
# src/backtest/backtest_wbtest.mbt.snap

test: "backtest ma_cross strategy"

---
BacktestResult {
  initial_capital: 100000.0,
  final_capital: 115234.56,
  total_return: 0.152345,
  max_drawdown: -0.084521,
  sharpe_ratio: 1.253421,
  total_trades: 24,
  win_rate: 0.625,
  profit_factor: 1.852341
}
---
```

### HTTP 服务器测试

```moonbit
// server/routes/strategies_test.mbt

test "list strategies" {
  let response = route_request("/api/strategies", "GET")

  assert_eq(response.status, 200)
  let json = json.parse(response.body)
  assert(json.has("strategies"))
  assert(json.has("total"))
}

test "get strategy by id" {
  let response = route_request("/api/strategies/ma_cross", "GET")

  assert_eq(response.status, 200)
  let json = json.parse(response.body)
  assert_eq(json.get("id"), "ma_cross")
  assert(json.has("parameters"))
}

test "return 404 for unknown strategy" {
  let response = route_request("/api/strategies/unknown", "GET")

  assert_eq(response.status, 404)
  let json = json.parse(response.body)
  assert(json.has("error"))
}
```

---

## 数据测试

### 测试范围

| 模块 | 测试类型 | 优先级 |
|------|---------|--------|
| `baostock_client.py` | 单元测试 | P0 |
| `enhanced_downloader.py` | 单元测试 + 集成 | P0 |
| 数据验证 | 集成测试 | P1 |
| 数据质量 | 定期测试 | P2 |

### Python 单元测试

```python
# tests/data/test_baostock_client.py

import pytest
from script.baostock_client import BaostockClient, get_default_date_range

class TestBaostockClient:

    def test_login_logout(self):
        """测试登录登出"""
        client = BaostockClient()

        # 登录
        assert client.login() == True
        assert client._logged_in == True

        # 重复登录
        assert client.login() == True

        # 登出
        client.logout()
        assert client._logged_in == False

    def test_context_manager(self):
        """测试上下文管理器"""
        with BaostockClient() as client:
            assert client._logged_in == True
            # 自动登出

        assert client._logged_in == False

    def test_get_all_stock_codes(self):
        """测试获取全部股票代码"""
        with BaostockClient() as client:
            codes = client.get_all_stock_codes()

            assert len(codes) > 0
            assert 'sh.600000' in codes
            assert all(c.startswith(('sh.', 'sz.')) for c in codes)

    def test_query_k_data(self):
        """测试查询 K 线数据"""
        with BaostockClient() as client:
            result = client.query_history_k_data(
                stock_code='sh.600000',
                start_date='2023-01-01',
                end_date='2023-01-31',
                frequency='d',
                adjust_flag='3'
            )

            assert result.success == True
            assert len(result.data) > 0
            assert 'date' in result.data[0]
            assert 'close' in result.data[0]
```

### 数据验证测试

```python
# tests/data/test_validate.py

import pytest
from script.enhanced_downloader import DataValidator

class TestDataValidator:

    def test_validate_price_range_valid(self):
        """测试有效价格范围"""
        data = [
            {'open': '10.5', 'high': '10.8', 'low': '10.4', 'close': '10.7'},
            {'open': '10.7', 'high': '11.0', 'low': '10.6', 'close': '10.9'}
        ]

        errors = DataValidator.validate_price_range(data)
        assert len(errors) == 0

    def test_validate_negative_price(self):
        """测试负价格检测"""
        data = [
            {'open': '10.5', 'high': '10.8', 'low': '-10.4', 'close': '10.7'}
        ]

        errors = DataValidator.validate_price_range(data)
        assert len(errors) > 0
        assert 'Negative low' in errors[0]

    def test_validate_extreme_price(self):
        """测试极端价格检测"""
        data = [
            {'open': '10.5', 'high': '10000.8', 'low': '10.4', 'close': '10.7'}
        ]

        errors = DataValidator.validate_price_range(data)
        assert len(errors) > 0
        assert 'Extreme high' in errors[0]

    def test_validate_date_sequence(self):
        """测试日期序列验证"""
        data = [
            {'date': '2023-01-01'},
            {'date': '2023-01-02'},
            {'date': '2023-01-03'}
        ]

        errors = DataValidator.validate_date_sequence(data, 'daily')
        assert len(errors) == 0

    def test_validate_date_gap(self):
        """测试日期间隔检测"""
        data = [
            {'date': '2023-01-01'},
            {'date': '2023-03-01'}  # 间隔 60 天
        ]

        errors = DataValidator.validate_date_sequence(data, 'daily')
        assert len(errors) > 0
        assert 'Large gap' in errors[0]

    def test_validate_price_continuity(self):
        """测试价格连续性检测"""
        data = [
            {'date': '2023-01-01', 'close': '10.0'},
            {'date': '2023-01-02', 'close': '20.0'}  # 翻倍
        ]

        errors = DataValidator.validate_price_continuity(data)
        assert len(errors) > 0
        assert 'Price jump' in errors[0]
```

### 数据质量定期测试

```python
# tests/data/test_data_quality.py

import pytest
from pathlib import Path
import csv

DATA_DIR = Path(__file__).parent.parent.parent / 'data'

class TestDataQuality:

    def test_all_files_readable(self):
        """测试所有数据文件可读"""
        csv_files = list(DATA_DIR.glob('*.csv'))
        assert len(csv_files) > 0

        for f in csv_files:
            with open(f, 'r') as fh:
                reader = csv.DictReader(fh)
                rows = list(reader)
                assert len(rows) > 0, f"Empty file: {f}"

    def test_all_files_have_required_columns(self):
        """测试所有文件包含必需列"""
        required_columns = ['date', 'open', 'high', 'low', 'close']

        for f in DATA_DIR.glob('*.csv'):
            with open(f, 'r') as fh:
                reader = csv.DictReader(fh)
                fieldnames = reader.fieldnames

                for col in required_columns:
                    assert col in fieldnames, f"Missing column {col} in {f}"

    def test_no_duplicate_dates(self):
        """测试无重复日期"""
        for f in DATA_DIR.glob('*.csv'):
            with open(f, 'r') as fh:
                reader = csv.DictReader(fh)
                dates = [row['date'] for row in reader]

                assert len(dates) == len(set(dates)), \
                    f"Duplicate dates found in {f}"
```

---

## 集成测试

### 前后端集成测试

```python
# tests/integration/test_api_integration.py

import pytest
import requests
import subprocess
import time

API_BASE = 'http://localhost:8080/api'

@pytest.fixture(scope='module')
def server():
    """启动测试服务器"""
    proc = subprocess.Popen(
        ['moon', 'run', 'cmd/main'],
        env={'MOONBIT_CMD': 'serve'}
    )
    time.sleep(3)  # 等待服务器启动

    yield

    proc.terminate()
    proc.wait()

class TestAPIIntegration:

    def test_health_check(self):
        """测试健康检查"""
        response = requests.get(f'{API_BASE}/health')
        assert response.status_code == 200
        assert response.json()['status'] == 'ok'

    def test_get_stocks(self):
        """测试获取股票列表"""
        response = requests.get(f'{API_BASE}/stocks')
        assert response.status_code == 200
        data = response.json()
        assert 'stocks' in data

    def test_get_klines(self):
        """测试获取 K 线数据"""
        response = requests.get(
            f'{API_BASE}/stocks/sh.600000/klines',
            params={'start': '2023-01-01', 'end': '2023-01-31'}
        )
        assert response.status_code == 200
        data = response.json()
        assert 'klines' in data
        assert len(data['klines']) > 0

    def test_run_backtest(self):
        """测试运行回测"""
        config = {
            'stock_code': 'sh.600000',
            'strategy': 'ma_cross',
            'start_date': '2023-01-01',
            'end_date': '2023-01-31',
            'initial_capital': 100000
        }

        response = requests.post(
            f'{API_BASE}/backtest',
            json=config
        )
        assert response.status_code == 200
        data = response.json()
        assert data['status'] in ['completed', 'started']

    def test_get_strategies(self):
        """测试获取策略列表"""
        response = requests.get(f'{API_BASE}/strategies')
        assert response.status_code == 200
        data = response.json()
        assert 'strategies' in data
        assert len(data['strategies']) > 0
```

---

## 测试报告

### 生成测试报告

```bash
# 运行测试并生成报告
moon test --coverage --report=html

# 查看覆盖率报告
open coverage/index.html
```

### 测试报告模板

```markdown
# 测试报告

**日期**: 2026-03-27
**版本**: v1.0.0

## 测试摘要

| 类别 | 总数 | 通过 | 失败 | 通过率 |
|------|------|------|------|--------|
| 单元测试 | 156 | 154 | 2 | 98.7% |
| 集成测试 | 24 | 23 | 1 | 95.8% |
| E2E 测试 | 8 | 8 | 0 | 100% |
| **总计** | **188** | **185** | **3** | **98.4%** |

## 失败测试

| 测试名 | 错误信息 | 优先级 |
|--------|---------|--------|
| test_extreme_price | assertion failed | P2 |
| test_industry_api | connection timeout | P1 |

## 覆盖率

| 模块 | 行覆盖率 | 分支覆盖率 |
|------|---------|-----------|
| src/data/ | 95% | 88% |
| src/strategy/ | 92% | 85% |
| src/backtest/ | 90% | 82% |
| server/ | 88% | 80% |

## 建议

1. 修复 2 个失败的单元测试
2. 提高 backtest 模块的分支覆盖率
3. 添加更多边界条件测试
```

---

## 附录

### A. 测试数据生成

```python
# tests/fixtures/generate_test_data.py

def generate_test_klines(count=100):
    """生成测试 K 线数据"""
    klines = []
    base_price = 10.0

    for i in range(count):
        date = f"2023-01-{i+1:02d}"
        open_price = base_price + random.uniform(-0.5, 0.5)
        close_price = open_price + random.uniform(-0.3, 0.3)
        high_price = max(open_price, close_price) + random.uniform(0.1, 0.3)
        low_price = min(open_price, close_price) - random.uniform(0.1, 0.3)

        klines.append({
            'date': date,
            'open': round(open_price, 2),
            'high': round(high_price, 2),
            'low': round(low_price, 2),
            'close': round(close_price, 2),
            'volume': random.randint(100000, 1000000)
        })

        base_price = close_price

    return klines
```

### B. Mock 数据

```python
# tests/fixtures/mocks.py

class MockResponse:
    def __init__(self, status_code, data):
        self.status_code = status_code
        self._data = data

    def json(self):
        return self._data

def mock_stocks_response():
    return MockResponse(200, {
        'stocks': [
            {'code': 'sh.600000', 'name': '浦发银行'},
            {'code': 'sz.000001', 'name': '平安银行'}
        ]
    })
```

---

*最后更新：2026-03-27*
*维护者：doc-engineer*
