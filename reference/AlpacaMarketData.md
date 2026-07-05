# AlpacaMarketData: Market Data, Assets, Calendar, and Clock

AlpacaMarketData: Market Data, Assets, Calendar, and Clock

AlpacaMarketData: Market Data, Assets, Calendar, and Clock

## Details

Provides methods for retrieving market data from Alpaca's REST API,
including historical bars (OHLCV), latest quotes/trades, snapshots,
asset info, market calendar, and clock.

Inherits from
[AlpacaBase](https://dereckscompany.github.io/alpaca/reference/AlpacaBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Bars**: Retrieve historical OHLCV candlestick data for stocks.

- **Trades**: Access historical and latest trade data.

- **Quotes**: Access historical and latest quote (NBBO) data.

- **Snapshots**: Get real-time snapshot of a symbol's latest state.

- **Assets**: Query available tradeable assets and their metadata.

- **Calendar**: Get market open/close schedule.

- **Clock**: Check current market status (open/closed).

- **Corporate Actions**: Query dividends, splits, mergers, spinoffs.

- **News**: Retrieve market news articles filtered by symbol/date.

- **Screener**: Most active stocks, top market movers.

### Base URLs

Market data endpoints use `https://data.alpaca.markets` by default.
Trading-related endpoints (assets, calendar, clock) use the trading base
URL. Both are configurable via constructor parameters.

### Official Documentation

- [Market Data
  API](https://docs.alpaca.markets/us/docs/about-market-data-api)

- [Historical Stock
  Data](https://docs.alpaca.markets/us/docs/historical-stock-data-1)

### Endpoints Covered

|  |  |  |
|----|----|----|
| Method | Endpoint | Base |
| get_bars | `GET /v2/stocks/\{symbol\}/bars` | data |
| get_bars_multi | `GET /v2/stocks/bars` | data |
| get_latest_bar | `GET /v2/stocks/\{symbol\}/bars/latest` | data |
| get_latest_trade | `GET /v2/stocks/\{symbol\}/trades/latest` | data |
| get_latest_quote | `GET /v2/stocks/\{symbol\}/quotes/latest` | data |
| get_snapshot | `GET /v2/stocks/\{symbol\}/snapshot` | data |
| get_trades | `GET /v2/stocks/\{symbol\}/trades` | data |
| get_quotes | `GET /v2/stocks/\{symbol\}/quotes` | data |
| get_assets | `GET /v2/assets` | trading |
| get_asset | `GET /v2/assets/\{symbol\}` | trading |
| get_calendar | `GET /v2/calendar` | trading |
| get_clock | `GET /v2/clock` | trading |
| get_corporate_actions | `GET /v2/corporate_actions/announcements` | trading |
| get_news | `GET /v1beta1/news` | data |
| get_latest_bars_multi | `GET /v2/stocks/bars/latest` | data |
| get_latest_trades_multi | `GET /v2/stocks/trades/latest` | data |
| get_latest_quotes_multi | `GET /v2/stocks/quotes/latest` | data |
| get_snapshots_multi | `GET /v2/stocks/snapshots` | data |
| get_most_actives | `GET /v1beta1/screener/stocks/most-actives` | data |
| get_movers | `GET /v1beta1/screener/\{market_type\}/movers` | data |

### Timezones

This client wraps Alpaca's `/v2/` market-data endpoints, which are
US-only. All returned date / time columns are coerced to `Date` or
`POSIXct` for ergonomic use:

- Endpoints whose JSON carries an explicit RFC-3339 offset (bars,
  trades, quotes, news, snapshots, clock) are parsed at the exact
  instant. Clock is displayed in `America/New_York`; bars / trades /
  quotes / news in UTC. Use
  [`lubridate::with_tz()`](https://lubridate.tidyverse.org/reference/with_tz.html)
  to view in any other timezone.

- The calendar endpoint returns *naive* wall-clock times (`"09:30"`,
  `"0400"`) with no offset in the payload. Alpaca does **not**
  explicitly document the timezone on the calendar reference page, but
  the values are Eastern Time by inference (US-only venues, `09:30`
  matches the NYSE/NASDAQ open, every other SDK treats them as ET, and
  the market-data FAQ confirms NY tz for bar aggregation). We localise
  with the named tz `America/New_York`, so DST transitions flip
  automatically.

This assumption is safe for `/v2/`. When Alpaca's `/v3/` multi-market
endpoints are adopted, per-market timezone lookup will replace the
single hard-coded tz. The constant lives in `R/helpers_parse.R` (search
for `TODO(v3)`).

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`alpaca::AlpacaBase`](https://dereckscompany.github.io/alpaca/reference/AlpacaBase.md)
-\> `AlpacaMarketData`

## Methods

### Public methods

- [`AlpacaMarketData$new()`](#method-AlpacaMarketData-new)

- [`AlpacaMarketData$get_bars()`](#method-AlpacaMarketData-get_bars)

- [`AlpacaMarketData$get_bars_multi()`](#method-AlpacaMarketData-get_bars_multi)

- [`AlpacaMarketData$get_latest_bar()`](#method-AlpacaMarketData-get_latest_bar)

- [`AlpacaMarketData$get_latest_trade()`](#method-AlpacaMarketData-get_latest_trade)

- [`AlpacaMarketData$get_latest_quote()`](#method-AlpacaMarketData-get_latest_quote)

- [`AlpacaMarketData$get_snapshot()`](#method-AlpacaMarketData-get_snapshot)

- [`AlpacaMarketData$get_latest_bars_multi()`](#method-AlpacaMarketData-get_latest_bars_multi)

- [`AlpacaMarketData$get_latest_trades_multi()`](#method-AlpacaMarketData-get_latest_trades_multi)

- [`AlpacaMarketData$get_latest_quotes_multi()`](#method-AlpacaMarketData-get_latest_quotes_multi)

- [`AlpacaMarketData$get_snapshots_multi()`](#method-AlpacaMarketData-get_snapshots_multi)

- [`AlpacaMarketData$get_trades()`](#method-AlpacaMarketData-get_trades)

- [`AlpacaMarketData$get_quotes()`](#method-AlpacaMarketData-get_quotes)

- [`AlpacaMarketData$get_assets()`](#method-AlpacaMarketData-get_assets)

- [`AlpacaMarketData$get_asset()`](#method-AlpacaMarketData-get_asset)

- [`AlpacaMarketData$get_calendar()`](#method-AlpacaMarketData-get_calendar)

- [`AlpacaMarketData$get_clock()`](#method-AlpacaMarketData-get_clock)

- [`AlpacaMarketData$get_corporate_actions()`](#method-AlpacaMarketData-get_corporate_actions)

- [`AlpacaMarketData$get_news()`](#method-AlpacaMarketData-get_news)

- [`AlpacaMarketData$get_crypto_orderbook()`](#method-AlpacaMarketData-get_crypto_orderbook)

- [`AlpacaMarketData$get_most_actives()`](#method-AlpacaMarketData-get_most_actives)

- [`AlpacaMarketData$get_movers()`](#method-AlpacaMarketData-get_movers)

- [`AlpacaMarketData$clone()`](#method-AlpacaMarketData-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise an AlpacaMarketData Object

Creates a new `AlpacaMarketData` instance for querying market data,
assets, calendar, and clock from Alpaca's REST API.

#### API Endpoint

No HTTP request is made during construction. The object stores
credentials and base URLs for subsequent method calls.

#### Official Documentation

- [Authentication](https://docs.alpaca.markets/us/docs/getting-started)
  Verified: 2026-05-21

#### curl

    # No request at construction. Verify credentials with the clock endpoint:
    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/clock'

#### JSON Response

    # (No response — constructor does not call an endpoint)

#### Usage

    AlpacaMarketData$new(
      keys = get_api_keys(),
      base_url = get_base_url(),
      data_base_url = get_data_base_url(),
      async = FALSE
    )

#### Arguments

- `keys`:

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) trading API base URL. Defaults to
  [`get_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_base_url.md).

- `data_base_url`:

  (scalar\<character\>) market data API base URL. Defaults to
  [`get_data_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_data_base_url.md).

- `async`:

  (scalar\<logical\>) if `TRUE`, methods return promises. Default
  `FALSE`.

#### Returns

(class\<AlpacaMarketData\>) invisibly, self.

------------------------------------------------------------------------

### Method `get_bars()`

Get Historical Bars (OHLCV)

Retrieves historical candlestick/bar data for a single symbol. Bars
include open, high, low, close, volume, trade count, and VWAP.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/bars`

#### Official Documentation

[Historical Stock
Bars](https://docs.alpaca.markets/us/reference/stockbarsingle-1)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/bars?timeframe=1Day&start=2024-01-01'

#### JSON Response

    {
      "bars": [
        {"t": "2024-01-02T05:00:00Z", "o": 187.15, "h": 188.44, "l": 183.89, "c": 185.64, "v": 82488700, "n": 1036517, "vw": 185.831}
      ],
      "symbol": "AAPL",
      "next_page_token": null
    }

#### Usage

    AlpacaMarketData$get_bars(
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
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol (e.g., `"AAPL"`).

- `timeframe`:

  (scalar\<character\>) bar timeframe. Valid values: `"1Min"` to
  `"59Min"`, `"1Hour"` to `"23Hour"`, `"1Day"`, `"1Week"`, `"1Month"` to
  `"12Month"`.

- `start`:

  (scalar\<character\> \| NULL) start date/time (RFC-3339 or
  `"YYYY-MM-DD"`).

- `end`:

  (scalar\<character\> \| NULL) end date/time.

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max bars **per page**
  (1-10000, default 10000). The method auto-paginates via
  `next_page_token`, so the full `start`..`end` range is returned
  regardless of `limit`; this only sets the page size (and thus the
  number of requests).

- `adjustment`:

  (scalar\<character\> \| NULL) price adjustment type. One or a
  comma-separated combination of: `"raw"`, `"split"`, `"dividend"`,
  `"spin-off"`, `"all"`. Default `"raw"`.

- `feed`:

  (scalar\<character\> \| NULL) data feed source: `"sip"` (default, all
  US exchanges), `"iex"`, `"otc"`, `"boats"`.

- `sort`:

  (scalar\<character\> \| NULL) `"asc"` (default) or `"desc"`.

- `page_token`:

  (scalar\<character\> \| NULL) starting cursor. Normally left NULL —
  auto-pagination begins at `start` and follows the cursor itself.

- `asof`:

  (scalar\<character\> \| NULL) as-of date (`"YYYY-MM-DD"`) used to
  identify the underlying entity when symbols have been renamed (e.g. FB
  -\> META). Pass `"-"` to skip symbol mapping.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency for returned prices.
  Default `"USD"`.

- `max_pages`:

  (scalar\<numeric in \[1, Inf\]\> \| scalar\<integer in \[1, Inf\[\>)
  cap on pages fetched (runaway guard). Default 1000 — high enough that
  real requests complete, low enough to bound a fat-fingered pull. Pass
  `Inf` for unbounded. If hit while more data remains, the partial
  result is returned with a
  [`warning()`](https://rdrr.io/r/base/warning.html).

- `sleep`:

  (scalar\<numeric in \[0, Inf\[\>) seconds to pause between page
  requests (rate-limit throttle; sync only). Default 0.3.

#### Returns

(Bars \| promise\<Bars\>) the bars. Columns: `datetime` (POSIXct, UTC),
`open`, `high`, `low`, `close`, `vwap` (numeric), and `volume`,
`trade_count` (integer).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    bars <- market$get_bars("AAPL", "1Day", start = "2024-01-01", end = "2024-01-31")
    print(bars)
    }

------------------------------------------------------------------------

### Method `get_bars_multi()`

Get Historical Bars for Multiple Symbols

Retrieves historical bar data for multiple symbols in a single request.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/bars`

#### Official Documentation

[Multi Stock Bars](https://docs.alpaca.markets/us/reference/stockbars)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/bars?symbols=AAPL,MSFT&timeframe=1Day&start=2024-01-01&limit=2'

#### JSON Response

    {
      "bars": {
        "AAPL": [
          {"t": "2024-01-02T05:00:00Z", "o": 187.15, "h": 188.44, "l": 183.89, "c": 185.64, "v": 82488700, "n": 1036517, "vw": 185.831}
        ],
        "MSFT": [
          {"t": "2024-01-02T05:00:00Z", "o": 373.86, "h": 376.04, "l": 371.34, "c": 374.72, "v": 22622100, "n": 345678, "vw": 374.12}
        ]
      },
      "next_page_token": null
    }

#### Usage

    AlpacaMarketData$get_bars_multi(
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
    )

#### Arguments

- `symbols`:

  (character) ticker symbols (max 100).

- `timeframe`:

  (scalar\<character\>) bar timeframe (see `get_bars()` for valid
  values).

- `start`:

  (scalar\<character\> \| NULL) start date/time.

- `end`:

  (scalar\<character\> \| NULL) end date/time.

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max bars **per page**
  (1-10000, default 10000). NOTE: Alpaca applies this as a *total row
  budget across all requested symbols per page* (not per symbol),
  filling symbols alphabetically. The method auto-paginates via
  `next_page_token`, so the full range for every symbol is returned
  regardless of `limit`.

- `adjustment`:

  (scalar\<character\> \| NULL) one or comma-separated combination of
  `"raw"`, `"split"`, `"dividend"`, `"spin-off"`, `"all"`.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`, `"otc"`,
  `"boats"`.

- `sort`:

  (scalar\<character\> \| NULL) `"asc"` or `"desc"`.

- `page_token`:

  (scalar\<character\> \| NULL) starting cursor. Normally left NULL —
  auto-pagination begins at `start` and follows the cursor itself.

- `asof`:

  (scalar\<character\> \| NULL) as-of date for symbol mapping
  (`"YYYY-MM-DD"` or `"-"` to skip).

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

- `max_pages`:

  (scalar\<numeric in \[1, Inf\]\> \| scalar\<integer in \[1, Inf\[\>)
  cap on pages fetched (runaway guard). Default 1000; pass `Inf` for
  unbounded. If hit while more data remains, the partial result is
  returned with a [`warning()`](https://rdrr.io/r/base/warning.html).

- `sleep`:

  (scalar\<numeric in \[0, Inf\[\>) seconds to pause between page
  requests (rate-limit throttle; sync only). Default 0.3.

#### Returns

(BarsMulti \| promise\<BarsMulti\>) the bars, with a `symbol` column
prepended plus the same columns as `get_bars()`.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    bars <- market$get_bars_multi(c("AAPL", "MSFT"), "1Day", start = "2024-01-01")
    print(bars)
    }

------------------------------------------------------------------------

### Method `get_latest_bar()`

Get Latest Bar

Retrieves the most recent bar for a single symbol.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/bars/latest`

#### Official Documentation

[Latest Stock
Bar](https://docs.alpaca.markets/us/reference/stocklatestbarsingle-1)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/bars/latest'

#### JSON Response

    {
      "bar": {
        "t": "2024-01-15T20:59:00Z",
        "o": 185.30,
        "h": 185.45,
        "l": 185.20,
        "c": 185.42,
        "v": 1234567,
        "n": 15432,
        "vw": 185.35
      },
      "symbol": "AAPL"
    }

#### Usage

    AlpacaMarketData$get_latest_bar(symbol, feed = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol.

- `feed`:

  (scalar\<character\> \| NULL) `"iex"` or `"sip"`.

#### Returns

(Bars \| promise\<Bars\>) the bar, with the same columns as
`get_bars()`, single row.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    bar <- market$get_latest_bar("AAPL")
    print(bar)
    }

------------------------------------------------------------------------

### Method `get_latest_trade()`

Get Latest Trade

Retrieves the most recent trade for a symbol.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/trades/latest`

#### Official Documentation

[Latest
Trade](https://docs.alpaca.markets/us/reference/stocklatesttradesingle-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/trades/latest'

#### JSON Response

    {
      "trade": {
        "t": "2024-01-15T20:00:00.123456Z",
        "x": "V",
        "p": 185.64,
        "s": 100,
        "c": ["@"],
        "i": 12345,
        "z": "C"
      },
      "symbol": "AAPL"
    }

#### Usage

    AlpacaMarketData$get_latest_trade(symbol, feed = NULL, currency = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(Trade \| promise\<Trade\>) **one row per trade** (a single row for this
single-trade method). Columns: `timestamp` (POSIXct), `price` (numeric),
`size` (integer), `exchange` (character), `tape` (character), `id`
(integer), and `conditions` (character, semicolon-separated condition
codes e.g. `"@;T"`; `NA` when the trade carries no condition codes).
Filter with `dt[grepl("T", conditions)]`; recover the original vector
via `strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    trade <- market$get_latest_trade("AAPL")
    print(trade)
    }

------------------------------------------------------------------------

### Method `get_latest_quote()`

Get Latest Quote (NBBO)

Retrieves the most recent National Best Bid and Offer for a symbol.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/quotes/latest`

#### Official Documentation

[Latest
Quote](https://docs.alpaca.markets/us/reference/stocklatestquotesingle-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/quotes/latest'

#### JSON Response

    {
      "quote": {
        "t": "2024-01-15T20:00:00.000123Z",
        "ax": "Q",
        "ap": 185.65,
        "as": 3,
        "bx": "K",
        "bp": 185.63,
        "bs": 2,
        "c": ["R"],
        "z": "C"
      },
      "symbol": "AAPL"
    }

#### Usage

    AlpacaMarketData$get_latest_quote(symbol, feed = NULL, currency = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(Quote \| promise\<Quote\>) **one row per quote**. Columns: `timestamp`
(POSIXct), `ask_exchange`, `bid_exchange`, `tape` (character),
`ask_price`, `bid_price` (numeric), `ask_size`, `bid_size` (integer),
and `conditions` (character, `;`-separated quote condition codes e.g.
`"R;F"`; `NA` when no conditions were reported). Filter with
`dt[grepl("R", conditions)]` or recover via
`strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    quote <- market$get_latest_quote("AAPL")
    print(quote)
    }

------------------------------------------------------------------------

### Method `get_snapshot()`

Get Snapshot

Retrieves the latest snapshot for a symbol including latest trade,
latest quote, minute bar, daily bar, and previous daily bar.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/snapshot`

#### Official Documentation

[Stock
Snapshot](https://docs.alpaca.markets/us/reference/stocksnapshotsingle)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/snapshot'

#### JSON Response

    {
      "latestTrade": {"t": "2024-01-15T20:00:00Z", "x": "V", "p": 185.64, "s": 100, "c": ["@"], "i": 12345, "z": "C"},
      "latestQuote": {"t": "2024-01-15T20:00:00Z", "ax": "Q", "ap": 185.65, "as": 3, "bx": "K", "bp": 185.63, "bs": 2, "c": ["R"], "z": "C"},
      "minuteBar": {"t": "2024-01-15T19:59:00Z", "o": 185.50, "h": 185.65, "l": 185.40, "c": 185.60, "v": 45230, "n": 312, "vw": 185.52},
      "dailyBar": {"t": "2024-01-15T05:00:00Z", "o": 184.20, "h": 186.10, "l": 183.80, "c": 185.64, "v": 56789012, "n": 678901, "vw": 185.12},
      "prevDailyBar": {"t": "2024-01-12T05:00:00Z", "o": 185.60, "h": 186.00, "l": 184.50, "c": 185.59, "v": 48234567, "n": 543210, "vw": 185.30}
    }

#### Usage

    AlpacaMarketData$get_snapshot(symbol, feed = NULL, currency = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(Snapshot \| promise\<Snapshot\>) the flattened snapshot fields
(prefixed by section name).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    snap <- market$get_snapshot("AAPL")
    print(snap)
    }

------------------------------------------------------------------------

### Method `get_latest_bars_multi()`

Get Latest Bars for Multiple Symbols

Retrieves the most recent bar for multiple symbols in a single request.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/bars/latest`

#### Official Documentation

[Latest Multi
Bars](https://docs.alpaca.markets/us/reference/stocklatestbars-1)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/bars/latest?symbols=AAPL,MSFT'

#### JSON Response

    {
      "bars": {
        "AAPL": {"t": "2024-01-15T20:59:00Z", "o": 185.30, "h": 185.45, "l": 185.20, "c": 185.42, "v": 1234567, "n": 15432, "vw": 185.35},
        "MSFT": {"t": "2024-01-15T20:59:00Z", "o": 420.10, "h": 420.50, "l": 419.80, "c": 420.35, "v": 987654, "n": 12345, "vw": 420.22}
      }
    }

#### Usage

    AlpacaMarketData$get_latest_bars_multi(symbols, feed = NULL, currency = NULL)

#### Arguments

- `symbols`:

  (character) ticker symbols.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(BarsMulti \| promise\<BarsMulti\>) the bars, with a `symbol` column and
the same columns as `get_bars()`.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    bars <- market$get_latest_bars_multi(c("AAPL", "MSFT"))
    print(bars)
    }

------------------------------------------------------------------------

### Method `get_latest_trades_multi()`

Get Latest Trades for Multiple Symbols

Retrieves the most recent trade for multiple symbols in a single
request.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/trades/latest`

#### Official Documentation

[Latest Multi
Trades](https://docs.alpaca.markets/us/reference/stocklatesttrades-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/trades/latest?symbols=AAPL,MSFT'

#### JSON Response

    {
      "trades": {
        "AAPL": {"t": "2024-01-15T20:00:00.123456Z", "x": "V", "p": 185.64, "s": 100, "c": ["@"], "i": 12345, "z": "C"},
        "MSFT": {"t": "2024-01-15T20:00:00.654321Z", "x": "Q", "p": 420.72, "s": 50, "c": ["@"], "i": 67890, "z": "C"}
      }
    }

#### Usage

    AlpacaMarketData$get_latest_trades_multi(symbols, feed = NULL, currency = NULL)

#### Arguments

- `symbols`:

  (character) ticker symbols.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(TradesMulti \| promise\<TradesMulti\>) the trades, with a leading
`symbol` column and the same per-trade columns as `get_latest_trade()`:
`timestamp`, `price`, `size`, `exchange`, `conditions` (`;`-collapsed),
`tape`, `id`. One row per symbol.

------------------------------------------------------------------------

### Method `get_latest_quotes_multi()`

Get Latest Quotes for Multiple Symbols

Retrieves the most recent NBBO quote for multiple symbols in a single
request.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/quotes/latest`

#### Official Documentation

[Latest Multi
Quotes](https://docs.alpaca.markets/us/reference/stocklatestquotes-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/quotes/latest?symbols=AAPL,MSFT'

#### JSON Response

    {
      "quotes": {
        "AAPL": {"t": "2024-01-15T20:00:00Z", "ax": "Q", "ap": 185.65, "as": 3, "bx": "K", "bp": 185.63, "bs": 2, "c": ["R"], "z": "C"},
        "MSFT": {"t": "2024-01-15T20:00:00Z", "ax": "N", "ap": 420.75, "as": 1, "bx": "P", "bp": 420.70, "bs": 4, "c": ["R"], "z": "C"}
      }
    }

#### Usage

    AlpacaMarketData$get_latest_quotes_multi(symbols, feed = NULL, currency = NULL)

#### Arguments

- `symbols`:

  (character) ticker symbols.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(QuotesMulti \| promise\<QuotesMulti\>) the quotes, with a `symbol`
column and quote columns (`timestamp`, `ask_*`, `bid_*`, `conditions`,
`tape`). `conditions` is a `;`-separated character column following the
package's array-collapse convention.

------------------------------------------------------------------------

### Method `get_snapshots_multi()`

Get Snapshots for Multiple Symbols

Retrieves real-time snapshots for multiple symbols in a single request.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/snapshots`

#### Official Documentation

[Multi Stock
Snapshots](https://docs.alpaca.markets/us/reference/stocksnapshots-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/snapshots?symbols=AAPL,MSFT'

#### JSON Response

    {
      "AAPL": {
        "latestTrade": {"t": "2024-01-15T20:00:00Z", "x": "V", "p": 185.64, "s": 100, "c": ["@"], "i": 12345, "z": "C"},
        "latestQuote": {"t": "2024-01-15T20:00:00Z", "ax": "Q", "ap": 185.65, "as": 3, "bx": "K", "bp": 185.63, "bs": 2, "c": ["R"], "z": "C"},
        "minuteBar": {"t": "2024-01-15T19:59:00Z", "o": 185.50, "h": 185.65, "l": 185.40, "c": 185.60, "v": 45230, "n": 312, "vw": 185.52},
        "dailyBar": {"t": "2024-01-15T05:00:00Z", "o": 184.20, "h": 186.10, "l": 183.80, "c": 185.64, "v": 56789012, "n": 678901, "vw": 185.12},
        "prevDailyBar": {"t": "2024-01-12T05:00:00Z", "o": 185.60, "h": 186.00, "l": 184.50, "c": 185.59, "v": 48234567, "n": 543210, "vw": 185.30}
      },
      "MSFT": {
        "latestTrade": {"t": "2024-01-15T20:00:00Z", "x": "Q", "p": 420.72, "s": 50, "c": ["@"], "i": 67890, "z": "C"},
        "latestQuote": {"t": "2024-01-15T20:00:00Z", "ax": "N", "ap": 420.75, "as": 1, "bx": "P", "bp": 420.70, "bs": 4, "c": ["R"], "z": "C"},
        "minuteBar": {"t": "2024-01-15T19:59:00Z", "o": 420.30, "h": 420.80, "l": 420.20, "c": 420.65, "v": 32100, "n": 245, "vw": 420.50},
        "dailyBar": {"t": "2024-01-15T05:00:00Z", "o": 419.50, "h": 421.00, "l": 418.80, "c": 420.72, "v": 23456789, "n": 345678, "vw": 420.10},
        "prevDailyBar": {"t": "2024-01-12T05:00:00Z", "o": 420.00, "h": 421.50, "l": 419.00, "c": 420.45, "v": 21345678, "n": 312345, "vw": 420.25}
      }
    }

#### Usage

    AlpacaMarketData$get_snapshots_multi(symbols, feed = NULL, currency = NULL)

#### Arguments

- `symbols`:

  (character) ticker symbols.

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`,
  `"delayed_sip"`, `"otc"`, `"boats"`, `"overnight"`.

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(SnapshotMulti \| promise\<SnapshotMulti\>) the snapshots, with a
`symbol` column and flattened snapshot fields.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    snaps <- market$get_snapshots_multi(c("AAPL", "MSFT", "GOOGL"))
    print(snaps)
    }

------------------------------------------------------------------------

### Method `get_trades()`

Get Historical Trades

Retrieves historical trade data for a symbol.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/trades`

#### Official Documentation

[Historical Stock
Trades](https://docs.alpaca.markets/us/reference/stocktradesingle-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/trades?start=2024-01-15&limit=3'

#### JSON Response

    {
      "trades": [
        {"t": "2024-01-15T09:30:00.123456Z", "x": "V", "p": 184.25, "s": 200, "c": ["@", "T"], "i": 10001, "z": "C"},
        {"t": "2024-01-15T09:30:00.234567Z", "x": "Q", "p": 184.30, "s": 100, "c": ["@"], "i": 10002, "z": "C"},
        {"t": "2024-01-15T09:30:00.345678Z", "x": "N", "p": 184.28, "s": 50, "c": ["@"], "i": 10003, "z": "C"}
      ],
      "symbol": "AAPL",
      "next_page_token": "QUFQTHwyMDI0LTAxLTE1VDA5OjMwOjAwLjM0NTY3OFp8MTAwMDM="
    }

#### Usage

    AlpacaMarketData$get_trades(
      symbol,
      start = NULL,
      end = NULL,
      limit = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL,
      asof = NULL,
      currency = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol.

- `start`:

  (scalar\<character\> \| NULL) start date/time.

- `end`:

  (scalar\<character\> \| NULL) end date/time.

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max trades (1-10000, default
  1000).

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`, `"otc"`,
  `"boats"`.

- `sort`:

  (scalar\<character\> \| NULL) `"asc"` or `"desc"`.

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

- `asof`:

  (scalar\<character\> \| NULL) as-of date for symbol mapping
  (`"YYYY-MM-DD"` or `"-"` to skip).

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(Trade \| promise\<Trade\>) **one row per trade**. Columns: `timestamp`
(POSIXct), `price` (numeric), `size` (integer), `exchange` (character),
`tape` (character), `id` (integer), and `conditions` (character,
semicolon-separated condition codes e.g. `"@;T"`). Filter with
`dt[grepl("T", conditions)]`.

------------------------------------------------------------------------

### Method `get_quotes()`

Get Historical Quotes

Retrieves historical quote (NBBO) data for a symbol.

#### API Endpoint

`GET https://data.alpaca.markets/v2/stocks/{symbol}/quotes`

#### Official Documentation

[Historical Stock
Quotes](https://docs.alpaca.markets/us/reference/stockquotesingle-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v2/stocks/AAPL/quotes?start=2024-01-15&limit=2'

#### JSON Response

    {
      "quotes": [
        {"t": "2024-01-15T09:30:00.000123Z", "ax": "Q", "ap": 184.30, "as": 5, "bx": "K", "bp": 184.25, "bs": 3, "c": ["R"], "z": "C"},
        {"t": "2024-01-15T09:30:00.001234Z", "ax": "N", "ap": 184.32, "as": 2, "bx": "P", "bp": 184.27, "bs": 4, "c": ["R"], "z": "C"}
      ],
      "symbol": "AAPL",
      "next_page_token": "QUFQTHwyMDI0LTAxLTE1VDA5OjMwOjAwLjAwMTIzNFp8Mg=="
    }

#### Usage

    AlpacaMarketData$get_quotes(
      symbol,
      start = NULL,
      end = NULL,
      limit = NULL,
      feed = NULL,
      sort = NULL,
      page_token = NULL,
      asof = NULL,
      currency = NULL
    )

#### Arguments

- `symbol`:

  (scalar\<character\>) ticker symbol.

- `start`:

  (scalar\<character\> \| NULL) start date/time.

- `end`:

  (scalar\<character\> \| NULL) end date/time.

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max quotes (1-10000, default
  1000).

- `feed`:

  (scalar\<character\> \| NULL) `"sip"` (default), `"iex"`, `"otc"`,
  `"boats"`.

- `sort`:

  (scalar\<character\> \| NULL) `"asc"` or `"desc"`.

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

- `asof`:

  (scalar\<character\> \| NULL) as-of date for symbol mapping
  (`"YYYY-MM-DD"` or `"-"` to skip).

- `currency`:

  (scalar\<character\> \| NULL) ISO 4217 currency. Default `"USD"`.

#### Returns

(Quote \| promise\<Quote\>) **one row per quote**. Columns: `timestamp`
(POSIXct), `ask_exchange`, `bid_exchange`, `tape` (character),
`ask_price`, `bid_price` (numeric), `ask_size`, `bid_size` (integer),
and `conditions` (character, `;`-separated quote condition codes e.g.
`"R;F"`; `NA` when no conditions were reported). Filter with
`dt[grepl("R", conditions)]` or recover via
`strsplit(dt$conditions[1], ";", fixed = TRUE)[[1]]`.

------------------------------------------------------------------------

### Method `get_assets()`

Get All Assets

Retrieves a list of available assets (stocks, crypto, etc.).

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/assets`

#### Official Documentation

[Assets](https://docs.alpaca.markets/us/reference/get-v2-assets-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/assets?status=active&asset_class=us_equity'

#### JSON Response

    [
      {
        "id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
        "class": "us_equity",
        "exchange": "NASDAQ",
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "status": "active",
        "tradable": true,
        "marginable": true,
        "maintenance_margin_requirement": 30,
        "shortable": true,
        "easy_to_borrow": true,
        "fractionable": true
      }
    ]

#### Usage

    AlpacaMarketData$get_assets(
      status = NULL,
      asset_class = NULL,
      exchange = NULL,
      attributes = NULL
    )

#### Arguments

- `status`:

  (scalar\<character\> \| NULL) filter by status (`"active"`,
  `"inactive"`).

- `asset_class`:

  (scalar\<character\> \| NULL) filter by class (`"us_equity"`,
  `"us_option"`, `"crypto"`).

- `exchange`:

  (scalar\<character\> \| NULL) filter by exchange (`"AMEX"`, `"ARCA"`,
  `"BATS"`, `"NYSE"`, `"NASDAQ"`, `"NYSEARCA"`, `"OTC"`).

- `attributes`:

  (scalar\<character\> \| NULL) comma-separated attribute filters.
  Returns assets matching any of the listed attributes. Supported
  values: `"ptp_no_exception"`, `"ptp_with_exception"`, `"ipo"`,
  `"has_options"`, `"options_late_close"`, `"fractional_eh_enabled"`,
  `"overnight_tradable"`, `"overnight_halted"`.

#### Returns

(Asset \| promise\<Asset\>) the assets. Columns: `id`, `class`,
`exchange`, `symbol`, `name`, `status` (character); `tradable`,
`marginable`, `shortable`, `fractionable` (logical).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    assets <- market$get_assets(status = "active", asset_class = "us_equity")
    print(assets[1:5, .(symbol, name, exchange, tradable)])
    }

------------------------------------------------------------------------

### Method `get_asset()`

Get Asset by Symbol or ID

Retrieves metadata for a single asset.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/assets/{symbol_or_id}`

#### Official Documentation

[Asset by ID or
Symbol](https://docs.alpaca.markets/us/reference/get-v2-assets-symbol_or_asset_id)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/assets/AAPL'

#### JSON Response

    {
      "id": "b0b6dd9d-8b9b-48a9-ba46-b9d54906e415",
      "class": "us_equity",
      "exchange": "NASDAQ",
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "status": "active",
      "tradable": true,
      "marginable": true,
      "maintenance_margin_requirement": 30,
      "shortable": true,
      "easy_to_borrow": true,
      "fractionable": true
    }

#### Usage

    AlpacaMarketData$get_asset(symbol_or_id)

#### Arguments

- `symbol_or_id`:

  (scalar\<character\>) ticker symbol or asset UUID.

#### Returns

(Asset \| promise\<Asset\>) the asset, with the same columns as
`get_assets()`, single row.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    aapl <- market$get_asset("AAPL")
    print(aapl)
    }

------------------------------------------------------------------------

### Method `get_calendar()`

Get Market Calendar

Retrieves the market calendar showing trading days and hours. Includes
early closure information.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/calendar`

#### Official Documentation

[Calendar](https://docs.alpaca.markets/us/reference/legacycalendar)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/calendar?start=2024-01-01&end=2024-01-05'

#### JSON Response

    [
      {"date": "2024-01-02", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-04"},
      {"date": "2024-01-03", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-05"},
      {"date": "2024-01-04", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-08"},
      {"date": "2024-01-05", "open": "09:30", "close": "16:00", "session_open": "0700", "session_close": "1900", "settlement_date": "2024-01-09"}
    ]

#### Usage

    AlpacaMarketData$get_calendar(start = NULL, end = NULL, date_type = NULL)

#### Arguments

- `start`:

  (scalar\<character\> \| NULL) start date (`"YYYY-MM-DD"`).

- `end`:

  (scalar\<character\> \| NULL) end date (`"YYYY-MM-DD"`).

- `date_type`:

  (scalar\<character\> \| NULL) one of `"TRADING"` or `"SETTLEMENT"`.
  Determines whether `start`/`end` are interpreted as trading dates
  (default) or settlement dates.

#### Returns

(Calendar \| promise\<Calendar\>) the calendar. Columns: `date` and
`settlement_date` (Date); `open`, `close`, `session_open`,
`session_close` (POSIXct, `America/New_York`).

Alpaca's API returns market times without an offset; per the Alpaca docs
they are Eastern Time. We localise to `America/New_York` (the named tz
handles DST automatically).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    cal <- market$get_calendar(start = "2024-01-01", end = "2024-01-31")
    print(cal)
    }

------------------------------------------------------------------------

### Method `get_clock()`

Get Market Clock

Retrieves the current market clock including whether the market is open
and the next open/close times.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/clock`

#### Official Documentation

[Clock](https://docs.alpaca.markets/us/reference/legacyclock) Verified:
2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/clock'

#### JSON Response

    {
      "timestamp": "2024-01-15T14:30:00.000-05:00",
      "is_open": true,
      "next_open": "2024-01-16T09:30:00-05:00",
      "next_close": "2024-01-15T16:00:00-05:00"
    }

#### Usage

    AlpacaMarketData$get_clock()

#### Returns

(Clock \| promise\<Clock\>) the clock. Columns: `timestamp`,
`next_open`, `next_close` (POSIXct, `America/New_York`) and `is_open`
(logical).

The Alpaca clock endpoint returns ISO-8601 timestamps with an explicit
offset; we parse the instant exactly and display it in
`America/New_York` for consistency with `get_calendar()`. Use
[`lubridate::with_tz()`](https://lubridate.tidyverse.org/reference/with_tz.html)
to view in another timezone.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    clock <- market$get_clock()
    cat("Market open:", clock$is_open, "\n")
    }

------------------------------------------------------------------------

### Method `get_corporate_actions()`

Get Corporate Action Announcements

Retrieves announcements for corporate actions such as dividends,
mergers, spinoffs, and stock splits. Essential for production trading
systems that need to handle position adjustments.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/corporate_actions/announcements`

#### Official Documentation

[Corporate
Actions](https://docs.alpaca.markets/us/reference/get-v2-corporate_actions-announcements-1)
Verified: 2026-05-21

Note: as of 2026-05, the `/v2/corporate_actions/announcements` endpoint
is marked DEPRECATED by Alpaca. It still works and the wrapper still
calls it, but Alpaca recommends migrating to the newer corporate-actions
market-data endpoint (`/v1beta1/corporate-actions`). Migration is
tracked as a follow-up.

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/corporate_actions/announcements?ca_types=dividend&since=2024-01-01&until=2024-03-31'

#### JSON Response

    [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "corporate_action_id": "DIV_AAPL_2024Q1",
        "ca_type": "dividend",
        "ca_sub_type": "cash",
        "initiating_symbol": "AAPL",
        "target_symbol": "AAPL",
        "declaration_date": "2024-02-01",
        "ex_date": "2024-02-09",
        "record_date": "2024-02-12",
        "payable_date": "2024-02-15",
        "cash": "0.24",
        "old_rate": "1",
        "new_rate": "1"
      }
    ]

#### Usage

    AlpacaMarketData$get_corporate_actions(
      ca_types,
      since,
      until,
      symbol = NULL,
      cusip = NULL,
      date_type = NULL
    )

#### Arguments

- `ca_types`:

  (scalar\<character\>) comma-separated corporate action types. Valid
  values: `"dividend"`, `"merger"`, `"spinoff"`, `"split"`.

- `since`:

  (scalar\<character\>) start date (`"YYYY-MM-DD"`). Required.

- `until`:

  (scalar\<character\>) end date (`"YYYY-MM-DD"`). Required.

- `symbol`:

  (scalar\<character\> \| NULL) filter by ticker symbol.

- `cusip`:

  (scalar\<character\> \| NULL) filter by CUSIP.

- `date_type`:

  (scalar\<character\> \| NULL) which date field `since`/`until` refer
  to. Alpaca's documented / SDK values are `"declaration_date"`,
  `"ex_date"`, `"record_date"`, `"payable_date"` (default server-side:
  `"ex_date"`). Validated client-side; invalid values abort before the
  request.

#### Returns

(CorporateAction \| promise\<CorporateAction\>) the announcements.
Columns: `id`, `corporate_action_id`, `ca_type`, `ca_sub_type`,
`initiating_symbol`, `target_symbol`, `cash`, `old_rate`, `new_rate`
(character); `declaration_date`, `ex_date`, `record_date`,
`payable_date` (Date).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()

    # Get all AAPL dividends in 2024
    divs <- market$get_corporate_actions(
      ca_types = "dividend", since = "2024-01-01", until = "2024-12-31",
      symbol = "AAPL"
    )
    print(divs)

    # Get all stock splits
    splits <- market$get_corporate_actions(
      ca_types = "split", since = "2024-01-01", until = "2024-12-31"
    )
    }

------------------------------------------------------------------------

### Method `get_news()`

Get Market News

Retrieves news articles from multiple sources filtered by symbols, date
range, or content. Useful for event-driven trading strategies.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/news`

#### Official Documentation

[News](https://docs.alpaca.markets/us/reference/news-3) Verified:
2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/news?symbols=AAPL&limit=10'

#### JSON Response

    {
      "news": [
        {
          "id": 35678901,
          "headline": "Apple Reports Record Q1 Revenue of $119.6 Billion",
          "author": "Reuters",
          "source": "reuters",
          "summary": "Apple Inc reported record first-quarter revenue driven by strong iPhone sales...",
          "url": "https://www.reuters.com/technology/apple-q1-2024-earnings",
          "symbols": ["AAPL"],
          "created_at": "2024-01-15T18:30:00Z",
          "updated_at": "2024-01-15T18:35:00Z",
          "images": [{"size": "large", "url": "https://example.com/aapl.jpg"}]
        }
      ],
      "next_page_token": "MTIzNDU2Nzg5MA=="
    }

#### Usage

    AlpacaMarketData$get_news(
      symbols = NULL,
      start = NULL,
      end = NULL,
      limit = NULL,
      sort = NULL,
      include_content = NULL,
      exclude_contentless = NULL,
      page_token = NULL
    )

#### Arguments

- `symbols`:

  (character \| NULL) comma-separated symbols to filter (e.g.,
  `"AAPL,MSFT"`), or a character vector of symbols.

- `start`:

  (scalar\<character\> \| NULL) start date/time (RFC-3339).

- `end`:

  (scalar\<character\> \| NULL) end date/time (RFC-3339).

- `limit`:

  (scalar\<count in \[1, Inf\[\> \| NULL) max articles (default 10, max
  50 server-side).

- `sort`:

  (scalar\<character\> \| NULL) `"desc"` (default, newest first) or
  `"asc"`.

- `include_content`:

  (scalar\<logical\> \| NULL) if `TRUE`, include full article content.

- `exclude_contentless`:

  (scalar\<logical\> \| NULL) if `TRUE`, exclude articles without
  content.

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

#### Returns

(News \| promise\<News\>) **one row per article**. Columns: `id`
(integer); `headline`, `author`, `source`, `summary`, `url` (character);
`created_at`, `updated_at` (POSIXct, UTC); `symbols` (character,
`;`-separated related tickers, e.g. `"AAPL;MSFT"`); `image_sizes`
(character, `;`-separated image size labels parallel to `image_urls`,
`NA` when the article has no images — missing per-image sizes become
empty tokens e.g. `"large;"`, never the literal `"NA"`); and
`image_urls` (character, `;`-separated image URLs, losslessly
double-encoded `%` → `%25` then `;` → `%3B` so a single
[`URLdecode()`](https://rdrr.io/r/utils/URLencode.html) after splitting
recovers the original). Filter symbols with
`dt[grepl("AAPL", symbols)]`; recover URLs with
`vapply(strsplit(dt$image_urls[1], ";", fixed = TRUE)[[1]], URLdecode, character(1))`.

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()

    # Latest AAPL news
    news <- market$get_news(symbols = "AAPL", limit = 5)
    print(news[, .(headline, source, created_at)])

    # News with full content
    news <- market$get_news(symbols = "TSLA", include_content = TRUE)
    }

------------------------------------------------------------------------

### Method `get_crypto_orderbook()`

Get Latest Crypto Orderbook

Retrieves the latest orderbook (top of book) for a crypto symbol.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta3/crypto/{loc}/latest/orderbooks`

#### Official Documentation

[Latest Crypto
Orderbooks](https://docs.alpaca.markets/us/reference/cryptolatestorderbooks-1)
Verified: 2026-05-22

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta3/crypto/us/latest/orderbooks?symbols=BTC/USD'

#### JSON Response

    {
      "orderbooks": {
        "BTC/USD": {
          "t": "2024-01-15T20:00:00.123456Z",
          "b": [
            {"p": 42950.50, "s": 0.5},
            {"p": 42949.00, "s": 1.2}
          ],
          "a": [
            {"p": 42951.00, "s": 0.3},
            {"p": 42952.50, "s": 0.8}
          ]
        }
      }
    }

#### Usage

    AlpacaMarketData$get_crypto_orderbook(symbols, loc = "us")

#### Arguments

- `symbols`:

  (character) crypto symbols (e.g. `"BTC/USD"`).

- `loc`:

  (scalar\<character\>) location code, `"us"` (default).

#### Returns

(CryptoOrderbook \| promise\<CryptoOrderbook\>) one row per
`(symbol, side, level)`. Columns: `symbol`, `side` (`"bid"` or `"ask"`)
(character); `level` (integer, 1-based depth within the side —
`level = 1` is top of book, ordering preserved from the Alpaca
response); `price`, `size` (numeric); and `timestamp` (POSIXct).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    ob <- market$get_crypto_orderbook("BTC/USD")
    print(ob)
    }

------------------------------------------------------------------------

### Method `get_most_actives()`

Get Most Active Stocks

Retrieves the most active stocks by volume or trade count.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/screener/stocks/most-actives`

#### Official Documentation

[Most Active
Stocks](https://docs.alpaca.markets/us/reference/mostactives-1)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/screener/stocks/most-actives?by=volume&top=5'

#### JSON Response

    {
      "most_actives": [
        {"symbol": "AAPL", "volume": 82488700, "trade_count": 1036517},
        {"symbol": "TSLA", "volume": 74523100, "trade_count": 987654},
        {"symbol": "NVDA", "volume": 65432100, "trade_count": 876543},
        {"symbol": "AMD", "volume": 54321000, "trade_count": 765432},
        {"symbol": "MSFT", "volume": 22622100, "trade_count": 345678}
      ],
      "last_updated": "2024-01-15T20:00:00Z"
    }

#### Usage

    AlpacaMarketData$get_most_actives(by = NULL, top = NULL)

#### Arguments

- `by`:

  (scalar\<character\> \| NULL) ranking metric: `"volume"` (default) or
  `"trades"`.

- `top`:

  (scalar\<count in \[1, Inf\[\> \| NULL) number of results to return
  (default 10).

#### Returns

(MostActives \| promise\<MostActives\>) the most active stocks. Columns:
`symbol` (character); `volume`, `trade_count` (count — the parser
coerces both whole-number counters to a `numeric` double so a large
volume cannot overflow `integer`).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    actives <- market$get_most_actives(by = "volume", top = 20)
    print(actives)
    }

------------------------------------------------------------------------

### Method `get_movers()`

Get Top Market Movers

Retrieves the top market movers (gainers and losers) by percentage
change.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/screener/{market_type}/movers`

#### Official Documentation

[Top Market Movers](https://docs.alpaca.markets/us/reference/movers-1)
Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/screener/stocks/movers?top=3'

#### JSON Response

    {
      "gainers": [
        {"symbol": "SMCI", "percent_change": 8.52, "change": 6.45, "price": 82.15},
        {"symbol": "PLTR", "percent_change": 5.31, "change": 1.23, "price": 24.40},
        {"symbol": "RIVN", "percent_change": 4.87, "change": 0.82, "price": 17.67}
      ],
      "losers": [
        {"symbol": "MRNA", "percent_change": -6.12, "change": -6.80, "price": 104.30},
        {"symbol": "ENPH", "percent_change": -5.45, "change": -6.10, "price": 105.80},
        {"symbol": "COIN", "percent_change": -4.98, "change": -7.50, "price": 143.10}
      ],
      "market_type": "stocks",
      "last_updated": "2024-01-15T20:00:00Z"
    }

#### Usage

    AlpacaMarketData$get_movers(market_type = "stocks", top = NULL)

#### Arguments

- `market_type`:

  (scalar\<character\>) `"stocks"` (default) or `"crypto"`.

- `top`:

  (scalar\<count in \[1, Inf\[\> \| NULL) number of results per
  direction (default 10).

#### Returns

(Movers \| promise\<Movers\>) the movers. Columns: `symbol` (character);
`percent_change`, `change`, `price` (numeric); plus a `direction` column
(`"gainer"` / `"loser"`).

#### Examples

    \dontrun{
    market <- AlpacaMarketData$new()
    movers <- market$get_movers(top = 5)
    print(movers)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AlpacaMarketData$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Synchronous usage
market <- AlpacaMarketData$new()
bars <- market$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01")
print(bars)

# Asynchronous usage
market_async <- AlpacaMarketData$new(async = TRUE)
main <- coro::async(function() {
  bars <- await(market_async$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01"))
  print(bars)
})
main()
while (!later::loop_empty()) later::run_now()
} # }


## ------------------------------------------------
## Method `AlpacaMarketData$get_bars`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
bars <- market$get_bars("AAPL", "1Day", start = "2024-01-01", end = "2024-01-31")
print(bars)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_bars_multi`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
bars <- market$get_bars_multi(c("AAPL", "MSFT"), "1Day", start = "2024-01-01")
print(bars)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_latest_bar`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
bar <- market$get_latest_bar("AAPL")
print(bar)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_latest_trade`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
trade <- market$get_latest_trade("AAPL")
print(trade)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_latest_quote`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
quote <- market$get_latest_quote("AAPL")
print(quote)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_snapshot`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
snap <- market$get_snapshot("AAPL")
print(snap)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_latest_bars_multi`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
bars <- market$get_latest_bars_multi(c("AAPL", "MSFT"))
print(bars)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_snapshots_multi`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
snaps <- market$get_snapshots_multi(c("AAPL", "MSFT", "GOOGL"))
print(snaps)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_assets`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
assets <- market$get_assets(status = "active", asset_class = "us_equity")
print(assets[1:5, .(symbol, name, exchange, tradable)])
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_asset`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
aapl <- market$get_asset("AAPL")
print(aapl)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_calendar`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
cal <- market$get_calendar(start = "2024-01-01", end = "2024-01-31")
print(cal)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_clock`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
clock <- market$get_clock()
cat("Market open:", clock$is_open, "\n")
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_corporate_actions`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()

# Get all AAPL dividends in 2024
divs <- market$get_corporate_actions(
  ca_types = "dividend", since = "2024-01-01", until = "2024-12-31",
  symbol = "AAPL"
)
print(divs)

# Get all stock splits
splits <- market$get_corporate_actions(
  ca_types = "split", since = "2024-01-01", until = "2024-12-31"
)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_news`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()

# Latest AAPL news
news <- market$get_news(symbols = "AAPL", limit = 5)
print(news[, .(headline, source, created_at)])

# News with full content
news <- market$get_news(symbols = "TSLA", include_content = TRUE)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_crypto_orderbook`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
ob <- market$get_crypto_orderbook("BTC/USD")
print(ob)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_most_actives`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
actives <- market$get_most_actives(by = "volume", top = 20)
print(actives)
} # }

## ------------------------------------------------
## Method `AlpacaMarketData$get_movers`
## ------------------------------------------------

if (FALSE) { # \dontrun{
market <- AlpacaMarketData$new()
movers <- market$get_movers(top = 5)
print(movers)
} # }
```
