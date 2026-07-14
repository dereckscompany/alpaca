# Type-fidelity NA audit (dereckscompany/.github discussion #2).
#
# Each measurement / venue-optional column Alpaca documents optional must (1) be
# emitted as a TYPED NA when the venue returns null -- never a bare logical NA,
# which would fail the column's own `assert_<type>()` -- and (2) satisfy the
# generated `@return` contract, which no longer carries `assert_no_missing_values`
# for that column. Before the audit these rows aborted the connector mid-run.

# Set the named fields of a parsed JSON body to JSON `null` (present-but-NULL).
# `[<-` with `list(NULL)` keeps the element (unlike `[[<-`, which drops it), so
# the parser sees the field and realises it as NA.
set_null <- function(body, fields) {
  for (f in fields) {
    body[f] <- list(NULL)
  }
  return(body)
}

# ---- Position (mark-derived measurements) ----

test_that("parse_position emits typed NA for null mark-derived measurements", {
  raw <- set_null(.fx("position"), POSITION_NULLABLE_MEASUREMENT_COLS)
  dt <- parse_position(raw)

  for (col in POSITION_NULLABLE_MEASUREMENT_COLS) {
    expect_true(is.character(dt[[col]]), info = col)
    expect_true(is.na(dt[[col]]), info = col)
  }
  # Structural columns are untouched.
  expect_identical(dt$symbol, "AAPL")
  expect_identical(dt$side, "long")
  # The live single-position contract accepts the NA row (aborted pre-audit).
  expect_no_error(assert_return_AlpacaAccount__get_position(dt))
})

test_that("parse_positions emits typed NA across a list of positions", {
  items <- lapply(.fx("positions"), set_null, fields = POSITION_NULLABLE_MEASUREMENT_COLS)
  dt <- parse_positions(items)

  for (col in POSITION_NULLABLE_MEASUREMENT_COLS) {
    expect_true(is.character(dt[[col]]), info = col)
    expect_true(all(is.na(dt[[col]])), info = col)
  }
  expect_no_error(assert_return_AlpacaAccount__get_positions(dt))
})

# ---- Account (balance / margin measurements) ----

test_that("parse_account emits typed NA for null balance/margin measurements", {
  raw <- set_null(.fx("account"), ACCOUNT_NULLABLE_MEASUREMENT_COLS)
  dt <- parse_account(raw)

  for (col in ACCOUNT_NULLABLE_MEASUREMENT_COLS) {
    expect_true(is.character(dt[[col]]), info = col)
    expect_true(is.na(dt[[col]]), info = col)
  }
  # Identity / status columns and the strict multiplier are untouched.
  expect_false(is.na(dt$status))
  expect_false(is.na(dt$multiplier))
  expect_no_error(assert_return_AlpacaAccount__get_account(dt))
})

# ---- Order (mleg parent / notional order) ----

test_that("parse_order emits typed NA for a multi-leg-parent / notional order", {
  raw <- set_null(.fx("order"), c("symbol", "side", "type", "qty"))
  dt <- parse_order(raw)

  for (col in c("symbol", "side", "type", "qty")) {
    expect_true(is.character(dt[[col]]), info = col)
    expect_true(is.na(dt[[col]]), info = col)
  }
  # id / status stay strict.
  expect_false(is.na(dt$id))
  expect_false(is.na(dt$status))
  expect_no_error(assert_return_AlpacaTrading__get_order(dt))
})

# ---- Asset (optional name) ----

test_that("parse_asset emits typed NA for a null asset name", {
  raw <- set_null(.fx("asset"), "name")
  dt <- parse_asset(raw)

  expect_true(is.character(dt$name))
  expect_true(is.na(dt$name))
  expect_no_error(assert_return_AlpacaMarketData__get_asset(dt))
})

# ---- Trade (optional exchange / tape) ----

test_that("parse_trades tolerates missing exchange / tape (venue-optional)", {
  trades <- list(
    list(t = "2024-01-15T14:30:00Z", p = 185.5, s = 100L, x = "V", z = "C", i = 1L, c = list("@")),
    list(t = "2024-01-15T14:30:01Z", p = 185.6, s = 50L, i = 2L, c = list("@"))
  )
  dt <- parse_trades(trades)

  expect_true(is.character(dt$exchange))
  expect_true(is.character(dt$tape))
  expect_true(is.na(dt$exchange[2]))
  expect_true(is.na(dt$tape[2]))
  expect_no_error(assert_return_AlpacaMarketData__get_latest_trade(dt))
})

# ---- Quote (optional ask/bid exchange, tape) ----

test_that("parse_quotes tolerates missing ask/bid exchange and tape", {
  q_full <- list(t = "2024-01-15T14:30:00Z", ax = "V", ap = 185.55, bx = "Q", bp = 185.5, z = "C", c = list("R"))
  q_full[["as"]] <- 200L
  q_full[["bs"]] <- 300L
  q_bare <- list(t = "2024-01-15T14:30:01Z", ap = 185.6, bp = 185.4, c = list("R"))
  q_bare[["as"]] <- 100L
  q_bare[["bs"]] <- 150L
  dt <- parse_quotes(list(q_full, q_bare))

  for (col in c("ask_exchange", "bid_exchange", "tape")) {
    expect_true(is.character(dt[[col]]), info = col)
    expect_true(is.na(dt[[col]][2]), info = col)
  }
  expect_no_error(assert_return_AlpacaMarketData__get_latest_quote(dt))
})

# ---- Bars (optional vwap / trade_count) ----

test_that("parse_bars tolerates missing vwap / trade_count", {
  bars <- list(
    list(t = "2024-01-15T14:30:00Z", o = 185.4, h = 185.6, l = 185.3, c = 185.5, v = 5000L, n = 50L, vw = 185.45),
    list(t = "2024-01-15T14:31:00Z", o = 185.5, h = 185.7, l = 185.4, c = 185.6, v = 4000L)
  )
  dt <- parse_bars(bars)

  expect_true(is.numeric(dt$vwap))
  expect_true(is.numeric(dt$trade_count))
  expect_true(is.na(dt$vwap[2]))
  expect_true(is.na(dt$trade_count[2]))
  expect_no_error(assert_return_AlpacaMarketData__get_bars(dt))
})

# ---- Corporate actions (optional announcement dates / target_symbol) ----

test_that("get_corporate_actions tolerates null announcement dates and target_symbol", {
  keys <- get_api_keys(api_key = "k", api_secret = "s")
  body <- lapply(
    .fx("corporate_actions"),
    set_null,
    fields = c("declaration_date", "ex_date", "record_date", "payable_date", "target_symbol")
  )
  resp <- mock_alpaca_response(body)
  httr2::local_mocked_responses(function(req) resp)

  dt <- suppressWarnings(
    AlpacaMarketData$new(keys = keys, base_url = "https://paper-api.alpaca.markets")$get_corporate_actions(
      ca_types = "dividend",
      since = "2024-01-01",
      until = "2024-03-31"
    )
  )
  for (col in c("declaration_date", "ex_date", "record_date", "payable_date")) {
    expect_s3_class(dt[[col]], "Date")
    expect_true(all(is.na(dt[[col]])), info = col)
  }
  expect_true(is.character(dt$target_symbol))
  expect_true(all(is.na(dt$target_symbol)))
})
