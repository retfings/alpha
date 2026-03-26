"""
Backtest API handlers.
Provides endpoints for running backtests and retrieving results.
"""

import random
from datetime import datetime
from typing import List, Dict, Any, Optional

from pydantic import BaseModel, Field


# ============================================================================
# Pydantic Models
# ============================================================================

class BacktestConfig(BaseModel):
    """Backtest configuration."""
    stock_code: str
    strategy: str = Field(default="ma_cross")
    start_date: str = Field(default="")
    end_date: str = Field(default="")
    initial_capital: float = Field(default=100000.0)
    commission_rate: float = Field(default=0.0003)
    slippage: float = Field(default=0.001)


class Trade(BaseModel):
    """Trade record."""
    stock: str
    action: str
    price: float
    quantity: float
    timestamp: str
    commission: float


class EquityPoint(BaseModel):
    """Equity curve point."""
    date: str
    equity: float
    drawdown: float
    position: float
    cash: float


class BacktestStats(BaseModel):
    """Backtest statistics."""
    total_return: float
    annual_return: float
    max_drawdown: float
    sharpe_ratio: float
    win_rate: float
    total_trades: int
    winning_trades: int
    losing_trades: int


class BacktestResult(BaseModel):
    """Complete backtest result."""
    initial_capital: float
    final_capital: float
    total_return: float
    max_drawdown: float
    sharpe_ratio: float
    total_trades: int
    equity_curve: List[EquityPoint]
    trades: List[Trade]
    stats: BacktestStats


# ============================================================================
# Mock Backtest Engine
# ============================================================================

def run_mock_backtest(
    klines: List[Dict[str, Any]],
    strategy: str,
    initial_capital: float,
    commission_rate: float,
    slippage: float
) -> Dict[str, Any]:
    """
    Run a mock backtest.

    In production, this would call the MoonBit backtest engine via C FFI.
    For now, generates realistic mock results for demonstration.
    """
    if not klines:
        raise ValueError("No K-line data provided")

    capital = initial_capital
    position = 0.0
    position_value = 0.0
    entry_price = 0.0

    equity_curve = []
    trades = []

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

        # Mock trading logic
        hold_days += 1

        if not in_position and i > 10 and hold_days > 5:
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
                        "stock": kline.get("code", "mock"),
                        "action": "Buy",
                        "price": round(price, 2),
                        "quantity": shares_to_buy,
                        "timestamp": date,
                        "commission": round(commission, 2)
                    })

        elif in_position and hold_days > 10:
            sell_price = price * (1 - slippage)
            proceeds = position * sell_price
            commission = proceeds * commission_rate

            trades.append({
                "stock": kline.get("code", "mock"),
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
            "stock": klines[-1].get("code", "mock"),
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

    days = len(klines)
    annual_return = (1 + total_return) ** (252 / days) - 1 if days > 0 else 0

    max_dd = min([e["drawdown"] for e in equity_curve]) if equity_curve else 0

    # Calculate Sharpe ratio
    if len(equity_curve) > 1:
        returns = [
            (equity_curve[i]["equity"] - equity_curve[i-1]["equity"]) / equity_curve[i-1]["equity"]
            for i in range(1, len(equity_curve))
        ]
        if returns:
            avg_return = sum(returns) / len(returns)
            std_return = (sum((r - avg_return) ** 2 for r in returns) / len(returns)) ** 0.5
            sharpe = (avg_return * 252) / (std_return * (252 ** 0.5)) if std_return > 0 else 0
        else:
            sharpe = 0
    else:
        sharpe = 0

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
            "win_rate": 0.55,
            "total_trades": total_trades_count,
            "winning_trades": int(total_trades_count * 0.55),
            "losing_trades": int(total_trades_count * 0.45)
        }
    }


# ============================================================================
# API Handlers
# ============================================================================

def run_backtest_handler(
    klines: List[Dict[str, Any]],
    config: BacktestConfig
) -> BacktestResult:
    """Run backtest and return results."""
    result = run_mock_backtest(
        klines=klines,
        strategy=config.strategy,
        initial_capital=config.initial_capital,
        commission_rate=config.commission_rate,
        slippage=config.slippage
    )
    return BacktestResult(**result)


def get_strategies_handler() -> List[Dict[str, str]]:
    """Get list of available strategies."""
    return [
        {"name": "ma_cross", "description": "均线交叉策略 (Moving Average Crossover)"},
        {"name": "momentum", "description": "动量策略 (Momentum)"},
        {"name": "mean_reversion", "description": "均值回归策略 (Mean Reversion)"}
    ]
