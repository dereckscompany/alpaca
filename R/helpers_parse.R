# File: R/helpers_parse.R
# Alpaca-specific response parsing and data.table construction helpers. The
# generic toolkit (to_snake_case, as_dt_row, as_dt_list,
# collapse_string_array_fields) is imported from connectcore (see imports.R);
# this file holds the Alpaca-specific time coercions and the per-endpoint
# parsers built on top of both.

#' Wrap Multi-Element List Fields
#'
#' Wraps any field that is a list with length >= 1 inside another list(),
#' so that `rbindlist()` treats it as a single list-column entry rather
#' than expanding it into multiple rows.
#'
#' @param x (list) a named list (single record).
#' @return (list) the same list with multi-element list fields wrapped.
#'
#' @keywords internal
#' @noRd
wrap_list_fields <- function(x) {
  assert_args_wrap_list_fields(x)
  for (nm in names(x)) {
    val <- x[[nm]]
    if (is.list(val) && length(val) >= 1) {
      x[[nm]] <- list(val)
    }
  }
  return(assert_return_wrap_list_fields(x))
}

# ----------------------------------------------------------------------
# Date / time conversion helpers
# ----------------------------------------------------------------------
# All RFC-3339 / `YYYY-MM-DD` parsing across the package funnels through
# these small helpers so the behaviour is consistent and there's a single
# chokepoint if we ever need to swap the underlying parser.
#
#   rfc3339_to_datetime(x)         scalar/vector  ->  POSIXct (UTC)
#   parse_timestamp_cols(dt, cols) data.table     ->  POSIXct in-place
#   parse_date_cols(dt, cols)      data.table     ->  Date in-place
#   combine_et_datetime(date, t)   date + HH:MM   ->  POSIXct (America/New_York)
#   hhmm_to_hh_mm(x)               "HHMM"         ->  "HH:MM"
#
# When to use which:
#   * Single value or ad-hoc one-off  -> rfc3339_to_datetime()
#   * Column(s) on a data.table       -> parse_timestamp_cols / parse_date_cols
#   * Naive market times (calendar)   -> combine_et_datetime + hhmm_to_hh_mm
#
# Why rfc3339_to_datetime() exists vs. calling lubridate::as_datetime
# directly: it short-circuits NULL and all-NA input to NA_POSIXct_,
# avoiding lubridate's length-0 / warning behaviour on those inputs.

#' Parse an RFC-3339 Timestamp to POSIXct
#'
#' Thin wrapper around [lubridate::as_datetime()] with NULL / all-NA
#' input short-circuited to `NA_POSIXct_`. Prefer this over calling
#' `lubridate::as_datetime()` directly so the package has one chokepoint
#' for instant parsing.
#'
#' @param x (character | NA | NULL) RFC-3339 timestamp string(s) (e.g.,
#'   `"2024-01-15T14:30:00Z"`), or `NULL`.
#' @return (POSIXct | NA) the parsed UTC date-times, or `NA` if `x` is `NULL`.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
rfc3339_to_datetime <- function(x) {
  assert_args_rfc3339_to_datetime(x)
  if (is.null(x)) {
    return(assert_return_rfc3339_to_datetime(lubridate::NA_POSIXct_))
  }
  # Don't short-circuit on `all(is.na(x))` — returning the length-1
  # `NA_POSIXct_` from there would, when fed back through
  # `coerce_cols()` -> `data.table::set()`, get recycled into the
  # existing column's type rather than replacing the column with a
  # POSIXct one. The helper must return a vector the same length as
  # `x` so the column lands as POSIXct regardless of whether every
  # value is NA. `lubridate::as_datetime()` does the right thing on
  # all-NA input on its own. Mirrors the binance fix in
  # `ms_to_datetime`.
  return(assert_return_rfc3339_to_datetime(lubridate::as_datetime(x)))
}

#' Apply a Function to Selected Columns of a data.table by Reference
#'
#' Walks `cols`; for each that exists in `dt`, replaces it in place with the
#' result of `fn(dt[[col]])`. Columns that are not in `dt` are silently
#' skipped — useful for endpoints whose payload sometimes omits optional
#' fields. A zero-row `dt` short-circuits, so the caller can pipe through
#' this without a separate `nrow(dt) > 0` guard.
#'
#' Replaces the repeated boilerplate of:
#'
#' ```r
#' if (nrow(dt) > 0 && "created_at" %in% names(dt)) {
#'   dt[, created_at := rfc3339_to_datetime(created_at)]
#' }
#' ```
#'
#' with:
#'
#' ```r
#' coerce_cols(dt, "created_at", rfc3339_to_datetime)
#' ```
#'
#' Modifies `dt` by reference via `data.table::set()`; returns `dt`
#' invisibly so the call can be the last line of a parser. Converter-
#' agnostic — pass any `fn(vec) -> vec` function. Mirrors the same-named
#' helper in the binance package.
#'
#' @param dt (class<data.table>) the table to mutate (by reference).
#' @param cols (character) candidate column names to convert.
#' @param fn (function) takes a column vector, returns the coerced vector.
#'
#' @return (class<data.table>) `dt`, modified by reference and returned
#'   invisibly.
#'
#' @keywords internal
#' @noRd
coerce_cols <- function(dt, cols, fn) {
  assert_args_coerce_cols(dt, cols, fn)
  if (nrow(dt) == 0L) {
    return(invisible(assert_return_coerce_cols(dt)))
  }
  # `unique()` prevents double-coercion when a caller passes the same
  # column name twice (e.g. `coerce_cols(dt, c("created_at",
  # "created_at"), rfc3339_to_datetime)` would otherwise re-feed the
  # already-converted POSIXct vector back through
  # `lubridate::as_datetime`, silently producing wildly wrong values
  # — POSIXct numerics reinterpreted as RFC-3339 strings parse to
  # year-56,000+ timestamps with no warning). Mirrors the kucoin and
  # binance fixes.
  for (col in unique(cols)) {
    if (col %in% names(dt)) {
      data.table::set(dt, j = col, value = fn(dt[[col]]))
    }
  }
  return(invisible(assert_return_coerce_cols(dt)))
}

#' Convert Named Character Columns of a data.table to POSIXct
#'
#' Thin wrapper over [coerce_cols()] specialised to `rfc3339_to_datetime`.
#' Walks the given column names; for each that exists in `dt`, replaces
#' it in place with the result of `rfc3339_to_datetime()`. Columns that
#' do not exist are silently skipped — endpoints frequently omit
#' optional timestamps (e.g. `filled_at` on an unfilled order), and we
#' want the parser to handle the present subset without erroring.
#'
#' @param dt (class<data.table>) the table to mutate (by reference).
#' @param cols (character) candidate column names to convert.
#' @return (class<data.table>) `dt`, modified by reference and returned
#'   invisibly.
#' @noassert
#'
#' @keywords internal
#' @noRd
parse_timestamp_cols <- function(dt, cols) {
  return(coerce_cols(dt, cols, rfc3339_to_datetime))
}

#' Convert Named Character Columns of a data.table to Date
#'
#' Thin wrapper over [coerce_cols()] specialised to
#' `lubridate::ymd(x, quiet = TRUE)`. Walks the given column names;
#' for each that exists in `dt`, parses `"YYYY-MM-DD"` strings to
#' `Date`. Columns that do not exist in `dt` are silently skipped.
#'
#' @param dt (class<data.table>) the table to mutate (by reference).
#' @param cols (character) candidate column names to convert.
#' @return (class<data.table>) `dt`, modified by reference and returned
#'   invisibly.
#' @noassert
#'
#' @keywords internal
#' @noRd
parse_date_cols <- function(dt, cols) {
  return(coerce_cols(dt, cols, function(x) lubridate::ymd(x, quiet = TRUE)))
}

# Exchange timezone used by Alpaca for naive market times (open/close,
# session_open/session_close on /v2/calendar). Alpaca does NOT
# explicitly document the timezone of these fields on the calendar /
# clock reference pages — the inference is:
#   1. /v2 is US-only (NYSE/NASDAQ-equivalent venues).
#   2. The market-data FAQ confirms NY tz is canonical for bar
#      aggregation.
#   3. `09:30` and `16:00` only make sense as ET wall-clock times.
#   4. Every Alpaca SDK in other languages treats it as ET.
# The named tz handles DST transitions automatically (a fixed `-05:00`
# would be wrong half the year).
#
# TODO(v3): Alpaca's `/v3/calendar` exposes multiple markets and will
# need per-market timezone lookup rather than this single constant.
ALPACA_EXCHANGE_TZ <- "America/New_York"

#' Combine a YYYY-MM-DD Date String with a HH:MM Time String
#'
#' @param date (character | NA) ISO date string(s).
#' @param time (character | NA) `"HH:MM"` clock time(s).
#' @return (POSIXct | NA) the combined date-times in `America/New_York`, `NA`
#'   where inputs are `NA`.
#'
#' @keywords internal
#' @noRd
combine_et_datetime <- function(date, time) {
  assert_args_combine_et_datetime(date, time)
  joined <- ifelse(is.na(date) | is.na(time), NA_character_, paste(date, time))
  return(assert_return_combine_et_datetime(lubridate::ymd_hm(joined, tz = ALPACA_EXCHANGE_TZ, quiet = TRUE)))
}

#' Insert a Colon into a HHMM Time String
#'
#' Alpaca's `session_open`/`session_close` fields are encoded as `"HHMM"`
#' (no separator), unlike `open`/`close` which use `"HH:MM"`.
#'
#' @param x (character | NA) `"HHMM"` strings.
#' @return (character | NA) `"HH:MM"` strings, NA-preserving.
#'
#' @keywords internal
#' @noRd
hhmm_to_hh_mm <- function(x) {
  assert_args_hhmm_to_hh_mm(x)
  out <- ifelse(is.na(x) | nchar(x) != 4L, NA_character_, paste0(substr(x, 1L, 2L), ":", substr(x, 3L, 4L)))
  return(assert_return_hhmm_to_hh_mm(out))
}

#' Parse Alpaca Bar Data to data.table
#'
#' Converts a list of bar objects (with short field names `t`, `o`, `h`, `l`,
#' `c`, `v`, `n`, `vw`) into a tidy [data.table::data.table] with descriptive
#' column names.
#'
#' @param bars (list | NULL) bar objects from the Alpaca API.
#' @return (class<data.table>) a table with columns: `timestamp`, `open`,
#'   `high`, `low`, `close`, `volume`, `trade_count`, `vwap`.
#'
#' @keywords internal
#' @noRd
parse_bars <- function(bars) {
  assert_args_parse_bars(bars)
  if (is.null(bars) || length(bars) == 0) {
    return(assert_return_parse_bars(empty_dt_bars()))
  }
  dt <- data.table::rbindlist(bars, fill = TRUE)
  name_map <- c(
    t = "timestamp",
    o = "open",
    h = "high",
    l = "low",
    c = "close",
    v = "volume",
    n = "trade_count",
    vw = "vwap"
  )
  idx <- names(dt) %in% names(name_map)
  if (any(idx)) {
    data.table::setnames(dt, names(dt)[idx], name_map[names(dt)[idx]])
  }
  data.table::setnames(dt, to_snake_case(names(dt)))
  parse_timestamp_cols(dt, "timestamp")
  # Alpaca sends a whole-number price without a decimal, so the raw JSON
  # parser realises that bar's price as `integer`. Coerce every price/vwap
  # column to a clean `numeric` double so the column is always a double.
  coerce_cols(dt, c("open", "high", "low", "close", "vwap"), as.numeric)
  return(assert_return_parse_bars(dt[]))
}

#' Parse Multi-Symbol Bar Response
#'
#' Alpaca's multi-symbol bars endpoint returns
#' `{"bars": {"AAPL": [...], ...}, "next_page_token": ...}`. This function
#' flattens that structure into a single data.table with a `symbol` column.
#'
#' @param data (list) the parsed Alpaca response.
#' @return (class<data.table>) a table with a `symbol` column prepended.
#' @noassert
#'
#' @keywords internal
#' @noRd
parse_multi_bars <- function(data) {
  return(parse_multi_bars_items(data$bars))
}

#' Parse Accumulated Multi-Symbol Bar Items (Across Pages)
#'
#' The pagination loop ([alpaca_paginate()]) accumulates the `bars` field of
#' each page via `c()`. For the multi-symbol endpoint that field is a *map*
#' (`{"AAPL": [...], "MSFT": [...]}`), so the accumulator is a named list of
#' per-symbol bar arrays in which the **same symbol may appear more than once**
#' (once per page it spanned). This parser groups by symbol name, concatenates
#' each symbol's arrays back together, and flattens to a single `data.table`
#' with a `symbol` column.
#'
#' Single-page callers pass one page's map directly; the duplicate-name
#' handling is a harmless superset of that case.
#'
#' @param items (list | NULL) accumulated per-symbol bar arrays.
#' @return (class<data.table>) a table with a `symbol` column prepended.
#'
#' @keywords internal
#' @noRd
parse_multi_bars_items <- function(items) {
  assert_args_parse_multi_bars_items(items)
  if (is.null(items) || length(items) == 0) {
    return(assert_return_parse_multi_bars_items(empty_dt_bars_multi()))
  }
  syms <- unique(names(items))
  dts <- lapply(syms, function(sym) {
    sym_bars <- do.call(c, unname(items[names(items) == sym]))
    dt <- parse_bars(sym_bars)
    if (nrow(dt) > 0) {
      dt[, symbol := sym]
      data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
    }
    return(dt[])
  })
  return(assert_return_parse_multi_bars_items(data.table::rbindlist(dts, fill = TRUE)[]))
}

#' Parse Alpaca Trade Data to data.table (One Row Per Trade)
#'
#' Converts a list of trade objects (with short field names) into a tidy
#' [data.table::data.table] with descriptive column names. Each trade is
#' a single row; the `c` condition-code array is collapsed to a
#' semicolon-separated `conditions` character column (e.g. `"@;T"`).
#'
#' Recover the original codes with
#' `strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`. Filter with
#' `dt[grepl("T", conditions)]`. Trades with no condition codes get
#' `conditions = NA`.
#'
#' @param trades (list | NULL) trade objects from the Alpaca API.
#' @return (class<data.table>) a table with columns: `timestamp`, `price`,
#'   `size`, `exchange`, `conditions`, `tape`, `id`.
#'
#' @keywords internal
#' @noRd
parse_trades <- function(trades) {
  assert_args_parse_trades(trades)
  if (is.null(trades) || length(trades) == 0) {
    return(assert_return_parse_trades(empty_dt_trades()))
  }
  # Collapse the `c` condition-code array on each trade so one trade
  # remains one row. We rename `c` to `conditions` first so the helper
  # finds the field by its semantic name.
  trades_clean <- lapply(trades, function(tr) {
    if (!is.null(tr[["c"]])) {
      tr[["conditions"]] <- tr[["c"]]
      tr[["c"]] <- NULL
    }
    return(collapse_string_array_fields(tr, "conditions"))
  })
  dt <- data.table::rbindlist(trades_clean, fill = TRUE)
  name_map <- c(
    t = "timestamp",
    p = "price",
    s = "size",
    x = "exchange",
    z = "tape",
    i = "id"
  )
  idx <- names(dt) %in% names(name_map)
  if (any(idx)) {
    data.table::setnames(dt, names(dt)[idx], name_map[names(dt)[idx]])
  }
  data.table::setnames(dt, to_snake_case(names(dt)))
  parse_timestamp_cols(dt, "timestamp")
  # Coerce the price to a clean `numeric` double (a whole-number price Alpaca
  # sends without a decimal would otherwise realise as `integer`).
  coerce_cols(dt, "price", as.numeric)
  return(assert_return_parse_trades(dt[]))
}

#' Parse Alpaca Quote Data to data.table (One Row Per Quote)
#'
#' Converts a list of quote objects (with short field names) into a tidy
#' [data.table::data.table] with descriptive column names. Each quote is
#' a single row; the `c` condition-code array is collapsed to a
#' semicolon-separated `conditions` character column (e.g. `"R;A"`).
#'
#' Recover the original codes with
#' `strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`. Filter with
#' `dt[grepl("R", conditions)]`. Quotes with no condition codes get
#' `conditions = NA`.
#'
#' @param quotes (list | NULL) quote objects from the Alpaca API.
#' @return (class<data.table>) a table with one row per quote and
#'   descriptive column names.
#'
#' @keywords internal
#' @noRd
parse_quotes <- function(quotes) {
  assert_args_parse_quotes(quotes)
  if (is.null(quotes) || length(quotes) == 0) {
    return(assert_return_parse_quotes(empty_dt_quotes()))
  }
  # Rename `c` -> `conditions` first so the helper finds the field, then
  # collapse the array to a `;`-joined character column. One quote =
  # one row regardless of how many condition codes it carries.
  quotes_clean <- lapply(quotes, function(q) {
    if (!is.null(q[["c"]])) {
      q[["conditions"]] <- q[["c"]]
      q[["c"]] <- NULL
    }
    return(collapse_string_array_fields(q, "conditions"))
  })
  dt <- data.table::rbindlist(quotes_clean, fill = TRUE)
  name_map <- c(
    t = "timestamp",
    ax = "ask_exchange",
    ap = "ask_price",
    "as" = "ask_size",
    bx = "bid_exchange",
    bp = "bid_price",
    bs = "bid_size",
    z = "tape"
  )
  idx <- names(dt) %in% names(name_map)
  if (any(idx)) {
    data.table::setnames(dt, names(dt)[idx], name_map[names(dt)[idx]])
  }
  data.table::setnames(dt, to_snake_case(names(dt)))
  parse_timestamp_cols(dt, "timestamp")
  # Coerce the bid/ask prices to clean `numeric` doubles (a whole-number price
  # Alpaca sends without a decimal would otherwise realise as `integer`).
  coerce_cols(dt, c("ask_price", "bid_price"), as.numeric)
  return(assert_return_parse_quotes(dt[]))
}

#' Parse Snapshot Data to data.table
#'
#' Flattens Alpaca's nested snapshot response (containing latestTrade,
#' latestQuote, minuteBar, dailyBar, prevDailyBar) into a single-row
#' data.table with prefixed column names. The inner `c` arrays on the
#' nested `latestTrade` and `latestQuote` (condition codes) are
#' collapsed to a `;`-joined character before flattening, so the
#' resulting `latest_trade_conditions` and `latest_quote_conditions`
#' columns are plain character — not list columns. Per the package's
#' "one entity = one row" policy, one symbol = one snapshot row.
#'
#' Options-specific extras: when the upstream snapshot carries an
#' `impliedVolatility` scalar (top-level) it surfaces as the
#' `implied_volatility` column, and the nested `greeks` object
#' (`delta`, `gamma`, `theta`, `vega`, `rho`) is flattened into
#' `greeks_*` columns. Stock snapshots never include these fields, so
#' the columns only appear for option chains / option snapshots.
#'
#' Note: the `c` field on the bar sections (minuteBar, dailyBar,
#' prevDailyBar) is the close *price* — a scalar number — and is left
#' untouched. The name map renames it to `*_close` per section.
#'
#' @param snapshot (list | NULL) a named list representing an Alpaca snapshot.
#' @return (class<data.table>) a single-row table.
#'
#' @keywords internal
#' @noRd
parse_snapshot <- function(snapshot) {
  assert_args_parse_snapshot(snapshot)
  if (is.null(snapshot) || length(snapshot) == 0) {
    return(assert_return_parse_snapshot(empty_dt_snapshot()))
  }
  # Collapse the inner `c` condition-code arrays on latestTrade /
  # latestQuote BEFORE flattening. Only these two sections — bar
  # sections use `c` to mean close price (a scalar), not conditions.
  #
  # When the section exists but its `c` field is missing or NULL, we
  # still want the downstream `latest_*_conditions` column to appear
  # (as `NA_character_`) so the schema stays consistent across calls.
  # Without this, an Alpaca payload that omits `c` would silently drop
  # the conditions column.
  for (sec in c("latestTrade", "latestQuote")) {
    sub <- snapshot[[sec]]
    if (is.null(sub)) {
      next
    }
    if (is.null(sub[["c"]])) {
      sub[["c"]] <- NA_character_
      snapshot[[sec]] <- sub
      next
    }
    if (is.list(sub[["c"]]) || length(sub[["c"]]) > 1L) {
      snapshot[[sec]] <- collapse_string_array_fields(sub, "c")
    }
  }
  # Flatten nested sections into a single list with prefixed raw names
  sections <- c("latestTrade", "latestQuote", "minuteBar", "dailyBar", "prevDailyBar")
  flat <- list()
  for (section in sections) {
    sub <- snapshot[[section]]
    if (!is.null(sub)) {
      prefix <- to_snake_case(section)
      for (nm in names(sub)) {
        flat[[paste0(prefix, "_", nm)]] <- sub[[nm]]
      }
    }
  }
  # Options-snapshot extras: top-level `impliedVolatility` (a scalar)
  # and the nested `greeks` object (fixed schema: delta, gamma, theta,
  # vega, rho). Stock snapshots never carry these, so the columns only
  # appear when the upstream is an options snapshot.
  if (!is.null(snapshot[["impliedVolatility"]])) {
    flat[["implied_volatility"]] <- snapshot[["impliedVolatility"]]
  }
  greeks <- snapshot[["greeks"]]
  if (!is.null(greeks) && length(greeks) > 0L) {
    for (nm in names(greeks)) {
      flat[[paste0("greeks_", to_snake_case(nm))]] <- greeks[[nm]]
    }
  }
  dt <- as_dt_row(flat)
  if (ncol(dt) == 0) {
    return(assert_return_parse_snapshot(empty_dt_snapshot()))
  }
  # Expand abbreviated field names with explicit map
  snapshot_name_map <- c(
    # latestTrade
    latest_trade_t = "latest_trade_timestamp",
    latest_trade_p = "latest_trade_price",
    latest_trade_s = "latest_trade_size",
    latest_trade_x = "latest_trade_exchange",
    latest_trade_c = "latest_trade_conditions",
    latest_trade_z = "latest_trade_tape",
    latest_trade_i = "latest_trade_id",
    latest_trade_tks = "latest_trade_taker_side",
    # latestQuote
    latest_quote_t = "latest_quote_timestamp",
    latest_quote_ax = "latest_quote_ask_exchange",
    latest_quote_ap = "latest_quote_ask_price",
    latest_quote_as = "latest_quote_ask_size",
    latest_quote_bx = "latest_quote_bid_exchange",
    latest_quote_bp = "latest_quote_bid_price",
    latest_quote_bs = "latest_quote_bid_size",
    latest_quote_c = "latest_quote_conditions",
    latest_quote_z = "latest_quote_tape",
    # minuteBar
    minute_bar_t = "minute_bar_timestamp",
    minute_bar_o = "minute_bar_open",
    minute_bar_h = "minute_bar_high",
    minute_bar_l = "minute_bar_low",
    minute_bar_c = "minute_bar_close",
    minute_bar_v = "minute_bar_volume",
    minute_bar_n = "minute_bar_trade_count",
    minute_bar_vw = "minute_bar_vwap",
    # dailyBar
    daily_bar_t = "daily_bar_timestamp",
    daily_bar_o = "daily_bar_open",
    daily_bar_h = "daily_bar_high",
    daily_bar_l = "daily_bar_low",
    daily_bar_c = "daily_bar_close",
    daily_bar_v = "daily_bar_volume",
    daily_bar_n = "daily_bar_trade_count",
    daily_bar_vw = "daily_bar_vwap",
    # prevDailyBar
    prev_daily_bar_t = "prev_daily_bar_timestamp",
    prev_daily_bar_o = "prev_daily_bar_open",
    prev_daily_bar_h = "prev_daily_bar_high",
    prev_daily_bar_l = "prev_daily_bar_low",
    prev_daily_bar_c = "prev_daily_bar_close",
    prev_daily_bar_v = "prev_daily_bar_volume",
    prev_daily_bar_n = "prev_daily_bar_trade_count",
    prev_daily_bar_vw = "prev_daily_bar_vwap"
  )
  idx <- names(dt) %in% names(snapshot_name_map)
  if (any(idx)) {
    data.table::setnames(dt, names(dt)[idx], snapshot_name_map[names(dt)[idx]])
  }
  data.table::setnames(dt, to_snake_case(names(dt)))
  parse_timestamp_cols(
    dt,
    c(
      "latest_trade_timestamp",
      "latest_quote_timestamp",
      "minute_bar_timestamp",
      "daily_bar_timestamp",
      "prev_daily_bar_timestamp"
    )
  )
  # Coerce the latest-trade/-quote prices to clean `numeric` doubles (a
  # whole-number price Alpaca sends without a decimal would otherwise realise
  # as `integer`). The `*_bar_*` OHLC blocks ride along as un-asserted extras.
  coerce_cols(
    dt,
    c("latest_trade_price", "latest_quote_ask_price", "latest_quote_bid_price"),
    as.numeric
  )
  return(assert_return_parse_snapshot(dt[]))
}

#' Parse Alpaca News Response to data.table (One Row Per Article)
#'
#' Per the package's "one entity = one row" policy, news articles are the
#' entity. The two nested arrays (`symbols` and `images`) become collapsed
#' character columns rather than exploding the row count.
#'
#' Concretely, the returned `data.table` has:
#'   - `symbols` (character): semicolon-separated related tickers, e.g.
#'     `"AAPL;MSFT;GOOGL"`. Recover with
#'     `strsplit(news$symbols, ";", fixed = TRUE)`.
#'   - `image_sizes` (character): semicolon-separated size labels (e.g.
#'     `"large;small"`) parallel to `image_urls`.
#'   - `image_urls` (character): semicolon-separated URLs. Any literal `;`
#'     inside a URL is percent-encoded to `%3B` before joining, so users
#'     can do `vapply(strsplit(news$image_urls, ";", fixed = TRUE)[[1]],
#'     URLdecode, character(1))` to recover the original URLs.
#'
#' Articles with no symbols and/or no images keep the article row, with
#' the missing fields set to `NA`.
#'
#' @param news_items (list | NULL) news article objects from the Alpaca API.
#' @return (class<data.table>) a table with one row per article.
#'
#' @keywords internal
#' @noRd
parse_news <- function(news_items) {
  assert_args_parse_news(news_items)
  if (is.null(news_items) || length(news_items) == 0) {
    return(assert_return_parse_news(empty_dt_news()))
  }
  # Walk each article, collapse the two nested arrays into scalar character
  # fields, then drop the originals so rbindlist sees a flat record.
  items_clean <- lapply(news_items, function(item) {
    # symbols: plain string array -> `;`-joined
    item <- collapse_string_array_fields(item, "symbols")

    # images: array of {size, url} objects -> two parallel `;`-joined cols.
    #
    # Two subtleties:
    #
    # 1. URLs may legally contain `;` (URL sub-delimiter, common in signed
    #    query strings). To make the joined string safely splittable AND
    #    `URLdecode()`-recoverable, we percent-encode `%` -> `%25` first and
    #    then `;` -> `%3B`. Encoding `;` alone would not be lossless: an
    #    upstream URL that already contained a literal `%3B` would round-
    #    trip to `;`. With both characters encoded, `URLdecode()` reverses
    #    each in the right order and the original string is recovered.
    #
    # 2. Per-image NA values are written as the empty token `""` (NOT
    #    `NA_character_`), because `paste(c("real", NA), collapse = ";")`
    #    yields the literal string `"real;NA"`, indistinguishable from a
    #    real "NA" value. `""` is unambiguous: an empty token always means
    #    "missing".
    imgs <- item[["images"]]
    if (is.null(imgs) || length(imgs) == 0L) {
      item$image_sizes <- NA_character_
      item$image_urls <- NA_character_
    } else {
      sizes <- vapply(
        imgs,
        function(img) {
          return(if (is.null(img$size)) "" else as.character(img$size))
        },
        character(1)
      )
      urls <- vapply(
        imgs,
        function(img) {
          return(if (is.null(img$url)) "" else as.character(img$url))
        },
        character(1)
      )
      urls_safe <- vapply(
        urls,
        function(u) {
          if (!nzchar(u)) {
            return("")
          }
          # Encode `%` first so we can encode `;` without ambiguity. The
          # pair is reversible by `URLdecode()` in one pass.
          u <- gsub("%", "%25", u, fixed = TRUE)
          u <- gsub(";", "%3B", u, fixed = TRUE)
          return(u)
        },
        character(1)
      )
      item$image_sizes <- paste(sizes, collapse = ";")
      item$image_urls <- paste(urls_safe, collapse = ";")
    }
    item[["images"]] <- NULL
    return(item)
  })

  dt <- data.table::rbindlist(items_clean, fill = TRUE)
  data.table::setnames(dt, to_snake_case(names(dt)))
  parse_timestamp_cols(dt, c("created_at", "updated_at"))
  return(assert_return_parse_news(dt[]))
}

#' Parse Alpaca Watchlist Response to Long-Format data.table
#'
#' Expands the `assets` array field so that each watchlist is represented
#' by one row per asset. Watchlists with no assets get a single row with
#' asset columns set to NA.
#'
#' Per-asset `attributes` arrays are collapsed to a `;`-separated character
#' column (see `collapse_string_array_fields()`), so the returned table has
#' no list columns even when some assets have empty `attributes`.
#'
#' @param wl (list | NULL) a named list representing a single watchlist response
#'   from the Alpaca API.
#' @return (class<data.table>) a long-format table with asset columns
#'   (prefixed `asset_`) alongside watchlist metadata.
#'
#' @keywords internal
#' @noRd
parse_watchlist <- function(wl) {
  assert_args_parse_watchlist(wl)
  if (is.null(wl) || length(wl) == 0) {
    return(assert_return_parse_watchlist(data.table::data.table()[]))
  }
  assets <- wl[["assets"]]
  wl[["assets"]] <- NULL
  # Build the parent watchlist row
  parent <- as_dt_row(wl)
  parse_timestamp_cols(parent, c("created_at", "updated_at"))
  if (is.null(assets) || length(assets) == 0) {
    # No assets: return one row with NA asset columns
    parent[, asset_id := NA_character_]
    parent[, asset_symbol := NA_character_]
    parent[, asset_name := NA_character_]
    # `asset_attributes` exists on every populated watchlist row (as a
    # `;`-collapsed character or NA). Include it on the empty row too so
    # the schema is stable across populated / empty watchlists, matching
    # the documented @return contract.
    parent[, asset_attributes := NA_character_]
    return(assert_return_parse_watchlist(parent[]))
  }
  # Collapse each asset's `attributes` string array to a scalar character
  # before binding. Without this, mixed empty/populated arrays make
  # `rbindlist` warn and fall back to a list column.
  assets <- lapply(assets, collapse_string_array_fields, "attributes")
  # Build the assets data.table
  assets_dt <- data.table::rbindlist(assets, fill = TRUE)
  data.table::setnames(assets_dt, to_snake_case(names(assets_dt)))
  # Prefix asset columns to avoid collision with watchlist columns
  asset_cols <- names(assets_dt)
  data.table::setnames(assets_dt, paste0("asset_", asset_cols))
  # Cross-join: repeat parent row for each asset
  parent_rep <- parent[rep(1L, nrow(assets_dt)), ]
  dt <- cbind(parent_rep, assets_dt)
  return(assert_return_parse_watchlist(dt[]))
}

#' Parse an Alpaca Asset Record to a Single-Row data.table
#'
#' Like `as_dt_row()` but collapses the `attributes` string array to a
#' single semicolon-separated character column (e.g.
#' `"fractional_eh_enabled;has_options;overnight_tradable"`). One asset
#' stays one row.
#'
#' @param x (list | NULL) a named list representing a single Alpaca asset.
#' @return (class<data.table>) a single-row table.
#'
#' @keywords internal
#' @noRd
parse_asset <- function(x) {
  assert_args_parse_asset(x)
  if (is.null(x) || length(x) == 0L) {
    return(assert_return_parse_asset(data.table::data.table()[]))
  }
  x <- collapse_string_array_fields(x, "attributes")
  return(assert_return_parse_asset(as_dt_row(x)))
}

#' Parse an Alpaca Asset List to a data.table
#'
#' Like `as_dt_list()` but applies `parse_asset()` per record so the
#' `attributes` array column is collapsed instead of arriving as a list
#' column.
#'
#' @param items (list | NULL) asset records.
#' @return (class<data.table>) a table with one row per asset.
#'
#' @keywords internal
#' @noRd
parse_assets <- function(items) {
  assert_args_parse_assets(items)
  if (is.null(items) || length(items) == 0L) {
    return(assert_return_parse_assets(empty_dt_assets()))
  }
  return(assert_return_parse_assets(data.table::rbindlist(lapply(items, parse_asset), fill = TRUE)[]))
}

#' Parse a Single Option Contract Record
#'
#' Like `as_dt_row()` but handles the optional `deliverables` array
#' (present when the caller passed `show_deliverables = TRUE`) per the
#' "array of objects" treatment: explode to one row per deliverable
#' with contract fields replicated, prefix deliverable columns with
#' `deliverable_`, and add a 1-indexed `deliverable_index`.
#'
#' Contracts without `deliverables` (the default response shape) come
#' back as a single row with no `deliverable_*` columns.
#'
#' @param x (list | NULL) a named list representing a single Alpaca option
#'   contract.
#' @return (class<data.table>) a table with one row per deliverable
#'   (or one row when no `deliverables` are present).
#'
#' @keywords internal
#' @noRd
parse_contract <- function(x) {
  assert_args_parse_contract(x)
  if (is.null(x) || length(x) == 0L) {
    return(assert_return_parse_contract(data.table::data.table()[]))
  }
  delivs <- x[["deliverables"]]
  x[["deliverables"]] <- NULL
  contract_row <- as_dt_row(x)
  parse_date_cols(
    contract_row,
    c(
      "expiration_date",
      "open_interest_date",
      "close_price_date"
    )
  )
  if (is.null(delivs) || length(delivs) == 0L) {
    return(assert_return_parse_contract(contract_row[]))
  }
  # Normalise per-deliverable records before binding: replace `NULL`
  # fields with `NA` so `rbindlist(fill = TRUE)` doesn't warn about
  # length-0 columns when one deliverable omits a field that another
  # has (e.g. a cash deliverable with no `asset_id`).
  delivs <- lapply(delivs, function(d) {
    return(lapply(d, function(v) if (is.null(v)) NA else v))
  })
  deliv_dt <- data.table::rbindlist(delivs, fill = TRUE)
  data.table::setnames(deliv_dt, to_snake_case(names(deliv_dt)))
  data.table::setnames(deliv_dt, paste0("deliverable_", names(deliv_dt)))
  deliv_dt[, deliverable_index := seq_len(.N)]
  contract_rep <- contract_row[rep(1L, nrow(deliv_dt)), ]
  return(assert_return_parse_contract(cbind(contract_rep, deliv_dt)[]))
}

#' Parse an Alpaca Option Contracts List
#'
#' Applies `parse_contract()` per record. When `show_deliverables =
#' TRUE` was passed to the underlying endpoint, the returned table has
#' one row per `(contract, deliverable)` pair; otherwise it has one
#' row per contract.
#'
#' @param items (list | NULL) option contract records.
#' @return (class<data.table>) the parsed contracts table.
#'
#' @keywords internal
#' @noRd
parse_contracts <- function(items) {
  assert_args_parse_contracts(items)
  if (is.null(items) || length(items) == 0L) {
    return(assert_return_parse_contracts(empty_dt_contracts()))
  }
  return(assert_return_parse_contracts(data.table::rbindlist(lapply(items, parse_contract), fill = TRUE)[]))
}

#' Parse a Single Order Response to data.table
#'
#' Returns a flat `data.table` with one row per "order" (parent and any
#' legs treated equally). For simple orders that's one row. For a bracket /
#' OCO / OTO order it's one parent row plus one row per leg.
#'
#' Two helper columns distinguish parent rows from leg rows:
#'
#' \itemize{
#'   \item `leg_index` — `NA_integer_` for the parent row; `1, 2, ...` for
#'         each leg in submission order.
#'   \item `parent_order_id` — `NA_character_` for the parent row; the
#'         parent's `id` for each leg row.
#' }
#'
#' Use `dt[is.na(parent_order_id)]` to see just the parent orders, and
#' `dt[parent_order_id == "<id>"]` to see the legs of a specific bracket.
#'
#' Each leg in the API is itself a full order object — including its own
#' `id`, `side`, `limit_price`, `status`, etc. — so the parent and the
#' legs share the same column set and `data.table::rbindlist()` aligns
#' them naturally.
#'
#' @param x (list | NULL) a named list representing a single order.
#' @return (class<data.table>) the parsed order table.
#'
#' @keywords internal
#' @noRd
parse_order <- function(x) {
  assert_args_parse_order(x)
  if (is.null(x) || length(x) == 0) {
    return(assert_return_parse_order(empty_dt_orders()))
  }
  legs <- x[["legs"]]
  parent_id <- x[["id"]]
  x[["legs"]] <- NULL

  parent_dt <- as_dt_row(x)
  if (nrow(parent_dt) > 0L) {
    parent_dt[, leg_index := NA_integer_]
    parent_dt[, parent_order_id := NA_character_]
  }

  if (is.null(legs) || !is.list(legs) || length(legs) == 0L) {
    parse_timestamp_cols(parent_dt, ORDER_TIMESTAMP_COLS)
    return(assert_return_parse_order(parent_dt[]))
  }

  # Each leg is itself an order — strip its `legs` field (always null in
  # the response we've seen, but defensive) and parse via the same path.
  legs_clean <- lapply(legs, function(leg) {
    leg[["legs"]] <- NULL
    return(leg)
  })
  legs_dt <- as_dt_list(legs_clean)
  if (nrow(legs_dt) > 0L) {
    legs_dt[, leg_index := seq_len(.N)]
    legs_dt[, parent_order_id := parent_id]
  }
  out <- data.table::rbindlist(list(parent_dt, legs_dt), fill = TRUE)
  parse_timestamp_cols(out, ORDER_TIMESTAMP_COLS)
  return(assert_return_parse_order(out[]))
}

# All timestamp fields Alpaca emits on an order record. Optional fields
# (filled_at, canceled_at, ...) are NA on records that never reached
# that state; parse_timestamp_cols() skips missing columns.
ORDER_TIMESTAMP_COLS <- c(
  "created_at",
  "updated_at",
  "submitted_at",
  "filled_at",
  "expired_at",
  "canceled_at",
  "failed_at",
  "replaced_at"
)

#' Parse a List of Order Responses to data.table
#'
#' Applies `parse_order()` to each item and row-binds.
#'
#' @param items (list | NULL) order named lists.
#' @return (class<data.table>) the parsed orders table.
#'
#' @keywords internal
#' @noRd
parse_orders <- function(items) {
  assert_args_parse_orders(items)
  if (is.null(items) || length(items) == 0) {
    return(assert_return_parse_orders(empty_dt_orders()))
  }
  dt <- data.table::rbindlist(lapply(items, parse_order), fill = TRUE)
  return(assert_return_parse_orders(dt[]))
}

# ---- Typed empty constructors ----
#
# Each `empty_dt_<descriptive>()` returns a zero-row data.table whose columns
# match the corresponding `@type` shape in R/types_alpaca.R (every column
# present, correctly typed). The list-returning endpoint methods substitute the
# matching empty into their empty branch so an empty Alpaca response still
# satisfies the method's typed `@return` contract (`assert_has_columns` requires
# the shape's columns to be present, which a bare `data.table()` would not
# carry). Single-object endpoints always return one row, so they need none.
# Datetime columns are built with a length-0
# `lubridate::as_datetime(character(0), tz = "UTC")` and date columns with a
# length-0 `lubridate::as_date(character(0))`, matching the class and tz the
# parsers' `parse_timestamp_cols` / `parse_date_cols` coercions produce.

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_bars <- function() {
  return(data.table::data.table(
    timestamp = lubridate::as_datetime(character(0), tz = "UTC"),
    open = numeric(0),
    high = numeric(0),
    low = numeric(0),
    close = numeric(0),
    volume = integer(0),
    trade_count = integer(0),
    vwap = numeric(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_bars_multi <- function() {
  dt <- empty_dt_bars()
  dt[, symbol := character(0)]
  data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
  return(dt[])
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_trades <- function() {
  return(data.table::data.table(
    timestamp = lubridate::as_datetime(character(0), tz = "UTC"),
    price = numeric(0),
    size = integer(0),
    exchange = character(0),
    tape = character(0),
    id = integer(0),
    conditions = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_trades_multi <- function() {
  dt <- empty_dt_trades()
  dt[, symbol := character(0)]
  data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
  return(dt[])
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_quotes <- function() {
  return(data.table::data.table(
    timestamp = lubridate::as_datetime(character(0), tz = "UTC"),
    ask_exchange = character(0),
    ask_price = numeric(0),
    ask_size = integer(0),
    bid_exchange = character(0),
    bid_price = numeric(0),
    bid_size = integer(0),
    tape = character(0),
    conditions = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_quotes_multi <- function() {
  dt <- empty_dt_quotes()
  dt[, symbol := character(0)]
  data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
  return(dt[])
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_option_trades_multi <- function() {
  # The options trade payload carries no consolidated tape, so the shape is the
  # equity TradesMulti minus `tape`.
  dt <- empty_dt_trades_multi()
  return(dt[, setdiff(names(dt), "tape"), with = FALSE][])
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_option_quotes_multi <- function() {
  # The options quote payload carries no consolidated tape, so the shape is the
  # equity QuotesMulti minus `tape`.
  dt <- empty_dt_quotes_multi()
  return(dt[, setdiff(names(dt), "tape"), with = FALSE][])
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_snapshot <- function() {
  return(data.table::data.table(
    latest_trade_timestamp = lubridate::as_datetime(character(0), tz = "UTC"),
    latest_trade_price = numeric(0),
    latest_trade_size = integer(0),
    latest_trade_conditions = character(0),
    latest_quote_timestamp = lubridate::as_datetime(character(0), tz = "UTC"),
    latest_quote_ask_price = numeric(0),
    latest_quote_bid_price = numeric(0),
    latest_quote_ask_size = integer(0),
    latest_quote_bid_size = integer(0),
    latest_quote_conditions = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_snapshots_multi <- function() {
  dt <- empty_dt_snapshot()
  dt[, symbol := character(0)]
  data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
  return(dt[])
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_assets <- function() {
  return(data.table::data.table(
    id = character(0),
    class = character(0),
    exchange = character(0),
    symbol = character(0),
    name = character(0),
    status = character(0),
    tradable = logical(0),
    marginable = logical(0),
    shortable = logical(0),
    fractionable = logical(0),
    attributes = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_calendar <- function() {
  return(data.table::data.table(
    date = lubridate::as_date(character(0)),
    open = lubridate::as_datetime(character(0), tz = "UTC"),
    close = lubridate::as_datetime(character(0), tz = "UTC"),
    session_open = lubridate::as_datetime(character(0), tz = "UTC"),
    session_close = lubridate::as_datetime(character(0), tz = "UTC"),
    settlement_date = lubridate::as_date(character(0))
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_corporate_actions <- function() {
  return(data.table::data.table(
    id = character(0),
    corporate_action_id = character(0),
    ca_type = character(0),
    ca_sub_type = character(0),
    initiating_symbol = character(0),
    target_symbol = character(0),
    declaration_date = lubridate::as_date(character(0)),
    ex_date = lubridate::as_date(character(0)),
    record_date = lubridate::as_date(character(0)),
    payable_date = lubridate::as_date(character(0)),
    cash = character(0),
    old_rate = character(0),
    new_rate = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_news <- function() {
  return(data.table::data.table(
    id = integer(0),
    headline = character(0),
    author = character(0),
    source = character(0),
    summary = character(0),
    url = character(0),
    symbols = character(0),
    created_at = lubridate::as_datetime(character(0), tz = "UTC"),
    updated_at = lubridate::as_datetime(character(0), tz = "UTC"),
    image_sizes = character(0),
    image_urls = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_most_actives <- function() {
  return(data.table::data.table(
    symbol = character(0),
    volume = numeric(0),
    trade_count = numeric(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_movers <- function() {
  return(data.table::data.table(
    symbol = character(0),
    percent_change = numeric(0),
    change = numeric(0),
    price = numeric(0),
    direction = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_contracts <- function() {
  return(data.table::data.table(
    id = character(0),
    symbol = character(0),
    name = character(0),
    status = character(0),
    tradable = logical(0),
    type = character(0),
    strike_price = character(0),
    expiration_date = lubridate::as_date(character(0)),
    underlying_symbol = character(0),
    style = character(0),
    root_symbol = character(0),
    size = character(0),
    open_interest = character(0),
    close_price = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_positions <- function() {
  return(data.table::data.table(
    asset_id = character(0),
    symbol = character(0),
    exchange = character(0),
    asset_class = character(0),
    avg_entry_price = character(0),
    qty = character(0),
    side = character(0),
    market_value = character(0),
    cost_basis = character(0),
    unrealized_pl = character(0),
    unrealized_plpc = character(0),
    current_price = character(0),
    lastday_price = character(0),
    change_today = character(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_activities <- function() {
  return(data.table::data.table(
    id = character(0),
    activity_type = character(0),
    symbol = character(0),
    side = character(0),
    qty = character(0),
    price = character(0),
    transaction_time = lubridate::as_datetime(character(0), tz = "UTC")
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_portfolio_history <- function() {
  return(data.table::data.table(
    timestamp = lubridate::as_datetime(character(0), tz = "UTC"),
    equity = numeric(0),
    profit_loss = numeric(0),
    profit_loss_pct = numeric(0)
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_watchlists <- function() {
  return(data.table::data.table(
    id = character(0),
    account_id = character(0),
    name = character(0),
    created_at = lubridate::as_datetime(character(0), tz = "UTC"),
    updated_at = lubridate::as_datetime(character(0), tz = "UTC")
  ))
}

#' @keywords internal
#' @noRd
#' @noassert
empty_dt_orders <- function() {
  return(data.table::data.table(
    id = character(0),
    symbol = character(0),
    side = character(0),
    type = character(0),
    status = character(0),
    qty = character(0),
    filled_qty = character(0),
    created_at = lubridate::as_datetime(character(0), tz = "UTC"),
    leg_index = integer(0),
    parent_order_id = character(0)
  ))
}
