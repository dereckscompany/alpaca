# File: R/utils.R
# General utility functions for the alpaca package.

#' Retrieve Alpaca API Base URL
#'
#' Returns the base URL for the Alpaca Trading API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `ALPACA_API_ENDPOINT` environment variable.
#' 3. The default `"https://paper-api.alpaca.markets"` (paper trading).
#'
#' @param url (scalar<character> | NULL) explicit base URL. Defaults to
#'   `Sys.getenv("ALPACA_API_ENDPOINT")`.
#' @return (scalar<character>) the API base URL.
#'
#' @examples
#' \dontrun{
#' get_base_url()
#' get_base_url("https://api.alpaca.markets")
#' }
#' @export
get_base_url <- function(url = Sys.getenv("ALPACA_API_ENDPOINT")) {
  assert_args_get_base_url(url)
  if (is.null(url) || !nzchar(url)) {
    return(assert_return_get_base_url("https://paper-api.alpaca.markets"))
  }
  return(assert_return_get_base_url(url))
}

#' Retrieve Alpaca Market Data API Base URL
#'
#' Returns the base URL for the Alpaca Market Data API in the following priority:
#' 1. The explicitly provided `url` parameter.
#' 2. The `ALPACA_DATA_ENDPOINT` environment variable.
#' 3. The default `"https://data.alpaca.markets"`.
#'
#' @param url (scalar<character> | NULL) explicit base URL. Defaults to
#'   `Sys.getenv("ALPACA_DATA_ENDPOINT")`.
#' @return (scalar<character>) the Market Data API base URL.
#'
#' @examples
#' \dontrun{
#' get_data_base_url()
#' get_data_base_url("https://data.sandbox.alpaca.markets")
#' }
#' @export
get_data_base_url <- function(url = Sys.getenv("ALPACA_DATA_ENDPOINT")) {
  assert_args_get_data_base_url(url)
  if (is.null(url) || !nzchar(url)) {
    return(assert_return_get_data_base_url("https://data.alpaca.markets"))
  }
  return(assert_return_get_data_base_url(url))
}

#' Retrieve Alpaca API Credentials
#'
#' Fetches API credentials from environment variables or explicit arguments.
#' Required environment variables: `ALPACA_API_KEY`, `ALPACA_API_SECRET`.
#'
#' @param api_key (scalar<character>) Alpaca API key ID. Defaults to
#'   `Sys.getenv("ALPACA_API_KEY")`.
#' @param api_secret (scalar<character>) Alpaca API secret key. Defaults to
#'   `Sys.getenv("ALPACA_API_SECRET")`.
#' @return (list) the credentials:
#' - api_key (scalar<character>) the API key ID.
#' - api_secret (scalar<character>) the API secret key.
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
  assert_args_get_api_keys(api_key, api_secret)
  if (!nzchar(api_key) || !nzchar(api_secret)) {
    rlang::warn(paste(
      "Alpaca API credentials are empty.",
      "Set ALPACA_API_KEY and ALPACA_API_SECRET environment variables",
      "or pass them explicitly."
    ))
  }
  return(assert_return_get_api_keys(list(
    api_key = api_key,
    api_secret = api_secret
  )))
}
