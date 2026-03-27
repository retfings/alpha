# 快速入门指南

本指南帮助你在 5 分钟内开始使用 MoonBit 量化回测框架。

## 1. 环境准备

### 安装 MoonBit

```bash
moon up
```

### 验证安装

```bash
moon --version
```

### 克隆项目

```bash
git clone <repository-url>
cd alpha
```

## 2. 构建和测试

### 类型检查

```bash
moon check    # 快速检查类型错误
```

### 构建项目

```bash
moon build    # 编译项目
```

### 运行测试

```bash
moon test     # 运行所有测试
```

## 3. 第一次回测

### 使用 CLI 运行回测

**重要**: 由于 MoonBit C 后端的参数传递机制，需要使用环境变量方式传递参数：

```bash
# 基本格式
MOONBIT_CMD=<command> MOONBIT_ARGS="<args>" moon run cmd/main

# 分析回撤
MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000 --metric max_drawdown" moon run cmd/main

# 运行回测
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31" moon run cmd/main

# 列出策略
MOONBIT_CMD=list-strategies moon run cmd/main

# 启动服务器
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run cmd/main
```

### 输出示例

```
================================
Backtest Report
================================
Initial Capital:  100000.00
Final Capital:    115000.00
Total Return:     15.00%
Max Drawdown:     -8.50%
Sharpe Ratio:     1.25
Total Trades:     24
Win Rate:         62.50%
================================
```

## 4. 编写你的第一个策略

### 创建策略文件

在 `src/strategy/builtins/` 目录下创建 `my_strategy.mbt`：

```moonbit
import retfings/alpha/src/data.{KLine}
import retfings/alpha/src/strategy.{Strategy, StrategyContext, Signal, Action}
import retfings/alpha/src/indicator.{sma}

/// 我的第一个策略：双均线交叉
pub fn my_ma_strategy() -> Strategy {
  Strategy {
    name: "My MA Cross",
    on_init: fn(ctx) {
      // 初始化逻辑
      io::println("策略初始化完成")
    },
    on_bar: fn(kline, ctx, indicators) {
      // 策略逻辑
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

### 计算指标

```moonbit
// 加载 K 线数据
let klines = data::load_klines_from_csv("data/sh.600000.csv")

// 提取收盘价
let closes = klines.map(fn(k) { k.close })

// 计算移动平均
let ma5 = indicator::sma(closes, 5)
let ma20 = indicator::sma(closes, 20)
```

## 5. 常用命令

| 命令 | 描述 | 用途 |
|------|------|------|
| `moon check` | 类型检查 | 验证代码正确性 |
| `moon build` | 构建项目 | 编译代码 |
| `moon test` | 运行测试 | 执行单元测试 |
| `moon fmt` | 格式化代码 | 统一代码风格 |
| `moon info` | 生成接口 | 生成公共接口文件 |
| `moon run cmd/main ...` | 运行程序 | 执行回测/分析 |

## 6. 下一步

### 学习更多

- [用户指南](user-guide.md) - 详细使用教程
- [API 参考](api-reference.md) - API 文档
- [策略示例](strategy-examples.md) - 策略编写示例

### 探索框架

- 查看内置策略：`src/strategy/builtins/`
- 查看技术指标：`src/indicator/`
- 查看风控规则：`src/risk/`

### 自定义策略

1. 参考 `src/strategy/builtins/ma_cross.mbt` 学习策略结构
2. 使用 `src/indicator/` 中的技术指标
3. 运行 `moon test` 确保策略正确
4. 使用 `moon run cmd/main backtest` 回测策略
   ```bash
   MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy my_strategy --stock sh.600000" moon run cmd/main
   ```

## 7. 获取帮助

### 查看帮助

```bash
MOONBIT_CMD=help moon run cmd/main
```

### 查阅文档

- [文档索引](INDEX.md) - 完整文档导航
- [常见问题](user-guide.md#troubleshooting) - 问题排查

### 社区支持

- [MoonBit 官方文档](https://www.moonbitlang.com/)
- [项目 Issues](https://github.com/your-repo/issues)

---

*最后更新：2026-03-27*
