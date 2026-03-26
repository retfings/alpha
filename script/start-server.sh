# HTTP Server Startup Script
# Usage: ./start-server.sh

#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "================================================"
echo "  Quantitative Drawdown Framework - HTTP Server"
echo "================================================"
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Server Script: $SCRIPT_DIR/server.py"
echo ""

# Check if dependencies are installed
if ! python -c "import fastapi, uvicorn" 2>/dev/null; then
    echo "Installing Python dependencies..."
    pip install -r "$SCRIPT_DIR/requirements.txt" -q
fi

echo ""
echo "Starting server on http://localhost:8080..."
echo ""
echo "Available endpoints:"
echo "  GET  /api/stocks                 - List stocks"
echo "  GET  /api/stocks/:code/klines    - Get K-line data"
echo "  GET  /api/strategies             - List strategies"
echo "  POST /api/backtest               - Run backtest"
echo "  GET  /api/drawdown/:code         - Get drawdown analysis"
echo "  GET  /api/portfolio/drawdown     - Get portfolio drawdown"
echo ""
echo "API Documentation: http://localhost:8080/docs"
echo "Web Interface:     http://localhost:8080/"
echo "================================================"
echo ""

cd "$PROJECT_ROOT"
python -m uvicorn script.server:app --host 0.0.0.0 --port 8080 --reload
