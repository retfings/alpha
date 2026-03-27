#!/usr/bin/env python3
"""
Enhanced Baostock Data Downloader

Features:
- Incremental updates (only download new data since last update)
- Data validation and quality checks
- Parallel download for better performance
- Automatic retry on failure
- Progress tracking and logging
- Support for both CSV and Parquet output formats
- Financial indicators download
- Industry classification data download

Usage:
    python script/enhanced_downloader.py --all
    python script/enhanced_downloader.py --stocks sh.600000 sz.000001
    python script/enhanced_downloader.py --incremental --all
    python script/enhanced_downloader.py --validate --all
    python script/enhanced_downloader.py --financials --all
    python script/enhanced_downloader.py --industries
"""

from __future__ import annotations

import argparse
import csv
import json
import logging
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Literal

import baostock as bs

logger = logging.getLogger(__name__)

# Type aliases
Frequency = Literal["d", "w", "m", "5", "15", "30", "60"]
AdjustFlag = Literal["1", "2", "3"]
OutputFormat = Literal["csv", "parquet"]

# Baostock fields for different frequencies
DAILY_FIELDS = "date,open,high,low,close,volume,amount,turn"
MINUTE_FIELDS = "date,time,open,high,low,close,volume,amount,turn"

# Financial indicator fields
FINANCIAL_FIELDS = "pubDate,statDate,roEAvg,roeWaa,roaAvg,netProfitOperatingIncomeRatio,grossProfitRatio,totalAssetTurnoverRatio,accountsReceivableTurnoverRatio,inventoryTurnoverRatio,operatingIncomeGrowthRate,netProfitGrowthRate,totalAssetGrowthRate,netAssetGrowthRate,debtToAssetRatio,currentRatio,quickRatio,cashFlowToOperatingIncomeRatio,netCashFlowFromOperatingActivitiesPerShare,dividendYield,payoutRatio,effectiveTaxRate,totalOperatingIncome,totalProfit,netProfitAttributableToParent,networkingCapital,netCashFromOperatingActivities,capex,epsBasic,dps,totalAsset,totalLiability,totalEquityAttributableToParent,retainedEarnings,cashAndEquivalents,accountsReceivable,inventory,nonCurrentAssetsDeferredTax,fixedAssets,constructionInProgress,intangibleAssets,goodwill,shortTermLoans,accountsPayable,employeePayable,longTermLoans,longTermPayables,capitalReserve,surplusReserve,undistributedProfit,operatingCost,sellingExpense,administrativeExpense,financialExpense,researchAndDevelopmentExpense,assetImpairmentLoss,creditImpairmentLoss,investmentIncome,netExposureChange,netFeeCommissionIncome,netTradingIncome,netExchangeGain,otherBusinessIncome,assetDisposalIncome,assetImpairmentLoss,creditImpairmentLoss,otherBusinessCost,interestExpense,interestIncome,minorityInterestIncome,minorityInterestDividend,withheldTax,otherComprehensiveIncome,comprehensiveIncomeTotal,ebit,ebitda,adjustedNetProfitAverage,equityMultiplier,roeDiluted,roaDiluted,incTax,surtax"

# Industry classification fields
INDUSTRY_FIELDS = "code,codeName,industryName,industryType,industryCode1,industryCode2,industryCode3"


@dataclass
class DownloadConfig:
    """Configuration for data download."""

    output_dir: str = "../data"
    frequency: Frequency = "d"
    adjustflag: AdjustFlag = "3"
    output_format: OutputFormat = "csv"
    max_workers: int = 4
    retry_attempts: int = 3
    retry_delay: float = 1.0
    show_progress: bool = True


@dataclass
class StockMetadata:
    """Metadata for a stock's downloaded data."""

    code: str
    last_update: str | None = None  # ISO format datetime
    last_date: str | None = None  # Last trading date in data
    record_count: int = 0
    file_path: str | None = None


@dataclass
class DownloadResult:
    """Result of a single stock download."""

    stock_code: str
    success: bool
    records_downloaded: int = 0
    message: str = ""
    error: str | None = None
    duration: float = 0.0
    incremental: bool = False
    data: list[dict] | None = None


@dataclass
class BatchDownloadReport:
    """Report for a batch download operation."""

    start_time: str
    end_time: str
    total_stocks: int
    successful: int = 0
    failed: int = 0
    total_records: int = 0
    incremental_updates: int = 0
    results: list[DownloadResult] = field(default_factory=list)
    errors: list[dict] = field(default_factory=list)

    def to_dict(self) -> dict:
        """Convert report to dictionary."""
        return {
            "start_time": self.start_time,
            "end_time": self.end_time,
            "total_stocks": self.total_stocks,
            "successful": self.successful,
            "failed": self.failed,
            "total_records": self.total_records,
            "incremental_updates": self.incremental_updates,
            "average_duration": sum(r.duration for r in self.results) / len(self.results) if self.results else 0,
        }


class DataValidator:
    """Validate downloaded stock data for quality and completeness."""

    @staticmethod
    def validate_price_range(data: list[dict], threshold: float = 1000.0) -> list[str]:
        """Check for invalid price values (negative or extreme)."""
        errors = []
        price_fields = ["open", "high", "low", "close"]

        for i, row in enumerate(data):
            for field in price_fields:
                if field in row:
                    try:
                        value = float(row[field])
                        if value < 0:
                            errors.append(f"Row {i}: Negative {field} value: {value}")
                        elif value > threshold:
                            errors.append(f"Row {i}: Extreme {field} value: {value} (>{threshold})")
                    except (ValueError, TypeError):
                        errors.append(f"Row {i}: Invalid {field} value: {row[field]}")

        return errors

    @staticmethod
    def validate_date_sequence(data: list[dict], expected_freq: str = "daily") -> list[str]:
        """Check for missing dates in the sequence."""
        errors = []

        if not data:
            return errors

        dates = []
        for row in data:
            if "date" in row:
                try:
                    dates.append(datetime.strptime(row["date"], "%Y-%m-%d"))
                except ValueError:
                    errors.append(f"Invalid date format: {row['date']}")

        if len(dates) < 2:
            return errors

        dates.sort()

        # Check for large gaps (more than 10 days for daily data)
        max_gap = timedelta(days=10) if expected_freq == "daily" else timedelta(days=40)

        for i in range(1, len(dates)):
            gap = dates[i] - dates[i - 1]
            if gap > max_gap:
                errors.append(
                    f"Large gap detected: {dates[i-1].date()} to {dates[i].date()} ({gap.days} days)"
                )

        return errors

    @staticmethod
    def validate_price_continuity(data: list[dict], max_jump: float = 0.5) -> list[str]:
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
                    if jump > max_jump:
                        errors.append(
                            f"Price jump detected at row {i}: "
                            f"{prev_close:.2f} -> {curr_open:.2f} ({jump*100:.1f}%)"
                        )
            except (ValueError, TypeError):
                pass

        return errors

    @classmethod
    def validate_all(cls, data: list[dict], stock_code: str) -> dict:
        """Run all validations and return summary."""
        price_errors = cls.validate_price_range(data)
        date_errors = cls.validate_date_sequence(data)
        continuity_errors = cls.validate_price_continuity(data)

        return {
            "stock_code": stock_code,
            "total_rows": len(data),
            "price_errors": len(price_errors),
            "date_errors": len(date_errors),
            "continuity_errors": len(continuity_errors),
            "total_errors": len(price_errors) + len(date_errors) + len(continuity_errors),
            "is_valid": len(price_errors) + len(date_errors) + len(continuity_errors) == 0,
            "errors": price_errors + date_errors + continuity_errors,
        }


class MetadataManager:
    """Manage metadata for downloaded stocks."""

    def __init__(self, metadata_dir: str) -> None:
        self.metadata_dir = Path(metadata_dir)
        self.metadata_dir.mkdir(parents=True, exist_ok=True)
        self._cache: dict[str, StockMetadata] = {}

    def _get_metadata_path(self, stock_code: str) -> Path:
        """Get path to metadata file for a stock."""
        safe_code = stock_code.replace(".", "_")
        return self.metadata_dir / f"{safe_code}.meta.json"

    def load(self, stock_code: str) -> StockMetadata | None:
        """Load metadata for a stock."""
        if stock_code in self._cache:
            return self._cache[stock_code]

        meta_path = self._get_metadata_path(stock_code)

        if not meta_path.exists():
            return None

        try:
            with open(meta_path, "r", encoding="utf-8") as f:
                data = json.load(f)
                metadata = StockMetadata(**data)
                self._cache[stock_code] = metadata
                return metadata
        except (json.JSONDecodeError, TypeError) as e:
            logger.warning(f"Failed to load metadata for {stock_code}: {e}")
            return None

    def save(self, metadata: StockMetadata) -> None:
        """Save metadata for a stock."""
        meta_path = self._get_metadata_path(metadata.code)
        self._cache[metadata.code] = metadata

        try:
            with open(meta_path, "w", encoding="utf-8") as f:
                json.dump(
                    {
                        "code": metadata.code,
                        "last_update": metadata.last_update,
                        "last_date": metadata.last_date,
                        "record_count": metadata.record_count,
                        "file_path": metadata.file_path,
                    },
                    f,
                    indent=2,
                )
        except IOError as e:
            logger.error(f"Failed to save metadata for {metadata.code}: {e}")

    def get_last_date(self, stock_code: str) -> str | None:
        """Get the last trading date for a stock."""
        metadata = self.load(stock_code)
        return metadata.last_date if metadata else None


class EnhancedBaostockDownloader:
    """Enhanced downloader with incremental updates and validation."""

    def __init__(self, config: DownloadConfig | None = None) -> None:
        self.config = config or DownloadConfig()
        self._logged_in = False
        self.metadata_manager = MetadataManager(
            os.path.join(self.config.output_dir, ".metadata")
        )
        self.validator = DataValidator()

    def login(self) -> bool:
        """Login to Baostock."""
        if self._logged_in:
            return True

        lg = bs.login()
        self._logged_in = lg.error_code == "0"

        if self._logged_in:
            logger.info("Baostock login successful")
        else:
            logger.error(f"Baostock login failed: {lg.error_msg}")

        return self._logged_in

    def logout(self) -> None:
        """Logout from Baostock."""
        if self._logged_in:
            bs.logout()
            self._logged_in = False
            logger.info("Baostock logout successful")

    def __enter__(self) -> EnhancedBaostockDownloader:
        self.login()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.logout()

    def get_all_stock_codes(self) -> list[str]:
        """Get all A-share stock codes."""
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

                    if (code.startswith("sh.") or code.startswith("sz.")) and stock_type == "1":
                        all_codes.append(code)

        logger.info(f"Found {len(all_codes)} A-share stocks")
        return all_codes

    def _generate_filename(
        self,
        stock_code: str,
        start_date: str,
        end_date: str,
        extension: str = ".csv",
    ) -> str:
        """Generate output filename."""
        stock_suffix = stock_code.replace(".", "_")
        adjust_suffix = "" if self.config.adjustflag == "2" else f"_qfq{self.config.adjustflag}"
        return f"{stock_suffix}_{start_date}_{end_date}{adjust_suffix}{extension}"

    def _load_existing_data(self, file_path: str) -> list[dict]:
        """Load existing data from CSV file."""
        if not os.path.exists(file_path):
            return []

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                return list(reader)
        except Exception as e:
            logger.warning(f"Failed to load existing data from {file_path}: {e}")
            return []

    def _save_to_csv(self, data: list[dict], file_path: str) -> bool:
        """Save data to CSV file."""
        if not data:
            return False

        try:
            os.makedirs(os.path.dirname(file_path) or ".", exist_ok=True)

            with open(file_path, "w", newline="", encoding="utf-8") as f:
                if data:
                    fieldnames = list(data[0].keys())
                    writer = csv.DictWriter(f, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(data)

            logger.debug(f"Data saved to {file_path}")
            return True

        except Exception as e:
            logger.error(f"Failed to save CSV: {e}")
            return False

    def download_incremental(
        self,
        stock_code: str,
        end_date: str | None = None,
    ) -> DownloadResult:
        """
        Download only new data since last update.

        Args:
            stock_code: Stock code
            end_date: End date (default: today)

        Returns:
            DownloadResult with download status
        """
        start_time = time.time()

        if not self._logged_in:
            if not self.login():
                return DownloadResult(
                    stock_code=stock_code,
                    success=False,
                    error="Not logged in",
                )

        # Get last downloaded date
        last_date = self.metadata_manager.get_last_date(stock_code)

        if not last_date:
            # No existing data, do full download
            return self.download_full(stock_code, end_date=end_date)

        # Calculate new start date (day after last date)
        try:
            last_date_obj = datetime.strptime(last_date, "%Y-%m-%d")
            new_start_date = (last_date_obj + timedelta(days=1)).strftime("%Y-%m-%d")
        except ValueError:
            new_start_date = last_date

        end_date = end_date or datetime.now().strftime("%Y-%m-%d")

        # Check if there's new data to download
        if new_start_date >= end_date:
            return DownloadResult(
                stock_code=stock_code,
                success=True,
                message="No new data available",
                incremental=True,
                duration=time.time() - start_time,
            )

        logger.info(f"Incremental update for {stock_code}: {new_start_date} to {end_date}")

        # Download new data
        result = self._download_range(
            stock_code=stock_code,
            start_date=new_start_date,
            end_date=end_date,
        )

        if not result.success:
            return result

        # Load existing data and merge
        metadata = self.metadata_manager.load(stock_code)
        if metadata and metadata.file_path:
            existing_data = self._load_existing_data(metadata.file_path)

            if existing_data and result.data:
                merged_data = existing_data + result.data

                # Save merged data
                if self._save_to_csv(merged_data, metadata.file_path):
                    # Update metadata
                    metadata.last_update = datetime.now().isoformat()
                    metadata.last_date = end_date
                    metadata.record_count = len(merged_data)
                    self.metadata_manager.save(metadata)

                    return DownloadResult(
                        stock_code=stock_code,
                        success=True,
                        records_downloaded=len(result.data),
                        message=f"Incremental update: {len(result.data)} new records",
                        incremental=True,
                        duration=time.time() - start_time,
                    )

        # Save new data to separate file
        filename = self._generate_filename(stock_code, new_start_date, end_date)
        file_path = os.path.join(self.config.output_dir, filename)

        if self._save_to_csv(result.data, file_path):
            # Update metadata
            self.metadata_manager.save(
                StockMetadata(
                    code=stock_code,
                    last_update=datetime.now().isoformat(),
                    last_date=end_date,
                    record_count=len(result.data),
                    file_path=file_path,
                )
            )

            return DownloadResult(
                stock_code=stock_code,
                success=True,
                records_downloaded=len(result.data),
                message=f"Incremental update saved to {filename}",
                incremental=True,
                duration=time.time() - start_time,
            )

        return DownloadResult(
            stock_code=stock_code,
            success=False,
            error="Failed to save data",
            duration=time.time() - start_time,
        )

    def download_full(
        self,
        stock_code: str,
        start_date: str | None = None,
        end_date: str | None = None,
    ) -> DownloadResult:
        """
        Download full data range for a stock.

        Args:
            stock_code: Stock code
            start_date: Start date (default: 3 years ago)
            end_date: End date (default: today)

        Returns:
            DownloadResult with download status
        """
        start_time = time.time()

        if start_date is None or end_date is None:
            start_date, end_date = self._get_default_date_range(3)

        logger.info(f"Full download for {stock_code}: {start_date} to {end_date}")

        result = self._download_range(
            stock_code=stock_code,
            start_date=start_date,
            end_date=end_date,
        )

        if not result.success or not result.data:
            result.duration = time.time() - start_time
            return result

        # Save to CSV
        filename = self._generate_filename(stock_code, start_date, end_date)
        file_path = os.path.join(self.config.output_dir, filename)

        if self._save_to_csv(result.data, file_path):
            # Validate data
            validation = self.validator.validate_all(result.data, stock_code)

            # Update metadata
            self.metadata_manager.save(
                StockMetadata(
                    code=stock_code,
                    last_update=datetime.now().isoformat(),
                    last_date=end_date,
                    record_count=len(result.data),
                    file_path=file_path,
                )
            )

            message = f"Downloaded {len(result.data)} records"
            if not validation["is_valid"]:
                message += f" (warning: {validation['total_errors']} validation issues)"

            result.records_downloaded = len(result.data)
            result.message = message
            result.duration = time.time() - start_time

            logger.info(f"Download completed for {stock_code}: {message}")
        else:
            result.success = False
            result.error = "Failed to save CSV"
            result.duration = time.time() - start_time

        return result

    def _download_range(
        self,
        stock_code: str,
        start_date: str,
        end_date: str,
        attempt: int = 1,
    ) -> DownloadResult:
        """Download data for a specific date range with retry logic."""
        if not self._logged_in:
            if not self.login():
                return DownloadResult(
                    stock_code=stock_code,
                    success=False,
                    error="Not logged in",
                )

        # Select fields based on frequency
        fields = MINUTE_FIELDS if self.config.frequency in ("5", "15", "30", "60") else DAILY_FIELDS

        try:
            rs = bs.query_history_k_data_plus(
                code=stock_code,
                fields=fields,
                start_date=start_date,
                end_date=end_date,
                frequency=self.config.frequency,
                adjustflag=self.config.adjustflag,
            )

            if rs.error_code != "0":
                return DownloadResult(
                    stock_code=stock_code,
                    success=False,
                    error=f"Query failed: {rs.error_msg}",
                )

            data: list[dict] = []
            while rs.next():
                row_data = rs.get_row_data()
                if rs.fields and row_data:
                    row_dict = dict(zip(rs.fields, row_data))
                    data.append(row_dict)

            if not data:
                return DownloadResult(
                    stock_code=stock_code,
                    success=True,
                    message="No data available for this range",
                )

            return DownloadResult(
                stock_code=stock_code,
                success=True,
                data=data,
                records_downloaded=len(data),
            )

        except Exception as e:
            logger.error(f"Download error for {stock_code}: {e}")

            # Retry logic
            if attempt < self.config.retry_attempts:
                logger.info(f"Retrying download for {stock_code} (attempt {attempt + 1}/{self.config.retry_attempts})")
                time.sleep(self.config.retry_delay * attempt)
                return self._download_range(stock_code, start_date, end_date, attempt + 1)

            return DownloadResult(
                stock_code=stock_code,
                success=False,
                error=f"Download failed after {attempt} attempts: {str(e)}",
            )

    def _get_default_date_range(self, years: int = 3) -> tuple[str, str]:
        """Get default date range."""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=years * 365)
        return start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")

    def validate_stock(self, stock_code: str) -> dict:
        """Validate existing data for a stock."""
        metadata = self.metadata_manager.load(stock_code)

        if not metadata or not metadata.file_path:
            return {
                "stock_code": stock_code,
                "error": "No data found for this stock",
            }

        data = self._load_existing_data(metadata.file_path)

        if not data:
            return {
                "stock_code": stock_code,
                "error": "No data loaded",
            }

        return self.validator.validate_all(data, stock_code)

    def download_financial_indicators(
        self,
        stock_code: str,
        start_date: str | None = None,
        end_date: str | None = None,
    ) -> DownloadResult:
        """
        Download financial indicators for a stock.

        Args:
            stock_code: Stock code (e.g., 'sh.600000')
            start_date: Start date (YYYY-MM-DD), default: 10 years ago
            end_date: End date (YYYY-MM-DD), default: today

        Returns:
            DownloadResult with download status
        """
        start_time = time.time()

        if not self._logged_in:
            if not self.login():
                return DownloadResult(
                    stock_code=stock_code,
                    success=False,
                    error="Not logged in",
                )

        # Default to 10 years of financial data
        if start_date is None:
            start_date = (datetime.now() - timedelta(days=10 * 365)).strftime("%Y-%m-%d")
        if end_date is None:
            end_date = datetime.now().strftime("%Y-%m-%d")

        logger.info(f"Downloading financial indicators for {stock_code}: {start_date} to {end_date}")

        try:
            rs = bs.query_profit_data(
                code=stock_code,
                start_year=start_date.replace("-", ""),
                end_year=end_date.replace("-", ""),
            )

            if rs.error_code != "0":
                return DownloadResult(
                    stock_code=stock_code,
                    success=False,
                    error=f"Query failed: {rs.error_msg}",
                )

            data: list[dict] = []
            while rs.next():
                row_data = rs.get_row_data()
                if rs.fields and row_data:
                    row_dict = dict(zip(rs.fields, row_data))
                    data.append(row_dict)

            if not data:
                return DownloadResult(
                    stock_code=stock_code,
                    success=True,
                    message="No financial data available for this stock",
                )

            # Save to CSV
            stock_suffix = stock_code.replace(".", "_")
            filename = f"{stock_suffix}_financials_{start_date}_{end_date}.csv"
            file_path = os.path.join(self.config.output_dir, "financials", filename)

            if self._save_to_csv(data, file_path):
                return DownloadResult(
                    stock_code=stock_code,
                    success=True,
                    records_downloaded=len(data),
                    message=f"Downloaded {len(data)} financial records",
                    duration=time.time() - start_time,
                )
            else:
                return DownloadResult(
                    stock_code=stock_code,
                    success=False,
                    error="Failed to save financial data",
                    duration=time.time() - start_time,
                )

        except Exception as e:
            logger.error(f"Failed to download financial indicators for {stock_code}: {e}")
            return DownloadResult(
                stock_code=stock_code,
                success=False,
                error=f"Download failed: {str(e)}",
                duration=time.time() - start_time,
            )

    def download_industry_classification(self) -> BatchDownloadReport:
        """
        Download industry classification data for all stocks.

        Returns:
            BatchDownloadReport with summary
        """
        start_time = datetime.now().isoformat()

        report = BatchDownloadReport(
            start_time=start_time,
            end_time="",
            total_stocks=0,
        )

        if not self._logged_in:
            if not self.login():
                report.end_time = datetime.now().isoformat()
                report.errors.append({"error": "Failed to login to Baostock"})
                return report

        logger.info("Downloading industry classification data...")

        try:
            # Query industry classification
            rs = bs.query_industry_data()

            if rs.error_code != "0":
                report.errors.append({"error": f"Industry query failed: {rs.error_msg}"})
                report.end_time = datetime.now().isoformat()
                return report

            data: list[dict] = []
            stock_codes_seen: set[str] = set()

            while rs.next():
                row_data = rs.get_row_data()
                if rs.fields and row_data:
                    row_dict = dict(zip(rs.fields, row_data))
                    data.append(row_dict)
                    if row_data and row_data[0]:
                        stock_codes_seen.add(row_data[0])

            if not data:
                report.errors.append({"error": "No industry classification data available"})
                report.end_time = datetime.now().isoformat()
                return report

            # Save to CSV
            filename = f"industry_classification_{datetime.now().strftime('%Y%m%d')}.csv"
            file_path = os.path.join(self.config.output_dir, "industries", filename)

            if self._save_to_csv(data, file_path):
                report.total_stocks = len(stock_codes_seen)
                report.successful = len(stock_codes_seen)
                report.total_records = len(data)
                report.results.append(
                    DownloadResult(
                        stock_code="ALL",
                        success=True,
                        records_downloaded=len(data),
                        message=f"Saved to {filename}",
                    )
                )
                logger.info(f"Industry classification saved to {file_path}")
            else:
                report.errors.append({"error": "Failed to save industry data"})

        except Exception as e:
            logger.error(f"Failed to download industry classification: {e}")
            report.errors.append({"error": str(e)})

        report.end_time = datetime.now().isoformat()
        return report

    def download_all_financials(
        self,
        stock_codes: list[str],
    ) -> BatchDownloadReport:
        """
        Download financial indicators for multiple stocks.

        Args:
            stock_codes: List of stock codes

        Returns:
            BatchDownloadReport with summary
        """
        start_time = datetime.now().isoformat()

        report = BatchDownloadReport(
            start_time=start_time,
            end_time="",
            total_stocks=len(stock_codes),
        )

        if not self._logged_in:
            if not self.login():
                report.end_time = datetime.now().isoformat()
                report.errors.append({"error": "Failed to login to Baostock"})
                return report

        # Ensure output directory exists
        os.makedirs(os.path.join(self.config.output_dir, "financials"), exist_ok=True)

        logger.info(f"Downloading financial indicators for {len(stock_codes)} stocks")

        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            futures = {}

            for stock_code in stock_codes:
                future = executor.submit(self.download_financial_indicators, stock_code)
                futures[future] = stock_code

            for future in as_completed(futures):
                stock_code = futures[future]
                try:
                    result = future.result()
                    report.results.append(result)

                    if result.success:
                        report.successful += 1
                        report.total_records += result.records_downloaded

                        if self.config.show_progress:
                            print(f"  [OK] {stock_code}: {result.message}")
                    else:
                        report.failed += 1
                        report.errors.append({
                            "stock_code": stock_code,
                            "error": result.error,
                        })

                        if self.config.show_progress:
                            print(f"  [FAIL] {stock_code}: {result.error}")

                except Exception as e:
                    report.failed += 1
                    report.errors.append({
                        "stock_code": stock_code,
                        "error": str(e),
                    })

                    if self.config.show_progress:
                        print(f"  [ERROR] {stock_code}: {e}")

        report.end_time = datetime.now().isoformat()
        return report

    def batch_download(
        self,
        stock_codes: list[str],
        incremental: bool = False,
        start_date: str | None = None,
        end_date: str | None = None,
    ) -> BatchDownloadReport:
        """
        Download data for multiple stocks in parallel.

        Args:
            stock_codes: List of stock codes
            incremental: Use incremental update mode
            start_date: Start date for full download
            end_date: End date for full download

        Returns:
            BatchDownloadReport with summary
        """
        start_time = datetime.now().isoformat()

        report = BatchDownloadReport(
            start_time=start_time,
            end_time="",
            total_stocks=len(stock_codes),
        )

        if not self._logged_in:
            if not self.login():
                report.end_time = datetime.now().isoformat()
                report.errors.append({"error": "Failed to login to Baostock"})
                return report

        # Ensure output directory exists
        os.makedirs(self.config.output_dir, exist_ok=True)

        logger.info(f"Starting batch download for {len(stock_codes)} stocks (incremental={incremental})")

        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            futures = {}

            for stock_code in stock_codes:
                if incremental:
                    future = executor.submit(
                        self.download_incremental,
                        stock_code,
                        end_date,
                    )
                else:
                    future = executor.submit(
                        self.download_full,
                        stock_code,
                        start_date,
                        end_date,
                    )
                futures[future] = stock_code

            for future in as_completed(futures):
                stock_code = futures[future]
                try:
                    result = future.result()
                    report.results.append(result)

                    if result.success:
                        report.successful += 1
                        report.total_records += result.records_downloaded
                        if result.incremental:
                            report.incremental_updates += 1

                        if self.config.show_progress:
                            print(f"  [OK] {stock_code}: {result.message}")
                    else:
                        report.failed += 1
                        report.errors.append({
                            "stock_code": stock_code,
                            "error": result.error,
                        })

                        if self.config.show_progress:
                            print(f"  [FAIL] {stock_code}: {result.error}")

                except Exception as e:
                    report.failed += 1
                    report.errors.append({
                        "stock_code": stock_code,
                        "error": str(e),
                    })

                    if self.config.show_progress:
                        print(f"  [ERROR] {stock_code}: {e}")

        report.end_time = datetime.now().isoformat()

        return report


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Enhanced Baostock Data Downloader",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python enhanced_downloader.py --all                     # Download all A-shares
  python enhanced_downloader.py --all --incremental       # Incremental update for all
  python enhanced_downloader.py -s sh.600000 sz.000001    # Download specific stocks
  python enhanced_downloader.py --validate --all          # Validate all existing data
  python enhanced_downloader.py --all -f 5 -q             # Download 5-min data quietly
  python enhanced_downloader.py --financials --all        # Download financial indicators
  python enhanced_downloader.py --industries              # Download industry classification
        """,
    )

    parser.add_argument(
        "--stocks", "-s",
        nargs="+",
        default=None,
        help="Stock codes (e.g., sh.600000 sz.000001)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Download all A-share stocks",
    )
    parser.add_argument(
        "--incremental", "-i",
        action="store_true",
        help="Use incremental update mode",
    )
    parser.add_argument(
        "--validate", "-v",
        action="store_true",
        help="Validate existing data instead of downloading",
    )
    parser.add_argument(
        "--financials",
        action="store_true",
        help="Download financial indicators for stocks",
    )
    parser.add_argument(
        "--industries",
        action="store_true",
        help="Download industry classification data",
    )
    parser.add_argument(
        "--start",
        type=str,
        default=None,
        help="Start date (YYYY-MM-DD)",
    )
    parser.add_argument(
        "--end",
        type=str,
        default=None,
        help="End date (YYYY-MM-DD)",
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        default=os.path.join(os.path.dirname(__file__), "..", "data"),
        help="Output directory",
    )
    parser.add_argument(
        "--frequency", "-f",
        type=str,
        choices=["d", "w", "m", "5", "15", "30", "60"],
        default="d",
        help="Data frequency",
    )
    parser.add_argument(
        "--adjustflag", "-a",
        type=str,
        choices=["1", "2", "3"],
        default="3",
        help="Adjustment type: 1=后复权，2=无复权，3=前复权",
    )
    parser.add_argument(
        "--workers", "-w",
        type=int,
        default=4,
        help="Number of parallel download workers",
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

    # Create config
    config = DownloadConfig(
        output_dir=args.output,
        frequency=args.frequency,
        adjustflag=args.adjustflag,
        max_workers=args.workers,
        show_progress=not args.quiet,
    )

    # Handle industry classification download
    if args.industries:
        print("Downloading industry classification data...")
        with EnhancedBaostockDownloader(config) as downloader:
            report = downloader.download_industry_classification()

            print("\n" + "=" * 50)
            print("INDUSTRY CLASSIFICATION DOWNLOAD")
            print("=" * 50)
            print(f"  Total stocks:      {report.total_stocks}")
            print(f"  Records:           {report.total_records}")

            if report.errors:
                print(f"\n  Errors: {report.errors[0].get('error', 'Unknown')}")
            else:
                print("  Status: SUCCESS")

            print("=" * 50)
        return

    # Determine stock list
    stock_list: list[str] = []

    if args.all:
        print("Fetching all A-share stock codes...")
        with EnhancedBaostockDownloader(config) as downloader:
            stock_list = downloader.get_all_stock_codes()
            print(f"Found {len(stock_list)} stocks.")

            if args.validate:
                # Validate all stocks
                print("Validating existing data...")
                valid_count = 0
                invalid_count = 0

                for stock_code in stock_list:
                    result = downloader.validate_stock(stock_code)
                    if result.get("is_valid", False):
                        valid_count += 1
                    else:
                        invalid_count += 1
                        if not args.quiet:
                            print(f"  [INVALID] {stock_code}: {result.get('error', result.get('total_errors', 0))} issues")

                print(f"\nValidation complete: {valid_count} valid, {invalid_count} invalid")
                return

            # Handle financial indicators download
            if args.financials:
                print(f"Downloading financial indicators for {len(stock_list)} stocks...")
                report = downloader.download_all_financials(stock_list)

                print("\n" + "=" * 50)
                print("FINANCIAL INDICATORS DOWNLOAD SUMMARY")
                print("=" * 50)
                print(f"  Total stocks:      {report.total_stocks}")
                print(f"  Successful:        {report.successful}")
                print(f"  Failed:            {report.failed}")
                print(f"  Total records:     {report.total_records}")

                if report.errors:
                    print(f"\n  Errors ({len(report.errors)}):")
                    for err in report.errors[:10]:
                        print(f"    - {err.get('stock_code', 'unknown')}: {err.get('error', 'unknown error')}")

                print("=" * 50)
                return
    elif args.stocks:
        stock_list = args.stocks
    else:
        stock_list = ["sh.600000", "sz.000001"]

    if not stock_list:
        print("No stocks to process.")
        sys.exit(1)

    # Handle financial indicators download for specific stocks
    if args.financials:
        print(f"Downloading financial indicators for {len(stock_list)} stocks...")
        with EnhancedBaostockDownloader(config) as downloader:
            report = downloader.download_all_financials(stock_list)

            print("\n" + "=" * 50)
            print("FINANCIAL INDICATORS DOWNLOAD SUMMARY")
            print("=" * 50)
            print(f"  Total stocks:      {report.total_stocks}")
            print(f"  Successful:        {report.successful}")
            print(f"  Failed:            {report.failed}")
            print(f"  Total records:     {report.total_records}")

            if report.errors:
                print(f"\n  Errors ({len(report.errors)}):")
                for err in report.errors[:10]:
                    print(f"    - {err.get('stock_code', 'unknown')}: {err.get('error', 'unknown error')}")

            print("=" * 50)
        return

    # Run batch download
    print(f"Processing {len(stock_list)} stocks...")

    with EnhancedBaostockDownloader(config) as downloader:
        report = downloader.batch_download(
            stock_codes=stock_list,
            incremental=args.incremental,
            start_date=args.start,
            end_date=args.end,
        )

        # Print summary
        print("\n" + "=" * 50)
        print("DOWNLOAD SUMMARY")
        print("=" * 50)
        print(f"  Total stocks:      {report.total_stocks}")
        print(f"  Successful:        {report.successful}")
        print(f"  Failed:            {report.failed}")
        print(f"  Total records:     {report.total_records}")
        print(f"  Incremental:       {report.incremental_updates}")
        print(f"  Duration:          {datetime.fromisoformat(report.end_time) - datetime.fromisoformat(report.start_time)}")

        if report.errors:
            print(f"\n  Errors ({len(report.errors)}):")
            for err in report.errors[:10]:  # Show first 10 errors
                print(f"    - {err.get('stock_code', 'unknown')}: {err.get('error', 'unknown error')}")
            if len(report.errors) > 10:
                print(f"    ... and {len(report.errors) - 10} more")

        print("=" * 50)


if __name__ == "__main__":
    main()
