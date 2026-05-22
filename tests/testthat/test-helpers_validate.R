test_that("validate_order_params accepts valid market order with qty", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 1
  )
  expect_equal(params$symbol, "AAPL")
  expect_equal(params$side, "buy")
  expect_equal(params$qty, "1")
})

test_that("validate_order_params accepts valid market order with notional", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    notional = 500
  )
  expect_equal(params$notional, "500")
  expect_null(params$qty)
})

test_that("validate_order_params rejects market order with both qty and notional", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "market",
      time_in_force = "day",
      qty = 1,
      notional = 500
    ),
    "mutually exclusive"
  )
})

test_that("validate_order_params rejects market order without qty or notional", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "market",
      time_in_force = "day"
    ),
    "qty.*notional"
  )
})

test_that("validate_order_params accepts valid limit order", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 150
  )
  expect_equal(params$limit_price, "150")
  expect_equal(params$type, "limit")
})

test_that("validate_order_params rejects limit order without limit_price", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "limit",
      time_in_force = "day",
      qty = 1
    ),
    "limit_price.*required"
  )
})

test_that("validate_order_params accepts valid stop order", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "sell",
    type = "stop",
    time_in_force = "gtc",
    qty = 10,
    stop_price = 140
  )
  expect_equal(params$stop_price, "140")
})

test_that("validate_order_params accepts valid stop-limit order", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "sell",
    type = "stop_limit",
    time_in_force = "gtc",
    qty = 10,
    stop_price = 140,
    limit_price = 139
  )
  expect_equal(params$stop_price, "140")
  expect_equal(params$limit_price, "139")
})

test_that("validate_order_params rejects stop-limit without limit_price", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "sell",
      type = "stop_limit",
      time_in_force = "gtc",
      qty = 10,
      stop_price = 140
    ),
    "limit_price.*required"
  )
})

test_that("validate_order_params accepts trailing stop with trail_percent", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "sell",
    type = "trailing_stop",
    time_in_force = "gtc",
    qty = 10,
    trail_percent = 5
  )
  expect_equal(params$trail_percent, "5")
})

test_that("validate_order_params rejects trailing stop with both trail params", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "sell",
      type = "trailing_stop",
      time_in_force = "gtc",
      qty = 10,
      trail_price = 5,
      trail_percent = 5
    ),
    "mutually exclusive"
  )
})

test_that("validate_order_params rejects invalid side", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "hold",
      type = "market",
      time_in_force = "day",
      qty = 1
    )
  )
})

test_that("validate_order_params rejects invalid type", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "foobar",
      time_in_force = "day",
      qty = 1
    )
  )
})

test_that("validate_order_params rejects empty symbol", {
  expect_error(
    validate_order_params(
      symbol = "",
      side = "buy",
      type = "market",
      time_in_force = "day",
      qty = 1
    ),
    "non-empty"
  )
})

test_that("validate_order_params validates order_class", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "market",
      time_in_force = "day",
      qty = 1,
      order_class = "invalid"
    )
  )
})

test_that("validate_order_params validates position_intent", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 1,
    position_intent = "buy_to_open"
  )
  expect_equal(params$position_intent, "buy_to_open")
})

test_that("validate_order_params rejects long client_order_id", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "market",
      time_in_force = "day",
      qty = 1,
      client_order_id = paste(rep("a", 129), collapse = "")
    ),
    "128 characters"
  )
})

test_that("validate_order_params removes NULLs from output", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 1
  )
  expect_false(any(vapply(params, is.null, logical(1))))
})

# ---- mleg (multi-leg options) order class -----------------------------------

test_that("validate_order_params accepts mleg orders without top-level symbol/side", {
  legs <- list(
    list(symbol = "AAPL250620C00200000", side = "buy", ratio_qty = "1", position_intent = "buy_to_open"),
    list(symbol = "AAPL250620C00210000", side = "sell", ratio_qty = "1", position_intent = "sell_to_open")
  )
  params <- validate_order_params(
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 0.5,
    order_class = "mleg",
    legs = legs
  )
  expect_equal(params$order_class, "mleg")
  expect_equal(length(params$legs), 2L)
  expect_null(params$symbol)
  expect_null(params$side)
})

test_that("validate_order_params rejects mleg orders without legs", {
  expect_error(
    validate_order_params(
      type = "limit",
      time_in_force = "day",
      qty = 1,
      limit_price = 0.5,
      order_class = "mleg"
    ),
    "legs.*required"
  )
})

test_that("validate_order_params rejects mleg orders with more than 4 legs", {
  five_legs <- replicate(5, list(symbol = "X", side = "buy", ratio_qty = "1"), simplify = FALSE)
  expect_error(
    validate_order_params(
      type = "limit",
      time_in_force = "day",
      qty = 1,
      limit_price = 0.5,
      order_class = "mleg",
      legs = five_legs
    ),
    "at most 4"
  )
})

test_that("validate_order_params normalises order_class case", {
  legs <- list(list(symbol = "X", side = "buy", ratio_qty = "1"))
  params <- validate_order_params(
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 0.5,
    order_class = "MLEG",
    legs = legs
  )
  expect_equal(params$order_class, "mleg")
})

test_that("validate_order_params treats empty order_class as NULL", {
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 1,
    order_class = ""
  )
  expect_null(params$order_class)
})

test_that("validate_order_params passes advanced_instructions through", {
  ai <- list(routing = "elite")
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 1,
    advanced_instructions = ai
  )
  expect_equal(params$advanced_instructions, ai)
})

# ---- non-mleg argument errors -----------------------------------------------

test_that("validate_order_params rejects non-mleg order with NULL side", {
  expect_error(
    validate_order_params(
      symbol = "AAPL",
      side = NULL,
      type = "market",
      time_in_force = "day",
      qty = 1
    ),
    "side.*buy.*sell"
  )
})

test_that("validate_order_params rejects non-mleg order with NULL symbol", {
  expect_error(
    validate_order_params(
      symbol = NULL,
      side = "buy",
      type = "market",
      time_in_force = "day",
      qty = 1
    ),
    "symbol.*non-empty"
  )
})
