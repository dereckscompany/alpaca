# File: R/AlpacaOptions.R
# R6 class for Alpaca options data and trading.

#' AlpacaOptions: Options Contracts and Data
#'
#' Provides methods for querying options contracts, retrieving options
#' market data (bars, trades, quotes, snapshots), and placing options orders
#' on Alpaca's API.
#'
#' Inherits from [AlpacaBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Contracts**: Search and filter available options contracts.
#' - **Market Data**: Retrieve historical and latest options market data.
#' - **Snapshots**: Get real-time snapshots of options contracts.
#' - **Options Chain**: Retrieve the full options chain for an underlying.
#'
#' ### Base URLs
#' Options market data endpoints use `https://data.alpaca.markets`.
#' Contract metadata endpoints use the trading base URL.
#'
#' ### Official Documentation
#' - [Options Contracts](https://docs.alpaca.markets/reference/optioncontracts)
#' - [Options Market Data](https://docs.alpaca.markets/docs/options-market-data)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Base |
#' |--------|----------|------|
#' | get_contracts | `GET /v2/options/contracts` | trading |
#' | get_contract | `GET /v2/options/contracts/\{symbol_or_id\}` | trading |
#' | get_option_bars | `GET /v1beta1/options/bars` | data |
#' | get_option_trades | `GET /v1beta1/options/trades` | data |
#' | get_option_latest_quotes | `GET /v1beta1/options/quotes/latest` | data |
#' | get_option_snapshots | `GET /v1beta1/options/snapshots` | data |
#' | get_option_snapshot | `GET /v1beta1/options/snapshots/\{symbol\}` | data |
#' | get_option_latest_trades | `GET /v1beta1/options/trades/latest` | data |
#' | get_option_chain | `GET /v1beta1/options/snapshots/\{underlying_symbol\}` | data |
#'
#' @examples
#' \dontrun{
#' opts <- AlpacaOptions$new()
#'
#' # Search for AAPL call options
#' contracts <- opts$get_contracts(
#'   underlying_symbols = "AAPL",
#'   type = "call",
#'   expiration_date_gte = "2024-06-01",
#'   limit = 10
#' )
#' print(contracts[, .(symbol, type, strike_price, expiration_date)])
#' }
#'
#' @importFrom R6 R6Class
#' @export
AlpacaOptions <- R6::R6Class(
  "AlpacaOptions",
  inherit = AlpacaBase,
  public = list(
    #' @description
    #' Initialise an AlpacaOptions Object
    #'
    #' Creates a new AlpacaOptions instance for querying options contracts,
    #' market data, and options chain information.
    #'
    #' ### API Endpoint
    #' Constructor only — no HTTP request is made.
    #'
    #' ### Official Documentation
    #' - [Options Trading Overview](https://docs.alpaca.markets/docs/options-trading)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' # No HTTP request — this is a constructor. Verify credentials with:
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/options/contracts?limit=1'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' # N/A — constructor does not make an HTTP request.
    #' ```
    #'
    #' @param keys List; API credentials from [get_api_keys()].
    #' @param base_url Character; trading API base URL. Defaults to `get_base_url()`.
    #' @param data_base_url Character; market data API base URL. Defaults to
    #'   `get_data_base_url()`.
    #' @param async Logical; if `TRUE`, methods return promises. Default `FALSE`.
    #' @return Invisible self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      data_base_url = get_data_base_url(),
      async = FALSE
    ) {
      super$initialize(keys = keys, base_url = base_url, async = async)
      private$.data_base_url <- data_base_url
      return(invisible(self))
    },

    # ---- Contracts ----

    #' @description
    #' Get Options Contracts
    #'
    #' Searches for available options contracts with filtering by underlying
    #' symbol, type, expiration date, strike price, and more.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/options/contracts`
    #'
    #' ### Official Documentation
    #' - [Get Options Contracts](https://docs.alpaca.markets/reference/optioncontracts)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/options/contracts?underlying_symbols=AAPL&type=call&limit=5'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "option_contracts": [
    #'     {
    #'       "id": "uuid",
    #'       "symbol": "AAPL240621C00200000",
    #'       "name": "AAPL Jun 21 2024 200.00 Call",
    #'       "status": "active",
    #'       "tradable": true,
    #'       "type": "call",
    #'       "strike_price": "200.00",
    #'       "expiration_date": "2024-06-21",
    #'       "underlying_symbol": "AAPL",
    #'       "underlying_asset_id": "uuid",
    #'       "style": "american",
    #'       "root_symbol": "AAPL",
    #'       "size": "100",
    #'       "open_interest": "1234",
    #'       "close_price": "5.50"
    #'     }
    #'   ],
    #'   "next_page_token": null
    #' }
    #' ```
    #'
    #' @param underlying_symbols Character or NULL; comma-separated underlying
    #'   symbols to filter (e.g., `"AAPL"` or `"AAPL,MSFT"`).
    #' @param status Character or NULL; contract status (`"active"`, `"inactive"`).
    #' @param type Character or NULL; option type (`"call"`, `"put"`).
    #' @param expiration_date Character or NULL; exact expiration date (`"YYYY-MM-DD"`).
    #' @param expiration_date_gte Character or NULL; expiration on or after this date.
    #' @param expiration_date_lte Character or NULL; expiration on or before this date.
    #' @param strike_price_gte Numeric or NULL; minimum strike price.
    #' @param strike_price_lte Numeric or NULL; maximum strike price.
    #' @param root_symbol Character or NULL; options root symbol.
    #' @param style Character or NULL; option style (`"american"`, `"european"`).
    #' @param limit Integer or NULL; max contracts to return (default 100, max 10000).
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Contract UUID.
    #'   - `symbol` (character): OCC option symbol.
    #'   - `name` (character): Human-readable contract name.
    #'   - `status` (character): Contract status.
    #'   - `tradable` (logical): Whether the contract is tradable.
    #'   - `type` (character): `"call"` or `"put"`.
    #'   - `strike_price` (character): Strike price.
    #'   - `expiration_date` (character): Expiration date.
    #'   - `underlying_symbol` (character): Underlying ticker symbol.
    #'   - `style` (character): Option style.
    #'   - `root_symbol` (character): Root symbol.
    #'   - `size` (character): Contract size (typically `"100"`).
    #'   - `open_interest` (character): Open interest.
    #'   - `close_price` (character): Last close price.
    #'
    #' @examples
    #' \dontrun{
    #' opts <- AlpacaOptions$new()
    #'
    #' # Find AAPL calls expiring after June 2024
    #' contracts <- opts$get_contracts(
    #'   underlying_symbols = "AAPL",
    #'   type = "call",
    #'   expiration_date_gte = "2024-06-01",
    #'   limit = 10
    #' )
    #' print(contracts)
    #' }
    get_contracts = function(
      underlying_symbols = NULL,
      status = NULL,
      type = NULL,
      expiration_date = NULL,
      expiration_date_gte = NULL,
      expiration_date_lte = NULL,
      strike_price_gte = NULL,
      strike_price_lte = NULL,
      root_symbol = NULL,
      style = NULL,
      limit = NULL,
      page_token = NULL
    ) {
      if (!is.null(strike_price_gte)) {
        strike_price_gte <- as.character(strike_price_gte)
      }
      if (!is.null(strike_price_lte)) {
        strike_price_lte <- as.character(strike_price_lte)
      }

      return(private$.request(
        endpoint = "/v2/options/contracts",
        query = list(
          underlying_symbols = underlying_symbols,
          status = status,
          type = type,
          expiration_date = expiration_date,
          expiration_date_gte = expiration_date_gte,
          expiration_date_lte = expiration_date_lte,
          strike_price_gte = strike_price_gte,
          strike_price_lte = strike_price_lte,
          root_symbol = root_symbol,
          style = style,
          limit = limit,
          page_token = page_token
        ),
        .parser = function(data) {
          as_dt_list(data$option_contracts)
        }
      ))
    },

    #' @description
    #' Get Option Contract by Symbol or ID
    #'
    #' Retrieves a single options contract by its OCC symbol or UUID.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/options/contracts/{symbol_or_id}`
    #'
    #' ### Official Documentation
    #' - [Get Option Contract by ID or Symbol](https://docs.alpaca.markets/reference/getoptioncontract)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/options/contracts/AAPL250620C00200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    #'   "symbol": "AAPL250620C00200000",
    #'   "name": "AAPL Jun 20 2025 200.00 Call",
    #'   "status": "active",
    #'   "tradable": true,
    #'   "type": "call",
    #'   "strike_price": "200",
    #'   "expiration_date": "2025-06-20",
    #'   "underlying_symbol": "AAPL",
    #'   "underlying_asset_id": "b28f4066-5c6d-479b-a2af-85dc1a8f02fd",
    #'   "style": "american",
    #'   "root_symbol": "AAPL",
    #'   "size": "100",
    #'   "open_interest": "8523",
    #'   "open_interest_date": "2025-03-07",
    #'   "close_price": "12.35",
    #'   "close_price_date": "2025-03-07"
    #' }
    #' ```
    #'
    #' @param symbol_or_id Character; OCC option symbol or contract UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same columns as `get_contracts()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' opts <- AlpacaOptions$new()
    #' contract <- opts$get_contract("AAPL240621C00200000")
    #' print(contract)
    #' }
    get_contract = function(symbol_or_id) {
      endpoint <- paste0("/v2/options/contracts/", symbol_or_id)
      return(private$.request(
        endpoint = endpoint,
        .parser = as_dt_row
      ))
    },

    # ---- Options Market Data ----

    #' @description
    #' Get Options Bars (OHLCV)
    #'
    #' Retrieves historical bar data for options contracts.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/bars`
    #'
    #' ### Official Documentation
    #' - [Options Bars](https://docs.alpaca.markets/reference/optionbars)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/bars?symbols=AAPL250620C00200000&timeframe=1Day&start=2025-03-01&limit=5'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "bars": {
    #'     "AAPL250620C00200000": [
    #'       {
    #'         "t": "2025-03-03T05:00:00Z",
    #'         "o": 11.80,
    #'         "h": 13.25,
    #'         "l": 11.50,
    #'         "c": 12.90,
    #'         "v": 4523,
    #'         "n": 312,
    #'         "vw": 12.45
    #'       },
    #'       {
    #'         "t": "2025-03-04T05:00:00Z",
    #'         "o": 12.90,
    #'         "h": 14.10,
    #'         "l": 12.60,
    #'         "c": 13.75,
    #'         "v": 5891,
    #'         "n": 428,
    #'         "vw": 13.30
    #'       }
    #'     ]
    #'   },
    #'   "next_page_token": null
    #' }
    #' ```
    #'
    #' @param symbols Character; comma-separated OCC option symbols.
    #' @param timeframe Character; bar timeframe (e.g., `"1Day"`, `"1Hour"`).
    #' @param start Character or NULL; start date/time (RFC-3339 or `"YYYY-MM-DD"`).
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max bars (1-10000, default 1000).
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column and the same bar columns as stock bars.
    #'
    #' @examples
    #' \dontrun{
    #' opts <- AlpacaOptions$new()
    #' bars <- opts$get_option_bars(
    #'   "AAPL240621C00200000", timeframe = "1Day",
    #'   start = "2024-06-01"
    #' )
    #' print(bars)
    #' }
    get_option_bars = function(
      symbols,
      timeframe = "1Day",
      start = NULL,
      end = NULL,
      limit = NULL,
      page_token = NULL
    ) {
      return(private$.data_request(
        endpoint = "/v1beta1/options/bars",
        query = list(
          symbols = symbols,
          timeframe = timeframe,
          start = start,
          end = end,
          limit = limit,
          page_token = page_token
        ),
        .parser = parse_multi_bars
      ))
    },

    #' @description
    #' Get Options Trades
    #'
    #' Retrieves historical trade data for options contracts.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/trades`
    #'
    #' ### Official Documentation
    #' - [Options Trades](https://docs.alpaca.markets/reference/optiontrades)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/trades?symbols=AAPL250620C00200000&start=2025-03-01&limit=5'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "trades": {
    #'     "AAPL250620C00200000": [
    #'       {
    #'         "t": "2025-03-03T14:30:02.123456Z",
    #'         "p": 12.35,
    #'         "s": 10,
    #'         "x": "C",
    #'         "c": ["a", "I"]
    #'       },
    #'       {
    #'         "t": "2025-03-03T14:31:15.654321Z",
    #'         "p": 12.40,
    #'         "s": 5,
    #'         "x": "P",
    #'         "c": ["a"]
    #'       }
    #'     ]
    #'   },
    #'   "next_page_token": null
    #' }
    #' ```
    #'
    #' @param symbols Character; comma-separated OCC option symbols.
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max trades (1-10000, default 1000).
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   trade columns.
    get_option_trades = function(
      symbols,
      start = NULL,
      end = NULL,
      limit = NULL,
      page_token = NULL
    ) {
      return(private$.data_request(
        endpoint = "/v1beta1/options/trades",
        query = list(
          symbols = symbols,
          start = start,
          end = end,
          limit = limit,
          page_token = page_token
        ),
        .parser = function(data) {
          trades_map <- data$trades
          if (is.null(trades_map) || length(trades_map) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(trades_map), function(sym) {
            dt <- parse_trades(trades_map[[sym]])
            if (nrow(dt) > 0) {
              dt[, symbol := sym]
              data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
            }
            return(dt[])
          })
          return(data.table::rbindlist(dts, fill = TRUE)[])
        }
      ))
    },

    #' @description
    #' Get Latest Options Quotes
    #'
    #' Retrieves the latest NBBO quotes for one or more options contracts.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/quotes/latest`
    #'
    #' ### Official Documentation
    #' - [Latest Options Quotes](https://docs.alpaca.markets/reference/optionlatestquotes)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/quotes/latest?symbols=AAPL250620C00200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "quotes": {
    #'     "AAPL250620C00200000": {
    #'       "t": "2025-03-07T20:59:58.123456Z",
    #'       "ax": "C",
    #'       "ap": 12.50,
    #'       "as": 15,
    #'       "bx": "P",
    #'       "bp": 12.30,
    #'       "bs": 22,
    #'       "c": "A"
    #'     }
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character; comma-separated OCC option symbols.
    #' @param feed Character or NULL; data feed.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   quote columns plus a `symbol` column.
    get_option_latest_quotes = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v1beta1/options/quotes/latest",
        query = list(symbols = symbols, feed = feed),
        .parser = function(data) {
          quotes_map <- data$quotes
          if (is.null(quotes_map) || length(quotes_map) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(quotes_map), function(sym) {
            dt <- parse_quotes(list(quotes_map[[sym]]))
            if (nrow(dt) > 0) {
              dt[, symbol := sym]
            }
            return(dt[])
          })
          dt <- data.table::rbindlist(dts, fill = TRUE)
          if ("symbol" %in% names(dt)) {
            data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Latest Options Trades
    #'
    #' Retrieves the latest trades for one or more options contracts.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/trades/latest`
    #'
    #' ### Official Documentation
    #' - [Latest Options Trades](https://docs.alpaca.markets/reference/optionlatesttrades)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/trades/latest?symbols=AAPL250620C00200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "trades": {
    #'     "AAPL250620C00200000": {
    #'       "t": "2025-03-07T20:58:45.987654Z",
    #'       "p": 12.35,
    #'       "s": 3,
    #'       "x": "C",
    #'       "c": ["a"]
    #'     }
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character; comma-separated OCC option symbols.
    #' @param feed Character or NULL; data feed.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   trade columns plus a `symbol` column.
    get_option_latest_trades = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v1beta1/options/trades/latest",
        query = list(symbols = symbols, feed = feed),
        .parser = function(data) {
          trades_map <- data$trades
          if (is.null(trades_map) || length(trades_map) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(trades_map), function(sym) {
            dt <- parse_trades(list(trades_map[[sym]]))
            if (nrow(dt) > 0) {
              dt[, symbol := sym]
            }
            return(dt[])
          })
          dt <- data.table::rbindlist(dts, fill = TRUE)
          if ("symbol" %in% names(dt)) {
            data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Options Snapshots
    #'
    #' Retrieves real-time snapshots for multiple options contracts, including
    #' the latest trade, latest quote, and implied volatility.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/snapshots`
    #'
    #' ### Official Documentation
    #' - [Options Snapshots](https://docs.alpaca.markets/reference/optionsnapshots)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/snapshots?symbols=AAPL250620C00200000,AAPL250620P00200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "snapshots": {
    #'     "AAPL250620C00200000": {
    #'       "latestTrade": {
    #'         "t": "2025-03-07T20:58:45.987654Z",
    #'         "p": 12.35,
    #'         "s": 3,
    #'         "x": "C",
    #'         "c": ["a"]
    #'       },
    #'       "latestQuote": {
    #'         "t": "2025-03-07T20:59:58.123456Z",
    #'         "ax": "C",
    #'         "ap": 12.50,
    #'         "as": 15,
    #'         "bx": "P",
    #'         "bp": 12.30,
    #'         "bs": 22,
    #'         "c": "A"
    #'       },
    #'       "impliedVolatility": 0.2856,
    #'       "greeks": {
    #'         "delta": 0.5423,
    #'         "gamma": 0.0187,
    #'         "theta": -0.0842,
    #'         "vega": 0.3215,
    #'         "rho": 0.1456
    #'       }
    #'     },
    #'     "AAPL250620P00200000": {
    #'       "latestTrade": {
    #'         "t": "2025-03-07T20:57:30.456789Z",
    #'         "p": 8.75,
    #'         "s": 5,
    #'         "x": "P",
    #'         "c": ["a"]
    #'       },
    #'       "latestQuote": {
    #'         "t": "2025-03-07T20:59:55.789012Z",
    #'         "ax": "P",
    #'         "ap": 8.90,
    #'         "as": 10,
    #'         "bx": "C",
    #'         "bp": 8.60,
    #'         "bs": 18,
    #'         "c": "A"
    #'       },
    #'       "impliedVolatility": 0.2712,
    #'       "greeks": {
    #'         "delta": -0.4577,
    #'         "gamma": 0.0187,
    #'         "theta": -0.0756,
    #'         "vega": 0.3215,
    #'         "rho": -0.1289
    #'       }
    #'     }
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character; comma-separated OCC option symbols.
    #' @param feed Character or NULL; data feed.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   flattened snapshot fields plus a `symbol` column.
    get_option_snapshots = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v1beta1/options/snapshots",
        query = list(symbols = symbols, feed = feed),
        .parser = function(data) {
          snaps <- data$snapshots
          if (is.null(snaps) || length(snaps) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(snaps), function(sym) {
            dt <- parse_snapshot(snaps[[sym]])
            if (nrow(dt) > 0) {
              dt[, symbol := sym]
            }
            return(dt[])
          })
          dt <- data.table::rbindlist(dts, fill = TRUE)
          if ("symbol" %in% names(dt)) {
            data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
          }
          return(dt[])
        }
      ))
    },

    #' @description
    #' Get Option Snapshot by Symbol
    #'
    #' Retrieves a real-time snapshot for a single options contract.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/snapshots/{symbol}`
    #'
    #' ### Official Documentation
    #' - [Option Snapshot](https://docs.alpaca.markets/reference/optionsnapshot)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/snapshots/AAPL250620C00200000'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "latestTrade": {
    #'     "t": "2025-03-07T20:58:45.987654Z",
    #'     "p": 12.35,
    #'     "s": 3,
    #'     "x": "C",
    #'     "c": ["a"]
    #'   },
    #'   "latestQuote": {
    #'     "t": "2025-03-07T20:59:58.123456Z",
    #'     "ax": "C",
    #'     "ap": 12.50,
    #'     "as": 15,
    #'     "bx": "P",
    #'     "bp": 12.30,
    #'     "bs": 22,
    #'     "c": "A"
    #'   },
    #'   "impliedVolatility": 0.2856,
    #'   "greeks": {
    #'     "delta": 0.5423,
    #'     "gamma": 0.0187,
    #'     "theta": -0.0842,
    #'     "vega": 0.3215,
    #'     "rho": 0.1456
    #'   }
    #' }
    #' ```
    #'
    #' @param symbol Character; OCC option symbol.
    #' @param feed Character or NULL; data feed.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   flattened snapshot fields.
    #'
    #' @examples
    #' \dontrun{
    #' opts <- AlpacaOptions$new()
    #' snap <- opts$get_option_snapshot("AAPL240621C00200000")
    #' print(snap)
    #' }
    get_option_snapshot = function(symbol, feed = NULL) {
      endpoint <- paste0("/v1beta1/options/snapshots/", symbol)
      return(private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed),
        .parser = parse_snapshot
      ))
    },

    #' @description
    #' Get Options Chain
    #'
    #' Retrieves the full options chain for an underlying symbol. Returns all
    #' available contracts with their latest market data.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/options/snapshots/{underlying_symbol}`
    #'
    #' ### Official Documentation
    #' - [Options Chain / Snapshots by Underlying](https://docs.alpaca.markets/reference/optionchain)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/options/snapshots/AAPL?type=call&expiration_date_gte=2025-06-01&strike_price_gte=190&strike_price_lte=210&limit=5'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "snapshots": {
    #'     "AAPL250620C00195000": {
    #'       "latestTrade": {
    #'         "t": "2025-03-07T20:55:12.345678Z",
    #'         "p": 15.20,
    #'         "s": 2,
    #'         "x": "C",
    #'         "c": ["a"]
    #'       },
    #'       "latestQuote": {
    #'         "t": "2025-03-07T20:59:50.123456Z",
    #'         "ax": "P",
    #'         "ap": 15.40,
    #'         "as": 12,
    #'         "bx": "C",
    #'         "bp": 15.00,
    #'         "bs": 20,
    #'         "c": "A"
    #'       },
    #'       "impliedVolatility": 0.2734,
    #'       "greeks": {
    #'         "delta": 0.6012,
    #'         "gamma": 0.0165,
    #'         "theta": -0.0912,
    #'         "vega": 0.3089,
    #'         "rho": 0.1623
    #'       }
    #'     },
    #'     "AAPL250620C00200000": {
    #'       "latestTrade": {
    #'         "t": "2025-03-07T20:58:45.987654Z",
    #'         "p": 12.35,
    #'         "s": 3,
    #'         "x": "C",
    #'         "c": ["a"]
    #'       },
    #'       "latestQuote": {
    #'         "t": "2025-03-07T20:59:58.123456Z",
    #'         "ax": "C",
    #'         "ap": 12.50,
    #'         "as": 15,
    #'         "bx": "P",
    #'         "bp": 12.30,
    #'         "bs": 22,
    #'         "c": "A"
    #'       },
    #'       "impliedVolatility": 0.2856,
    #'       "greeks": {
    #'         "delta": 0.5423,
    #'         "gamma": 0.0187,
    #'         "theta": -0.0842,
    #'         "vega": 0.3215,
    #'         "rho": 0.1456
    #'       }
    #'     }
    #'   },
    #'   "next_page_token": null
    #' }
    #' ```
    #'
    #' @param underlying_symbol Character; the underlying ticker symbol (e.g., `"AAPL"`).
    #' @param type Character or NULL; `"call"`, `"put"`.
    #' @param expiration_date Character or NULL; exact expiration date (`"YYYY-MM-DD"`).
    #' @param expiration_date_gte Character or NULL; expiration on or after this date.
    #' @param expiration_date_lte Character or NULL; expiration on or before this date.
    #' @param strike_price_gte Numeric or NULL; minimum strike price.
    #' @param strike_price_lte Numeric or NULL; maximum strike price.
    #' @param root_symbol Character or NULL; options root symbol.
    #' @param feed Character or NULL; data feed.
    #' @param limit Integer or NULL; max results. Default 100.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   flattened snapshot fields plus a `symbol` column.
    #'
    #' @examples
    #' \dontrun{
    #' opts <- AlpacaOptions$new()
    #' chain <- opts$get_option_chain("AAPL", type = "call",
    #'                                 expiration_date_gte = "2024-06-01")
    #' print(chain)
    #' }
    get_option_chain = function(
      underlying_symbol,
      type = NULL,
      expiration_date = NULL,
      expiration_date_gte = NULL,
      expiration_date_lte = NULL,
      strike_price_gte = NULL,
      strike_price_lte = NULL,
      root_symbol = NULL,
      feed = NULL,
      limit = NULL,
      page_token = NULL
    ) {
      if (!is.null(strike_price_gte)) {
        strike_price_gte <- as.character(strike_price_gte)
      }
      if (!is.null(strike_price_lte)) {
        strike_price_lte <- as.character(strike_price_lte)
      }

      return(private$.data_request(
        endpoint = paste0("/v1beta1/options/snapshots/", underlying_symbol),
        query = list(
          type = type,
          expiration_date = expiration_date,
          expiration_date_gte = expiration_date_gte,
          expiration_date_lte = expiration_date_lte,
          strike_price_gte = strike_price_gte,
          strike_price_lte = strike_price_lte,
          root_symbol = root_symbol,
          feed = feed,
          limit = limit,
          page_token = page_token
        ),
        .parser = function(data) {
          snaps <- data$snapshots
          if (is.null(snaps) || length(snaps) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(snaps), function(sym) {
            dt <- parse_snapshot(snaps[[sym]])
            if (nrow(dt) > 0) {
              dt[, symbol := sym]
            }
            return(dt[])
          })
          dt <- data.table::rbindlist(dts, fill = TRUE)
          if ("symbol" %in% names(dt)) {
            data.table::setcolorder(dt, c("symbol", setdiff(names(dt), "symbol")))
          }
          return(dt[])
        }
      ))
    }
  ),
  private = list(
    .data_base_url = NULL,

    # Execute a market data API request (uses data base URL)
    .data_request = function(
      endpoint,
      query = list(),
      .parser = identity,
      timeout = 30
    ) {
      return(alpaca_build_request(
        base_url = private$.data_base_url,
        endpoint = endpoint,
        method = "GET",
        query = query,
        keys = private$.keys,
        .perform = private$.perform,
        .parser = .parser,
        is_async = private$.is_async,
        timeout = timeout
      ))
    }
  )
)
