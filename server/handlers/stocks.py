"""
Stock data API handlers.
Provides endpoints for listing stocks and retrieving K-line data.
"""

import csv
from pathlib import Path
from typing import List, Optional, Dict, Any

from fastapi import HTTPException

# Project root is parent of 'server' directory
PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"


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

    parts = stock_code.split(".")
    if len(parts) != 2:
        return None

    exchange, code = parts

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
            except (ValueError, KeyError):
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


# ============================================================================
# API Handlers
# ============================================================================

def get_stocks_handler() -> List[str]:
    """Get list of available stocks."""
    return scan_stocks()


def get_stock_info_handler(stock_code: str) -> Dict[str, str]:
    """Get information about a specific stock."""
    parts = stock_code.split(".")
    if len(parts) != 2:
        raise HTTPException(status_code=400, detail="Invalid stock code format")

    exchange, code = parts
    return {
        "code": stock_code,
        "name": f"{exchange.upper()} {code}",
        "exchange": exchange.upper()
    }


def get_klines_handler(
    stock_code: str,
    start: Optional[str] = None,
    end: Optional[str] = None
) -> Dict[str, Any]:
    """Get K-line data for a stock."""
    filepath = find_stock_file(stock_code)

    if not filepath:
        raise HTTPException(
            status_code=404,
            detail=f"Stock '{stock_code}' not found"
        )

    klines = load_klines_from_csv(filepath)
    klines = filter_klines_by_date(klines, start, end)

    return {
        "stock_code": stock_code,
        "klines": klines
    }
