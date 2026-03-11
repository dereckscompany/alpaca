KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"
DATA_BASE <- "https://data.alpaca.markets"

new_options <- function() {
  AlpacaOptions$new(keys = KEYS, base_url = BASE, data_base_url = DATA_BASE)
}

test_that("AlpacaOptions inherits from AlpacaBase", {
  opts <- new_options()
  expect_s3_class(opts, "AlpacaOptions")
  expect_s3_class(opts, "AlpacaBase")
})

test_that("get_contracts returns data.table with contract fields", {
  resp <- mock_alpaca_response(mock_option_contracts_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_contracts(underlying_symbols = "AAPL", type = "call")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true(all(c("symbol", "type", "strike_price", "expiration_date") %in% names(dt)))
})

test_that("get_contracts uses trading base URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_option_contracts_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_options()$get_contracts()
  expect_true(grepl("paper-api\\.alpaca\\.markets", captured_url))
})

test_that("get_contract returns single-row data.table", {
  resp <- mock_alpaca_response(mock_option_contract_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_contract("AAPL240621C00200000")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol, "AAPL240621C00200000")
})

test_that("get_option_bars uses data base URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_multi_bars_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_options()$get_option_bars("AAPL240621C00200000")
  expect_true(grepl("data\\.alpaca\\.markets", captured_url))
  expect_true(grepl("v1beta1/options/bars", captured_url))
})

test_that("get_option_bars returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_multi_bars_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_option_bars("AAPL240621C00200000")
  expect_s3_class(dt, "data.table")
  expect_true("symbol" %in% names(dt))
})

test_that("get_option_snapshot uses data base URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_snapshot_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_options()$get_option_snapshot("AAPL240621C00200000")
  expect_true(grepl("data\\.alpaca\\.markets", captured_url))
  expect_true(grepl("v1beta1/options/snapshots", captured_url))
})

test_that("get_option_latest_trades returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_option_latest_trades_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_option_latest_trades("AAPL240621C00200000")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_true("symbol" %in% names(dt))
  expect_equal(dt$symbol, "AAPL240621C00200000")
})

test_that("get_option_latest_trades uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_option_latest_trades_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_options()$get_option_latest_trades("AAPL240621C00200000")
  expect_true(grepl("v1beta1/options/trades/latest", captured_url))
  expect_true(grepl("data\\.alpaca\\.markets", captured_url))
})

test_that("get_option_chain returns data.table with symbol column", {
  resp <- mock_alpaca_response(mock_option_chain_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_option_chain("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
  expect_true("symbol" %in% names(dt))
  expect_equal(names(dt)[1], "symbol")
})

test_that("get_option_chain uses correct endpoint and data base URL", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_option_chain_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_options()$get_option_chain("AAPL", type = "call")
  expect_true(grepl("v1beta1/options/snapshots/AAPL", captured_url))
  expect_true(grepl("data\\.alpaca\\.markets", captured_url))
})
