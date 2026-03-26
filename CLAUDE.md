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

This is a MoonBit module (`moon.mod.json`) with a standard layout:

- **Root package** (`alpha.mbt`) - Library code and public APIs
- **cmd/main/** - Executable entry point with `options("is-main": true)`
- **Test files**: `*_test.mbt` (blackbox) and `*_wbtest.mbt` (whitebox)

MoonBit packages are per-directory with `moon.pkg` declaring imports. All `.mbt` files in a package are concatenated; declarations are package-scoped regardless of file. Use `///|` to separate top-level blocks.

## Development Workflow

1. Edit code in `.mbt` files
2. Run `moon check` to validate
3. Run `moon test` (use `--update` for snapshot changes)
4. Run `moon fmt && moon info` before committing
5. Review `.mbti` diffs to verify public API changes are intentional
6. Commit changes with `git commit`
7. Push to remote with `git push`

## Git Hooks

Pre-commit hook runs `moon check` automatically. Configure with:
```bash
git config core.hooksPath .githooks
```

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
