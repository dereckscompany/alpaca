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
#' - [Market Data API](https://docs.alpaca.markets/us/docs/about-market-data-api)
#' - [Historical Stock Data](https://docs.alpaca.markets/us/docs/historical-stock-data-1)
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
#' ### Timezones
#' This client wraps Alpaca's `/v2/` market-data endpoints, which are
#' US-only. All returned date / time columns are coerced to `Date` or
#' `POSIXct` for ergonomic use:
#'
#' - Endpoints whose JSON carries an explicit RFC-3339 offset (bars,
#'   trades, quotes, news, snapshots, clock) are parsed at the exact
#'   instant. Clock is displayed in `America/New_York`; bars / trades
#'   / quotes / news in UTC. Use [lubridate::with_tz()] to view in any
#'   other timezone.
#' - The calendar endpoint returns *naive* wall-clock times (`"09:30"`,
#'   `"0400"`) with no offset in the payload. Alpaca does **not**
#'   explicitly document the timezone on the calendar reference page,
#'   but the values are Eastern Time by inference (US-only venues,
#'   `09:30` matches the NYSE/NASDAQ open, every other SDK treats them
#'   as ET, and the market-data FAQ confirms NY tz for bar
#'   aggregation). We localise with the named tz `America/New_York`,
#'   so DST transitions flip automatically.
#'
#' This assumption is safe for `/v2/`. When Alpaca's `/v3/` multi-market
#' endpoints are adopted, per-market timezone lookup will replace the
#' single hard-coded tz. The constant lives in `R/helpers_parse.R`
#' (search for `TODO(v3)`).
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
    #' - [Authentication](https://docs.alpaca.markets/us/docs/getting-started)
    #' Verified: 2026-05-21
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
    #' @param keys (list) API credentials from [get_api_keys()].
    #' @param base_url (scalar<character>) trading API base URL. Defaults to
    #'   `get_base_url()`.
    #' @param data_base_url (scalar<character>) market data API base URL. Defaults
    #'   to `get_data_base_url()`.
    #' @param async (scalar<logical>) if `TRUE`, methods return promises. Default
    #'   `FALSE`.
    #' @return (class<AlpacaMarketData>) invisibly, self.
    initialize = function(
      keys = get_api_keys(),
      base_url = get_base_url(),
      data_base_url = get_data_base_url(),
      async = FALSE
    ) {
      assert_args_AlpacaMarketData__initialize(keys, base_url, data_base_url, async)
      super$initialize(keys = keys, base_url = base_url, async = async)
      private$.data_base_url <- data_base_url
      return(invisible(assert_return_AlpacaMarketData__initialize(self)))
    },

    # ---- Historical Bars ----

    # nolint start: line_length_linter.
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
    #' [Historical Stock Bars](https://docs.alpaca.markets/us/reference/stockbarsingle-1)
    #' Verified: 2026-05-21
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
    #' @param symbol (scalar<character>) ticker symbol (e.g., `"AAPL"`).
    #' @param timeframe (scalar<character>) bar timeframe. Valid values:
    #'   `"1Min"` to `"59Min"`, `"1Hour"` to `"23Hour"`, `"1Day"`, `"1Week"`,
    #'   `"1Month"` to `"12Month"`.
    #' @param start (scalar<character> | NULL) start date/time (RFC-3339 or
    #'   `"YYYY-MM-DD"`).
    #' @param end (scalar<character> | NULL) end date/time.
    #' @param limit (scalar<count in [1, 10001[> | NULL) max bars **per page**
    #'   (1-10000, default 10000). The method auto-paginates via
    #'   `next_page_token`, so the full `start`..`end` range is returned
    #'   regardless of `limit`; this only sets the page size (and thus the number
    #'   of requests).
    #' @param adjustment (scalar<character> | NULL) price adjustment type. One or
    #'   a comma-separated combination of: `"raw"`, `"split"`, `"dividend"`,
    #'   `"spin-off"`, `"all"`. Default `"raw"`.
    #' @param asof (scalar<character> | NULL) as-of date (`"YYYY-MM-DD"`) used to
    #'   identify the underlying entity when symbols have been renamed
    #'   (e.g. FB -> META). Pass `"-"` to skip symbol mapping.
    #' @param feed (scalar<character> | NULL) data feed source:
    #'   `"sip"` (default, all US exchanges), `"iex"`, `"otc"`, `"boats"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency for returned
    #'   prices. Default `"USD"`.
    #' @param sort (scalar<character> | NULL) `"asc"` (default) or `"desc"`.
    #' @param page_token (scalar<character> | NULL) starting cursor. Normally left
    #'   NULL — auto-pagination begins at `start` and follows the cursor itself.
    #' @param max_pages (scalar<numeric in [1, Inf]> | scalar<integer in [1, Inf[>) cap on pages fetched
    #'   (runaway guard). Default 1000 — high enough that real requests complete,
    #'   low enough to bound a fat-fingered pull. Pass `Inf` for unbounded. If hit
    #'   while more data remains, the partial result is returned with a
    #'   `warning()`.
    #' @param sleep (scalar<numeric in [0, Inf[>) seconds to pause between page
    #'   requests (rate-limit throttle; sync only). Default 0.3.
    #' @return (Bars | promise<Bars>) the bars. Columns: `datetime`
    #'   (POSIXct, UTC), `open`, `high`, `low`, `close`, `vwap` (numeric), and
    #'   `volume`, `trade_count` (integer).
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
      limit = 10000L,
      adjustment = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL,
      asof = NULL,
      currency = NULL,
      max_pages = 1000L,
      sleep = 0.3
    ) {
      assert_args_AlpacaMarketData__get_bars(
        symbol,
        timeframe,
        start,
        end,
        limit,
        adjustment,
        asof,
        feed,
        currency,
        sort,
        page_token,
        max_pages,
        sleep
      )
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/bars")
      result <- alpaca_paginate(
        base_url = private$.data_base_url,
        endpoint = endpoint,
        query = list(
          timeframe = timeframe,
          start = start,
          end = end,
          limit = limit,
          adjustment = adjustment,
          feed = feed,
          sort = sort,
          page_token = page_token,
          asof = asof,
          currency = currency
        ),
        keys = private$.keys,
        .perform = private$.perform,
        is_async = private$.is_async,
        items_field = "bars",
        .parser = parse_bars,
        max_pages = max_pages,
        sleep = sleep,
        timeout = 30
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_bars,
        is_async = private$.is_async
      ))
    },
    # nolint end

    # nolint start: line_length_linter.
    #' @description
    #' Get Historical Bars for Multiple Symbols
    #'
    #' Retrieves historical bar data for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/bars`
    #'
    #' ### Official Documentation
    #' [Multi Stock Bars](https://docs.alpaca.markets/us/reference/stockbars)
    #' Verified: 2026-05-21
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
    #' @param symbols (character) ticker symbols (max 100).
    #' @param timeframe (scalar<character>) bar timeframe (see `get_bars()` for
    #'   valid values).
    #' @param start (scalar<character> | NULL) start date/time.
    #' @param end (scalar<character> | NULL) end date/time.
    #' @param limit (scalar<count in [1, 10001[> | NULL) max bars **per page**
    #'   (1-10000, default 10000). NOTE: Alpaca applies this as a *total row
    #'   budget across all requested symbols per page* (not per symbol), filling
    #'   symbols alphabetically. The method auto-paginates via `next_page_token`,
    #'   so the full range for every symbol is returned regardless of `limit`.
    #' @param adjustment (scalar<character> | NULL) one or comma-separated
    #'   combination of `"raw"`, `"split"`, `"dividend"`, `"spin-off"`, `"all"`.
    #' @param asof (scalar<character> | NULL) as-of date for symbol mapping
    #'   (`"YYYY-MM-DD"` or `"-"` to skip).
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`, `"otc"`,
    #'   `"boats"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @param sort (scalar<character> | NULL) `"asc"` or `"desc"`.
    #' @param page_token (scalar<character> | NULL) starting cursor. Normally left
    #'   NULL — auto-pagination begins at `start` and follows the cursor itself.
    #' @param max_pages (scalar<numeric in [1, Inf]> | scalar<integer in [1, Inf[>) cap on pages fetched
    #'   (runaway guard). Default 1000; pass `Inf` for unbounded. If hit while
    #'   more data remains, the partial result is returned with a `warning()`.
    #' @param sleep (scalar<numeric in [0, Inf[>) seconds to pause between page
    #'   requests (rate-limit throttle; sync only). Default 0.3.
    #' @return (BarsMulti | promise<BarsMulti>) the bars, with a `symbol`
    #'   column prepended plus the same columns as `get_bars()`.
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
      limit = 10000L,
      adjustment = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL,
      asof = NULL,
      currency = NULL,
      max_pages = 1000L,
      sleep = 0.3
    ) {
      assert_args_AlpacaMarketData__get_bars_multi(
        symbols,
        timeframe,
        start,
        end,
        limit,
        adjustment,
        asof,
        feed,
        currency,
        sort,
        page_token,
        max_pages,
        sleep
      )
      result <- alpaca_paginate(
        base_url = private$.data_base_url,
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
          page_token = page_token,
          asof = asof,
          currency = currency
        ),
        keys = private$.keys,
        .perform = private$.perform,
        is_async = private$.is_async,
        items_field = "bars",
        .parser = parse_multi_bars_items,
        max_pages = max_pages,
        sleep = sleep,
        timeout = 30
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_bars_multi,
        is_async = private$.is_async
      ))
    },
    # nolint end

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
    #' [Latest Stock Bar](https://docs.alpaca.markets/us/reference/stocklatestbarsingle-1)
    #' Verified: 2026-05-21
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
    #' @param symbol (scalar<character>) ticker symbol.
    #' @param feed (scalar<character> | NULL) `"iex"` or `"sip"`.
    #' @return (Bars | promise<Bars>) the bar, with the same columns
    #'   as `get_bars()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bar <- market$get_latest_bar("AAPL")
    #' print(bar)
    #' }
    get_latest_bar = function(symbol, feed = NULL) {
      assert_args_AlpacaMarketData__get_latest_bar(symbol, feed)
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/bars/latest")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed),
        .parser = function(data) {
          return(parse_bars(list(data$bar)))
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_latest_bar,
        is_async = private$.is_async
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
    #' [Latest Trade](https://docs.alpaca.markets/us/reference/stocklatesttradesingle-1)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) ticker symbol.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (Trade | promise<Trade>) **one row per trade** (a single
    #'   row for this single-trade method). Columns: `timestamp` (POSIXct),
    #'   `price` (numeric), `size` (integer), `exchange` (character), `tape`
    #'   (character), `id` (integer), and `conditions` (character,
    #'   semicolon-separated condition codes e.g. `"@;T"`; `NA` when the trade
    #'   carries no condition codes). Filter with `dt[grepl("T", conditions)]`;
    #'   recover the original vector via
    #'   `strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' trade <- market$get_latest_trade("AAPL")
    #' print(trade)
    #' }
    get_latest_trade = function(symbol, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_latest_trade(symbol, feed, currency)
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/trades/latest")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed, currency = currency),
        .parser = function(data) {
          return(parse_trades(list(data$trade)))
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_latest_trade,
        is_async = private$.is_async
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
    #' [Latest Quote](https://docs.alpaca.markets/us/reference/stocklatestquotesingle-1)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) ticker symbol.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (Quote | promise<Quote>) **one row per quote**. Columns:
    #'   `timestamp` (POSIXct), `ask_exchange`, `bid_exchange`, `tape`
    #'   (character), `ask_price`, `bid_price` (numeric), `ask_size`, `bid_size`
    #'   (integer), and `conditions` (character, `;`-separated quote condition
    #'   codes e.g. `"R;F"`; `NA` when no conditions were reported). Filter with
    #'   `dt[grepl("R", conditions)]` or recover via
    #'   `strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' quote <- market$get_latest_quote("AAPL")
    #' print(quote)
    #' }
    get_latest_quote = function(symbol, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_latest_quote(symbol, feed, currency)
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/quotes/latest")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed, currency = currency),
        .parser = function(data) {
          return(parse_quotes(list(data$quote)))
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_latest_quote,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
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
    #' [Stock Snapshot](https://docs.alpaca.markets/us/reference/stocksnapshotsingle)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) ticker symbol.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (Snapshot | promise<Snapshot>) the flattened snapshot fields
    #'   (prefixed by section name).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' snap <- market$get_snapshot("AAPL")
    #' print(snap)
    #' }
    get_snapshot = function(symbol, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_snapshot(symbol, feed, currency)
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/snapshot")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(feed = feed, currency = currency),
        .parser = parse_snapshot
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_snapshot,
        is_async = private$.is_async
      ))
    },
    # nolint end

    # nolint start: line_length_linter.
    #' @description
    #' Get Latest Bars for Multiple Symbols
    #'
    #' Retrieves the most recent bar for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/bars/latest`
    #'
    #' ### Official Documentation
    #' [Latest Multi Bars](https://docs.alpaca.markets/us/reference/stocklatestbars-1)
    #' Verified: 2026-05-21
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
    #' @param symbols (character) ticker symbols.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (BarsMulti | promise<BarsMulti>) the bars, with a `symbol`
    #'   column and the same columns as `get_bars()`.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' bars <- market$get_latest_bars_multi(c("AAPL", "MSFT"))
    #' print(bars)
    #' }
    get_latest_bars_multi = function(symbols, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_latest_bars_multi(symbols, feed, currency)
      result <- private$.data_request(
        endpoint = "/v2/stocks/bars/latest",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed,
          currency = currency
        ),
        .parser = function(data) {
          bars_map <- data$bars
          if (is.null(bars_map) || length(bars_map) == 0) {
            return(empty_dt_bars_multi())
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_latest_bars_multi,
        is_async = private$.is_async
      ))
    },
    # nolint end

    # nolint start: line_length_linter.
    #' @description
    #' Get Latest Trades for Multiple Symbols
    #'
    #' Retrieves the most recent trade for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/trades/latest`
    #'
    #' ### Official Documentation
    #' [Latest Multi Trades](https://docs.alpaca.markets/us/reference/stocklatesttrades-1)
    #' Verified: 2026-05-22
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
    #' @param symbols (character) ticker symbols.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (TradesMulti | promise<TradesMulti>) the trades, with a leading
    #'   `symbol` column and the same per-trade columns as `get_latest_trade()`:
    #'   `timestamp`, `price`, `size`, `exchange`, `conditions` (`;`-collapsed),
    #'   `tape`, `id`. One row per symbol.
    get_latest_trades_multi = function(symbols, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_latest_trades_multi(symbols, feed, currency)
      result <- private$.data_request(
        endpoint = "/v2/stocks/trades/latest",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed,
          currency = currency
        ),
        .parser = function(data) {
          trades_map <- data$trades
          if (is.null(trades_map) || length(trades_map) == 0) {
            return(empty_dt_trades_multi())
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_latest_trades_multi,
        is_async = private$.is_async
      ))
    },
    # nolint end

    # nolint start: line_length_linter.
    #' @description
    #' Get Latest Quotes for Multiple Symbols
    #'
    #' Retrieves the most recent NBBO quote for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/quotes/latest`
    #'
    #' ### Official Documentation
    #' [Latest Multi Quotes](https://docs.alpaca.markets/us/reference/stocklatestquotes-1)
    #' Verified: 2026-05-22
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
    #' @param symbols (character) ticker symbols.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (QuotesMulti | promise<QuotesMulti>) the quotes, with a `symbol`
    #'   column and quote columns (`timestamp`, `ask_*`, `bid_*`, `conditions`,
    #'   `tape`). `conditions` is a `;`-separated character column following the
    #'   package's array-collapse convention.
    get_latest_quotes_multi = function(symbols, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_latest_quotes_multi(symbols, feed, currency)
      result <- private$.data_request(
        endpoint = "/v2/stocks/quotes/latest",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed,
          currency = currency
        ),
        .parser = function(data) {
          quotes_map <- data$quotes
          if (is.null(quotes_map) || length(quotes_map) == 0) {
            return(empty_dt_quotes_multi())
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_latest_quotes_multi,
        is_async = private$.is_async
      ))
    },
    # nolint end

    # nolint start: line_length_linter.
    #' @description
    #' Get Snapshots for Multiple Symbols
    #'
    #' Retrieves real-time snapshots for multiple symbols in a single request.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/snapshots`
    #'
    #' ### Official Documentation
    #' [Multi Stock Snapshots](https://docs.alpaca.markets/us/reference/stocksnapshots-1)
    #' Verified: 2026-05-22
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
    #' @param symbols (character) ticker symbols.
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`,
    #'   `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @return (SnapshotMulti | promise<SnapshotMulti>) the snapshots, with a
    #'   `symbol` column and flattened snapshot fields.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' snaps <- market$get_snapshots_multi(c("AAPL", "MSFT", "GOOGL"))
    #' print(snaps)
    #' }
    get_snapshots_multi = function(symbols, feed = NULL, currency = NULL) {
      assert_args_AlpacaMarketData__get_snapshots_multi(symbols, feed, currency)
      result <- private$.data_request(
        endpoint = "/v2/stocks/snapshots",
        query = list(
          symbols = paste(symbols, collapse = ","),
          feed = feed,
          currency = currency
        ),
        .parser = function(data) {
          if (is.null(data) || length(data) == 0) {
            return(empty_dt_snapshots_multi())
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_snapshots_multi,
        is_async = private$.is_async
      ))
    },
    # nolint end

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
    #' [Historical Stock Trades](https://docs.alpaca.markets/us/reference/stocktradesingle-1)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) ticker symbol.
    #' @param start (scalar<character> | NULL) start date/time.
    #' @param end (scalar<character> | NULL) end date/time.
    #' @param limit (scalar<count in [1, 10001[> | NULL) max trades (1-10000,
    #'   default 1000).
    #' @param asof (scalar<character> | NULL) as-of date for symbol mapping
    #'   (`"YYYY-MM-DD"` or `"-"` to skip).
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`, `"otc"`,
    #'   `"boats"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @param sort (scalar<character> | NULL) `"asc"` or `"desc"`.
    #' @param page_token (scalar<character> | NULL) cursor for pagination.
    #' @return (Trade | promise<Trade>) **one row per trade**. Columns:
    #'   `timestamp` (POSIXct), `price` (numeric), `size` (integer), `exchange`
    #'   (character), `tape` (character), `id` (integer), and `conditions`
    #'   (character, semicolon-separated condition codes e.g. `"@;T"`). Filter
    #'   with `dt[grepl("T", conditions)]`.
    get_trades = function(
      symbol,
      start = NULL,
      end = NULL,
      limit = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL,
      asof = NULL,
      currency = NULL
    ) {
      assert_args_AlpacaMarketData__get_trades(
        symbol,
        start,
        end,
        limit,
        asof,
        feed,
        currency,
        sort,
        page_token
      )
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/trades")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(
          start = start,
          end = end,
          limit = limit,
          feed = feed,
          sort = sort,
          page_token = page_token,
          asof = asof,
          currency = currency
        ),
        .parser = function(data) parse_trades(data$trades)
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_trades,
        is_async = private$.is_async
      ))
    },

    # nolint start: line_length_linter.
    #' @description
    #' Get Historical Quotes
    #'
    #' Retrieves historical quote (NBBO) data for a symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v2/stocks/{symbol}/quotes`
    #'
    #' ### Official Documentation
    #' [Historical Stock Quotes](https://docs.alpaca.markets/us/reference/stockquotesingle-1)
    #' Verified: 2026-05-22
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
    #' @param symbol (scalar<character>) ticker symbol.
    #' @param start (scalar<character> | NULL) start date/time.
    #' @param end (scalar<character> | NULL) end date/time.
    #' @param limit (scalar<count in [1, 10001[> | NULL) max quotes (1-10000,
    #'   default 1000).
    #' @param asof (scalar<character> | NULL) as-of date for symbol mapping
    #'   (`"YYYY-MM-DD"` or `"-"` to skip).
    #' @param feed (scalar<character> | NULL) `"sip"` (default), `"iex"`, `"otc"`,
    #'   `"boats"`.
    #' @param currency (scalar<character> | NULL) ISO 4217 currency. Default
    #'   `"USD"`.
    #' @param sort (scalar<character> | NULL) `"asc"` or `"desc"`.
    #' @param page_token (scalar<character> | NULL) cursor for pagination.
    #' @return (Quote | promise<Quote>) **one row per quote**. Columns:
    #'   `timestamp` (POSIXct), `ask_exchange`, `bid_exchange`, `tape`
    #'   (character), `ask_price`, `bid_price` (numeric), `ask_size`, `bid_size`
    #'   (integer), and `conditions` (character, `;`-separated quote condition
    #'   codes e.g. `"R;F"`; `NA` when no conditions were reported). Filter with
    #'   `dt[grepl("R", conditions)]` or recover via
    #'   `strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`.
    get_quotes = function(
      symbol,
      start = NULL,
      end = NULL,
      limit = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL,
      asof = NULL,
      currency = NULL
    ) {
      assert_args_AlpacaMarketData__get_quotes(
        symbol,
        start,
        end,
        limit,
        asof,
        feed,
        currency,
        sort,
        page_token
      )
      assert::assert_nonempty_strings(symbol)
      endpoint <- paste0("/v2/stocks/", symbol, "/quotes")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(
          start = start,
          end = end,
          limit = limit,
          feed = feed,
          sort = sort,
          page_token = page_token,
          asof = asof,
          currency = currency
        ),
        .parser = function(data) parse_quotes(data$quotes)
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_quotes,
        is_async = private$.is_async
      ))
    },
    # nolint end

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
    #' [Assets](https://docs.alpaca.markets/us/reference/get-v2-assets-1)
    #' Verified: 2026-05-22
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
    #' @param status (scalar<character> | NULL) filter by status (`"active"`,
    #'   `"inactive"`).
    #' @param asset_class (scalar<character> | NULL) filter by class
    #'   (`"us_equity"`, `"us_option"`, `"crypto"`).
    #' @param exchange (scalar<character> | NULL) filter by exchange (`"AMEX"`,
    #'   `"ARCA"`, `"BATS"`, `"NYSE"`, `"NASDAQ"`, `"NYSEARCA"`, `"OTC"`).
    #' @param attributes (scalar<character> | NULL) comma-separated attribute
    #'   filters. Returns assets matching any of the listed attributes. Supported
    #'   values: `"ptp_no_exception"`, `"ptp_with_exception"`, `"ipo"`,
    #'   `"has_options"`, `"options_late_close"`, `"fractional_eh_enabled"`,
    #'   `"overnight_tradable"`, `"overnight_halted"`.
    #' @return (Asset | promise<Asset>) the assets. Columns: `id`,
    #'   `class`, `exchange`, `symbol`, `name`, `status` (character); `tradable`,
    #'   `marginable`, `shortable`, `fractionable` (logical).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' assets <- market$get_assets(status = "active", asset_class = "us_equity")
    #' print(assets[1:5, .(symbol, name, exchange, tradable)])
    #' }
    get_assets = function(status = NULL, asset_class = NULL, exchange = NULL, attributes = NULL) {
      assert_args_AlpacaMarketData__get_assets(status, asset_class, exchange, attributes)
      result <- private$.request(
        endpoint = "/v2/assets",
        query = list(status = status, asset_class = asset_class, exchange = exchange, attributes = attributes),
        .parser = parse_assets
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_assets,
        is_async = private$.is_async
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
    #' [Asset by ID or Symbol](https://docs.alpaca.markets/us/reference/get-v2-assets-symbol_or_asset_id)
    #' Verified: 2026-05-22
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
    #' @param symbol_or_id (scalar<character>) ticker symbol or asset UUID.
    #' @return (Asset | promise<Asset>) the asset, with the same
    #'   columns as `get_assets()`, single row.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' aapl <- market$get_asset("AAPL")
    #' print(aapl)
    #' }
    get_asset = function(symbol_or_id) {
      assert_args_AlpacaMarketData__get_asset(symbol_or_id)
      assert::assert_nonempty_strings(symbol_or_id)
      endpoint <- paste0("/v2/assets/", symbol_or_id)
      result <- private$.request(
        endpoint = endpoint,
        .parser = parse_asset
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_asset,
        is_async = private$.is_async
      ))
    },

    # ---- Calendar & Clock ----

    # nolint start: line_length_linter.
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
    #' [Calendar](https://docs.alpaca.markets/us/reference/legacycalendar)
    #' Verified: 2026-05-21
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
    #' @param start (scalar<character> | NULL) start date (`"YYYY-MM-DD"`).
    #' @param end (scalar<character> | NULL) end date (`"YYYY-MM-DD"`).
    #' @param date_type (scalar<character> | NULL) one of `"TRADING"` or
    #'   `"SETTLEMENT"`. Determines whether `start`/`end` are interpreted as
    #'   trading dates (default) or settlement dates.
    #' @return (Calendar | promise<Calendar>) the calendar. Columns: `date`
    #'   and `settlement_date` (Date); `open`, `close`, `session_open`,
    #'   `session_close` (POSIXct, `America/New_York`).
    #'
    #' Alpaca's API returns market times without an offset; per the
    #' Alpaca docs they are Eastern Time. We localise to
    #' `America/New_York` (the named tz handles DST automatically).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' cal <- market$get_calendar(start = "2024-01-01", end = "2024-01-31")
    #' print(cal)
    #' }
    get_calendar = function(start = NULL, end = NULL, date_type = NULL) {
      assert_args_AlpacaMarketData__get_calendar(start, end, date_type)
      if (!is.null(date_type)) {
        rlang::arg_match0(date_type, c("TRADING", "SETTLEMENT"))
      }
      result <- private$.request(
        endpoint = "/v2/calendar",
        query = list(start = start, end = end, date_type = date_type),
        .parser = function(items) {
          dt <- as_dt_list(items)
          if (nrow(dt) == 0L) {
            return(empty_dt_calendar())
          }
          # Snapshot the date column before we reassign it to Date below;
          # the time-combine calls need the original "YYYY-MM-DD" character.
          d <- dt$date
          # Regular-hours open/close arrive as "HH:MM".
          coerce_cols(dt, c("open", "close"), function(x) combine_et_datetime(d, x))
          # Extended-hours session_open/session_close arrive as "HHMM"
          # (no colon) — normalise before combining.
          coerce_cols(
            dt,
            c("session_open", "session_close"),
            function(x) combine_et_datetime(d, hhmm_to_hh_mm(x))
          )
          parse_date_cols(dt, c("date", "settlement_date"))
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_calendar,
        is_async = private$.is_async
      ))
    },
    # nolint end

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
    #' [Clock](https://docs.alpaca.markets/us/reference/legacyclock)
    #' Verified: 2026-05-21
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
    #' @return (Clock | promise<Clock>) the clock. Columns:
    #'   `timestamp`, `next_open`, `next_close` (POSIXct, `America/New_York`) and
    #'   `is_open` (logical).
    #'
    #' The Alpaca clock endpoint returns ISO-8601 timestamps with an
    #' explicit offset; we parse the instant exactly and display it in
    #' `America/New_York` for consistency with `get_calendar()`. Use
    #' `lubridate::with_tz()` to view in another timezone.
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' clock <- market$get_clock()
    #' cat("Market open:", clock$is_open, "\n")
    #' }
    get_clock = function() {
      result <- private$.request(
        endpoint = "/v2/clock",
        .parser = function(x) {
          dt <- as_dt_row(x)
          coerce_cols(
            dt,
            c("timestamp", "next_open", "next_close"),
            function(v) lubridate::with_tz(rfc3339_to_datetime(v), ALPACA_EXCHANGE_TZ)
          )
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_clock,
        is_async = private$.is_async
      ))
    },

    # ---- Corporate Actions ----

    # nolint start: line_length_linter.
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
    #' [Corporate Actions](https://docs.alpaca.markets/us/reference/get-v2-corporate_actions-announcements-1)
    #' Verified: 2026-05-21
    #'
    #' Note: as of 2026-05, the `/v2/corporate_actions/announcements` endpoint is
    #' marked DEPRECATED by Alpaca. It still works and the wrapper still calls
    #' it, but Alpaca recommends migrating to the newer corporate-actions
    #' market-data endpoint (`/v1beta1/corporate-actions`). Migration is tracked
    #' as a follow-up.
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
    #' @param ca_types (scalar<character>) comma-separated corporate action
    #'   types. Valid values: `"dividend"`, `"merger"`, `"spinoff"`, `"split"`.
    #' @param since (scalar<character>) start date (`"YYYY-MM-DD"`). Required.
    #' @param until (scalar<character>) end date (`"YYYY-MM-DD"`). Required.
    #' @param symbol (scalar<character> | NULL) filter by ticker symbol.
    #' @param cusip (scalar<character> | NULL) filter by CUSIP.
    #' @param date_type (scalar<character> | NULL) which date field `since`/`until`
    #'   refer to. Alpaca's documented / SDK values are `"declaration_date"`,
    #'   `"ex_date"`, `"record_date"`, `"payable_date"` (default server-side:
    #'   `"ex_date"`). Validated client-side; invalid values abort before the
    #'   request.
    #' @return (CorporateAction | promise<CorporateAction>) the announcements.
    #'   Columns: `id`, `corporate_action_id`, `ca_type`, `ca_sub_type`,
    #'   `initiating_symbol`, `target_symbol`, `cash`, `old_rate`, `new_rate`
    #'   (character); `declaration_date`, `ex_date`, `record_date`,
    #'   `payable_date` (Date).
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
      assert_args_AlpacaMarketData__get_corporate_actions(
        ca_types,
        since,
        until,
        symbol,
        cusip,
        date_type
      )
      if (!is.null(date_type)) {
        rlang::arg_match0(
          date_type,
          c("declaration_date", "ex_date", "record_date", "payable_date")
        )
      }
      rlang::warn(
        paste0(
          "`get_corporate_actions()` wraps `/v2/corporate_actions/announcements`, ",
          "which Alpaca has flagged DEPRECATED in favour of the newer ",
          "`/v1beta1/corporate-actions` market-data endpoint. The wrapper still ",
          "works today but migration is recommended."
        ),
        .frequency = "regularly",
        .frequency_id = "get_corporate_actions_deprecated"
      )
      result <- private$.request(
        endpoint = "/v2/corporate_actions/announcements",
        query = list(
          ca_types = ca_types,
          since = since,
          until = until,
          symbol = symbol,
          cusip = cusip,
          date_type = date_type
        ),
        .parser = function(items) {
          if (is.null(items) || length(items) == 0) {
            return(empty_dt_corporate_actions())
          }
          dt <- as_dt_list(items)
          parse_date_cols(
            dt,
            c(
              "declaration_date",
              "ex_date",
              "record_date",
              "payable_date"
            )
          )
          return(dt)
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_corporate_actions,
        is_async = private$.is_async
      ))
    },
    # nolint end

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
    #' [News](https://docs.alpaca.markets/us/reference/news-3)
    #' Verified: 2026-05-22
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
    #' @param symbols (character | NULL) comma-separated symbols to filter
    #'   (e.g., `"AAPL,MSFT"`), or a character vector of symbols.
    #' @param start (scalar<character> | NULL) start date/time (RFC-3339).
    #' @param end (scalar<character> | NULL) end date/time (RFC-3339).
    #' @param limit (scalar<count in [1, Inf[> | NULL) max articles (default 10,
    #'   max 50 server-side).
    #' @param sort (scalar<character> | NULL) `"desc"` (default, newest first) or
    #'   `"asc"`.
    #' @param include_content (scalar<logical> | NULL) if `TRUE`, include full
    #'   article content.
    #' @param exclude_contentless (scalar<logical> | NULL) if `TRUE`, exclude
    #'   articles without content.
    #' @param page_token (scalar<character> | NULL) cursor for pagination.
    #' @return (News | promise<News>) **one row per article**.
    #'   Columns: `id` (integer); `headline`, `author`, `source`, `summary`,
    #'   `url` (character); `created_at`, `updated_at` (POSIXct, UTC); `symbols`
    #'   (character, `;`-separated related tickers, e.g. `"AAPL;MSFT"`);
    #'   `image_sizes` (character, `;`-separated image size labels parallel to
    #'   `image_urls`, `NA` when the article has no images — missing per-image
    #'   sizes become empty tokens e.g. `"large;"`, never the literal `"NA"`);
    #'   and `image_urls` (character, `;`-separated image URLs, losslessly
    #'   double-encoded `%` → `%25` then `;` → `%3B` so a single `URLdecode()`
    #'   after splitting recovers the original). Filter symbols with
    #'   `dt[grepl("AAPL", symbols)]`; recover URLs with
    #'   `vapply(strsplit(dt$image_urls[1], ";", fixed = TRUE)[[1]], URLdecode, character(1))`.
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
      assert_args_AlpacaMarketData__get_news(
        symbols,
        start,
        end,
        limit,
        sort,
        include_content,
        exclude_contentless,
        page_token
      )
      # Join symbols with comma like other multi-symbol methods
      if (!is.null(symbols) && length(symbols) > 1) {
        symbols <- paste(symbols, collapse = ",")
      }
      result <- private$.data_request(
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
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_news,
        is_async = private$.is_async
      ))
    },

    # ---- Crypto Orderbook ----

    #' @description
    #' Get Latest Crypto Orderbook
    #'
    #' Retrieves the latest orderbook (top of book) for a crypto symbol.
    #'
    #' ### API Endpoint
    #' `GET https://data.alpaca.markets/v1beta3/crypto/{loc}/latest/orderbooks`
    #'
    #' ### Official Documentation
    #' [Latest Crypto Orderbooks](https://docs.alpaca.markets/us/reference/cryptolatestorderbooks-1)
    #' Verified: 2026-05-22
    #'
    #' ### curl
    #' ```
    #' curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
    #'   'https://data.alpaca.markets/v1beta3/crypto/us/latest/orderbooks?symbols=BTC/USD'
    #' ```
    #'
    #' ### JSON Response
    #' ```json
    #' {
    #'   "orderbooks": {
    #'     "BTC/USD": {
    #'       "t": "2024-01-15T20:00:00.123456Z",
    #'       "b": [
    #'         {"p": 42950.50, "s": 0.5},
    #'         {"p": 42949.00, "s": 1.2}
    #'       ],
    #'       "a": [
    #'         {"p": 42951.00, "s": 0.3},
    #'         {"p": 42952.50, "s": 0.8}
    #'       ]
    #'     }
    #'   }
    #' }
    #' ```
    #'
    #' @param symbols (character) crypto symbols (e.g. `"BTC/USD"`).
    #' @param loc (scalar<character>) location code, `"us"` (default).
    #' @return (CryptoOrderbook | promise<CryptoOrderbook>) one row per
    #'   `(symbol, side, level)`. Columns: `symbol`, `side` (`"bid"` or `"ask"`)
    #'   (character); `level` (integer, 1-based depth within the side — `level = 1`
    #'   is top of book, ordering preserved from the Alpaca response); `price`,
    #'   `size` (numeric); and `timestamp` (POSIXct).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' ob <- market$get_crypto_orderbook("BTC/USD")
    #' print(ob)
    #' }
    get_crypto_orderbook = function(symbols, loc = "us") {
      assert_args_AlpacaMarketData__get_crypto_orderbook(symbols, loc)
      if (length(symbols) > 1) {
        symbols <- paste(symbols, collapse = ",")
      }
      endpoint <- paste0("/v1beta3/crypto/", loc, "/latest/orderbooks")
      result <- private$.data_request(
        endpoint = endpoint,
        query = list(symbols = symbols),
        .parser = function(data) {
          ob_map <- data$orderbooks
          if (is.null(ob_map) || length(ob_map) == 0) {
            return(data.table::data.table(
              symbol = character(),
              side = character(),
              level = integer(),
              price = numeric(),
              size = numeric(),
              timestamp = lubridate::as_datetime(character(), tz = "UTC")
            ))
          }
          dts <- lapply(names(ob_map), function(sym) {
            ob <- ob_map[[sym]]
            ts <- rfc3339_to_datetime(ob$t)
            rows <- list()
            if (!is.null(ob$b) && length(ob$b) > 0) {
              bids <- data.table::rbindlist(ob$b)
              data.table::setnames(bids, c("p", "s"), c("price", "size"))
              # `level` is 1-based depth from the top of book. .I after
              # rbindlist preserves the Alpaca response's level ordering.
              bids[, `:=`(symbol = sym, side = "bid", level = .I, timestamp = ts)]
              rows <- c(rows, list(bids))
            }
            if (!is.null(ob$a) && length(ob$a) > 0) {
              asks <- data.table::rbindlist(ob$a)
              data.table::setnames(asks, c("p", "s"), c("price", "size"))
              asks[, `:=`(symbol = sym, side = "ask", level = .I, timestamp = ts)]
              rows <- c(rows, list(asks))
            }
            if (length(rows) == 0) {
              return(data.table::data.table())
            }
            return(data.table::rbindlist(rows, fill = TRUE))
          })
          dt <- data.table::rbindlist(dts, fill = TRUE)
          if (nrow(dt) > 0 && "symbol" %in% names(dt)) {
            data.table::setcolorder(dt, c("symbol", "side", "level", "price", "size", "timestamp"))
          }
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_crypto_orderbook,
        is_async = private$.is_async
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
    #' [Most Active Stocks](https://docs.alpaca.markets/us/reference/mostactives-1)
    #' Verified: 2026-05-21
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
    #' @param by (scalar<character> | NULL) ranking metric: `"volume"` (default)
    #'   or `"trades"`.
    #' @param top (scalar<count in [1, Inf[> | NULL) number of results to return
    #'   (default 10).
    #' @return (MostActives | promise<MostActives>) the most active stocks.
    #'   Columns: `symbol` (character); `volume`, `trade_count` (count — the
    #'   parser coerces both whole-number counters to a `numeric` double so a
    #'   large volume cannot overflow `integer`).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' actives <- market$get_most_actives(by = "volume", top = 20)
    #' print(actives)
    #' }
    get_most_actives = function(by = NULL, top = NULL) {
      assert_args_AlpacaMarketData__get_most_actives(by, top)
      result <- private$.data_request(
        endpoint = "/v1beta1/screener/stocks/most-actives",
        query = list(by = by, top = top),
        .parser = function(data) {
          if (is.null(data$most_actives) || length(data$most_actives) == 0) {
            return(empty_dt_most_actives())
          }
          dt <- as_dt_list(data$most_actives)
          # `volume` / `trade_count` are whole-number counters; coerce both to a
          # clean `numeric` double so a large volume cannot overflow `integer`.
          coerce_cols(dt, c("volume", "trade_count"), as.numeric)
          return(dt[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_most_actives,
        is_async = private$.is_async
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
    #' [Top Market Movers](https://docs.alpaca.markets/us/reference/movers-1)
    #' Verified: 2026-05-21
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
    #' @param market_type (scalar<character>) `"stocks"` (default) or `"crypto"`.
    #' @param top (scalar<count in [1, Inf[> | NULL) number of results per
    #'   direction (default 10).
    #' @return (Movers | promise<Movers>) the movers. Columns: `symbol`
    #'   (character); `percent_change`, `change`, `price` (numeric); plus a
    #'   `direction` column (`"gainer"` / `"loser"`).
    #'
    #' @examples
    #' \dontrun{
    #' market <- AlpacaMarketData$new()
    #' movers <- market$get_movers(top = 5)
    #' print(movers)
    #' }
    get_movers = function(market_type = "stocks", top = NULL) {
      assert_args_AlpacaMarketData__get_movers(market_type, top)
      endpoint <- paste0("/v1beta1/screener/", market_type, "/movers")
      result <- private$.data_request(
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
            return(empty_dt_movers())
          }
          return(data.table::rbindlist(dts, fill = TRUE)[])
        }
      )
      return(connectcore::then_or_now(
        result,
        assert_return_AlpacaMarketData__get_movers,
        is_async = private$.is_async
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
