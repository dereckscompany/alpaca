# Tests for AlpacaAccount watchlist methods

test_that("get_watchlists returns data.table of watchlists", {
  mock_perform <- function(req) {
    mock_alpaca_response(mock_watchlists_response())
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$get_watchlists()

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_true("name" %in% names(result))
  expect_equal(result$name[1], "Tech Stocks")
})

test_that("get_watchlist returns single watchlist with assets", {
  mock_perform <- function(req) {
    mock_alpaca_response(mock_watchlist_response())
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$get_watchlist("wl-uuid-1")

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1)
  expect_equal(result$name, "Tech Stocks")
})

test_that("add_watchlist sends POST with name and symbols", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_watchlist_response())
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$add_watchlist("Tech Stocks", symbols = c("AAPL", "MSFT"))

  expect_s3_class(result, "data.table")
  expect_equal(captured_req$method, "POST")
  expect_true(grepl("watchlists", captured_req$url))
})

test_that("modify_watchlist sends PUT request", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_watchlist_response())
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$modify_watchlist("wl-uuid-1", name = "Updated", symbols = c("AAPL"))

  expect_equal(captured_req$method, "PUT")
})

test_that("add_watchlist_symbol sends POST to watchlist/{id}", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_watchlist_response())
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$add_watchlist_symbol("wl-uuid-1", "NVDA")

  expect_equal(captured_req$method, "POST")
  expect_true(grepl("wl-uuid-1", captured_req$url))
})

test_that("cancel_watchlist_symbol sends DELETE for symbol", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_watchlist_response())
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$cancel_watchlist_symbol("wl-uuid-1", "AAPL")

  expect_equal(captured_req$method, "DELETE")
  expect_true(grepl("wl-uuid-1/AAPL", captured_req$url))
})

test_that("cancel_watchlist sends DELETE and returns confirmation dt", {
  mock_perform <- function(req) {
    mock_no_content_response()
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  dt <- acct$cancel_watchlist("wl-uuid-1")

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$watchlist_id, "wl-uuid-1")
  expect_equal(dt$status, "deleted")
})
