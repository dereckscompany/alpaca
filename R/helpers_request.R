# File: R/helpers_request.R
# Core HTTP request infrastructure for the alpaca package.
# Provides alpaca_build_request() and response parsing.

#' Apply Continuation to a Value or Promise
#'
#' Routes a value through `fn` either synchronously or asynchronously depending
#' on whether the caller is in async mode. This is the single sync/async
#' branching point in the package.
#'
#' @param x A value or a [promises::promise].
#' @param fn A function to apply to the resolved value of `x`.
#' @param is_async Logical; whether the caller is in async mode.
#' @return If `is_async`, returns `promises::then(x, fn)`. Otherwise returns `fn(x)`.
#' @keywords internal
#' @noRd
then_or_now <- function(x, fn, is_async = FALSE) {
  if (is_async) {
    return(promises::then(x, fn))
  }
  return(fn(x))
}

#' Build and Execute an Alpaca API Request
#'
#' Constructs an [httr2::request], adds authentication headers, performs it via
#' the supplied `.perform` function, and parses the JSON response. This is the
#' single point through which all Alpaca API calls flow.
#'
#' ### Authentication
#' Alpaca uses header-based authentication with two headers:
#' - `APCA-API-KEY-ID`: Your API key ID
#' - `APCA-API-SECRET-KEY`: Your API secret key
#'
#' @param base_url Character; the API base URL.
#' @param endpoint Character; the API path (e.g., `"/v2/account"`).
#' @param method Character; HTTP method. Default `"GET"`.
#' @param query Named list; query parameters. Default `list()`.
#' @param body Named list or NULL; JSON request body (for POST/PATCH). Default `NULL`.
#' @param keys List or NULL; API credentials with `api_key` and `api_secret`.
#'   Default `NULL` (no auth).
#' @param .perform Function; the httr2 perform function. Default `httr2::req_perform`.
#' @param .parser Function; post-processing function applied to parsed response.
#'   Default `identity`.
#' @param is_async Logical; whether `.perform` returns promises. Default `FALSE`.
#' @param timeout Numeric; request timeout in seconds. Default `10`.
#' @return Parsed and post-processed API response data, or a promise thereof.
#'
#' @importFrom httr2 request req_method req_url_path_append req_url_query
#'   req_body_json req_timeout req_perform req_headers req_error
#' @importFrom jsonlite toJSON
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
  timeout = 10
) {
  req <- httr2::request(base_url)
  req <- httr2::req_url_path_append(req, endpoint)
  req <- httr2::req_method(req, method)
  req <- httr2::req_timeout(req, timeout)

  # Add query parameters (drop NULLs)
  query <- query[!vapply(query, is.null, logical(1))]
  if (length(query) > 0) {
    req <- httr2::req_url_query(req, !!!query)
  }

  # Add JSON body for POST/PATCH/PUT
  if (!is.null(body)) {
    body <- body[!vapply(body, is.null, logical(1))]
    if (length(body) > 0) {
      req <- httr2::req_body_json(req, body)
    }
  }

  # Suppress httr2 auto-error so parse_alpaca_response handles errors
  req <- httr2::req_error(req, is_error = function(resp) FALSE)

  # Add authentication headers
  if (!is.null(keys)) {
    req <- httr2::req_headers(
      req,
      `APCA-API-KEY-ID` = keys$api_key,
      `APCA-API-SECRET-KEY` = keys$api_secret
    )
  }

  result <- .perform(req)

  # Single branching point: parse response then apply .parser
  return(then_or_now(
    result,
    function(resp) {
      data <- parse_alpaca_response(resp)
      return(.parser(data))
    },
    is_async = is_async
  ))
}

#' Parse and Validate an Alpaca API Response
#'
#' Extracts JSON from an [httr2::response], validates the HTTP status, and
#' returns the parsed data. Alpaca returns error details in the JSON body
#' with a `message` field.
#'
#' @param resp An [httr2::response] object.
#' @return The parsed JSON response data.
#'
#' @importFrom httr2 resp_status resp_body_json resp_body_string
#' @importFrom rlang abort
#' @keywords internal
#' @noRd
parse_alpaca_response <- function(resp) {
  status <- httr2::resp_status(resp)

  # Handle 204 No Content (e.g., successful DELETE)
  if (status == 204L) {
    return(list())
  }

  parsed <- tryCatch(
    httr2::resp_body_json(resp, simplifyVector = FALSE),
    error = function(e) NULL
  )

  if (status < 200L || status >= 300L) {
    msg <- "No error message provided."
    if (!is.null(parsed)) {
      msg <- parsed$message %||% parsed$msg %||% msg
    } else {
      msg <- tryCatch(
        httr2::resp_body_string(resp),
        error = function(e) msg
      )
    }
    rlang::abort(paste0("Alpaca API error ", status, ": ", msg))
  }

  return(parsed)
}
