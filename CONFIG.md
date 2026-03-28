# Configuration

This file describes the configuration options for the MoonBit Drawdown project.

## Configuration File (config.json)

The project supports a `config.json` file in the project root directory to customize settings.

### Available Options

```json
{
  "data_dir": "data"
}
```

- **data_dir**: Specifies the directory where stock data CSV files are stored.
  - Can be a relative path (resolved relative to project root)
  - Can be an absolute path (e.g., `/path/to/data` on Unix or `C:\data` on Windows)
  - Default: `"data"`

## Environment Variables

Environment variables take precedence over the configuration file:

- **`MOONBIT_DATA_DIR`**: Override the data directory path
  ```bash
  MOONBIT_DATA_DIR=/custom/data/path moon run alpha
  ```

- **`MOONBIT_CMD`**: Command to execute (analyze, backtest, monitor, report, serve, help)
- **`MOONBIT_ARGS`**: Space-separated command arguments
- **`DATA_FILES`**: Comma-separated list of data file names in the data directory

## Priority Order

1. Environment variable `MOONBIT_DATA_DIR` (highest priority)
2. `config.json` file `data_dir` field
3. Default `"data"` directory (relative to project root)

## Usage Examples

### From Project Root

```bash
# Uses config.json or default "data" directory
MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000 --metric max_drawdown" moon run alpha

# Override with environment variable
MOONBIT_DATA_DIR=/custom/data MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000" moon run alpha
```

### From Build Directory

```bash
cd _build/native/debug/build/alpha

# Uses config.json (finds project root automatically)
MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000 --metric max_drawdown" ./main.exe

# Or use absolute path via environment variable
MOONBIT_DATA_DIR=/mnt/c/Users/liujia/Desktop/project/moonbit/alpha/data ./main.exe
```
