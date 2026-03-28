# 股票策略系统快速入门

**5 分钟上手指南**

本文档带你快速开始使用股票策略系统进行回测分析。

## 目录

1. [环境准备](#环境准备) - 2 分钟
2. [启动服务器](#启动服务器) - 1 分钟
3. [运行第一个回测](#运行第一个回测) - 2 分钟
4. [下一步](#下一步)

---

## 环境准备

### 1. 安装 MoonBit

```bash
# Linux/macOS
curl https://get.moonbitlang.com | bash

# Windows
# 访问 https://www.moonbitlang.com/downloads 下载安装程序
```

验证安装：
```bash
moon --version
```

### 2. 克隆项目

```bash
git clone https://github.com/retfings/alpha.git
cd alpha
```

### 3. 准备数据

使用 Baostock 下载股票数据：

```bash
# 安装依赖
pip install baostock

# 下载示例数据（浦发银行和平安银行）
python script/enhanced_downloader.py -s sh.600000 sz.000001

# 或下载全部 A 股（约需 15 分钟）
python script/enhanced_downloader.py --all -w 8
```

### 4. 验证环境

```bash
# 类型检查
moon check

# 运行测试
moon test
```

---

## 启动服务器

### 1. 构建并启动

```bash
# 启动 HTTP 服务器（默认端口 8080）
MOONBIT_CMD=serve moon run alpha
```

### 2. 验证服务器

打开新终端，测试服务器：

```bash
curl http://localhost:8080/api/health
```

预期响应：
```json
{"status":"ok","service":"moonbit-drawdown"}
```

---

## 运行第一个回测

### 方法 1：使用 Web 界面（推荐新手）

1. 打开浏览器访问：`http://localhost:8080`

2. 点击「股票策略」进入策略配置页面

3. **Step 1 - 择股设置**：
   - 选择股票池：输入 `sh.600000`（浦发银行）
   - 设置筛选条件（可选）

4. **Step 2 - 交易模型**：
   - 选择策略：`ma_cross`（均线交叉）
   - 配置参数：快周期=10，慢周期=30

5. **Step 3 - 回测设置**：
   - 开始日期：`2023-01-01`
   - 结束日期：`2023-12-31`
   - 初始资金：`100000`

6. 点击「运行回测」，等待结果

### 方法 2：使用 API

```bash
# 运行回测
curl -X POST http://localhost:8080/api/backtest \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "sh.600000",
    "strategy": "ma_cross",
    "start_date": "2023-01-01",
    "end_date": "2023-12-31",
    "initial_capital": 100000
  }'
```

响应：
```json
{
  "status": "completed",
  "result": {
    "initial_capital": 100000,
    "final_capital": 115000,
    "total_return": 0.15,
    "max_drawdown": -0.085,
    "sharpe_ratio": 1.25,
    "total_trades": 24
  }
}
```

### 方法 3：使用 CLI

```bash
# 运行回测
MOONBIT_CMD=backtest \
MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31" \
moon run alpha
```

---

## 解读回测结果

回测完成后，你将看到以下关键指标：

| 指标 | 值 | 说明 |
|------|-----|------|
| **总收益** | 15% | 策略期间的总回报率 |
| **最大回撤** | -8.5% | 最大亏损幅度 |
| **夏普比率** | 1.25 | 风险调整后收益（>1 为佳） |
| **交易次数** | 24 | 总交易笔数 |
| **胜率** | 62.5% | 盈利交易占比 |

### 收益曲线图

查看资金曲线走势，评估策略稳定性。

### 交易记录

查看每笔交易的详细信息：
- 买入/卖出时间
- 成交价格
- 成交数量
- 手续费

---

## 下一步

### 学习更多功能

1. **探索其他策略**
   ```bash
   # 查看可用策略
   curl http://localhost:8080/api/strategies
   ```

2. **股票筛选**
   ```bash
   # 按行业筛选股票
   curl "http://localhost:8080/api/stocks/filter?industry=银行"
   ```

3. **行业分析**
   ```bash
   # 查看行业列表
   curl http://localhost:8080/api/industries
   ```

### 深入文档

| 文档 | 描述 |
|------|------|
| [用户指南](user-guide.md) | 完整使用教程 |
| [API 参考](api-endpoints.md) | HTTP API 端点详解 |
| [开发者指南](developer-guide.md) | 开发环境搭建 |
| [策略示例](strategy-examples.md) | 策略编写示例 |

### 常见问题

**Q: 数据从哪里来？**

A: 使用 Baostock API 下载 A 股数据。参考 [数据下载指南](data-download-guide.md)。

**Q: 如何创建自定义策略？**

A: 在 `src/strategy/` 目录下创建新的 `.mbt` 文件。参考 [策略示例](strategy-examples.md)。

**Q: 服务器无法启动？**

A: 检查：
1. MoonBit 是否正确安装
2. 端口 8080 是否被占用
3. 运行 `moon check` 检查代码

---

## 总结

恭喜！你已经完成了：
- ✅ 环境配置
- ✅ 服务器启动
- ✅ 第一次回测
- ✅ 结果解读

现在你可以开始探索更高级的功能了！

---

*最后更新：2026-03-27*
*维护者：doc-engineer*
