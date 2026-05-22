KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"

new_account <- function() {
  return(AlpacaAccount$new(keys = KEYS, base_url = BASE))
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
  # created_at must parse to POSIXct (UTC), not character.
  expect_true(inherits(dt$created_at, "POSIXct"))
  expect_equal(attr(dt$created_at, "tzone"), "UTC")
})

test_that("get_account flattens admin_configurations / user_configurations into wide cols (no list cols)", {
  resp <- mock_alpaca_response(mock_account_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_account()

  # The nested config objects must be gone, replaced by wide-prefixed
  # columns. No list columns anywhere.
  expect_false("admin_configurations" %in% names(dt))
  expect_false("user_configurations" %in% names(dt))
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)

  # admin_*
  expect_true("admin_configurations_max_margin_multiplier" %in% names(dt))
  expect_equal(dt$admin_configurations_max_margin_multiplier, "4")
  expect_equal(dt$admin_configurations_max_options_trading_level, 3L)

  # user_*
  expect_true("user_configurations_dtbp_check" %in% names(dt))
  expect_equal(dt$user_configurations_dtbp_check, "entry")
  expect_equal(dt$user_configurations_no_shorting, FALSE)
  expect_equal(dt$user_configurations_trade_confirm_email, "all")
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

test_that("get_portfolio_history rejects providing all of period, start, end", {
  expect_error(
    new_account()$get_portfolio_history(
      period = "1M",
      start = "2026-01-01",
      end = "2026-02-01"
    ),
    "Only two of"
  )
})

test_that("get_portfolio_history warns and forwards deprecated date_start/date_end", {
  captured_url <- NULL
  resp <- mock_alpaca_response(
    list(timestamp = list(), equity = list(), profit_loss = list(), profit_loss_pct = list())
  )
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  expect_warning(
    new_account()$get_portfolio_history(
      date_start = "2026-01-01",
      date_end = "2026-02-01"
    ),
    "date_start.*deprecated"
  )
  expect_true(grepl("start=2026-01-01", captured_url))
  expect_true(grepl("end=2026-02-01", captured_url))
})

test_that("get_activities rejects both activity_types and category", {
  expect_error(
    new_account()$get_activities(
      activity_types = "FILL",
      category = "trade_activity"
    ),
    "mutually exclusive"
  )
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

test_that("get_activities returns data.table with transaction_time POSIXct", {
  resp <- mock_alpaca_response(mock_activities_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_activities()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  if ("transaction_time" %in% names(dt)) {
    expect_true(inherits(dt$transaction_time, "POSIXct"))
  }
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

test_that("get_account_config returns data.table with config fields", {
  resp <- mock_alpaca_response(mock_account_config_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_account()$get_account_config()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true(all(c("dtbp_check", "no_shorting", "fractional_trading") %in% names(dt)))
  expect_equal(dt$dtbp_check, "both")
})

test_that("get_account_config uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_account_config_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_account()$get_account_config()
  expect_true(grepl("/v2/account/configurations", captured_url))
})

test_that("modify_account_config sends PATCH request", {
  captured_req <- NULL
  resp <- mock_alpaca_response(mock_account_config_response())
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  new_account()$modify_account_config(no_shorting = TRUE)
  expect_equal(captured_req$method, "PATCH")
  expect_true(grepl("/v2/account/configurations", captured_req$url))
})

test_that("exercise_option sends POST to correct endpoint", {
  captured_req <- NULL
  resp <- mock_no_content_response()
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  dt <- new_account()$exercise_option("AAPL240621C00200000")
  expect_equal(captured_req$method, "POST")
  expect_true(grepl("/v2/positions/AAPL240621C00200000/exercise", captured_req$url))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "AAPL240621C00200000")
  expect_equal(dt$status, "exercised")
})
