#!/usr/bin/env python3
"""
Baostock API wrapper module.

Provides a type-safe interface to the Baostock financial data API.
"""

from __future__ import annotations

import csv
import logging
import os
from dataclasses import dataclass
from datetime import datetime
from typing import Literal

import baostock as bs

logger = logging.getLogger(__name__)

# Type aliases
Frequency = Literal["d", "w", "m", "5", "15", "30", "60"]
AdjustFlag = Literal["1", "2", "3"]

# Baostock fields for different frequencies
DAILY_FIELDS = "date,open,high,low,close,volume,amount,turn"
MINUTE_FIELDS = "date,time,open,high,low,close,volume,amount,turn"


@dataclass
class StockData:
    """Represents a single row of stock data."""

    date: str
    open: float
    high: float
    low: float
    close: float
    volume: int
    amount: float
    turn: float
    time: str | None = None  # Only for minute-level data


@dataclass
class QueryResult:
    """Result of a data query."""

    success: bool
    error_code: str
    error_msg: str
    data: list[dict[str, str]]
    fields: list[str]


class BaostockClient:
    """
    A wrapper around the Baostock API providing convenient methods for
    querying stock data.
    """

    def __init__(self) -> None:
        """Initialize the client without logging in."""
        self._logged_in = False

    def login(self) -> bool:
        """
        Login to Baostock API.

        Returns:
            True if login successful, False otherwise.
        """
        if self._logged_in:
            return True

        lg = bs.login()
        self._logged_in = lg.error_code == "0"

        if not self._logged_in:
            logger.error(f"Baostock login failed: {lg.error_msg}")
        else:
            logger.info("Baostock login successful")

        return self._logged_in

    def logout(self) -> None:
        """Logout from Baostock API."""
        if self._logged_in:
            bs.logout()
            self._logged_in = False
            logger.info("Baostock logout successful")

    def __enter__(self) -> BaostockClient:
        """Context manager entry - login."""
        self.login()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Context manager exit - logout."""
        self.logout()

    def get_all_stock_codes(self) -> list[str]:
        """
        Get all A-share stock codes.

        Returns:
            List of stock codes in format 'sh.xxx' or 'sz.xxx'.
            Empty list if query fails.
        """
        if not self._logged_in:
            if not self.login():
                return []

        logger.info("Querying all A-share stocks...")
        rs = bs.query_stock_basic()

        all_codes: list[str] = []
        if rs.error_code == "0":
            while rs.next():
                row = rs.get_row_data()
                if row and row[0]:
                    code = row[0]
                    stock_type = row[4] if len(row) > 4 else ""

                    # Filter for A-share stocks
                    if (code.startswith("sh.") or code.startswith("sz.")) and stock_type == "1":
                        all_codes.append(code)

        logger.info(f"Found {len(all_codes)} A-share stocks")
        return all_codes

    def query_history_k_data(
        self,
        stock_code: str,
        start_date: str,
        end_date: str,
        frequency: Frequency = "d",
        adjust_flag: AdjustFlag = "2",
    ) -> QueryResult:
        """
        Query historical K-line data for a stock.

        Args:
            stock_code: Stock code (e.g., 'sh.600000')
            start_date: Start date (YYYY-MM-DD)
            end_date: End date (YYYY-MM-DD)
            frequency: Data frequency ('d', 'w', 'm', '5', '15', '30', '60')
            adjust_flag: Adjustment type ('1'=后复权，'2'=无复权，'3'=前复权)

        Returns:
            QueryResult containing the query status and data.
        """
        if not self._logged_in:
            if not self.login():
                return QueryResult(
                    success=False,
                    error_code="-1",
                    error_msg="Not logged in",
                    data=[],
                    fields=[],
                )

        # Select fields based on frequency
        fields = MINUTE_FIELDS if frequency in ("5", "15", "30", "60") else DAILY_FIELDS

        logger.debug(
            f"Querying {stock_code} from {start_date} to {end_date}, "
            f"frequency={frequency}, adjust={adjust_flag}"
        )

        rs = bs.query_history_k_data_plus(
            code=stock_code,
            fields=fields,
            start_date=start_date,
            end_date=end_date,
            frequency=frequency,
            adjustflag=adjust_flag,
        )

        if rs.error_code != "0":
            logger.error(f"Query failed for {stock_code}: {rs.error_msg}")
            return QueryResult(
                success=False,
                error_code=rs.error_code,
                error_msg=rs.error_msg,
                data=[],
                fields=list(rs.fields) if hasattr(rs, "fields") and rs.fields else [],
            )

        # Collect all data
        data: list[dict[str, str]] = []
        while rs.next():
            row_data = rs.get_row_data()
            if rs.fields and row_data:
                row_dict = dict(zip(rs.fields, row_data))
                data.append(row_dict)

        logger.debug(f"Retrieved {len(data)} records for {stock_code}")

        return QueryResult(
            success=True,
            error_code="0",
            error_msg="",
            data=data,
            fields=list(rs.fields) if hasattr(rs, "fields") and rs.fields else [],
        )

    def save_to_csv(
        self,
        result: QueryResult,
        output_path: str,
    ) -> bool:
        """
        Save query result to CSV file.

        Args:
            result: QueryResult from query_history_k_data
            output_path: Path to output CSV file

        Returns:
            True if save successful, False otherwise.
        """
        if not result.success or not result.data:
            logger.warning("No data to save")
            return False

        try:
            os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)

            with open(output_path, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=result.fields)
                writer.writeheader()
                writer.writerows(result.data)

            logger.info(f"Data saved to {output_path}")
            return True

        except Exception as e:
            logger.error(f"Failed to save CSV: {e}")
            return False

    def download_and_save(
        self,
        stock_code: str,
        start_date: str,
        end_date: str,
        output_dir: str,
        frequency: Frequency = "d",
        adjust_flag: AdjustFlag = "2",
    ) -> tuple[bool, str]:
        """
        Download stock data and save to CSV.

        Args:
            stock_code: Stock code
            start_date: Start date (YYYY-MM-DD)
            end_date: End date (YYYY-MM-DD)
            output_dir: Output directory
            frequency: Data frequency
            adjust_flag: Adjustment type

        Returns:
            Tuple of (success, message).
        """
        # Query data
        result = self.query_history_k_data(
            stock_code=stock_code,
            start_date=start_date,
            end_date=end_date,
            frequency=frequency,
            adjust_flag=adjust_flag,
        )

        if not result.success:
            return False, f"Query failed: {result.error_msg}"

        if not result.data:
            return False, "No data returned"

        # Generate output filename
        stock_suffix = stock_code.replace(".", "_")
        adjust_suffix = "" if adjust_flag == "2" else f"_qfq{adjust_flag}"
        filename = f"{stock_suffix}_{start_date}_{end_date}{adjust_suffix}.csv"
        output_path = os.path.join(output_dir, filename)

        # Save to CSV
        if self.save_to_csv(result, output_path):
            return True, f"Saved to {output_path}"
        else:
            return False, "Failed to save CSV"


def get_default_date_range(years: int = 3) -> tuple[str, str]:
    """
    Get default date range (end date is today, start date is N years ago).

    Args:
        years: Number of years to look back

    Returns:
        Tuple of (start_date, end_date) in YYYY-MM-DD format.
    """
    end_date = datetime.now()
    start_date = end_date.replace(year=end_date.year - years)
    return start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")


def setup_logging(level: int = logging.INFO) -> None:
    """
    Setup logging configuration.

    Args:
        level: Logging level (default: INFO)
    """
    logging.basicConfig(
        level=level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
