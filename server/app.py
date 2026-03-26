"""
Quantitative Drawdown Framework - HTTP API Server

FastAPI-based RESTful API server for stock backtesting and drawdown analysis.

Usage:
    uvicorn server.app:app --reload --port 8080
"""

from pathlib import Path

from fastapi import FastAPI, Query, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse

# Import handlers
from server.handlers.stocks import (
    get_stocks_handler,
    get_stock_info_handler,
    get_klines_handler
)
from server.handlers.backtest import (
    BacktestConfig,
    BacktestResult,
    run_backtest_handler,
    get_strategies_handler
)
from server.handlers.drawdown import (
    get_drawdown_handler,
    get_portfolio_drawdown_handler
)

# ============================================================================
# Configuration
# ============================================================================

PROJECT_ROOT = Path(__file__).parent.parent
WWW_DIR = PROJECT_ROOT / "www"

# ============================================================================
# FastAPI App
# ============================================================================

app = FastAPI(
    title="量化回撤框架 API",
    description="RESTful API for quantitative drawdown analysis and backtesting",
    version="0.1.0"
)

# Mount static files for web frontend
if WWW_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(WWW_DIR)), name="static")

# ============================================================================
# Root Endpoint
# ============================================================================

@app.get("/")
async def root():
    """Serve the web frontend."""
    index_path = WWW_DIR / "index.html"
    if index_path.exists():
        return FileResponse(str(index_path))
    return {"message": "量化回撤框架 API", "docs": "/docs"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    from datetime import datetime
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# ============================================================================
# Stock Endpoints
# ============================================================================

@app.get("/api/stocks", tags=["股票数据"])
async def get_stocks():
    """获取可用股票列表"""
    return get_stocks_handler()

@app.get("/api/stocks/{stock_code}", tags=["股票数据"])
async def get_stock_info(stock_code: str):
    """获取股票信息"""
    return get_stock_info_handler(stock_code)

@app.get("/api/stocks/{stock_code}/klines", tags=["股票数据"])
async def get_klines(
    stock_code: str,
    start: str = Query(None, description="开始日期 (YYYY-MM-DD)"),
    end: str = Query(None, description="结束日期 (YYYY-MM-DD)")
):
    """获取 K 线数据"""
    return get_klines_handler(stock_code, start, end)

# ============================================================================
# Strategy Endpoints
# ============================================================================

@app.get("/api/strategies", tags=["策略"])
async def get_strategies():
    """获取可用策略列表"""
    return get_strategies_handler()

# ============================================================================
# Backtest Endpoints
# ============================================================================

@app.post("/api/backtest", response_model=BacktestResult, tags=["回测"])
async def run_backtest(config: BacktestConfig):
    """
    运行策略回测

    执行策略并返回性能指标
    """
    # Get K-line data
    klines_result = get_klines_handler(
        config.stock_code,
        config.start_date if config.start_date else None,
        config.end_date if config.end_date else None
    )

    klines = klines_result.get("klines", [])

    if not klines:
        raise HTTPException(
            status_code=400,
            detail=f"No data available for stock '{config.stock_code}'"
        )

    # Run backtest
    result = run_backtest_handler(klines, config)
    return result

@app.get("/api/backtest/{backtest_id}/result", tags=["回测"])
async def get_backtest_result(backtest_id: str):
    """
    获取回测结果

    注意：当前实现不保存回测结果
    """
    raise HTTPException(
        status_code=404,
        detail="Backtest results are not persisted. Run a new backtest."
    )

# ============================================================================
# Drawdown Analysis Endpoints
# ============================================================================

@app.get("/api/drawdown/{stock_code}", tags=["回撤分析"])
async def get_drawdown(
    stock_code: str,
    start: str = Query(None, description="开始日期 (YYYY-MM-DD)"),
    end: str = Query(None, description="结束日期 (YYYY-MM-DD)")
):
    """
    计算个股回撤分析

    返回最大回撤、峰值/谷底日期和回撤序列
    """
    # Get K-line data
    klines_result = get_klines_handler(stock_code, start, end)
    klines = klines_result.get("klines", [])

    if not klines:
        raise HTTPException(
            status_code=400,
            detail="No data available for the specified date range"
        )

    return get_drawdown_handler(stock_code, klines, start, end)

@app.get("/api/portfolio/drawdown", tags=["回撤分析"])
async def get_portfolio_drawdown():
    """获取组合回撤分析"""
    return get_portfolio_drawdown_handler()

# ============================================================================
# Error Handlers
# ============================================================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Custom HTTP exception handler."""
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """General exception handler."""
    return JSONResponse(
        status_code=500,
        content={"error": str(exc)}
    )

# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    """Run the server using uvicorn."""
    import uvicorn

    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║     量化回撤框架 - HTTP Server                            ║
    ╠═══════════════════════════════════════════════════════════╣
    ║  Server: http://localhost:8080                            ║
    ║  API Docs: http://localhost:8080/docs                     ║
    ║  Web UI: http://localhost:8080/                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    uvicorn.run(app, host="0.0.0.0", port=8080, reload=False)

if __name__ == "__main__":
    main()
