# AlpacaTrading: Order Management

AlpacaTrading: Order Management

AlpacaTrading: Order Management

## Details

Provides methods for placing, modifying, cancelling, and querying orders
on Alpaca's Trading API.

Inherits from
[AlpacaBase](https://dereckmezquita.github.io/alpaca/reference/AlpacaBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Place Orders**: Market, limit, stop, stop-limit, and trailing stop
  orders.

- **Order Classes**: Simple, bracket, OCO, and OTO orders.

- **Modify Orders**: Replace existing orders with updated parameters.

- **Cancel Orders**: Cancel individual orders or all open orders.

- **Query Orders**: List open, closed, or all orders with filtering.

### Official Documentation

[Orders](https://docs.alpaca.markets/reference/orders-4)

### Endpoints Covered

|                        |                                     |        |
|------------------------|-------------------------------------|--------|
| Method                 | Endpoint                            | HTTP   |
| add_order              | `POST /v2/orders`                   | POST   |
| get_orders             | `GET /v2/orders`                    | GET    |
| get_order              | `GET /v2/orders/\{order_id\}`       | GET    |
| get_order_by_client_id | `GET /v2/orders:by_client_order_id` | GET    |
| modify_order           | `PATCH /v2/orders/\{order_id\}`     | PATCH  |
| cancel_order           | `DELETE /v2/orders/\{order_id\}`    | DELETE |
| cancel_all_orders      | `DELETE /v2/orders`                 | DELETE |

## Super class

[`alpaca::AlpacaBase`](https://dereckmezquita.github.io/alpaca/reference/AlpacaBase.md)
-\> `AlpacaTrading`

## Methods

### Public methods

- [`AlpacaTrading$add_order()`](#method-AlpacaTrading-add_order)

- [`AlpacaTrading$get_orders()`](#method-AlpacaTrading-get_orders)

- [`AlpacaTrading$get_order()`](#method-AlpacaTrading-get_order)

- [`AlpacaTrading$get_order_by_client_id()`](#method-AlpacaTrading-get_order_by_client_id)

- [`AlpacaTrading$modify_order()`](#method-AlpacaTrading-modify_order)

- [`AlpacaTrading$cancel_order()`](#method-AlpacaTrading-cancel_order)

- [`AlpacaTrading$cancel_all_orders()`](#method-AlpacaTrading-cancel_all_orders)

- [`AlpacaTrading$clone()`](#method-AlpacaTrading-clone)

Inherited methods

- [`alpaca::AlpacaBase$initialize()`](https://dereckmezquita.github.io/alpaca/reference/AlpacaBase.html#method-initialize)

------------------------------------------------------------------------

### Method `add_order()`

Place an Order

Submits a new order to Alpaca. Supports all order types including
market, limit, stop, stop-limit, and trailing stop. Also supports
advanced order classes (bracket, OCO, OTO).

#### API Endpoint

`POST https://paper-api.alpaca.markets/v2/orders`

#### Official Documentation

[Create Order](https://docs.alpaca.markets/reference/postorder)
Verified: 2026-03-10

#### curl

    curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      -H "Content-Type: application/json" \
      -d '{"symbol":"AAPL","qty":"1","side":"buy","type":"market","time_in_force":"day"}' \
      'https://paper-api.alpaca.markets/v2/orders'

#### JSON Request

    {
      "symbol": "AAPL",
      "qty": "1",
      "side": "buy",
      "type": "limit",
      "time_in_force": "day",
      "limit_price": "150.00",
      "extended_hours": false,
      "client_order_id": "my-order-001",
      "order_class": "simple"
    }

#### JSON Response

    {
      "id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
      "client_order_id": "my-order-001",
      "created_at": "2026-03-10T14:30:00.000000Z",
      "updated_at": "2026-03-10T14:30:00.000000Z",
      "submitted_at": "2026-03-10T14:30:00.000000Z",
      "filled_at": null,
      "expired_at": null,
      "canceled_at": null,
      "failed_at": null,
      "replaced_at": null,
      "replaced_by": null,
      "replaces": null,
      "asset_id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
      "symbol": "AAPL",
      "asset_class": "us_equity",
      "notional": null,
      "qty": "1",
      "filled_qty": "0",
      "filled_avg_price": null,
      "order_class": "simple",
      "order_type": "limit",
      "type": "limit",
      "side": "buy",
      "time_in_force": "day",
      "limit_price": "150.00",
      "stop_price": null,
      "status": "accepted",
      "extended_hours": false,
      "legs": null,
      "trail_percent": null,
      "trail_price": null,
      "hwm": null
    }

#### Usage

    AlpacaTrading$add_order(
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
    )

#### Arguments

- `symbol`:

  Character; ticker symbol (e.g., `"AAPL"`).

- `side`:

  Character; `"buy"` or `"sell"`.

- `type`:

  Character; order type: `"market"`, `"limit"`, `"stop"`,
  `"stop_limit"`, `"trailing_stop"`.

- `time_in_force`:

  Character; `"day"`, `"gtc"`, `"opg"`, `"cls"`, `"ioc"`, `"fok"`.

- `qty`:

  Numeric or NULL; number of shares. Mutually exclusive with `notional`.

- `notional`:

  Numeric or NULL; dollar amount. Market/day orders only.

- `limit_price`:

  Numeric or NULL; limit price. Required for `"limit"` and
  `"stop_limit"` orders.

- `stop_price`:

  Numeric or NULL; stop trigger price. Required for `"stop"` and
  `"stop_limit"` orders.

- `trail_price`:

  Numeric or NULL; trailing stop dollar offset.

- `trail_percent`:

  Numeric or NULL; trailing stop percentage offset.

- `extended_hours`:

  Logical or NULL; allow pre/post market execution.

- `client_order_id`:

  Character or NULL; unique client order ID (max 128 chars).

- `order_class`:

  Character or NULL; `"simple"`, `"bracket"`, `"oco"`, `"oto"`.

- `take_profit`:

  List or NULL; `list(limit_price = ...)` for bracket orders.

- `stop_loss`:

  List or NULL; `list(stop_price = ..., limit_price = ...)` for bracket
  orders.

- `position_intent`:

  Character or NULL; `"buy_to_open"`, `"buy_to_close"`,
  `"sell_to_open"`, `"sell_to_close"`.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `id` (character): Order UUID.

- `client_order_id` (character): Client order ID.

- `symbol` (character): Ticker symbol.

- `side` (character): `"buy"` or `"sell"`.

- `type` (character): Order type.

- `time_in_force` (character): Time in force.

- `status` (character): Order status (e.g., `"accepted"`, `"new"`,
  `"filled"`).

- `qty` (character): Requested quantity.

- `filled_qty` (character): Quantity filled so far.

- `filled_avg_price` (character): Average fill price.

- `limit_price` (character): Limit price (if set).

- `stop_price` (character): Stop price (if set).

- `created_at` (character): Order creation timestamp.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()

    # Market order
    order <- trading$add_order(
      symbol = "AAPL", side = "buy", type = "market",
      time_in_force = "day", qty = 1
    )

    # Limit order
    order <- trading$add_order(
      symbol = "AAPL", side = "buy", type = "limit",
      time_in_force = "day", qty = 1, limit_price = 150
    )

    # Bracket order
    order <- trading$add_order(
      symbol = "AAPL", side = "buy", type = "market",
      time_in_force = "day", qty = 10, order_class = "bracket",
      take_profit = list(limit_price = 200),
      stop_loss = list(stop_price = 140, limit_price = 139)
    )
    }

------------------------------------------------------------------------

### Method `get_orders()`

List Orders

Retrieves a list of orders with optional filtering by status, symbol,
side, and date range. Supports pagination.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/orders`

#### Official Documentation

[List Orders](https://docs.alpaca.markets/reference/getallorders)
Verified: 2026-03-10

#### curl

    curl -X GET -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/orders?status=open&limit=50&direction=desc'

#### JSON Response

    [
      {
        "id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
        "client_order_id": "my-order-001",
        "created_at": "2026-03-10T14:30:00.000000Z",
        "updated_at": "2026-03-10T14:30:00.000000Z",
        "submitted_at": "2026-03-10T14:30:00.000000Z",
        "filled_at": null,
        "expired_at": null,
        "canceled_at": null,
        "failed_at": null,
        "replaced_at": null,
        "replaced_by": null,
        "replaces": null,
        "asset_id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
        "symbol": "AAPL",
        "asset_class": "us_equity",
        "notional": null,
        "qty": "1",
        "filled_qty": "0",
        "filled_avg_price": null,
        "order_class": "simple",
        "order_type": "limit",
        "type": "limit",
        "side": "buy",
        "time_in_force": "day",
        "limit_price": "150.00",
        "stop_price": null,
        "status": "new",
        "extended_hours": false,
        "legs": null,
        "trail_percent": null,
        "trail_price": null,
        "hwm": null
      }
    ]

#### Usage

    AlpacaTrading$get_orders(
      status = NULL,
      limit = NULL,
      after = NULL,
      until = NULL,
      direction = NULL,
      nested = NULL,
      symbols = NULL,
      side = NULL
    )

#### Arguments

- `status`:

  Character or NULL; `"open"`, `"closed"`, `"all"`. Default `"open"`.

- `limit`:

  Integer or NULL; max orders (default 50, max 500).

- `after`:

  Character or NULL; only orders submitted after this timestamp.

- `until`:

  Character or NULL; only orders submitted before this timestamp.

- `direction`:

  Character or NULL; `"asc"` or `"desc"`.

- `nested`:

  Logical or NULL; roll up multi-leg orders under `legs`.

- `symbols`:

  Character or NULL; comma-separated symbol filter.

- `side`:

  Character or NULL; filter by side.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the same
columns as `add_order()` return value.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()
    open_orders <- trading$get_orders(status = "open")
    print(open_orders)
    }

------------------------------------------------------------------------

### Method `get_order()`

Get Order by ID

Retrieves a single order by its UUID.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/orders/{order_id}`

#### Official Documentation

[Get Order](https://docs.alpaca.markets/reference/getorderbyorderid)
Verified: 2026-03-10

#### curl

    curl -X GET -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/orders/b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f'

#### JSON Response

    {
      "id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
      "client_order_id": "my-order-001",
      "created_at": "2026-03-10T14:30:00.000000Z",
      "updated_at": "2026-03-10T14:30:05.000000Z",
      "submitted_at": "2026-03-10T14:30:00.000000Z",
      "filled_at": "2026-03-10T14:30:05.000000Z",
      "expired_at": null,
      "canceled_at": null,
      "failed_at": null,
      "replaced_at": null,
      "replaced_by": null,
      "replaces": null,
      "asset_id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
      "symbol": "AAPL",
      "asset_class": "us_equity",
      "notional": null,
      "qty": "1",
      "filled_qty": "1",
      "filled_avg_price": "149.85",
      "order_class": "simple",
      "order_type": "limit",
      "type": "limit",
      "side": "buy",
      "time_in_force": "day",
      "limit_price": "150.00",
      "stop_price": null,
      "status": "filled",
      "extended_hours": false,
      "legs": null,
      "trail_percent": null,
      "trail_price": null,
      "hwm": null
    }

#### Usage

    AlpacaTrading$get_order(order_id, nested = NULL)

#### Arguments

- `order_id`:

  Character; order UUID.

- `nested`:

  Logical or NULL; include leg orders.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`), single row.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()
    order <- trading$get_order("some-order-uuid")
    print(order)
    }

------------------------------------------------------------------------

### Method `get_order_by_client_id()`

Get Order by Client Order ID

Retrieves a single order by its client order ID. Useful for idempotent
order tracking in production systems.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/orders/by_client_order_id`

#### Official Documentation

[Get Order by Client
ID](https://docs.alpaca.markets/reference/getorderbyclientorderid)
Verified: 2026-03-10

#### curl

    curl -X GET -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/orders:by_client_order_id?client_order_id=my-order-001'

#### JSON Response

    {
      "id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
      "client_order_id": "my-order-001",
      "created_at": "2026-03-10T14:30:00.000000Z",
      "updated_at": "2026-03-10T14:30:05.000000Z",
      "submitted_at": "2026-03-10T14:30:00.000000Z",
      "filled_at": "2026-03-10T14:30:05.000000Z",
      "expired_at": null,
      "canceled_at": null,
      "failed_at": null,
      "replaced_at": null,
      "replaced_by": null,
      "replaces": null,
      "asset_id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
      "symbol": "AAPL",
      "asset_class": "us_equity",
      "notional": null,
      "qty": "1",
      "filled_qty": "1",
      "filled_avg_price": "149.85",
      "order_class": "simple",
      "order_type": "limit",
      "type": "limit",
      "side": "buy",
      "time_in_force": "day",
      "limit_price": "150.00",
      "stop_price": null,
      "status": "filled",
      "extended_hours": false,
      "legs": null,
      "trail_percent": null,
      "trail_price": null,
      "hwm": null
    }

#### Usage

    AlpacaTrading$get_order_by_client_id(client_order_id)

#### Arguments

- `client_order_id`:

  Character; the client order ID (max 128 chars).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`), single row.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()
    order <- trading$get_order_by_client_id("my-unique-order-id")
    print(order)
    }

------------------------------------------------------------------------

### Method `modify_order()`

Replace (Modify) an Order

Replaces an existing order with updated parameters. The original order
is cancelled and a new order is created atomically.

#### API Endpoint

`PATCH https://paper-api.alpaca.markets/v2/orders/{order_id}`

#### Official Documentation

[Replace Order](https://docs.alpaca.markets/reference/patchorder)
Verified: 2026-03-10

#### curl

    curl -X PATCH -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      -H "Content-Type: application/json" \
      -d '{"qty":"2","limit_price":"155.00"}' \
      'https://paper-api.alpaca.markets/v2/orders/b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f'

#### JSON Request

    {
      "qty": "2",
      "time_in_force": "day",
      "limit_price": "155.00",
      "stop_price": null,
      "trail": null,
      "client_order_id": "my-order-001-modified"
    }

#### JSON Response

    {
      "id": "e7f3c1a2-8d5b-4f6e-9a2c-1b3d5e7f9a1c",
      "client_order_id": "my-order-001-modified",
      "created_at": "2026-03-10T14:35:00.000000Z",
      "updated_at": "2026-03-10T14:35:00.000000Z",
      "submitted_at": "2026-03-10T14:35:00.000000Z",
      "filled_at": null,
      "expired_at": null,
      "canceled_at": null,
      "failed_at": null,
      "replaced_at": null,
      "replaced_by": null,
      "replaces": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
      "asset_id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
      "symbol": "AAPL",
      "asset_class": "us_equity",
      "notional": null,
      "qty": "2",
      "filled_qty": "0",
      "filled_avg_price": null,
      "order_class": "simple",
      "order_type": "limit",
      "type": "limit",
      "side": "buy",
      "time_in_force": "day",
      "limit_price": "155.00",
      "stop_price": null,
      "status": "accepted",
      "extended_hours": false,
      "legs": null,
      "trail_percent": null,
      "trail_price": null,
      "hwm": null
    }

#### Usage

    AlpacaTrading$modify_order(
      order_id,
      qty = NULL,
      time_in_force = NULL,
      limit_price = NULL,
      stop_price = NULL,
      trail = NULL,
      client_order_id = NULL
    )

#### Arguments

- `order_id`:

  Character; order UUID to replace.

- `qty`:

  Numeric or NULL; new quantity.

- `time_in_force`:

  Character or NULL; new time in force.

- `limit_price`:

  Numeric or NULL; new limit price.

- `stop_price`:

  Numeric or NULL; new stop price.

- `trail`:

  Numeric or NULL; new trail value.

- `client_order_id`:

  Character or NULL; new client order ID.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the
replacement order details.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()
    modified <- trading$modify_order("some-order-uuid", limit_price = 155)
    print(modified)
    }

------------------------------------------------------------------------

### Method `cancel_order()`

Cancel an Order

Cancels a single open order by its UUID.

#### API Endpoint

`DELETE https://paper-api.alpaca.markets/v2/orders/{order_id}`

#### Official Documentation

[Cancel
Order](https://docs.alpaca.markets/reference/deleteorderbyorderid)
Verified: 2026-03-10

#### curl

    curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/orders/b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f'

#### JSON Response

The API returns HTTP 204 (No Content) on success. This method returns a
confirmation `data.table`:

    {
      "order_id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
      "status": "cancelled"
    }

#### Usage

    AlpacaTrading$cancel_order(order_id)

#### Arguments

- `order_id`:

  Character; order UUID to cancel.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`), single row
with columns:

- `order_id` (character): The cancelled order UUID.

- `status` (character): `"cancelled"`.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()
    trading$cancel_order("some-order-uuid")
    }

------------------------------------------------------------------------

### Method `cancel_all_orders()`

Cancel All Open Orders

Cancels all open orders. Returns a list of orders that were cancelled.

#### API Endpoint

`DELETE https://paper-api.alpaca.markets/v2/orders`

#### Official Documentation

[Cancel All
Orders](https://docs.alpaca.markets/reference/deleteallorders) Verified:
2026-03-10

#### curl

    curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/orders'

#### JSON Response

    [
      {
        "id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
        "status": 200,
        "body": {
          "id": "b3a0b82d-62f4-4c23-87a5-3e5b1e3c0a1f",
          "client_order_id": "my-order-001",
          "created_at": "2026-03-10T14:30:00.000000Z",
          "updated_at": "2026-03-10T14:40:00.000000Z",
          "submitted_at": "2026-03-10T14:30:00.000000Z",
          "filled_at": null,
          "expired_at": null,
          "canceled_at": "2026-03-10T14:40:00.000000Z",
          "failed_at": null,
          "replaced_at": null,
          "replaced_by": null,
          "replaces": null,
          "asset_id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
          "symbol": "AAPL",
          "asset_class": "us_equity",
          "notional": null,
          "qty": "1",
          "filled_qty": "0",
          "filled_avg_price": null,
          "order_class": "simple",
          "order_type": "limit",
          "type": "limit",
          "side": "buy",
          "time_in_force": "day",
          "limit_price": "150.00",
          "stop_price": null,
          "status": "pending_cancel",
          "extended_hours": false,
          "legs": null,
          "trail_percent": null,
          "trail_price": null,
          "hwm": null
        }
      }
    ]

#### Usage

    AlpacaTrading$cancel_all_orders()

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`). When orders
are cancelled, one row per order with full order details. When no open
orders exist, a single confirmation row with columns:

- `status` (character): `"cancelled"`.

#### Examples

    \dontrun{
    trading <- AlpacaTrading$new()
    cancelled <- trading$cancel_all_orders()
    print(cancelled)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AlpacaTrading$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()

# Place a limit order
order <- trading$add_order(
  symbol = "AAPL", side = "buy", type = "limit",
  time_in_force = "day", qty = 1, limit_price = 150
)
print(order)

# Cancel it
trading$cancel_order(order$id)
} # }


## ------------------------------------------------
## Method `AlpacaTrading$add_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()

# Market order
order <- trading$add_order(
  symbol = "AAPL", side = "buy", type = "market",
  time_in_force = "day", qty = 1
)

# Limit order
order <- trading$add_order(
  symbol = "AAPL", side = "buy", type = "limit",
  time_in_force = "day", qty = 1, limit_price = 150
)

# Bracket order
order <- trading$add_order(
  symbol = "AAPL", side = "buy", type = "market",
  time_in_force = "day", qty = 10, order_class = "bracket",
  take_profit = list(limit_price = 200),
  stop_loss = list(stop_price = 140, limit_price = 139)
)
} # }

## ------------------------------------------------
## Method `AlpacaTrading$get_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()
open_orders <- trading$get_orders(status = "open")
print(open_orders)
} # }

## ------------------------------------------------
## Method `AlpacaTrading$get_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()
order <- trading$get_order("some-order-uuid")
print(order)
} # }

## ------------------------------------------------
## Method `AlpacaTrading$get_order_by_client_id`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()
order <- trading$get_order_by_client_id("my-unique-order-id")
print(order)
} # }

## ------------------------------------------------
## Method `AlpacaTrading$modify_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()
modified <- trading$modify_order("some-order-uuid", limit_price = 155)
print(modified)
} # }

## ------------------------------------------------
## Method `AlpacaTrading$cancel_order`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()
trading$cancel_order("some-order-uuid")
} # }

## ------------------------------------------------
## Method `AlpacaTrading$cancel_all_orders`
## ------------------------------------------------

if (FALSE) { # \dontrun{
trading <- AlpacaTrading$new()
cancelled <- trading$cancel_all_orders()
print(cancelled)
} # }
```
