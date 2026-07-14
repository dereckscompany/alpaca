# Guards the typed-empty invariant: every `empty_dt_*()` constructor must return
# a zero-row data.table that still carries its full typed column set (and no list
# column), never a column-less `data.table()`. A column-less empty is what
# silently violates the methods' `assert_has_columns` @return contracts on an
# empty book / quiet window / flat account. Every parser's empty branch routes
# through one of these constructors, so pinning the constructors pins the empties.

# The full set of extracted typed-empty constructors (one per reused return shape).
empty_constructors <- list(
  empty_dt_bars = empty_dt_bars,
  empty_dt_bars_multi = empty_dt_bars_multi,
  empty_dt_trades = empty_dt_trades,
  empty_dt_trades_multi = empty_dt_trades_multi,
  empty_dt_quotes = empty_dt_quotes,
  empty_dt_quotes_multi = empty_dt_quotes_multi,
  empty_dt_option_trades_multi = empty_dt_option_trades_multi,
  empty_dt_option_quotes_multi = empty_dt_option_quotes_multi,
  empty_dt_snapshot = empty_dt_snapshot,
  empty_dt_snapshots_multi = empty_dt_snapshots_multi,
  empty_dt_assets = empty_dt_assets,
  empty_dt_calendar = empty_dt_calendar,
  empty_dt_corporate_actions = empty_dt_corporate_actions,
  empty_dt_corporate_actions_history = empty_dt_corporate_actions_history,
  empty_dt_news = empty_dt_news,
  empty_dt_most_actives = empty_dt_most_actives,
  empty_dt_movers = empty_dt_movers,
  empty_dt_contracts = empty_dt_contracts,
  empty_dt_positions = empty_dt_positions,
  empty_dt_activities = empty_dt_activities,
  empty_dt_portfolio_history = empty_dt_portfolio_history,
  empty_dt_watchlists = empty_dt_watchlists,
  empty_dt_orders = empty_dt_orders
)

test_that("every empty_dt_* constructor returns a zero-row, typed, list-free table", {
  for (nm in names(empty_constructors)) {
    dt <- empty_constructors[[nm]]()
    expect_s3_class(dt, "data.table")
    expect_identical(nrow(dt), 0L, label = paste(nm, "row count"))
    expect_true(ncol(dt) > 0L, label = paste(nm, "column count"))
    expect_false(
      any(vapply(dt, is.list, logical(1L))),
      label = paste(nm, "list column")
    )
  }
})

test_that("the bar constructors carry the renamed `datetime` reference column", {
  # Pins the bar/candle reference-time convention (I.2.5): bars use `datetime`,
  # not `timestamp`. `empty_dt_bars_multi` extends `empty_dt_bars` with `symbol`.
  expect_named(
    empty_dt_bars(),
    c("datetime", "open", "high", "low", "close", "volume", "trade_count", "vwap")
  )
  expect_named(
    empty_dt_bars_multi(),
    c("symbol", "datetime", "open", "high", "low", "close", "volume", "trade_count", "vwap")
  )
  expect_s3_class(empty_dt_bars()[["datetime"]], "POSIXct")
})

test_that("each parser's empty branch matches its constructor's schema", {
  # A parser's empty path must return exactly the constructor's typed empty, so
  # the two cannot drift (names, order, and column types must agree).
  cases <- list(
    parse_bars = list(parse_bars, empty_dt_bars),
    parse_trades = list(parse_trades, empty_dt_trades),
    parse_quotes = list(parse_quotes, empty_dt_quotes)
  )
  for (nm in names(cases)) {
    parser <- cases[[nm]][[1L]]
    ctor <- cases[[nm]][[2L]]
    empty <- parser(NULL)
    ref <- ctor()
    expect_identical(names(empty), names(ref), label = paste(nm, "column names"))
    expect_identical(
      vapply(empty, function(x) class(x)[1L], ""),
      vapply(ref, function(x) class(x)[1L], ""),
      label = paste(nm, "column types")
    )
  }
})
