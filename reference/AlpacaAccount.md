# AlpacaAccount: Account, Positions, and Portfolio

AlpacaAccount: Account, Positions, and Portfolio

AlpacaAccount: Account, Positions, and Portfolio

## Details

Provides methods for retrieving account information, managing positions,
viewing portfolio history, and querying account activities on Alpaca's
Trading API.

Inherits from
[AlpacaBase](https://dereckmezquita.github.io/alpaca/reference/AlpacaBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Account**: Retrieve current account details (equity, buying power,
  etc.).

- **Positions**: View all open positions or a specific position by
  symbol.

- **Close Positions**: Close individual positions (fully or partially).

- **Options Exercise**: Exercise options positions.

- **Account Config**: View and update account configurations.

- **Portfolio History**: View historical portfolio value snapshots.

- **Activities**: Query account activity history (fills, dividends,
  etc.).

- **Watchlists**: Create, update, and manage symbol watchlists.

### Official Documentation

- [Account](https://docs.alpaca.markets/reference/getaccount-1)

- [Positions](https://docs.alpaca.markets/reference/getallopenpositions-1)

- [Portfolio
  History](https://docs.alpaca.markets/reference/getportfoliohistory)

- [Account
  Activities](https://docs.alpaca.markets/reference/getaccountactivities)

### Endpoints Covered

|                         |                                                |        |
|-------------------------|------------------------------------------------|--------|
| Method                  | Endpoint                                       | HTTP   |
| get_account             | `GET /v2/account`                              | GET    |
| get_positions           | `GET /v2/positions`                            | GET    |
| get_position            | `GET /v2/positions/\{symbol_or_id\}`           | GET    |
| close_position          | `DELETE /v2/positions/\{symbol_or_id\}`        | DELETE |
| close_all_positions     | `DELETE /v2/positions`                         | DELETE |
| get_account_config      | `GET /v2/account/configurations`               | GET    |
| modify_account_config   | `PATCH /v2/account/configurations`             | PATCH  |
| exercise_option         | `POST /v2/positions/\{symbol_or_id\}/exercise` | POST   |
| get_portfolio_history   | `GET /v2/account/portfolio/history`            | GET    |
| get_activities          | `GET /v2/account/activities`                   | GET    |
| get_activities_by_type  | `GET /v2/account/activities/\{type\}`          | GET    |
| get_watchlists          | `GET /v2/watchlists`                           | GET    |
| get_watchlist           | `GET /v2/watchlists/\{id\}`                    | GET    |
| add_watchlist           | `POST /v2/watchlists`                          | POST   |
| modify_watchlist        | `PUT /v2/watchlists/\{id\}`                    | PUT    |
| add_watchlist_symbol    | `POST /v2/watchlists/\{id\}`                   | POST   |
| cancel_watchlist_symbol | `DELETE /v2/watchlists/\{id\}/\{symbol\}`      | DELETE |
| cancel_watchlist        | `DELETE /v2/watchlists/\{id\}`                 | DELETE |

## Super class

[`alpaca::AlpacaBase`](https://dereckmezquita.github.io/alpaca/reference/AlpacaBase.md)
-\> `AlpacaAccount`

## Methods

### Public methods

- [`AlpacaAccount$get_account()`](#method-AlpacaAccount-get_account)

- [`AlpacaAccount$get_account_config()`](#method-AlpacaAccount-get_account_config)

- [`AlpacaAccount$modify_account_config()`](#method-AlpacaAccount-modify_account_config)

- [`AlpacaAccount$get_positions()`](#method-AlpacaAccount-get_positions)

- [`AlpacaAccount$get_position()`](#method-AlpacaAccount-get_position)

- [`AlpacaAccount$close_position()`](#method-AlpacaAccount-close_position)

- [`AlpacaAccount$close_all_positions()`](#method-AlpacaAccount-close_all_positions)

- [`AlpacaAccount$exercise_option()`](#method-AlpacaAccount-exercise_option)

- [`AlpacaAccount$get_portfolio_history()`](#method-AlpacaAccount-get_portfolio_history)

- [`AlpacaAccount$get_activities()`](#method-AlpacaAccount-get_activities)

- [`AlpacaAccount$get_activities_by_type()`](#method-AlpacaAccount-get_activities_by_type)

- [`AlpacaAccount$get_watchlists()`](#method-AlpacaAccount-get_watchlists)

- [`AlpacaAccount$get_watchlist()`](#method-AlpacaAccount-get_watchlist)

- [`AlpacaAccount$add_watchlist()`](#method-AlpacaAccount-add_watchlist)

- [`AlpacaAccount$modify_watchlist()`](#method-AlpacaAccount-modify_watchlist)

- [`AlpacaAccount$add_watchlist_symbol()`](#method-AlpacaAccount-add_watchlist_symbol)

- [`AlpacaAccount$cancel_watchlist_symbol()`](#method-AlpacaAccount-cancel_watchlist_symbol)

- [`AlpacaAccount$cancel_watchlist()`](#method-AlpacaAccount-cancel_watchlist)

- [`AlpacaAccount$clone()`](#method-AlpacaAccount-clone)

Inherited methods

- [`alpaca::AlpacaBase$initialize()`](https://dereckmezquita.github.io/alpaca/reference/AlpacaBase.html#method-initialize)

------------------------------------------------------------------------

### Method `get_account()`

Get Account Information

Retrieves the current account details including equity, buying power,
cash, margin, and account status.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/account`

#### Official Documentation

[Get Account](https://docs.alpaca.markets/reference/getaccount-1)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/account'

#### JSON Response

    {
      "id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
      "account_number": "PA1234567",
      "status": "ACTIVE",
      "currency": "USD",
      "cash": "100000",
      "portfolio_value": "100000",
      "equity": "100000",
      "last_equity": "100000",
      "buying_power": "400000",
      "initial_margin": "0",
      "maintenance_margin": "0",
      "long_market_value": "0",
      "short_market_value": "0",
      "pattern_day_trader": false,
      "trading_blocked": false,
      "transfers_blocked": false,
      "account_blocked": false,
      "daytrade_count": 0,
      "daytrading_buying_power": "0",
      "regt_buying_power": "200000",
      "multiplier": "4",
      "sma": "0",
      "created_at": "2024-01-01T00:00:00Z"
    }

#### Usage

    AlpacaAccount$get_account()

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `id` (character): Account UUID.

- `account_number` (character): Account number.

- `status` (character): Account status (e.g., `"ACTIVE"`).

- `currency` (character): Account currency (e.g., `"USD"`).

- `cash` (character): Cash balance.

- `portfolio_value` (character): Total portfolio value.

- `equity` (character): Account equity.

- `buying_power` (character): Available buying power.

- `initial_margin` (character): Initial margin requirement.

- `maintenance_margin` (character): Maintenance margin requirement.

- `long_market_value` (character): Market value of long positions.

- `short_market_value` (character): Market value of short positions.

- `pattern_day_trader` (logical): Whether flagged as PDT.

- `trading_blocked` (logical): Whether trading is blocked.

- `daytrade_count` (integer): Number of day trades in the last 5 days.

- `daytrading_buying_power` (character): Day trading buying power.

- `created_at` (character): Account creation timestamp.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    info <- acct$get_account()
    cat("Equity:", info$equity, "\n")
    cat("Buying power:", info$buying_power, "\n")
    }

------------------------------------------------------------------------

### Method `get_account_config()`

Get Account Configurations

Retrieves the current account configuration settings including DTBP
check behavior, trade confirmation emails, and shorting restrictions.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/account/configurations`

#### Official Documentation

[Get Account
Configurations](https://docs.alpaca.markets/reference/getaccountconfig-1)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/account/configurations'

#### JSON Response

    {
      "dtbp_check": "both",
      "no_shorting": false,
      "suspend_trade": false,
      "trade_confirm_email": "all",
      "fractional_trading": true,
      "max_margin_multiplier": "4",
      "pdt_check": "entry",
      "max_options_trading_level": 2
    }

#### Usage

    AlpacaAccount$get_account_config()

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `dtbp_check` (character): Day trading buying power check method.

- `no_shorting` (logical): Whether shorting is disabled.

- `suspend_trade` (logical): Whether trading is suspended.

- `trade_confirm_email` (character): Trade confirmation email setting.

- `fractional_trading` (logical): Whether fractional trading is enabled.

- `max_margin_multiplier` (character): Maximum margin multiplier.

- `pdt_check` (character): PDT check method.

- `max_options_trading_level` (integer): Options trading level.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    config <- acct$get_account_config()
    print(config)
    }

------------------------------------------------------------------------

### Method `modify_account_config()`

Update Account Configurations

Modifies one or more account configuration settings.

#### API Endpoint

`PATCH https://paper-api.alpaca.markets/v2/account/configurations`

#### Official Documentation

[Update Account
Configurations](https://docs.alpaca.markets/reference/patchaccountconfig-1)
Verified: 2026-03-10

#### curl

    curl -X PATCH -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      -H "Content-Type: application/json" \
      -d '{"no_shorting": true, "fractional_trading": false}' \
      'https://paper-api.alpaca.markets/v2/account/configurations'

#### JSON Request

    {
      "no_shorting": true,
      "fractional_trading": false
    }

#### JSON Response

    {
      "dtbp_check": "both",
      "no_shorting": true,
      "suspend_trade": false,
      "trade_confirm_email": "all",
      "fractional_trading": false,
      "max_margin_multiplier": "4",
      "pdt_check": "entry",
      "max_options_trading_level": 2
    }

#### Usage

    AlpacaAccount$modify_account_config(
      dtbp_check = NULL,
      no_shorting = NULL,
      suspend_trade = NULL,
      trade_confirm_email = NULL,
      fractional_trading = NULL,
      max_margin_multiplier = NULL,
      pdt_check = NULL,
      max_options_trading_level = NULL
    )

#### Arguments

- `dtbp_check`:

  Character or NULL; DTBP check method: `"both"`, `"entry"`, `"exit"`.

- `no_shorting`:

  Logical or NULL; if `TRUE`, disables short selling.

- `suspend_trade`:

  Logical or NULL; if `TRUE`, suspends all trading.

- `trade_confirm_email`:

  Character or NULL; `"all"`, `"none"`.

- `fractional_trading`:

  Logical or NULL; enable/disable fractional trading.

- `max_margin_multiplier`:

  Character or NULL; `"1"` (no margin) or `"2"` (Reg-T).

- `pdt_check`:

  Character or NULL; `"both"`, `"entry"`, `"exit"`.

- `max_options_trading_level`:

  Integer or NULL; options trading level (0-2).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the
updated configuration.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$modify_account_config(no_shorting = TRUE)
    }

------------------------------------------------------------------------

### Method `get_positions()`

Get All Open Positions

Retrieves all currently open positions in the account.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/positions`

#### Official Documentation

[Get All Open
Positions](https://docs.alpaca.markets/reference/getallopenpositions-1)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/positions'

#### JSON Response

    [
      {
        "asset_id": "904837e3-3b76-47ec-b432-046db621571b",
        "symbol": "AAPL",
        "exchange": "NASDAQ",
        "asset_class": "us_equity",
        "avg_entry_price": "185.50",
        "qty": "10",
        "side": "long",
        "market_value": "1870.00",
        "cost_basis": "1855.00",
        "unrealized_pl": "15.00",
        "unrealized_plpc": "0.008",
        "current_price": "187.00",
        "lastday_price": "186.00",
        "change_today": "0.005"
      }
    ]

#### Usage

    AlpacaAccount$get_positions()

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `asset_id` (character): Asset UUID.

- `symbol` (character): Ticker symbol.

- `exchange` (character): Exchange.

- `asset_class` (character): Asset class (e.g., `"us_equity"`).

- `avg_entry_price` (character): Average entry price.

- `qty` (character): Quantity held.

- `side` (character): Position side (`"long"` or `"short"`).

- `market_value` (character): Current market value.

- `cost_basis` (character): Total cost basis.

- `unrealized_pl` (character): Unrealised profit/loss.

- `unrealized_plpc` (character): Unrealised P/L percentage.

- `current_price` (character): Current asset price.

- `lastday_price` (character): Previous close price.

- `change_today` (character): Percentage change today.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    positions <- acct$get_positions()
    print(positions[, .(symbol, qty, unrealized_pl)])
    }

------------------------------------------------------------------------

### Method `get_position()`

Get Position by Symbol or Asset ID

Retrieves a single open position by symbol or asset UUID.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/positions/{symbol_or_asset_id}`

#### Official Documentation

[Get Open
Position](https://docs.alpaca.markets/reference/getopenposition-1)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/positions/AAPL'

#### JSON Response

    {
      "asset_id": "904837e3-3b76-47ec-b432-046db621571b",
      "symbol": "AAPL",
      "exchange": "NASDAQ",
      "asset_class": "us_equity",
      "avg_entry_price": "185.50",
      "qty": "10",
      "side": "long",
      "market_value": "1870.00",
      "cost_basis": "1855.00",
      "unrealized_pl": "15.00",
      "unrealized_plpc": "0.008",
      "current_price": "187.00",
      "lastday_price": "186.00",
      "change_today": "0.005"
    }

#### Usage

    AlpacaAccount$get_position(symbol_or_id)

#### Arguments

- `symbol_or_id`:

  Character; ticker symbol (e.g., `"AAPL"`) or asset UUID.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the same
columns as `get_positions()`, single row.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    pos <- acct$get_position("AAPL")
    print(pos[, .(symbol, qty, avg_entry_price, current_price, unrealized_pl)])
    }

------------------------------------------------------------------------

### Method `close_position()`

Close a Position

Closes an open position by symbol or asset ID. Supports closing the full
position or a partial amount by quantity or percentage.

#### API Endpoint

`DELETE https://paper-api.alpaca.markets/v2/positions/{symbol_or_asset_id}`

#### Official Documentation

[Close Position](https://docs.alpaca.markets/reference/deleteposition)
Verified: 2026-03-10

#### curl

    curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/positions/AAPL?percentage=50'

#### JSON Response

    {
      "id": "61e69015-8549-4bab-b63c-cc230e7e2e8b",
      "client_order_id": "eb9e2aaa-f71a-4f51-b5b4-52a6c565dad4",
      "created_at": "2026-03-10T14:30:00.000Z",
      "updated_at": "2026-03-10T14:30:00.000Z",
      "submitted_at": "2026-03-10T14:30:00.000Z",
      "symbol": "AAPL",
      "asset_class": "us_equity",
      "qty": "5",
      "filled_qty": "0",
      "type": "market",
      "side": "sell",
      "time_in_force": "day",
      "status": "pending_new"
    }

#### Usage

    AlpacaAccount$close_position(symbol_or_id, qty = NULL, percentage = NULL)

#### Arguments

- `symbol_or_id`:

  Character; ticker symbol or asset UUID.

- `qty`:

  Numeric or NULL; number of shares to close. Mutually exclusive with
  `percentage`.

- `percentage`:

  Numeric or NULL; percentage of position to close (0-100). Mutually
  exclusive with `qty`.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the
closing order details.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()

    # Close entire position
    acct$close_position("AAPL")

    # Close 50% of a position
    acct$close_position("AAPL", percentage = 50)

    # Close 5 shares
    acct$close_position("AAPL", qty = 5)
    }

------------------------------------------------------------------------

### Method `close_all_positions()`

Close All Positions

Closes all open positions. Optionally cancels all open orders first.

#### API Endpoint

`DELETE https://paper-api.alpaca.markets/v2/positions`

#### Official Documentation

[Close All
Positions](https://docs.alpaca.markets/reference/deleteallopenpositions)
Verified: 2026-03-10

#### curl

    curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/positions?cancel_orders=true'

#### JSON Response

    [
      {
        "symbol": "AAPL",
        "status": 200,
        "body": {
          "id": "61e69015-8549-4bab-b63c-cc230e7e2e8b",
          "symbol": "AAPL",
          "qty": "10",
          "side": "sell",
          "type": "market",
          "time_in_force": "day",
          "status": "pending_new"
        }
      },
      {
        "symbol": "MSFT",
        "status": 200,
        "body": {
          "id": "b3d29c1a-7e5f-4a2b-9c1d-8e7f6a5b4c3d",
          "symbol": "MSFT",
          "qty": "5",
          "side": "sell",
          "type": "market",
          "time_in_force": "day",
          "status": "pending_new"
        }
      }
    ]

#### Usage

    AlpacaAccount$close_all_positions(cancel_orders = FALSE)

#### Arguments

- `cancel_orders`:

  Logical; if `TRUE`, cancels all open orders before liquidating
  positions. Default `FALSE`.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`). When
positions are closed, one row per position with full order details. When
no open positions exist, a single confirmation row with columns:

- `cancel_orders` (logical): Whether orders were also cancelled.

- `status` (character): `"closed"`.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$close_all_positions(cancel_orders = TRUE)
    }

------------------------------------------------------------------------

### Method `exercise_option()`

Exercise an Options Position

Exercises an options position. Only applicable to options contracts.

#### API Endpoint

`POST https://paper-api.alpaca.markets/v2/positions/{symbol_or_id}/exercise`

#### Official Documentation

[Exercise
Option](https://docs.alpaca.markets/reference/postpositionsymboloridexercise)
Verified: 2026-03-10

#### curl

    curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/positions/AAPL240621C00200000/exercise'

#### JSON Response

The API returns `204 No Content` on success. This method returns a
confirmation `data.table`:

    {
      "symbol": "AAPL240621C00200000",
      "status": "exercised"
    }

#### Usage

    AlpacaAccount$exercise_option(symbol_or_id)

#### Arguments

- `symbol_or_id`:

  Character; OCC option symbol or asset UUID.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`), single row
with columns:

- `symbol` (character): The exercised option symbol or asset UUID.

- `status` (character): `"exercised"`.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$exercise_option("AAPL240621C00200000")
    }

------------------------------------------------------------------------

### Method `get_portfolio_history()`

Get Portfolio History

Retrieves the portfolio value history as a time series.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/account/portfolio/history`

#### Official Documentation

[Portfolio
History](https://docs.alpaca.markets/reference/getportfoliohistory)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/account/portfolio/history?period=1M&timeframe=1D'

#### JSON Response

    {
      "timestamp": [1704067200, 1704153600, 1704240000],
      "equity": [100000.0, 100150.5, 99800.25],
      "profit_loss": [0.0, 150.5, -200.25],
      "profit_loss_pct": [0.0, 0.001505, -0.002],
      "base_value": 100000.0,
      "timeframe": "1D"
    }

#### Usage

    AlpacaAccount$get_portfolio_history(
      period = NULL,
      timeframe = NULL,
      date_start = NULL,
      date_end = NULL,
      intraday_reporting = NULL,
      pnl_reset = NULL
    )

#### Arguments

- `period`:

  Character or NULL; time period for the history. Examples: `"1D"`,
  `"1W"`, `"1M"`, `"3M"`, `"1A"`, `"all"`. Cannot be used with
  `date_start`/`date_end`.

- `timeframe`:

  Character or NULL; resolution of the time series: `"1Min"`, `"5Min"`,
  `"15Min"`, `"1H"`, `"1D"`.

- `date_start`:

  Character or NULL; start date (`"YYYY-MM-DD"`). Use with `date_end`
  instead of `period`.

- `date_end`:

  Character or NULL; end date (`"YYYY-MM-DD"`).

- `intraday_reporting`:

  Character or NULL; `"market_hours"` (default) or `"extended_hours"`.

- `pnl_reset`:

  Character or NULL; `"per_day"` (default) or `"no_reset"`.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `timestamp` (POSIXct): Snapshot timestamp in UTC.

- `equity` (numeric): Portfolio equity value.

- `profit_loss` (numeric): Profit/loss.

- `profit_loss_pct` (numeric): Profit/loss percentage.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    history <- acct$get_portfolio_history(period = "1M", timeframe = "1D")
    print(history)
    }

------------------------------------------------------------------------

### Method `get_activities()`

Get Account Activities

Retrieves account activity history across all activity types. Activities
include order fills, dividends, transfers, and other events.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/account/activities`

#### Official Documentation

[Account
Activities](https://docs.alpaca.markets/reference/getaccountactivities)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/account/activities?activity_types=FILL&direction=desc&page_size=10'

#### JSON Response

    [
      {
        "id": "20260310120000000::b3d29c1a-7e5f-4a2b-9c1d-8e7f6a5b4c3d",
        "activity_type": "FILL",
        "symbol": "AAPL",
        "side": "buy",
        "qty": "10",
        "price": "187.25",
        "cum_qty": "10",
        "leaves_qty": "0",
        "type": "fill",
        "transaction_time": "2026-03-10T12:00:00.000Z",
        "order_id": "61e69015-8549-4bab-b63c-cc230e7e2e8b",
        "order_status": "filled"
      }
    ]

#### Usage

    AlpacaAccount$get_activities(
      activity_types = NULL,
      date = NULL,
      until = NULL,
      after = NULL,
      direction = NULL,
      page_size = NULL,
      page_token = NULL
    )

#### Arguments

- `activity_types`:

  Character or NULL; comma-separated activity types to filter (e.g.,
  `"FILL"`, `"DIV"`, `"TRANS"`). See Alpaca docs for full list.

- `date`:

  Character or NULL; filter to a specific date (`"YYYY-MM-DD"`).

- `until`:

  Character or NULL; only activities before this timestamp.

- `after`:

  Character or NULL; only activities after this timestamp.

- `direction`:

  Character or NULL; `"asc"` or `"desc"`.

- `page_size`:

  Integer or NULL; max results per page (default 100, max 100).

- `page_token`:

  Character or NULL; cursor for pagination.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with activity
details. Columns vary by activity type.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    activities <- acct$get_activities(activity_types = "FILL")
    print(activities)
    }

------------------------------------------------------------------------

### Method `get_activities_by_type()`

Get Account Activities by Type

Retrieves account activities filtered to a specific type.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/account/activities/{activity_type}`

#### Official Documentation

[Get Account Activities by
Type](https://docs.alpaca.markets/reference/getaccountactivitiesbyactivitytype)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/account/activities/FILL?direction=desc&page_size=5'

#### JSON Response

    [
      {
        "id": "20260310140000000::a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "activity_type": "FILL",
        "symbol": "TSLA",
        "side": "buy",
        "qty": "5",
        "price": "178.50",
        "cum_qty": "5",
        "leaves_qty": "0",
        "type": "fill",
        "transaction_time": "2026-03-10T14:00:00.000Z",
        "order_id": "c4d5e6f7-a8b9-0c1d-2e3f-4a5b6c7d8e9f",
        "order_status": "filled"
      }
    ]

#### Usage

    AlpacaAccount$get_activities_by_type(
      activity_type,
      date = NULL,
      until = NULL,
      after = NULL,
      direction = NULL,
      page_size = NULL,
      page_token = NULL
    )

#### Arguments

- `activity_type`:

  Character; activity type (e.g., `"FILL"`, `"DIV"`, `"TRANS"`,
  `"JNLC"`, `"JNLS"`, `"CSD"`, `"CSW"`).

- `date`:

  Character or NULL; filter to a specific date.

- `until`:

  Character or NULL; only activities before this timestamp.

- `after`:

  Character or NULL; only activities after this timestamp.

- `direction`:

  Character or NULL; `"asc"` or `"desc"`.

- `page_size`:

  Integer or NULL; max results per page.

- `page_token`:

  Character or NULL; cursor for pagination.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with activity
details.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    fills <- acct$get_activities_by_type("FILL")
    print(fills)
    }

------------------------------------------------------------------------

### Method `get_watchlists()`

Get All Watchlists

Retrieves all watchlists for the account.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/watchlists`

#### Official Documentation

[Watchlists](https://docs.alpaca.markets/reference/getwatchlists)
Verified: 2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/watchlists'

#### JSON Response

    [
      {
        "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
        "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
        "name": "Tech Stocks",
        "created_at": "2026-01-15T10:30:00Z",
        "updated_at": "2026-03-10T08:00:00Z"
      },
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
        "name": "Energy Sector",
        "created_at": "2026-02-20T14:00:00Z",
        "updated_at": "2026-03-09T16:45:00Z"
      }
    ]

#### Usage

    AlpacaAccount$get_watchlists()

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with columns:

- `id` (character): Watchlist UUID.

- `account_id` (character): Account UUID.

- `name` (character): Watchlist name.

- `created_at` (character): Creation timestamp.

- `updated_at` (character): Last update timestamp.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    watchlists <- acct$get_watchlists()
    print(watchlists)
    }

------------------------------------------------------------------------

### Method `get_watchlist()`

Get a Watchlist by ID

Retrieves a single watchlist including its asset entries.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`

#### Official Documentation

[Get Watchlist by
ID](https://docs.alpaca.markets/reference/getwatchlistbyid) Verified:
2026-03-10

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'

#### JSON Response

    {
      "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
      "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
      "name": "Tech Stocks",
      "created_at": "2026-01-15T10:30:00Z",
      "updated_at": "2026-03-10T08:00:00Z",
      "assets": [
        {
          "id": "904837e3-3b76-47ec-b432-046db621571b",
          "symbol": "AAPL",
          "name": "Apple Inc.",
          "exchange": "NASDAQ",
          "asset_class": "us_equity",
          "tradable": true
        },
        {
          "id": "b2e3f4a5-c6d7-8901-2345-6789abcdef01",
          "symbol": "MSFT",
          "name": "Microsoft Corporation",
          "exchange": "NASDAQ",
          "asset_class": "us_equity",
          "tradable": true
        }
      ]
    }

#### Usage

    AlpacaAccount$get_watchlist(watchlist_id)

#### Arguments

- `watchlist_id`:

  Character; watchlist UUID.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) in long format
with one row per asset in the watchlist. Columns include watchlist
metadata (`id`, `account_id`, `name`, `created_at`, `updated_at`) and
asset columns prefixed with `asset_` (`asset_id`, `asset_symbol`,
`asset_name`, etc.).

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    wl <- acct$get_watchlist("some-uuid")
    print(wl)
    }

------------------------------------------------------------------------

### Method `add_watchlist()`

Create a Watchlist

Creates a new watchlist with an optional initial set of symbols.

#### API Endpoint

`POST https://paper-api.alpaca.markets/v2/watchlists`

#### Official Documentation

[Create Watchlist](https://docs.alpaca.markets/reference/postwatchlist)
Verified: 2026-03-10

#### curl

    curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      -H "Content-Type: application/json" \
      -d '{"name": "My Tech Stocks", "symbols": ["AAPL", "MSFT", "GOOGL"]}' \
      'https://paper-api.alpaca.markets/v2/watchlists'

#### JSON Request

    {
      "name": "My Tech Stocks",
      "symbols": ["AAPL", "MSFT", "GOOGL"]
    }

#### JSON Response

    {
      "id": "d7e8f9a0-b1c2-3456-7890-abcdef123456",
      "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
      "name": "My Tech Stocks",
      "created_at": "2026-03-10T15:00:00Z",
      "updated_at": "2026-03-10T15:00:00Z",
      "assets": [
        {"id": "904837e3-3b76-47ec-b432-046db621571b", "symbol": "AAPL", "name": "Apple Inc."},
        {"id": "b2e3f4a5-c6d7-8901-2345-6789abcdef01", "symbol": "MSFT", "name": "Microsoft Corporation"},
        {"id": "c3d4e5f6-a7b8-9012-3456-789abcdef012", "symbol": "GOOGL", "name": "Alphabet Inc."}
      ]
    }

#### Usage

    AlpacaAccount$add_watchlist(name, symbols = NULL)

#### Arguments

- `name`:

  Character; watchlist name.

- `symbols`:

  Character vector or NULL; initial symbols (e.g., `c("AAPL", "MSFT")`).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the
created watchlist details.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    wl <- acct$add_watchlist("My Tech Stocks", symbols = c("AAPL", "MSFT", "GOOGL"))
    print(wl)
    }

------------------------------------------------------------------------

### Method `modify_watchlist()`

Update a Watchlist

Replaces the name and/or symbols of an existing watchlist.

#### API Endpoint

`PUT https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`

#### Official Documentation

[Update
Watchlist](https://docs.alpaca.markets/reference/putwatchlistbyid)
Verified: 2026-03-10

#### curl

    curl -X PUT -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      -H "Content-Type: application/json" \
      -d '{"name": "Updated Name", "symbols": ["AAPL", "TSLA"]}' \
      'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'

#### JSON Request

    {
      "name": "Updated Name",
      "symbols": ["AAPL", "TSLA"]
    }

#### JSON Response

    {
      "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
      "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
      "name": "Updated Name",
      "created_at": "2026-01-15T10:30:00Z",
      "updated_at": "2026-03-10T16:00:00Z",
      "assets": [
        {"id": "904837e3-3b76-47ec-b432-046db621571b", "symbol": "AAPL", "name": "Apple Inc."},
        {"id": "e5f6a7b8-c9d0-1234-5678-9abcdef01234", "symbol": "TSLA", "name": "Tesla, Inc."}
      ]
    }

#### Usage

    AlpacaAccount$modify_watchlist(watchlist_id, name, symbols)

#### Arguments

- `watchlist_id`:

  Character; watchlist UUID.

- `name`:

  Character; new watchlist name.

- `symbols`:

  Character vector; new full list of symbols (replaces existing).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with updated
watchlist details.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$modify_watchlist("some-uuid", name = "Updated Name",
                          symbols = c("AAPL", "TSLA"))
    }

------------------------------------------------------------------------

### Method `add_watchlist_symbol()`

Add Symbol to Watchlist

Appends a single symbol to an existing watchlist.

#### API Endpoint

`POST https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`

#### Official Documentation

[Add Symbol to
Watchlist](https://docs.alpaca.markets/reference/postwatchlistbyid)
Verified: 2026-03-10

#### curl

    curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      -H "Content-Type: application/json" \
      -d '{"symbol": "NVDA"}' \
      'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'

#### JSON Request

    {
      "symbol": "NVDA"
    }

#### JSON Response

    {
      "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
      "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
      "name": "Tech Stocks",
      "created_at": "2026-01-15T10:30:00Z",
      "updated_at": "2026-03-10T16:30:00Z",
      "assets": [
        {"id": "904837e3-3b76-47ec-b432-046db621571b", "symbol": "AAPL", "name": "Apple Inc."},
        {"id": "b2e3f4a5-c6d7-8901-2345-6789abcdef01", "symbol": "MSFT", "name": "Microsoft Corporation"},
        {"id": "f6a7b8c9-d0e1-2345-6789-abcdef012345", "symbol": "NVDA", "name": "NVIDIA Corporation"}
      ]
    }

#### Usage

    AlpacaAccount$add_watchlist_symbol(watchlist_id, symbol)

#### Arguments

- `watchlist_id`:

  Character; watchlist UUID.

- `symbol`:

  Character; ticker symbol to add (e.g., `"AAPL"`).

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`) with the
updated watchlist.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$add_watchlist_symbol("some-uuid", "NVDA")
    }

------------------------------------------------------------------------

### Method `cancel_watchlist_symbol()`

Remove Symbol from Watchlist

Removes a single symbol from a watchlist.

#### API Endpoint

`DELETE https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}/{symbol}`

#### Official Documentation

[Remove Symbol from
Watchlist](https://docs.alpaca.markets/reference/deletewatchlistbyidsymbol)
Verified: 2026-03-10

#### curl

    curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234/AAPL'

#### JSON Response

The API returns `204 No Content` on success. This method returns a
confirmation `data.table`:

    {
      "watchlist_id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
      "symbol": "AAPL",
      "status": "removed"
    }

#### Usage

    AlpacaAccount$cancel_watchlist_symbol(watchlist_id, symbol)

#### Arguments

- `watchlist_id`:

  Character; watchlist UUID.

- `symbol`:

  Character; ticker symbol to remove.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`). When the API
returns the updated watchlist, a single row with watchlist details. On
204 No Content, a single confirmation row with columns:

- `watchlist_id` (character): The watchlist UUID.

- `symbol` (character): The removed ticker symbol.

- `status` (character): `"removed"`.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$cancel_watchlist_symbol("some-uuid", "AAPL")
    }

------------------------------------------------------------------------

### Method `cancel_watchlist()`

Delete a Watchlist

Permanently deletes a watchlist.

#### API Endpoint

`DELETE https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`

#### Official Documentation

[Delete
Watchlist](https://docs.alpaca.markets/reference/deletewatchlistbyid)
Verified: 2026-03-10

#### curl

    curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'

#### JSON Response

The API returns `204 No Content` on success. This method returns a
confirmation `data.table`:

    {
      "watchlist_id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
      "status": "deleted"
    }

#### Usage

    AlpacaAccount$cancel_watchlist(watchlist_id)

#### Arguments

- `watchlist_id`:

  Character; watchlist UUID.

#### Returns

`data.table` (or `promise<data.table>` if `async = TRUE`), single row
with columns:

- `watchlist_id` (character): The deleted watchlist UUID.

- `status` (character): `"deleted"`.

#### Examples

    \dontrun{
    acct <- AlpacaAccount$new()
    acct$cancel_watchlist("some-uuid")
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AlpacaAccount$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()

# Account details
info <- acct$get_account()
print(info[, .(status, equity, buying_power, cash)])

# Open positions
positions <- acct$get_positions()
print(positions)
} # }


## ------------------------------------------------
## Method `AlpacaAccount$get_account`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
info <- acct$get_account()
cat("Equity:", info$equity, "\n")
cat("Buying power:", info$buying_power, "\n")
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_account_config`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
config <- acct$get_account_config()
print(config)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$modify_account_config`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$modify_account_config(no_shorting = TRUE)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_positions`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
positions <- acct$get_positions()
print(positions[, .(symbol, qty, unrealized_pl)])
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_position`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
pos <- acct$get_position("AAPL")
print(pos[, .(symbol, qty, avg_entry_price, current_price, unrealized_pl)])
} # }

## ------------------------------------------------
## Method `AlpacaAccount$close_position`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()

# Close entire position
acct$close_position("AAPL")

# Close 50% of a position
acct$close_position("AAPL", percentage = 50)

# Close 5 shares
acct$close_position("AAPL", qty = 5)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$close_all_positions`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$close_all_positions(cancel_orders = TRUE)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$exercise_option`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$exercise_option("AAPL240621C00200000")
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_portfolio_history`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
history <- acct$get_portfolio_history(period = "1M", timeframe = "1D")
print(history)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_activities`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
activities <- acct$get_activities(activity_types = "FILL")
print(activities)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_activities_by_type`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
fills <- acct$get_activities_by_type("FILL")
print(fills)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_watchlists`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
watchlists <- acct$get_watchlists()
print(watchlists)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$get_watchlist`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
wl <- acct$get_watchlist("some-uuid")
print(wl)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$add_watchlist`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
wl <- acct$add_watchlist("My Tech Stocks", symbols = c("AAPL", "MSFT", "GOOGL"))
print(wl)
} # }

## ------------------------------------------------
## Method `AlpacaAccount$modify_watchlist`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$modify_watchlist("some-uuid", name = "Updated Name",
                      symbols = c("AAPL", "TSLA"))
} # }

## ------------------------------------------------
## Method `AlpacaAccount$add_watchlist_symbol`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$add_watchlist_symbol("some-uuid", "NVDA")
} # }

## ------------------------------------------------
## Method `AlpacaAccount$cancel_watchlist_symbol`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$cancel_watchlist_symbol("some-uuid", "AAPL")
} # }

## ------------------------------------------------
## Method `AlpacaAccount$cancel_watchlist`
## ------------------------------------------------

if (FALSE) { # \dontrun{
acct <- AlpacaAccount$new()
acct$cancel_watchlist("some-uuid")
} # }
```
