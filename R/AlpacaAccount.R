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
    #' @return (Account | promise<Account>) the account details. Columns
    #'   include `id`, `account_number`, `status`, `currency`, `cash`,
    #'   `portfolio_value`, `equity`, `buying_power`, `initial_margin`,
    #'   `maintenance_margin`, `long_market_value`, `short_market_value`,
    #'   `daytrading_buying_power` (all character); `pattern_day_trader` and
    #'   `trading_blocked` (logical); `daytrade_count` (integer); and
    #'   `created_at` (POSIXct, UTC).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' info <- acct$get_account()
    #' cat("Equity:", info$equity, "\n")
    #' cat("Buying power:", info$buying_power, "\n")
    #' }
    get_account = function() {
      result <- private$.request(
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_account,
        is_async = private$.is_async
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
    #'   "pdt_check": "entry"
    #' }
    #' ```
    #'
    #' @return (AccountConfig | promise<AccountConfig>) the configuration. Columns
    #'   include `dtbp_check`, `trade_confirm_email`, `max_margin_multiplier`,
    #'   `pdt_check` (character); and `no_shorting`, `suspend_trade`,
    #'   `fractional_trading` (logical).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' config <- acct$get_account_config()
    #' print(config)
    #' }
    get_account_config = function() {
      result <- private$.request(
        endpoint = "/v2/account/configurations",
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_account_config,
        is_async = private$.is_async
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
    #'   "pdt_check": "entry"
    #' }
    #' ```
    #'
    #' @param dtbp_check (scalar<character> | NULL) DTBP check method: `"both"`,
    #'   `"entry"`, `"exit"`.
    #' @param no_shorting (scalar<logical> | NULL) if `TRUE`, disables short
    #'   selling.
    #' @param suspend_trade (scalar<logical> | NULL) if `TRUE`, suspends all
    #'   trading.
    #' @param trade_confirm_email (scalar<character> | NULL) `"all"`, `"none"`.
    #' @param fractional_trading (scalar<logical> | NULL) enable/disable
    #'   fractional trading.
    #' @param max_margin_multiplier (scalar<character> | NULL) `"1"`, `"2"`, or
    #'   `"4"`.
    #' @param pdt_check (scalar<character> | NULL) `"both"`, `"entry"`, `"exit"`.
    #' @param max_options_trading_level (scalar<count in [0, Inf[> | NULL) options
    #'   trading level (0=disabled, 1=Covered Call/Cash-Secured Put, 2=Long
    #'   Call/Put, 3=Spreads/Straddles).
    #' @param ptp_no_exception_entry (scalar<logical> | NULL) if `TRUE`, accept
    #'   orders for PTP symbols with no exception.
    #' @param disable_overnight_trading (scalar<logical> | NULL) if `TRUE`,
    #'   disable overnight trading on the account.
    #' @return (AccountConfig | promise<AccountConfig>) the updated configuration.
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
      assert_args_AlpacaAccount__modify_account_config(
        dtbp_check,
        no_shorting,
        suspend_trade,
        trade_confirm_email,
        fractional_trading,
        max_margin_multiplier,
        pdt_check,
        max_options_trading_level,
        ptp_no_exception_entry,
        disable_overnight_trading
      )
      result <- private$.request(
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__modify_account_config,
        is_async = private$.is_async
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
    #' @return (Position | promise<Position>) the open positions. Columns
    #'   include `asset_id`, `symbol`, `exchange`, `asset_class`,
    #'   `avg_entry_price`, `qty`, `side`, `market_value`, `cost_basis`,
    #'   `unrealized_pl`, `unrealized_plpc`, `current_price`, `lastday_price`
    #'   and `change_today` (all character).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' positions <- acct$get_positions()
    #' print(positions[, .(symbol, qty, unrealized_pl)])
    #' }
    get_positions = function() {
      result <- private$.request(
        endpoint = "/v2/positions",
        .parser = function(items) {
          if (is.null(items) || length(items) == 0) {
            return(empty_dt_positions())
          }
          return(as_dt_list(items))
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_positions,
        is_async = private$.is_async
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
    #' @param symbol_or_id (scalar<character>) ticker symbol (e.g., `"AAPL"`) or
    #'   asset UUID.
    #' @return (Position | promise<Position>) the position, with the same
    #'   columns as `get_positions()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' pos <- acct$get_position("AAPL")
    #' print(pos[, .(symbol, qty, avg_entry_price, current_price, unrealized_pl)])
    #' }
    get_position = function(symbol_or_id) {
      assert_args_AlpacaAccount__get_position(symbol_or_id)
      assert::assert_nonempty_strings(symbol_or_id)
      endpoint <- paste0("/v2/positions/", symbol_or_id)
      result <- private$.request(
        endpoint = endpoint,
        .parser = as_dt_row
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_position,
        is_async = private$.is_async
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
    #' @param symbol_or_id (scalar<character>) ticker symbol or asset UUID.
    #' @param qty (scalar<numeric> | NULL) number of shares to close. Mutually
    #'   exclusive with `percentage`.
    #' @param percentage (scalar<numeric> | NULL) percentage of position to close
    #'   (0-100). Mutually exclusive with `qty`.
    #' @return (OrderCore | promise<OrderCore>) the closing order as a single row
    #'   (the core order columns; the venue returns the richer single-order
    #'   fields as un-asserted extras). Unlike the list/single-order endpoints
    #'   this path bypasses `parse_order()`, so it carries no `leg_index` /
    #'   `parent_order_id` columns.
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
      assert_args_AlpacaAccount__close_position(symbol_or_id, qty, percentage)
      assert::assert_nonempty_strings(symbol_or_id)
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
      result <- private$.request(
        endpoint = endpoint,
        method = "DELETE",
        query = list(qty = qty, percentage = percentage),
        .parser = function(data) {
          dt <- as_dt_row(data)
          parse_timestamp_cols(dt, ORDER_TIMESTAMP_COLS)
          return(dt)
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__close_position,
        is_async = private$.is_async
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
    #' @param cancel_orders (scalar<logical>) if `TRUE`, cancels all open orders
    #'   before liquidating positions. Default `FALSE`.
    #' @return (data.table | promise<data.table>) the closed positions. When
    #'   positions are closed, one row per position with full order details.
    #'   When no open positions exist, a single confirmation row with
    #'   `cancel_orders` (logical, whether orders were also cancelled) and
    #'   `status` (character, `"closed"`).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$close_all_positions(cancel_orders = TRUE)
    #' }
    close_all_positions = function(cancel_orders = FALSE) {
      assert_args_AlpacaAccount__close_all_positions(cancel_orders)
      result <- private$.request(
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__close_all_positions,
        is_async = private$.is_async
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
    #' @param symbol_or_id (scalar<character>) OCC option symbol or asset UUID.
    #' @return (ExerciseAck | promise<ExerciseAck>) a single-row confirmation
    #'   with `symbol` (the exercised option symbol or asset UUID) and `status`
    #'   (always `"exercised"`).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$exercise_option("AAPL240621C00200000")
    #' }
    exercise_option = function(symbol_or_id) {
      assert_args_AlpacaAccount__exercise_option(symbol_or_id)
      assert::assert_nonempty_strings(symbol_or_id)
      endpoint <- paste0("/v2/positions/", symbol_or_id, "/exercise")
      result <- private$.request(
        endpoint = endpoint,
        method = "POST",
        .parser = function(data) {
          return(data.table::data.table(
            symbol = symbol_or_id,
            status = "exercised"
          )[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__exercise_option,
        is_async = private$.is_async
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
    #' @param period (scalar<character> | NULL) time period for the history.
    #'   Examples: `"1D"`, `"1W"`, `"1M"`, `"3M"`, `"1A"`, `"all"`. Mutually
    #'   exclusive with providing both `start` and `end`.
    #' @param timeframe (scalar<character> | NULL) resolution of the time series:
    #'   `"1Min"`, `"5Min"`, `"15Min"`, `"1H"`, `"1D"`.
    #' @param start (scalar<character> | NULL) start timestamp in RFC3339 format.
    #'   Defaults to `end` minus `period`.
    #' @param end (scalar<character> | NULL) end timestamp in RFC3339 format.
    #' @param intraday_reporting (scalar<character> | NULL) `"market_hours"`
    #'   (default), `"extended_hours"`, or `"continuous"` (for 24/7 crypto
    #'   charts).
    #' @param pnl_reset (scalar<character> | NULL) `"per_day"` (default) or
    #'   `"no_reset"`. Set to `"no_reset"` for continuous crypto PnL.
    #' @param date_start (scalar<character> | NULL) deprecated alias for `start`.
    #'   Earlier releases used this name but it was silently ignored by the API.
    #'   Now forwarded to `start` with a deprecation warning. Will be removed in
    #'   a future release.
    #' @param date_end (scalar<character> | NULL) deprecated alias for `end`.
    #'   Same notes as `date_start`.
    #' @return (PortfolioHistory | promise<PortfolioHistory>) the portfolio
    #'   history. Columns: `timestamp` (POSIXct, UTC), `equity` (numeric),
    #'   `profit_loss` (numeric) and `profit_loss_pct` (numeric).
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
      assert_args_AlpacaAccount__get_portfolio_history(
        period,
        timeframe,
        start,
        end,
        intraday_reporting,
        pnl_reset,
        date_start,
        date_end
      )
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
      result <- private$.request(
        endpoint = "/v2/account/portfolio/history",
        query = list(
          period = period,
          timeframe = timeframe,
          start = start,
          end = end,
          intraday_reporting = intraday_reporting,
          pnl_reset = pnl_reset
        ),
        .parser = function(data) {
          if (is.null(data) || is.null(data$timestamp) || length(data$timestamp) == 0) {
            return(empty_dt_portfolio_history())
          }
          # The response carries parallel arrays (timestamp, equity, ...).
          # Parsed with simplifyVector = FALSE each is a list whose JSON
          # `null` elements are NULL; `nums()` coerces to a numeric vector
          # mapping NULL -> NA so the columns stay aligned.
          nums <- function(x) {
            return(vapply(x, function(v) if (is.null(v)) NA_real_ else as.numeric(v), numeric(1L)))
          }
          dt <- data.table::data.table(
            timestamp = lubridate::as_datetime(as.integer(nums(data$timestamp)), tz = "UTC"),
            equity = nums(data$equity),
            profit_loss = nums(data$profit_loss),
            profit_loss_pct = nums(data$profit_loss_pct)
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_portfolio_history,
        is_async = private$.is_async
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
    #' @param activity_types (scalar<character> | NULL) comma-separated activity
    #'   types to filter (e.g., `"FILL"`, `"DIV"`, `"TRANS"`). See Alpaca docs
    #'   for full list. Mutually exclusive with `category`.
    #' @param category (scalar<character> | NULL) broad category filter:
    #'   `"trade_activity"` or `"non_trade_activity"`. Mutually exclusive with
    #'   `activity_types`.
    #' @param date (scalar<character> | NULL) filter to a specific date
    #'   (`"YYYY-MM-DD"`).
    #' @param until (scalar<character> | NULL) only activities before this
    #'   timestamp.
    #' @param after (scalar<character> | NULL) only activities after this
    #'   timestamp.
    #' @param direction (scalar<character> | NULL) `"asc"` or `"desc"`.
    #' @param page_size (scalar<count in [1, 101[> | NULL) max results per page.
    #'   Alpaca caps this at **100** for `/v2/account/activities`; values above
    #'   100 return HTTP 422 server-side. This method validates the cap up-front
    #'   and `abort()`s with a clear message rather than letting the vendor
    #'   error leak through. Must be a single non-NA integerish value when
    #'   provided. Default `NULL` lets Alpaca pick its server-side default
    #'   (currently 100).
    #' @param page_token (scalar<character> | NULL) cursor for the next page. For
    #'   activities this is the **`id` of the last row from the previous page**
    #'   (Alpaca's activity IDs are sortable cursors, not opaque tokens). See the
    #'   "Pagination" section below.
    #' @noassert page_size
    #' @return (Activity | promise<Activity>) the activities. Columns beyond the
    #'   guaranteed `Activity` set vary by activity type. `id` is the per-activity
    #'   cursor used for paging (see "Pagination"). An empty response returns a
    #'   zero-row table carrying the `Activity` columns.
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
      assert_args_AlpacaAccount__get_activities(
        activity_types,
        category,
        date,
        until,
        after,
        direction,
        page_token
      )
      if (!is.null(activity_types) && !is.null(category)) {
        rlang::abort("`activity_types` and `category` are mutually exclusive.")
      }
      if (!is.null(category)) {
        rlang::arg_match0(category, c("trade_activity", "non_trade_activity"))
      }
      if (!is.null(direction)) {
        rlang::arg_match0(direction, c("asc", "desc"))
      }
      if (!is.null(page_size)) {
        if (!is.numeric(page_size) || length(page_size) != 1L || is.na(page_size)) {
          rlang::abort(
            "`page_size` must be a single non-NA integerish value, or NULL."
          )
        }
        if (page_size > 100L) {
          rlang::abort(paste0(
            "`page_size` must be <= 100 (Alpaca's documented cap for ",
            "/v2/account/activities). Got: ",
            page_size,
            ". See `?AlpacaAccount` -> Pagination for how to walk multiple ",
            "pages via `page_token`."
          ))
        }
      }
      result <- private$.request(
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
          if (is.null(items) || length(items) == 0) {
            return(empty_dt_activities())
          }
          dt <- as_dt_list(items)
          parse_timestamp_cols(dt, "transaction_time")
          return(dt)
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_activities,
        is_async = private$.is_async
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
    #' @param activity_type (scalar<character>) activity type (e.g., `"FILL"`,
    #'   `"DIV"`, `"TRANS"`, `"JNLC"`, `"JNLS"`, `"CSD"`, `"CSW"`).
    #' @param date (scalar<character> | NULL) filter to a specific date.
    #' @param until (scalar<character> | NULL) only activities before this
    #'   timestamp.
    #' @param after (scalar<character> | NULL) only activities after this
    #'   timestamp.
    #' @param direction (scalar<character> | NULL) `"asc"` or `"desc"`.
    #' @param page_size (scalar<count in [1, 101[> | NULL) max results per page.
    #'   Alpaca caps this at **100** for `/v2/account/activities/{type}`; values
    #'   above 100 return HTTP 422 server-side. This method validates the cap
    #'   up-front and `abort()`s with a clear message rather than letting the
    #'   vendor error leak through. Must be a single non-NA integerish value when
    #'   provided. Default `NULL` lets Alpaca pick its server-side default
    #'   (currently 100). For multi-page walks see the "Pagination" section on
    #'   `get_activities()` — the id-cursor recipe is identical for this method.
    #' @param page_token (scalar<character> | NULL) cursor for the next page —
    #'   the **`id` of the last row from the previous page**. See the
    #'   "Pagination" section on `get_activities()` for a worked example; the
    #'   recipe is identical for this method.
    #' @noassert page_size
    #' @return (Activity | promise<Activity>) the activities. `id` is the
    #'   per-activity cursor used for paging. An empty response returns a
    #'   zero-row table carrying the `Activity` columns.
    #'
    #' @seealso [AlpacaAccount$get_activities()] — the sibling method
    #'   includes the worked id-cursor pagination loop in its
    #'   `@section Pagination`. This method follows the same contract.
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
      assert_args_AlpacaAccount__get_activities_by_type(
        activity_type,
        date,
        until,
        after,
        direction,
        page_token
      )
      assert::assert_nonempty_strings(activity_type)
      if (!is.null(page_size)) {
        if (!is.numeric(page_size) || length(page_size) != 1L || is.na(page_size)) {
          rlang::abort(
            "`page_size` must be a single non-NA integerish value, or NULL."
          )
        }
        if (page_size > 100L) {
          rlang::abort(paste0(
            "`page_size` must be <= 100 (Alpaca's documented cap for ",
            "/v2/account/activities/{type}). Got: ",
            page_size,
            ". See `?AlpacaAccount` -> Pagination for how to walk multiple ",
            "pages via `page_token`."
          ))
        }
      }
      endpoint <- paste0("/v2/account/activities/", activity_type)
      result <- private$.request(
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
          if (is.null(items) || length(items) == 0) {
            return(empty_dt_activities())
          }
          dt <- as_dt_list(items)
          parse_timestamp_cols(dt, "transaction_time")
          return(dt)
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_activities_by_type,
        is_async = private$.is_async
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
    #' @return (Watchlists | promise<Watchlists>) the watchlists. Columns: `id`,
    #'   `account_id`, `name` (character); `created_at` and `updated_at`
    #'   (POSIXct, UTC).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' watchlists <- acct$get_watchlists()
    #' print(watchlists)
    #' }
    get_watchlists = function() {
      result <- private$.request(
        endpoint = "/v2/watchlists",
        .parser = function(items) {
          if (is.null(items) || length(items) == 0) {
            return(empty_dt_watchlists())
          }
          dt <- as_dt_list(items)
          parse_timestamp_cols(dt, c("created_at", "updated_at"))
          return(dt)
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_watchlists,
        is_async = private$.is_async
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
    #' @param watchlist_id (scalar<character>) watchlist UUID.
    #' @return (Watchlist | promise<Watchlist>) a long-format table with one
    #'   row per asset in the watchlist. Columns include watchlist metadata
    #'   (`id`, `account_id`, `name`, `created_at`, `updated_at`) and asset
    #'   columns prefixed with `asset_` (`asset_id`, `asset_symbol`,
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
      assert_args_AlpacaAccount__get_watchlist(watchlist_id)
      assert::assert_nonempty_strings(watchlist_id)
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      result <- private$.request(
        endpoint = endpoint,
        .parser = parse_watchlist
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__get_watchlist,
        is_async = private$.is_async
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
    #' @param name (scalar<character>) watchlist name.
    #' @param symbols (character | NULL) initial symbols (e.g.,
    #'   `c("AAPL", "MSFT")`).
    #' @return (Watchlist | promise<Watchlist>) the same long-format shape as
    #'   `get_watchlist()`: one row per asset, with watchlist metadata (`id`,
    #'   `account_id`, `name`, `created_at`, `updated_at`) replicated and asset
    #'   columns prefixed `asset_` (`asset_id`, `asset_symbol`, `asset_name`,
    #'   `asset_attributes`, ...). A watchlist created with no symbols returns
    #'   one row with asset columns set to `NA`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' wl <- acct$add_watchlist("My Tech Stocks", symbols = c("AAPL", "MSFT", "GOOGL"))
    #' print(wl)
    #' }
    add_watchlist = function(name, symbols = NULL) {
      assert_args_AlpacaAccount__add_watchlist(name, symbols)
      assert::assert_nonempty_strings(name)
      result <- private$.request(
        endpoint = "/v2/watchlists",
        method = "POST",
        body = list(name = name, symbols = symbols),
        .parser = parse_watchlist
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__add_watchlist,
        is_async = private$.is_async
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
    #' @param watchlist_id (scalar<character>) watchlist UUID.
    #' @param name (scalar<character>) new watchlist name.
    #' @param symbols (character) new full list of symbols (replaces existing).
    #' @return (Watchlist | promise<Watchlist>) the same long-format shape as
    #'   `get_watchlist()`: one row per asset (after the modification),
    #'   watchlist metadata replicated on each row, asset columns prefixed
    #'   `asset_`.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$modify_watchlist("some-uuid", name = "Updated Name",
    #'                       symbols = c("AAPL", "TSLA"))
    #' }
    modify_watchlist = function(watchlist_id, name, symbols) {
      assert_args_AlpacaAccount__modify_watchlist(watchlist_id, name, symbols)
      assert::assert_nonempty_strings(watchlist_id)
      assert::assert_nonempty_strings(name)
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      result <- private$.request(
        endpoint = endpoint,
        method = "PUT",
        body = list(name = name, symbols = symbols),
        .parser = parse_watchlist
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__modify_watchlist,
        is_async = private$.is_async
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
    #' @param watchlist_id (scalar<character>) watchlist UUID.
    #' @param symbol (scalar<character>) ticker symbol to add (e.g., `"AAPL"`).
    #' @return (Watchlist | promise<Watchlist>) the same long-format shape as
    #'   `get_watchlist()`: one row per asset in the updated watchlist.
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$add_watchlist_symbol("some-uuid", "NVDA")
    #' }
    add_watchlist_symbol = function(watchlist_id, symbol) {
      assert_args_AlpacaAccount__add_watchlist_symbol(watchlist_id, symbol)
      assert::assert_nonempty_strings(watchlist_id)
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      result <- private$.request(
        endpoint = endpoint,
        method = "POST",
        body = list(symbol = symbol),
        .parser = parse_watchlist
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__add_watchlist_symbol,
        is_async = private$.is_async
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
    #' @param watchlist_id (scalar<character>) watchlist UUID.
    #' @param symbol (scalar<character>) ticker symbol to remove.
    #' @return (data.table | promise<data.table>) the result. When the API
    #'   returns the updated watchlist, a single row with watchlist details. On
    #'   204 No Content, a single confirmation row with `watchlist_id`
    #'   (character, the watchlist UUID), `symbol` (character, the removed ticker
    #'   symbol) and `status` (character, `"removed"`).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$cancel_watchlist_symbol("some-uuid", "AAPL")
    #' }
    cancel_watchlist_symbol = function(watchlist_id, symbol) {
      assert_args_AlpacaAccount__cancel_watchlist_symbol(watchlist_id, symbol)
      assert::assert_nonempty_strings(watchlist_id)
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/watchlists/", watchlist_id, "/", symbol)
      result <- private$.request(
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__cancel_watchlist_symbol,
        is_async = private$.is_async
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
    #' @param watchlist_id (scalar<character>) watchlist UUID.
    #' @return (CancelWatchlistAck | promise<CancelWatchlistAck>) a single-row
    #'   confirmation with `watchlist_id` (the deleted watchlist UUID) and
    #'   `status` (always `"deleted"`).
    #'
    #' @examples
    #' \dontrun{
    #' acct <- AlpacaAccount$new()
    #' acct$cancel_watchlist("some-uuid")
    #' }
    cancel_watchlist = function(watchlist_id) {
      assert_args_AlpacaAccount__cancel_watchlist(watchlist_id)
      assert::assert_nonempty_strings(watchlist_id)
      endpoint <- paste0("/v2/watchlists/", watchlist_id)
      result <- private$.request(
        endpoint = endpoint,
        method = "DELETE",
        .parser = function(data) {
          return(data.table::data.table(
            watchlist_id = watchlist_id,
            status = "deleted"
          )[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaAccount__cancel_watchlist,
        is_async = private$.is_async
      ))
    }
  )
)
