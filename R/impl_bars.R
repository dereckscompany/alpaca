# File: R/impl_bars.R
# Shared bar-fetching implementation with time-range segmentation.

#' Alpaca Timeframe-to-Seconds Mapping
#'
#' Maps Alpaca bar timeframe strings to their duration in seconds. Used for
#' time-range segmentation in bulk bar downloads.
#'
#' @keywords internal
#' @noRd
alpaca_timeframe_map <- c(
  "1Min" = 60,
  "5Min" = 300,
  "15Min" = 900,
  "30Min" = 1800,
  "1Hour" = 3600,
  "2Hour" = 7200,
  "4Hour" = 14400,
  "1Day" = 86400,
  "1Week" = 604800,
  "1Month" = 2592000
)

#' Fetch Bars with Time-Range Segmentation
#'
#' Fetches historical bar data for a single symbol, automatically segmenting
#' large date ranges into multiple API requests (Alpaca max 10,000 bars per
#' request). Returns a single `data.table` with deduplicated, sorted results.
#'
#' @param symbol Character; ticker symbol.
#' @param timeframe Character; bar timeframe (e.g., `"1Day"`).
#' @param start POSIXct or character; start timestamp.
#' @param end POSIXct or character; end timestamp.
#' @param keys List; API credentials from [get_api_keys()].
#' @param data_base_url Character; market data API base URL.
#' @param .perform Function; httr2 perform function.
#' @param is_async Logical; async mode flag.
#' @param adjustment Character; price adjustment (`"raw"`, `"split"`, `"dividend"`, `"all"`).
#' @param feed Character or NULL; data feed (`"iex"` or `"sip"`).
#' @param limit_per_request Integer; max bars per request. Default 10000.
#' @param sleep Numeric; seconds to sleep between requests. Default 0.2.
#' @return `data.table` with columns: timestamp, open, high, low, close, volume,
#'   trade_count, vwap.
#'
#' @keywords internal
#' @noRd
alpaca_fetch_bars <- function(
  symbol,
  timeframe = "1Day",
  start,
  end,
  keys,
  data_base_url,
  .perform = httr2::req_perform,
  is_async = FALSE,
  adjustment = "raw",
  feed = NULL,
  limit_per_request = 10000L,
  sleep = 0.2
) {
  # Convert to POSIXct if needed
  if (is.character(start)) {
    start <- lubridate::as_datetime(start, tz = "UTC")
  }
  if (is.character(end)) {
    end <- lubridate::as_datetime(end, tz = "UTC")
  }

  bar_seconds <- alpaca_timeframe_map[[timeframe]]
  if (is.null(bar_seconds)) {
    rlang::abort(paste0(
      "Unknown timeframe: ",
      timeframe,
      ". Valid: ",
      paste(names(alpaca_timeframe_map), collapse = ", ")
    ))
  }

  # Compute segments
  span_seconds <- lubridate::time_length(end - start, unit = "seconds")
  segment_seconds <- limit_per_request * bar_seconds
  n_segments <- max(1L, ceiling(span_seconds / segment_seconds))

  results <- vector("list", n_segments)
  seg_start <- start

  for (i in seq_len(n_segments)) {
    seg_end <- min(seg_start + segment_seconds, end)

    dt <- alpaca_build_request(
      base_url = data_base_url,
      endpoint = paste0("/v2/stocks/", symbol, "/bars"),
      method = "GET",
      query = list(
        timeframe = timeframe,
        start = format(seg_start, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        end = format(seg_end, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        limit = limit_per_request,
        adjustment = adjustment,
        feed = feed
      ),
      keys = keys,
      .perform = .perform,
      .parser = function(data) parse_bars(data$bars),
      is_async = is_async,
      timeout = 30
    )

    results[[i]] <- dt
    seg_start <- seg_end

    if (i < n_segments && sleep > 0) {
      Sys.sleep(sleep)
    }
  }

  # Combine and deduplicate
  combined <- data.table::rbindlist(results, fill = TRUE)
  if (nrow(combined) > 0 && "timestamp" %in% names(combined)) {
    combined <- unique(combined, by = "timestamp")
    data.table::setorder(combined, timestamp)
  }

  return(combined)
}
