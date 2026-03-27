#!/usr/bin/env python3
"""
Data Validation Tool for Stock Data

Validates downloaded stock data for quality and completeness.

Usage:
    python script/validate_data.py --all
    python script/validate_data.py --stocks sh.600000 sz.000001
    python script/validate_data.py --report
"""

from __future__ import annotations

import argparse
import csv
import json
import logging
import os
import sys
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


@dataclass
class ValidationError:
    """Represents a single validation error."""

    error_type: str  # price, date, continuity
    severity: str  # warning, error
    message: str
    row_index: int | None = None
    field: str | None = None
    value: Any | None = None


@dataclass
class ValidationResult:
    """Validation result for a single stock."""

    stock_code: str
    file_path: str
    total_rows: int
    is_valid: bool
    errors: list[ValidationError]
    warnings: list[ValidationError]
    statistics: dict[str, Any]


class DataValidator:
    """Validate stock data for quality issues."""

    # Configuration thresholds
    DEFAULT_PRICE_THRESHOLD = 1000.0  # Maximum reasonable price
    DEFAULT_MAX_JUMP = 0.5  # 50% max price jump between days
    DAILY_MAX_GAP = timedelta(days=10)  # Max gap for daily data
    WEEKLY_MAX_GAP = timedelta(days=10)  # Max gap for weekly data
    MONTHLY_MAX_GAP = timedelta(days=40)  # Max gap for monthly data
    MINUTE_MAX_GAP = timedelta(minutes=5)  # Max gap for minute data

    def __init__(
        self,
        price_threshold: float = DEFAULT_PRICE_THRESHOLD,
        max_jump: float = DEFAULT_MAX_JUMP,
    ) -> None:
        self.price_threshold = price_threshold
        self.max_jump = max_jump

    def validate_price_range(self, data: list[dict]) -> list[ValidationError]:
        """Check for invalid price values (negative or extreme)."""
        errors = []
        price_fields = ["open", "high", "low", "close"]

        for i, row in enumerate(data):
            for field in price_fields:
                if field in row:
                    try:
                        value = float(row[field])
                        if value < 0:
                            errors.append(ValidationError(
                                error_type="price",
                                severity="error",
                                message=f"Negative {field} value: {value}",
                                row_index=i,
                                field=field,
                                value=value,
                            ))
                        elif value > self.price_threshold:
                            errors.append(ValidationError(
                                error_type="price",
                                severity="warning",
                                message=f"Extreme {field} value: {value} (>{self.price_threshold})",
                                row_index=i,
                                field=field,
                                value=value,
                            ))
                    except (ValueError, TypeError):
                        errors.append(ValidationError(
                            error_type="price",
                            severity="error",
                            message=f"Invalid {field} value: {row[field]}",
                            row_index=i,
                            field=field,
                            value=row[field],
                        ))

        return errors

    def validate_date_sequence(self, data: list[dict], frequency: str = "daily") -> list[ValidationError]:
        """Check for missing dates in the sequence."""
        errors = []

        if not data:
            return errors

        dates = []
        for i, row in enumerate(data):
            if "date" in row:
                try:
                    dates.append((i, datetime.strptime(row["date"], "%Y-%m-%d")))
                except ValueError:
                    errors.append(ValidationError(
                        error_type="date",
                        severity="error",
                        message=f"Invalid date format: {row['date']}",
                        row_index=i,
                        field="date",
                        value=row["date"],
                    ))

        if len(dates) < 2:
            return errors

        dates.sort(key=lambda x: x[1])

        # Select max gap based on frequency
        max_gap = {
            "d": self.DAILY_MAX_GAP,
            "w": self.WEEKLY_MAX_GAP,
            "m": self.MONTHLY_MAX_GAP,
            "5": self.MINUTE_MAX_GAP,
            "15": self.MINUTE_MAX_GAP,
            "30": self.MINUTE_MAX_GAP,
            "60": self.MINUTE_MAX_GAP,
        }.get(frequency, self.DAILY_MAX_GAP)

        for i in range(1, len(dates)):
            prev_idx, prev_date = dates[i - 1]
            curr_idx, curr_date = dates[i]
            gap = curr_date - prev_date

            if gap > max_gap:
                errors.append(ValidationError(
                    error_type="date",
                    severity="warning",
                    message=f"Large gap detected: {prev_date.date()} to {curr_date.date()} ({gap.days} days)",
                    row_index=curr_idx,
                    field="date",
                    value=f"{prev_date.date()} -> {curr_date.date()}",
                ))

        return errors

    def validate_price_continuity(self, data: list[dict]) -> list[ValidationError]:
        """Detect extreme price jumps between consecutive days."""
        errors = []

        if len(data) < 2:
            return errors

        for i in range(1, len(data)):
            try:
                prev_close = float(data[i - 1].get("close", 0))
                curr_open = float(data[i].get("open", 0))

                if prev_close > 0:
                    jump = abs(curr_open - prev_close) / prev_close
                    if jump > self.max_jump:
                        errors.append(ValidationError(
                            error_type="continuity",
                            severity="warning",
                            message=f"Price jump detected: {prev_close:.2f} -> {curr_open:.2f} ({jump*100:.1f}%)",
                            row_index=i,
                            field="open",
                            value=f"{jump*100:.1f}%",
                        ))
            except (ValueError, TypeError):
                pass

        return errors

    def validate_volume(self, data: list[dict]) -> list[ValidationError]:
        """Check for invalid volume values."""
        errors = []

        for i, row in enumerate(data):
            if "volume" in row:
                try:
                    value = float(row["volume"])
                    if value < 0:
                        errors.append(ValidationError(
                            error_type="volume",
                            severity="error",
                            message=f"Negative volume: {value}",
                            row_index=i,
                            field="volume",
                            value=value,
                        ))
                except (ValueError, TypeError):
                    errors.append(ValidationError(
                        error_type="volume",
                        severity="error",
                        message=f"Invalid volume value: {row['volume']}",
                        row_index=i,
                        field="volume",
                        value=row["volume"],
                    ))

        return errors

    def compute_statistics(self, data: list[dict]) -> dict[str, Any]:
        """Compute basic statistics for the data."""
        if not data:
            return {}

        stats: dict[str, Any] = {
            "total_rows": len(data),
        }

        # Date range
        dates = [row.get("date") for row in data if row.get("date")]
        if dates:
            stats["date_range"] = {"start": min(dates), "end": max(dates)}

        # Price statistics
        price_fields = ["open", "high", "low", "close"]
        for field in price_fields:
            values = []
            for row in data:
                if field in row:
                    try:
                        values.append(float(row[field]))
                    except (ValueError, TypeError):
                        pass

            if values:
                stats[f"{field}_stats"] = {
                    "min": min(values),
                    "max": max(values),
                    "avg": sum(values) / len(values),
                }

        # Volume statistics
        if "volume" in data[0]:
            volumes = []
            for row in data:
                if "volume" in row:
                    try:
                        volumes.append(float(row["volume"]))
                    except (ValueError, TypeError):
                        pass

            if volumes:
                stats["volume_stats"] = {
                    "min": min(volumes),
                    "max": max(volumes),
                    "avg": sum(volumes) / len(volumes),
                }

        return stats

    def validate_all(
        self,
        data: list[dict],
        stock_code: str,
        file_path: str,
        frequency: str = "d",
    ) -> ValidationResult:
        """Run all validations and return comprehensive result."""
        price_errors = self.validate_price_range(data)
        date_errors = self.validate_date_sequence(data, frequency)
        continuity_errors = self.validate_price_continuity(data)
        volume_errors = self.validate_volume(data)

        all_errors = price_errors + date_errors + continuity_errors + volume_errors
        errors = [e for e in all_errors if e.severity == "error"]
        warnings = [e for e in all_errors if e.severity == "warning"]

        statistics = self.compute_statistics(data)

        return ValidationResult(
            stock_code=stock_code,
            file_path=file_path,
            total_rows=len(data),
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            statistics=statistics,
        )


class DataFileManager:
    """Manage stock data files."""

    def __init__(self, data_dir: str) -> None:
        self.data_dir = Path(data_dir)

    def find_stock_files(self, stock_codes: list[str] | None = None) -> dict[str, str]:
        """
        Find CSV files for given stock codes or all stocks.

        Returns:
            Dict mapping stock_code -> file_path
        """
        files: dict[str, str] = {}

        if not self.data_dir.exists():
            logger.warning(f"Data directory does not exist: {self.data_dir}")
            return files

        csv_files = list(self.data_dir.glob("*.csv"))

        for file_path in csv_files:
            filename = file_path.name
            # Parse stock code from filename (format: sh_600000_...)
            parts = filename.split("_")
            if len(parts) >= 2:
                # Reconstruct stock code (sh.600000)
                exchange = parts[0]
                code = parts[1]
                stock_code = f"{exchange}.{code}"

                if stock_codes is None or stock_code in stock_codes:
                    # Prefer the most recent file for each stock
                    if stock_code not in files or file_path.stat().st_mtime > Path(files[stock_code]).stat().st_mtime:
                        files[stock_code] = str(file_path)

        return files

    def load_data(self, file_path: str) -> list[dict]:
        """Load data from CSV file."""
        if not os.path.exists(file_path):
            return []

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                return list(reader)
        except Exception as e:
            logger.error(f"Failed to load data from {file_path}: {e}")
            return []


def generate_report(results: list[ValidationResult], output_path: str | None = None) -> str:
    """Generate validation report."""
    report_lines = [
        "=" * 60,
        "STOCK DATA VALIDATION REPORT",
        f"Generated: {datetime.now().isoformat()}",
        "=" * 60,
        "",
    ]

    total_stocks = len(results)
    valid_stocks = sum(1 for r in results if r.is_valid)
    invalid_stocks = total_stocks - valid_stocks
    total_errors = sum(len(r.errors) for r in results)
    total_warnings = sum(len(r.warnings) for r in results)

    report_lines.extend([
        "SUMMARY",
        "-" * 40,
        f"  Total stocks:     {total_stocks}",
        f"  Valid stocks:     {valid_stocks} ({valid_stocks/total_stocks*100:.1f}%)",
        f"  Invalid stocks:   {invalid_stocks}",
        f"  Total errors:     {total_errors}",
        f"  Total warnings:   {total_warnings}",
        "",
    ])

    # List invalid stocks
    if invalid_stocks > 0:
        report_lines.append("INVALID STOCKS")
        report_lines.append("-" * 40)

        for result in results:
            if not result.is_valid:
                error_count = len(result.errors)
                warning_count = len(result.warnings)
                report_lines.append(f"  {result.stock_code}: {error_count} errors, {warning_count} warnings")

                # Show first few errors
                for error in result.errors[:3]:
                    report_lines.append(f"    - [{error.error_type}] {error.message}")
                if error_count > 3:
                    report_lines.append(f"    ... and {error_count - 3} more errors")

        report_lines.append("")

    # Detailed statistics for valid stocks
    if valid_stocks > 0:
        report_lines.append("VALID STOCKS STATISTICS")
        report_lines.append("-" * 40)

        for result in results:
            if result.is_valid:
                stats = result.statistics
                date_range = stats.get("date_range", {})
                report_lines.append(
                    f"  {result.stock_code}: {stats.get('total_rows', 0)} rows, "
                    f"{date_range.get('start', 'N/A')} to {date_range.get('end', 'N/A')}"
                )

        report_lines.append("")

    report_content = "\n".join(report_lines)

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report_content)
        logger.info(f"Report saved to {output_path}")

    return report_content


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Validate stock data quality",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python validate_data.py --all                   # Validate all stocks
  python validate_data.py -s sh.600000 sz.000001  # Validate specific stocks
  python validate_data.py --report                # Generate detailed report
  python validate_data.py --output report.txt     # Save report to file
        """,
    )

    parser.add_argument(
        "--stocks", "-s",
        nargs="+",
        default=None,
        help="Stock codes to validate",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Validate all stocks in data directory",
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="Generate detailed validation report",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output path for report",
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

    # Initialize components
    validator = DataValidator()
    file_manager = DataFileManager(args.data_dir)

    # Determine which stocks to validate
    if args.all:
        stock_files = file_manager.find_stock_files()
        print(f"Found {len(stock_files)} stock files in {args.data_dir}")
    elif args.stocks:
        stock_files = file_manager.find_stock_files(args.stocks)
        if len(stock_files) < len(args.stocks):
            missing = set(args.stocks) - set(stock_files.keys())
            logger.warning(f"Files not found for: {missing}")
    else:
        # Default to a few sample stocks
        stock_files = file_manager.find_stock_files(["sh.600000", "sz.000001"])

    if not stock_files:
        print("No stock files found to validate.")
        sys.exit(0)

    # Validate each stock
    results: list[ValidationResult] = []

    print(f"Validating {len(stock_files)} stocks...")

    for stock_code, file_path in sorted(stock_files.items()):
        if not args.quiet:
            print(f"  Validating {stock_code}...", end=" ")

        data = file_manager.load_data(file_path)

        if not data:
            result = ValidationResult(
                stock_code=stock_code,
                file_path=file_path,
                total_rows=0,
                is_valid=False,
                errors=[ValidationError(
                    error_type="file",
                    severity="error",
                    message="No data loaded from file",
                )],
                warnings=[],
                statistics={},
            )
        else:
            result = validator.validate_all(data, stock_code, file_path)

        results.append(result)

        if not args.quiet:
            status = "OK" if result.is_valid else "ISSUES"
            print(f"{status} ({result.total_rows} rows, {len(result.errors)} errors, {len(result.warnings)} warnings)")

    # Generate report
    if args.report or args.output:
        report = generate_report(results, args.output)
        if not args.output:
            print("\n" + report)

    # Summary
    valid_count = sum(1 for r in results if r.is_valid)
    invalid_count = len(results) - valid_count
    total_errors = sum(len(r.errors) for r in results)
    total_warnings = sum(len(r.warnings) for r in results)

    print("\n" + "=" * 50)
    print("VALIDATION SUMMARY")
    print("=" * 50)
    print(f"  Total stocks:     {len(results)}")
    print(f"  Valid:            {valid_count}")
    print(f"  Invalid:          {invalid_count}")
    print(f"  Total errors:     {total_errors}")
    print(f"  Total warnings:   {total_warnings}")
    print("=" * 50)

    # Exit with error code if any validation failed
    sys.exit(0 if invalid_count == 0 else 1)


if __name__ == "__main__":
    main()
