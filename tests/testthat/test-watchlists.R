# Tests for AlpacaAccount watchlist methods

test_that("get_watchlists returns data.table of watchlists", {
  mock_perform <- function(req) {
    return(mock_alpaca_response(mock_watchlists_response()))
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

test_that("get_watchlist returns long-format data.table with one row per asset", {
  mock_perform <- function(req) {
    return(mock_alpaca_response(mock_watchlist_response()))
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$get_watchlist("wl-uuid-1")

  expect_s3_class(result, "data.table")
  # Mock watchlist has 2 assets (AAPL, MSFT) => 2 rows
  expect_equal(nrow(result), 2)
  expect_equal(unique(result$name), "Tech Stocks")
  expect_true("asset_symbol" %in% names(result))
  expect_true("asset_id" %in% names(result))
  expect_false("assets" %in% names(result))
  expect_setequal(result$asset_symbol, c("AAPL", "MSFT"))
})

test_that("get_watchlist on an empty watchlist returns the full asset_* schema (including asset_attributes)", {
  empty_wl <- list(
    id = "wl-empty",
    account_id = "acct-uuid-123",
    name = "Empty",
    created_at = "2024-01-10T10:00:00Z",
    updated_at = "2024-01-10T10:00:00Z",
    assets = list()
  )
  mock_perform <- function(req) mock_alpaca_response(empty_wl)

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$get_watchlist("wl-empty")

  expect_equal(nrow(result), 1L)
  # All four asset_* cols must be present so users can rely on the schema.
  for (col in c("asset_id", "asset_symbol", "asset_name", "asset_attributes")) {
    expect_true(col %in% names(result), info = paste("missing column:", col))
    expect_true(is.na(result[[col]]), info = paste("expected NA in column:", col))
  }
})

test_that("get_watchlist collapses per-asset `attributes` to a character column (no list cols)", {
  mock_perform <- function(req) {
    return(mock_alpaca_response(mock_watchlist_response()))
  }

  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  acct$.__enclos_env__$private$.perform <- mock_perform

  result <- acct$get_watchlist("wl-uuid-1")

  # No list columns anywhere — populated and empty attribute arrays both
  # must reduce to a plain character cell.
  list_cols <- names(result)[vapply(result, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)

  expect_true("asset_attributes" %in% names(result))
  expect_true(is.character(result$asset_attributes))

  # Asset with attributes: `;`-joined character.
  expect_equal(
    result[asset_symbol == "AAPL", asset_attributes],
    "fractional_eh_enabled;has_options"
  )
  # Asset with an empty array: NA character (not literal "" or "NA").
  expect_true(is.na(result[asset_symbol == "MSFT", asset_attributes]))
})

test_that("add_watchlist sends POST with name and symbols", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    return(mock_alpaca_response(mock_watchlist_response()))
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
    return(mock_alpaca_response(mock_watchlist_response()))
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
    return(mock_alpaca_response(mock_watchlist_response()))
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
    return(mock_alpaca_response(mock_watchlist_response()))
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
    return(mock_no_content_response())
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
