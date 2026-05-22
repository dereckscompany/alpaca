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
  # Simple order: leg_index and parent_order_id are NA (parent row only).
  expect_true(is.na(dt$leg_index))
  expect_true(is.na(dt$parent_order_id))
})

# ---- Bracket orders: parent row + leg rows -------------------------------

test_that("add_order on a bracket returns one parent row + N leg rows", {
  resp <- mock_alpaca_response(mock_bracket_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$add_order(
    symbol = "AAPL", side = "buy", type = "limit",
    time_in_force = "gtc", qty = 1, limit_price = 1,
    order_class = "bracket",
    take_profit = list(limit_price = 500),
    stop_loss = list(stop_price = 0.5, limit_price = 0.4)
  )

  # Two legs → three rows: parent + take-profit + stop-loss.
  expect_equal(nrow(dt), 3L)

  parents <- dt[is.na(parent_order_id)]
  expect_equal(nrow(parents), 1L)
  expect_equal(parents$id, "bracket-parent")
  expect_true(is.na(parents$leg_index))

  legs <- dt[!is.na(parent_order_id)]
  expect_equal(nrow(legs), 2L)
  expect_setequal(legs$parent_order_id, "bracket-parent")
  expect_equal(legs$leg_index, c(1L, 2L))
  expect_equal(legs$id, c("leg-tp", "leg-sl"))
  # Legs carry their own field values, not the parent's.
  expect_equal(legs$side, c("sell", "sell"))
  expect_equal(legs[leg_index == 1L]$limit_price, "500.00")
  expect_equal(legs[leg_index == 2L]$stop_price,  "0.50")
})

test_that("get_order on a bracket exposes parent + legs via parent_order_id", {
  resp <- mock_alpaca_response(mock_bracket_order_response())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_order("bracket-parent")
  expect_equal(nrow(dt), 3L)

  # User-facing query patterns documented in @return:
  parent_only <- dt[is.na(parent_order_id)]
  expect_equal(nrow(parent_only), 1L)

  bracket_legs <- dt[parent_order_id == "bracket-parent"]
  expect_equal(nrow(bracket_legs), 2L)
})

test_that("get_orders rbinds simple + bracket orders into a single flat table", {
  # Mock a list of two orders: one simple, one bracket. The result should
  # be 1 (simple) + 1 (parent) + 2 (legs) = 4 rows.
  resp <- mock_alpaca_response(list(
    mock_order_response(),
    mock_bracket_order_response()
  ))
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$get_orders()
  expect_equal(nrow(dt), 4L)
  expect_equal(sum(is.na(dt$parent_order_id)), 2L)  # simple + bracket-parent
  expect_equal(sum(!is.na(dt$parent_order_id)), 2L) # 2 legs
})

test_that("parse_order returns no list columns even with legs", {
  dt <- parse_order(mock_bracket_order_response())
  list_cols <- names(dt)[vapply(dt, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
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

test_that("cancel_order returns confirmation data.table on 204", {
  resp <- mock_no_content_response()
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_order("order-uuid-123")
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$order_id, "order-uuid-123")
  expect_equal(dt$status, "cancelled")
})

test_that("cancel_all_orders returns confirmation dt when no orders", {
  resp <- mock_alpaca_response(list())
  httr2::local_mocked_responses(function(req) resp)

  dt <- new_trading()$cancel_all_orders()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1L)
  expect_equal(dt$status, "cancelled")
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
