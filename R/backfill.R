# File: R/backfill.R
# Bulk bar data download with CSV-based resume.

#' Backfill Historical Bar Data
#'
#' Downloads historical OHLCV bar data for one or more symbols and timeframes,
#' saving results to a CSV file. Supports resuming interrupted downloads by
#' reading existing data and skipping completed symbol-timeframe combinations.
#'
#' @param symbols Character vector; ticker symbols (e.g., `c("AAPL", "MSFT")`).
#' @param timeframes Character vector; bar timeframes (e.g., `c("1Day", "1Hour")`).
#'   See [alpaca_timeframe_map] for valid values.
#' @param start Character or POSIXct; start date/time.
#' @param end Character or POSIXct; end date/time. Defaults to `Sys.time()`.
#' @param path Character; file path for CSV output. Default `"alpaca_bars.csv"`.
#' @param adjustment Character; price adjustment type. Default `"raw"`.
#' @param feed Character or NULL; data feed (`"iex"` or `"sip"`).
#' @param sleep Numeric; seconds to pause between requests (rate limiting).
#'   Default `0.25`.
#' @param keys List; API credentials. Defaults to [get_api_keys()].
#' @param data_base_url Character; market data base URL. Defaults to [get_data_base_url()].
#' @return `data.table` with all downloaded data (invisibly). Also writes to CSV.
#'   Has a `"failures"` attribute listing any symbol-timeframe combos that failed.
#'
#' @examples
#' \dontrun{
#' # Download daily bars for AAPL and MSFT
#' dt <- alpaca_backfill_bars(
#'   symbols = c("AAPL", "MSFT"),
#'   timeframes = "1Day",
#'   start = "2020-01-01",
#'   path = "data/bars.csv"
#' )
#'
#' # Resume an interrupted download
#' dt <- alpaca_backfill_bars(
#'   symbols = c("AAPL", "MSFT", "TSLA"),
#'   timeframes = c("1Day", "1Hour"),
#'   start = "2020-01-01",
#'   path = "data/bars.csv"
#' )
#' }
#'
#' @export
alpaca_backfill_bars <- function(
  symbols,
  timeframes = "1Day",
  start,
  end = Sys.time(),
  path = "alpaca_bars.csv",
  adjustment = "raw",
  feed = NULL,
  sleep = 0.25,
  keys = get_api_keys(),
  data_base_url = get_data_base_url()
) {
  if (is.character(start)) {
    start <- lubridate::as_datetime(start, tz = "UTC")
  }
  if (is.character(end)) {
    end <- lubridate::as_datetime(end, tz = "UTC")
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
    return(invisible(existing))
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
          start = start,
          end = end,
          keys = keys,
          data_base_url = data_base_url,
          adjustment = adjustment,
          feed = feed,
          sleep = sleep
        )
      },
      error = function(e) {
        message(sprintf("    ERROR: %s", conditionMessage(e)))
        NULL
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
  if (nrow(combined) > 0 && "timestamp" %in% names(combined)) {
    combined <- unique(combined, by = c("symbol", "timeframe", "timestamp"))
    data.table::setorder(combined, symbol, timeframe, timestamp)
  }

  # Write CSV
  data.table::fwrite(combined, path)
  message(sprintf("\nDone. %d total rows written to %s", nrow(combined), path))

  if (length(failures) > 0) {
    message(sprintf("Failed: %s", paste(failures, collapse = ", ")))
  }

  attr(combined, "failures") <- failures
  return(invisible(combined))
}
