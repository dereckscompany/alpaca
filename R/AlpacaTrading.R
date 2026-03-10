# File: R/AlpacaTrading.R
# R6 class for Alpaca order management.

#' AlpacaTrading: Order Management
#'
#' Provides methods for placing, modifying, cancelling, and querying orders
#' on Alpaca's Trading API.
#'
#' Inherits from [AlpacaBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Place Orders**: Market, limit, stop, stop-limit, and trailing stop orders.
#' - **Order Classes**: Simple, bracket, OCO, and OTO orders.
#' - **Modify Orders**: Replace existing orders with updated parameters.
#' - **Cancel Orders**: Cancel individual orders or all open orders.
#' - **Query Orders**: List open, closed, or all orders with filtering.
#'
#' ### Official Documentation
#' [Orders](https://docs.alpaca.markets/reference/orders-4)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | add_order | POST /v2/orders | POST |
#' | get_orders | GET /v2/orders | GET |
#' | get_order | GET /v2/orders/{order_id} | GET |
#' | get_order_by_client_id | GET /v2/orders:by_client_order_id | GET |
#' | modify_order | PATCH /v2/orders/{order_id} | PATCH |
#' | cancel_order | DELETE /v2/orders/{order_id} | DELETE |
#' | cancel_all_orders | DELETE /v2/orders | DELETE |
#'
#' @examples
#' \dontrun{
#' trading <- AlpacaTrading$new()
#'
#' # Place a limit order
#' order <- trading$add_order(
#'   symbol = "AAPL", side = "buy", type = "limit",
#'   time_in_force = "day", qty = 1, limit_price = 150
#' )
#' print(order)
#'
#' # Cancel it
#' trading$cancel_order(order$id)
#' }
#'
#' @importFrom R6 R6Class
#' @export
AlpacaTrading <- R6::R6Class(
  "AlpacaTrading",
  inherit = AlpacaBase,
  public = list(
    # ---- Place Order ----

    #' @description
    #' Place an Order
    #'
    #' Submits a new order to Alpaca. Supports all order types including
    #' market, limit, stop, stop-limit, and trailing stop. Also supports
    #' advanced order classes (bracket, OCO, OTO).
    #'
    #' ### API Endpoint
    #' `POST https://paper-api.alpaca.markets/v2/orders`
    #'
    #' ### Official Documentation
    #' [Create Order](https://docs.alpaca.markets/reference/postorder)
    #'
    #' ### curl
    #' ```
    #' curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   -H "Content-Type: application/json" \
    #'   -d '{"symbol":"AAPL","qty":"1","side":"buy","type":"market","time_in_force":"day"}' \
    #'   'https://paper-api.alpaca.markets/v2/orders'
    #' ```
    #'
    #' @param symbol Character; ticker symbol (e.g., `"AAPL"`).
    #' @param side Character; `"buy"` or `"sell"`.
    #' @param type Character; order type: `"market"`, `"limit"`, `"stop"`,
    #'   `"stop_limit"`, `"trailing_stop"`.
    #' @param time_in_force Character; `"day"`, `"gtc"`, `"opg"`, `"cls"`, `"ioc"`, `"fok"`.
    #' @param qty Numeric or NULL; number of shares. Mutually exclusive with `notional`.
    #' @param notional Numeric or NULL; dollar amount. Market/day orders only.
    #' @param limit_price Numeric or NULL; limit price. Required for `"limit"` and
    #'   `"stop_limit"` orders.
    #' @param stop_price Numeric or NULL; stop trigger price. Required for `"stop"` and
    #'   `"stop_limit"` orders.
    #' @param trail_price Numeric or NULL; trailing stop dollar offset.
    #' @param trail_percent Numeric or NULL; trailing stop percentage offset.
    #' @param extended_hours Logical or NULL; allow pre/post market execution.
    #' @param client_order_id Character or NULL; unique client order ID (max 128 chars).
    #' @param order_class Character or NULL; `"simple"`, `"bracket"`, `"oco"`, `"oto"`.
    #' @param take_profit List or NULL; `list(limit_price = ...)` for bracket orders.
    #' @param stop_loss List or NULL; `list(stop_price = ..., limit_price = ...)` for bracket orders.
    #' @param position_intent Character or NULL; `"buy_to_open"`, `"buy_to_close"`,
    #'   `"sell_to_open"`, `"sell_to_close"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Order UUID.
    #'   - `client_order_id` (character): Client order ID.
    #'   - `symbol` (character): Ticker symbol.
    #'   - `side` (character): `"buy"` or `"sell"`.
    #'   - `type` (character): Order type.
    #'   - `time_in_force` (character): Time in force.
    #'   - `status` (character): Order status (e.g., `"accepted"`, `"new"`, `"filled"`).
    #'   - `qty` (character): Requested quantity.
    #'   - `filled_qty` (character): Quantity filled so far.
    #'   - `filled_avg_price` (character): Average fill price.
    #'   - `limit_price` (character): Limit price (if set).
    #'   - `stop_price` (character): Stop price (if set).
    #'   - `created_at` (character): Order creation timestamp.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #'
    #' # Market order
    #' order <- trading$add_order(
    #'   symbol = "AAPL", side = "buy", type = "market",
    #'   time_in_force = "day", qty = 1
    #' )
    #'
    #' # Limit order
    #' order <- trading$add_order(
    #'   symbol = "AAPL", side = "buy", type = "limit",
    #'   time_in_force = "day", qty = 1, limit_price = 150
    #' )
    #'
    #' # Bracket order
    #' order <- trading$add_order(
    #'   symbol = "AAPL", side = "buy", type = "market",
    #'   time_in_force = "day", qty = 10, order_class = "bracket",
    #'   take_profit = list(limit_price = 200),
    #'   stop_loss = list(stop_price = 140, limit_price = 139)
    #' )
    #' }
    add_order = function(
      symbol,
      side,
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
      position_intent = NULL
    ) {
      params <- validate_order_params(
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
        position_intent = position_intent
      )

      return(private$.request(
        endpoint = "/v2/orders",
        method = "POST",
        body = params,
        .parser = as_dt_row
      ))
    },

    # ---- Query Orders ----

    #' @description
    #' List Orders
    #'
    #' Retrieves a list of orders with optional filtering by status, symbol,
    #' side, and date range. Supports pagination.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/orders`
    #'
    #' ### Official Documentation
    #' [List Orders](https://docs.alpaca.markets/reference/getallorders)
    #'
    #' @param status Character or NULL; `"open"`, `"closed"`, `"all"`. Default `"open"`.
    #' @param limit Integer or NULL; max orders (default 50, max 500).
    #' @param after Character or NULL; only orders submitted after this timestamp.
    #' @param until Character or NULL; only orders submitted before this timestamp.
    #' @param direction Character or NULL; `"asc"` or `"desc"`.
    #' @param nested Logical or NULL; roll up multi-leg orders under `legs`.
    #' @param symbols Character or NULL; comma-separated symbol filter.
    #' @param side Character or NULL; filter by side.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same columns as [add_order()] return value.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #' open_orders <- trading$get_orders(status = "open")
    #' print(open_orders)
    #' }
    get_orders = function(
      status = NULL,
      limit = NULL,
      after = NULL,
      until = NULL,
      direction = NULL,
      nested = NULL,
      symbols = NULL,
      side = NULL
    ) {
      return(private$.request(
        endpoint = "/v2/orders",
        query = list(
          status = status,
          limit = limit,
          after = after,
          until = until,
          direction = direction,
          nested = nested,
          symbols = symbols,
          side = side
        ),
        .parser = as_dt_list
      ))
    },

    #' @description
    #' Get Order by ID
    #'
    #' Retrieves a single order by its UUID.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/orders/{order_id}`
    #'
    #' @param order_id Character; order UUID.
    #' @param nested Logical or NULL; include leg orders.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #' order <- trading$get_order("some-order-uuid")
    #' print(order)
    #' }
    get_order = function(order_id, nested = NULL) {
      endpoint <- paste0("/v2/orders/", order_id)
      return(private$.request(
        endpoint = endpoint,
        query = list(nested = nested),
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Order by Client Order ID
    #'
    #' Retrieves a single order by its client order ID. Useful for idempotent
    #' order tracking in production systems.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/orders/by_client_order_id`
    #'
    #' @param client_order_id Character; the client order ID (max 128 chars).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #' order <- trading$get_order_by_client_id("my-unique-order-id")
    #' print(order)
    #' }
    get_order_by_client_id = function(client_order_id) {
      return(private$.request(
        endpoint = "/v2/orders:by_client_order_id",
        query = list(client_order_id = client_order_id),
        .parser = as_dt_row
      ))
    },

    # ---- Modify Order ----

    #' @description
    #' Replace (Modify) an Order
    #'
    #' Replaces an existing order with updated parameters. The original order
    #' is cancelled and a new order is created atomically.
    #'
    #' ### API Endpoint
    #' `PATCH https://paper-api.alpaca.markets/v2/orders/{order_id}`
    #'
    #' ### Official Documentation
    #' [Replace Order](https://docs.alpaca.markets/reference/patchorder)
    #'
    #' @param order_id Character; order UUID to replace.
    #' @param qty Numeric or NULL; new quantity.
    #' @param time_in_force Character or NULL; new time in force.
    #' @param limit_price Numeric or NULL; new limit price.
    #' @param stop_price Numeric or NULL; new stop price.
    #' @param trail Numeric or NULL; new trail value.
    #' @param client_order_id Character or NULL; new client order ID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the replacement order details.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #' modified <- trading$modify_order("some-order-uuid", limit_price = 155)
    #' print(modified)
    #' }
    modify_order = function(
      order_id,
      qty = NULL,
      time_in_force = NULL,
      limit_price = NULL,
      stop_price = NULL,
      trail = NULL,
      client_order_id = NULL
    ) {
      if (!is.null(qty)) {
        qty <- as.character(qty)
      }
      if (!is.null(limit_price)) {
        limit_price <- as.character(limit_price)
      }
      if (!is.null(stop_price)) {
        stop_price <- as.character(stop_price)
      }
      if (!is.null(trail)) {
        trail <- as.character(trail)
      }

      endpoint <- paste0("/v2/orders/", order_id)
      return(private$.request(
        endpoint = endpoint,
        method = "PATCH",
        body = list(
          qty = qty,
          time_in_force = time_in_force,
          limit_price = limit_price,
          stop_price = stop_price,
          trail = trail,
          client_order_id = client_order_id
        ),
        .parser = as_dt_row
      ))
    },

    # ---- Cancel Orders ----

    #' @description
    #' Cancel an Order
    #'
    #' Cancels a single open order by its UUID.
    #'
    #' ### API Endpoint
    #' `DELETE https://paper-api.alpaca.markets/v2/orders/{order_id}`
    #'
    #' @param order_id Character; order UUID to cancel.
    #' @return Empty `data.table` on success (HTTP 204), or a `promise` thereof.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #' trading$cancel_order("some-order-uuid")
    #' }
    cancel_order = function(order_id) {
      endpoint <- paste0("/v2/orders/", order_id)
      return(private$.request(
        endpoint = endpoint,
        method = "DELETE",
        .parser = function(data) data.table::data.table()
      ))
    },

    #' @description
    #' Cancel All Open Orders
    #'
    #' Cancels all open orders. Returns a list of orders that were cancelled.
    #'
    #' ### API Endpoint
    #' `DELETE https://paper-api.alpaca.markets/v2/orders`
    #'
    #' ### Official Documentation
    #' [Cancel All Orders](https://docs.alpaca.markets/reference/deleteallorders)
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   cancelled order details.
    #'
    #' @examples
    #' \dontrun{
    #' trading <- AlpacaTrading$new()
    #' cancelled <- trading$cancel_all_orders()
    #' print(cancelled)
    #' }
    cancel_all_orders = function() {
      return(private$.request(
        endpoint = "/v2/orders",
        method = "DELETE",
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table())
          }
          as_dt_list(data)
        }
      ))
    }
  )
)
