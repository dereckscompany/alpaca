# tests/testthat/test-data-integrity.R
# Tests that expose data integrity risks in parsing.
# These test the parsers directly with deliberately malformed or edge-case data
# to surface silent corruption, NA injection, and misalignment.

# -- fill = TRUE silently introduces NA columns when records have different fields --

test_that("as_dt_list with heterogeneous records produces NA columns", {
  # Simulates mixing equity + option positions, or API version changes
  items <- list(
    list(symbol = "AAPL", price = "185.50", asset_class = "us_equity"),
    list(
      symbol = "AAPL240621C00200000",
      price = "5.50",
      asset_class = "us_option",
      greeks_delta = 0.65,
      greeks_gamma = 0.03
    )
  )
  dt <- as_dt_list(items)

  # fill = TRUE means the equity row gets NA for greeks columns
  # This test documents the current (dangerous) behavior
  expect_equal(nrow(dt), 2L)
  expect_true("greeks_delta" %in% names(dt))
  expect_true(is.na(dt$greeks_delta[1])) # equity row has NA greeks
})

test_that("as_dt_list with completely disjoint records pads everything with NAs", {
  # Worst case: two records sharing no fields
  items <- list(
    list(a = 1, b = 2),
    list(c = 3, d = 4)
  )
  dt <- as_dt_list(items)

  expect_equal(nrow(dt), 2L)
  expect_equal(ncol(dt), 4L)
  # Every cell in each row that didn't have the field is NA
  expect_true(is.na(dt$a[2]))
  expect_true(is.na(dt$b[2]))
  expect_true(is.na(dt$c[1]))
  expect_true(is.na(dt$d[1]))
})

# -- parse_bars with inconsistent records --

test_that("parse_bars with a missing field in one bar produces NA", {
  bars <- list(
    list(t = "2024-01-02T05:00:00Z", o = 187, h = 188, l = 183, c = 185, v = 100L, n = 10L, vw = 185.5),
    list(t = "2024-01-03T05:00:00Z", o = 184, h = 185, l = 183, c = 184, v = 50L, n = 5L)
    # missing vw in second bar
  )
  dt <- parse_bars(bars)

  expect_equal(nrow(dt), 2L)
  expect_true("vwap" %in% names(dt))
  # Second row has NA vwap due to fill = TRUE
  expect_true(is.na(dt$vwap[2]))
})

# -- parse_trades with inconsistent records --

test_that("parse_trades with heterogeneous fields produces NAs", {
  # One trade has conditions, one doesn't (like mixing stock + crypto)
  trades <- list(
    list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L, x = "V", c = list("@"), z = "C", i = 1L),
    list(t = "2024-01-15T14:31:00Z", p = 186.00, s = 50L, i = 2L, tks = "B")
    # second trade has no x, c, z but has tks
  )
  dt <- parse_trades(trades)

  expect_equal(nrow(dt), 2L)
  # fill = TRUE creates NA values for missing fields
  expect_true(is.na(dt$exchange[2]))
  expect_true(is.na(dt$tape[2]))
  # tks is not in the name_map, so it stays as raw "tks" (not snake_cased)
  expect_true("tks" %in% names(dt))
  expect_true(is.na(dt$tks[1]))
})

# -- parse_quotes with heterogeneous fields produces NAs --

test_that("parse_quotes with heterogeneous fields produces NAs", {
  quotes <- list(
    list(
      t = "2024-01-15T14:30:00Z",
      ap = 185.55,
      `as` = 200L,
      bp = 185.50,
      bs = 300L,
      ax = "V",
      bx = "Q",
      c = list("R"),
      z = "C"
    ),
    list(t = "2024-01-15T14:31:00Z", ap = 186.00, `as` = 100L, bp = 185.90, bs = 150L)
    # second quote has no ax, bx, c, z
  )
  dt <- parse_quotes(quotes)

  expect_equal(nrow(dt), 2L)
  expect_true(is.na(dt$ask_exchange[2]))
  expect_true(is.na(dt$bid_exchange[2]))
  expect_true(is.na(dt$tape[2]))
})

# -- parse_snapshot applies name maps to nested fields --

test_that("parse_snapshot applies bar/trade/quote name maps to nested fields", {
  snapshot <- mock_snapshot_response()
  dt <- parse_snapshot(snapshot)

  expect_equal(nrow(dt), 1L)

  # Bar fields are expanded with descriptive names
  expect_true("daily_bar_open" %in% names(dt))
  expect_true("daily_bar_high" %in% names(dt))
  expect_true("minute_bar_vwap" %in% names(dt))

  # Trade fields are expanded
  expect_true("latest_trade_price" %in% names(dt))
  expect_true("latest_trade_size" %in% names(dt))

  # Quote fields are expanded
  expect_true("latest_quote_ask_price" %in% names(dt))
  expect_true("latest_quote_bid_price" %in% names(dt))

  # Raw abbreviations no longer exist
  expect_false("daily_bar_o" %in% names(dt))
  expect_false("daily_bar_h" %in% names(dt))
  expect_false("latest_trade_p" %in% names(dt))
  expect_false("latest_quote_ap" %in% names(dt))
})

# -- Portfolio history: simplifyVector = TRUE converts null to NA --

test_that("portfolio history with NA elements preserves alignment", {
  # Simulate data as it arrives with simplifyVector = TRUE:
  # JSON nulls become NA in atomic vectors directly
  data <- list(
    timestamp = c(1704067200L, 1704153600L, 1704240000L),
    equity = c(100000.0, NA, 99800.25), # null became NA
    profit_loss = c(0.0, 150.5, -200.25),
    profit_loss_pct = c(0.0, 0.001505, -0.002),
    base_value = 100000.0,
    timeframe = "1D"
  )

  dt <- data.table::data.table(
    timestamp = lubridate::as_datetime(as.integer(data$timestamp), tz = "UTC"),
    equity = as.numeric(data$equity),
    profit_loss = as.numeric(data$profit_loss),
    profit_loss_pct = as.numeric(data$profit_loss_pct)
  )

  expect_equal(nrow(dt), 3L)
  expect_equal(dt$equity[1], 100000.0)
  expect_true(is.na(dt$equity[2])) # NULL preserved as NA
  expect_equal(dt$equity[3], 99800.25) # correct value, not recycled
})

test_that("portfolio history with all NAs in equity preserves rows", {
  # Simulate data as it arrives with simplifyVector = TRUE
  data <- list(
    timestamp = c(1704067200L, 1704153600L),
    equity = c(NA_real_, NA_real_),
    profit_loss = c(0.0, 150.5),
    profit_loss_pct = c(0.0, 0.001505),
    base_value = 100000.0,
    timeframe = "1D"
  )

  dt <- data.table::data.table(
    timestamp = lubridate::as_datetime(as.integer(data$timestamp), tz = "UTC"),
    equity = as.numeric(data$equity),
    profit_loss = as.numeric(data$profit_loss),
    profit_loss_pct = as.numeric(data$profit_loss_pct)
  )

  # Rows preserved, equity is NA
  expect_equal(nrow(dt), 2L)
  expect_true(all(is.na(dt$equity)))
  expect_equal(dt$profit_loss[1], 0.0)
  expect_equal(dt$profit_loss[2], 150.5)
})

# -- name_map snake_cases unknown fields as fallback --

test_that("parse_trades snake_cases unknown fields not in name_map", {
  # Simulate Alpaca adding a new camelCase field in the future
  trades <- list(
    list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L, i = 1L, tks = "B")
  )
  dt <- parse_trades(trades)

  # "tks" is not in the name_map but is already lowercase — stays as "tks"
  expect_true("tks" %in% names(dt))
})

test_that("parse_bars snake_cases unknown camelCase fields", {
  bars <- list(
    list(
      t = "2024-01-02T05:00:00Z",
      o = 187,
      h = 188,
      l = 183,
      c = 185,
      v = 100L,
      n = 10L,
      vw = 185.5,
      newField = "surprise"
    )
  )
  dt <- parse_bars(bars)

  # "newField" is not in name_map but gets snake_cased as fallback
  expect_true("new_field" %in% names(dt))
  expect_false("newField" %in% names(dt))
})

# -- Exact column name assertions for parsers --

test_that("parse_bars returns exactly the expected columns", {
  bars <- list(
    list(t = "2024-01-02T05:00:00Z", o = 187, h = 188, l = 183, c = 185, v = 100L, n = 10L, vw = 185.5)
  )
  dt <- parse_bars(bars)

  expected_cols <- c("timestamp", "open", "high", "low", "close", "volume", "trade_count", "vwap")
  expect_equal(names(dt), expected_cols)
})

test_that("parse_trades returns exactly the expected columns for stock trades", {
  trades <- list(
    list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L, x = "V", c = list("@"), z = "C", i = 12345L)
  )
  dt <- parse_trades(trades)

  expected_cols <- c("timestamp", "price", "size", "exchange", "conditions", "tape", "id")
  expect_equal(names(dt), expected_cols)
})

test_that("parse_quotes returns exactly the expected columns for stock quotes", {
  quotes <- list(
    list(
      t = "2024-01-15T14:30:00Z",
      ax = "V",
      ap = 185.55,
      `as` = 200L,
      bx = "Q",
      bp = 185.50,
      bs = 300L,
      c = list("R"),
      z = "C"
    )
  )
  dt <- parse_quotes(quotes)

  expected_cols <- c(
    "timestamp",
    "ask_exchange",
    "ask_price",
    "ask_size",
    "bid_exchange",
    "bid_price",
    "bid_size",
    "conditions",
    "tape"
  )
  expect_equal(names(dt), expected_cols)
})

# -- No-NA assertions on well-formed data --

test_that("parse_bars produces zero NAs on complete data", {
  bars <- list(
    list(t = "2024-01-02T05:00:00Z", o = 187, h = 188, l = 183, c = 185, v = 100L, n = 10L, vw = 185.5),
    list(t = "2024-01-03T05:00:00Z", o = 184, h = 185, l = 183, c = 184, v = 50L, n = 5L, vw = 184.2)
  )
  dt <- parse_bars(bars)

  expect_equal(sum(is.na(dt)), 0L)
})

test_that("parse_trades produces zero NAs on complete stock data", {
  trades <- list(
    list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L, x = "V", c = list("@"), z = "C", i = 1L),
    list(t = "2024-01-15T14:31:00Z", p = 186.00, s = 50L, x = "Q", c = list("@"), z = "C", i = 2L)
  )
  dt <- parse_trades(trades)

  # conditions is a list-column, check non-list columns only
  non_list_cols <- names(dt)[!sapply(dt, is.list)]
  expect_equal(sum(is.na(dt[, ..non_list_cols])), 0L)
})

# -- Backfill resume with mismatched columns --

test_that("backfill CSV with old column names causes silent issues on resume", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  # Write a CSV with "wrong" column names (simulating old package version)
  old_data <- data.table::data.table(
    symbol = "AAPL",
    timeframe = "1Day",
    old_timestamp = "2024-01-02T05:00:00Z", # wrong column name
    open = 187.15,
    high = 188.44,
    low = 183.89,
    close = 185.64,
    volume = 82488700L
  )
  data.table::fwrite(old_data, outfile)

  # Now read it back and rbindlist with new data
  new_data <- data.table::data.table(
    symbol = "AAPL",
    timeframe = "1Day",
    timestamp = "2024-01-03T05:00:00Z", # correct column name
    open = 184.22,
    high = 185.88,
    low = 183.43,
    close = 184.25,
    volume = 58414500L
  )

  existing <- data.table::fread(outfile)
  combined <- data.table::rbindlist(list(existing, new_data), fill = TRUE)

  # Both old_timestamp and timestamp columns exist, with NAs cross-filled
  expect_true("old_timestamp" %in% names(combined))
  expect_true("timestamp" %in% names(combined))
  expect_true(is.na(combined$timestamp[1])) # old row missing new col
  expect_true(is.na(combined$old_timestamp[2])) # new row missing old col
  expect_equal(nrow(combined), 2L)
  expect_equal(ncol(combined), 9L) # 8 unique + 1 duplicate = 9 columns
})

# -- Type safety: what happens if API returns unexpected types --

test_that("as_dt_row with mixed types in same field across records", {
  # Simulate API returning a number in one record and a string in another
  items <- list(
    list(symbol = "AAPL", qty = 10),
    list(symbol = "MSFT", qty = "five") # wrong type
  )

  # rbindlist will coerce to a common type (character) silently
  dt <- as_dt_list(items)
  expect_equal(nrow(dt), 2L)
  # Both values become character due to coercion
  expect_type(dt$qty, "character")
  expect_equal(dt$qty[1], "10")
  expect_equal(dt$qty[2], "five")
})

# -- Name collision: API returns both short and long form of same field --

test_that("parse_trades with both p and price creates duplicate column names", {
  # If Alpaca ever returns both the short and long form of a field
  trades <- list(
    list(t = "2024-01-15T14:30:00Z", p = 185.50, price = 999.99, s = 100L, i = 1L)
  )
  dt <- parse_trades(trades)

  # "p" gets renamed to "price" by name_map, but "price" already exists
  # data.table allows duplicate names — second column becomes INACCESSIBLE by name
  expect_equal(sum(names(dt) == "price"), 2L)
  # dt$price only returns the FIRST "price" column (the renamed "p")
  expect_equal(dt$price[1], 185.50)
  # The real "price" = 999.99 is silently hidden
})

test_that("parse_bars with both o and open creates duplicate column names", {
  bars <- list(
    list(t = "2024-01-02T05:00:00Z", o = 187, open = 999, h = 188, l = 183, c = 185, v = 100L, n = 10L, vw = 185.5)
  )
  dt <- parse_bars(bars)

  # "o" renamed to "open", but "open" already exists
  expect_equal(sum(names(dt) == "open"), 2L)
})

# -- snake_case collision in as_dt_row --

test_that("as_dt_row with camelCase and snake_case of same name causes collision", {
  # API returns both fooBar and foo_bar
  item <- list(fooBar = 1, foo_bar = 2)
  dt <- as_dt_row(item)

  # Both become "foo_bar" after to_snake_case
  expect_equal(sum(names(dt) == "foo_bar"), 2L)
  # dt$foo_bar only returns first column
  expect_equal(dt$foo_bar[1], 1)
  # Second value (2) is inaccessible by name
})

# -- Snapshot with missing sections --

test_that("parse_snapshot with NULL sections omits those sections cleanly", {
  # Simulate API returning snapshot with missing latestTrade
  snapshot <- list(
    latestTrade = NULL,
    latestQuote = list(t = "2024-01-15T14:30:00Z", ap = 185.55, bp = 185.50),
    minuteBar = NULL,
    dailyBar = list(
      t = "2024-01-15T05:00:00Z",
      o = 184,
      h = 186,
      l = 183,
      c = 185,
      v = 50000000L,
      n = 500000L,
      vw = 185.0
    ),
    prevDailyBar = NULL
  )
  dt <- parse_snapshot(snapshot)

  expect_equal(nrow(dt), 1L)
  # Only latestQuote and dailyBar columns exist — with expanded names
  expect_true("latest_quote_ask_price" %in% names(dt))
  expect_true("daily_bar_open" %in% names(dt))
  # No latest_trade columns at all (not NA, just absent)
  expect_false(any(grepl("latest_trade", names(dt))))
  expect_false(any(grepl("minute_bar", names(dt))))
  expect_false(any(grepl("prev_daily_bar", names(dt))))
})

# -- Multi-symbol snapshots with different sections present --

test_that("multi-symbol snapshots with different sections produce NAs", {
  # One symbol has all sections, another is missing latestTrade
  data <- list(
    AAPL = list(
      latestTrade = list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L),
      latestQuote = list(t = "2024-01-15T14:30:00Z", ap = 185.55, bp = 185.50),
      dailyBar = list(
        t = "2024-01-15T05:00:00Z",
        o = 184,
        h = 186,
        l = 183,
        c = 185,
        v = 50000000L,
        n = 500000L,
        vw = 185.0
      )
    ),
    MSFT = list(
      latestQuote = list(t = "2024-01-15T14:30:00Z", ap = 373.55, bp = 373.50),
      dailyBar = list(
        t = "2024-01-15T05:00:00Z",
        o = 372,
        h = 375,
        l = 371,
        c = 373,
        v = 25000000L,
        n = 250000L,
        vw = 373.0
      )
      # No latestTrade for MSFT
    )
  )

  # Parse each snapshot individually and rbindlist
  dts <- lapply(names(data), function(sym) {
    dt <- parse_snapshot(data[[sym]])
    if (nrow(dt) > 0) {
      dt[, symbol := sym]
    }
    return(dt)
  })
  combined <- data.table::rbindlist(dts, fill = TRUE)

  expect_equal(nrow(combined), 2L)
  # MSFT row has NA for latest_trade columns because it was missing
  msft_row <- combined[combined$symbol == "MSFT", ]
  expect_true("latest_trade_price" %in% names(combined))
  expect_true(is.na(msft_row$latest_trade_price))
})

# -- Multi-symbol bars where one symbol returns empty --

test_that("parse_multi_bars handles one symbol with data and one empty", {
  data <- list(
    bars = list(
      AAPL = list(
        list(t = "2024-01-02T05:00:00Z", o = 187, h = 188, l = 183, c = 185, v = 100L, n = 10L, vw = 185.5)
      ),
      MSFT = list() # empty
    ),
    next_page_token = NULL
  )
  dt <- parse_multi_bars(data)

  # MSFT should be absent, not present with NAs
  expect_true(all(dt$symbol == "AAPL"))
  expect_equal(nrow(dt), 1L)
})

# -- BTC/USD symbol as a response key (crypto market data) --

test_that("parse_multi_bars handles symbol with slash (crypto)", {
  data <- list(
    bars = list(
      "BTC/USD" = list(
        list(t = "2024-01-02T05:00:00Z", o = 42000, h = 43000, l = 41000, c = 42500, v = 100, n = 5000, vw = 42250)
      )
    ),
    next_page_token = NULL
  )
  dt <- parse_multi_bars(data)

  expect_equal(nrow(dt), 1L)
  expect_equal(dt$symbol[1], "BTC/USD")
})

# -- wrap_list_fields edge cases --

test_that("wrap_list_fields does not wrap length-1 lists", {
  x <- list(a = 1, b = list("single"))
  result <- wrap_list_fields(x)

  # Length-1 list is NOT wrapped — it stays as list("single")
  expect_true(is.list(result$b))
  expect_equal(length(result$b), 1L)
})

test_that("wrap_list_fields wraps length-2+ lists", {
  x <- list(a = 1, b = list("first", "second"))
  result <- wrap_list_fields(x)

  # Length-2 list IS wrapped — becomes list(list("first", "second"))
  expect_true(is.list(result$b))
  expect_equal(length(result$b), 1L)
  expect_true(is.list(result$b[[1]]))
})

test_that("rbindlist without wrap_list_fields expands rows from multi-element lists", {
  # This is the bug that wrap_list_fields prevents
  records <- list(
    list(symbol = "AAPL", conditions = list("@", "T")), # 2 conditions
    list(symbol = "MSFT", conditions = list("@")) # 1 condition
  )

  # Without wrapping: rbindlist expands the 2-element list into 2 rows
  dt_unwrapped <- data.table::rbindlist(records, fill = TRUE)
  expect_gt(nrow(dt_unwrapped), 2L) # More than 2 rows — data is corrupted

  # With wrapping: each record stays as 1 row
  wrapped <- lapply(records, wrap_list_fields)
  dt_wrapped <- data.table::rbindlist(wrapped, fill = TRUE)
  expect_equal(nrow(dt_wrapped), 2L) # Correct: 2 records = 2 rows
})

# -- Deeply nested structures --

test_that("as_dt_row with nested list becomes a list-column", {
  item <- list(
    symbol = "AAPL",
    nested = list(
      inner_a = 1,
      inner_b = 2
    )
  )
  dt <- as_dt_row(item)

  expect_equal(nrow(dt), 1L)
  # The nested list becomes a list-column (wrapped by as_dt_row logic)
  expect_true(is.list(dt$nested))
})

# -- to_snake_case idempotency --

test_that("to_snake_case is idempotent on already-snake_case input", {
  expect_equal(to_snake_case("already_snake"), "already_snake")
  expect_equal(to_snake_case("simple"), "simple")
  expect_equal(to_snake_case("multi_word_name"), "multi_word_name")
})

test_that("to_snake_case handles edge cases", {
  # All caps
  expect_equal(to_snake_case("URL"), "url")
  # Numbers
  expect_equal(to_snake_case("field1Name"), "field1_name")
  # Leading uppercase
  expect_equal(to_snake_case("Symbol"), "symbol")
})
