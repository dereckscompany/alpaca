# Typed Alpaca input-validation conditions. Every non-transport abort is raised
# through abort_alpaca_validation_error(), classed c("alpaca_validation_error",
# "alpaca_error") -- alpaca_error is the connector's DOMAIN root, parallel to the
# transport connectcore_error root. The message strings stay byte-identical to
# the bare rlang::abort() calls each site replaced (the goldens below pin that).
# If a golden fails, the backward-compatibility contract broke.

test_that("abort_alpaca_validation_error layers alpaca_validation_error then alpaca_error", {
  err <- tryCatch(alpaca:::abort_alpaca_validation_error("boom"), error = function(e) e)
  expect_identical(
    class(err),
    c("alpaca_validation_error", "alpaca_error", "rlang_error", "error", "condition")
  )
  expect_identical(conditionMessage(err), "boom")
})

test_that("alpaca_validation_error is caught by the alpaca_error root but is NOT a transport error", {
  caught <- tryCatch(alpaca:::abort_alpaca_validation_error("x"), alpaca_error = function(e) "root")
  expect_identical(caught, "root")
  err <- tryCatch(alpaca:::abort_alpaca_validation_error("x"), error = function(e) e)
  expect_false(inherits(err, "connectcore_error"))
})

# ---- Real sites: class, and byte-identical message (golden) ----

test_that("validate_order_params rejects qty + notional with alpaca_validation_error (golden)", {
  err <- tryCatch(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "market",
      time_in_force = "day",
      qty = 1,
      notional = 500
    ),
    error = function(e) e
  )
  expect_s3_class(err, "alpaca_validation_error")
  expect_s3_class(err, "alpaca_error")
  expect_identical(conditionMessage(err), "Parameters 'qty' and 'notional' are mutually exclusive.")
})

test_that("validate_order_params rejects a limit order without limit_price with alpaca_validation_error (golden)", {
  err <- tryCatch(
    validate_order_params(
      symbol = "AAPL",
      side = "buy",
      type = "limit",
      time_in_force = "day",
      qty = 1
    ),
    error = function(e) e
  )
  expect_s3_class(err, "alpaca_validation_error")
  expect_s3_class(err, "alpaca_error")
  expect_identical(conditionMessage(err), "Parameter 'limit_price' is required for limit orders.")
})
