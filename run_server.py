#!/usr/bin/env python3
"""
Stock Strategy Page Server

Simple HTTP server for serving the stock strategy frontend page.
Run this script to start the server and access the page in your browser.

Usage:
    python run_server.py [port]

Examples:
    python run_server.py          # Starts server on port 8000
    python run_server.py 3000     # Starts server on port 3000
"""

import http.server
import socketserver
import os
import sys
import webbrowser
from pathlib import Path

# Configuration
DEFAULT_PORT = 8000
HOST = 'localhost'

# Get the directory where this script is located
SCRIPT_DIR = Path(__file__).parent.absolute()
WWW_DIR = SCRIPT_DIR / 'www'

class StockStrategyHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler for serving stock strategy pages."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WWW_DIR), **kwargs)

    def log_message(self, format, *args):
        """Custom log message format."""
        print(f"[{self.log_date_time_string()}] {format % args}")


def start_server(port: int = DEFAULT_PORT) -> None:
    """Start the HTTP server."""

    # Ensure www directory exists
    if not WWW_DIR.exists():
        print(f"Error: www directory not found at {WWW_DIR}")
        sys.exit(1)

    # Allow port reuse to avoid "Address already in use" errors
    socketserver.TCPServer.allow_reuse_address = True

    # Create server
    with socketserver.TCPServer((HOST, port), StockStrategyHandler) as httpd:
        url = f"http://{HOST}:{port}"

        print("=" * 60)
        print("  Stock Strategy Server")
        print("=" * 60)
        print(f"  Server started at: {url}")
        print(f"  Serving files from: {WWW_DIR}")
        print()
        print("  Available pages:")
        print(f"    - Dashboard:    {url}/index.html")
        print(f"    - Stock Strategy: {url}/stock_strategy.html")
        print()
        print("  Press Ctrl+C to stop the server")
        print("=" * 60)

        # Open browser automatically
        try:
            webbrowser.open(f"{url}/stock_strategy.html")
        except Exception:
            pass

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")


def main():
    """Main entry point."""
    # Parse port from command line
    port = DEFAULT_PORT
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}. Using default port {DEFAULT_PORT}")

    start_server(port)


if __name__ == '__main__':
    main()
