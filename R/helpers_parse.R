# File: R/helpers_parse.R
# Response parsing and data.table construction helpers.

#' Convert camelCase Names to snake_case
#'
#' @param names Character vector; names to convert.
#' @return Character vector; converted snake_case names.
#'
#' @keywords internal
#' @noRd
to_snake_case <- function(names) {
  out <- gsub("([a-z0-9])([A-Z])", "\\1_\\2", names)
  out <- gsub("([A-Z])([A-Z][a-z])", "\\1_\\2", out)
  out <- tolower(out)
  return(out)
}

#' Convert a Named List to a Single-Row data.table
#'
#' Converts a flat named list (typically from an Alpaca API JSON response)
#' into a single-row [data.table::data.table]. NULL values become NA.
#' Column names are converted to snake_case.
#'
#' @param x A named list.
#' @return A single-row [data.table::data.table] with snake_case column names.
#'
#' @keywords internal
#' @noRd
as_dt_row <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(data.table::data.table())
  }
  x <- lapply(x, function(val) {
    if (is.null(val)) {
      return(NA)
    }
    if (is.list(val) && length(val) == 0) {
      return(NA)
    }
    if (is.list(val) && length(val) > 1) {
      return(list(val))
    }
    return(val)
  })
  dt <- data.table::as.data.table(x)
  data.table::setnames(dt, to_snake_case(names(dt)))
  return(dt)
}

#' Convert a List of Lists to a data.table
#'
#' Takes a list where each element is a named list (e.g., from a JSON array)
#' and row-binds them into a [data.table::data.table] with snake_case columns.
#'
#' @param items A list of named lists, or NULL.
#' @return A [data.table::data.table]. Returns an empty data.table if `items`
#'   is NULL or empty.
#'
#' @keywords internal
#' @noRd
as_dt_list <- function(items) {
  if (is.null(items) || length(items) == 0) {
    return(data.table::data.table())
  }
  dt <- data.table::rbindlist(lapply(items, as_dt_row), fill = TRUE)
  return(dt)
}

#' Parse an RFC-3339 Timestamp to POSIXct
#'
#' @param x Character; RFC-3339 timestamp string (e.g., `"2024-01-15T14:30:00Z"`).
#' @return POSIXct in UTC, or NA if `x` is NULL/NA.
#'
#' @importFrom lubridate as_datetime
#' @keywords internal
#' @noRd
rfc3339_to_datetime <- function(x) {
  if (is.null(x) || all(is.na(x))) {
    return(lubridate::NA_POSIXct_)
  }
  return(lubridate::as_datetime(x))
}

#' Parse Alpaca Bar Data to data.table
#'
#' Converts a list of bar objects (with short field names `t`, `o`, `h`, `l`,
#' `c`, `v`, `n`, `vw`) into a tidy [data.table::data.table] with descriptive
#' column names.
#'
#' @param bars A list of bar objects from the Alpaca API.
#' @return A [data.table::data.table] with columns: `timestamp`, `open`,
#'   `high`, `low`, `close`, `volume`, `trade_count`, `vwap`.
#'
#' @keywords internal
#' @noRd
parse_bars <- function(bars) {
  if (is.null(bars) || length(bars) == 0) {
    return(data.table::data.table())
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
  current <- names(dt)
  new_names <- ifelse(current %in% names(name_map), name_map[current], current)
  data.table::setnames(dt, new_names)
  if ("timestamp" %in% names(dt)) {
    dt[, timestamp := rfc3339_to_datetime(timestamp)]
  }
  return(dt)
}

#' Parse Multi-Symbol Bar Response
#'
#' Alpaca's multi-symbol bars endpoint returns
#' `{"bars": {"AAPL": [...], ...}, "next_page_token": ...}`. This function
#' flattens that structure into a single data.table with a `symbol` column.
#'
#' @param data List; the parsed Alpaca response.
#' @return A [data.table::data.table] with a `symbol` column prepended.
#'
#' @keywords internal
#' @noRd
parse_multi_bars <- function(data) {
  bars_map <- data$bars
  if (is.null(bars_map) || length(bars_map) == 0) {
    return(data.table::data.table())
  }
  dts <- lapply(names(bars_map), function(sym) {
    dt <- parse_bars(bars_map[[sym]])
    if (nrow(dt) > 0) {
      dt[, symbol := sym]
      data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
    }
    return(dt)
  })
  return(data.table::rbindlist(dts, fill = TRUE))
}

#' Parse Alpaca Trade Data to data.table
#'
#' Converts a list of trade objects (with short field names) into a tidy
#' [data.table::data.table] with descriptive column names.
#'
#' @param trades A list of trade objects from the Alpaca API.
#' @return A [data.table::data.table] with columns: `timestamp`, `price`,
#'   `size`, `exchange`, `conditions`, `tape`, `id`.
#'
#' @keywords internal
#' @noRd
parse_trades <- function(trades) {
  if (is.null(trades) || length(trades) == 0) {
    return(data.table::data.table())
  }
  dt <- data.table::rbindlist(trades, fill = TRUE)
  name_map <- c(
    t = "timestamp",
    p = "price",
    s = "size",
    x = "exchange",
    c = "conditions",
    z = "tape",
    i = "id"
  )
  current <- names(dt)
  new_names <- ifelse(current %in% names(name_map), name_map[current], current)
  data.table::setnames(dt, new_names)
  if ("timestamp" %in% names(dt)) {
    dt[, timestamp := rfc3339_to_datetime(timestamp)]
  }
  return(dt)
}

#' Parse Alpaca Quote Data to data.table
#'
#' Converts a list of quote objects (with short field names) into a tidy
#' [data.table::data.table] with descriptive column names.
#'
#' @param quotes A list of quote objects from the Alpaca API.
#' @return A [data.table::data.table] with descriptive column names.
#'
#' @keywords internal
#' @noRd
parse_quotes <- function(quotes) {
  if (is.null(quotes) || length(quotes) == 0) {
    return(data.table::data.table())
  }
  dt <- data.table::rbindlist(quotes, fill = TRUE)
  name_map <- c(
    t = "timestamp",
    ax = "ask_exchange",
    ap = "ask_price",
    "as" = "ask_size",
    bx = "bid_exchange",
    bp = "bid_price",
    bs = "bid_size",
    c = "conditions",
    z = "tape"
  )
  current <- names(dt)
  new_names <- ifelse(current %in% names(name_map), name_map[current], current)
  data.table::setnames(dt, new_names)
  if ("timestamp" %in% names(dt)) {
    dt[, timestamp := rfc3339_to_datetime(timestamp)]
  }
  return(dt)
}

#' Parse Snapshot Data to data.table
#'
#' Flattens Alpaca's nested snapshot response (containing latestTrade,
#' latestQuote, minuteBar, dailyBar, prevDailyBar) into a single-row
#' data.table with prefixed column names.
#'
#' @param snapshot A named list representing an Alpaca snapshot.
#' @return A single-row [data.table::data.table].
#'
#' @keywords internal
#' @noRd
parse_snapshot <- function(snapshot) {
  if (is.null(snapshot) || length(snapshot) == 0) {
    return(data.table::data.table())
  }
  flat <- list()
  for (section in c("latestTrade", "latestQuote", "minuteBar", "dailyBar", "prevDailyBar")) {
    sub <- snapshot[[section]]
    if (!is.null(sub)) {
      prefix <- to_snake_case(section)
      for (nm in names(sub)) {
        flat[[paste0(prefix, "_", nm)]] <- sub[[nm]]
      }
    }
  }
  return(as_dt_row(flat))
}
