# Tests for AlpacaMarketData corporate actions and news methods

test_that("get_corporate_actions returns data.table of announcements", {
  mock_perform <- function(req) {
    expect_true(grepl("corporate_actions/announcements", req$url))
    expect_true(grepl("ca_types=dividend", req$url))
    mock_alpaca_response(mock_corporate_actions_response())
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_corporate_actions(
    ca_types = "dividend",
    since = "2024-01-01",
    until = "2024-12-31"
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_true("ca_type" %in% names(result))
  expect_equal(result$ca_type[1], "dividend")
  expect_equal(result$ca_type[2], "split")
  expect_equal(result$initiating_symbol[1], "AAPL")
})

test_that("get_corporate_actions passes symbol filter", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_corporate_actions_response())
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  market$get_corporate_actions(
    ca_types = "dividend",
    since = "2024-01-01",
    until = "2024-12-31",
    symbol = "AAPL"
  )

  expect_true(grepl("symbol=AAPL", captured_req$url))
})

test_that("get_corporate_actions uses trading base URL", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(list())
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  market$get_corporate_actions(
    ca_types = "split",
    since = "2024-01-01",
    until = "2024-12-31"
  )

  expect_true(grepl("paper-api.alpaca.markets", captured_req$url))
})
