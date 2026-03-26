#!/usr/bin/env python3
"""
Download stock data using baostock API.
Saves data to CSV files in the data/ directory.
"""

import os
import sys
from datetime import datetime, timedelta

import baostock as bs


def download_stock_data(
    stock_code: str,
    start_date: str,
    end_date: str,
    output_dir: str,
    frequency: str = "d",
    fields: str = "date,time,open,high,low,close,volume,amount,turn",
) -> None:
    """
    Download stock data and save to CSV.

    Args:
        stock_code: Stock code in format 'sh.xxx' or 'sz.xxx'
        start_date: Start date in 'YYYY-MM-DD' format
        end_date: End date in 'YYYY-MM-DD' format
        output_dir: Directory to save the CSV file
        frequency: 'd' (daily), 'w' (weekly), 'm' (monthly), default 'd'
        fields: Fields to download, default includes OHLCV and turnover
    """
    # Login to baostock
    lg = bs.login()
    if lg.error_code != "0":
        print(f"Login failed: {lg.error_msg}")
        sys.exit(1)

    print(f"Logged in successfully. Downloading data for {stock_code}...")

    # Query historical data
    rs = bs.query_history_k_data_plus(
        code=stock_code,
        fields=fields,
        start_date=start_date,
        end_date=end_date,
        frequency=frequency,
        adjustflag="2",  # No adjustment
    )

    if rs.error_code != "0":
        print(f"Query failed: {rs.error_msg}")
        bs.logout()
        sys.exit(1)

    # Export to CSV
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, f"{stock_code.replace('.', '_')}_{start_date}_{end_date}.csv")

    rs.export_to_csv(output_file)
    print(f"Data saved to: {output_file}")

    # Logout
    bs.logout()


def download_stocks_from_list(
    stock_list: list[str],
    start_date: str,
    end_date: str,
    output_dir: str,
    frequency: str = "d",
) -> None:
    """
    Download data for multiple stocks.

    Args:
        stock_list: List of stock codes
        start_date: Start date in 'YYYY-MM-DD' format
        end_date: End date in 'YYYY-MM-DD' format
        output_dir: Directory to save CSV files
        frequency: Data frequency
    """
    lg = bs.login()
    if lg.error_code != "0":
        print(f"Login failed: {lg.error_msg}")
        sys.exit(1)

    print(f"Logged in successfully. Downloading data for {len(stock_list)} stocks...")

    os.makedirs(output_dir, exist_ok=True)

    for stock_code in stock_list:
        fields = "date,time,open,high,low,close,volume,amount,turn"
        rs = bs.query_history_k_data_plus(
            code=stock_code,
            fields=fields,
            start_date=start_date,
            end_date=end_date,
            frequency=frequency,
            adjustflag="2",
        )

        if rs.error_code != "0":
            print(f"Failed to download {stock_code}: {rs.error_msg}")
            continue

        output_file = os.path.join(output_dir, f"{stock_code.replace('.', '_')}_{start_date}_{end_date}.csv")
        rs.export_to_csv(output_file)
        print(f"Downloaded: {stock_code} -> {output_file}")

    bs.logout()
    print("Download completed.")


def main() -> None:
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Download stock data using baostock")
    parser.add_argument(
        "--stocks",
        "-s",
        nargs="+",
        default=["sh.600000", "sz.000001"],
        help="Stock codes (e.g., sh.600000 sz.000001)",
    )
    parser.add_argument(
        "--start",
        type=str,
        default=(datetime.now() - timedelta(days=365)).strftime("%Y-%m-%d"),
        help="Start date (YYYY-MM-DD), default: 1 year ago",
    )
    parser.add_argument(
        "--end",
        type=str,
        default=datetime.now().strftime("%Y-%m-%d"),
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
        choices=["d", "w", "m"],
        default="d",
        help="Frequency: d=daily, w=weekly, m=monthly",
    )

    args = parser.parse_args()

    if len(args.stocks) == 1:
        download_stock_data(
            stock_code=args.stocks[0],
            start_date=args.start,
            end_date=args.end,
            output_dir=args.output,
            frequency=args.frequency,
        )
    else:
        download_stocks_from_list(
            stock_list=args.stocks,
            start_date=args.start,
            end_date=args.end,
            output_dir=args.output,
            frequency=args.frequency,
        )


if __name__ == "__main__":
    main()
