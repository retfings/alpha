#!/usr/bin/env python3
"""
CSV to Parquet Conversion Tool for Stock Data

Convert downloaded CSV files to compressed Parquet format for better performance.

Requirements:
    pip install pandas pyarrow

Usage:
    python script/convert_to_parquet.py --all
    python script/convert_to_parquet.py --stocks sh.600000 sz.000001
    python script/convert_to_parquet.py --input data/sh_600000_*.csv
"""

from __future__ import annotations

import argparse
import glob
import logging
import os
import sys
from pathlib import Path

try:
    import pandas as pd
    import pyarrow as pa
    import pyarrow.parquet as pq
    PYARROW_AVAILABLE = True
except ImportError:
    PYARROW_AVAILABLE = False
    print("Warning: pandas and pyarrow are required for this tool.")
    print("Install with: pip install pandas pyarrow")

logger = logging.getLogger(__name__)


class ParquetConverter:
    """Convert CSV stock data files to Parquet format."""

    def __init__(
        self,
        compression: str = "snappy",
        output_dir: str | None = None,
        keep_csv: bool = True,
    ) -> None:
        """
        Initialize the converter.

        Args:
            compression: Compression codec (snappy, gzip, zstd, none)
            output_dir: Output directory for Parquet files
            keep_csv: Whether to keep original CSV files
        """
        self.compression = compression
        self.output_dir = output_dir
        self.keep_csv = keep_csv

    def convert_file(self, csv_path: str, output_path: str | None = None) -> dict:
        """
        Convert a single CSV file to Parquet.

        Args:
            csv_path: Path to input CSV file
            output_path: Optional output path (default: same name with .parquet)

        Returns:
            Conversion result dictionary
        """
        if not PYARROW_AVAILABLE:
            return {
                "success": False,
                "error": "pyarrow not installed",
                "csv_path": csv_path,
            }

        try:
            # Read CSV
            df = pd.read_csv(csv_path)

            # Optimize data types
            df = self._optimize_dtypes(df)

            # Determine output path
            if output_path is None:
                output_path = str(Path(csv_path).with_suffix(".parquet"))

            if self.output_dir:
                os.makedirs(self.output_dir, exist_ok=True)
                output_path = os.path.join(self.output_dir, Path(csv_path).name.replace(".csv", ".parquet"))

            # Save to Parquet
            table = pa.Table.from_pandas(df)
            pq.write_table(table, output_path, compression=self.compression)

            # Get file sizes
            csv_size = os.path.getsize(csv_path)
            parquet_size = os.path.getsize(output_path)
            compression_ratio = (1 - parquet_size / csv_size) * 100 if csv_size > 0 else 0

            result = {
                "success": True,
                "csv_path": csv_path,
                "parquet_path": output_path,
                "records": len(df),
                "csv_size_bytes": csv_size,
                "parquet_size_bytes": parquet_size,
                "compression_ratio": compression_ratio,
            }

            # Optionally remove CSV
            if not self.keep_csv:
                os.remove(csv_path)
                logger.info(f"Removed CSV: {csv_path}")

            return result

        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "csv_path": csv_path,
            }

    def _optimize_dtypes(self, df: pd.DataFrame) -> pd.DataFrame:
        """Optimize DataFrame data types for Parquet storage."""
        # Convert date columns to datetime
        if "date" in df.columns:
            df["date"] = pd.to_datetime(df["date"])

        # Optimize numeric columns
        numeric_cols = df.select_dtypes(include=["float64", "int64"]).columns

        for col in numeric_cols:
            # Check if column can be downcast
            col_min = df[col].min()
            col_max = df[col].max()

            if df[col].dtype == "float64":
                if col_min >= 0 and col_max <= 255:
                    df[col] = pd.to_numeric(df[col], downcast="unsigned")
                elif col_min >= -128 and col_max <= 127:
                    df[col] = pd.to_numeric(df[col], downcast="integer")
                else:
                    df[col] = pd.to_numeric(df[col], downcast="float")
            elif df[col].dtype == "int64":
                if col_min >= 0 and col_max <= 255:
                    df[col] = pd.to_numeric(df[col], downcast="unsigned")
                else:
                    df[col] = pd.to_numeric(df[col], downcast="integer")

        return df

    def batch_convert(
        self,
        csv_files: list[str],
        show_progress: bool = True,
    ) -> dict:
        """
        Convert multiple CSV files to Parquet.

        Args:
            csv_files: List of CSV file paths
            show_progress: Show progress output

        Returns:
            Batch conversion summary
        """
        results = []
        total_csv_size = 0
        total_parquet_size = 0
        total_records = 0
        success_count = 0
        fail_count = 0

        for i, csv_path in enumerate(csv_files, 1):
            if show_progress:
                print(f"[{i}/{len(csv_files)}] Converting: {csv_path}...", end=" ")

            result = self.convert_file(csv_path)
            results.append(result)

            if result["success"]:
                success_count += 1
                total_csv_size += result["csv_size_bytes"]
                total_parquet_size += result["parquet_size_bytes"]
                total_records += result["records"]

                if show_progress:
                    ratio = result["compression_ratio"]
                    print(f"OK ({result['records']} records, {ratio:.1f}% smaller)")
            else:
                fail_count += 1
                if show_progress:
                    print(f"FAIL: {result.get('error', 'Unknown error')}")

        # Calculate overall compression
        overall_ratio = (1 - total_parquet_size / total_csv_size) * 100 if total_csv_size > 0 else 0

        return {
            "total_files": len(csv_files),
            "successful": success_count,
            "failed": fail_count,
            "total_records": total_records,
            "total_csv_size": total_csv_size,
            "total_parquet_size": total_parquet_size,
            "compression_ratio": overall_ratio,
            "results": results,
        }


def find_stock_csv_files(data_dir: str, stock_codes: list[str] | None = None) -> list[str]:
    """Find CSV files for given stock codes or all stocks."""
    csv_files = []

    if stock_codes:
        for code in stock_codes:
            pattern = os.path.join(data_dir, f"{code.replace('.', '_')}_*.csv")
            csv_files.extend(glob.glob(pattern))
    else:
        # Find all CSV files in data directory
        pattern = os.path.join(data_dir, "*.csv")
        csv_files = glob.glob(pattern)

    # Exclude files in subdirectories
    csv_files = [f for f in csv_files if os.path.dirname(f) == data_dir]

    return sorted(csv_files)


def main() -> None:
    """Main entry point."""
    if not PYARROW_AVAILABLE:
        print("Error: pandas and pyarrow are required.")
        print("Install with: pip install pandas pyarrow")
        sys.exit(1)

    parser = argparse.ArgumentParser(
        description="Convert CSV stock data to Parquet format",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python convert_to_parquet.py --all                  # Convert all CSV files
  python convert_to_parquet.py -s sh.600000          # Convert specific stocks
  python convert_to_parquet.py --compression gzip    # Use gzip compression
  python convert_to_parquet.py --output parquet/     # Save to subdirectory
        """,
    )

    parser.add_argument(
        "--all",
        action="store_true",
        help="Convert all CSV files in data directory",
    )
    parser.add_argument(
        "--stocks", "-s",
        nargs="+",
        default=None,
        help="Stock codes to convert",
    )
    parser.add_argument(
        "--input",
        nargs="+",
        default=None,
        help="Input CSV file paths",
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        default=None,
        help="Output directory for Parquet files",
    )
    parser.add_argument(
        "--compression", "-c",
        type=str,
        choices=["snappy", "gzip", "zstd", "none"],
        default="snappy",
        help="Compression codec (default: snappy)",
    )
    parser.add_argument(
        "--keep-csv",
        action="store_true",
        default=True,
        help="Keep original CSV files (default: True)",
    )
    parser.add_argument(
        "--remove-csv",
        action="store_true",
        help="Remove original CSV files after conversion",
    )
    parser.add_argument(
        "--data-dir",
        type=str,
        default=os.path.join(os.path.dirname(__file__), "..", "data"),
        help="Data directory",
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Suppress progress output",
    )

    args = parser.parse_args()

    # Setup logging
    log_level = logging.WARNING if args.quiet else logging.INFO
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    # Determine input files
    if args.input:
        csv_files = args.input
    elif args.all or args.stocks:
        csv_files = find_stock_csv_files(args.data_dir, args.stocks)
    else:
        # Default to all files
        csv_files = find_stock_csv_files(args.data_dir)

    if not csv_files:
        print("No CSV files found to convert.")
        sys.exit(0)

    print(f"Found {len(csv_files)} CSV files to convert.")

    # Create converter
    converter = ParquetConverter(
        compression=args.compression,
        output_dir=args.output,
        keep_csv=not args.remove_csv,
    )

    # Run batch conversion
    print(f"Converting with {args.compression} compression...")
    print()

    report = converter.batch_convert(csv_files, show_progress=not args.quiet)

    # Print summary
    print()
    print("=" * 60)
    print("CONVERSION SUMMARY")
    print("=" * 60)
    print(f"  Total files:       {report['total_files']}")
    print(f"  Successful:        {report['successful']}")
    print(f"  Failed:            {report['failed']}")
    print(f"  Total records:     {report['total_records']:,}")
    print(f"  CSV size:          {report['total_csv_size'] / 1024 / 1024:.2f} MB")
    print(f"  Parquet size:      {report['total_parquet_size'] / 1024 / 1024:.2f} MB")
    print(f"  Compression ratio: {report['compression_ratio']:.1f}%")
    print("=" * 60)

    # Exit with error code if any conversion failed
    sys.exit(0 if report["failed"] == 0 else 1)


if __name__ == "__main__":
    main()
