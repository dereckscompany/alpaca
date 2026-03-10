KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"

new_trading <- function() {
  AlpacaTrading$new(keys = KEYS, base_url = BASE)
}

test_that("AlpacaTrading inherits from AlpacaBase", {
  trading <- new_trading()
  expect_s3_class(trading, "AlpacaTrading")
  expect_s3_class(trading, "AlpacaBase")
})

test_that("add_order returns order data.table", {
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 150
  )
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$id, "order-uuid-123")
  expect_equal(dt$symbol, "AAPL")
  expect_equal(dt$status, "accepted")
})

test_that("add_order sends POST to /v2/orders", {
  captured_req <- NULL
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  new_trading()$add_order(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 1
  )

  expect_equal(captured_req$method, "POST")
  expect_true(grepl("/v2/orders", captured_req$url))
})

test_that("get_orders returns data.table", {
  resp <- mock_alpaca_response(mock_orders_list_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 2L)
})

test_that("get_order returns single-row data.table", {
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order("order-uuid-123")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$id, "order-uuid-123")
})

test_that("cancel_order returns empty data.table on 204", {
  resp <- mock_no_content_response()
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order("order-uuid-123")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 0L)
})

test_that("cancel_all_orders returns data.table", {
  resp <- mock_alpaca_response(list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_all_orders()
  expect_s3_class(dt, "data.table")
})

test_that("modify_order sends PATCH request", {
  captured_req <- NULL
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  new_trading()$modify_order("order-uuid-123", limit_price = 155)
  expect_equal(captured_req$method, "PATCH")
  expect_true(grepl("order-uuid-123", captured_req$url))
})

test_that("get_order_by_client_id returns single-row data.table", {
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order_by_client_id("client-123")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$id, "order-uuid-123")
})

test_that("get_order_by_client_id uses correct endpoint", {
  captured_url <- NULL
  resp <- mock_alpaca_response(mock_order_response())
  httr2::local_mocked_responses(function(req) {
    captured_url <<- req$url
    return(resp)
  })

  new_trading()$get_order_by_client_id("my-client-id")
  expect_true(grepl("orders:by_client_order_id", captured_url))
  expect_true(grepl("client_order_id=my-client-id", captured_url))
})
