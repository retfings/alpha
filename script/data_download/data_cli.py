#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
股票数据下载 CLI 工具

提供命令行接口来下载和保存股票数据到 CSV 文件。
支持下载 K 线数据、财务数据、行业分类、分红数据等。

用法:
    python data_cli.py download-kline --code sh.600000 --start 2023-01-01 --end 2023-12-31
    python data_cli.py download-financials --code sh.600000
    python data_cli.py download-all --code sh.600000
    python data_cli.py list-stocks --industry 银行
"""

import argparse
import sys
import os
from datetime import datetime
from typing import Optional
import pandas as pd

# 导入 BaoStockAPI
from download_data import BaoStockAPI


def format_code_for_filename(code: str) -> str:
    """将股票代码转换为文件名格式"""
    return code.replace('.', '_')


def ensure_output_dir(output_dir: str) -> str:
    """确保输出目录存在"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"创建输出目录：{output_dir}")
    return output_dir


def save_to_csv(df: pd.DataFrame, filepath: str) -> bool:
    """保存 DataFrame 到 CSV 文件"""
    try:
        df.to_csv(filepath, index=False, encoding='utf-8-sig')
        print(f"数据已保存到：{filepath}")
        print(f"共 {len(df)} 行数据")
        return True
    except Exception as e:
        print(f"保存文件失败：{e}")
        return False


def cmd_download_kline(args):
    """下载 K 线数据"""
    api = BaoStockAPI()
    api.init()

    try:
        print(f"正在下载 {args.code} 的 K 线数据...")
        print(f"时间范围：{args.start or '开始'} 至 {args.end or '结束'}")
        print(f"频率：{args.frequency}")
        print(f"复权类型：{args.adjust}")

        df = api.get_history_k_data(
            code=args.code,
            start_date=args.start,
            end_date=args.end,
            frequency=args.frequency,
            adjustflag=args.adjust
        )

        if df.empty:
            print("未获取到数据")
            return 1

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        code_fmt = format_code_for_filename(args.code)
        freq_map = {'d': 'daily', 'w': 'weekly', 'm': 'monthly',
                    '5': '5min', '15': '15min', '30': '30min', '60': '60min'}
        freq_name = freq_map.get(args.frequency, args.frequency)
        adjust_map = {'1': 'adj', '2': 'pre-adj', '3': 'no-adj'}
        adjust_name = adjust_map.get(args.adjust, args.adjust)

        filename = f"{code_fmt}_kline_{freq_name}_{adjust_name}_{args.start or 'all'}_{args.end or 'now'}.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)
        return 0
    finally:
        api.logout()


def cmd_download_financials(args):
    """下载财务数据"""
    api = BaoStockAPI()
    api.init()

    try:
        code = args.code
        year = args.year
        quarter = args.quarter

        print(f"正在下载 {code} 的财务数据...")

        if year and quarter:
            # 下载指定季度的数据
            quarters = [(year, quarter)]
        elif year:
            # 下载指定年份所有季度
            quarters = [(year, 1), (year, 2), (year, 3), (year, 4)]
        else:
            # 下载最近 5 年的数据
            current_year = datetime.now().year
            quarters = []
            for y in range(current_year - 4, current_year + 1):
                for q in range(1, 5):
                    quarters.append((y, q))

        all_data = []
        for y, q in quarters:
            try:
                print(f"  获取 {y} 年第 {q} 季度数据...")

                # 盈利能力
                profit_df = api.get_profit_data(code, y, q)
                if not profit_df.empty:
                    profit_df['data_type'] = 'profit'
                    all_data.append(profit_df)

                # 营运能力
                operation_df = api.get_operation_data(code, y, q)
                if not operation_df.empty:
                    operation_df['data_type'] = 'operation'
                    all_data.append(operation_df)

                # 成长能力
                growth_df = api.get_growth_data(code, y, q)
                if not growth_df.empty:
                    growth_df['data_type'] = 'growth'
                    all_data.append(growth_df)

            except Exception as e:
                print(f"    跳过 {y} 年第 {q} 季度：{e}")

        if not all_data:
            print("未获取到财务数据")
            return 1

        # 合并所有数据
        df = pd.concat(all_data, ignore_index=True)

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        code_fmt = format_code_for_filename(code)
        filename = f"{code_fmt}_financials.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)
        return 0
    finally:
        api.logout()


def cmd_download_dividend(args):
    """下载分红数据"""
    api = BaoStockAPI()
    api.init()

    try:
        code = args.code
        year = args.year or ""
        year_type = args.type

        print(f"正在下载 {code} 的分红数据...")

        df = api.get_dividend_data(code, year=year, yearType=year_type)

        if df.empty:
            print("未获取到分红数据")
            return 1

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        code_fmt = format_code_for_filename(code)
        filename = f"{code_fmt}_dividend_{year or 'all'}_{year_type}.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)
        return 0
    finally:
        api.logout()


def cmd_download_industry(args):
    """下载行业分类数据"""
    api = BaoStockAPI()
    api.init()

    try:
        code = args.code or ""

        if code:
            print(f"正在下载 {code} 的行业分类数据...")
        else:
            print("正在下载所有股票的行业分类数据...")

        df = api.get_industry_classified(code)

        if df.empty:
            print("未获取到行业分类数据")
            return 1

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        filename = "industry_classification.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)
        return 0
    finally:
        api.logout()


def cmd_download_index(args):
    """下载指数数据"""
    api = BaoStockAPI()
    api.init()

    try:
        print(f"正在下载指数 {args.code} 的 K 线数据...")
        print(f"时间范围：{args.start or '开始'} 至 {args.end or '结束'}")
        print(f"频率：{args.frequency}")

        df = api.get_index_data(
            code=args.code,
            start_date=args.start,
            end_date=args.end,
            frequency=args.frequency
        )

        if df.empty:
            print("未获取到指数数据")
            return 1

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        code_fmt = format_code_for_filename(args.code)
        freq_map = {'d': 'daily', 'w': 'weekly', 'm': 'monthly'}
        freq_name = freq_map.get(args.frequency, args.frequency)

        filename = f"{code_fmt}_index_{freq_name}_{args.start or 'all'}_{args.end or 'now'}.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)
        return 0
    finally:
        api.logout()


def cmd_download_valuation(args):
    """下载估值数据"""
    api = BaoStockAPI()
    api.init()

    try:
        print(f"正在下载 {args.code} 的估值数据...")
        print(f"时间范围：{args.start or '开始'} 至 {args.end or '结束'}")

        df = api.get_valuation_data(
            code=args.code,
            start_date=args.start,
            end_date=args.end,
            frequency=args.frequency
        )

        if df.empty:
            print("未获取到估值数据")
            return 1

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        code_fmt = format_code_for_filename(args.code)
        freq_map = {'d': 'daily', 'w': 'weekly', 'm': 'monthly'}
        freq_name = freq_map.get(args.frequency, args.frequency)

        filename = f"{code_fmt}_valuation_{freq_name}_{args.start or 'all'}_{args.end or 'now'}.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)
        return 0
    finally:
        api.logout()


def cmd_download_all(args):
    """下载所有数据"""
    api = BaoStockAPI()
    api.init()

    try:
        code = args.code
        print(f"正在下载 {code} 的所有数据...")

        output_dir = ensure_output_dir(args.output_dir)
        code_fmt = format_code_for_filename(code)

        # 1. 下载 K 线数据（最近一年）
        print("\n[1/5] 下载 K 线数据...")
        end_date = datetime.now().strftime('%Y-%m-%d')
        start_date = f"{int(end_date[:4]) - 1}{end_date[4:]}"
        kline_df = api.get_history_k_data(code, start_date=start_date, end_date=end_date)
        if not kline_df.empty:
            save_to_csv(kline_df, os.path.join(output_dir, f"{code_fmt}_kline_daily.csv"))

        # 2. 下载财务数据（最近 4 个季度）
        print("\n[2/5] 下载财务数据...")
        current_year = datetime.now().year
        all_financials = []
        for q in range(1, 5):
            try:
                profit = api.get_profit_data(code, current_year - 1, q)
                operation = api.get_operation_data(code, current_year - 1, q)
                growth = api.get_growth_data(code, current_year - 1, q)
                if not profit.empty:
                    all_financials.append(profit)
                if not operation.empty:
                    all_financials.append(operation)
                if not growth.empty:
                    all_financials.append(growth)
            except:
                pass
        if all_financials:
            fin_df = pd.concat(all_financials, ignore_index=True)
            save_to_csv(fin_df, os.path.join(output_dir, f"{code_fmt}_financials.csv"))

        # 3. 下载分红数据
        print("\n[3/5] 下载分红数据...")
        div_df = api.get_dividend_data(code)
        if not div_df.empty:
            save_to_csv(div_df, os.path.join(output_dir, f"{code_fmt}_dividend.csv"))

        # 4. 下载行业分类数据
        print("\n[4/5] 下载行业分类数据...")
        ind_df = api.get_industry_classified(code)
        if not ind_df.empty:
            save_to_csv(ind_df, os.path.join(output_dir, f"{code_fmt}_industry.csv"))

        # 5. 下载估值数据（最近一年）
        print("\n[5/5] 下载估值数据...")
        val_df = api.get_valuation_data(code, start_date=start_date, end_date=end_date)
        if not val_df.empty:
            save_to_csv(val_df, os.path.join(output_dir, f"{code_fmt}_valuation_daily.csv"))

        print(f"\n所有数据已保存到：{output_dir}")
        return 0
    finally:
        api.logout()


def cmd_list_stocks(args):
    """列出股票列表"""
    api = BaoStockAPI()
    api.init()

    try:
        print("正在获取股票列表...")

        df = api.get_industry_classified("")

        if df.empty:
            print("未获取到股票列表")
            return 1

        # 如果指定了行业，进行筛选
        if args.industry:
            df = df[df['industry'].str.contains(args.industry, na=False)]
            print(f"找到包含'{args.industry}'的行业股票共 {len(df)} 只")
        else:
            print(f"共获取到 {len(df)} 只股票")

        # 保存文件
        output_dir = ensure_output_dir(args.output_dir)
        filename = "stock_list.csv"
        filepath = os.path.join(output_dir, filename)

        save_to_csv(df, filepath)

        # 显示前几条
        print("\n前 10 条记录:")
        print(df.head(10).to_string(index=False))

        return 0
    finally:
        api.logout()


def main():
    parser = argparse.ArgumentParser(
        description='股票数据下载 CLI 工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 下载 K 线数据
  %(prog)s download-kline --code sh.600000 --start 2023-01-01 --end 2023-12-31
  %(prog)s download-kline --code sz.000001 --frequency w --adjust 1

  # 下载财务数据
  %(prog)s download-financials --code sh.600000
  %(prog)s download-financials --code sh.600000 --year 2023 --quarter 4

  # 下载分红数据
  %(prog)s download-dividend --code sh.600000
  %(prog)s download-dividend --code sh.600000 --year 2023

  # 下载指数数据
  %(prog)s download-index --code sh.000001 --start 2023-01-01

  # 下载估值数据
  %(prog)s download-valuation --code sh.600000 --start 2023-01-01

  # 下载所有数据
  %(prog)s download-all --code sh.600000

  # 列出股票列表
  %(prog)s list-stocks
  %(prog)s list-stocks --industry 银行
        """
    )

    parser.add_argument('-o', '--output-dir', default='./data',
                       help='输出目录 (默认：./data)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='显示详细输出')

    subparsers = parser.add_subparsers(dest='command', help='可用命令')

    # download-kline 命令
    kline_parser = subparsers.add_parser('download-kline', help='下载 K 线数据')
    kline_parser.add_argument('--code', required=True, help='股票代码，如 sh.600000')
    kline_parser.add_argument('--start', help='开始日期 (YYYY-MM-DD)')
    kline_parser.add_argument('--end', help='结束日期 (YYYY-MM-DD)')
    kline_parser.add_argument('--frequency', '-f', choices=['d', 'w', 'm', '5', '15', '30', '60'],
                             default='d', help='频率：d=日线，w=周线，m=月线，5/15/30/60=分钟线')
    kline_parser.add_argument('--adjust', '-a', choices=['1', '2', '3'], default='3',
                             help='复权类型：1=后复权，2=前复权，3=不复权 (默认)')
    kline_parser.set_defaults(func=cmd_download_kline)

    # download-financials 命令
    fin_parser = subparsers.add_parser('download-financials', help='下载财务数据')
    fin_parser.add_argument('--code', required=True, help='股票代码，如 sh.600000')
    fin_parser.add_argument('--year', type=int, help='年份，如 2023')
    fin_parser.add_argument('--quarter', type=int, choices=[1, 2, 3, 4],
                           help='季度：1=Q1, 2=H1, 3=Q3, 4=Annual')
    fin_parser.set_defaults(func=cmd_download_financials)

    # download-dividend 命令
    div_parser = subparsers.add_parser('download-dividend', help='下载分红数据')
    div_parser.add_argument('--code', required=True, help='股票代码，如 sh.600000')
    div_parser.add_argument('--year', help='年份，如 2023')
    div_parser.add_argument('--type', choices=['report', 'operate', 'dividend'],
                           default='report', help='年份类型：report=预案公告，operate=除权除息，dividend=分红')
    div_parser.set_defaults(func=cmd_download_dividend)

    # download-industry 命令
    ind_parser = subparsers.add_parser('download-industry', help='下载行业分类数据')
    ind_parser.add_argument('--code', help='股票代码，不指定则获取全部')
    ind_parser.set_defaults(func=cmd_download_industry)

    # download-index 命令
    idx_parser = subparsers.add_parser('download-index', help='下载指数数据')
    idx_parser.add_argument('--code', required=True, help='指数代码，如 sh.000001')
    idx_parser.add_argument('--start', help='开始日期 (YYYY-MM-DD)')
    idx_parser.add_argument('--end', help='结束日期 (YYYY-MM-DD)')
    idx_parser.add_argument('--frequency', '-f', choices=['d', 'w', 'm'],
                           default='d', help='频率：d=日线，w=周线，m=月线')
    idx_parser.set_defaults(func=cmd_download_index)

    # download-valuation 命令
    val_parser = subparsers.add_parser('download-valuation', help='下载估值数据')
    val_parser.add_argument('--code', required=True, help='股票代码，如 sh.600000')
    val_parser.add_argument('--start', help='开始日期 (YYYY-MM-DD)')
    val_parser.add_argument('--end', help='结束日期 (YYYY-MM-DD)')
    val_parser.add_argument('--frequency', '-f', choices=['d', 'w', 'm'],
                           default='d', help='频率：d=日线，w=周线，m=月线')
    val_parser.set_defaults(func=cmd_download_valuation)

    # download-all 命令
    all_parser = subparsers.add_parser('download-all', help='下载所有数据')
    all_parser.add_argument('--code', required=True, help='股票代码，如 sh.600000')
    all_parser.set_defaults(func=cmd_download_all)

    # list-stocks 命令
    list_parser = subparsers.add_parser('list-stocks', help='列出股票列表')
    list_parser.add_argument('--industry', help='按行业筛选')
    list_parser.set_defaults(func=cmd_list_stocks)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
