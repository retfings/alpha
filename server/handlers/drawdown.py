"""
Drawdown analysis API handlers.
Provides endpoints for calculating and retrieving drawdown metrics.
"""

from datetime import datetime
from typing import List, Dict, Any, Optional

from pydantic import BaseModel


# ============================================================================
# Pydantic Models
# ============================================================================

class DrawdownPoint(BaseModel):
    """Single drawdown point."""
    date: str
    value: float
    drawdown: float


class DrawdownResult(BaseModel):
    """Drawdown analysis result."""
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


class PortfolioDrawdownResult(BaseModel):
    """Portfolio-level drawdown result."""
    max_drawdown: float
    current_drawdown: float
    peak_date: str
    peak_value: float
    drawdown_series: List[DrawdownPoint]
    positions: List[Any]


# ============================================================================
# Drawdown Calculation Functions
# ============================================================================

def calculate_drawdown_series(
    prices: List[float],
    dates: List[str]
) -> List[Dict[str, Any]]:
    """
    Calculate drawdown series from price data.

    Args:
        prices: List of prices (e.g., closing prices)
        dates: List of corresponding dates

    Returns:
        List of drawdown points with date, value, and drawdown percentage
    """
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


def find_max_drawdown(drawdown_series: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Find maximum drawdown from series.

    Args:
        drawdown_series: List of drawdown points

    Returns:
        Dictionary with max drawdown info
    """
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

    peak_date = peak_point.get("peak_date", drawdown_series[0]["date"])

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
# API Handlers
# ============================================================================

def get_drawdown_handler(
    stock_code: str,
    klines: List[Dict[str, Any]],
    start: Optional[str] = None,
    end: Optional[str] = None
) -> DrawdownResult:
    """
    Calculate drawdown for a stock.

    Args:
        stock_code: Stock code (e.g., "sh.600000")
        klines: List of K-line data
        start: Optional start date filter
        end: Optional end date filter

    Returns:
        DrawdownResult with max drawdown and series
    """
    # Filter by date range
    if start:
        klines = [k for k in klines if k["date"] >= start]
    if end:
        klines = [k for k in klines if k["date"] <= end]

    if not klines:
        raise ValueError("No data available for the specified date range")

    # Extract prices and dates
    prices = [k["close"] for k in klines]
    dates = [k["date"] for k in klines]

    # Calculate drawdown series
    drawdown_series = calculate_drawdown_series(prices, dates)

    # Find max drawdown
    max_dd_info = find_max_drawdown(drawdown_series)

    # Format series for response
    formatted_series = [
        DrawdownPoint(
            date=point["date"],
            value=point["value"],
            drawdown=point["drawdown"]
        )
        for point in drawdown_series
    ]

    return DrawdownResult(
        stock_code=stock_code,
        start_date=start or dates[0],
        end_date=end or dates[-1],
        **max_dd_info,
        drawdown_series=formatted_series
    )


def get_portfolio_drawdown_handler() -> PortfolioDrawdownResult:
    """
    Calculate portfolio-level drawdown.

    Note: This is a placeholder. Real implementation would require
    portfolio holdings data.
    """
    return PortfolioDrawdownResult(
        max_drawdown=-0.12,
        current_drawdown=-0.05,
        peak_date="2026-01-15",
        peak_value=125000.0,
        drawdown_series=[],
        positions=[]
    )
