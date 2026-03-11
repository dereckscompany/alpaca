# ===========================================================================
# Bug Hunt Tests — Alpaca
# These tests are written as if each bug is already fixed.
# Running against the current code should produce FAILURES.
# ===========================================================================

# ---------------------------------------------------------------------------
# Bug #3: alpaca_fetch_bars() is broken in async mode
# The for-loop collects unresolved promises; rbindlist receives promise
# objects instead of data.tables.
# ---------------------------------------------------------------------------
test_that("alpaca_fetch_bars works correctly in async mode", {
  skip_if_not_installed("promises")

  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  DATA_BASE <- "https://data.alpaca.markets"

  # Mock bars data
  mock_bars <- list(
    bars = list(
      list(t = "2024-01-02T05:00:00Z", o = 185.5, h = 186.0, l = 185.0, c = 185.8, v = 1000, n = 50, vw = 185.6),
      list(t = "2024-01-03T05:00:00Z", o = 185.8, h = 186.5, l = 185.2, c = 186.2, v = 1100, n = 55, vw = 185.9)
    ),
    next_page_token = NULL
  )

  resp <- mock_alpaca_response(mock_bars)

  # Use a custom .perform that returns a promise (async mode)
  async_perform <- function(req) {
    promises::promise(function(resolve, reject) {
      resolve(resp)
    })
  }

  # This should return a promise that resolves to a data.table
  result_promise <- alpaca:::alpaca_fetch_bars(
    symbol = "AAPL",
    timeframe = "1Day",
    start = "2024-01-02",
    end = "2024-01-04",
    keys = keys,
    data_base_url = DATA_BASE,
    .perform = async_perform,
    is_async = TRUE
  )

  # The result should be a promise, not a data.table with promise objects inside
  expect_true(
    promises::is.promise(result_promise),
    info = "alpaca_fetch_bars in async mode should return a promise"
  )

  # Resolve the promise and check the result
  resolved <- NULL
  error_msg <- NULL
  promises::then(
    result_promise,
    onFulfilled = function(val) {
      resolved <<- val
    },
    onRejected = function(err) {
      error_msg <<- conditionMessage(err)
    }
  )

  # Run event loop multiple times to resolve nested promise chains
  for (i in 1:10) {
    later::run_now(timeoutSecs = 0.5)
  }

  expect_null(error_msg, info = paste("Promise rejected with:", error_msg))
  expect_false(is.null(resolved), info = "Promise should have resolved")
  if (!is.null(resolved)) {
    expect_s3_class(resolved, "data.table")
    expect_true(nrow(resolved) > 0, info = "Resolved data.table should have rows")
  }
})

# ---------------------------------------------------------------------------
# Bug #8 (alpaca): wrap_list_fields misses length-1 list fields
# ---------------------------------------------------------------------------
test_that("wrap_list_fields wraps length-1 list fields consistently", {
  # Trade with single condition (length-1 list)
  trade1 <- list(
    t = "2024-01-02T14:30:00Z",
    p = 185.5,
    s = 100,
    c = list("@")
  )

  # Trade with multiple conditions (length>1 list)
  trade2 <- list(
    t = "2024-01-02T14:30:01Z",
    p = 185.6,
    s = 200,
    c = list("@", "T")
  )

  wrapped1 <- alpaca:::wrap_list_fields(trade1)
  wrapped2 <- alpaca:::wrap_list_fields(trade2)

  # Both should have their list fields wrapped
  expect_true(
    is.list(wrapped1$c) && length(wrapped1$c) == 1 && is.list(wrapped1$c[[1]]),
    info = "Single-element list field should be double-wrapped: list(list('@'))"
  )
  expect_true(
    is.list(wrapped2$c) && length(wrapped2$c) == 1,
    info = "Multi-element list field should be wrapped: list(list('@', 'T'))"
  )

  # Should be rbindlist-compatible
  dt1 <- data.table::as.data.table(wrapped1)
  dt2 <- data.table::as.data.table(wrapped2)
  combined <- data.table::rbindlist(list(dt1, dt2), fill = TRUE)

  expect_equal(nrow(combined), 2L)
  expect_true(is.list(combined$c), info = "Combined data.table should have consistent list column type")
})

# ---------------------------------------------------------------------------
# Bug #8 (alpaca variant): as_dt_row wraps length>1 but not length-1 lists
# ---------------------------------------------------------------------------
test_that("as_dt_row wraps length-1 list fields consistently", {
  row1 <- list(name = "A", tags = list("stock"))
  row2 <- list(name = "B", tags = list("stock", "etf"))

  dt1 <- alpaca:::as_dt_row(row1)
  dt2 <- alpaca:::as_dt_row(row2)

  expect_true(is.list(dt1$tags), info = "Single-element list field should remain a list column")

  combined <- data.table::rbindlist(list(dt1, dt2), fill = TRUE)
  expect_equal(nrow(combined), 2L)
  expect_true(is.list(combined$tags), info = "Combined data.table should have consistent list column")
  expect_equal(combined$tags[[1]], list("stock"))
  expect_equal(combined$tags[[2]], list("stock", "etf"))
})

# ---------------------------------------------------------------------------
# Bug #10: close_all_positions doesn't unwrap nested body field
# The API returns [{symbol, status, body: {order details...}}]
# The parser should extract the body contents.
# ---------------------------------------------------------------------------
test_that("close_all_positions unwraps nested body field", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://paper-api.alpaca.markets"

  account <- AlpacaAccount$new(keys = keys, base_url = BASE)

  # Alpaca returns this structure for DELETE /v2/positions
  mock_data <- list(
    list(
      symbol = "AAPL",
      status = 200L,
      body = list(
        id = "order-123",
        client_order_id = "client-123",
        created_at = "2024-01-15T14:30:00Z",
        symbol = "AAPL",
        qty = "10",
        side = "sell",
        type = "market",
        status = "accepted"
      )
    ),
    list(
      symbol = "MSFT",
      status = 200L,
      body = list(
        id = "order-456",
        client_order_id = "client-456",
        created_at = "2024-01-15T14:30:00Z",
        symbol = "MSFT",
        qty = "5",
        side = "sell",
        type = "market",
        status = "accepted"
      )
    )
  )

  resp <- mock_alpaca_response(mock_data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- account$close_all_positions(cancel_orders = TRUE)
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)

  # The order details from body should be accessible as columns
  expect_true(
    "id" %in% names(dt) || "order_id" %in% names(dt),
    info = "Order details from body should be unwrapped into columns"
  )

  # The body field should NOT be an opaque list column
  if ("body" %in% names(dt)) {
    expect_false(is.list(dt$body), info = "body should be unwrapped, not left as a nested list column")
  }
})

# ---------------------------------------------------------------------------
# Bug #10 (variant): cancel_all_orders doesn't unwrap nested body field
# ---------------------------------------------------------------------------
test_that("cancel_all_orders unwraps nested body field", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://paper-api.alpaca.markets"

  trading <- AlpacaTrading$new(keys = keys, base_url = BASE)

  mock_data <- list(
    list(
      id = "order-123",
      status = 200L,
      body = list(
        id = "order-123",
        client_order_id = "client-123",
        created_at = "2024-01-15T14:30:00Z",
        symbol = "AAPL",
        qty = "10",
        side = "buy",
        type = "limit",
        status = "canceled"
      )
    )
  )

  resp <- mock_alpaca_response(mock_data)
  httr2::local_mocked_responses(function(req) resp)

  dt <- trading$cancel_all_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)

  # Order details from body should be accessible
  expect_true(
    "symbol" %in% names(dt) || "client_order_id" %in% names(dt),
    info = "Order details from body should be unwrapped"
  )

  if ("body" %in% names(dt)) {
    expect_false(is.list(dt$body), info = "body should be unwrapped, not left as a nested list column")
  }
})

# ---------------------------------------------------------------------------
# Bug #11: get_news() doesn't paste(collapse=",") for symbols parameter
# Passing a character vector should produce comma-separated, not repeated params.
# ---------------------------------------------------------------------------
test_that("get_news joins symbols with comma like other multi-symbol methods", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  BASE <- "https://paper-api.alpaca.markets"
  DATA_BASE <- "https://data.alpaca.markets"

  market <- AlpacaMarketData$new(keys = keys, base_url = BASE, data_base_url = DATA_BASE)

  captured_url <- NULL

  mock_news <- list(
    news = list(
      list(
        id = 1L,
        headline = "Test headline",
        author = "Test author",
        created_at = "2024-01-15T14:30:00Z",
        updated_at = "2024-01-15T14:30:00Z",
        summary = "Test summary",
        url = "https://example.com",
        source = "test",
        symbols = list("AAPL", "MSFT")
      )
    ),
    next_page_token = NULL
  )

  resp <- mock_alpaca_response(mock_news)
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    resp
  })

  market$get_news(symbols = c("AAPL", "MSFT"))

  # The URL should contain symbols=AAPL,MSFT (comma-separated)
  # NOT symbols=AAPL&symbols=MSFT (repeated params)
  expect_true(
    grepl("symbols=AAPL%2CMSFT", captured_url) ||
      grepl("symbols=AAPL,MSFT", captured_url),
    info = paste(
      "symbols should be comma-separated in URL, not repeated.",
      "Got URL:",
      captured_url
    )
  )
  expect_false(
    grepl("symbols=AAPL&symbols=MSFT", captured_url),
    info = "symbols should NOT appear as repeated query parameters"
  )
})

# ---------------------------------------------------------------------------
# Bug #12: alpaca_paginate() uses default 10s timeout instead of 30s
# ---------------------------------------------------------------------------
test_that("alpaca_paginate accepts and forwards custom timeout", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")

  mock_data <- list(
    news = list(
      list(id = 1L, headline = "Test")
    ),
    next_page_token = NULL
  )

  resp <- mock_alpaca_response(mock_data)

  captured_req <- NULL
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    resp
  })

  result <- alpaca:::alpaca_paginate(
    base_url = "https://data.alpaca.markets",
    endpoint = "/v1beta1/news",
    keys = keys,
    .perform = httr2::req_perform,
    timeout = 30,
    items_field = "news"
  )

  # Verify the timeout was set to 30s (30000ms), not the default 10s
  req_options <- captured_req$options
  timeout_val <- req_options$timeout_ms %||% (req_options$timeout * 1000)
  expect_equal(
    timeout_val,
    30000,
    info = "alpaca_paginate should forward timeout to build_request (30s, not default 10s)"
  )
})

# ---------------------------------------------------------------------------
# Bug #18 (alpaca): get_api_keys() returns empty strings without warning
# ---------------------------------------------------------------------------
test_that("get_api_keys warns when env vars are not set", {
  withr::local_envvar(ALPACA_API_KEY = "", ALPACA_API_SECRET = "")

  expect_warning(
    get_api_keys(),
    regexp = "API|key|secret|credential|not set|missing|empty",
    ignore.case = TRUE,
    info = "get_api_keys should warn when env vars return empty strings"
  )
})
