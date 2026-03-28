#!/bin/bash
# MoonBit Test Runner Script
# Provides convenient test execution with filtering and reporting

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TEST_FILTER=""
UPDATE_SNAPSHOTS=false
VERBOSE=false
RUN_COVERAGE=false

# Print usage
usage() {
    cat << EOF
MoonBit Test Runner

Usage: $(basename "$0") [OPTIONS] [FILTER]

Options:
    -h, --help              Show this help message
    -u, --update            Update snapshot tests
    -v, --verbose           Verbose output
    -c, --coverage          Run coverage analysis (future)
    -f, --filter FILTER     Run tests matching FILTER (glob pattern)
    --list                  List all tests without running

Examples:
    $(basename "$0")                    # Run all tests
    $(basename "$0") -f "integration"   # Run integration tests
    $(basename "$0") -u                 # Update snapshots
    $(basename "$0") -f "backtest"      # Run backtest tests
    $(basename "$0") --list             # List all tests

Filter Patterns:
    "integration"       Tests containing "integration"
    "backtest"          Tests in backtest module
    "data/*"            All data module tests
    "*/loader_*"        All loader tests

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -u|--update)
            UPDATE_SNAPSHOTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            RUN_COVERAGE=true
            shift
            ;;
        -f|--filter)
            TEST_FILTER="$2"
            shift 2
            ;;
        --list)
            LIST_TESTS=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            TEST_FILTER="$1"
            shift
            ;;
    esac
done

# Print header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MoonBit Quantitative Backtest Framework${NC}"
echo -e "${BLUE}  Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# List tests mode
if [[ "$LIST_TESTS" == "true" ]]; then
    echo -e "${YELLOW}Finding tests...${NC}"
    echo

    # Find all test files
    find src -name "*_test.mbt" -o -name "*_wbtest.mbt" | sort | while read -r file; do
        echo "  $file"

        if [[ "$VERBOSE" == "true" ]]; then
            # Extract test names
            grep -E "^test \"" "$file" 2>/dev/null | sed 's/.*test "\([^"]*\)".*/    - \1/' || true
        fi
    done

    echo
    echo "Total test files: $(find src -name '*_test.mbt' -o -name '*_wbtest.mbt' | wc -l | tr -d ' ')"
    exit 0
fi

# Build test command
TEST_CMD="moon test"

if [[ "$UPDATE_SNAPSHOTS" == "true" ]]; then
    TEST_CMD="$TEST_CMD --update"
    echo -e "${YELLOW}Mode: Update snapshots${NC}"
fi

if [[ -n "$TEST_FILTER" ]]; then
    TEST_CMD="$TEST_CMD -F \"$TEST_FILTER\""
    echo -e "${YELLOW}Filter: $TEST_FILTER${NC}"
fi

echo -e "${BLUE}----------------------------------------${NC}"
echo

# Run tests
echo -e "${GREEN}Running tests...${NC}"
echo

if eval "$TEST_CMD"; then
    echo
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    exit 0
else
    echo
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${RED}✗ Some tests failed${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    exit 1
fi
