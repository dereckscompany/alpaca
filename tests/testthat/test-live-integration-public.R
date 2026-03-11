# Live integration tests — market data endpoints.
#
# NOTE: Unlike crypto exchanges, ALL Alpaca endpoints require API keys
# (even market data). A free paper-trading account works fine.
#
# Run with:
#   ALPACA_LIVE_TESTS=true Rscript --vanilla -e 'devtools::test(filter = "live-integration-public")'
#
# Requires ALPACA_API_KEY and ALPACA_API_SECRET env vars.
# Skipped by default — only runs when ALPACA_LIVE_TESTS=true is set.

skip_if_not(
  identical(Sys.getenv("ALPACA_LIVE_TESTS"), "true"),
  "Live API tests skipped (set ALPACA_LIVE_TESTS=true to run)"
)

# Throttle between requests to respect rate limits
throttle <- function() Sys.sleep(0.3)

# ---- Setup ----

.keys <- get_api_keys()
market <- AlpacaMarketData$new(keys = .keys)

# ---- Market Data: Bars ----

test_that("[LIVE] get_bars returns data.table with OHLCV columns", {
  dt <- market$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01", end = "2024-01-31", limit = 5)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true(all(c("timestamp", "open", "high", "low", "close", "volume") %in% names(dt)))
  expect_s3_class(dt$timestamp, "POSIXct")
  expect_true(all(dt$high >= dt$low))
  throttle()
})

test_that("[LIVE] get_bars_multi returns data.table with symbol column", {
  dt <- market$get_bars_multi(c("AAPL", "MSFT"), timeframe = "1Day", start = "2024-01-01", end = "2024-01-10")
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("symbol" %in% names(dt))
  expect_true(all(dt$symbol %in% c("AAPL", "MSFT")))
  throttle()
})

# ---- Market Data: Latest ----

test_that("[LIVE] get_latest_bar returns single-row data.table", {
  dt <- market$get_latest_bar("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_true("close" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_latest_trade returns single-row data.table", {
  dt <- market$get_latest_trade("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_true(all(c("price", "size") %in% names(dt)))
  expect_true(dt$price > 0)
  throttle()
})

test_that("[LIVE] get_latest_quote returns bid/ask data", {
  dt <- market$get_latest_quote("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_true(all(c("ask_price", "bid_price") %in% names(dt)))
  expect_true(dt$ask_price >= dt$bid_price)
  throttle()
})

# ---- Market Data: Snapshot ----

test_that("[LIVE] get_snapshot returns flattened snapshot data", {
  dt <- market$get_snapshot("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_gt(ncol(dt), 5)
  throttle()
})

# ---- Market Data: Historical Trades & Quotes ----

test_that("[LIVE] get_trades returns historical trade data", {
  dt <- market$get_trades("AAPL", start = "2024-01-16", end = "2024-01-16", limit = 10)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("price" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_quotes returns historical quote data", {
  dt <- market$get_quotes("AAPL", start = "2024-01-16", end = "2024-01-16", limit = 10)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true(all(c("ask_price", "bid_price") %in% names(dt)))
  throttle()
})

# ---- Assets ----

test_that("[LIVE] get_assets returns data.table of assets", {
  dt <- market$get_assets(status = "active", asset_class = "us_equity")
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 100)
  expect_true(all(c("symbol", "name", "tradable", "shortable") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_asset returns single asset info", {
  dt <- market$get_asset("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_equal(dt$symbol, "AAPL")
  expect_true(dt$tradable)
  throttle()
})

# ---- Calendar & Clock ----

test_that("[LIVE] get_calendar returns trading days", {
  dt <- market$get_calendar(start = "2024-01-01", end = "2024-01-31")
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 15)
  expect_true(all(c("date", "open", "close") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_clock returns market status", {
  dt <- market$get_clock()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_true("is_open" %in% names(dt))
  expect_true(is.logical(dt$is_open))
  throttle()
})

# ---- News ----

test_that("[LIVE] get_news returns news articles", {
  dt <- market$get_news(symbols = "AAPL", limit = 5)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true(all(c("headline", "source") %in% names(dt)))
  throttle()
})

# ---- Corporate Actions ----

test_that("[LIVE] get_corporate_actions returns announcements", {
  dt <- market$get_corporate_actions(
    ca_types = "dividend",
    since = "2024-01-01",
    until = "2024-03-31",
    symbol = "AAPL"
  )
  expect_s3_class(dt, "data.table")
  # AAPL pays quarterly dividends, so expect at least some
  expect_gt(nrow(dt), 0)
  expect_true("ca_type" %in% names(dt))
  throttle()
})

# ---- Options ----

test_that("[LIVE] AlpacaOptions get_contracts returns options contracts", {
  opts <- AlpacaOptions$new(keys = .keys)
  dt <- opts$get_contracts(underlying_symbols = "AAPL", type = "call", limit = 5)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true(all(c("symbol", "type", "strike_price", "expiration_date") %in% names(dt)))
  throttle()
})

# ---- Pagination ----

test_that("[LIVE] alpaca_paginate fetches multiple pages of bars", {
  dt <- alpaca_paginate(
    base_url = get_data_base_url(),
    endpoint = "/v2/stocks/AAPL/bars",
    query = list(timeframe = "1Day", start = "2024-01-01", end = "2024-06-30", limit = 100),
    keys = .keys,
    items_field = "bars",
    max_pages = 3,
    .parser = parse_bars
  )
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("timestamp" %in% names(dt))
  throttle()
})

# ---- Multi-Symbol Latest ----

test_that("[LIVE] get_latest_bars_multi returns bars for multiple symbols", {
  dt <- market$get_latest_bars_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("symbol" %in% names(dt))
  expect_true(all(dt$symbol %in% c("AAPL", "MSFT")))
  expect_true("close" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_latest_trades_multi returns trades for multiple symbols", {
  dt <- market$get_latest_trades_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("symbol" %in% names(dt))
  expect_true("price" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_latest_quotes_multi returns quotes for multiple symbols", {
  dt <- market$get_latest_quotes_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("symbol" %in% names(dt))
  expect_true(all(c("ask_price", "bid_price") %in% names(dt)))
  throttle()
})

test_that("[LIVE] get_snapshots_multi returns snapshots for multiple symbols", {
  dt <- market$get_snapshots_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("symbol" %in% names(dt))
  expect_gt(ncol(dt), 5)
  throttle()
})

# ---- Screener ----

test_that("[LIVE] get_most_actives returns active stocks", {
  dt <- market$get_most_actives(by = "volume", top = 5)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("symbol" %in% names(dt))
  throttle()
})

test_that("[LIVE] get_movers returns gainers and losers", {
  dt <- market$get_movers(market_type = "stocks", top = 5)
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true("direction" %in% names(dt))
  throttle()
})

# ---- Options: New Endpoints ----

test_that("[LIVE] AlpacaOptions get_option_chain returns chain data", {
  opts <- AlpacaOptions$new(keys = .keys)
  # Get the chain for a popular stock — use a future expiration
  dt <- opts$get_option_chain("AAPL", type = "call", limit = 5)
  expect_s3_class(dt, "data.table")
  # May be empty if no active contracts match, but should not error
  if (nrow(dt) > 0) {
    expect_true("symbol" %in% names(dt))
  }
  throttle()
})
