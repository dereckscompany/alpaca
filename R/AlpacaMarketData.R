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
#' | get_bars | GET /v2/stocks/{symbol}/bars | data |
#' | get_bars_multi | GET /v2/stocks/bars | data |
#' | get_latest_bar | GET /v2/stocks/{symbol}/latest/bar | data |
#' | get_latest_trade | GET /v2/stocks/{symbol}/latest/trade | data |
#' | get_latest_quote | GET /v2/stocks/{symbol}/latest/quote | data |
#' | get_snapshot | GET /v2/stocks/{symbol}/snapshot | data |
#' | get_trades | GET /v2/stocks/{symbol}/trades | data |
#' | get_quotes | GET /v2/stocks/{symbol}/quotes | data |
#' | get_assets | GET /v2/assets | trading |
#' | get_asset | GET /v2/assets/{symbol} | trading |
#' | get_calendar | GET /v2/calendar | trading |
#' | get_clock | GET /v2/clock | trading |
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
    #' [Historical Stock Bars](https://docs.alpaca.markets/docs/historical-stock-data-1)
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
    #' @param symbols Character vector; ticker symbols (max 100).
    #' @param timeframe Character; bar timeframe (see [get_bars()] for valid values).
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max bars per symbol (1-10000, default 1000).
    #' @param adjustment Character or NULL; `"raw"`, `"split"`, `"dividend"`, `"all"`.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @param sort Character or NULL; `"asc"` or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with a
    #'   `symbol` column prepended plus the same columns as [get_bars()].
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
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/latest/bar`
    #'
    #' @param symbol Character; ticker symbol.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with the
    #'   same columns as [get_bars()], single row.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bar <- market$get_latest_bar("AAPL")
    #' print(bar)
    #' }
    get_latest_bar = function(symbol, feed = NULL) {
      endpoint <- paste0("/v2/stocks/", symbol, "/latest/bar")
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
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/latest/trade`
    #'
    #' ### Official Documentation
    #' [Latest Trade](https://docs.alpaca.markets/reference/stocklatesttrade)
    #'
    #' @param symbol Character; ticker symbol.
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with columns:
    #'   - `timestamp` (POSIXct): Trade timestamp.
    #'   - `price` (numeric): Trade price.
    #'   - `size` (integer): Trade size.
    #'   - `exchange` (character): Exchange code.
    #'   - `conditions` (list): Trade conditions.
    #'   - `tape` (character): SIP tape.
    #'   - `id` (integer): Trade ID.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' trade <- market$get_latest_trade("AAPL")
    #' print(trade)
    #' }
    get_latest_trade = function(symbol, feed = NULL) {
      endpoint <- paste0("/v2/stocks/", symbol, "/latest/trade")
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
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/latest/quote`
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
      endpoint <- paste0("/v2/stocks/", symbol, "/latest/quote")
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
    #' Get Historical Trades
    #'
    #' Retrieves historical trade data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/trades`
    #'
    #' @param symbol Character; ticker symbol.
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max trades (1-10000, default 1000).
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @param sort Character or NULL; `"asc"` or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   trade columns (see [get_latest_trade()]).
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
    #' @param symbol Character; ticker symbol.
    #' @param start Character or NULL; start date/time.
    #' @param end Character or NULL; end date/time.
    #' @param limit Integer or NULL; max quotes (1-10000, default 1000).
    #' @param feed Character or NULL; `"iex"` or `"sip"`.
    #' @param sort Character or NULL; `"asc"` or `"desc"`.
    #' @param page_token Character or NULL; cursor for pagination.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   quote columns (see [get_latest_quote()]).
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
    #' @param symbol_or_id Character; ticker symbol or asset UUID.
    #' @return `data.table` (or `promise<data.table>` if `async = TRUE`) with
    #'   the same columns as [get_assets()], single row.
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
    }
  ),
  private = list(
    .data_base_url = NULL,

    # Execute a Market Data API request (uses data base URL)
    .data_request = function(
      endpoint,
      query = list(),
      .parser = identity,
      timeout = 10
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
