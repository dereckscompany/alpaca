# Live integration tests — private endpoints (account, trading, positions).
#
# Run with:
#   ALPACA_LIVE_TESTS=true Rscript --vanilla -e 'devtools::test(filter = "live")'
#
# These tests hit the real Alpaca API with authenticated requests.
# They are skipped by default. Use paper trading credentials only!
#
# IMPORTANT: These tests use PAPER TRADING. Never use live credentials.
# Order tests are read-only (get_orders) or use cancel immediately.

skip_if_not(
  identical(Sys.getenv("ALPACA_LIVE_TESTS"), "true"),
  "Live API tests skipped (set ALPACA_LIVE_TESTS=true to run)"
)

.api_key <- Sys.getenv("ALPACA_API_KEY", "")
.api_secret <- Sys.getenv("ALPACA_API_SECRET", "")

skip_if(
  .api_key == "" || .api_secret == "",
  "No API keys configured (set ALPACA_API_KEY + ALPACA_API_SECRET)"
)

.keys <- get_api_keys(api_key = .api_key, api_secret = .api_secret)

# Verify we're on paper trading — never run destructive tests on live
.base_url <- get_base_url()
skip_if_not(
  grepl("paper", .base_url, ignore.case = TRUE),
  paste0("Refusing to run private tests on non-paper URL: ", .base_url)
)

throttle <- function() Sys.sleep(0.3)

# ---- Account ----

acct <- AlpacaAccount$new(keys = .keys, base_url = .base_url)

test_that("[LIVE] get_account returns account info with margin fields", {
  dt <- acct$get_account()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_true(all(c("status", "equity", "buying_power", "cash") %in% names(dt)))
  expect_equal(dt$status, "ACTIVE")
  throttle()
})

test_that("[LIVE] get_account includes margin and short fields", {
  dt <- acct$get_account()
  expect_true(all(
    c(
      "initial_margin",
      "maintenance_margin",
      "long_market_value",
      "short_market_value",
      "daytrading_buying_power",
      "multiplier"
    ) %in%
      names(dt)
  ))
  throttle()
})

# ---- Positions ----

test_that("[LIVE] get_positions returns data.table", {
  dt <- acct$get_positions()
  expect_s3_class(dt, "data.table")
  # May be empty if no open positions
  if (nrow(dt) > 0) {
    expect_true(all(c("symbol", "qty", "side", "market_value") %in% names(dt)))
  }
  throttle()
})

# ---- Portfolio History ----

test_that("[LIVE] get_portfolio_history returns time series", {
  dt <- acct$get_portfolio_history(period = "1W", timeframe = "1D")
  expect_s3_class(dt, "data.table")
  expect_gt(nrow(dt), 0)
  expect_true(all(c("timestamp", "equity", "profit_loss") %in% names(dt)))
  expect_s3_class(dt$timestamp, "POSIXct")
  throttle()
})

# ---- Activities ----

test_that("[LIVE] get_activities returns data.table", {
  dt <- acct$get_activities(page_size = 5)
  expect_s3_class(dt, "data.table")
  # May be empty for new accounts
  throttle()
})

# ---- Trading: Orders ----

trading <- AlpacaTrading$new(keys = .keys, base_url = .base_url)

test_that("[LIVE] get_orders returns data.table of orders", {
  dt <- trading$get_orders(status = "all", limit = 5)
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] place and immediately cancel a limit order", {
  # Place a limit order far from market price (won't fill)
  order <- trading$add_order(
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 1.00 # Far below market — won't execute
  )
  expect_s3_class(order, "data.table")
  expect_equal(nrow(order), 1)
  expect_true(order$symbol == "AAPL")
  expect_true(order$side == "buy")

  throttle()

  # Cancel it immediately
  trading$cancel_order(order$id)
  throttle()

  # Verify it was cancelled
  cancelled <- trading$get_order(order$id)
  # Status should be "canceled" or "pending_cancel"
  expect_true(cancelled$status %in% c("canceled", "pending_cancel", "cancelled"))
  throttle()
})

test_that("[LIVE] cancel_all_orders works", {
  # Place two cheap orders
  trading$add_order(
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 1.00
  )
  throttle()
  trading$add_order(
    symbol = "MSFT",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 1.00
  )
  throttle()

  # Cancel all
  result <- trading$cancel_all_orders()
  expect_s3_class(result, "data.table")

  # Wait for cancellations to propagate
  Sys.sleep(1)

  # Verify no open orders remain
  open <- trading$get_orders(status = "open")
  expect_equal(nrow(open), 0)
  throttle()
})

# ---- Watchlists ----

test_that("[LIVE] watchlist CRUD lifecycle", {
  # Use unique name to avoid conflicts from previous failed runs
  wl_name <- paste0("Test WL ", format(Sys.time(), "%H%M%S"))
  updated_name <- paste0("Updated WL ", format(Sys.time(), "%H%M%S"))

  # Clean up any leftover test watchlists first
  existing <- acct$get_watchlists()
  if (nrow(existing) > 0) {
    old_wl <- existing[grepl("^(Test|Updated) WL", existing$name), ]
    if (nrow(old_wl) > 0) {
      for (old_id in old_wl$id) {
        tryCatch(acct$cancel_watchlist(old_id), error = function(e) NULL)
        throttle()
      }
    }
  }

  # Create — long format: one row per asset
  wl <- acct$add_watchlist(wl_name, symbols = c("AAPL", "MSFT"))
  expect_s3_class(wl, "data.table")
  expect_equal(unique(wl$name), wl_name)
  wl_id <- wl$id[1]
  throttle()

  # Read
  all_wl <- acct$get_watchlists()
  expect_s3_class(all_wl, "data.table")
  expect_true(wl_id %in% all_wl$id)
  throttle()

  # Get single — long format: one row per asset
  single <- acct$get_watchlist(wl_id)
  expect_equal(unique(single$name), wl_name)
  throttle()

  # Add symbol
  updated <- acct$add_watchlist_symbol(wl_id, "GOOGL")
  expect_s3_class(updated, "data.table")
  throttle()

  # Remove symbol
  acct$cancel_watchlist_symbol(wl_id, "MSFT")
  throttle()

  # Update — long format: one row per asset
  modified <- acct$modify_watchlist(wl_id, name = updated_name, symbols = c("AAPL", "GOOGL", "NVDA"))
  expect_equal(unique(modified$name), updated_name)
  throttle()

  # Delete
  acct$cancel_watchlist(wl_id)
  throttle()

  # Verify deleted
  all_wl2 <- acct$get_watchlists()
  if (nrow(all_wl2) > 0) {
    expect_false(wl_id %in% all_wl2$id)
  }
  throttle()
})

# ---- Account Config ----

test_that("[LIVE] get_account_config returns configuration", {
  dt <- acct$get_account_config()
  expect_s3_class(dt, "data.table")
  expect_equal(nrow(dt), 1)
  expect_true(all(c("dtbp_check", "no_shorting", "fractional_trading") %in% names(dt)))
  throttle()
})

test_that("[LIVE] modify_account_config round-trips correctly", {
  # Get current config
  original <- acct$get_account_config()
  throttle()

  # Toggle trade_confirm_email and toggle back
  current_email <- original$trade_confirm_email
  new_email <- if (identical(current_email, "all")) "none" else "all"

  modified <- acct$modify_account_config(trade_confirm_email = new_email)
  expect_s3_class(modified, "data.table")
  expect_equal(modified$trade_confirm_email, new_email)
  throttle()

  # Restore original
  acct$modify_account_config(trade_confirm_email = current_email)
  throttle()
})

# ---- Order by Client ID ----

test_that("[LIVE] get_order_by_client_id retrieves order", {
  client_id <- paste0("test-", format(Sys.time(), "%H%M%S"), "-", sample(1000:9999, 1))

  # Place order with custom client_order_id
  order <- trading$add_order(
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = 1,
    limit_price = 1.00,
    client_order_id = client_id
  )
  expect_equal(order$client_order_id, client_id)
  throttle()

  # Retrieve by client_order_id
  found <- trading$get_order_by_client_id(client_id)
  expect_s3_class(found, "data.table")
  expect_equal(nrow(found), 1)
  expect_equal(found$client_order_id, client_id)
  expect_equal(found$id, order$id)
  throttle()

  # Clean up
  trading$cancel_order(order$id)
  throttle()
})
