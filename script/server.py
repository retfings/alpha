#!/usr/bin/env python3
"""
Quantitative Drawdown Framework - HTTP API Server

FastAPI-based RESTful API server for the quantitative drawdown framework.
Provides endpoints for stock data, backtesting, and drawdown analysis.

Usage:
    uvicorn server:app --reload --port 8080
    # or
    python server.py
"""

import os
import csv
import json
from datetime import datetime
from typing import Optional, List, Dict, Any
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel, Field

# ============================================================================
# Configuration
# ============================================================================

# Get the project root directory (parent of 'script' directory)
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
WWW_DIR = PROJECT_ROOT / "www"

# ============================================================================
# FastAPI App
# ============================================================================

app = FastAPI(
    title="Quantitative Drawdown Framework API",
    description="RESTful API for stock backtesting and drawdown analysis",
    version="0.1.0"
)

# Mount static files for web frontend
if WWW_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(WWW_DIR)), name="static")

# ============================================================================
# Pydantic Models (Request/Response Schemas)
# ============================================================================

class StockInfo(BaseModel):
    code: str
    name: str
    exchange: str

class KLineData(BaseModel):
    date: str
    open: float
    high: float
    low: float
    close: float
    volume: float
    amount: float
    turn: float

class KLineResponse(BaseModel):
    stock_code: str
    klines: List[KLineData]

class DrawdownPoint(BaseModel):
    date: str
    value: float
    drawdown: float

class DrawdownResult(BaseModel):
    stock_code: str
    start_date: str
    end_date: str
    max_drawdown: float
    peak: float
    trough: float
    peak_date: str
    trough_date: str
    duration: int
    drawdown_series: List[DrawdownPoint]

class BacktestRequest(BaseModel):
    stock_code: str
    strategy: str = Field(default="ma_cross", description="Strategy name")
    start_date: str = Field(default="", description="Start date (YYYY-MM-DD)")
    end_date: str = Field(default="", description="End date (YYYY-MM-DD)")
    initial_capital: float = Field(default=100000.0, description="Initial capital")
    commission_rate: float = Field(default=0.0003, description="Commission rate")
    slippage: float = Field(default=0.001, description="Slippage")

class Trade(BaseModel):
    stock: str
    action: str
    price: float
    quantity: float
    timestamp: str
    commission: float

class EquityPoint(BaseModel):
    date: str
    equity: float
    drawdown: float
    position: float
    cash: float

class BacktestStats(BaseModel):
    total_return: float
    annual_return: float
    max_drawdown: float
    sharpe_ratio: float
    win_rate: float
    total_trades: int
    winning_trades: int
    losing_trades: int

class BacktestResult(BaseModel):
    initial_capital: float
    final_capital: float
    total_return: float
    max_drawdown: float
    sharpe_ratio: float
    total_trades: int
    equity_curve: List[EquityPoint]
    trades: List[Trade]
    stats: BacktestStats

class StrategyInfo(BaseModel):
    name: str
    description: str

class ErrorResponse(BaseModel):
    error: str

# ============================================================================
# Utility Functions
# ============================================================================

def scan_stocks() -> List[str]:
    """Scan data directory for available stock CSV files."""
    stocks = []
    if not DATA_DIR.exists():
        return stocks

    for file in DATA_DIR.glob("*.csv"):
        # Expected filename format: {exchange}_{code}_{start}_{end}.csv
        parts = file.stem.split("_")
        if len(parts) >= 2:
            exchange, code = parts[0], parts[1]
            stocks.append(f"{exchange}.{code}")

    return sorted(set(stocks))

def find_stock_file(stock_code: str) -> Optional[Path]:
    """Find the CSV file for a given stock code."""
    if not DATA_DIR.exists():
        return None

    # Parse stock code (e.g., "sh.600000")
    parts = stock_code.split(".")
    if len(parts) != 2:
        return None

    exchange, code = parts

    # Search for matching CSV file
    for file in DATA_DIR.glob(f"{exchange}_{code}_*.csv"):
        return file

    return None

def load_klines_from_csv(filepath: Path) -> List[Dict[str, Any]]:
    """Load K-line data from CSV file."""
    klines = []

    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                kline = {
                    "date": row.get("date", ""),
                    "open": float(row.get("open", 0)),
                    "high": float(row.get("high", 0)),
                    "low": float(row.get("low", 0)),
                    "close": float(row.get("close", 0)),
                    "volume": float(row.get("volume", 0)),
                    "amount": float(row.get("amount", 0)),
                    "turn": float(row.get("turn", 0)),
                }
                klines.append(kline)
            except (ValueError, KeyError) as e:
                continue

    return klines

def filter_klines_by_date(
    klines: List[Dict],
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
) -> List[Dict]:
    """Filter K-line data by date range."""
    result = klines

    if start_date:
        result = [k for k in result if k["date"] >= start_date]

    if end_date:
        result = [k for k in result if k["date"] <= end_date]

    return result

def calculate_drawdown_series(prices: List[float], dates: List[str]) -> List[Dict]:
    """Calculate drawdown series from price data."""
    if not prices or not dates:
        return []

    result = []
    peak = prices[0]
    peak_date = dates[0]

    for i, (price, date) in enumerate(zip(prices, dates)):
        if price > peak:
            peak = price
            peak_date = date

        drawdown = (peak - price) / peak if peak > 0 else 0

        result.append({
            "date": date,
            "value": price,
            "drawdown": -drawdown,  # Negative for drawdown
            "peak_date": peak_date
        })

    return result

def find_max_drawdown(drawdown_series: List[Dict]) -> Dict:
    """Find maximum drawdown from series."""
    if not drawdown_series:
        return {
            "max_drawdown": 0.0,
            "peak": 0.0,
            "trough": 0.0,
            "peak_date": "",
            "trough_date": "",
            "duration": 0
        }

    max_dd = 0.0
    max_dd_idx = 0

    for i, point in enumerate(drawdown_series):
        dd = abs(point["drawdown"])
        if dd > max_dd:
            max_dd = dd
            max_dd_idx = i

    peak_point = drawdown_series[max_dd_idx]
    trough_point = drawdown_series[max_dd_idx]

    # Find peak date
    peak_date = peak_point.get("peak_date", drawdown_series[0]["date"])

    # Calculate duration
    try:
        peak_dt = datetime.strptime(peak_date, "%Y-%m-%d")
        trough_dt = datetime.strptime(trough_point["date"], "%Y-%m-%d")
        duration = abs((trough_dt - peak_dt).days)
    except ValueError:
        duration = 0

    return {
        "max_drawdown": -max_dd,
        "peak": peak_point["value"],
        "trough": trough_point["value"],
        "peak_date": peak_date,
        "trough_date": trough_point["date"],
        "duration": duration
    }

# ============================================================================
# Mock Backtest Engine
# ============================================================================

def run_mock_backtest(
    klines: List[Dict],
    strategy: str,
    initial_capital: float,
    commission_rate: float,
    slippage: float
) -> Dict:
    """
    Run a mock backtest.

    In a real implementation, this would:
    1. Load the actual MoonBit backtest engine via C FFI
    2. Or implement a Python backtest engine
    3. Execute strategy signals and track positions

    For now, we generate realistic mock results for demonstration.
    """
    if not klines:
        raise ValueError("No K-line data provided")

    # Initialize state
    capital = initial_capital
    position = 0.0
    position_value = 0.0
    entry_price = 0.0

    equity_curve = []
    trades = []

    # Simple mock strategy logic
    in_position = False
    hold_days = 0

    for i, kline in enumerate(klines):
        date = kline["date"]
        price = kline["close"]

        # Calculate current equity
        if in_position:
            position_value = position * price
            unrealized_pnl = (price - entry_price) * position
            current_equity = capital + position_value + unrealized_pnl
        else:
            current_equity = capital

        # Calculate drawdown
        peak_equity = max([e["equity"] for e in equity_curve]) if equity_curve else current_equity
        drawdown = (peak_equity - current_equity) / peak_equity if peak_equity > 0 else 0

        equity_curve.append({
            "date": date,
            "equity": round(current_equity, 2),
            "drawdown": round(drawdown, 4),
            "position": round(position_value, 2) if in_position else 0,
            "cash": round(capital, 2)
        })

        # Mock trading logic (simple momentum-like)
        hold_days += 1

        if not in_position and i > 10 and hold_days > 5:
            # Enter position (buy)
            shares_to_buy = int((capital * 0.95) / price)
            if shares_to_buy > 0:
                cost = shares_to_buy * price * (1 + slippage)
                commission = cost * commission_rate

                if cost + commission <= capital:
                    capital -= (cost + commission)
                    position = shares_to_buy
                    position_value = shares_to_buy * price
                    entry_price = price
                    in_position = True
                    hold_days = 0

                    trades.append({
                        "stock": "mock",
                        "action": "Buy",
                        "price": round(price, 2),
                        "quantity": shares_to_buy,
                        "timestamp": date,
                        "commission": round(commission, 2)
                    })

        elif in_position and hold_days > 10:
            # Exit position (sell)
            sell_price = price * (1 - slippage)
            proceeds = position * sell_price
            commission = proceeds * commission_rate

            trades.append({
                "stock": "mock",
                "action": "Sell",
                "price": round(price, 2),
                "quantity": position,
                "timestamp": date,
                "commission": round(commission, 2)
            })

            capital += (proceeds - commission)
            position = 0
            position_value = 0
            in_position = False
            hold_days = 0

    # Close any open position at the end
    if in_position and klines:
        final_price = klines[-1]["close"]
        proceeds = position * final_price * (1 - slippage)
        commission = proceeds * commission_rate

        trades.append({
            "stock": "mock",
            "action": "Sell",
            "price": round(final_price, 2),
            "quantity": position,
            "timestamp": klines[-1]["date"],
            "commission": round(commission, 2)
        })

        capital += (proceeds - commission)

    # Calculate statistics
    final_capital = capital
    total_return = (final_capital - initial_capital) / initial_capital if initial_capital > 0 else 0

    # Annualized return (assuming 252 trading days)
    if len(klines) > 0:
        days = len(klines)
        annual_return = (1 + total_return) ** (252 / days) - 1 if days > 0 else 0
    else:
        annual_return = 0

    # Calculate max drawdown from equity curve
    max_dd = min([e["drawdown"] for e in equity_curve]) if equity_curve else 0

    # Calculate Sharpe ratio (simplified)
    if len(equity_curve) > 1:
        returns = []
        for i in range(1, len(equity_curve)):
            ret = (equity_curve[i]["equity"] - equity_curve[i-1]["equity"]) / equity_curve[i-1]["equity"]
            returns.append(ret)

        if returns:
            avg_return = sum(returns) / len(returns)
            std_return = (sum((r - avg_return) ** 2 for r in returns) / len(returns)) ** 0.5
            sharpe = (avg_return * 252) / (std_return * (252 ** 0.5)) if std_return > 0 else 0
        else:
            sharpe = 0
    else:
        sharpe = 0

    # Win/loss statistics
    winning_trades = len([t for t in trades if t["action"] == "Sell"]) // 2  # Approximate
    total_trades_count = len([t for t in trades if t["action"] == "Sell"])

    return {
        "initial_capital": initial_capital,
        "final_capital": round(final_capital, 2),
        "total_return": round(total_return, 4),
        "max_drawdown": round(max_dd, 4),
        "sharpe_ratio": round(sharpe, 3),
        "total_trades": total_trades_count,
        "equity_curve": equity_curve,
        "trades": trades,
        "stats": {
            "total_return": round(total_return, 4),
            "annual_return": round(annual_return, 4),
            "max_drawdown": round(max_dd, 4),
            "sharpe_ratio": round(sharpe, 3),
            "win_rate": 0.55,  # Mock value
            "total_trades": total_trades_count,
            "winning_trades": int(total_trades_count * 0.55),
            "losing_trades": int(total_trades_count * 0.45)
        }
    }

# ============================================================================
# API Routes
# ============================================================================

@app.get("/")
async def root():
    """Root endpoint - serves the web frontend."""
    index_path = WWW_DIR / "index.html"
    if index_path.exists():
        return FileResponse(str(index_path))
    return {"message": "Quantitative Drawdown Framework API", "docs": "/docs"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/api/stocks", response_model=List[str], tags=["Stocks"])
async def get_stocks():
    """
    Get list of available stocks.

    Returns stock codes in format: exchange.code (e.g., "sh.600000")
    """
    stocks = scan_stocks()

    if not stocks:
        # Return mock data if no stocks found
        return ["sh.600000", "sh.600004", "sh.600006", "sh.600007", "sh.600008"]

    return stocks

@app.get("/api/stocks/{stock_code}", response_model=StockInfo, tags=["Stocks"])
async def get_stock_info(stock_code: str):
    """Get information about a specific stock."""
    parts = stock_code.split(".")

    if len(parts) != 2:
        raise HTTPException(status_code=400, detail="Invalid stock code format. Use 'exchange.code'")

    exchange, code = parts

    return {
        "code": stock_code,
        "name": f"{exchange.upper()} {code}",
        "exchange": exchange.upper()
    }

@app.get("/api/stocks/{stock_code}/klines", response_model=KLineResponse, tags=["Stocks"])
async def get_klines(
    stock_code: str,
    start: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end: Optional[str] = Query(None, description="End date (YYYY-MM-DD)")
):
    """
    Get K-line data for a stock.

    Returns OHLCV data filtered by date range if specified.
    """
    # Find stock file
    filepath = find_stock_file(stock_code)

    if not filepath:
        raise HTTPException(
            status_code=404,
            detail=f"Stock '{stock_code}' not found. Check data directory."
        )

    # Load K-lines
    klines = load_klines_from_csv(filepath)

    # Filter by date
    klines = filter_klines_by_date(klines, start, end)

    return {
        "stock_code": stock_code,
        "klines": klines
    }

@app.get("/api/strategies", response_model=List[StrategyInfo], tags=["Strategies"])
async def get_strategies():
    """Get list of available trading strategies."""
    return [
        {"name": "ma_cross", "description": "均线交叉策略 (Moving Average Crossover)"},
        {"name": "momentum", "description": "动量策略 (Momentum)"},
        {"name": "mean_reversion", "description": "均值回归策略 (Mean Reversion)"}
    ]

@app.post("/api/backtest", response_model=BacktestResult, tags=["Backtest"])
async def run_backtest(request: BacktestRequest):
    """
    Run a backtest with the specified strategy.

    Executes the strategy on historical data and returns performance metrics.
    """
    # Find stock file
    filepath = find_stock_file(request.stock_code)

    if not filepath:
        raise HTTPException(
            status_code=404,
            detail=f"Stock '{request.stock_code}' not found"
        )

    # Load K-lines
    klines = load_klines_from_csv(filepath)

    # Filter by date range
    klines = filter_klines_by_date(klines, request.start_date, request.end_date)

    if not klines:
        raise HTTPException(
            status_code=400,
            detail="No data available for the specified date range"
        )

    # Run backtest
    try:
        result = run_mock_backtest(
            klines=klines,
            strategy=request.strategy,
            initial_capital=request.initial_capital,
            commission_rate=request.commission_rate,
            slippage=request.slippage
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/backtest/{backtest_id}/result", tags=["Backtest"])
async def get_backtest_result(backtest_id: str):
    """
    Get result of a previously run backtest.

    Note: In this implementation, backtests are not persisted.
    This endpoint is for API compatibility.
    """
    raise HTTPException(
        status_code=404,
        detail="Backtest results are not persisted. Run a new backtest."
    )

@app.get("/api/drawdown/{stock_code}", response_model=DrawdownResult, tags=["Analysis"])
async def get_drawdown(
    stock_code: str,
    start: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end: Optional[str] = Query(None, description="End date (YYYY-MM-DD)")
):
    """
    Calculate drawdown analysis for a stock.

    Returns maximum drawdown, peak/trough dates, and drawdown series.
    """
    # Find stock file
    filepath = find_stock_file(stock_code)

    if not filepath:
        raise HTTPException(
            status_code=404,
            detail=f"Stock '{stock_code}' not found"
        )

    # Load K-lines
    klines = load_klines_from_csv(filepath)

    # Filter by date
    klines = filter_klines_by_date(klines, start, end)

    if not klines:
        raise HTTPException(
            status_code=400,
            detail="No data available for the specified date range"
        )

    # Extract prices and dates
    prices = [k["close"] for k in klines]
    dates = [k["date"] for k in klines]

    # Calculate drawdown series
    drawdown_series = calculate_drawdown_series(prices, dates)

    # Find max drawdown
    max_dd_info = find_max_drawdown(drawdown_series)

    # Format drawdown series for response
    formatted_series = [
        {
            "date": point["date"],
            "value": point["value"],
            "drawdown": point["drawdown"]
        }
        for point in drawdown_series
    ]

    return {
        "stock_code": stock_code,
        "start_date": start or dates[0],
        "end_date": end or dates[-1],
        **max_dd_info,
        "drawdown_series": formatted_series
    }

@app.get("/api/portfolio/drawdown", tags=["Analysis"])
async def get_portfolio_drawdown():
    """
    Calculate portfolio-level drawdown.

    Note: This is a placeholder. Real implementation would require
    portfolio holdings data.
    """
    # Placeholder response
    return {
        "max_drawdown": -0.12,
        "current_drawdown": -0.05,
        "peak_date": "2024-01-15",
        "peak_value": 125000.0,
        "drawdown_series": [],
        "positions": []
    }

# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    """Run the server using uvicorn."""
    import uvicorn

    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║     Quantitative Drawdown Framework - HTTP Server         ║
    ╠═══════════════════════════════════════════════════════════╣
    ║  Server: http://localhost:8080                            ║
    ║  API Docs: http://localhost:8080/docs                     ║
    ║  Web UI: http://localhost:8080/                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """)

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        reload=False
    )

if __name__ == "__main__":
    main()
