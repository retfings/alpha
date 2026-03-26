#!/usr/bin/env python3
"""
Download stock data using baostock API.
Saves data to CSV files in the data/ directory.
"""

import os
import sys
from datetime import datetime, timedelta

import baostock as bs


def get_all_stock_codes() -> list[str]:
    """
    Get all A-share stock codes by enumerating valid code ranges.

    Returns:
        List of stock codes in format 'sh.xxx' or 'sz.xxx'
    """
    # Login first
    lg = bs.login()
    if lg.error_code != "0":
        print(f"Login failed: {lg.error_msg}")
        return []

    all_codes = []

    def scan_range(prefix: str, start: int, end: int, step: int = 100) -> list[str]:
        """Scan a range of stock codes."""
        codes = []
        for batch_start in range(start, end + 1, step):
            batch_end = min(batch_start + step - 1, end)
            for i in range(batch_start, batch_end + 1):
                code = f"{prefix}.{i:06d}"
                rs = bs.query_stock_basic(code=code)
                if rs.error_code == "0":
                    while rs.next():
                        row = rs.get_row_data()
                        if row and row[0]:
                            codes.append(row[0])
                            break
        return codes

    print("Scanning Shanghai main board (600000-605999)...")
    all_codes.extend(scan_range("sh", 600000, 605999))
    print(f"  Found {len(all_codes)} stocks so far")

    print("Scanning Shanghai STAR market (688000-688999)...")
    all_codes.extend(scan_range("sh", 688000, 688999))
    print(f"  Found {len(all_codes)} stocks so far")

    print("Scanning Shenzhen main board (000001-002999)...")
    all_codes.extend(scan_range("sz", 1, 2999))
    print(f"  Found {len(all_codes)} stocks so far")

    print("Scanning Shenzhen SME/GEM (300001-301999)...")
    all_codes.extend(scan_range("sz", 300001, 301999))
    print(f"  Found {len(all_codes)} stocks so far")

    bs.logout()
    return all_codes


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
    adjustflag: str = "2",
    show_progress: bool = True,
) -> None:
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
    """
    lg = bs.login()
    if lg.error_code != "0":
        print(f"Login failed: {lg.error_msg}")
        sys.exit(1)

    print(f"Logged in successfully. Downloading data for {len(stock_list)} stocks...")

    os.makedirs(output_dir, exist_ok=True)

    success_count = 0
    fail_count = 0

    for i, stock_code in enumerate(stock_list, 1):
        # 5 分钟级别需要额外字段
        if frequency == "5":
            fields = "date,time,open,high,low,close,volume,amount,turn"
        else:
            fields = "date,open,high,low,close,volume,amount,turn"

        rs = bs.query_history_k_data_plus(
            code=stock_code,
            fields=fields,
            start_date=start_date,
            end_date=end_date,
            frequency=frequency,
            adjustflag=adjustflag,
        )

        if rs.error_code != "0":
            fail_count += 1
            if show_progress:
                print(f"[{i}/{len(stock_list)}] Failed: {stock_code}: {rs.error_msg}")
            continue

        # 文件名包含复权信息
        adjust_suffix = "" if adjustflag == "2" else f"_qfq{adjustflag}"
        output_file = os.path.join(output_dir, f"{stock_code.replace('.', '_')}_{start_date}_{end_date}{adjust_suffix}.csv")
        rs.export_to_csv(output_file)
        success_count += 1

        if show_progress:
            print(f"[{i}/{len(stock_list)}] Downloaded: {stock_code} -> {output_file}")

    bs.logout()
    print(f"Download completed. Success: {success_count}, Failed: {fail_count}")


def main() -> None:
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Download stock data using baostock")
    parser.add_argument(
        "--stocks",
        "-s",
        nargs="+",
        default=None,
        help="Stock codes (e.g., sh.600000 sz.000001). Skip if --all is used.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Download all A-share stocks",
    )
    parser.add_argument(
        "--start",
        type=str,
        default=(datetime.now() - timedelta(days=365*3)).strftime("%Y-%m-%d"),
        help="Start date (YYYY-MM-DD), default: 3 years ago",
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

    # Determine stock list
    if args.all:
        print("Fetching all A-share stock codes...")
        stock_list = get_all_stock_codes()
        print(f"Found {len(stock_list)} stocks.")
    elif args.stocks:
        stock_list = args.stocks
    else:
        # Default to a few sample stocks
        stock_list = ["sh.600000", "sz.000001"]

    if not stock_list:
        print("No stocks to download.")
        sys.exit(1)

    # 5 分钟级别数据需要单独登录下载
    if args.frequency == "5":
        print(f"Downloading 5-minute level data with 前复权...")

    download_stocks_from_list(
        stock_list=stock_list,
        start_date=args.start,
        end_date=args.end,
        output_dir=args.output,
        frequency=args.frequency,
        adjustflag=args.adjustflag,
        show_progress=not args.quiet,
    )


if __name__ == "__main__":
    main()
