# Live integration tests — private endpoints (account, trading, positions).
#
# Run with:
#   ALPACA_LIVE_TESTS=true Rscript --vanilla -e 'devtools::test(filter = "live")'
#
# These tests hit the real Alpaca API with authenticated requests.
# They are skipped by default. Use paper trading credentials only!
#
# IMPORTANT: These tests use PAPER TRADING. Never use live credentials.
# Order-placing tests rest a non-marketable limit order on a symbol the account
# holds no position/order in (to avoid a wash-trade self-cross) and cancel it
# immediately; they skip gracefully if the broker still flags a wash trade.

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

# ---- Wash-trade-safe order helpers ----
#
# The paper account may already hold a position or a resting order in a given
# symbol; a fresh order on that same symbol can be rejected with
# "403 ... potential wash trade detected" (a self-cross). These helpers pick a
# liquid symbol the account is NOT currently exposed to, and skip the test
# gracefully if the broker still flags a wash trade -- so the suite is never red
# purely from transient account state.

.held_symbols <- function() {
  held <- character(0)
  pos <- tryCatch(acct$get_positions(), error = function(e) NULL)
  if (!is.null(pos) && nrow(pos) > 0) {
    held <- c(held, pos$symbol)
  }
  ords <- tryCatch(trading$get_orders(status = "open", limit = 500), error = function(e) NULL)
  if (!is.null(ords) && nrow(ords) > 0) {
    held <- c(held, ords$symbol)
  }
  return(unique(held))
}

# Liquid large-caps, all priced far above the $1 resting limit below, so the
# order never becomes marketable (rests, never fills).
.throwaway_candidates <- c(
  "F", "T", "INTC", "PFE", "KO", "CSCO", "BAC", "VZ", "SBUX", "HPQ", "MU", "KEY"
)

# Return `n` liquid symbols the account currently holds no position or open
# order in; skip the test if not enough are free (rather than risk a self-cross).
.pick_throwaway_symbols <- function(n = 1) {
  free <- setdiff(.throwaway_candidates, .held_symbols())
  if (length(free) < n) {
    testthat::skip(sprintf(
      "Need %d throwaway symbol(s) free of current positions/orders; none available — skipping to avoid a wash-trade self-cross.",
      n
    ))
  }
  return(free[seq_len(n)])
}

# Place a resting, non-marketable buy limit order on `symbol`; skip (not fail)
# if the broker still rejects it as a potential wash trade from account state.
.add_resting_order_or_skip <- function(symbol, ...) {
  return(tryCatch(
    trading$add_order(
      symbol = symbol,
      side = "buy",
      type = "limit",
      time_in_force = "day",
      qty = 1,
      limit_price = 1.00,
      ...
    ),
    error = function(e) {
      if (grepl("wash trade", conditionMessage(e), ignore.case = TRUE)) {
        testthat::skip(paste(
          "Broker rejected the order as a potential wash trade (account state):",
          conditionMessage(e)
        ))
      }
      stop(e)
    }
  ))
}

test_that("[LIVE] get_orders returns data.table of orders", {
  dt <- trading$get_orders(status = "all", limit = 5)
  expect_s3_class(dt, "data.table")
  throttle()
})

test_that("[LIVE] place and immediately cancel a limit order", {
  # Use a symbol the account holds no position/order in, so a buy can't
  # self-cross into a wash-trade rejection. Limit far below market — won't fill.
  sym <- .pick_throwaway_symbols(1)
  order <- .add_resting_order_or_skip(sym)
  expect_s3_class(order, "data.table")
  expect_equal(nrow(order), 1)
  expect_true(order$symbol == sym)
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
  # Two resting orders on symbols the account isn't exposed to (no self-cross).
  syms <- .pick_throwaway_symbols(2)
  .add_resting_order_or_skip(syms[1])
  throttle()
  .add_resting_order_or_skip(syms[2])
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

  # Place order with custom client_order_id on a non-exposed symbol.
  sym <- .pick_throwaway_symbols(1)
  order <- .add_resting_order_or_skip(sym, client_order_id = client_id)
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
