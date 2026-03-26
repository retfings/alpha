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

- `docs/architecture.md` - Full architecture design

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
