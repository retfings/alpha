# Command Line Interface Documentation

## Overview

The `alpha` package provides a CLI for quantitative drawdown analysis. It supports multiple commands for analyzing stocks, running backtests, monitoring positions, and generating reports.

## Usage Pattern

```bash
MOONBIT_CMD=<command> MOONBIT_ARGS="<args>" moon run alpha
```

Commands are executed via environment variables:
- `MOONBIT_CMD` - The command to execute
- `MOONBIT_ARGS` - Space-separated arguments for the command

## Commands

### help

Show help message with usage examples.

```bash
MOONBIT_CMD=help moon run alpha
```

### analyze

Analyze drawdown metrics for a specific stock.

```bash
MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000 --metric max_drawdown" moon run alpha
```

**Options:**
- `--stock <code>` - Stock code in format `market.code` (e.g., `sh.600000`)
- `--metric <name>` - Metric to analyze (default: `max_drawdown`)

### backtest

Run a trading strategy backtest on historical data.

```bash
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2024-01-01 --end 2024-12-31" moon run alpha
```

**Options:**
- `--strategy <name>` - Strategy name (`ma_cross`, `momentum`, `rsi_mean_reversion`)
- `--stock <code>` - Stock code in format `market.code`
- `--start <date>` - Start date in `YYYY-MM-DD` format
- `--end <date>` - End date in `YYYY-MM-DD` format

### monitor

Monitor drawdown levels for a stock with alert thresholds.

```bash
MOONBIT_CMD=monitor MOONBIT_ARGS="--stock sh.600000" moon run alpha
```

**Options:**
- `--stock <code>` - Stock code in format `market.code`

**Alert Thresholds:**
- Warning: -10% drawdown
- Critical: -20% drawdown

### report

Generate backtest/analysis reports in various formats.

```bash
MOONBIT_CMD=report MOONBIT_ARGS="--format html" moon run alpha
```

**Options:**
- `--format <fmt>` - Output format: `text`, `html`, `json`

### list-strategies

List all available trading strategies.

```bash
MOONBIT_CMD=list-strategies moon run alpha
```

### serve

Start the HTTP API server.

```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 8080" moon run alpha
```

**Options:**
- `--port <number>` - Server port (default: `8080`)

## Environment Variables

### Data Directory Configuration

The data directory is resolved in the following priority order:

1. **`MOONBIT_DATA_DIR`** environment variable
2. **`config.json`** with `data_dir` field
3. Default: `data` directory in project root

```bash
# Using environment variable
MOONBIT_DATA_DIR=/path/to/data MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000" moon run alpha
```

```json
// config.json example
{
  "data_dir": "data"
}
```

### DATA_FILES

Specify available data files for faster lookup:

```bash
DATA_FILES="sh_600000_*.csv,sh_600001_*.csv" MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000" moon run alpha
```

## Available Strategies

| Strategy | Description | Parameters |
|----------|-------------|------------|
| `ma_cross` | Moving Average Crossover | `fast_period`, `slow_period` |
| `momentum` | Momentum-based strategy | `lookback_period`, `threshold` |
| `rsi_mean_reversion` | RSI-based mean reversion | `rsi_period`, `oversold`, `overbought` |

## Examples

### Analyze a stock's maximum drawdown

```bash
MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000" moon run alpha
```

### Run a full backtest

```bash
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2024-01-01 --end 2024-12-31" moon run alpha
```

### Generate an HTML report

```bash
MOONBIT_CMD=report MOONBIT_ARGS="--format html" moon run alpha
```

### Start the API server on port 3000

```bash
MOONBIT_CMD=serve MOONBIT_ARGS="--port 3000" moon run alpha
```
