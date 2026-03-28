#!/usr/bin/env python3
"""
Download stock data using baostock API.
Saves data to CSV files in the data/ directory.
"""

from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import datetime, timedelta

from baostock_client import (
    BaostockClient,
    Frequency,
    AdjustFlag,
    get_default_date_range,
    setup_logging,
)

logger = logging.getLogger(__name__)


def download_stocks_from_list(
    stock_list: list[str],
    start_date: str,
    end_date: str,
    output_dir: str,
    frequency: Frequency = "d",
    adjustflag: AdjustFlag = "2",
    show_progress: bool = True,
) -> tuple[int, int]:
    """
    Download data for multiple stocks.

    Args:
        stock_list: List of stock codes
        start_date: Start date in 'YYYY-MM-DD' format
        end_date: End date in 'YYYY-MM-DD' format
        output_dir: Directory to save CSV files
        frequency: Data frequency
        adjustflag: Adjustment type: 1=后复权，2=无复权，3=前复权
        show_progress: Whether to show progress messages

    Returns:
        Tuple of (success_count, fail_count)
    """
    client = BaostockClient()

    if not client.login():
        logger.error("Failed to login to Baostock")
        return 0, len(stock_list)

    if show_progress:
        print(f"Logged in successfully. Downloading data for {len(stock_list)} stocks...")

    os.makedirs(output_dir, exist_ok=True)

    success_count = 0
    fail_count = 0

    for i, stock_code in enumerate(stock_list, 1):
        success, message = client.download_and_save(
            stock_code=stock_code,
            start_date=start_date,
            end_date=end_date,
            output_dir=output_dir,
            frequency=frequency,
            adjust_flag=adjustflag,
        )

        if success:
            success_count += 1
            if show_progress:
                print(f"[{i}/{len(stock_list)}] Downloaded: {stock_code} -> {message}")
        else:
            fail_count += 1
            if show_progress:
                print(f"[{i}/{len(stock_list)}] Failed: {stock_code}: {message}")

    client.logout()

    if show_progress:
        print(f"Download completed. Success: {success_count}, Failed: {fail_count}")

    return success_count, fail_count


def main() -> None:
    """Main entry point."""
    setup_logging()

    parser = argparse.ArgumentParser(description="Download stock data using baostock")
    parser.add_argument(
        "--stocks",
        "-s",
        nargs="+",
        default=None,
        help="Stock codes (e.g., sh.600000 sz.000001). Ignored when --all is used.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Download all A-share stocks (can be combined with --start, --end, -o, -f, -a, -q)",
    )
    parser.add_argument(
        "--start",
        type=str,
        default=None,
        help="Start date (YYYY-MM-DD), default: 3 years ago",
    )
    parser.add_argument(
        "--end",
        type=str,
        default=None,
        help="End date (YYYY-MM-DD), default: today",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        default=os.path.join(os.path.dirname(__file__), "..", "data"),
        help="Output directory",
    )
    parser.add_argument(
        "--frequency",
        "-f",
        type=str,
        choices=["d", "w", "m", "5", "15", "30", "60"],
        default="d",
        help="Frequency: d=daily, w=weekly, m=monthly, 5/15/30/60=minute level",
    )
    parser.add_argument(
        "--adjustflag",
        "-a",
        type=str,
        choices=["1", "2", "3"],
        default="3",
        help="Adjustment: 1=后复权，2=无复权，3=前复权 (default)",
    )
    parser.add_argument(
        "--quiet",
        "-q",
        action="store_true",
        help="Suppress progress output",
    )

    args = parser.parse_args()

    # Set default date range if not specified
    start_date = args.start or get_default_date_range(3)[0]
    end_date = args.end or get_default_date_range(3)[1]

    # Determine stock list
    stock_list: list[str] = []

    if args.all:
        print("Fetching all A-share stock codes...")
        client = BaostockClient()
        if client.login():
            stock_list = client.get_all_stock_codes()
            client.logout()
            print(f"Found {len(stock_list)} stocks.")
        else:
            print("Failed to fetch stock list.")
            sys.exit(1)
    elif args.stocks:
        stock_list = args.stocks
    else:
        # Default to a few sample stocks
        stock_list = ["sh.600000", "sz.000001"]

    if not stock_list:
        print("No stocks to download.")
        sys.exit(1)

    download_stocks_from_list(
        stock_list=stock_list,
        start_date=start_date,
        end_date=end_date,
        output_dir=args.output,
        frequency=args.frequency,
        adjustflag=args.adjustflag,
        show_progress=not args.quiet,
    )


if __name__ == "__main__":
    main()
