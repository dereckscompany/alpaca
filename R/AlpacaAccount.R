# File: R/AlpacaAccount.R
# R6 class for Alpaca account, positions, and portfolio management.

#' AlpacaAccount: Account, Positions, and Portfolio
#'
#' Provides methods for retrieving account information, managing positions,
#' viewing portfolio history, and querying account activities on Alpaca's
#' Trading API.
#'
#' Inherits from [AlpacaBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Account**: Retrieve current account details (equity, buying power, etc.).
#' - **Positions**: View all open positions or a specific position by symbol.
#' - **Close Positions**: Close individual positions (fully or partially).
#' - **Options Exercise**: Exercise options positions.
#' - **Account Config**: View and update account configurations.
#' - **Portfolio History**: View historical portfolio value snapshots.
#' - **Activities**: Query account activity history (fills, dividends, etc.).
#' - **Watchlists**: Create, update, and manage symbol watchlists.
#'
#' ### Official Documentation
#' - [Account](https://docs.alpaca.markets/us/reference/getaccount-1)
#' - [Positions](https://docs.alpaca.markets/us/reference/getallopenpositions)
#' - [Portfolio History](https://docs.alpaca.markets/us/reference/getaccountportfoliohistory-1)
#' - [Account Activities](https://docs.alpaca.markets/us/reference/getaccountactivities-2)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_account | `GET /v2/account` | GET |
#' | get_positions | `GET /v2/positions` | GET |
#' | get_position | `GET /v2/positions/\{symbol_or_id\}` | GET |
#' | close_position | `DELETE /v2/positions/\{symbol_or_id\}` | DELETE |
#' | close_all_positions | `DELETE /v2/positions` | DELETE |
#' | get_account_config | `GET /v2/account/configurations` | GET |
#' | modify_account_config | `PATCH /v2/account/configurations` | PATCH |
#' | exercise_option | `POST /v2/positions/\{symbol_or_id\}/exercise` | POST |
#' | get_portfolio_history | `GET /v2/account/portfolio/history` | GET |
#' | get_activities | `GET /v2/account/activities` | GET |
#' | get_activities_by_type | `GET /v2/account/activities/\{type\}` | GET |
#' | get_watchlists | `GET /v2/watchlists` | GET |
#' | get_watchlist | `GET /v2/watchlists/\{id\}` | GET |
#' | add_watchlist | `POST /v2/watchlists` | POST |
#' | modify_watchlist | `PUT /v2/watchlists/\{id\}` | PUT |
#' | add_watchlist_symbol | `POST /v2/watchlists/\{id\}` | POST |
#' | cancel_watchlist_symbol | `DELETE /v2/watchlists/\{id\}/\{symbol\}` | DELETE |
#' | cancel_watchlist | `DELETE /v2/watchlists/\{id\}` | DELETE |
#'
#' @examples
#' \dontrun{
#' acct <- AlpacaAccount$new()
#'
#' # Account details
#' info <- acct$get_account()
#' print(info[, .(status, equity, buying_power, cash)])
#'
#' # Open positions
#' positions <- acct$get_positions()
#' print(positions)
#' }
#'
#' @importFrom R6 R6Class
#' @export
AlpacaAccount <- R6::R6Class(
  "AlpacaAccount",
  inherit = AlpacaBase,
  public = list(
    # ---- Account ----

    #' @description
    #' Get Account Information
    #'
    #' Retrieves the current account details including equity, buying power,
    #' cash, margin, and account status.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/account`
    #'
    #' ### Official Documentation
    #' [Get Account](https://docs.alpaca.markets/us/reference/getaccount-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/account'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'   "account_number": "PA1234567",
    #'   "status": "ACTIVE",
    #'   "currency": "USD",
    #'   "cash": "100000",
    #'   "portfolio_value": "100000",
    #'   "equity": "100000",
    #'   "last_equity": "100000",
    #'   "buying_power": "400000",
    #'   "initial_margin": "0",
    #'   "maintenance_margin": "0",
    #'   "long_market_value": "0",
    #'   "short_market_value": "0",
    #'   "pattern_day_trader": false,
    #'   "trading_blocked": false,
    #'   "transfers_blocked": false,
    #'   "account_blocked": false,
    #'   "daytrade_count": 0,
    #'   "daytrading_buying_power": "0",
    #'   "regt_buying_power": "200000",
    #'   "multiplier": "4",
    #'   "sma": "0",
    #'   "created_at": "2024-01-01T00:00:00Z"
    #' }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Account UUID.
    #'   - `account_number` (character): Account number.
    #'   - `status` (character): Account status (e.g., `"ACTIVE"`).
    #'   - `currency` (character): Account currency (e.g., `"USD"`).
    #'   - `cash` (character): Cash balance.
    #'   - `portfolio_value` (character): Total portfolio value.
    #'   - `equity` (character): Account equity.
    #'   - `buying_power` (character): Available buying power.
    #'   - `initial_margin` (character): Initial margin requirement.
    #'   - `maintenance_margin` (character): Maintenance margin requirement.
    #'   - `long_market_value` (character): Market value of long positions.
    #'   - `short_market_value` (character): Market value of short positions.
    #'   - `pattern_day_trader` (logical): Whether flagged as PDT.
    #'   - `trading_blocked` (logical): Whether trading is blocked.
    #'   - `daytrade_count` (integer): Number of day trades in the last 5 days.
    #'   - `daytrading_buying_power` (character): Day trading buying power.
    #'   - `created_at` (POSIXct, UTC): Account creation timestamp.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' info <- acct$get_account()
    #' cat("Equity:", info$equity, "\n")
    #' cat("Buying power:", info$buying_power, "\n")
    #' }
    get_account = function() {
      return(private$.request(
        endpoint = "/v2/account",
        .parser = function(data) {
          # Flatten nested configuration objects into wide prefixed columns
          for (cfg_field in c("admin_configurations", "user_configurations")) {
            cfg <- data[[cfg_field]]
            if (!is.null(cfg) && is.list(cfg) && length(cfg) > 0) {
              for (nm in names(cfg)) {
                data[[paste0(cfg_field, "_", nm)]] <- cfg[[nm]]
              }
            }
            data[[cfg_field]] <- NULL
          }
          dt <- as_dt_row(data)
          parse_timestamp_cols(dt, "created_at")
          return(dt)
        }
      ))
    },

    #' @description
    #' Get Account Configurations
    #'
    #' Retrieves the current account configuration settings including DTBP
    #' check behaviour, trade confirmation emails, and shorting restrictions.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/account/configurations`
    #'
    #' ### Official Documentation
    #' [Get Account Configurations](https://docs.alpaca.markets/us/reference/getaccountconfig-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/account/configurations'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "dtbp_check": "both",
    #'   "no_shorting": false,
    #'   "suspend_trade": false,
    #'   "trade_confirm_email": "all",
    #'   "fractional_trading": true,
    #'   "max_margin_multiplier": "4",
    #'   "pdt_check": "entry",
    #'   "max_options_trading_level": 2
    #' }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `dtbp_check` (character): Day trading buying power check method.
    #'   - `no_shorting` (logical): Whether shorting is disabled.
    #'   - `suspend_trade` (logical): Whether trading is suspended.
    #'   - `trade_confirm_email` (character): Trade confirmation email setting.
    #'   - `fractional_trading` (logical): Whether fractional trading is enabled.
    #'   - `max_margin_multiplier` (character): Maximum margin multiplier.
    #'   - `pdt_check` (character): PDT check method.
    #'   - `max_options_trading_level` (integer): Options trading level.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' config <- acct$get_account_config()
    #' print(config)
    #' }
    get_account_config = function() {
      return(private$.request(
        endpoint = "/v2/account/configurations",
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Update Account Configurations
    #'
    #' Modifies one or more account configuration settings.
    #'
    #' ### API Endpoint
    #' `PATCH https://paper-api.alpaca.markets/v2/account/configurations`
    #'
    #' ### Official Documentation
    #' [Update Account Configurations](https://docs.alpaca.markets/us/reference/patchaccountconfig-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X PATCH -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   -H "Content-Type: application/json" \
    #'   -d '{"no_shorting": true, "fractional_trading": false}' \
    #'   'https://paper-api.alpaca.markets/v2/account/configurations'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "no_shorting": true,
    #'   "fractional_trading": false
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "dtbp_check": "both",
    #'   "no_shorting": true,
    #'   "suspend_trade": false,
    #'   "trade_confirm_email": "all",
    #'   "fractional_trading": false,
    #'   "max_margin_multiplier": "4",
    #'   "pdt_check": "entry",
    #'   "max_options_trading_level": 2
    #' }
    #' ```
    #'
    #' @param dtbp_check Character or NULL; DTBP check method: `"both"`, `"entry"`, `"exit"`.
    #' @param no_shorting Logical or NULL; if `TRUE`, disables short selling.
    #' @param suspend_trade Logical or NULL; if `TRUE`, suspends all trading.
    #' @param trade_confirm_email Character or NULL; `"all"`, `"none"`.
    #' @param fractional_trading Logical or NULL; enable/disable fractional trading.
    #' @param max_margin_multiplier Character or NULL; `"1"`, `"2"`, or `"4"`.
    #' @param pdt_check Character or NULL; `"both"`, `"entry"`, `"exit"`.
    #' @param max_options_trading_level Integer or NULL; options trading level
    #'   (0=disabled, 1=Covered Call/Cash-Secured Put, 2=Long Call/Put,
    #'   3=Spreads/Straddles).
    #' @param ptp_no_exception_entry Logical or NULL; if `TRUE`, accept orders
    #'   for PTP symbols with no exception.
    #' @param disable_overnight_trading Logical or NULL; if `TRUE`, disable
    #'   overnight trading on the account.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the updated configuration.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$modify_account_config(no_shorting = TRUE)
    #' }
    modify_account_config = function(
      dtbp_check = NULL,
      no_shorting = NULL,
      suspend_trade = NULL,
      trade_confirm_email = NULL,
      fractional_trading = NULL,
      max_margin_multiplier = NULL,
      pdt_check = NULL,
      max_options_trading_level = NULL,
      ptp_no_exception_entry = NULL,
      disable_overnight_trading = NULL
    ) {
      return(private$.request(
        endpoint = "/v2/account/configurations",
        method = "PATCH",
        body = list(
          dtbp_check = dtbp_check,
          no_shorting = no_shorting,
          suspend_trade = suspend_trade,
          trade_confirm_email = trade_confirm_email,
          fractional_trading = fractional_trading,
          max_margin_multiplier = max_margin_multiplier,
          pdt_check = pdt_check,
          max_options_trading_level = max_options_trading_level,
          ptp_no_exception_entry = ptp_no_exception_entry,
          disable_overnight_trading = disable_overnight_trading
        ),
        .parser = as_dt_row
      ))
    },

    # ---- Positions ----

    #' @description
    #' Get All Open Positions
    #'
    #' Retrieves all currently open positions in the account.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/positions`
    #'
    #' ### Official Documentation
    #' [Get All Open Positions](https://docs.alpaca.markets/us/reference/getallopenpositions)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/positions'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "asset_id": "904837e3-3b76-47ec-b432-046db621571b",
    #'     "symbol": "AAPL",
    #'     "exchange": "NASDAQ",
    #'     "asset_class": "us_equity",
    #'     "avg_entry_price": "185.50",
    #'     "qty": "10",
    #'     "side": "long",
    #'     "market_value": "1870.00",
    #'     "cost_basis": "1855.00",
    #'     "unrealized_pl": "15.00",
    #'     "unrealized_plpc": "0.008",
    #'     "current_price": "187.00",
    #'     "lastday_price": "186.00",
    #'     "change_today": "0.005"
    #'   }
    #' ]
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `asset_id` (character): Asset UUID.
    #'   - `symbol` (character): Ticker symbol.
    #'   - `exchange` (character): Exchange.
    #'   - `asset_class` (character): Asset class (e.g., `"us_equity"`).
    #'   - `avg_entry_price` (character): Average entry price.
    #'   - `qty` (character): Quantity held.
    #'   - `side` (character): Position side (`"long"` or `"short"`).
    #'   - `market_value` (character): Current market value.
    #'   - `cost_basis` (character): Total cost basis.
    #'   - `unrealized_pl` (character): Unrealised profit/loss.
    #'   - `unrealized_plpc` (character): Unrealised P/L percentage.
    #'   - `current_price` (character): Current asset price.
    #'   - `lastday_price` (character): Previous close price.
    #'   - `change_today` (character): Percentage change today.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' positions <- acct$get_positions()
    #' print(positions[, .(symbol, qty, unrealized_pl)])
    #' }
    get_positions = function() {
      return(private$.request(
        endpoint = "/v2/positions",
        .parser = as_dt_list
      ))
    },

    #' @description
    #' Get Position by Symbol or Asset ID
    #'
    #' Retrieves a single open position by symbol or asset UUID.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/positions/{symbol_or_asset_id}`
    #'
    #' ### Official Documentation
    #' [Get Open Position](https://docs.alpaca.markets/us/reference/getopenposition-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/positions/AAPL'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "asset_id": "904837e3-3b76-47ec-b432-046db621571b",
    #'   "symbol": "AAPL",
    #'   "exchange": "NASDAQ",
    #'   "asset_class": "us_equity",
    #'   "avg_entry_price": "185.50",
    #'   "qty": "10",
    #'   "side": "long",
    #'   "market_value": "1870.00",
    #'   "cost_basis": "1855.00",
    #'   "unrealized_pl": "15.00",
    #'   "unrealized_plpc": "0.008",
    #'   "current_price": "187.00",
    #'   "lastday_price": "186.00",
    #'   "change_today": "0.005"
    #' }
    #' ```
    #'
    #' @param symbol_or_id Character; ticker symbol (e.g., `"AAPL"`) or asset UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with the
    #'   same columns as `get_positions()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' pos <- acct$get_position("AAPL")
    #' print(pos[, .(symbol, qty, avg_entry_price, current_price, unrealized_pl)])
    #' }
    get_position = function(symbol_or_id) {
      endpoint <- paste0("/v2/positions/", symbol_or_id)
      return(private$.request(
        endpoint = endpoint,
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Close a Position
    #'
    #' Closes an open position by symbol or asset ID. Supports closing the
    #' full position or a partial amount by quantity or percentage.
    #'
    #' ### API Endpoint
    #' `DELETE https://paper-api.alpaca.markets/v2/positions/{symbol_or_asset_id}`
    #'
    #' ### Official Documentation
    #' [Close Position](https://docs.alpaca.markets/us/reference/deleteopenposition-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/positions/AAPL?percentage=50'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "61e69015-8549-4bab-b63c-cc230e7e2e8b",
    #'   "client_order_id": "eb9e2aaa-f71a-4f51-b5b4-52a6c565dad4",
    #'   "created_at": "2026-03-10T14:30:00.000Z",
    #'   "updated_at": "2026-03-10T14:30:00.000Z",
    #'   "submitted_at": "2026-03-10T14:30:00.000Z",
    #'   "symbol": "AAPL",
    #'   "asset_class": "us_equity",
    #'   "qty": "5",
    #'   "filled_qty": "0",
    #'   "type": "market",
    #'   "side": "sell",
    #'   "time_in_force": "day",
    #'   "status": "pending_new"
    #' }
    #' ```
    #'
    #' @param symbol_or_id Character; ticker symbol or asset UUID.
    #' @param qty Numeric or NULL; number of shares to close. Mutually exclusive
    #'   with `percentage`.
    #' @param percentage Numeric or NULL; percentage of position to close (0-100).
    #'   Mutually exclusive with `qty`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the closing order details.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #'
    #' # Close entire position
    #' acct$close_position("AAPL")
    #'
    #' # Close 50% of a position
    #' acct$close_position("AAPL", percentage = 50)
    #'
    #' # Close 5 shares
    #' acct$close_position("AAPL", qty = 5)
    #' }
    close_position = function(symbol_or_id, qty = NULL, percentage = NULL) {
      if (!is.null(qty) && !is.null(percentage)) {
        rlang::abort("`qty` and `percentage` are mutually exclusive.")
      }
      if (!is.null(qty)) {
        qty <- as.character(qty)
      }
      if (!is.null(percentage)) {
        percentage <- as.character(percentage)
      }

      endpoint <- paste0("/v2/positions/", symbol_or_id)
      return(private$.request(
        endpoint = endpoint,
        method = "DELETE",
        query = list(qty = qty, percentage = percentage),
        .parser = function(data) {
          dt <- as_dt_row(data)
          parse_timestamp_cols(dt, ORDER_TIMESTAMP_COLS)
          return(dt)
        }
      ))
    },

    #' @description
    #' Close All Positions
    #'
    #' Closes all open positions. Optionally cancels all open orders first.
    #'
    #' ### API Endpoint
    #' `DELETE https://paper-api.alpaca.markets/v2/positions`
    #'
    #' ### Official Documentation
    #' [Close All Positions](https://docs.alpaca.markets/us/reference/deleteallopenpositions-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/positions?cancel_orders=true'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "symbol": "AAPL",
    #'     "status": 200,
    #'     "body": {
    #'       "id": "61e69015-8549-4bab-b63c-cc230e7e2e8b",
    #'       "symbol": "AAPL",
    #'       "qty": "10",
    #'       "side": "sell",
    #'       "type": "market",
    #'       "time_in_force": "day",
    #'       "status": "pending_new"
    #'     }
    #'   },
    #'   {
    #'     "symbol": "MSFT",
    #'     "status": 200,
    #'     "body": {
    #'       "id": "b3d29c1a-7e5f-4a2b-9c1d-8e7f6a5b4c3d",
    #'       "symbol": "MSFT",
    #'       "qty": "5",
    #'       "side": "sell",
    #'       "type": "market",
    #'       "time_in_force": "day",
    #'       "status": "pending_new"
    #'     }
    #'   }
    #' ]
    #' ```
    #'
    #' @param cancel_orders Logical; if `TRUE`, cancels all open orders before
    #'   liquidating positions. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`).
    #'   When positions are closed, one row per position with full order details.
    #'   When no open positions exist, a single confirmation row with columns:
    #'   - `cancel_orders` (logical): Whether orders were also cancelled.
    #'   - `status` (character): `"closed"`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$close_all_positions(cancel_orders = TRUE)
    #' }
    close_all_positions = function(cancel_orders = FALSE) {
      return(private$.request(
        endpoint = "/v2/positions",
        method = "DELETE",
        query = list(cancel_orders = tolower(as.character(cancel_orders))),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table(
              cancel_orders = cancel_orders,
              status = "closed"
            )[])
          }
          # Alpaca returns [{symbol, status, body: {order...}}, ...]
          # Unwrap body into top-level fields
          unwrapped <- lapply(data, function(item) {
            body <- item$body
            item$body <- NULL
            if (is.list(body)) {
              return(c(item, body))
            } else {
              return(item)
            }
          })
          dt <- as_dt_list(unwrapped)
          parse_timestamp_cols(dt, ORDER_TIMESTAMP_COLS)
          return(dt)
        }
      ))
    },

    #' @description
    #' Exercise an Options Position
    #'
    #' Exercises an options position. Only applicable to options contracts.
    #'
    #' ### API Endpoint
    #' `POST https://paper-api.alpaca.markets/v2/positions/{symbol_or_id}/exercise`
    #'
    #' ### Official Documentation
    #' [Exercise Option](https://docs.alpaca.markets/us/reference/optionexercise)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/positions/AAPL240621C00200000/exercise'
    #' ```
    #'
    #' ### JSON Response
    #' The API returns `204 No Content` on success. This method returns a
    #' confirmation `data.table`:
    #' ```json
    #' {
    #'   "symbol": "AAPL240621C00200000",
    #'   "status": "exercised"
    #' }
    #' ```
    #'
    #' @param symbol_or_id Character; OCC option symbol or asset UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row with columns:
    #'   - `symbol` (character): The exercised option symbol or asset UUID.
    #'   - `status` (character): `"exercised"`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$exercise_option("AAPL240621C00200000")
    #' }
    exercise_option = function(symbol_or_id) {
      endpoint <- paste0("/v2/positions/", symbol_or_id, "/exercise")
      return(private$.request(
        endpoint = endpoint,
        method = "POST",
        .parser = function(data) {
          return(data.table::data.table(
            symbol = symbol_or_id,
            status = "exercised"
          )[])
        }
      ))
    },

    # ---- Portfolio History ----

    #' @description
    #' Get Portfolio History
    #'
    #' Retrieves the portfolio value history as a time series.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/account/portfolio/history`
    #'
    #' ### Official Documentation
    #' [Portfolio History](https://docs.alpaca.markets/us/reference/getaccountportfoliohistory-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/account/portfolio/history?period=1M&timeframe=1D'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "timestamp": [1704067200, 1704153600, 1704240000],
    #'   "equity": [100000.0, 100150.5, 99800.25],
    #'   "profit_loss": [0.0, 150.5, -200.25],
    #'   "profit_loss_pct": [0.0, 0.001505, -0.002],
    #'   "base_value": 100000.0,
    #'   "timeframe": "1D"
    #' }
    #' ```
    #'
    #' @param period Character or NULL; time period for the history. Examples:
    #'   `"1D"`, `"1W"`, `"1M"`, `"3M"`, `"1A"`, `"all"`. Mutually exclusive with
    #'   providing both `start` and `end`.
    #' @param timeframe Character or NULL; resolution of the time series:
    #'   `"1Min"`, `"5Min"`, `"15Min"`, `"1H"`, `"1D"`.
    #' @param start Character or NULL; start timestamp in RFC3339 format.
    #'   Defaults to `end` minus `period`.
    #' @param end Character or NULL; end timestamp in RFC3339 format.
    #' @param intraday_reporting Character or NULL; `"market_hours"` (default),
    #'   `"extended_hours"`, or `"continuous"` (for 24/7 crypto charts).
    #' @param pnl_reset Character or NULL; `"per_day"` (default) or `"no_reset"`.
    #'   Set to `"no_reset"` for continuous crypto PnL.
    #' @param date_start Deprecated alias for `start`. Earlier releases used
    #'   this name but it was silently ignored by the API. Now forwarded to
    #'   `start` with a deprecation warning. Will be removed in a future
    #'   release.
    #' @param date_end Deprecated alias for `end`. Same notes as `date_start`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
    #'   - `equity` (numeric): Portfolio equity value.
    #'   - `profit_loss` (numeric): Profit/loss.
    #'   - `profit_loss_pct` (numeric): Profit/loss percentage.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' history <- acct$get_portfolio_history(period = "1M", timeframe = "1D")
    #' print(history)
    #' }
    get_portfolio_history = function(
      period = NULL,
      timeframe = NULL,
      start = NULL,
      end = NULL,
      intraday_reporting = NULL,
      pnl_reset = NULL,
      date_start = NULL,
      date_end = NULL
    ) {
      # Deprecated aliases — forward to the new names with a once-per-session
      # warning so a tight loop doesn't spam stderr.
      if (!is.null(date_start)) {
        rlang::warn(
          "`date_start` is deprecated as of alpaca 0.1.0; use `start` instead. Forwarding the value.",
          .frequency = "regularly",
          .frequency_id = "get_portfolio_history_date_start_deprecated"
        )
        if (is.null(start)) start <- date_start
      }
      if (!is.null(date_end)) {
        rlang::warn(
          "`date_end` is deprecated as of alpaca 0.1.0; use `end` instead. Forwarding the value.",
          .frequency = "regularly",
          .frequency_id = "get_portfolio_history_date_end_deprecated"
        )
        if (is.null(end)) end <- date_end
      }
      if (!is.null(period) && !is.null(start) && !is.null(end)) {
        rlang::abort("Only two of `start`, `end`, and `period` may be supplied at once.")
      }
      if (!is.null(intraday_reporting)) {
        rlang::arg_match0(intraday_reporting, c("market_hours", "extended_hours", "continuous"))
      }
      if (!is.null(pnl_reset)) {
        rlang::arg_match0(pnl_reset, c("per_day", "no_reset"))
      }
      return(private$.request(
        endpoint = "/v2/account/portfolio/history",
        query = list(
          period = period,
          timeframe = timeframe,
          start = start,
          end = end,
          intraday_reporting = intraday_reporting,
          pnl_reset = pnl_reset
        ),
        simplifyVector = TRUE,
        .parser = function(data) {
          if (is.null(data) || is.null(data$timestamp) || length(data$timestamp) == 0) {
            return(data.table::data.table()[])
          }
          dt <- data.table::data.table(
            timestamp = lubridate::as_datetime(as.integer(data$timestamp), tz = "UTC"),
            equity = as.numeric(data$equity),
            profit_loss = as.numeric(data$profit_loss),
            profit_loss_pct = as.numeric(data$profit_loss_pct)
          )
          return(dt[])
        }
      ))
    },

    # ---- Account Activities ----

    #' @description
    #' Get Account Activities
    #'
    #' Retrieves account activity history across all activity types. Activities
    #' include order fills, dividends, transfers, and other events.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/account/activities`
    #'
    #' ### Official Documentation
    #' [Account Activities](https://docs.alpaca.markets/us/reference/getaccountactivities-2)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/account/activities?activity_types=FILL&direction=desc&page_size=10'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "20260310120000000::b3d29c1a-7e5f-4a2b-9c1d-8e7f6a5b4c3d",
    #'     "activity_type": "FILL",
    #'     "symbol": "AAPL",
    #'     "side": "buy",
    #'     "qty": "10",
    #'     "price": "187.25",
    #'     "cum_qty": "10",
    #'     "leaves_qty": "0",
    #'     "type": "fill",
    #'     "transaction_time": "2026-03-10T12:00:00.000Z",
    #'     "order_id": "61e69015-8549-4bab-b63c-cc230e7e2e8b",
    #'     "order_status": "filled"
    #'   }
    #' ]
    #' ```
    #'
    #' @param activity_types Character or NULL; comma-separated activity types to
    #'   filter (e.g., `"FILL"`, `"DIV"`, `"TRANS"`). See Alpaca docs for full list.
    #'   Mutually exclusive with `category`.
    #' @param category Character or NULL; broad category filter:
    #'   `"trade_activity"` or `"non_trade_activity"`. Mutually exclusive with
    #'   `activity_types`.
    #' @param date Character or NULL; filter to a specific date (`"YYYY-MM-DD"`).
    #' @param until Character or NULL; only activities before this timestamp.
    #' @param after Character or NULL; only activities after this timestamp.
    #' @param direction Character or NULL; `"asc"` or `"desc"`.
    #' @param page_size Integer or NULL; max results per page. Alpaca caps
    #'   this at **100** for `/v2/account/activities`; values above 100
    #'   return HTTP 422 server-side. This method validates the cap up-front
    #'   and `abort()`s with a clear message rather than letting the vendor
    #'   error leak through. Default `NULL` lets Alpaca pick its server-side
    #'   default (currently 100).
    #' @param page_token Character or NULL; cursor for the next page. For
    #'   activities this is the **`id` of the last row from the previous
    #'   page** (Alpaca's activity IDs are sortable cursors, not opaque
    #'   tokens). See the "Pagination" section below.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   activity details. Columns vary by activity type. Always includes
    #'   `id` (the per-activity cursor — see "Pagination").
    #'
    #' @section Pagination:
    #' This method does **not** auto-paginate. To walk every activity that
    #' matches your filters, pass the last row's `id` back in as
    #' `page_token`; stop when a returned page is shorter than `page_size`
    #' (i.e. you've reached the tail). A worked example:
    #'
    #' ```r
    #' library(data.table)
    #' acct <- AlpacaAccount$new()
    #'
    #' pages <- list()
    #' token <- NULL
    #' repeat {
    #'   dt <- acct$get_activities(
    #'     activity_types = "FILL",
    #'     direction = "desc",
    #'     page_size = 100L,        # the hard server-side cap
    #'     page_token = token
    #'   )
    #'   if (nrow(dt) == 0L) break
    #'   pages[[length(pages) + 1L]] <- dt
    #'   if (nrow(dt) < 100L) break # short page == last page
    #'   token <- tail(dt$id, 1L)
    #' }
    #' all_fills <- rbindlist(pages, use.names = TRUE, fill = TRUE)
    #' ```
    #'
    #' Automated pagination (drop `page_size`, add `n` / `max_total`) is
    #' planned for a follow-up release; this method's public API will
    #' remain backward-compatible.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' activities <- acct$get_activities(activity_types = "FILL")
    #' print(activities)
    #' }
    get_activities = function(
      activity_types = NULL,
      date = NULL,
      until = NULL,
      after = NULL,
      direction = NULL,
      page_size = NULL,
      page_token = NULL,
      category = NULL
    ) {
      if (!is.null(activity_types) && !is.null(category)) {
        rlang::abort("`activity_types` and `category` are mutually exclusive.")
      }
      if (!is.null(category)) {
        rlang::arg_match0(category, c("trade_activity", "non_trade_activity"))
      }
      if (!is.null(direction)) {
        rlang::arg_match0(direction, c("asc", "desc"))
      }
      if (!is.null(page_size) && page_size > 100L) {
        rlang::abort(paste0(
          "`page_size` must be <= 100 (Alpaca's documented cap for ",
          "/v2/account/activities). Got: ", page_size,
          ". See `?AlpacaAccount$get_activities` -> Pagination for how to ",
          "walk multiple pages via `page_token`."
        ))
      }
      return(private$.request(
        endpoint = "/v2/account/activities",
        query = list(
          activity_types = activity_types,
          date = date,
          until = until,
          after = after,
          direction = direction,
          page_size = page_size,
          page_token = page_token,
          category = category
        ),
        .parser = function(items) {
          dt <- as_dt_list(items)
          parse_timestamp_cols(dt, "transaction_time")
          return(dt)
        }
      ))
    },

    #' @description
    #' Get Account Activities by Type
    #'
    #' Retrieves account activities filtered to a specific type.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/account/activities/{activity_type}`
    #'
    #' ### Official Documentation
    #' [Get Account Activities by Type](https://docs.alpaca.markets/us/reference/getaccountactivitiesbyactivitytype-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/account/activities/FILL?direction=desc&page_size=5'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "20260310140000000::a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    #'     "activity_type": "FILL",
    #'     "symbol": "TSLA",
    #'     "side": "buy",
    #'     "qty": "5",
    #'     "price": "178.50",
    #'     "cum_qty": "5",
    #'     "leaves_qty": "0",
    #'     "type": "fill",
    #'     "transaction_time": "2026-03-10T14:00:00.000Z",
    #'     "order_id": "c4d5e6f7-a8b9-0c1d-2e3f-4a5b6c7d8e9f",
    #'     "order_status": "filled"
    #'   }
    #' ]
    #' ```
    #'
    #' @param activity_type Character; activity type (e.g., `"FILL"`, `"DIV"`,
    #'   `"TRANS"`, `"JNLC"`, `"JNLS"`, `"CSD"`, `"CSW"`).
    #' @param date Character or NULL; filter to a specific date.
    #' @param until Character or NULL; only activities before this timestamp.
    #' @param after Character or NULL; only activities after this timestamp.
    #' @param direction Character or NULL; `"asc"` or `"desc"`.
    #' @param page_size Integer or NULL; max results per page. Alpaca caps
    #'   this at **100** for `/v2/account/activities/{type}`; values above
    #'   100 return HTTP 422 server-side. This method validates the cap
    #'   up-front and `abort()`s with a clear message rather than letting
    #'   the vendor error leak through. Default `NULL` lets Alpaca pick its
    #'   server-side default (currently 100).
    #' @param page_token Character or NULL; cursor for the next page —
    #'   the **`id` of the last row from the previous page**. See the
    #'   "Pagination" section on `get_activities()` for a worked example;
    #'   the recipe is identical for this method.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   activity details. Always includes `id` (the per-activity cursor).
    #'
    #' @section Pagination:
    #' Same id-cursor recipe as `get_activities()` — pass the last row's
    #' `id` back in as `page_token`, stop when a returned page is shorter
    #' than `page_size`. See `?AlpacaAccount$get_activities` -> Pagination
    #' for the full example. Automated pagination is planned for a
    #' follow-up release.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' fills <- acct$get_activities_by_type("FILL")
    #' print(fills)
    #' }
    get_activities_by_type = function(
      activity_type,
      date = NULL,
      until = NULL,
      after = NULL,
      direction = NULL,
      page_size = NULL,
      page_token = NULL
    ) {
      if (!is.null(page_size) && page_size > 100L) {
        rlang::abort(paste0(
          "`page_size` must be <= 100 (Alpaca's documented cap for ",
          "/v2/account/activities/{type}). Got: ", page_size,
          ". See `?AlpacaAccount$get_activities` -> Pagination for how to ",
          "walk multiple pages via `page_token`."
        ))
      }
      endpoint <- paste0("/v2/account/activities/", activity_type)
      return(private$.request(
        endpoint = endpoint,
        query = list(
          date = date,
          until = until,
          after = after,
          direction = direction,
          page_size = page_size,
          page_token = page_token
        ),
        .parser = function(items) {
          dt <- as_dt_list(items)
          parse_timestamp_cols(dt, "transaction_time")
          return(dt)
        }
      ))
    },

    # ---- Watchlists ----

    #' @description
    #' Get All Watchlists
    #'
    #' Retrieves all watchlists for the account.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/watchlists`
    #'
    #' ### Official Documentation
    #' [Watchlists](https://docs.alpaca.markets/us/reference/getwatchlists-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/watchlists'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
    #'     "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'     "name": "Tech Stocks",
    #'     "created_at": "2026-01-15T10:30:00Z",
    #'     "updated_at": "2026-03-10T08:00:00Z"
    #'   },
    #'   {
    #'     "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    #'     "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'     "name": "Energy Sector",
    #'     "created_at": "2026-02-20T14:00:00Z",
    #'     "updated_at": "2026-03-09T16:45:00Z"
    #'   }
    #' ]
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Watchlist UUID.
    #'   - `account_id` (character): Account UUID.
    #'   - `name` (character): Watchlist name.
    #'   - `created_at` (POSIXct, UTC): Creation timestamp.
    #'   - `updated_at` (POSIXct, UTC): Last update timestamp.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' watchlists <- acct$get_watchlists()
    #' print(watchlists)
    #' }
    get_watchlists = function() {
      return(private$.request(
        endpoint = "/v2/watchlists",
        .parser = function(items) {
          dt <- as_dt_list(items)
          parse_timestamp_cols(dt, c("created_at", "updated_at"))
          return(dt)
        }
      ))
    },

    #' @description
    #' Get a Watchlist by ID
    #'
    #' Retrieves a single watchlist including its asset entries.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`
    #'
    #' ### Official Documentation
    #' [Get Watchlist by ID](https://docs.alpaca.markets/us/reference/getwatchlistbyid-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
    #'   "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'   "name": "Tech Stocks",
    #'   "created_at": "2026-01-15T10:30:00Z",
    #'   "updated_at": "2026-03-10T08:00:00Z",
    #'   "assets": [
    #'     {
    #'       "id": "904837e3-3b76-47ec-b432-046db621571b",
    #'       "symbol": "AAPL",
    #'       "name": "Apple Inc.",
    #'       "exchange": "NASDAQ",
    #'       "asset_class": "us_equity",
    #'       "tradable": true
    #'     },
    #'     {
    #'       "id": "b2e3f4a5-c6d7-8901-2345-6789abcdef01",
    #'       "symbol": "MSFT",
    #'       "name": "Microsoft Corporation",
    #'       "exchange": "NASDAQ",
    #'       "asset_class": "us_equity",
    #'       "tradable": true
    #'     }
    #'   ]
    #' }
    #' ```
    #'
    #' @param watchlist_id Character; watchlist UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) in long
    #'   format with one row per asset in the watchlist. Columns include watchlist
    #'   metadata (`id`, `account_id`, `name`, `created_at`, `updated_at`) and
    #'   asset columns prefixed with `asset_` (`asset_id`, `asset_symbol`,
    #'   `asset_name`, `asset_attributes`, etc.). `asset_attributes` is a
    #'   `;`-separated character column (e.g.
    #'   `"fractional_eh_enabled;has_options"`) — `NA` when the asset has
    #'   no attributes. Recover the original vector with
    #'   `strsplit(dt$asset_attributes, ";", fixed = TRUE)[[1]]`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' wl <- acct$get_watchlist("some-uuid")
    #' print(wl)
    #' }
    get_watchlist = function(watchlist_id) {
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      return(private$.request(
        endpoint = endpoint,
        .parser = parse_watchlist
      ))
    },

    #' @description
    #' Create a Watchlist
    #'
    #' Creates a new watchlist with an optional initial set of symbols.
    #'
    #' ### API Endpoint
    #' `POST https://paper-api.alpaca.markets/v2/watchlists`
    #'
    #' ### Official Documentation
    #' [Create Watchlist](https://docs.alpaca.markets/us/reference/postwatchlist-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   -H "Content-Type: application/json" \
    #'   -d '{"name": "My Tech Stocks", "symbols": ["AAPL", "MSFT", "GOOGL"]}' \
    #'   'https://paper-api.alpaca.markets/v2/watchlists'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "name": "My Tech Stocks",
    #'   "symbols": ["AAPL", "MSFT", "GOOGL"]
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "d7e8f9a0-b1c2-3456-7890-abcdef123456",
    #'   "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'   "name": "My Tech Stocks",
    #'   "created_at": "2026-03-10T15:00:00Z",
    #'   "updated_at": "2026-03-10T15:00:00Z",
    #'   "assets": [
    #'     {"id": "904837e3-3b76-47ec-b432-046db621571b", "symbol": "AAPL", "name": "Apple Inc."},
    #'     {"id": "b2e3f4a5-c6d7-8901-2345-6789abcdef01", "symbol": "MSFT", "name": "Microsoft Corporation"},
    #'     {"id": "c3d4e5f6-a7b8-9012-3456-789abcdef012", "symbol": "GOOGL", "name": "Alphabet Inc."}
    #'   ]
    #' }
    #' ```
    #'
    #' @param name Character; watchlist name.
    #' @param symbols Character vector or NULL; initial symbols (e.g.,
    #'   `c("AAPL", "MSFT")`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same long-format shape as `get_watchlist()`: one row per
    #'   asset, with watchlist metadata (`id`, `account_id`, `name`,
    #'   `created_at`, `updated_at`) replicated and asset columns prefixed
    #'   `asset_` (`asset_id`, `asset_symbol`, `asset_name`,
    #'   `asset_attributes`, ...). A watchlist created with no symbols
    #'   returns one row with asset columns set to `NA`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' wl <- acct$add_watchlist("My Tech Stocks", symbols = c("AAPL", "MSFT", "GOOGL"))
    #' print(wl)
    #' }
    add_watchlist = function(name, symbols = NULL) {
      return(private$.request(
        endpoint = "/v2/watchlists",
        method = "POST",
        body = list(name = name, symbols = symbols),
        .parser = parse_watchlist
      ))
    },

    #' @description
    #' Update a Watchlist
    #'
    #' Replaces the name and/or symbols of an existing watchlist.
    #'
    #' ### API Endpoint
    #' `PUT https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`
    #'
    #' ### Official Documentation
    #' [Update Watchlist](https://docs.alpaca.markets/us/reference/updatewatchlistbyid-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X PUT -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   -H "Content-Type: application/json" \
    #'   -d '{"name": "Updated Name", "symbols": ["AAPL", "TSLA"]}' \
    #'   'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "name": "Updated Name",
    #'   "symbols": ["AAPL", "TSLA"]
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
    #'   "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'   "name": "Updated Name",
    #'   "created_at": "2026-01-15T10:30:00Z",
    #'   "updated_at": "2026-03-10T16:00:00Z",
    #'   "assets": [
    #'     {"id": "904837e3-3b76-47ec-b432-046db621571b", "symbol": "AAPL", "name": "Apple Inc."},
    #'     {"id": "e5f6a7b8-c9d0-1234-5678-9abcdef01234", "symbol": "TSLA", "name": "Tesla, Inc."}
    #'   ]
    #' }
    #' ```
    #'
    #' @param watchlist_id Character; watchlist UUID.
    #' @param name Character; new watchlist name.
    #' @param symbols Character vector; new full list of symbols (replaces existing).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same long-format shape as `get_watchlist()`: one row per
    #'   asset (after the modification), watchlist metadata replicated
    #'   on each row, asset columns prefixed `asset_`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$modify_watchlist("some-uuid", name = "Updated Name",
    #'                       symbols = c("AAPL", "TSLA"))
    #' }
    modify_watchlist = function(watchlist_id, name, symbols) {
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      return(private$.request(
        endpoint = endpoint,
        method = "PUT",
        body = list(name = name, symbols = symbols),
        .parser = parse_watchlist
      ))
    },

    #' @description
    #' Add Symbol to Watchlist
    #'
    #' Appends a single symbol to an existing watchlist.
    #'
    #' ### API Endpoint
    #' `POST https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`
    #'
    #' ### Official Documentation
    #' [Add Symbol to Watchlist](https://docs.alpaca.markets/us/reference/addassettowatchlist-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X POST -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   -H "Content-Type: application/json" \
    #'   -d '{"symbol": "NVDA"}' \
    #'   'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'
    #' ```
    #'
    #' ### JSON Request
    #' ```json
    #' {
    #'   "symbol": "NVDA"
    #' }
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
    #'   "account_id": "e6fe16f3-64a4-4921-8928-cadf02f92f98",
    #'   "name": "Tech Stocks",
    #'   "created_at": "2026-01-15T10:30:00Z",
    #'   "updated_at": "2026-03-10T16:30:00Z",
    #'   "assets": [
    #'     {"id": "904837e3-3b76-47ec-b432-046db621571b", "symbol": "AAPL", "name": "Apple Inc."},
    #'     {"id": "b2e3f4a5-c6d7-8901-2345-6789abcdef01", "symbol": "MSFT", "name": "Microsoft Corporation"},
    #'     {"id": "f6a7b8c9-d0e1-2345-6789-abcdef012345", "symbol": "NVDA", "name": "NVIDIA Corporation"}
    #'   ]
    #' }
    #' ```
    #'
    #' @param watchlist_id Character; watchlist UUID.
    #' @param symbol Character; ticker symbol to add (e.g., `"AAPL"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same long-format shape as `get_watchlist()`: one row per
    #'   asset in the updated watchlist.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$add_watchlist_symbol("some-uuid", "NVDA")
    #' }
    add_watchlist_symbol = function(watchlist_id, symbol) {
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      return(private$.request(
        endpoint = endpoint,
        method = "POST",
        body = list(symbol = symbol),
        .parser = parse_watchlist
      ))
    },

    #' @description
    #' Remove Symbol from Watchlist
    #'
    #' Removes a single symbol from a watchlist.
    #'
    #' ### API Endpoint
    #' `DELETE https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}/{symbol}`
    #'
    #' ### Official Documentation
    #' [Remove Symbol from Watchlist](https://docs.alpaca.markets/us/reference/removeassetfromwatchlist-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234/AAPL'
    #' ```
    #'
    #' ### JSON Response
    #' The API returns `204 No Content` on success. This method returns a
    #' confirmation `data.table`:
    #' ```json
    #' {
    #'   "watchlist_id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
    #'   "symbol": "AAPL",
    #'   "status": "removed"
    #' }
    #' ```
    #'
    #' @param watchlist_id Character; watchlist UUID.
    #' @param symbol Character; ticker symbol to remove.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`).
    #'   When the API returns the updated watchlist, a single row with watchlist details.
    #'   On 204 No Content, a single confirmation row with columns:
    #'   - `watchlist_id` (character): The watchlist UUID.
    #'   - `symbol` (character): The removed ticker symbol.
    #'   - `status` (character): `"removed"`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$cancel_watchlist_symbol("some-uuid", "AAPL")
    #' }
    cancel_watchlist_symbol = function(watchlist_id, symbol) {
      endpoint <- paste0("/v2/watchlists/", watchlist_id, "/", symbol)
      return(private$.request(
        endpoint = endpoint,
        method = "DELETE",
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table(
              watchlist_id = watchlist_id,
              symbol = symbol,
              status = "removed"
            )[])
          }
          return(parse_watchlist(data))
        }
      ))
    },

    #' @description
    #' Delete a Watchlist
    #'
    #' Permanently deletes a watchlist.
    #'
    #' ### API Endpoint
    #' `DELETE https://paper-api.alpaca.markets/v2/watchlists/{watchlist_id}`
    #'
    #' ### Official Documentation
    #' [Delete Watchlist](https://docs.alpaca.markets/us/reference/deletewatchlistbyid-1)
    #' Verified: 2026-05-21
    #'
    #' ### curl
    #' ```
    #' curl -X DELETE -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/watchlists/f5a6b7c8-d9e0-1234-5678-9abcdef01234'
    #' ```
    #'
    #' ### JSON Response
    #' The API returns `204 No Content` on success. This method returns a
    #' confirmation `data.table`:
    #' ```json
    #' {
    #'   "watchlist_id": "f5a6b7c8-d9e0-1234-5678-9abcdef01234",
    #'   "status": "deleted"
    #' }
    #' ```
    #'
    #' @param watchlist_id Character; watchlist UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`), single row with columns:
    #'   - `watchlist_id` (character): The deleted watchlist UUID.
    #'   - `status` (character): `"deleted"`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$cancel_watchlist("some-uuid")
    #' }
    cancel_watchlist = function(watchlist_id) {
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      return(private$.request(
        endpoint = endpoint,
        method = "DELETE",
        .parser = function(data) {
          return(data.table::data.table(
            watchlist_id = watchlist_id,
            status = "deleted"
          )[])
        }
      ))
    }
  )
)
