# File: R/utils.R
# General utility functions for the alpaca package.

#' Retrieve Alpaca API Base URL
#'
#' Returns the base URL for the Alpaca Trading API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `ALPACA_API_ENDPOINT` environment variable.
#' 3. The default `"https://paper-api.alpaca.markets"` (paper trading).
#'
#' @param url Character string; explicit base URL. Defaults to
#'   `Sys.getenv("ALPACA_API_ENDPOINT")`.
#' @return Character string; the API base URL.
#'
#' @examples
#' \dontrun{
#' get_base_url()
#' get_base_url("https://api.alpaca.markets")
#' }
#' @export
get_base_url <- function(url = Sys.getenv("ALPACA_API_ENDPOINT")) {
  if (is.null(url) || !nzchar(url)) {
    return("https://paper-api.alpaca.markets")
  }
  return(url)
}

#' Retrieve Alpaca Market Data API Base URL
#'
#' Returns the base URL for the Alpaca Market Data API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `ALPACA_DATA_ENDPOINT` environment variable.
#' 3. The default `"https://data.alpaca.markets"`.
#'
#' @param url Character string; explicit base URL. Defaults to
#'   `Sys.getenv("ALPACA_DATA_ENDPOINT")`.
#' @return Character string; the Market Data API base URL.
#'
#' @examples
#' \dontrun{
#' get_data_base_url()
#' get_data_base_url("https://data.sandbox.alpaca.markets")
#' }
#' @export
get_data_base_url <- function(url = Sys.getenv("ALPACA_DATA_ENDPOINT")) {
  if (is.null(url) || !nzchar(url)) {
    return("https://data.alpaca.markets")
  }
  return(url)
}

#' Retrieve Alpaca API Credentials
#'
#' Fetches API credentials from environment variables or explicit arguments.
#' Required environment variables: `ALPACA_API_KEY`, `ALPACA_API_SECRET`.
#'
#' @param api_key Character string; Alpaca API key ID. Defaults to
#'   `Sys.getenv("ALPACA_API_KEY")`.
#' @param api_secret Character string; Alpaca API secret key. Defaults to
#'   `Sys.getenv("ALPACA_API_SECRET")`.
#' @return Named list with `api_key` and `api_secret`.
#'
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' keys <- get_api_keys(api_key = "my_key", api_secret = "my_secret")
#' }
#' @export
get_api_keys <- function(
  api_key = Sys.getenv("ALPACA_API_KEY"),
  api_secret = Sys.getenv("ALPACA_API_SECRET")
) {
  return(list(
    api_key = api_key,
    api_secret = api_secret
  ))
}
