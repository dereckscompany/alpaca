# Tests for alpaca_paginate()

test_that("alpaca_paginate follows next_page_token across pages", {
  call_count <- 0L

  mock_perform <- function(req) {
    call_count <<- call_count + 1L
    url <- req$url
    if (grepl("page_token=token-page-2", url)) {
      return(mock_alpaca_response(mock_bars_page2_response()))
    }
    return(mock_alpaca_response(mock_bars_page1_response()))
  }

  result <- alpaca_paginate(
    base_url = "https://data.alpaca.markets",
    endpoint = "/v2/stocks/AAPL/bars",
    query = list(timeframe = "1Day"),
    keys = list(api_key = "k", api_secret = "s"),
    .perform = mock_perform,
    items_field = "bars",
    .parser = parse_bars
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_equal(call_count, 2L)
  expect_true("timestamp" %in% names(result))
})

test_that("alpaca_paginate stops at max_pages", {
  call_count <- 0L

  mock_perform <- function(req) {
    call_count <<- call_count + 1L
    # Always return a next page token
    return(mock_alpaca_response(mock_bars_page1_response()))
  }

  result <- alpaca_paginate(
    base_url = "https://data.alpaca.markets",
    endpoint = "/v2/stocks/AAPL/bars",
    query = list(timeframe = "1Day"),
    keys = list(api_key = "k", api_secret = "s"),
    .perform = mock_perform,
    items_field = "bars",
    max_pages = 3,
    .parser = parse_bars
  )

  expect_equal(call_count, 3L)
  expect_equal(nrow(result), 3)
})

test_that("alpaca_paginate handles single page (no next_page_token)", {
  mock_perform <- function(req) {
    return(mock_alpaca_response(mock_bars_page2_response()))
  }

  result <- alpaca_paginate(
    base_url = "https://data.alpaca.markets",
    endpoint = "/v2/stocks/AAPL/bars",
    query = list(timeframe = "1Day"),
    keys = list(api_key = "k", api_secret = "s"),
    .perform = mock_perform,
    items_field = "bars",
    .parser = parse_bars
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1)
})

test_that("alpaca_paginate works without items_field (top-level list)", {
  mock_perform <- function(req) {
    return(mock_alpaca_response(list(
      list(id = "act-1", activity_type = "FILL"),
      list(id = "act-2", activity_type = "DIV")
    )))
  }

  result <- alpaca_paginate(
    base_url = "https://paper-api.alpaca.markets",
    endpoint = "/v2/account/activities",
    keys = list(api_key = "k", api_secret = "s"),
    .perform = mock_perform,
    .parser = as_dt_list
  )

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
})
