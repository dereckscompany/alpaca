# File: R/AlpacaBase.R
# Abstract R6 base class for all Alpaca API client classes.

#' AlpacaBase: Abstract Base Class for Alpaca API Clients
#'
#' Provides shared infrastructure for all Alpaca R6 classes, including API
#' credential management, sync/async execution mode, and a standardised
#' method for calling implementation functions.
#'
#' ### Sync vs Async
#' The `async` parameter controls execution mode for all API methods:
#' - `async = FALSE` (default): methods return results directly (`data.table`, etc.).
#' - `async = TRUE`: methods return [promises::promise] objects that resolve to the same types.
#'
#' When async, use [coro::async()] and `await()` or [promises::then()] to consume results.
#' The `promises` package must be installed for async mode (`Suggests` dependency).
#'
#' ### Authentication
#' Alpaca uses header-based authentication with two headers:
#' - `APCA-API-KEY-ID`: Your API key ID
#' - `APCA-API-SECRET-KEY`: Your API secret key
#'
#' No HMAC signing is required — credentials are sent directly in headers.
#'
#' ### Design
#' This class is not meant to be instantiated directly. Subclasses (e.g.,
#' [AlpacaMarketData], [AlpacaTrading]) inherit from it and define their
#' own public methods that delegate to `private$.request()`.
#'
#' @section Fields:
#' All fields are private:
#' - `.keys`: List; API credentials from [get_api_keys()].
#' - `.base_url`: Character; API base URL from [get_base_url()].
#' - `.perform`: Function; either [httr2::req_perform] or [httr2::req_perform_promise].
#' - `.is_async`: Logical; whether the instance is in async mode.
#'
#' @examples
#' \dontrun{
#' # Not instantiated directly; use subclasses:
#' market <- AlpacaMarketData$new()                 # sync
#' market_async <- AlpacaMarketData$new(async = TRUE)  # async
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom httr2 req_perform
#' @export
AlpacaBase <- R6::R6Class(
  "AlpacaBase",
  public = list(
    #' @description
    #' Initialise an AlpacaBase Object
    #'
    #' @param keys List; API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url Character; API base URL. Defaults to `get_base_url()`.
    #' @param async Logical; if `TRUE`, methods return promises. Default `FALSE`.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE
    ) {
      private$.keys <- keys
      private$.base_url <- base_url
      private$.is_async <- isTRUE(async)

      if (private$.is_async) {
        if (!requireNamespace("promises", quietly = TRUE)) {
          rlang::abort(
            "Package 'promises' is required for async mode. Install with: install.packages('promises')"
          )
        }
        private$.perform <- httr2::req_perform_promise
      } else {
        private$.perform <- httr2::req_perform
      }

      return(invisible(self))
    }
  ),
  active = list(
    #' @field is_async Logical; read-only flag indicating whether this instance
    #'   operates in async mode.
    is_async = function() {
      return(private$.is_async)
    }
  ),
  private = list(
    .keys = NULL,
    .base_url = NULL,
    .perform = NULL,
    .is_async = FALSE,

    # Execute an Alpaca API Request
    #
    # Convenience wrapper around alpaca_build_request() that injects the
    # instance's base URL, credentials, and perform function.
    .request = function(
      endpoint,
      method = "GET",
      query = list(),
      body = NULL,
      auth = TRUE,
      .parser = identity,
      timeout = 10
    ) {
      return(alpaca_build_request(
        base_url = private$.base_url,
        endpoint = endpoint,
        method = method,
        query = query,
        body = body,
        keys = if (auth) private$.keys else NULL,
        .perform = private$.perform,
        .parser = .parser,
        is_async = private$.is_async,
        timeout = timeout
      ))
    }
  )
)
