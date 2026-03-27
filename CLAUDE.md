# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
moon check              # Type check without building (fast, run regularly)
moon build              # Build project
moon run cmd/main       # Run main package
moon test               # Run all tests
moon test --update      # Update snapshot tests
moon test [dirname]     # Test specific directory
moon test -F "glob"     # Run tests matching filter
moon fmt                # Format code
moon info               # Generate public interface (.mbti) files
```

### CLI Commands (Environment Variable Mode)

**Important**: Due to MoonBit C backend's parameter passing mechanism, CLI commands require environment variables:

```bash
# Basic format
MOONBIT_CMD=<command> MOONBIT_ARGS="<arguments>" moon run cmd/main

# Show help
MOONBIT_CMD=help moon run cmd/main

# Start HTTP server (default port 8080)
MOONBIT_CMD=serve moon run cmd/main
MOONBIT_CMD=serve MOONBIT_ARGS="--port 3000" moon run cmd/main

# Analyze stock drawdown
MOONBIT_CMD=analyze MOONBIT_ARGS="--stock sh.600000 --metric max_drawdown" moon run cmd/main

# Run backtest
MOONBIT_CMD=backtest MOONBIT_ARGS="--strategy ma_cross --stock sh.600000 --start 2023-01-01 --end 2023-12-31" moon run cmd/main

# List available strategies
MOONBIT_CMD=list-strategies moon run cmd/main

# Generate report
MOONBIT_CMD=report MOONBIT_ARGS="--format html" moon run cmd/main
```

### Server API Endpoints

After starting the server with `MOONBIT_CMD=serve`, access APIs at `http://localhost:8080`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/stocks` | GET | List stocks |
| `/api/stocks/:code/klines` | GET | Get K-line data |
| `/api/backtest` | POST | Run backtest |
| `/api/drawdown/:code` | GET | Get drawdown analysis |

See `docs/api-endpoints.md` for complete API documentation.

## Architecture

This is a **quantitative drawdown framework** built with MoonBit, supporting both CLI and Web interfaces.

### Project Layout

```
alpha/
├── cmd/main/           # CLI entry point
├── src/                # Core business logic
│   ├── data/           # Data layer (CSV/Parquet loaders, KLine types)
│   ├── strategy/       # Strategy engine and built-in strategies
│   ├── drawdown/       # Drawdown calculation core
│   ├── risk/           # Risk management rules engine
│   ├── portfolio/      # Portfolio and position management
│   ├── indicator/      # Technical indicators (MA, MACD, RSI, etc.)
│   └── backtest/       # Backtest engine and reporting
├── server/             # HTTP API server
├── www/                # Web frontend (static files)
├── data/               # Stock data (CSV files)
├── script/             # Python utilities (data download)
└── docs/               # Documentation
```

### Key Components

- **Root package** (`alpha.mbt`) - Public API exports
- **cmd/main/** - CLI executable with command parsing
- **Test files**: `*_test.mbt` (blackbox) and `*_wbtest.mbt` (whitebox)

### Technical Stack

- **Data Format**: CSV (current), Parquet (planned)
- **Strategy Definition**: Pure MoonBit code (type-safe)
- **Web Backend**: Simple HTTP server in MoonBit
- **Web Frontend**: Static HTML/CSS/JS with Chart.js

MoonBit packages are per-directory with `moon.pkg` declaring imports. All `.mbt` files in a package are concatenated; declarations are package-scoped regardless of file. Use `///|` to separate top-level blocks.

### Documentation

**Core Documentation**:
- `docs/INDEX.md` - Complete documentation navigation
- `docs/QUICKSTART.md` - 5-minute quick start guide
- `docs/architecture.md` - Full architecture design
- `docs/api-reference.md` - Core modules API reference
- `docs/api-endpoints.md` - HTTP API endpoints reference
- `docs/frontend-backend-integration.md` - Frontend-backend integration guide
- `docs/user-guide.md` - User guide and tutorials
- `docs/strategy-examples.md` - Strategy examples and patterns

**Development Documentation**:
- `docs/optimization-roadmap.md` - Development and optimization plan
- `docs/test-coverage-report.md` - Test coverage analysis
- `docs/code-fixes.md` - Code fix records

## Development Workflow

1. Edit code in `.mbt` files
2. Run `moon check` to validate
3. Run `moon test` (use `--update` for snapshot changes)
4. Run `moon fmt && moon info` before committing
5. Review `.mbti` diffs to verify public API changes are intentional
6. Commit changes with `git commit`
7. Push to remote with `git push`

## Git Hooks

Configure with:
```bash
git config core.hooksPath .githooks
```

**Important:** Run the above command to enable hooks.

Available hooks:
- **pre-commit**: Runs `moon check` automatically before each commit
- **post-commit**: Logs file changes to `docs/changelogs.md` after each commit

## Skills

Three specialized skills are available in `.claude/skills/`:
- `moonbit-agent-guide` - General MoonBit development
- `moonbit-refactoring` - Idiomatic refactoring patterns
- `moonbit-c-binding` - C FFI bindings

## Git Workflow

**Important:** After any file changes, always commit and push to remote:

```bash
git add .
git commit -m "Your commit message"
git push
```

This ensures all changes are backed up to the remote repository immediately.
