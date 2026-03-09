KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"

new_account <- function() {
  AlpacaAccount$new(keys = KEYS, base_url = BASE)
}

test_that("AlpacaAccount inherits from AlpacaBase", {
  acct <- new_account()
  expect_s3_class(acct, "AlpacaAccount")
  expect_s3_class(acct, "AlpacaBase")
})

test_that("get_account returns data.table with account fields", {
  resp <- mock_alpaca_response(mock_account_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "ACTIVE")
  expect_equal(dt$equity, "100000")
  expect_equal(dt$buying_power, "400000")
  expect_true("pattern_day_trader" %in% names(dt))
})

test_that("get_positions returns data.table", {
  resp <- mock_alpaca_response(mock_positions_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_positions()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "AAPL")
  expect_equal(dt$side, "long")
  expect_true(all(c("avg_entry_price", "qty", "unrealized_pl") %in% names(dt)))
})

test_that("get_position returns single-row data.table", {
  resp <- mock_alpaca_response(mock_positions_response()[[1]])
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_position("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "AAPL")
})

test_that("get_position uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_positions_response()[[1]])
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_account()$get_position("AAPL")
  expect_true(grepl("/v2/positions/AAPL", captured_url))
})

test_that("close_position sends DELETE request", {
  captured_req <- NULL
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  new_account()$close_position("AAPL")
  expect_equal(captured_req$method, "DELETE")
  expect_true(grepl("/v2/positions/AAPL", captured_req$url))
})

test_that("close_position rejects both qty and percentage", {
  expect_error(
    new_account()$close_position("AAPL", qty = 5, percentage = 50),
    "mutually exclusive"
  )
})

test_that("close_position passes percentage as query param", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_account()$close_position("AAPL", percentage = 50)
  expect_true(grepl("percentage=50", captured_url))
})

test_that("get_portfolio_history returns data.table with correct columns", {
  resp <- mock_alpaca_response(mock_portfolio_history_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_portfolio_history(period = "1M", timeframe = "1D")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)
  expect_true(all(c("timestamp", "equity", "profit_loss", "profit_loss_pct") %in% names(dt)))
  expect_s3_class(dt$timestamp, "POSIXct")
})

test_that("get_activities returns data.table", {
  resp <- mock_alpaca_response(mock_activities_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_activities()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
})

test_that("get_activities_by_type uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_activities_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_account()$get_activities_by_type("FILL")
  expect_true(grepl("/v2/account/activities/FILL", captured_url))
})
