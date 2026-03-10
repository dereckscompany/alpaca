KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"
DATA_BASE <- "https://data.alpaca.markets"

new_market <- function() {
  AlpacaMarketData$new(keys = KEYS, base_url = BASE, data_base_url = DATA_BASE)
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

test_that("get_latest_trade returns single-row data.table", {
  resp <- mock_alpaca_response(mock_trade_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_trade("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("timestamp", "price", "size") %in% names(dt)))
})

test_that("get_latest_quote returns single-row data.table", {
  resp <- mock_alpaca_response(mock_quote_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_quote("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("timestamp", "ask_price", "bid_price") %in% names(dt)))
})

test_that("get_snapshot returns flattened data.table", {
  resp <- mock_alpaca_response(mock_snapshot_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_snapshot("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
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

test_that("get_latest_trades_multi returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_latest_trades_multi_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_market()$get_latest_trades_multi(c("AAPL", "MSFT"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_setequal(unique(dt$symbol), c("AAPL", "MSFT"))
  expect_true("price" %in% names(dt))
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
