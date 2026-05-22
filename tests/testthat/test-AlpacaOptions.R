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

test_that("get_contracts with show_deliverables explodes deliverables to long format", {
  # Fixture: 2 contracts. Contract 1 has 1 deliverable; contract 2 has
  # 2 deliverables (spinoff). Expected row count: 1 + 2 = 3.
  resp <- mock_alpaca_response(mock_option_contracts_with_deliverables_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_contracts(
    underlying_symbols = "AAPL",
    show_deliverables = TRUE
  )

  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)

  # No list columns anywhere.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)

  # Contract 1: one row, deliverable_index = 1.
  c1 <- dt[id == "opt-uuid-1"]
  expect_equal(nrow(c1), 1L)
  expect_equal(c1$deliverable_index, 1L)
  expect_equal(c1$deliverable_symbol, "AAPL")
  expect_equal(c1$deliverable_amount, "100")

  # Spinoff contract: two rows, indices 1 and 2, contract fields replicated.
  spin <- dt[id == "opt-uuid-spinoff"]
  expect_equal(nrow(spin), 2L)
  expect_equal(spin$deliverable_index, c(1L, 2L))
  expect_equal(spin$deliverable_symbol, c("NEWCO", "USD"))
  expect_equal(unique(spin$underlying_symbol), "OLDCO")
})

test_that("get_contracts without show_deliverables returns one row per contract (no deliverable_* cols)", {
  resp <- mock_alpaca_response(mock_option_contracts_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_contracts(underlying_symbols = "AAPL")
  expect_equal(nrow(dt), 2L)
  expect_false(any(grepl("^deliverable_", names(dt))))
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

test_that("get_option_chain preserves impliedVolatility and greeks_*", {
  resp <- mock_alpaca_response(mock_option_chain_with_greeks_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_options()$get_option_chain("AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)

  # No list columns.
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)

  # Top-level scalar.
  expect_true("implied_volatility" %in% names(dt))
  expect_equal(dt$implied_volatility, 0.2712)

  # Greeks flattened to wide.
  expect_true(all(
    c(
      "greeks_delta",
      "greeks_gamma",
      "greeks_theta",
      "greeks_vega",
      "greeks_rho"
    ) %in%
      names(dt)
  ))
  expect_equal(dt$greeks_delta, -0.4577)
  expect_equal(dt$greeks_rho, -0.1289)
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
