# File: R/AlpacaBase.R
# Abstract R6 base class for all Alpaca API client classes.

#' AlpacaBase: Abstract Base Class for Alpaca API Clients
#'
#' Provides shared infrastructure for all Alpaca R6 classes, including API
#' credential management, sync/async execution mode, and a standardised
#' request funnel.
#'
#' Inherits the transport from [connectcore::RestClient] and customises the two
#' venue-specific seams: `.sign()` adds Alpaca's API-key headers, and
#' `.parse_envelope()` reads Alpaca's error shape. Every endpoint method on a
#' subclass delegates to the inherited `private$.request()`.
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
#' No HMAC signing is required — credentials are sent directly in headers, which
#' is exactly what the `.sign()` override does.
#'
#' ### Design
#' This class is not meant to be instantiated directly. Subclasses (e.g.,
#' [AlpacaMarketData], [AlpacaTrading]) inherit from it and define their
#' own public methods that delegate to `private$.request()`.
#'
#' @examples
#' \dontrun{
#' # Not instantiated directly; use subclasses:
#' market <- AlpacaMarketData$new()                 # sync
#' market_async <- AlpacaMarketData$new(async = TRUE)  # async
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom httr2 req_headers
#' @export
AlpacaBase <- R6::R6Class(
  "AlpacaBase",
  inherit = connectcore::RestClient,
  public = list(
    #' @description
    #' Initialise an AlpacaBase Object
    #'
    #' @param keys (list) API credentials from [get_api_keys()].
    #'   Defaults to `get_api_keys()`.
    #' @param base_url (scalar<character>) API base URL. Defaults to
    #'   `get_base_url()`.
    #' @param async (scalar<logical>) if `TRUE`, methods return promises. Default
    #'   `FALSE`.
    #' @return (class<AlpacaBase>) invisibly, self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE
    ) {
      assert_args_AlpacaBase__initialize(keys, base_url, async)
      if (isTRUE(async) && !requireNamespace("promises", quietly = TRUE)) {
        rlang::abort(
          "Package 'promises' is required for async mode. Install with: install.packages('promises')"
        )
      }
      super$initialize(
        keys = keys,
        base_url = base_url,
        async = async,
        body_format = "json"
      )
      return(invisible(assert_return_AlpacaBase__initialize(self)))
    }
  ),
  private = list(
    # Authenticate an Alpaca request by adding the two API-key headers. Alpaca
    # uses plain header credentials, not request signing, so this seam just
    # forwards the stored keys onto the request.
    .sign = function(req, keys, ctx) {
      return(httr2::req_headers(
        req,
        `APCA-API-KEY-ID` = keys$api_key,
        `APCA-API-SECRET-KEY` = keys$api_secret
      ))
    },

    # Turn a response into data and raise on error, using Alpaca's error shape:
    # 204 No Content -> empty list; non-2xx carries a `message` (or `msg`) field
    # in the JSON body. Parses with simplifyVector = FALSE (the package default);
    # the one endpoint needing parallel-array simplification handles it in its
    # own parser.
    .parse_envelope = function(resp) {
      return(parse_alpaca_response(resp, simplifyVector = FALSE))
    },

    # Pre-serialise the body to its exact pre-migration wire bytes, then hand it
    # to the shared funnel verbatim via connectcore's raw path. The default JSON
    # path would re-serialise with `auto_unbox = TRUE` and collapse a
    # single-symbol watchlist `symbols` to a scalar; `alpaca_serialize_body()`
    # owns the serialisation instead and keeps `symbols` a JSON array. Bodyless
    # requests fall straight through to the inherited funnel unchanged.
    .request = function(endpoint, method = "GET", query = list(), body = NULL, ...) {
      raw_body <- if (is.null(body)) NULL else alpaca_serialize_body(body)
      # A body that prunes to nothing sent no bytes pre-migration; fall through
      # to the bodyless funnel path rather than emitting an empty-object body.
      if (is.null(raw_body)) {
        return(super$.request(
          endpoint = endpoint,
          method = method,
          query = query,
          body = NULL,
          ...
        ))
      }
      return(super$.request(
        endpoint = endpoint,
        method = method,
        query = query,
        body = raw_body,
        body_format = "raw",
        raw_content_type = "application/json",
        ...
      ))
    }
  )
)
