#!/bin/bash
# HTTP Server Startup Script
# Usage: ./start.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "================================================"
echo "  量化回撤框架 - HTTP Server"
echo "================================================"
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Server: $SCRIPT_DIR/app.py"
echo ""

# Check dependencies
if ! python -c "import fastapi, uvicorn" 2>/dev/null; then
    echo "Installing Python dependencies..."
    pip install -r "$SCRIPT_DIR/requirements.txt" -q
fi

echo ""
echo "Starting server on http://localhost:8080..."
echo ""
echo "API Endpoints:"
echo "  GET  /api/stocks                 - 股票列表"
echo "  GET  /api/stocks/:code/klines    - K 线数据"
echo "  GET  /api/strategies             - 策略列表"
echo "  POST /api/backtest               - 运行回测"
echo "  GET  /api/drawdown/:code         - 回撤分析"
echo "  GET  /api/portfolio/drawdown     - 组合回撤"
echo ""
echo "API Documentation: http://localhost:8080/docs"
echo "Web Interface:     http://localhost:8080/"
echo "================================================"
echo ""

cd "$PROJECT_ROOT"
python -m uvicorn server.app:app --host 0.0.0.0 --port 8080 --reload
