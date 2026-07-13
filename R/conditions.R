# File: R/conditions.R
# Alpaca's typed API-error condition. Alpaca signals failure with HTTP status
# codes and a JSON body carrying a `message` (or `msg`) field, so a single raiser
# sits at the `parse_alpaca_response()` funnel and layers Alpaca's own class
# family IN FRONT of connectcore's, per the recipe in `?connectcore_conditions`.
# A caller can then catch `alpaca_api_error` (any Alpaca HTTP failure),
# `connectcore_api_error` (any HTTP failure fleet-wide), or `connectcore_error`
# (any transport failure) — reading `e$status` / `e$url` / `e$body_snippet`
# instead of grepping the message text.
#
# Backward compatibility is a hard contract: the message string is byte-identical
# to the bare `rlang::abort()` this replaced ("Alpaca API error <status>: <msg>"),
# so existing tests and downstream message greps keep matching. The classes and
# fields are purely additive.

#' Raise a typed Alpaca HTTP API error
#'
#' Signals a condition classed
#' `c("alpaca_api_error_<status>", "alpaca_api_error",`
#' `"connectcore_api_error_<status>", "connectcore_api_error",`
#' `"connectcore_error")` (on top of rlang's error classes), carrying the HTTP
#' `status`, the request `url` (query-string credentials redacted with
#' [connectcore::scrub_url()]), and the response `body_snippet` as structured
#' fields. The message defaults to the byte-identical
#' `"Alpaca API error <status>: <msg>"` string the funnel signalled before typed
#' conditions existed, so nothing that matched on message text breaks. See
#' [connectcore::connectcore_conditions] for the taxonomy and the subclass recipe.
#'
#' @param status (scalar<count in [100, 599]>) the HTTP status code. Also names
#'   the most specific classes, `alpaca_api_error_<status>` and
#'   `connectcore_api_error_<status>`.
#' @param msg (scalar<character>) the extracted Alpaca error message (from the
#'   body's `message` / `msg` field, or the raw body). Rendered into the
#'   condition message after the status.
#' @param url (scalar<character> | NULL) the request URL; query-string credentials
#'   are redacted with [connectcore::scrub_url()] before storing on the `url`
#'   field. Default `NULL`.
#' @param body (scalar<character> | NULL) the response body text; stored on the
#'   `body_snippet` field (named `body_snippet`, not `body`, because
#'   `rlang::abort()` reserves `body`). Default `NULL`.
#' @param message (scalar<character> | NULL) the condition message. `NULL`
#'   (default) derives the byte-identical legacy string from `status` and `msg`.
#' @return (class<connectcore_error>) never returns normally; signals the classed
#'   condition described above.
#'
#' @importFrom rlang abort caller_env
#' @keywords internal
#' @noassert
#' @noRd
abort_alpaca_error <- function(status, msg, url = NULL, body = NULL, message = NULL) {
  if (is.null(message)) {
    message <- paste0("Alpaca API error ", status, ": ", msg)
  }
  return(rlang::abort(
    message = message,
    class = c(
      sprintf("alpaca_api_error_%d", as.integer(status)),
      "alpaca_api_error",
      sprintf("connectcore_api_error_%d", as.integer(status)),
      "connectcore_api_error",
      "connectcore_error"
    ),
    status = as.integer(status),
    url = connectcore::scrub_url(url),
    body_snippet = body,
    call = rlang::caller_env()
  ))
}

#' Raise a typed Alpaca input-validation error
#'
#' Signals a condition classed `c("alpaca_validation_error", "alpaca_error")` (on
#' top of rlang's error classes) for a NON-transport failure: a method's argument
#' or parameter is malformed or violates a rule before any request is made
#' (mutually-exclusive parameters supplied together, a missing required order
#' field, a `page_size` over the cap, an unknown timeframe, a malformed `legs`
#' list). `alpaca_error` is the connector's DOMAIN root, parallel to the transport
#' `connectcore_error` root: a validation failure is not a transport failure, so
#' the two roots never meet -- exactly the `core_error` / `connectcore_error`
#' split. The `message` is passed through verbatim, so the string stays
#' byte-identical to the bare `rlang::abort()` this replaced. See
#' [connectcore::connectcore_conditions] for the transport taxonomy.
#'
#' @param message (scalar<character>) the condition message, passed through
#'   verbatim to [rlang::abort()].
#' @param ... structured fields stored on the condition, read with `e[["field"]]`.
#'   Forwarded to [rlang::abort()].
#' @param call (environment) the environment blamed in the traceback; defaults to
#'   the caller via [rlang::caller_env()].
#' @return (class<alpaca_error>) never returns normally; signals the classed
#'   condition described above.
#' @importFrom rlang abort caller_env
#' @keywords internal
#' @noassert
#' @noRd
abort_alpaca_validation_error <- function(message, ..., call = rlang::caller_env()) {
  return(rlang::abort(
    message = message,
    class = c("alpaca_validation_error", "alpaca_error"),
    ...,
    call = call
  ))
}
