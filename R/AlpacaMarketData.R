# File: R/AlpacaMarketData.R
# R6 class for Alpaca market data retrieval.

#' AlpacaMarketData: Market Data, Assets, Calendar, and Clock
#'
#' Provides methods for retrieving market data from Alpaca's REST API,
#' including historical bars (OHLCV), latest quotes/trades, snapshots,
#' asset info, market calendar, and clock.
#'
#' Inherits from [AlpacaBase]. All methods support both synchronous and
#' asynchronous execution depending on the `async` parameter at construction.
#'
#' ### Purpose and Scope
#' - **Bars**: Retrieve historical OHLCV candlestick data for stocks.
#' - **Trades**: Access historical and latest trade data.
#' - **Quotes**: Access historical and latest quote (NBBO) data.
#' - **Snapshots**: Get real-time snapshot of a symbol's latest state.
#' - **Assets**: Query available tradeable assets and their metadata.
#' - **Calendar**: Get market open/close schedule.
#' - **Clock**: Check current market status (open/closed).
#' - **Corporate Actions**: Query dividends, splits, mergers, spinoffs.
#' - **News**: Retrieve market news articles filtered by symbol/date.
#' - **Screener**: Most active stocks, top market movers.
#'
#' ### Base URLs
#' Market data endpoints use `https://data.alpaca.markets` by default.
#' Trading-related endpoints (assets, calendar, clock) use the trading
#' base URL. Both are configurable via constructor parameters.
#'
#' ### Official Documentation
#' - [Market Data API](https://docs.alpaca.markets/docs/about-market-data-api)
#' - [Historical Stock Data](https://docs.alpaca.markets/docs/historical-stock-data-1)
#'
#' ### Endpoints Covered
#' | Method | Endpoint | Base |
#' |--------|----------|------|
#' | get_bars | `GET /v2/stocks/\{symbol\}/bars` | data |
#' | get_bars_multi | `GET /v2/stocks/bars` | data |
#' | get_latest_bar | `GET /v2/stocks/\{symbol\}/bars/latest` | data |
#' | get_latest_trade | `GET /v2/stocks/\{symbol\}/trades/latest` | data |
#' | get_latest_quote | `GET /v2/stocks/\{symbol\}/quotes/latest` | data |
#' | get_snapshot | `GET /v2/stocks/\{symbol\}/snapshot` | data |
#' | get_trades | `GET /v2/stocks/\{symbol\}/trades` | data |
#' | get_quotes | `GET /v2/stocks/\{symbol\}/quotes` | data |
#' | get_assets | `GET /v2/assets` | trading |
#' | get_asset | `GET /v2/assets/\{symbol\}` | trading |
#' | get_calendar | `GET /v2/calendar` | trading |
#' | get_clock | `GET /v2/clock` | trading |
#' | get_corporate_actions | `GET /v2/corporate_actions/announcements` | trading |
#' | get_news | `GET /v1beta1/news` | data |
#' | get_latest_bars_multi | `GET /v2/stocks/bars/latest` | data |
#' | get_latest_trades_multi | `GET /v2/stocks/trades/latest` | data |
#' | get_latest_quotes_multi | `GET /v2/stocks/quotes/latest` | data |
#' | get_snapshots_multi | `GET /v2/stocks/snapshots` | data |
#' | get_most_actives | `GET /v1beta1/screener/stocks/most-actives` | data |
#' | get_movers | `GET /v1beta1/screener/\{market_type\}/movers` | data |
#'
#' @examples
#' \dontrun{
#' # Synchronous usage
#' market <- AlpacaMarketData$new()
#' bars <- market$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01")
#' print(bars)
#'
#' # Asynchronous usage
#' market_async <- AlpacaMarketData$new(async = TRUE)
#' main <- coro::async(function() {
#'   bars <- await(market_async$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01"))
#'   print(bars)
#' })
#' main()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom lubridate as_datetime
#' @export
AlpacaMarketData <- R6::R6Class(
  "AlpacaMarketData",
  inherit = AlpacaBase,
  public = list(
    #' @description
    #' Initialise an AlpacaMarketData Object
    #'
    #' Creates a new `AlpacaMarketData` instance for querying market data,
    #' assets, calendar, and clock from Alpaca's REST API.
    #'
    #' ### API Endpoint
    #' No HTTP request is made during construction. The object stores
    #' credentials and base URLs for subsequent method calls.
    #'
    #' ### Official Documentation
    #' - [Authentication](https://docs.alpaca.markets/docs/getting-started)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' # No request at construction. Verify credentials with the clock endpoint:
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/clock'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' # (No response — constructor does not call an endpoint)
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

    # ---- Historical Bars ----

    #' @description
    #' Get Historical Bars (OHLCV)
    #'
    #' Retrieves historical candlestick/bar data for a single symbol. Bars
    #' include open, high, low, close, volume, trade count, and VWAP.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/bars`
    #'
    #' ### Official Documentation
    #' [Historical Stock Bars](https://docs.alpaca.markets/reference/stockbars)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/bars?timeframe=1Day&start=2024-01-01'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "bars": [
    #'     {"t": "2024-01-02T05:00:00Z", "o": 187.15, "h": 188.44, "l": 183.89, "c": 185.64, "v": 82488700, "n": 1036517, "vw": 185.831}
    #'   ],
    #'   "symbol": "AAPL",
    #'   "next_page_token": null
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol (e.g., `"AAPL"`).
    #' @param timeframe Character; bar timeframe. Valid values:
    #'   `"1Min"` to `"59Min"`, `"1Hour"` to `"23Hour"`, `"1Day"`, `"1Week"`,
    #'   `"1Month"` to `"12Month"`.
    #' @param start Character or NULL; start date/time (RFC-3339 or `"YYYY-MM-DD"`).
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max bars (1-10000, default 1000).
    #' @param adjustment Character or NULL; price adjustment type:
    #'   `"raw"`, `"split"`, `"dividend"`, `"all"`. Default `"raw"`.
    #' @param feed Character or NULL; data feed source:
    #'   `"iex"` (free), `"sip"` (paid, all exchanges).
    #' @param sort Character or NULL; `"asc"` (default) or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `timestamp` (POSIXct): Bar timestamp in UTC.
    #'   - `open` (numeric): Opening price.
    #'   - `high` (numeric): Highest price.
    #'   - `low` (numeric): Lowest price.
    #'   - `close` (numeric): Closing price.
    #'   - `volume` (integer): Volume traded.
    #'   - `trade_count` (integer): Number of trades.
    #'   - `vwap` (numeric): Volume-weighted average price.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bars <- market$get_bars("AAPL", "1Day", start = "2024-01-01", end = "2024-01-31")
    #' print(bars)
    #' }
    get_bars = function(
      symbol,
      timeframe = "1Day",
      start = NULL,
      end = NULL,
      limit = NULL,
      adjustment = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL
    ) {
      endpoint <- paste0("/v2/stocks/", symbol, "/bars")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(
          timeframe = timeframe,
          start = start,
          end = end,
          limit = limit,
          adjustment = adjustment,
          feed = feed,
          sort = sort,
          page_token = page_token
        ),
        .parser = function(data) {
          parse_bars(data$bars)
        }
      ))
    },

    #' @description
    #' Get Historical Bars for Multiple Symbols
    #'
    #' Retrieves historical bar data for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/bars`
    #'
    #' ### Official Documentation
    #' [Multi Stock Bars](https://docs.alpaca.markets/reference/stockbars-1)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/bars?symbols=AAPL,MSFT&timeframe=1Day&start=2024-01-01&limit=2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "bars": {
    #'     "AAPL": [
    #'       {"t": "2024-01-02T05:00:00Z", "o": 187.15, "h": 188.44, "l": 183.89, "c": 185.64, "v": 82488700, "n": 1036517, "vw": 185.831}
    #'     ],
    #'     "MSFT": [
    #'       {"t": "2024-01-02T05:00:00Z", "o": 373.86, "h": 376.04, "l": 371.34, "c": 374.72, "v": 22622100, "n": 345678, "vw": 374.12}
    #'     ]
    #'   },
    #'   "next_page_token": null
    #' }
    #' ```
    #'
    #' @param symbols Character vector; ticker symbols (max 100).
    #' @param timeframe Character; bar timeframe (see `get_bars()` for valid values).
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max bars per symbol (1-10000, default 1000).
    #' @param adjustment Character or NULL; `"raw"`, `"split"`, `"dividend"`, `"all"`.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @param sort Character or NULL; `"asc"` or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column prepended plus the same columns as `get_bars()`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bars <- market$get_bars_multi(c("AAPL", "MSFT"), "1Day", start = "2024-01-01")
    #' print(bars)
    #' }
    get_bars_multi = function(
      symbols,
      timeframe = "1Day",
      start = NULL,
      end = NULL,
      limit = NULL,
      adjustment = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL
    ) {
      return(private$.data_request(
        endpoint = "/v2/stocks/bars",
        query = list(
          symbols = paste(symbols, collapse = ","),
          timeframe = timeframe,
          start = start,
          end = end,
          limit = limit,
          adjustment = adjustment,
          feed = feed,
          sort = sort,
          page_token = page_token
        ),
        .parser = parse_multi_bars
      ))
    },

    # ---- Latest Data ----

    #' @description
    #' Get Latest Bar
    #'
    #' Retrieves the most recent bar for a single symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/bars/latest`
    #'
    #' ### Official Documentation
    #' [Latest Stock Bar](https://docs.alpaca.markets/reference/stocklatestbar)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/bars/latest'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "bar": {
    #'     "t": "2024-01-15T20:59:00Z",
    #'     "o": 185.30,
    #'     "h": 185.45,
    #'     "l": 185.20,
    #'     "c": 185.42,
    #'     "v": 1234567,
    #'     "n": 15432,
    #'     "vw": 185.35
    #'   },
    #'   "symbol": "AAPL"
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with the
    #'   same columns as `get_bars()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bar <- market$get_latest_bar("AAPL")
    #' print(bar)
    #' }
    get_latest_bar = function(symbol, feed = NULL) {
      endpoint <- paste0("/v2/stocks/", symbol, "/bars/latest")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed),
        .parser = function(data) {
          parse_bars(list(data$bar))
        }
      ))
    },

    #' @description
    #' Get Latest Trade
    #'
    #' Retrieves the most recent trade for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/trades/latest`
    #'
    #' ### Official Documentation
    #' [Latest Trade](https://docs.alpaca.markets/reference/stocklatesttrade)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/trades/latest'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "trade": {
    #'     "t": "2024-01-15T20:00:00.123456Z",
    #'     "x": "V",
    #'     "p": 185.64,
    #'     "s": 100,
    #'     "c": ["@"],
    #'     "i": 12345,
    #'     "z": "C"
    #'   },
    #'   "symbol": "AAPL"
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) in long
    #'   format with one row per trade condition. Columns:
    #'   - `timestamp` (POSIXct): Trade timestamp.
    #'   - `price` (numeric): Trade price.
    #'   - `size` (integer): Trade size.
    #'   - `exchange` (character): Exchange code.
    #'   - `tape` (character): SIP tape.
    #'   - `id` (integer): Trade ID.
    #'   - `condition` (character): Trade condition code.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' trade <- market$get_latest_trade("AAPL")
    #' print(trade)
    #' }
    get_latest_trade = function(symbol, feed = NULL) {
      endpoint <- paste0("/v2/stocks/", symbol, "/trades/latest")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed),
        .parser = function(data) {
          parse_trades(list(data$trade))
        }
      ))
    },

    #' @description
    #' Get Latest Quote (NBBO)
    #'
    #' Retrieves the most recent National Best Bid and Offer for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/quotes/latest`
    #'
    #' ### Official Documentation
    #' [Latest Quote](https://docs.alpaca.markets/reference/stocklatestquote)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/quotes/latest'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "quote": {
    #'     "t": "2024-01-15T20:00:00.000123Z",
    #'     "ax": "Q",
    #'     "ap": 185.65,
    #'     "as": 3,
    #'     "bx": "K",
    #'     "bp": 185.63,
    #'     "bs": 2,
    #'     "c": ["R"],
    #'     "z": "C"
    #'   },
    #'   "symbol": "AAPL"
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `timestamp` (POSIXct): Quote timestamp.
    #'   - `ask_exchange` (character): Ask exchange code.
    #'   - `ask_price` (numeric): Ask price.
    #'   - `ask_size` (integer): Ask size.
    #'   - `bid_exchange` (character): Bid exchange code.
    #'   - `bid_price` (numeric): Bid price.
    #'   - `bid_size` (integer): Bid size.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' quote <- market$get_latest_quote("AAPL")
    #' print(quote)
    #' }
    get_latest_quote = function(symbol, feed = NULL) {
      endpoint <- paste0("/v2/stocks/", symbol, "/quotes/latest")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed),
        .parser = function(data) {
          parse_quotes(list(data$quote))
        }
      ))
    },

    #' @description
    #' Get Snapshot
    #'
    #' Retrieves the latest snapshot for a symbol including latest trade,
    #' latest quote, minute bar, daily bar, and previous daily bar.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/snapshot`
    #'
    #' ### Official Documentation
    #' [Stock Snapshot](https://docs.alpaca.markets/reference/stocksnapshot)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/snapshot'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "latestTrade": {"t": "2024-01-15T20:00:00Z", "x": "V", "p": 185.64, "s": 100, "c": ["@"], "i": 12345, "z": "C"},
    #'   "latestQuote": {"t": "2024-01-15T20:00:00Z", "ax": "Q", "ap": 185.65, "as": 3, "bx": "K", "bp": 185.63, "bs": 2, "c": ["R"], "z": "C"},
    #'   "minuteBar": {"t": "2024-01-15T19:59:00Z", "o": 185.50, "h": 185.65, "l": 185.40, "c": 185.60, "v": 45230, "n": 312, "vw": 185.52},
    #'   "dailyBar": {"t": "2024-01-15T05:00:00Z", "o": 184.20, "h": 186.10, "l": 183.80, "c": 185.64, "v": 56789012, "n": 678901, "vw": 185.12},
    #'   "prevDailyBar": {"t": "2024-01-12T05:00:00Z", "o": 185.60, "h": 186.00, "l": 184.50, "c": 185.59, "v": 48234567, "n": 543210, "vw": 185.30}
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   flattened snapshot fields (prefixed by section name).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' snap <- market$get_snapshot("AAPL")
    #' print(snap)
    #' }
    get_snapshot = function(symbol, feed = NULL) {
      endpoint <- paste0("/v2/stocks/", symbol, "/snapshot")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed),
        .parser = parse_snapshot
      ))
    },

    #' @description
    #' Get Latest Bars for Multiple Symbols
    #'
    #' Retrieves the most recent bar for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/bars/latest`
    #'
    #' ### Official Documentation
    #' [Latest Multi Bars](https://docs.alpaca.markets/reference/stocklatestbars)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/bars/latest?symbols=AAPL,MSFT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "bars": {
    #'     "AAPL": {"t": "2024-01-15T20:59:00Z", "o": 185.30, "h": 185.45, "l": 185.20, "c": 185.42, "v": 1234567, "n": 15432, "vw": 185.35},
    #'     "MSFT": {"t": "2024-01-15T20:59:00Z", "o": 420.10, "h": 420.50, "l": 419.80, "c": 420.35, "v": 987654, "n": 12345, "vw": 420.22}
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character vector; ticker symbols.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column and the same columns as `get_bars()`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bars <- market$get_latest_bars_multi(c("AAPL", "MSFT"))
    #' print(bars)
    #' }
    get_latest_bars_multi = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v2/stocks/bars/latest",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed
        ),
        .parser = function(data) {
          bars_map <- data$bars
          if (is.null(bars_map) || length(bars_map) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(bars_map), function(sym) {
            dt <- parse_bars(list(bars_map[[sym]]))
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
    #' Get Latest Trades for Multiple Symbols
    #'
    #' Retrieves the most recent trade for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/trades/latest`
    #'
    #' ### Official Documentation
    #' [Latest Multi Trades](https://docs.alpaca.markets/reference/stocklatesttrades)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/trades/latest?symbols=AAPL,MSFT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "trades": {
    #'     "AAPL": {"t": "2024-01-15T20:00:00.123456Z", "x": "V", "p": 185.64, "s": 100, "c": ["@"], "i": 12345, "z": "C"},
    #'     "MSFT": {"t": "2024-01-15T20:00:00.654321Z", "x": "Q", "p": 420.72, "s": 50, "c": ["@"], "i": 67890, "z": "C"}
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character vector; ticker symbols.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column and trade columns.
    get_latest_trades_multi = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v2/stocks/trades/latest",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed
        ),
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
    #' Get Latest Quotes for Multiple Symbols
    #'
    #' Retrieves the most recent NBBO quote for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/quotes/latest`
    #'
    #' ### Official Documentation
    #' [Latest Multi Quotes](https://docs.alpaca.markets/reference/stocklatestquotes)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/quotes/latest?symbols=AAPL,MSFT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "quotes": {
    #'     "AAPL": {"t": "2024-01-15T20:00:00Z", "ax": "Q", "ap": 185.65, "as": 3, "bx": "K", "bp": 185.63, "bs": 2, "c": ["R"], "z": "C"},
    #'     "MSFT": {"t": "2024-01-15T20:00:00Z", "ax": "N", "ap": 420.75, "as": 1, "bx": "P", "bp": 420.70, "bs": 4, "c": ["R"], "z": "C"}
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character vector; ticker symbols.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column and quote columns.
    get_latest_quotes_multi = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v2/stocks/quotes/latest",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed
        ),
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
    #' Get Snapshots for Multiple Symbols
    #'
    #' Retrieves real-time snapshots for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/snapshots`
    #'
    #' ### Official Documentation
    #' [Multi Stock Snapshots](https://docs.alpaca.markets/reference/stocksnapshots)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/snapshots?symbols=AAPL,MSFT'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "AAPL": {
    #'     "latestTrade": {"t": "2024-01-15T20:00:00Z", "x": "V", "p": 185.64, "s": 100, "c": ["@"], "i": 12345, "z": "C"},
    #'     "latestQuote": {"t": "2024-01-15T20:00:00Z", "ax": "Q", "ap": 185.65, "as": 3, "bx": "K", "bp": 185.63, "bs": 2, "c": ["R"], "z": "C"},
    #'     "minuteBar": {"t": "2024-01-15T19:59:00Z", "o": 185.50, "h": 185.65, "l": 185.40, "c": 185.60, "v": 45230, "n": 312, "vw": 185.52},
    #'     "dailyBar": {"t": "2024-01-15T05:00:00Z", "o": 184.20, "h": 186.10, "l": 183.80, "c": 185.64, "v": 56789012, "n": 678901, "vw": 185.12},
    #'     "prevDailyBar": {"t": "2024-01-12T05:00:00Z", "o": 185.60, "h": 186.00, "l": 184.50, "c": 185.59, "v": 48234567, "n": 543210, "vw": 185.30}
    #'   },
    #'   "MSFT": {
    #'     "latestTrade": {"t": "2024-01-15T20:00:00Z", "x": "Q", "p": 420.72, "s": 50, "c": ["@"], "i": 67890, "z": "C"},
    #'     "latestQuote": {"t": "2024-01-15T20:00:00Z", "ax": "N", "ap": 420.75, "as": 1, "bx": "P", "bp": 420.70, "bs": 4, "c": ["R"], "z": "C"},
    #'     "minuteBar": {"t": "2024-01-15T19:59:00Z", "o": 420.30, "h": 420.80, "l": 420.20, "c": 420.65, "v": 32100, "n": 245, "vw": 420.50},
    #'     "dailyBar": {"t": "2024-01-15T05:00:00Z", "o": 419.50, "h": 421.00, "l": 418.80, "c": 420.72, "v": 23456789, "n": 345678, "vw": 420.10},
    #'     "prevDailyBar": {"t": "2024-01-12T05:00:00Z", "o": 420.00, "h": 421.50, "l": 419.00, "c": 420.45, "v": 21345678, "n": 312345, "vw": 420.25}
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols Character vector; ticker symbols.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column and flattened snapshot fields.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' snaps <- market$get_snapshots_multi(c("AAPL", "MSFT", "GOOGL"))
    #' print(snaps)
    #' }
    get_snapshots_multi = function(symbols, feed = NULL) {
      return(private$.data_request(
        endpoint = "/v2/stocks/snapshots",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(data.table::data.table()[])
          }
          dts <- lapply(names(data), function(sym) {
            dt <- parse_snapshot(data[[sym]])
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

    # ---- Historical Trades & Quotes ----

    #' @description
    #' Get Historical Trades
    #'
    #' Retrieves historical trade data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/trades`
    #'
    #' ### Official Documentation
    #' [Historical Stock Trades](https://docs.alpaca.markets/reference/stocktrades)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/trades?start=2024-01-15&limit=3'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "trades": [
    #'     {"t": "2024-01-15T09:30:00.123456Z", "x": "V", "p": 184.25, "s": 200, "c": ["@", "T"], "i": 10001, "z": "C"},
    #'     {"t": "2024-01-15T09:30:00.234567Z", "x": "Q", "p": 184.30, "s": 100, "c": ["@"], "i": 10002, "z": "C"},
    #'     {"t": "2024-01-15T09:30:00.345678Z", "x": "N", "p": 184.28, "s": 50, "c": ["@"], "i": 10003, "z": "C"}
    #'   ],
    #'   "symbol": "AAPL",
    #'   "next_page_token": "QUFQTHwyMDI0LTAxLTE1VDA5OjMwOjAwLjM0NTY3OFp8MTAwMDM="
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol.
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max trades (1-10000, default 1000).
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @param sort Character or NULL; `"asc"` or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) in long
    #'   format with one row per trade condition. Columns:
    #'   - `timestamp` (POSIXct): Trade timestamp.
    #'   - `price` (numeric): Trade price.
    #'   - `size` (integer): Trade size.
    #'   - `exchange` (character): Exchange code.
    #'   - `tape` (character): SIP tape.
    #'   - `id` (integer): Trade ID.
    #'   - `condition` (character): Trade condition code.
    get_trades = function(
      symbol,
      start = NULL,
      end = NULL,
      limit = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL
    ) {
      endpoint <- paste0("/v2/stocks/", symbol, "/trades")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(
          start = start,
          end = end,
          limit = limit,
          feed = feed,
          sort = sort,
          page_token = page_token
        ),
        .parser = function(data) parse_trades(data$trades)
      ))
    },

    #' @description
    #' Get Historical Quotes
    #'
    #' Retrieves historical quote (NBBO) data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/quotes`
    #'
    #' ### Official Documentation
    #' [Historical Stock Quotes](https://docs.alpaca.markets/reference/stockquotes)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v2/stocks/AAPL/quotes?start=2024-01-15&limit=2'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "quotes": [
    #'     {"t": "2024-01-15T09:30:00.000123Z", "ax": "Q", "ap": 184.30, "as": 5, "bx": "K", "bp": 184.25, "bs": 3, "c": ["R"], "z": "C"},
    #'     {"t": "2024-01-15T09:30:00.001234Z", "ax": "N", "ap": 184.32, "as": 2, "bx": "P", "bp": 184.27, "bs": 4, "c": ["R"], "z": "C"}
    #'   ],
    #'   "symbol": "AAPL",
    #'   "next_page_token": "QUFQTHwyMDI0LTAxLTE1VDA5OjMwOjAwLjAwMTIzNFp8Mg=="
    #' }
    #' ```
    #'
    #' @param symbol Character; ticker symbol.
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max quotes (1-10000, default 1000).
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @param sort Character or NULL; `"asc"` or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `timestamp` (POSIXct): Quote timestamp.
    #'   - `ask_exchange` (character): Ask exchange code.
    #'   - `ask_price` (numeric): Ask price.
    #'   - `ask_size` (integer): Ask size.
    #'   - `bid_exchange` (character): Bid exchange code.
    #'   - `bid_price` (numeric): Bid price.
    #'   - `bid_size` (integer): Bid size.
    get_quotes = function(
      symbol,
      start = NULL,
      end = NULL,
      limit = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL
    ) {
      endpoint <- paste0("/v2/stocks/", symbol, "/quotes")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(
          start = start,
          end = end,
          limit = limit,
          feed = feed,
          sort = sort,
          page_token = page_token
        ),
        .parser = function(data) parse_quotes(data$quotes)
      ))
    },

    # ---- Assets ----

    #' @description
    #' Get All Assets
    #'
    #' Retrieves a list of available assets (stocks, crypto, etc.).
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/assets`
    #'
    #' ### Official Documentation
    #' [Assets](https://docs.alpaca.markets/reference/get-v2-assets)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/assets?status=active&asset_class=us_equity'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
    #'     "class": "us_equity",
    #'     "exchange": "NASDAQ",
    #'     "symbol": "AAPL",
    #'     "name": "Apple Inc.",
    #'     "status": "active",
    #'     "tradable": true,
    #'     "marginable": true,
    #'     "maintenance_margin_requirement": 30,
    #'     "shortable": true,
    #'     "easy_to_borrow": true,
    #'     "fractionable": true
    #'   }
    #' ]
    #' ```
    #'
    #' @param status Character or NULL; filter by status (`"active"`, `"inactive"`).
    #' @param asset_class Character or NULL; filter by class (`"us_equity"`,
    #'   `"us_option"`, `"crypto"`).
    #' @param exchange Character or NULL; filter by exchange.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Asset UUID.
    #'   - `class` (character): Asset class.
    #'   - `exchange` (character): Exchange.
    #'   - `symbol` (character): Ticker symbol.
    #'   - `name` (character): Company name.
    #'   - `status` (character): Active/inactive.
    #'   - `tradable` (logical): Whether the asset is tradable.
    #'   - `marginable` (logical): Whether margin is available.
    #'   - `shortable` (logical): Whether short selling is available.
    #'   - `fractionable` (logical): Whether fractional shares are available.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' assets <- market$get_assets(status = "active", asset_class = "us_equity")
    #' print(assets[1:5, .(symbol, name, exchange, tradable)])
    #' }
    get_assets = function(status = NULL, asset_class = NULL, exchange = NULL) {
      return(private$.request(
        endpoint = "/v2/assets",
        query = list(status = status, asset_class = asset_class, exchange = exchange),
        .parser = as_dt_list
      ))
    },

    #' @description
    #' Get Asset by Symbol or ID
    #'
    #' Retrieves metadata for a single asset.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/assets/{symbol_or_id}`
    #'
    #' ### Official Documentation
    #' [Asset by ID or Symbol](https://docs.alpaca.markets/reference/get-v2-assets-symbol_or_asset_id)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/assets/AAPL'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
    #'   "class": "us_equity",
    #'   "exchange": "NASDAQ",
    #'   "symbol": "AAPL",
    #'   "name": "Apple Inc.",
    #'   "status": "active",
    #'   "tradable": true,
    #'   "marginable": true,
    #'   "maintenance_margin_requirement": 30,
    #'   "shortable": true,
    #'   "easy_to_borrow": true,
    #'   "fractionable": true
    #' }
    #' ```
    #'
    #' @param symbol_or_id Character; ticker symbol or asset UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same columns as `get_assets()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' aapl <- market$get_asset("AAPL")
    #' print(aapl)
    #' }
    get_asset = function(symbol_or_id) {
      endpoint <- paste0("/v2/assets/", symbol_or_id)
      return(private$.request(
        endpoint = endpoint,
        .parser = as_dt_row
      ))
    },

    # ---- Calendar & Clock ----

    #' @description
    #' Get Market Calendar
    #'
    #' Retrieves the market calendar showing trading days and hours.
    #' Includes early closure information.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/calendar`
    #'
    #' ### Official Documentation
    #' [Calendar](https://docs.alpaca.markets/reference/get-v2-calendar)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/calendar?start=2024-01-01&end=2024-01-05'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {"date": "2024-01-02", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-04"},
    #'   {"date": "2024-01-03", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-05"},
    #'   {"date": "2024-01-04", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-08"},
    #'   {"date": "2024-01-05", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-09"}
    #' ]
    #' ```
    #'
    #' @param start Character or NULL; start date (`"YYYY-MM-DD"`).
    #' @param end Character or NULL; end date (`"YYYY-MM-DD"`).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `date` (character): Trading date.
    #'   - `open` (character): Market open time (ET).
    #'   - `close` (character): Market close time (ET).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' cal <- market$get_calendar(start = "2024-01-01", end = "2024-01-31")
    #' print(cal)
    #' }
    get_calendar = function(start = NULL, end = NULL) {
      return(private$.request(
        endpoint = "/v2/calendar",
        query = list(start = start, end = end),
        .parser = as_dt_list
      ))
    },

    #' @description
    #' Get Market Clock
    #'
    #' Retrieves the current market clock including whether the market is
    #' open and the next open/close times.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/clock`
    #'
    #' ### Official Documentation
    #' [Clock](https://docs.alpaca.markets/reference/get-v2-clock)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/clock'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "timestamp": "2024-01-15T14:30:00.000-05:00",
    #'   "is_open": true,
    #'   "next_open": "2024-01-16T09:30:00-05:00",
    #'   "next_close": "2024-01-15T16:00:00-05:00"
    #' }
    #' ```
    #'
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `timestamp` (character): Current server timestamp.
    #'   - `is_open` (logical): Whether the market is currently open.
    #'   - `next_open` (character): Next market open time.
    #'   - `next_close` (character): Next market close time.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' clock <- market$get_clock()
    #' cat("Market open:", clock$is_open, "\n")
    #' }
    get_clock = function() {
      return(private$.request(
        endpoint = "/v2/clock",
        .parser = as_dt_row
      ))
    },

    # ---- Corporate Actions ----

    #' @description
    #' Get Corporate Action Announcements
    #'
    #' Retrieves announcements for corporate actions such as dividends, mergers,
    #' spinoffs, and stock splits. Essential for production trading systems that
    #' need to handle position adjustments.
    #'
    #' ### API Endpoint
    #' `GET https://paper-api.alpaca.markets/v2/corporate_actions/announcements`
    #'
    #' ### Official Documentation
    #' [Corporate Actions](https://docs.alpaca.markets/reference/get-v2-corporate_actions-announcements)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://paper-api.alpaca.markets/v2/corporate_actions/announcements?ca_types=dividend&since=2024-01-01&until=2024-03-31'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' [
    #'   {
    #'     "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    #'     "corporate_action_id": "DIV_AAPL_2024Q1",
    #'     "ca_type": "dividend",
    #'     "ca_sub_type": "cash",
    #'     "initiating_symbol": "AAPL",
    #'     "target_symbol": "AAPL",
    #'     "declaration_date": "2024-02-01",
    #'     "ex_date": "2024-02-09",
    #'     "record_date": "2024-02-12",
    #'     "payable_date": "2024-02-15",
    #'     "cash": "0.24",
    #'     "old_rate": "1",
    #'     "new_rate": "1"
    #'   }
    #' ]
    #' ```
    #'
    #' @param ca_types Character; comma-separated corporate action types. Valid
    #'   values: `"dividend"`, `"merger"`, `"spinoff"`, `"split"`.
    #' @param since Character; start date (`"YYYY-MM-DD"`). Required.
    #' @param until Character; end date (`"YYYY-MM-DD"`). Required.
    #' @param symbol Character or NULL; filter by ticker symbol.
    #' @param cusip Character or NULL; filter by CUSIP.
    #' @param date_type Character or NULL; which date field `since`/`until` refer to:
    #'   `"declaration"`, `"ex"`, `"record"`, `"payable"`. Default `"ex"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `id` (character): Announcement UUID.
    #'   - `corporate_action_id` (character): Corporate action ID.
    #'   - `ca_type` (character): Action type.
    #'   - `ca_sub_type` (character): Action sub-type.
    #'   - `initiating_symbol` (character): Symbol initiating the action.
    #'   - `target_symbol` (character): Target symbol (for mergers).
    #'   - `declaration_date` (character): Declaration date.
    #'   - `ex_date` (character): Ex-date.
    #'   - `record_date` (character): Record date.
    #'   - `payable_date` (character): Payable date.
    #'   - `cash` (character): Cash amount (for dividends).
    #'   - `old_rate` (character): Old rate (for splits).
    #'   - `new_rate` (character): New rate (for splits).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #'
    #' # Get all AAPL dividends in 2024
    #' divs <- market$get_corporate_actions(
    #'   ca_types = "dividend", since = "2024-01-01", until = "2024-12-31",
    #'   symbol = "AAPL"
    #' )
    #' print(divs)
    #'
    #' # Get all stock splits
    #' splits <- market$get_corporate_actions(
    #'   ca_types = "split", since = "2024-01-01", until = "2024-12-31"
    #' )
    #' }
    get_corporate_actions = function(
      ca_types,
      since,
      until,
      symbol = NULL,
      cusip = NULL,
      date_type = NULL
    ) {
      return(private$.request(
        endpoint = "/v2/corporate_actions/announcements",
        query = list(
          ca_types = ca_types,
          since = since,
          until = until,
          symbol = symbol,
          cusip = cusip,
          date_type = date_type
        ),
        .parser = as_dt_list
      ))
    },

    # ---- News ----

    #' @description
    #' Get Market News
    #'
    #' Retrieves news articles from multiple sources filtered by symbols,
    #' date range, or content. Useful for event-driven trading strategies.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/news`
    #'
    #' ### Official Documentation
    #' [News](https://docs.alpaca.markets/reference/news-1)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/news?symbols=AAPL&limit=10'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "news": [
    #'     {
    #'       "id": 35678901,
    #'       "headline": "Apple Reports Record Q1 Revenue of $119.6 Billion",
    #'       "author": "Reuters",
    #'       "source": "reuters",
    #'       "summary": "Apple Inc reported record first-quarter revenue driven by strong iPhone sales...",
    #'       "url": "https://www.reuters.com/technology/apple-q1-2024-earnings",
    #'       "symbols": ["AAPL"],
    #'       "created_at": "2024-01-15T18:30:00Z",
    #'       "updated_at": "2024-01-15T18:35:00Z",
    #'       "images": [{"size": "large", "url": "https://example.com/aapl.jpg"}]
    #'     }
    #'   ],
    #'   "next_page_token": "MTIzNDU2Nzg5MA=="
    #' }
    #' ```
    #'
    #' @param symbols Character or NULL; comma-separated symbols to filter
    #'   (e.g., `"AAPL,MSFT"`).
    #' @param start Character or NULL; start date/time (RFC-3339).
    #' @param end Character or NULL; end date/time (RFC-3339).
    #' @param limit Integer or NULL; max articles (default 10, max 50).
    #' @param sort Character or NULL; `"desc"` (default, newest first) or `"asc"`.
    #' @param include_content Logical or NULL; if `TRUE`, include full article content.
    #' @param exclude_contentless Logical or NULL; if `TRUE`, exclude articles
    #'   without content.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) in long
    #'   format with one row per related symbol. Columns:
    #'   - `id` (integer): Article ID.
    #'   - `headline` (character): Article headline.
    #'   - `author` (character): Author name.
    #'   - `source` (character): News source.
    #'   - `summary` (character): Article summary.
    #'   - `url` (character): Article URL.
    #'   - `created_at` (character): Publication timestamp.
    #'   - `updated_at` (character): Last update timestamp.
    #'   - `symbol` (character): Related ticker symbol.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #'
    #' # Latest AAPL news
    #' news <- market$get_news(symbols = "AAPL", limit = 5)
    #' print(news[, .(headline, source, created_at)])
    #'
    #' # News with full content
    #' news <- market$get_news(symbols = "TSLA", include_content = TRUE)
    #' }
    get_news = function(
      symbols = NULL,
      start = NULL,
      end = NULL,
      limit = NULL,
      sort = NULL,
      include_content = NULL,
      exclude_contentless = NULL,
      page_token = NULL
    ) {
      # Join symbols with comma like other multi-symbol methods
      if (!is.null(symbols) && length(symbols) > 1) {
        symbols <- paste(symbols, collapse = ",")
      }
      return(private$.data_request(
        endpoint = "/v1beta1/news",
        query = list(
          symbols = symbols,
          start = start,
          end = end,
          limit = limit,
          sort = sort,
          include_content = include_content,
          exclude_contentless = exclude_contentless,
          page_token = page_token
        ),
        .parser = function(data) parse_news(data$news)
      ))
    },

    # ---- Screener ----

    #' @description
    #' Get Most Active Stocks
    #'
    #' Retrieves the most active stocks by volume or trade count.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/screener/stocks/most-actives`
    #'
    #' ### Official Documentation
    #' [Most Active Stocks](https://docs.alpaca.markets/reference/mostactives)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/screener/stocks/most-actives?by=volume&top=5'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "most_actives": [
    #'     {"symbol": "AAPL", "volume": 82488700, "trade_count": 1036517},
    #'     {"symbol": "TSLA", "volume": 74523100, "trade_count": 987654},
    #'     {"symbol": "NVDA", "volume": 65432100, "trade_count": 876543},
    #'     {"symbol": "AMD", "volume": 54321000, "trade_count": 765432},
    #'     {"symbol": "MSFT", "volume": 22622100, "trade_count": 345678}
    #'   ],
    #'   "last_updated": "2024-01-15T20:00:00Z"
    #' }
    #' ```
    #'
    #' @param by Character or NULL; ranking metric: `"volume"` (default) or `"trades"`.
    #' @param top Integer or NULL; number of results to return (default 10).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Ticker symbol.
    #'   - `volume` (numeric): Trading volume.
    #'   - `trade_count` (numeric): Number of trades.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' actives <- market$get_most_actives(by = "volume", top = 20)
    #' print(actives)
    #' }
    get_most_actives = function(by = NULL, top = NULL) {
      return(private$.data_request(
        endpoint = "/v1beta1/screener/stocks/most-actives",
        query = list(by = by, top = top),
        .parser = function(data) as_dt_list(data$most_actives)
      ))
    },

    #' @description
    #' Get Top Market Movers
    #'
    #' Retrieves the top market movers (gainers and losers) by percentage change.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta1/screener/{market_type}/movers`
    #'
    #' ### Official Documentation
    #' [Top Market Movers](https://docs.alpaca.markets/reference/movers)
    #' Verifieid: 2026-03-10
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta1/screener/stocks/movers?top=3'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "gainers": [
    #'     {"symbol": "SMCI", "percent_change": 8.52, "change": 6.45, "price": 82.15},
    #'     {"symbol": "PLTR", "percent_change": 5.31, "change": 1.23, "price": 24.40},
    #'     {"symbol": "RIVN", "percent_change": 4.87, "change": 0.82, "price": 17.67}
    #'   ],
    #'   "losers": [
    #'     {"symbol": "MRNA", "percent_change": -6.12, "change": -6.80, "price": 104.30},
    #'     {"symbol": "ENPH", "percent_change": -5.45, "change": -6.10, "price": 105.80},
    #'     {"symbol": "COIN", "percent_change": -4.98, "change": -7.50, "price": 143.10}
    #'   ],
    #'   "market_type": "stocks",
    #'   "last_updated": "2024-01-15T20:00:00Z"
    #' }
    #' ```
    #'
    #' @param market_type Character; `"stocks"` (default) or `"crypto"`.
    #' @param top Integer or NULL; number of results per direction (default 10).
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `symbol` (character): Ticker symbol.
    #'   - `percent_change` (numeric): Percentage change.
    #'   - `change` (numeric): Absolute price change.
    #'   - `price` (numeric): Current price.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' movers <- market$get_movers(top = 5)
    #' print(movers)
    #' }
    get_movers = function(market_type = "stocks", top = NULL) {
      endpoint <- paste0("/v1beta1/screener/", market_type, "/movers")
      return(private$.data_request(
        endpoint = endpoint,
        query = list(top = top),
        .parser = function(data) {
          gainers <- data$gainers
          losers <- data$losers
          dts <- list()
          if (!is.null(gainers) && length(gainers) > 0) {
            g <- as_dt_list(gainers)
            if (nrow(g) > 0) {
              g[, direction := "gainer"]
            }
            dts <- c(dts, list(g))
          }
          if (!is.null(losers) && length(losers) > 0) {
            l <- as_dt_list(losers)
            if (nrow(l) > 0) {
              l[, direction := "loser"]
            }
            dts <- c(dts, list(l))
          }
          if (length(dts) == 0) {
            return(data.table::data.table()[])
          }
          return(data.table::rbindlist(dts, fill = TRUE)[])
        }
      ))
    }
  ),
  private = list(
    .data_base_url = NULL,

    # Execute a Market Data API request (uses data base URL)
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
