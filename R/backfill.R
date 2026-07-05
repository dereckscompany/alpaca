# File: R/backfill.R
# Bulk bar data download with CSV-based resume.

#' Backfill Historical Bar Data
#'
#' Downloads historical OHLCV bar data for one or more symbols and timeframes,
#' saving results to a CSV file. Supports resuming interrupted downloads by
#' reading existing data and skipping completed symbol-timeframe combinations.
#'
#' @param symbols (character) ticker symbols (e.g., `c("AAPL", "MSFT")`).
#' @param timeframes (character) bar timeframes (e.g., `c("1Day", "1Hour")`).
#'   See `alpaca_timeframe_map` for valid values.
#' @param from (POSIXct | character) start date/time.
#' @param to (POSIXct | character) end date/time. Defaults to the current UTC
#'   time ([lubridate::now()]).
#' @param path (scalar<character>) file path for CSV output. Default
#'   `"alpaca_bars.csv"`.
#' @param adjustment (scalar<character>) price adjustment type. Default `"raw"`.
#' @param feed (scalar<character> | NULL) data feed (`"iex"` or `"sip"`).
#' @param sleep (scalar<numeric in [0, Inf[>) seconds to pause between requests
#'   (rate limiting). Default `0.25`.
#' @param keys (list) API credentials. Defaults to [get_api_keys()].
#' @param data_base_url (scalar<character>) market data base URL. Defaults to
#'   [get_data_base_url()].
#' @return (class<data.table>) all downloaded data (invisibly). Also writes to
#'   CSV.
#'
#'   Per-combo failures are surfaced as warnings during the run (one
#'   `rlang::warn()` per failed `(symbol, timeframe)` pair, with the
#'   underlying error message). After the loop, if any combinations
#'   failed, a final summary warning lists the count and the affected
#'   pairs. No failure data is hidden on the return value.
#'
#' @examples
#' \dontrun{
#' # Download daily bars for AAPL and MSFT
#' dt <- alpaca_backfill_bars(
#'   symbols = c("AAPL", "MSFT"),
#'   timeframes = "1Day",
#'   from = "2020-01-01",
#'   path = "data/bars.csv"
#' )
#'
#' # Resume an interrupted download
#' dt <- alpaca_backfill_bars(
#'   symbols = c("AAPL", "MSFT", "TSLA"),
#'   timeframes = c("1Day", "1Hour"),
#'   from = "2020-01-01",
#'   path = "data/bars.csv"
#' )
#' }
#'
#' @export
alpaca_backfill_bars <- function(
  symbols,
  timeframes = "1Day",
  from,
  to = lubridate::now(tzone = "UTC"),
  path = "alpaca_bars.csv",
  adjustment = "raw",
  feed = NULL,
  sleep = 0.25,
  keys = get_api_keys(),
  data_base_url = get_data_base_url()
) {
  assert_args_alpaca_backfill_bars(
    symbols,
    timeframes,
    from,
    to,
    path,
    adjustment,
    feed,
    sleep,
    keys,
    data_base_url
  )
  if (is.character(from)) {
    from <- lubridate::as_datetime(from, tz = "UTC")
  }
  if (is.character(to)) {
    to <- lubridate::as_datetime(to, tz = "UTC")
  }

  # Read existing CSV for resume support
  existing <- data.table::data.table()
  completed <- character()
  if (file.exists(path)) {
    existing <- data.table::fread(path)
    if (nrow(existing) > 0 && all(c("symbol", "timeframe") %in% names(existing))) {
      completed <- unique(paste(existing$symbol, existing$timeframe, sep = "|"))
    }
    message(sprintf("Resuming: %d existing rows, %d combos already done.", nrow(existing), length(completed)))
  }

  # Build task grid
  tasks <- expand.grid(symbol = symbols, timeframe = timeframes, stringsAsFactors = FALSE)
  tasks$key <- paste(tasks$symbol, tasks$timeframe, sep = "|")
  tasks <- tasks[!tasks$key %in% completed, , drop = FALSE]

  if (nrow(tasks) == 0) {
    message("All symbol-timeframe combinations already downloaded.")
    return(invisible(assert_return_alpaca_backfill_bars(existing)))
  }

  message(sprintf("Downloading %d symbol-timeframe combination(s)...\n", nrow(tasks)))

  results <- list(existing)
  failures <- character()

  for (i in seq_len(nrow(tasks))) {
    sym <- tasks$symbol[i]
    tf <- tasks$timeframe[i]
    message(sprintf("  [%d/%d] %s %s", i, nrow(tasks), sym, tf))

    dt <- tryCatch(
      {
        alpaca_fetch_bars(
          symbol = sym,
          timeframe = tf,
          start = from,
          end = to,
          keys = keys,
          data_base_url = data_base_url,
          adjustment = adjustment,
          feed = feed,
          sleep = sleep
        )
      },
      error = function(e) {
        rlang::warn(sprintf(
          "[%d/%d] %s %s: FAILED - %s",
          i,
          nrow(tasks),
          sym,
          tf,
          conditionMessage(e)
        ))
        return(NULL)
      }
    )

    if (!is.null(dt) && nrow(dt) > 0) {
      dt[, symbol := sym]
      dt[, timeframe := tf]
      results <- c(results, list(dt))
      message(sprintf("    %d bars", nrow(dt)))
    } else if (is.null(dt)) {
      failures <- c(failures, paste(sym, tf, sep = "|"))
    } else {
      message("    0 bars (no data in range)")
    }

    if (i < nrow(tasks) && sleep > 0) {
      Sys.sleep(sleep)
    }
  }

  combined <- data.table::rbindlist(results, fill = TRUE)

  # Deduplicate
  if (nrow(combined) > 0 && "datetime" %in% names(combined)) {
    combined <- unique(combined, by = c("symbol", "timeframe", "datetime"))
    data.table::setorder(combined, symbol, timeframe, datetime)
  }

  # Write CSV
  data.table::fwrite(combined, path)
  message(sprintf("\nDone. %d total rows written to %s", nrow(combined), path))

  # Final summary warning if anything failed. Per-combo warnings already
  # fired inside the tryCatch above; this gives a single line the user
  # can't miss if the verbose per-combo output scrolled past.
  if (length(failures) > 0) {
    rlang::warn(sprintf(
      "alpaca_backfill_bars: %d of %d (symbol, timeframe) combinations failed: %s",
      length(failures),
      nrow(tasks),
      paste(failures, collapse = ", ")
    ))
  }

  return(invisible(assert_return_alpaca_backfill_bars(combined)))
}
