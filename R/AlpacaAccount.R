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
#' - [Account](https://docs.alpaca.markets/reference/getaccount-1)
#' - [Positions](https://docs.alpaca.markets/reference/getallopenpositions-1)
#' - [Portfolio History](https://docs.alpaca.markets/reference/getportfoliohistory)
#' - [Account Activities](https://docs.alpaca.markets/reference/getaccountactivities)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | HTTP |
#' |--------|----------|------|
#' | get_account | GET /v2/account | GET |
#' | get_positions | GET /v2/positions | GET |
#' | get_position | GET /v2/positions/{symbol_or_id} | GET |
#' | close_position | DELETE /v2/positions/{symbol_or_id} | DELETE |
#' | close_all_positions | DELETE /v2/positions | DELETE |
#' | get_account_config | GET /v2/account/configurations | GET |
#' | modify_account_config | PATCH /v2/account/configurations | PATCH |
#' | exercise_option | POST /v2/positions/{symbol_or_id}/exercise | POST |
#' | get_portfolio_history | GET /v2/account/portfolio/history | GET |
#' | get_activities | GET /v2/account/activities | GET |
#' | get_activities_by_type | GET /v2/account/activities/{type} | GET |
#' | get_watchlists | GET /v2/watchlists | GET |
#' | get_watchlist | GET /v2/watchlists/{id} | GET |
#' | add_watchlist | POST /v2/watchlists | POST |
#' | modify_watchlist | PUT /v2/watchlists/{id} | PUT |
#' | add_watchlist_symbol | POST /v2/watchlists/{id} | POST |
#' | cancel_watchlist_symbol | DELETE /v2/watchlists/{id}/{symbol} | DELETE |
#' | cancel_watchlist | DELETE /v2/watchlists/{id} | DELETE |
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
    #' [Get Account](https://docs.alpaca.markets/reference/getaccount-1)
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
    #'   - `created_at` (character): Account creation timestamp.
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
        .parser = as_dt_row
      ))
    },

    #' @description
    #' Get Account Configurations
    #'
    #' Retrieves the current account configuration settings including DTBP
    #' check behavior, trade confirmation emails, and shorting restrictions.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/account/configurations`
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
    #' @param dtbp_check Character or NULL; DTBP check method: `"both"`, `"entry"`, `"exit"`.
    #' @param no_shorting Logical or NULL; if `TRUE`, disables short selling.
    #' @param suspend_trade Logical or NULL; if `TRUE`, suspends all trading.
    #' @param trade_confirm_email Character or NULL; `"all"`, `"none"`.
    #' @param fractional_trading Logical or NULL; enable/disable fractional trading.
    #' @param max_margin_multiplier Character or NULL; `"1"` (no margin) or `"2"` (Reg-T).
    #' @param pdt_check Character or NULL; `"both"`, `"entry"`, `"exit"`.
    #' @param max_options_trading_level Integer or NULL; options trading level (0-2).
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
      max_options_trading_level = NULL
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
          max_options_trading_level = max_options_trading_level
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
    #' [Get All Open Positions](https://docs.alpaca.markets/reference/getallopenpositions-1)
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
    #' [Get Open Position](https://docs.alpaca.markets/reference/getopenposition-1)
    #'
    #' @param symbol_or_id Character; ticker symbol (e.g., `"AAPL"`) or asset UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with the
    #'   same columns as [get_positions()], single row.
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
    #' [Close Position](https://docs.alpaca.markets/reference/deleteposition)
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
        .parser = as_dt_row
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
    #' [Close All Positions](https://docs.alpaca.markets/reference/deleteallopenpositions)
    #'
    #' @param cancel_orders Logical; if `TRUE`, cancels all open orders before
    #'   liquidating positions. Default `FALSE`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   closing order details for each position.
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
            return(data.table::data.table())
          }
          as_dt_list(data)
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
    #' @param symbol_or_id Character; OCC option symbol or asset UUID.
    #' @return `invisible(NULL)` on success (HTTP 204).
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
        .parser = function(data) return(invisible(NULL))
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
    #' [Portfolio History](https://docs.alpaca.markets/reference/getportfoliohistory)
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
    #'   `"1D"`, `"1W"`, `"1M"`, `"3M"`, `"1A"`, `"all"`. Cannot be used with
    #'   `date_start`/`date_end`.
    #' @param timeframe Character or NULL; resolution of the time series:
    #'   `"1Min"`, `"5Min"`, `"15Min"`, `"1H"`, `"1D"`.
    #' @param date_start Character or NULL; start date (`"YYYY-MM-DD"`). Use with
    #'   `date_end` instead of `period`.
    #' @param date_end Character or NULL; end date (`"YYYY-MM-DD"`).
    #' @param intraday_reporting Character or NULL; `"market_hours"` (default) or
    #'   `"extended_hours"`.
    #' @param pnl_reset Character or NULL; `"per_day"` (default) or `"no_reset"`.
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
      date_start = NULL,
      date_end = NULL,
      intraday_reporting = NULL,
      pnl_reset = NULL
    ) {
      return(private$.request(
        endpoint = "/v2/account/portfolio/history",
        query = list(
          period = period,
          timeframe = timeframe,
          date_start = date_start,
          date_end = date_end,
          intraday_reporting = intraday_reporting,
          pnl_reset = pnl_reset
        ),
        simplifyVector = TRUE,
        .parser = function(data) {
          if (is.null(data) || is.null(data$timestamp) || length(data$timestamp) == 0) {
            return(data.table::data.table())
          }
          dt <- data.table::data.table(
            timestamp = lubridate::as_datetime(as.integer(data$timestamp), tz = "UTC"),
            equity = as.numeric(data$equity),
            profit_loss = as.numeric(data$profit_loss),
            profit_loss_pct = as.numeric(data$profit_loss_pct)
          )
          return(dt)
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
    #' [Account Activities](https://docs.alpaca.markets/reference/getaccountactivities)
    #'
    #' @param activity_types Character or NULL; comma-separated activity types to
    #'   filter (e.g., `"FILL"`, `"DIV"`, `"TRANS"`). See Alpaca docs for full list.
    #' @param date Character or NULL; filter to a specific date (`"YYYY-MM-DD"`).
    #' @param until Character or NULL; only activities before this timestamp.
    #' @param after Character or NULL; only activities after this timestamp.
    #' @param direction Character or NULL; `"asc"` or `"desc"`.
    #' @param page_size Integer or NULL; max results per page (default 100, max 100).
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   activity details. Columns vary by activity type.
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
      page_token = NULL
    ) {
      return(private$.request(
        endpoint = "/v2/account/activities",
        query = list(
          activity_types = activity_types,
          date = date,
          until = until,
          after = after,
          direction = direction,
          page_size = page_size,
          page_token = page_token
        ),
        .parser = as_dt_list
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
    #' @param activity_type Character; activity type (e.g., `"FILL"`, `"DIV"`,
    #'   `"TRANS"`, `"JNLC"`, `"JNLS"`, `"CSD"`, `"CSW"`).
    #' @param date Character or NULL; filter to a specific date.
    #' @param until Character or NULL; only activities before this timestamp.
    #' @param after Character or NULL; only activities after this timestamp.
    #' @param direction Character or NULL; `"asc"` or `"desc"`.
    #' @param page_size Integer or NULL; max results per page.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   activity details.
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
        .parser = as_dt_list
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
    #' [Watchlists](https://docs.alpaca.markets/reference/getwatchlists)
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Watchlist UUID.
    #'   - `account_id` (character): Account UUID.
    #'   - `name` (character): Watchlist name.
    #'   - `created_at` (character): Creation timestamp.
    #'   - `updated_at` (character): Last update timestamp.
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
        .parser = as_dt_list
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
    #' @param watchlist_id Character; watchlist UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   watchlist metadata and an `assets` list column containing the symbols.
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
        .parser = as_dt_row
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
    #' [Create Watchlist](https://docs.alpaca.markets/reference/postwatchlist)
    #'
    #' @param name Character; watchlist name.
    #' @param symbols Character vector or NULL; initial symbols (e.g.,
    #'   `c("AAPL", "MSFT")`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with the
    #'   created watchlist details.
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
        .parser = as_dt_row
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
    #' @param watchlist_id Character; watchlist UUID.
    #' @param name Character; new watchlist name.
    #' @param symbols Character vector; new full list of symbols (replaces existing).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with updated
    #'   watchlist details.
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
        .parser = as_dt_row
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
    #' @param watchlist_id Character; watchlist UUID.
    #' @param symbol Character; ticker symbol to add (e.g., `"AAPL"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the updated watchlist.
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
        .parser = as_dt_row
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
    #' @param watchlist_id Character; watchlist UUID.
    #' @param symbol Character; ticker symbol to remove.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the updated watchlist, or empty data.table on 204.
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
            return(data.table::data.table())
          }
          as_dt_row(data)
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
    #' @param watchlist_id Character; watchlist UUID.
    #' @return `invisible(NULL)` on success (HTTP 204).
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
        .parser = function(data) return(invisible(NULL))
      ))
    }
  )
)
