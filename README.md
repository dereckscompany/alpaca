
# alpaca

<!-- badges: start -->

[![R-CMD-check](https://github.com/dereckscompany/alpaca/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dereckscompany/alpaca/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R API wrapper for the [Alpaca](https://alpaca.markets/) trading
platform. Provides `R6` classes for market data, stock trading, options,
account management, and positions. Supports both synchronous and
asynchronous (promise based) operation via `httr2`.

## Disclaimer

This software is provided “as is”, without warranty of any kind. **This
package interacts with live brokerage accounts and can execute real
trades involving real money.** By using this package you accept full
responsibility for any financial losses, erroneous transactions, or
other damages that may result. Always test with paper trading first, use
API key permissions to restrict access to only what you need, and never
share your API credentials. The author(s) and contributor(s) are not
liable for any financial loss or damage arising from the use of this
software.

We invite you to read the source code and make contributions if you find
a bug or wish to make an improvement.

## Design Philosophy

All API responses are returned as `data.table` objects with three
transformations applied:

1.  **snake_case column names** – camelCase keys from the JSON response
    (e.g. `latestTrade`, `nextClose`) are converted to snake_case
    (`latest_trade`, `next_close`). A handful of endpoints additionally
    expand abbreviated single-letter keys returned by Alpaca’s
    bar/trade/quote feeds (e.g. `t` → `datetime` on a bar’s reference
    time and `t` → `timestamp` on a trade/quote event time, `p` →
    `price`, `o`/`h`/`l`/`c` → `open`/`high`/`low`/`close`, `vw` →
    `volume_weighted_avg_price`) so the resulting column names are
    self-describing. The full mapping per endpoint is documented in the
    method-level `@return` blocks.

2.  **All RFC-3339 timestamps are `POSIXct`** – Every timestamp the
    Alpaca API emits in RFC-3339 form is parsed for you, regardless of
    endpoint: bars, trades, quotes, snapshots (incl. the five nested
    `*_timestamp` fields), orderbooks, news (`created_at`,
    `updated_at`), orders (`created_at`, `updated_at`, `submitted_at`,
    `filled_at`, `expired_at`, `canceled_at`, `failed_at`,
    `replaced_at`), account `created_at`, watchlist `created_at` /
    `updated_at`, and activities `transaction_time`. POSIXct columns are
    displayed in UTC by default. See each method’s `@return` for the
    per-column types.

3.  **One entity = one row, no list columns** – For every endpoint
    normalised under the shape policy (see *Data-shape conventions*
    below) the returned `data.table` contains no list columns. A small
    number of legacy endpoints that go through the generic parser may
    still surface nested arrays as list columns; those are called out
    individually in their `@return`.

**No fields are dropped** by the normalising parsers (`parse_trades`,
`parse_quotes`, `parse_news`, `parse_snapshot`,
`parse_asset`/`parse_assets`, `parse_order`/`parse_orders`,
`parse_watchlist`). Every scalar and array field present in the Alpaca
response surfaces as a column on the resulting `data.table` – collapsed,
exploded, or wide-prefixed per the shape policy. If you don’t need a
column, drop it yourself.

## Data-shape conventions

Alpaca’s JSON responses sometimes contain nested arrays and objects. To
keep returns intuitive (and consistent across the `alpaca` / `binance` /
`kucoin` packages), every method follows one rule: **identify the entity
for the endpoint, and return one row per entity**. The four cases:

| Nested shape | Treatment | Example |
|----|----|----|
| Array of plain strings (`conditions`, `attributes`, `permissions`, `symbols`, `image_urls`) | Collapsed into a single character column joined by `;`. | `dt$attributes` -\> `"fractional_eh_enabled;has_options;overnight_tradable"` |
| Array of objects (orderbook levels, watchlist assets, multi-leg orders) | Exploded to long format with parent fields replicated. A position-index column is added when order matters (`level`, `leg_index`). | `get_crypto_orderbook("BTC/USD")` -\> one row per `(side, level)`. |
| Fixed-schema nested object (snapshot bars, account configurations) | Flattened to wide `parent_child` columns. | `get_account()` -\> `admin_configurations_max_options_trading_level`. |
| Empty / null array | `NA_character_` (no list cells). Empty responses -\> empty `data.table` (not stub rows). | An asset with no attributes -\> `attributes = NA`. |

### Recovering the original values

Filter with `grepl`:

``` r
# All assets that support options trading
options_assets <- assets[grepl("has_options", attributes)]

# All trades reported on the consolidated tape
trades_on_tape <- trades[grepl("T", conditions)]
```

Split back into the original character vector:

``` r
strsplit(dt$attributes[1], ";", fixed = TRUE)[[1]]
# [1] "fractional_eh_enabled" "has_options" "overnight_tradable"
```

URL-encoded fields (currently just news `image_urls`, where Alpaca
legitimately uses `;` inside some URLs) round-trip via `URLdecode()`.
The encoding is **lossless** in both directions: each URL is
double-encoded (`%` → `%25`, then `;` → `%3B`) before joining, so a
single `URLdecode()` after splitting recovers the original string even
when the upstream URL already contained `%3B` or other percent-escapes:

``` r
urls <- strsplit(news$image_urls[1], ";", fixed = TRUE)[[1]]
urls <- vapply(urls, URLdecode, character(1))
```

For parallel arrays like `image_sizes` / `image_urls`, when one element
omits a per-image field the missing value becomes an **empty token**
(e.g. `"large;"`), never the literal string `"NA"` — so a real `"NA"`
value remains unambiguous from a missing one.

### Multi-leg orders (`bracket` / `oco` / `oto`)

Multi-leg orders return a flat `data.table` with one row per “order”
(parent and legs treated equally). Two helper columns disambiguate:

- `leg_index` (integer) – `NA` on the parent row; `1, 2, ...` on each
  leg.
- `parent_order_id` (character) – `NA` on the parent row; the parent’s
  `id` on each leg.

``` r
# Just the parent orders (filter out legs)
dt[is.na(parent_order_id)]

# All legs of one specific bracket
dt[parent_order_id == "<parent-uuid>"]
```

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckscompany/alpaca")
```

## Setup

``` r
# special mock for local build
box::use(
  alpaca[
    get_api_keys,
    get_base_url,
    get_data_base_url
  ],
  connectcore[local_mock_api],
  ./tests/testthat/mock_router[.mock_routes]
)

KEYS <- get_api_keys(
  api_key = "fake-key",
  api_secret = "fake-secret"
)

TBASE <- "https://paper-api.alpaca.markets"
DBASE <- "https://data.alpaca.markets"

# httr2 exposes a native global mock hook: connectcore::local_mock_api installs
# the .mock_routes dispatcher as the httr2_mock option for the rest of this
# scope, so every request below is served from canned fixtures -- no network,
# no real credentials.
local_mock_api(.mock_routes)

# normal imports
box::use(
  alpaca[
    AlpacaMarketData,
    AlpacaTrading,
    AlpacaAccount,
    AlpacaOptions
  ]
)
```

Set your API credentials as environment variables in `.Renviron`:

``` bash
ALPACA_API_KEY = your-api-key
ALPACA_API_SECRET = your-api-secret
ALPACA_API_ENDPOINT = https://paper-api.alpaca.markets
```

If you don’t have a key, visit the [Alpaca
dashboard](https://app.alpaca.markets/).

## Quick Start – Market Data

All endpoints require authentication (even market data).

``` r
market <- AlpacaMarketData$new(keys = KEYS, base_url = TBASE, data_base_url = DBASE)
```

### Historical Bars

``` r
bars <- market$get_bars(
  symbol = "AAPL",
  timeframe = "1Day",
  start = "2024-01-01",
  end = "2024-01-31"
)
bars[]
```

    #>               datetime  open  high   low close  volume trade_count  vwap
    #>                 <POSc> <num> <num> <num> <num>   <num>       <num> <num>
    #> 1: 2024-01-02 05:00:00   100   110    95   105 1000000       10000 102.5
    #> 2: 2024-01-03 05:00:00   105   115   100   112 1100000       11000 108.0

`get_bars()` and `get_bars_multi()` **auto-paginate**: they follow
Alpaca’s `next_page_token` and return the full date range as one
`data.table`, not just the first ~1,000-row page the API caps each
response at. Tune the page size, throttle and page cap with `limit` /
`sleep` / `max_pages`.

### Latest Trade

``` r
trade <- market$get_latest_trade(symbol = "AAPL")
trade[]
```

    #>              timestamp price  size exchange   tape    id conditions
    #>                 <POSc> <num> <int>   <char> <char> <num>     <char>
    #> 1: 2024-01-15 14:30:00 185.5   100        V      C 12345          @

### Latest Quote (NBBO)

``` r
quote <- market$get_latest_quote(symbol = "AAPL")
quote[]
```

    #>              timestamp ask_exchange ask_price ask_size bid_exchange bid_price
    #>                 <POSc>       <char>     <num>    <int>       <char>     <num>
    #> 1: 2024-01-15 14:30:00            V    185.55      200            Q     185.5
    #>    bid_size   tape conditions
    #>       <int> <char>     <char>
    #> 1:      300      C          R

### Market Clock

``` r
market$get_clock()
```

    #>              timestamp is_open           next_open          next_close
    #>                 <POSc>  <lgcl>              <POSc>              <POSc>
    #> 1: 2024-01-15 14:30:00    TRUE 2024-01-16 09:30:00 2024-01-15 16:00:00

### Available Assets

``` r
assets <- market$get_assets(status = "active", asset_class = "us_equity")
assets[]
```

    #>        id     class exchange symbol                  name status tradable
    #>    <char>    <char>   <char> <char>                <char> <char>   <lgcl>
    #> 1: uuid-1 us_equity   NASDAQ   AAPL            Apple Inc. active     TRUE
    #> 2: uuid-2 us_equity   NASDAQ   MSFT Microsoft Corporation active     TRUE
    #>    marginable maintenance_margin_requirement margin_requirement_long
    #>        <lgcl>                          <int>                  <char>
    #> 1:       TRUE                             30                      30
    #> 2:       TRUE                             30                      30
    #>    margin_requirement_short shortable easy_to_borrow  borrow_status
    #>                      <char>    <lgcl>         <lgcl>         <char>
    #> 1:                       30      TRUE           TRUE easy_to_borrow
    #> 2:                       30      TRUE           TRUE easy_to_borrow
    #>    fractionable                                           attributes
    #>          <lgcl>                                               <char>
    #> 1:         TRUE fractional_eh_enabled;has_options;overnight_tradable
    #> 2:         TRUE                                                 <NA>

### Market News

``` r
news <- market$get_news(symbols = "AAPL", limit = 5)
news[, .(headline, source, created_at)]
```

    #>                                      headline   source          created_at
    #>                                        <char>   <char>              <POSc>
    #> 1:           Apple Reports Record Q1 Earnings benzinga 2024-01-25 18:30:00
    #> 2:         Tech Sector Rallies on AI Optimism  reuters 2024-01-25 16:00:00
    #> 3:              Some Generic Markets Headline     wire 2024-01-25 15:00:00
    #> 4:                        URL with semicolons     test 2024-01-25 14:00:00
    #> 5:  URL with a pre-existing %3B in the source     test 2024-01-25 13:00:00
    #> 6: Article with partially-missing image sizes     test 2024-01-25 12:00:00

## Account

``` r
acct <- AlpacaAccount$new(keys = KEYS, base_url = TBASE)
```

### Account Info

``` r
info <- acct$get_account()
info[, .(status, equity, buying_power, cash)]
```

    #>    status equity buying_power   cash
    #>    <char> <char>       <char> <char>
    #> 1: ACTIVE 100000       400000 100000

### Open Positions

``` r
acct$get_positions()
```

    #>     asset_id symbol exchange asset_class avg_entry_price    qty   side
    #>       <char> <char>   <char>      <char>          <char> <char> <char>
    #> 1: uuid-aapl   AAPL   NASDAQ   us_equity          185.50     10   long
    #>    market_value cost_basis unrealized_pl unrealized_plpc current_price
    #>          <char>     <char>        <char>          <char>        <char>
    #> 1:      1870.00    1855.00         15.00           0.008        187.00
    #>    lastday_price change_today
    #>           <char>       <char>
    #> 1:        186.00        0.005

### Portfolio History

``` r
acct$get_portfolio_history(period = "1M", timeframe = "1D")
```

    #>     timestamp    equity profit_loss profit_loss_pct
    #>        <POSc>     <num>       <num>           <num>
    #> 1: 2024-01-01 100000.00        0.00        0.000000
    #> 2: 2024-01-02 100150.50      150.50        0.001505
    #> 3: 2024-01-03  99800.25     -200.25       -0.002000

## Trading

``` r
trading <- AlpacaTrading$new(keys = KEYS, base_url = TBASE)
```

### Place a Limit Order

``` r
order <- trading$add_order(
  symbol = "AAPL",
  side = "buy",
  type = "limit",
  time_in_force = "day",
  qty = 1,
  limit_price = 150
)
order[, .(id, symbol, side, type, status, limit_price)]
```

    #>                id symbol   side   type   status limit_price
    #>            <char> <char> <char> <char>   <char>      <char>
    #> 1: order-uuid-123   AAPL    buy  limit accepted      150.00

### List Open Orders

``` r
trading$get_orders(status = "open")
```

    #>         id client_order_id          created_at          updated_at
    #>     <char>          <char>              <POSc>              <POSc>
    #> 1: order-1  client-order-1 2024-01-15 14:30:00 2024-01-15 14:30:00
    #> 2: order-2  client-order-2 2024-01-15 14:31:00 2024-01-15 14:31:05
    #>           submitted_at           filled_at expired_at canceled_at failed_at
    #>                 <POSc>              <POSc>     <POSc>      <POSc>    <POSc>
    #> 1: 2024-01-15 14:30:00                <NA>       <NA>        <NA>      <NA>
    #> 2: 2024-01-15 14:31:00 2024-01-15 14:31:05       <NA>        <NA>      <NA>
    #>    replaced_at replaced_by replaces  asset_id symbol asset_class notional
    #>         <POSc>      <lgcl>   <lgcl>    <char> <char>      <char>   <lgcl>
    #> 1:        <NA>          NA       NA uuid-aapl   AAPL   us_equity       NA
    #> 2:        <NA>          NA       NA uuid-msft   MSFT   us_equity       NA
    #>       qty filled_qty filled_avg_price order_class order_type   type   side
    #>    <char>     <char>           <char>      <char>     <char> <char> <char>
    #> 1:      1          0             <NA>                  limit  limit    buy
    #> 2:     10         10           374.00                 market market   sell
    #>    position_intent time_in_force limit_price stop_price status extended_hours
    #>             <char>        <char>      <char>     <lgcl> <char>         <lgcl>
    #> 1:     buy_to_open           day      150.00         NA    new          FALSE
    #> 2:   sell_to_close           day        <NA>         NA filled          FALSE
    #>    trail_percent trail_price    hwm subtag source           expires_at
    #>           <lgcl>      <lgcl> <lgcl> <lgcl> <lgcl>               <char>
    #> 1:            NA          NA     NA     NA     NA 2024-04-15T20:00:00Z
    #> 2:            NA          NA     NA     NA     NA 2024-04-15T20:00:00Z
    #>    leg_index parent_order_id
    #>        <int>          <char>
    #> 1:        NA            <NA>
    #> 2:        NA            <NA>

### Cancel an Order

``` r
trading$cancel_order(order_id = "order-uuid-123")
```

    #>          order_id    status
    #>            <char>    <char>
    #> 1: order-uuid-123 cancelled

## Options

``` r
opts <- AlpacaOptions$new(keys = KEYS, base_url = TBASE, data_base_url = DBASE)
```

### List Contracts

``` r
contracts <- opts$get_contracts(
  underlying_symbols = "AAPL",
  type = "call",
  expiration_date_gte = "2024-06-01",
  limit = 10
)
contracts[, .(symbol, type, strike_price, expiration_date)]
```

    #>                 symbol   type strike_price expiration_date
    #>                 <char> <char>       <char>          <Date>
    #> 1: AAPL240621C00200000   call       200.00      2024-06-21
    #> 2: AAPL240621P00180000    put       180.00      2024-06-21

### Options Chain

``` r
chain <- opts$get_option_chain(underlying_symbol = "AAPL", type = "call")
chain[]
```

    #>                 symbol latest_trade_timestamp latest_trade_price
    #>                 <char>                 <POSc>              <num>
    #> 1: AAPL240621C00200000    2024-06-15 14:30:00                5.5
    #> 2: AAPL240621C00210000    2024-06-15 14:30:00                3.2
    #>    latest_trade_size latest_trade_conditions latest_quote_timestamp
    #>                <int>                  <char>                 <POSc>
    #> 1:                10                       g    2024-06-15 14:30:00
    #> 2:                 5                    <NA>    2024-06-15 14:30:00
    #>    latest_quote_ask_price latest_quote_bid_price latest_quote_ask_size
    #>                     <num>                  <num>                 <int>
    #> 1:                    5.6                    5.4                    50
    #> 2:                    3.3                    3.1                    30
    #>    latest_quote_bid_size latest_quote_conditions minute_bar_timestamp
    #>                    <int>                  <char>               <POSc>
    #> 1:                    40                       A  2024-06-15 14:30:00
    #> 2:                    25                    <NA>                 <NA>
    #>    minute_bar_open minute_bar_high minute_bar_low minute_bar_close
    #>              <num>           <num>          <num>            <num>
    #> 1:            5.45             5.6            5.4              5.5
    #> 2:              NA              NA             NA               NA
    #>    minute_bar_volume minute_bar_trade_count minute_bar_vwap daily_bar_timestamp
    #>                <int>                  <int>           <num>              <POSc>
    #> 1:               120                      8            5.48 2024-06-15 04:00:00
    #> 2:                NA                     NA              NA                <NA>
    #>    daily_bar_open daily_bar_high daily_bar_low daily_bar_close daily_bar_volume
    #>             <num>          <num>         <num>           <num>            <int>
    #> 1:            5.2            5.7           5.1             5.5             3500
    #> 2:             NA             NA            NA              NA               NA
    #>    daily_bar_trade_count daily_bar_vwap prev_daily_bar_timestamp
    #>                    <int>          <num>                   <POSc>
    #> 1:                   210           5.42      2024-06-14 04:00:00
    #> 2:                    NA             NA                     <NA>
    #>    prev_daily_bar_open prev_daily_bar_high prev_daily_bar_low
    #>                  <num>               <num>              <num>
    #> 1:                 4.9                 5.3                4.8
    #> 2:                  NA                  NA                 NA
    #>    prev_daily_bar_close prev_daily_bar_volume prev_daily_bar_trade_count
    #>                   <num>                 <int>                      <int>
    #> 1:                  5.2                  4100                        260
    #> 2:                   NA                    NA                         NA
    #>    prev_daily_bar_vwap
    #>                  <num>
    #> 1:                5.09
    #> 2:                  NA

## Short Selling

Alpaca integrates margin and short selling directly into the standard
trading API – no special classes needed. To short a stock, simply place
a sell order for a symbol you don’t own:

``` r
# Short 100 shares of AAPL at market
trading$add_order(
  symbol = "AAPL",
  side = "sell",
  type = "market",
  time_in_force = "day",
  qty = 100
)

# Close the short (buy to cover)
acct$close_position(symbol_or_id = "AAPL")
```

## Bulk Historical Data

The `alpaca_backfill_bars()` function downloads historical bar data for
multiple symbols and timeframes with CSV-based resume support:

``` r
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT", "TSLA"),
  timeframes = c("1Day", "1Hour"),
  from = "2020-01-01",
  path = "data/bars.csv"
)

# Resume an interrupted download -- already-completed combos are skipped
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT", "TSLA", "GOOGL"),
  timeframes = c("1Day", "1Hour"),
  from = "2020-01-01",
  path = "data/bars.csv"
)
```

## Sample Data

The package includes a bundled dataset of simulated AAPL daily bars for
testing and demonstration:

``` r
data(alpaca_aapl_1day_bars, package = "alpaca")
head(alpaca_aapl_1day_bars)
```

    #>               datetime   open   high    low  close    volume trade_count   vwap
    #>                 <POSc>  <num>  <num>  <num>  <num>     <int>       <int>  <num>
    #> 1: 2024-01-02 05:00:00 188.28 190.81 188.28 188.90 119197246      746404 188.60
    #> 2: 2024-01-03 05:00:00 187.42 189.19 186.50 187.39  75079489      523028 187.32
    #> 3: 2024-01-04 05:00:00 187.83 189.45 187.83 188.51  95992257      784214 188.84
    #> 4: 2024-01-05 05:00:00 190.50 191.47 189.27 190.39 111126156     1312892 190.31
    #> 5: 2024-01-08 05:00:00 192.39 192.39 190.41 191.64 106732757     1218918 191.42
    #> 6: 2024-01-09 05:00:00 190.84 192.20 190.19 191.43  98753716     1029576 191.44

## Async Usage

All classes accept `async = TRUE`, causing methods to return promises.
Use `coro::async()` to write sequential-looking async code:

``` r
market_async <- AlpacaMarketData$new(async = TRUE)

main <- coro::async(function() {
  bars <- await(market_async$get_bars(
    symbol = "AAPL",
    timeframe = "1Day",
    start = "2024-01-01",
    end = "2024-01-31"
  ))
  clock <- await(market_async$get_clock())

  print(bars)
  cat("Market open:", clock$is_open, "\n")
})

main()
while (!later::loop_empty()) {
  later::run_now()
}
```

    #>      close     high      low trade_count    open            datetime   volume
    #>      <num>    <num>    <num>       <num>   <num>              <POSc>    <num>
    #>  1: 185.64 188.4400 183.8850     1009074 187.150 2024-01-02 05:00:00 82496943
    #>  2: 184.25 185.8800 183.4300      656956 184.220 2024-01-03 05:00:00 58418916
    #>  3: 181.91 183.0872 180.8800      712850 182.150 2024-01-04 05:00:00 71992243
    #>  4: 181.18 182.7600 180.1700      682335 181.990 2024-01-05 05:00:00 62379661
    #>  5: 185.56 185.6000 181.5000      669304 182.085 2024-01-08 05:00:00 59151720
    #>  6: 185.14 185.1500 182.7300      538297 183.920 2024-01-09 05:00:00 42848219
    #>  7: 186.19 186.4000 183.9200      554884 184.350 2024-01-10 05:00:00 46797681
    #>  8: 185.59 187.0500 183.6200      584114 186.540 2024-01-11 05:00:00 49133996
    #>  9: 185.92 186.7400 185.1900      477050 186.060 2024-01-12 05:00:00 40477782
    #> 10: 183.63 184.2600 180.9340      767431 182.160 2024-01-16 05:00:00 65612289
    #> 11: 182.68 182.9300 180.3000      594725 181.270 2024-01-17 05:00:00 47321545
    #> 12: 188.63 189.1400 185.8300      787472 186.090 2024-01-18 05:00:00 78031784
    #> 13: 191.56 191.9500 188.8200      682664 189.330 2024-01-19 05:00:00 68902985
    #> 14: 193.89 195.3300 192.2600      718256 192.300 2024-01-22 05:00:00 60139948
    #> 15: 195.18 195.7500 193.8299      533198 195.020 2024-01-23 05:00:00 42360151
    #> 16: 194.50 196.3800 194.3400      594907 195.420 2024-01-24 05:00:00 53636461
    #> 17: 194.17 196.2675 193.1125      644776 195.220 2024-01-25 05:00:00 54834147
    #> 18: 192.42 194.7600 191.9400      534166 194.270 2024-01-26 05:00:00 44594011
    #> 19: 191.73 192.2000 189.5800      599512 192.010 2024-01-29 05:00:00 47145521
    #> 20: 188.04 191.8000 187.4700      690706 190.940 2024-01-30 05:00:00 55854611
    #> 21: 184.40 187.0950 184.3500      679844 187.040 2024-01-31 05:00:00 55467803
    #>      close     high      low trade_count    open            datetime   volume
    #>      <num>    <num>    <num>       <num>   <num>              <POSc>    <num>
    #>         vwap
    #>        <num>
    #>  1: 185.8462
    #>  2: 184.3197
    #>  3: 182.0131
    #>  4: 181.4839
    #>  5: 184.4009
    #>  6: 184.3641
    #>  7: 185.2238
    #>  8: 185.0222
    #>  9: 185.8182
    #> 10: 182.8303
    #> 11: 181.8952
    #> 12: 187.9687
    #> 13: 190.6088
    #> 14: 194.0135
    #> 15: 194.8158
    #> 16: 195.2364
    #> 17: 194.7833
    #> 18: 193.1369
    #> 19: 191.2808
    #> 20: 188.8236
    #> 21: 185.3675
    #>         vwap
    #>        <num>
    #> Market open: FALSE

## Available Classes

| Class | Purpose |
|----|----|
| `AlpacaMarketData` | Historical bars, latest trades/quotes, snapshots, assets, calendar, clock, news, screener, corporate actions |
| `AlpacaTrading` | Place, modify, cancel, and query orders |
| `AlpacaAccount` | Account info, positions, portfolio history, activities, watchlists |
| `AlpacaOptions` | Options contracts, bars, trades, quotes, snapshots, chain |

Standalone function: `alpaca_backfill_bars()` – bulk historical bar
download with CSV resume.

## Citation

If you use this package in your work, please cite it:

``` r
citation("alpaca")
```

> Mezquita, D. (2026). alpaca: R API Wrapper to Alpaca Trading Platform.
> R package version 0.1.0.

## Licence

MIT © [Dereck Mezquita](https://github.com/dereckmezquita)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--9307--6762-green)](https://orcid.org/0000-0002-9307-6762).
See [LICENSE.md](LICENSE.md) for the full text, including the citation
clause.
