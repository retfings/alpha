/// Handler for serve command

///|
/// Run serve command - start HTTP API server
pub fn _run_serve(port : Int) -> Unit {
  println("Starting HTTP API server on port \{port}...")
  println("")
  println("Available endpoints:")
  println("  GET  /api/health              - Health check")
  println("  GET  /api/stocks              - List stocks")
  println("  GET  /api/stocks/:code        - Get stock info")
  println("  GET  /api/stocks/:code/klines - Get klines")
  println("  POST /api/backtest            - Start backtest")
  println("  GET  /api/backtest/:id/result - Get result")
  println("  GET  /api/drawdown/:code      - Get drawdown")
  println("  GET  /api/portfolio/drawdown  - Portfolio drawdown")
  println("")
  println("Press Ctrl+C to stop")
  println("")

  // Start the HTTP server
  @server.start_server(port)
}
