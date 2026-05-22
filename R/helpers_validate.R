# File: R/helpers_validate.R
# Input validation helpers for order parameters.

#' Validate Order Parameters
#'
#' Validates and normalises parameters for an Alpaca order. Converts numeric
#' price/quantity values to character strings as required by the API. Returns
#' a clean named list ready for JSON serialisation.
#'
#' ### Validation Rules
#' - **Market orders**: require either `qty` or `notional` (mutually exclusive).
#' - **Limit orders**: require `qty` and `limit_price`.
#' - **Stop orders**: require `qty` and `stop_price`.
#' - **Stop-limit orders**: require `qty`, `stop_price`, and `limit_price`.
#' - **Trailing stop orders**: require `qty` and either `trail_price` or `trail_percent`.
#'
#' @param symbol Character or NULL; ticker symbol (e.g., `"AAPL"`). Required
#'   for all order classes except `"mleg"` (multi-leg options), where each
#'   leg carries its own symbol.
#' @param side Character or NULL; `"buy"` or `"sell"`. Required for all order
#'   classes except `"mleg"`, where each leg carries its own side.
#' @param type Character; order type.
#' @param time_in_force Character; `"day"`, `"gtc"`, `"opg"`, `"cls"`, `"ioc"`, `"fok"`.
#' @param qty Numeric or NULL; number of shares.
#' @param notional Numeric or NULL; dollar amount (market/day orders only).
#' @param limit_price Numeric or NULL; limit price.
#' @param stop_price Numeric or NULL; stop trigger price.
#' @param trail_price Numeric or NULL; trailing stop dollar offset.
#' @param trail_percent Numeric or NULL; trailing stop percentage offset.
#' @param extended_hours Logical or NULL; allow pre/post market.
#' @param client_order_id Character or NULL; unique client order ID (max 128 chars).
#' @param order_class Character or NULL; `"simple"`, `"bracket"`, `"oco"`,
#'   `"oto"`, or `"mleg"` (multi-leg options). Case-insensitive; empty string
#'   is treated as NULL.
#' @param take_profit List or NULL; `list(limit_price = ...)` for bracket orders.
#' @param stop_loss List or NULL; `list(stop_price = ..., limit_price = ...)` for bracket orders.
#' @param position_intent Character or NULL; `"buy_to_open"`, `"buy_to_close"`,
#'   `"sell_to_open"`, `"sell_to_close"`.
#' @param legs List or NULL; list of leg objects for multi-leg options orders
#'   (`order_class = "mleg"`). Max 4 legs.
#' @param advanced_instructions List or NULL; advanced routing instructions for
#'   the Alpaca Elite Smart Router.
#' @return Named list of validated order parameters (NULLs removed).
#'
#' @importFrom rlang abort arg_match0
#' @keywords internal
#' @noRd
validate_order_params <- function(
  symbol = NULL,
  side = NULL,
  type,
  time_in_force,
  qty = NULL,
  notional = NULL,
  limit_price = NULL,
  stop_price = NULL,
  trail_price = NULL,
  trail_percent = NULL,
  extended_hours = NULL,
  client_order_id = NULL,
  order_class = NULL,
  take_profit = NULL,
  stop_loss = NULL,
  position_intent = NULL,
  legs = NULL,
  advanced_instructions = NULL
) {
  # Normalise order_class first: empty string is equivalent to NULL, and
  # match case-insensitively so callers don't have to remember the casing.
  if (!is.null(order_class) && identical(order_class, "")) {
    order_class <- NULL
  }
  if (!is.null(order_class)) {
    order_class <- tolower(order_class)
  }
  is_mleg <- identical(order_class, "mleg")

  type <- tolower(type)
  time_in_force <- tolower(time_in_force)

  if (!is_mleg) {
    # Non-mleg orders require both symbol and side. mleg orders carry these
    # on each leg, so the top-level fields are optional.
    if (is.null(symbol) || !is.character(symbol) || !nzchar(symbol)) {
      rlang::abort("Parameter 'symbol' must be a non-empty character string (omit only for `order_class = \"mleg\"`).")
    }
    if (is.null(side) || !is.character(side) || !nzchar(side)) {
      rlang::abort("Parameter 'side' must be 'buy' or 'sell' (omit only for `order_class = \"mleg\"`).")
    }
    side <- tolower(side)
    rlang::arg_match0(side, c("buy", "sell"))
  } else {
    # mleg orders require legs (each leg carries its own symbol/side/qty).
    if (is.null(legs) || length(legs) == 0L) {
      rlang::abort("`legs` is required for `order_class = \"mleg\"` (provide a list of leg objects).")
    }
    if (length(legs) > 4L) {
      rlang::abort(paste0("`legs` may contain at most 4 entries (got ", length(legs), ")."))
    }
  }
  rlang::arg_match0(type, c("market", "limit", "stop", "stop_limit", "trailing_stop"))
  rlang::arg_match0(time_in_force, c("day", "gtc", "opg", "cls", "ioc", "fok"))

  # Convert numerics to character for the API
  if (!is.null(qty)) {
    qty <- as.character(qty)
  }
  if (!is.null(notional)) {
    notional <- as.character(notional)
  }
  if (!is.null(limit_price)) {
    limit_price <- as.character(limit_price)
  }
  if (!is.null(stop_price)) {
    stop_price <- as.character(stop_price)
  }
  if (!is.null(trail_price)) {
    trail_price <- as.character(trail_price)
  }
  if (!is.null(trail_percent)) {
    trail_percent <- as.character(trail_percent)
  }

  # Type-specific validation
  if (type == "market") {
    if (is.null(qty) && is.null(notional)) {
      rlang::abort("Either 'qty' or 'notional' must be specified for market orders.")
    }
    if (!is.null(qty) && !is.null(notional)) {
      rlang::abort("Parameters 'qty' and 'notional' are mutually exclusive.")
    }
  } else if (type == "limit") {
    if (is.null(qty)) {
      rlang::abort("Parameter 'qty' is required for limit orders.")
    }
    if (is.null(limit_price)) rlang::abort("Parameter 'limit_price' is required for limit orders.")
  } else if (type == "stop") {
    if (is.null(qty)) {
      rlang::abort("Parameter 'qty' is required for stop orders.")
    }
    if (is.null(stop_price)) rlang::abort("Parameter 'stop_price' is required for stop orders.")
  } else if (type == "stop_limit") {
    if (is.null(qty)) {
      rlang::abort("Parameter 'qty' is required for stop-limit orders.")
    }
    if (is.null(stop_price)) {
      rlang::abort("Parameter 'stop_price' is required for stop-limit orders.")
    }
    if (is.null(limit_price)) rlang::abort("Parameter 'limit_price' is required for stop-limit orders.")
  } else if (type == "trailing_stop") {
    if (is.null(qty)) {
      rlang::abort("Parameter 'qty' is required for trailing stop orders.")
    }
    if (is.null(trail_price) && is.null(trail_percent)) {
      rlang::abort("Either 'trail_price' or 'trail_percent' must be specified for trailing stop orders.")
    }
    if (!is.null(trail_price) && !is.null(trail_percent)) {
      rlang::abort("Parameters 'trail_price' and 'trail_percent' are mutually exclusive.")
    }
  }

  # Optional parameter validation
  if (!is.null(order_class) && nzchar(order_class)) {
    rlang::arg_match0(order_class, c("simple", "bracket", "oco", "oto", "mleg"))
  }
  if (!is.null(position_intent)) {
    rlang::arg_match0(
      position_intent,
      c("buy_to_open", "buy_to_close", "sell_to_open", "sell_to_close")
    )
  }
  if (!is.null(client_order_id) && nchar(client_order_id) > 128L) {
    rlang::abort("Parameter 'client_order_id' must not exceed 128 characters.")
  }

  # Build the result list, dropping NULLs
  params <- list(
    symbol = symbol,
    side = side,
    type = type,
    time_in_force = time_in_force,
    qty = qty,
    notional = notional,
    limit_price = limit_price,
    stop_price = stop_price,
    trail_price = trail_price,
    trail_percent = trail_percent,
    extended_hours = extended_hours,
    client_order_id = client_order_id,
    order_class = order_class,
    take_profit = take_profit,
    stop_loss = stop_loss,
    position_intent = position_intent,
    legs = legs,
    advanced_instructions = advanced_instructions
  )
  params <- params[!vapply(params, is.null, logical(1))]

  return(params)
}
