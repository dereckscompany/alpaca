# File: R/helpers_request.R
# Free-function request helpers for the alpaca package. The single request
# funnel and the sync/async branch point come from connectcore; this file keeps
# the Alpaca-specific error envelope, the header-auth signer, the cursor
# paginator, and the thin `alpaca_build_request()` wrapper the bulk-bar and
# market-data paths use directly.

#' Sign an Alpaca request with API-key headers
#'
#' Adds Alpaca's two authentication headers (`APCA-API-KEY-ID`,
#' `APCA-API-SECRET-KEY`) from the supplied credentials. Alpaca uses plain
#' header credentials, not request signing, so this is the connector's `.sign()`
#' seam: no timestamp or HMAC is involved.
#'
#' @param req (class<httr2_request>) the request to sign.
#' @param keys (list) credentials with `api_key` and `api_secret`.
#' @param ctx (list) signing context (unused — Alpaca needs no server clock).
#' @return (class<httr2_request>) the request with the two API-key headers added.
#' @noassert
#'
#' @importFrom httr2 req_headers
#' @keywords internal
#' @noRd
alpaca_sign <- function(req, keys, ctx = list()) {
  return(httr2::req_headers(
    req,
    `APCA-API-KEY-ID` = keys$api_key,
    `APCA-API-SECRET-KEY` = keys$api_secret
  ))
}

#' Serialise an Alpaca request body to its exact wire bytes
#'
#' Pre-serialises a body list to the JSON string Alpaca expects, reproducing the
#' byte-for-byte output the package produced before the connectcore migration.
#' The pre-migration funnel sent bodies through `httr2::req_body_json()`, which
#' serialises with `jsonlite::toJSON(auto_unbox = TRUE, digits = 22, null =
#' "null")`; this helper uses those exact options so the migrated transport
#' (which sends the result verbatim via connectcore's `body_format = "raw"`
#' path) is wire-identical.
#'
#' The one deliberate departure is the `symbols` field. Alpaca's watchlist
#' endpoints require `symbols` to be a JSON array, but `auto_unbox = TRUE`
#' collapses a single-element character vector to a bare scalar (`"AAPL"`
#' instead of `["AAPL"]`), which the API rejects. Wrapping `symbols` in
#' [as.list()] keeps it an array for any length without touching any other
#' field's bytes.
#'
#' @param body (list) the request body. NULL entries are dropped first
#'   (matching the pre-migration funnel).
#' @return (scalar<character> | NULL) the serialised JSON body, or `NULL` when
#'   the body prunes to nothing (the pre-migration funnel sent no body in that
#'   case).
#'
#' @keywords internal
#' @noRd
alpaca_serialize_body <- function(body) {
  assert_args_alpaca_serialize_body(body)
  body <- body[!vapply(body, is.null, logical(1))]
  if (length(body) == 0L) {
    return(assert_return_alpaca_serialize_body(NULL))
  }
  if (!is.null(body$symbols)) {
    # Keep `symbols` a JSON array even for a single symbol; auto_unbox would
    # otherwise emit a scalar, which Alpaca's watchlist endpoints reject.
    body$symbols <- as.list(body$symbols)
  }
  return(assert_return_alpaca_serialize_body(as.character(jsonlite::toJSON(
    body,
    auto_unbox = TRUE,
    digits = 22,
    null = "null"
  ))))
}

#' Build and Execute an Alpaca API Request
#'
#' Constructs an [httr2::request], adds authentication headers, performs it via
#' the supplied `.perform` function, and parses the JSON response. This is the
#' single point through which the bulk-bar and market-data paths flow; it
#' delegates the transport to [connectcore::build_request()] and supplies the
#' Alpaca header signer and error-envelope parser.
#'
#' ### Authentication
#' Alpaca uses header-based authentication with two headers:
#' - `APCA-API-KEY-ID`: Your API key ID
#' - `APCA-API-SECRET-KEY`: Your API secret key
#'
#' @param base_url (scalar<character>) the API base URL.
#' @param endpoint (scalar<character>) the API path (e.g., `"/v2/account"`).
#' @param method (scalar<character>) HTTP method. Default `"GET"`.
#' @param query (list) query parameters. Default `list()`.
#' @param body (list | NULL) JSON request body (for POST/PATCH). Default `NULL`.
#' @param keys (list | NULL) API credentials with `api_key` and `api_secret`.
#'   Default `NULL` (no auth).
#' @param .perform (function) the httr2 perform function. Default
#'   `httr2::req_perform`.
#' @param .parser (function) post-processing function applied to parsed
#'   response. Default `identity`.
#' @param is_async (scalar<logical>) whether `.perform` returns promises.
#'   Default `FALSE`.
#' @param timeout (scalar<numeric in ]0, Inf[>) request timeout in seconds.
#'   Default `10`.
#' @param simplifyVector (scalar<logical>) passed to [httr2::resp_body_json].
#'   Default `FALSE`. Set to `TRUE` for endpoints returning parallel arrays so
#'   JSON nulls become NA in atomic vectors.
#' @return (any | promise<any>) parsed and post-processed API response data, or
#'   a promise thereof.
#'
#' @importFrom httr2 req_perform
#' @export
alpaca_build_request <- function(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  timeout = 10,
  simplifyVector = FALSE # nolint: object_name_linter. mirrors httr2::resp_body_json's argument name verbatim.
) {
  assert_args_alpaca_build_request(
    base_url,
    endpoint,
    method,
    query,
    body,
    keys,
    .perform,
    .parser,
    is_async,
    timeout,
    simplifyVector
  )
  return(assert_return_alpaca_build_request(connectcore::build_request(
    base_url = base_url,
    endpoint = endpoint,
    method = method,
    query = query,
    body = body,
    keys = keys,
    sign = alpaca_sign,
    parse_envelope = function(resp) parse_alpaca_response(resp, simplifyVector = simplifyVector),
    body_format = "json",
    .perform = .perform,
    .parser = .parser,
    is_async = is_async,
    timeout = timeout
  )))
}

#' Auto-Paginate an Alpaca API Endpoint
#'
#' Follows Alpaca's cursor-based pagination (`page_token` / `next_page_token`)
#' automatically, accumulating results across all pages. Works with any
#' paginated endpoint (orders, activities, bars, trades, quotes, etc.).
#'
#' Alpaca endpoints return a `next_page_token` field when more results are
#' available. This function loops through pages until no more tokens remain
#' or `max_pages` is reached, then applies `.parser` to the combined result
#' list.
#'
#' If `max_pages` is hit while the server still reports more data
#' (`next_page_token` present), the accumulated pages are returned anyway —
#' fetched work is never thrown away — but an `rlang::warn()` fires so the
#' truncation can never pass silently. Resume by re-requesting with a later
#' `start` (bars/trades/quotes are time-ordered) or by raising `max_pages`.
#'
#' @param base_url (scalar<character>) the API base URL.
#' @param endpoint (scalar<character>) the API path (e.g., `"/v2/orders"`).
#' @param method (scalar<character>) HTTP method. Default `"GET"`.
#' @param query (list) query parameters. Default `list()`.
#' @param keys (list | NULL) API credentials.
#' @param .perform (function) the httr2 perform function.
#' @param .parser (function) applied to the accumulated list of page items.
#'   Receives a single flat list of all items across pages.
#' @param is_async (scalar<logical>) whether `.perform` returns promises.
#' @param items_field (scalar<character> | NULL) the JSON field containing the
#'   array of items (e.g., `"bars"`, `"trades"`, `"quotes"`). If `NULL`, the
#'   entire response list is accumulated (for endpoints returning top-level
#'   arrays).
#' @param max_pages (scalar<numeric in [1, Inf]> | scalar<integer in [1, Inf[>) maximum
#'   number of pages to fetch. Default `Inf`.
#' @param sleep (scalar<numeric in [0, Inf[>) seconds to pause between page
#'   requests, to respect rate limits (Alpaca's free/Basic data tier caps at
#'   200 req/min). Applied in synchronous mode only. Default `0`.
#' @param timeout (scalar<numeric in ]0, Inf[>) request timeout in seconds.
#'   Default `10`.
#' @return (any | promise<any>) parsed and post-processed API response data, or
#'   a promise thereof.
#'
#' @examples
#' \dontrun{
#' # Fetch ALL historical bars across pages
#' all_bars <- alpaca_paginate(
#'   base_url = "https://data.alpaca.markets",
#'   endpoint = "/v2/stocks/AAPL/bars",
#'   query = list(timeframe = "1Day", start = "2020-01-01"),
#'   keys = get_api_keys(),
#'   items_field = "bars",
#'   .parser = parse_bars
#' )
#' }
#'
#' @importFrom httr2 req_perform
#' @export
alpaca_paginate <- function(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  items_field = NULL,
  max_pages = Inf,
  sleep = 0,
  timeout = 10
) {
  assert_args_alpaca_paginate(
    base_url,
    endpoint,
    method,
    query,
    keys,
    .perform,
    .parser,
    is_async,
    items_field,
    max_pages,
    sleep,
    timeout
  )
  accumulator <- list()
  page_count <- 0L

  fetch_page <- function(page_token = NULL) {
    q <- query
    if (!is.null(page_token)) {
      q$page_token <- page_token
    }

    result <- alpaca_build_request(
      base_url = base_url,
      endpoint = endpoint,
      method = method,
      query = q,
      keys = keys,
      .perform = .perform,
      is_async = is_async,
      timeout = timeout
    )

    return(connectcore::then_or_now(
      result,
      function(data) {
        page_count <<- page_count + 1L

        if (!is.null(items_field)) {
          page_items <- data[[items_field]]
        } else {
          page_items <- data
        }

        if (!is.null(page_items) && length(page_items) > 0) {
          accumulator <<- c(accumulator, page_items)
        }

        next_token <- data$next_page_token
        has_more <- !is.null(next_token) && nzchar(next_token)

        if (has_more && page_count < max_pages) {
          # Throttle between pages (sync only; a blocking sleep would stall the
          # event loop in async mode).
          if (!is_async && sleep > 0) {
            Sys.sleep(sleep)
          }
          return(fetch_page(next_token))
        }

        # Stopped with the server still reporting more data: keep what we have
        # but make the truncation impossible to miss.
        if (has_more) {
          rlang::warn(sprintf(
            paste0(
              "alpaca_paginate: stopped at max_pages = %s with more data ",
              "still available (fetched %d page(s)). Returning a partial ",
              "result. Resume from a later `start`, or raise `max_pages`."
            ),
            format(max_pages),
            page_count
          ))
        }

        return(.parser(accumulator))
      },
      is_async = is_async
    ))
  }

  return(assert_return_alpaca_paginate(fetch_page()))
}

#' Parse and Validate an Alpaca API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status, and
#' returns the parsed data. Alpaca returns error details in the JSON body
#' with a `message` field. This is the connector's `.parse_envelope()` seam.
#'
#' @param resp (class<httr2_response>) the response object.
#' @param simplifyVector (scalar<logical>) passed to [httr2::resp_body_json].
#'   Default `FALSE` (lists preserved). Set to `TRUE` for endpoints returning
#'   parallel arrays (e.g., portfolio history) so JSON nulls become NA in atomic
#'   vectors.
#' @return (any) the parsed JSON response data.
#'
#' @importFrom httr2 resp_status resp_body_json resp_body_string
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
# nolint start: object_name_linter. `simplifyVector` mirrors httr2::resp_body_json's argument name verbatim.
parse_alpaca_response <- function(resp, simplifyVector = FALSE) {
  # nolint end
  assert_args_parse_alpaca_response(resp, simplifyVector)
  status <- httr2::resp_status(resp)

  # Handle 204 No Content (e.g., successful DELETE)
  if (status == 204L) {
    return(assert_return_parse_alpaca_response(list()))
  }

  parsed <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = simplifyVector),
    error = function(e) NULL
  )

  if (status < 200L || status >= 300L) {
    msg <- "No error message provided."
    if (!is.null(parsed)) {
      msg <- if (!is.null(parsed$message)) {
        parsed$message
      } else if (!is.null(parsed$msg)) {
        parsed$msg
      } else {
        msg
      }
    } else {
      msg <- tryCatch(
        httr2::resp_body_string(resp),
        error = function(e) msg
      )
    }
    rlang::abort(paste0("Alpaca API error ", status, ": ", msg))
  }

  return(assert_return_parse_alpaca_response(parsed))
}
