KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"
DATA_BASE <- "https://data.alpaca.markets"

new_market <- function() {
  return(AlpacaMarketData$new(keys = KEYS, base_url = BASE, data_base_url = DATA_BASE))
}

test_that("AlpacaMarketData inherits from AlpacaBase", {
  market <- new_market()
  expect_s3_class(market, "AlpacaMarketData")
  expect_s3_class(market, "AlpacaBase")
  expect_false(market$is_async)
})

test_that("get_bars returns data.table with correct columns", {
  resp <- mock_alpaca_response(mock_bars_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_bars("AAPL", timeframe = "1Day")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("timestamp", "open", "high", "low", "close", "volume", "trade_count", "vwap") %in% names(dt)))
  expect_s3_class(dt$timestamp, "POSIXct")
})

test_that("get_bars_multi returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_multi_bars_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_bars_multi(c("AAPL", "MSFT"), timeframe = "1Day")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_equal(names(dt)[1], "symbol")
  expect_setequal(unique(dt$symbol), c("AAPL", "MSFT"))
})

test_that("get_latest_trade returns long-format data.table with condition column", {
  resp <- mock_alpaca_response(mock_trade_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_trade("AAPL")
  expect_s3_class(dt, "data.table")
  # Policy: one trade = one row, regardless of how many condition codes.
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("timestamp", "price", "size", "conditions") %in% names(dt)))
  expect_false("condition" %in% names(dt))
  expect_true(is.character(dt$conditions))
  expect_false(is.list(dt$conditions))
  expect_equal(dt$conditions[1], "@")
})

test_that("get_latest_quote returns single-row data.table", {
  resp <- mock_alpaca_response(mock_quote_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_quote("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("timestamp", "ask_price", "bid_price") %in% names(dt)))
})

test_that("get_snapshot returns flattened data.table with always-present conditions cols", {
  resp <- mock_alpaca_response(mock_snapshot_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_snapshot("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  # `latest_trade_conditions` / `latest_quote_conditions` always exist
  # when their parent section is present.
  expect_true(all(c("latest_trade_conditions", "latest_quote_conditions") %in% names(dt)))
  expect_equal(dt$latest_trade_conditions, "@;T")
  expect_equal(dt$latest_quote_conditions, "R")
  # Bar `*_close` columns are scalar numbers (not "conditions").
  expect_true(is.numeric(dt$minute_bar_close))
  expect_equal(dt$minute_bar_close, 185.50)
})

test_that("get_assets returns data.table", {
  resp <- mock_alpaca_response(mock_assets_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_assets()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
})

test_that("get_asset returns single-row data.table", {
  resp <- mock_alpaca_response(mock_assets_response()[[1]])
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_asset("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
})

test_that("get_clock returns data.table with is_open field", {
  resp <- mock_alpaca_response(mock_clock_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_clock()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("is_open" %in% names(dt))
})

test_that("get_corporate_actions parses the four *_date fields to Date", {
  resp <- mock_alpaca_response(mock_corporate_actions_response())
  httr2::local_mocked_responses(function(req) resp)

  # The endpoint emits a deprecation warning we don't care about here.
  dt <- suppressWarnings(
    new_market()$get_corporate_actions(
      ca_types = "dividend",
      since = "2024-01-01",
      until = "2024-03-31"
    )
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  for (col in c("declaration_date", "ex_date", "record_date", "payable_date")) {
    expect_true(inherits(dt[[col]], "Date"), label = col)
  }
  expect_equal(format(dt$ex_date), c("2024-02-09", "2024-06-10"))
})

test_that("get_calendar returns data.table", {
  resp <- mock_alpaca_response(mock_calendar_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_calendar()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("date", "open", "close") %in% names(dt)))
})

test_that("get_bars uses data base URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_bars_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_bars("AAPL")
  expect_true(grepl("data\\.alpaca\\.markets", captured_url))
})

test_that("get_assets uses trading base URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_assets_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_assets()
  expect_true(grepl("paper-api\\.alpaca\\.markets", captured_url))
})

test_that("get_latest_bars_multi returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_latest_bars_multi_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_bars_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_equal(names(dt)[1], "symbol")
  expect_setequal(unique(dt$symbol), c("AAPL", "MSFT"))
})

test_that("get_latest_trades_multi returns long-format data.table with condition column", {
  resp <- mock_alpaca_response(mock_latest_trades_multi_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_trades_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  # Policy: one symbol = one row (latest trade per symbol).
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_setequal(unique(dt$symbol), c("AAPL", "MSFT"))
  expect_true("price" %in% names(dt))
  expect_true("conditions" %in% names(dt))
  expect_false("condition" %in% names(dt))
  expect_false(is.list(dt$conditions))
})

test_that("get_latest_quotes_multi returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_latest_quotes_multi_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_quotes_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_true(all(c("ask_price", "bid_price") %in% names(dt)))
})

test_that("get_snapshots_multi returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_snapshots_multi_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_snapshots_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_setequal(unique(dt$symbol), c("AAPL", "MSFT"))

  # Schema stability: conditions columns must exist on every row, even
  # when one symbol's snapshot omits the `c` field on a section.
  expect_true(all(c("latest_trade_conditions", "latest_quote_conditions") %in% names(dt)))
  expect_equal(dt[symbol == "AAPL"]$latest_trade_conditions, "@;T")
  expect_equal(dt[symbol == "AAPL"]$latest_quote_conditions, "R")
  expect_true(is.na(dt[symbol == "MSFT"]$latest_trade_conditions))
  expect_true(is.na(dt[symbol == "MSFT"]$latest_quote_conditions))
})

test_that("get_most_actives returns data.table", {
  resp <- mock_alpaca_response(mock_most_actives_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_most_actives()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true("symbol" %in% names(dt))
  expect_true("volume" %in% names(dt))
})

test_that("get_most_actives uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_most_actives_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_most_actives(by = "volume", top = 10)
  expect_true(grepl("screener/stocks/most-actives", captured_url))
  expect_true(grepl("data\\.alpaca\\.markets", captured_url))
})

test_that("get_movers returns data.table with direction column", {
  resp <- mock_alpaca_response(mock_movers_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_movers()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 4L)
  expect_true("direction" %in% names(dt))
  expect_setequal(unique(dt$direction), c("gainer", "loser"))
})

test_that("get_movers uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_movers_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_movers(market_type = "stocks", top = 5)
  expect_true(grepl("screener/stocks/movers", captured_url))
})

# ---- new query parameters land on the URL ----------------------------------

test_that("get_bars puts asof and currency on the URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_bars_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_bars(
    "AAPL",
    timeframe = "1Day",
    asof = "2024-06-09",
    currency = "EUR"
  )
  expect_true(grepl("asof=2024-06-09", captured_url))
  expect_true(grepl("currency=EUR", captured_url))
})

test_that("get_calendar puts date_type on the URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_calendar(date_type = "SETTLEMENT")
  expect_true(grepl("date_type=SETTLEMENT", captured_url))
})

test_that("get_assets puts attributes on the URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(list())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_assets(attributes = "has_options,overnight_tradable")
  expect_true(grepl("attributes=has_options", captured_url))
})

# ---- enum guards ------------------------------------------------------------

test_that("get_calendar rejects unknown date_type", {
  expect_error(
    new_market()$get_calendar(date_type = "WHENEVER"),
    "date_type"
  )
})

# ---- get_crypto_orderbook -------------------------------------------------

test_that("get_crypto_orderbook returns long format with `level` position index", {
  resp <- mock_alpaca_response(mock_crypto_orderbook_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_crypto_orderbook("BTC/USD")

  expect_s3_class(dt, "data.table")
  # Mock fixture has 2 bids + 2 asks for one symbol -> 4 rows.
  expect_equal(nrow(dt), 4L)
  # Column set + ordering match the documented `(symbol, side, level, ...)`.
  expect_equal(names(dt), c("symbol", "side", "level", "price", "size", "timestamp"))
  # No list columns sneak through.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
})

test_that("get_crypto_orderbook indexes each side from 1 (top of book)", {
  resp <- mock_alpaca_response(mock_crypto_orderbook_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_crypto_orderbook("BTC/USD")
  # level 1 is the best bid / best ask.
  expect_equal(dt[side == "bid"]$level, c(1L, 2L))
  expect_equal(dt[side == "ask"]$level, c(1L, 2L))
  # Prices are preserved in Alpaca-response order (bids descend from best,
  # asks ascend from best).
  expect_equal(dt[side == "bid"]$price, c(42950.50, 42949.00))
  expect_equal(dt[side == "ask"]$price, c(42951.00, 42952.50))
})

test_that("get_crypto_orderbook parses timestamp as POSIXct", {
  resp <- mock_alpaca_response(mock_crypto_orderbook_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_crypto_orderbook("BTC/USD")
  expect_s3_class(dt$timestamp, "POSIXct")
  # All four rows share the snapshot timestamp.
  expect_equal(length(unique(dt$timestamp)), 1L)
})

test_that("get_crypto_orderbook returns empty data.table with full schema on empty response", {
  resp <- mock_alpaca_response(list(orderbooks = list()))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_crypto_orderbook("BTC/USD")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
  expect_equal(names(dt), c("symbol", "side", "level", "price", "size", "timestamp"))
})

test_that("get_crypto_orderbook builds the right URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_crypto_orderbook_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_market()$get_crypto_orderbook(c("BTC/USD", "ETH/USD"), loc = "us")
  expect_true(grepl("/v1beta3/crypto/us/latest/orderbooks", captured_url, fixed = TRUE))
  expect_true(grepl("symbols=", captured_url, fixed = TRUE))
})
