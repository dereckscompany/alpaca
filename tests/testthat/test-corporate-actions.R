# Tests for AlpacaMarketData corporate actions and news methods

test_that("get_corporate_actions returns data.table of announcements", {
  mock_perform <- function(req) {
    expect_true(grepl("corporate_actions/announcements", req$url))
    expect_true(grepl("ca_types=dividend", req$url))
    return(mock_alpaca_response(mock_corporate_actions_response()))
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
    return(mock_alpaca_response(mock_corporate_actions_response()))
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
    return(mock_alpaca_response(list()))
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

# ---- get_corporate_actions_history (market-data archive, data host) ----

new_market <- function(async = FALSE) {
  return(AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets",
    async = async
  ))
}

test_that("get_corporate_actions_history stacks types with a `type` discriminator and full schema", {
  market <- new_market()
  market$.__enclos_env__$private$.perform <- function(req) {
    return(mock_alpaca_response(mock_corporate_actions_history_response()))
  }

  dt <- market$get_corporate_actions_history(symbols = c("AAPL", "TSLA"))
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 3L)

  # The full canonical schema is always present (reindexed), in order, id + type first.
  expect_equal(names(dt)[1:2], c("id", "type"))
  expect_true(all(
    c(
      "symbol",
      "cusip",
      "new_rate",
      "old_rate",
      "rate",
      "foreign",
      "special",
      "ex_date",
      "process_date",
      "effective_date",
      "acquirer_symbol",
      "acquiree_rate"
    ) %in%
      names(dt)
  ))
  expect_equal(ncol(dt), ncol(empty_dt_corporate_actions_history()))

  # Discriminator carries the venue's plural group keys.
  expect_setequal(dt$type, c("cash_dividends", "forward_splits", "stock_mergers"))

  # Column types per the NA-audit conventions.
  expect_type(dt$id, "character")
  expect_type(dt$type, "character")
  expect_type(dt$symbol, "character")
  expect_type(dt$rate, "double")
  expect_type(dt$new_rate, "double")
  expect_type(dt$foreign, "logical")
  expect_s3_class(dt$ex_date, "Date")
  expect_s3_class(dt$process_date, "Date")

  # No list columns anywhere.
  expect_equal(length(names(dt)[vapply(dt, is.list, logical(1L))]), 0L)
})

test_that("get_corporate_actions_history NA-fills the columns a type does not carry", {
  market <- new_market()
  market$.__enclos_env__$private$.perform <- function(req) {
    return(mock_alpaca_response(mock_corporate_actions_history_response()))
  }

  dt <- market$get_corporate_actions_history()
  div <- dt[type == "cash_dividends"]
  split <- dt[type == "forward_splits"]
  merger <- dt[type == "stock_mergers"]

  # A dividend carries `rate` but no split rate; a split carries new/old_rate but
  # no `rate`; a merger carries acquirer/acquiree symbols but no `symbol`.
  expect_equal(div$rate, 0.25)
  expect_true(is.na(div$new_rate))
  expect_equal(split$new_rate, 3)
  expect_true(is.na(split$rate))
  expect_true(is.na(merger$symbol))
  expect_equal(merger$acquirer_symbol, "ACQR")
  expect_equal(div$ex_date, as.Date("2024-02-09"))
  expect_true(is.na(merger$ex_date))
})

test_that("get_corporate_actions_history uses the data base URL and passes filters", {
  captured <- NULL
  market <- new_market()
  market$.__enclos_env__$private$.perform <- function(req) {
    captured <<- req
    return(mock_alpaca_response(mock_corporate_actions_history_response()))
  }

  market$get_corporate_actions_history(
    types = c("forward_split", "cash_dividend"),
    symbols = c("AAPL", "TSLA"),
    start = "2016-01-01",
    end = "2024-12-31"
  )

  expect_true(grepl("data.alpaca.markets", captured$url))
  expect_true(grepl("v1/corporate-actions", captured$url))
  expect_true(grepl("types=forward_split", captured$url))
  expect_true(grepl("symbols=AAPL", captured$url))
})

test_that("get_corporate_actions_history rejects an invalid type before any request", {
  market <- new_market()
  called <- FALSE
  market$.__enclos_env__$private$.perform <- function(req) {
    called <<- TRUE
    return(mock_alpaca_response(mock_corporate_actions_history_response()))
  }

  expect_error(
    market$get_corporate_actions_history(types = c("cash_dividend", "not_a_type")),
    class = "alpaca_validation_error"
  )
  expect_false(called)
})

test_that("get_corporate_actions_history returns the typed empty on no actions", {
  market <- new_market()
  market$.__enclos_env__$private$.perform <- function(req) {
    return(mock_alpaca_response(list(corporate_actions = list(), next_page_token = NULL)))
  }

  dt <- market$get_corporate_actions_history(symbols = "AAPL")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
  expect_identical(names(dt), names(empty_dt_corporate_actions_history()))
  expect_s3_class(dt$ex_date, "Date")
})

test_that("get_corporate_actions_history auto-paginates across next_page_token", {
  page <- 0L
  market <- new_market()
  market$.__enclos_env__$private$.perform <- function(req) {
    page <<- page + 1L
    if (grepl("page_token=tok2", req$url)) {
      return(mock_alpaca_response(list(
        corporate_actions = list(
          forward_splits = list(list(
            id = "id-2",
            symbol = "TSLA",
            new_rate = 3,
            old_rate = 1,
            ex_date = "2022-08-25",
            process_date = "2022-08-25"
          ))
        ),
        next_page_token = NULL
      )))
    }
    return(mock_alpaca_response(list(
      corporate_actions = list(
        cash_dividends = list(list(
          id = "id-1",
          symbol = "AAPL",
          rate = 0.25,
          foreign = FALSE,
          special = FALSE,
          ex_date = "2024-02-09",
          process_date = "2024-02-15"
        ))
      ),
      next_page_token = "tok2"
    )))
  }

  dt <- market$get_corporate_actions_history()
  expect_equal(page, 2L)
  expect_equal(nrow(dt), 2L)
  expect_setequal(dt$type, c("cash_dividends", "forward_splits"))
})

test_that("get_corporate_actions_history resolves the same table in async mode", {
  market <- new_market(async = TRUE)
  # Async mode performs via a promise-returning performer (real code uses
  # httr2::req_perform_promise); the mock resolves the synthetic response.
  market$.__enclos_env__$private$.perform <- function(req) {
    return(promises::promise_resolve(mock_alpaca_response(mock_corporate_actions_history_response())))
  }

  p <- market$get_corporate_actions_history(symbols = "AAPL")
  expect_s3_class(p, "promise")

  resolved <- NULL
  promises::then(p, function(val) resolved <<- val)
  for (i in 1:20) {
    later::run_now(0.1)
  }

  expect_s3_class(resolved, "data.table")
  expect_equal(nrow(resolved), 3L)
  expect_setequal(resolved$type, c("cash_dividends", "forward_splits", "stock_mergers"))
})
