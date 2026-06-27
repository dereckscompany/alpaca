# File: R/utils_time.R
# Timestamp conversion utilities for the Alpaca API.

#' Convert RFC-3339 Timestamp to POSIXct
#'
#' Parses an RFC-3339 timestamp string (e.g., `"2024-01-15T14:30:00Z"`) into
#' a `POSIXct` object in UTC. Returns `NA` for `NULL` or `NA` input.
#'
#' @param x (any?) RFC-3339 timestamp string(s), a bare `NA`, or `NULL`.
#' @return (POSIXct | NA) the parsed UTC date-times, or `NA` if input is
#'   `NULL`/`NA`.
#'
#' @examples
#' time_convert_from_alpaca("2024-01-15T14:30:00Z")
#' time_convert_from_alpaca("2024-01-15T14:30:00.123-05:00")
#'
#' @importFrom lubridate as_datetime
#' @export
time_convert_from_alpaca <- function(x) {
  assert_args_time_convert_from_alpaca(x)
  if (is.null(x) || all(is.na(x))) {
    return(assert_return_time_convert_from_alpaca(lubridate::NA_POSIXct_))
  }
  return(assert_return_time_convert_from_alpaca(lubridate::as_datetime(x)))
}

#' Convert POSIXct to RFC-3339 Timestamp String
#'
#' Formats a `POSIXct` object as an RFC-3339 timestamp string suitable for
#' the Alpaca API. Output is always in UTC with `Z` suffix.
#'
#' @param x (any?) a date-time (or character coercible to POSIXct), a bare `NA`,
#'   or `NULL`.
#' @return (character | NA) RFC-3339 strings (e.g., `"2024-01-15T14:30:00Z"`),
#'   or `NA` if input is `NULL`/`NA`.
#'
#' @examples
#' time_convert_to_alpaca(Sys.time())
#' time_convert_to_alpaca(as.POSIXct("2024-01-15 14:30:00", tz = "UTC"))
#'
#' @export
time_convert_to_alpaca <- function(x) {
  assert_args_time_convert_to_alpaca(x)
  if (is.null(x) || all(is.na(x))) {
    return(assert_return_time_convert_to_alpaca(NA_character_))
  }
  if (is.character(x)) {
    x <- lubridate::as_datetime(x, tz = "UTC")
  }
  return(assert_return_time_convert_to_alpaca(format(x, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")))
}
