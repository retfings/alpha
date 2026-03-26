# MoonBit Drawdown Framework - User Guide

## Overview

MoonBit Drawdown is a quantitative drawdown analysis framework built with MoonBit. It provides tools for backtesting trading strategies, calculating drawdown metrics, and managing risk controls.

### Key Features

- **Strategy Backtesting**: Test trading strategies on historical data
- **Drawdown Analysis**: Calculate and monitor drawdown metrics
- **Risk Management**: Built-in risk rules and controls
- **Technical Indicators**: MA, RSI, MACD, Bollinger Bands, ATR
- **Multiple Strategies**: MA Crossover, RSI Momentum, Mean Reversion
- **Report Generation**: HTML and text report formats

---

## Installation

### Prerequisites

- MoonBit toolchain installed
- Python 3.x (for data download scripts)
- BaoStock account (for A-share market data)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd alpha
```

2. Install MoonBit dependencies:
```bash
moon update
```

3. Configure git hooks (recommended):
```bash
git config core.hooksPath .githooks
```

## Quick Start

### 1. Download Stock Data

Use the provided Python script to download historical data:

```bash
python script/download_data.py --stocks sh.600000,sz.000001 --days 365
```

### 2. Run a Backtest

```bash
moon run cmd/main backtest --strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31
```

### 3. Analyze Drawdown

```bash
moon run cmd/main analyze --stock sh.600000 --metric max_drawdown
```

## CLI Commands

### `analyze` - Analyze Stock/Portfolio Drawdown

Analyze historical drawdown metrics for a stock or portfolio.

**Syntax:**
```bash
moon run cmd/main analyze --stock <CODE> --metric <METRIC>
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--stock` | Stock code (required) | - |
| `--metric` | Metric to analyze | `max_drawdown` |

**Available Metrics:**
- `max_drawdown` - Maximum historical drawdown
- `current_drawdown` - Current drawdown from peak
- `avg_drawdown` - Average drawdown
- `all` - All metrics

**Examples:**
```bash
# Analyze maximum drawdown for a single stock
moon run cmd/main analyze --stock sh.600000

# Analyze all metrics
moon run cmd/main analyze --stock sz.000001 --metric all

# Analyze multiple stocks (batch mode)
moon run cmd/main analyze --stocks sh.600000,sz.000001 --metrics all
```

### `backtest` - Run Strategy Backtest

Execute a trading strategy backtest over historical data.

**Syntax:**
```bash
moon run cmd/main backtest --strategy <NAME> --stock <CODE> --start <DATE> --end <DATE>
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--strategy` | Strategy name (required) | - |
| `--stock` | Stock code (required) | - |
| `--start` | Start date (YYYY-MM-DD) | - |
| `--end` | End date (YYYY-MM-DD) | - |
| `--capital` | Initial capital | 100000 |
| `--commission` | Commission rate | 0.0003 |
| `--slippage` | Slippage rate | 0.001 |

**Examples:**
```bash
# Basic backtest
moon run cmd/main backtest --strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31

# Backtest with custom capital
moon run cmd/main backtest --strategy momentum --stock sz.000001 --start 2023-01-01 --end 2023-06-30 --capital 500000
```

### `list-strategies` - List Available Strategies

Display all available trading strategies.

**Syntax:**
```bash
moon run cmd/main list-strategies
```

### `report` - Generate Analysis Report

Generate a comprehensive analysis report in HTML format.

**Syntax:**
```bash
moon run cmd/main report --output <FILENAME>
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--output` | Output filename | `report.html` |

**Examples:**
```bash
moon run cmd/main report --output my_analysis.html
```

### `help` - Show Help

Display help information.

```bash
moon run cmd/main help
```

## Configuration

### Backtest Configuration

Default backtest parameters can be configured in your strategy or via CLI flags:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `initial_capital` | 100,000 | Starting capital |
| `commission_rate` | 0.0003 (0.03%) | Trading commission |
| `slippage` | 0.001 (0.1%) | Price slippage |
| `benchmark` | None | Benchmark stock code |

### Risk Control Configuration

Risk rules can be configured with custom thresholds:

| Rule | Default | Description |
|------|---------|-------------|
| Max Drawdown | 20% | Stop trading if drawdown exceeds |
| Position Limit | 95% | Maximum position ratio |
| Daily Loss Limit | 5% | Stop trading if daily loss exceeds |

## Data Management

### Data Directory Structure

```
data/
├── sh.600000.csv    # Shanghai stock 600000
├── sz.000001.csv    # Shenzhen stock 000001
└── ...
```

### Stock Code Format

Stock codes follow the BaoStock format:
- Shanghai stocks: `sh.XXXXXX` (e.g., `sh.600000`)
- Shenzhen stocks: `sz.XXXXXX` (e.g., `sz.000001`)

### Downloading Data

```bash
# Download single stock
python script/download_data.py --stocks sh.600000

# Download multiple stocks
python script/download_data.py --stocks sh.600000,sz.000001,sz.000002

# Download with custom date range
python script/download_data.py --stocks sh.600000 --start-date 2023-01-01 --end-date 2023-12-31
```

## Interpreting Results

### Backtest Metrics

| Metric | Description |
|--------|-------------|
| `total_return` | Total return percentage |
| `annual_return` | Annualized return |
| `max_drawdown` | Maximum drawdown (negative %) |
| `sharpe_ratio` | Risk-adjusted return metric |
| `sortino_ratio` | Downside risk-adjusted return |
| `win_rate` | Percentage of winning trades |
| `profit_factor` | Gross profit / Gross loss |
| `total_trades` | Number of trades executed |

### Drawdown Interpretation

Drawdown values are expressed as negative percentages:
- `-0.10` = 10% drawdown
- `-0.25` = 25% drawdown
- More negative = worse drawdown

## Troubleshooting

### Common Issues

**"No data found for stock"**
- Ensure data files exist in the `data/` directory
- Run the download script to fetch data

**"Strategy not found"**
- Check strategy name with `list-strategies`
- Verify strategy is registered in the registry

**Type check errors**
- Run `moon check` to validate your code
- Ensure all `.mbt` files have correct syntax

### Getting Help

- Check the architecture documentation: `docs/architecture.md`
- Review strategy examples: `docs/strategy-examples.md`
- Run tests: `moon test`

## Best Practices

### Development Workflow

1. **Set up your environment**
   ```bash
   moon update
   git config core.hooksPath .githooks
   ```

2. **Download data for testing**
   ```bash
   python script/download_data.py --stocks sh.600000 --days 100
   ```

3. **Develop your strategy**
   - Create strategy in `src/strategy/builtins/your_strategy.mbt`
   - Add comprehensive docstrings
   - Write unit tests

4. **Test your changes**
   ```bash
   moon check     # Type check
   moon test      # Run all tests
   moon fmt       # Format code
   ```

5. **Run backtests**
   ```bash
   moon run cmd/main backtest --strategy your_strategy --stock sh.600000
   ```

6. **Review results and iterate**
   - Analyze drawdown metrics
   - Check trade log
   - Adjust parameters as needed

### Common Commands Reference

| Command | Description | When to Use |
|---------|-------------|-------------|
| `moon check` | Type check without building | After every code change |
| `moon build` | Build the project | Before running or testing |
| `moon test` | Run all tests | After code changes |
| `moon test --update` | Update snapshot tests | When expected outputs change |
| `moon fmt` | Format code | Before committing |
| `moon info` | Generate .mbti files | Before committing |
| `moon run cmd/main ...` | Run CLI commands | For backtesting/analysis |

### Code Style Guidelines

- Use descriptive names for functions and variables
- Add docstrings to all public APIs
- Keep functions focused and single-purpose
- Use pattern matching for enum handling
- Handle edge cases explicitly

---

## See Also

- [Architecture Documentation](architecture.md) - System architecture and design
- [Strategy Examples](strategy-examples.md) - Example strategies and patterns
- [API Reference](api-reference.md) - Complete API documentation
