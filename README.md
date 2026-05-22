
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
    bar/trade/quote feeds (e.g. `t` → `timestamp`, `p` → `price`,
    `o`/`h`/`l`/`c` → `open`/`high`/`low`/`close`, `vw` →
    `volume_weighted_avg_price`) so the resulting column names are
    self-describing. The full mapping per endpoint is documented in the
    method-level `@return` blocks.

2.  **Timestamps to POSIXct where the field is clearly a market-data
    timestamp** – Numeric epoch fields and obvious RFC-3339 fields on
    market-data endpoints (bars, trades, quotes, snapshots, orderbook)
    are converted to `POSIXct` under their snake_case name. Some textual
    `created_at` / `updated_at` fields on lower-level endpoints (notably
    news articles) are left as `character` strings; see the relevant
    `@return` for the exact type per column.

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
  ./tests/testthat/mock_router[mock_router]
)

KEYS <- get_api_keys(
  api_key = "fake-key",
  api_secret = "fake-secret"
)

TBASE <- "https://paper-api.alpaca.markets"
DBASE <- "https://data.alpaca.markets"

options(httr2_mock = mock_router)

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

    #>              timestamp   open   high    low  close   volume trade_count    vwap
    #>                 <POSc>  <num>  <num>  <num>  <num>    <int>       <int>   <num>
    #> 1: 2024-01-02 05:00:00 187.15 188.44 183.89 185.64 82488700     1036517 185.831
    #> 2: 2024-01-03 05:00:00 184.22 185.88 183.43 184.25 58414500      729382 184.567

### Latest Trade

``` r
trade <- market$get_latest_trade(symbol = "AAPL")
trade[]
```

    #>              timestamp price  size exchange   tape    id conditions
    #>                 <POSc> <num> <int>   <char> <char> <int>     <char>
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

    #>                        timestamp is_open                 next_open
    #>                           <char>  <lgcl>                    <char>
    #> 1: 2024-01-15T14:30:00.000-05:00    TRUE 2024-01-16T09:30:00-05:00
    #>                   next_close
    #>                       <char>
    #> 1: 2024-01-15T16:00:00-05:00

### Available Assets

``` r
assets <- market$get_assets(status = "active", asset_class = "us_equity")
assets[]
```

    #>        id     class exchange symbol                  name status tradable
    #>    <char>    <char>   <char> <char>                <char> <char>   <lgcl>
    #> 1: uuid-1 us_equity   NASDAQ   AAPL            Apple Inc. active     TRUE
    #> 2: uuid-2 us_equity   NASDAQ   MSFT Microsoft Corporation active     TRUE
    #>    marginable shortable fractionable
    #>        <lgcl>    <lgcl>       <lgcl>
    #> 1:       TRUE      TRUE         TRUE
    #> 2:       TRUE      TRUE         TRUE
    #>                                              attributes
    #>                                                  <char>
    #> 1: fractional_eh_enabled;has_options;overnight_tradable
    #> 2:                                                 <NA>

### Market News

``` r
news <- market$get_news(symbols = "AAPL", limit = 5)
news[, .(headline, source, created_at)]
```

    #>                                      headline   source           created_at
    #>                                        <char>   <char>               <char>
    #> 1:           Apple Reports Record Q1 Earnings benzinga 2024-01-25T18:30:00Z
    #> 2:         Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z
    #> 3:              Some Generic Markets Headline     wire 2024-01-25T15:00:00Z
    #> 4:                        URL with semicolons     test 2024-01-25T14:00:00Z
    #> 5:  URL with a pre-existing %3B in the source     test 2024-01-25T13:00:00Z
    #> 6: Article with partially-missing image sizes     test 2024-01-25T12:00:00Z

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
    #> 1: 2024-01-01 100000.00        0.00          0.0000
    #> 2: 2024-01-02 100150.50      150.50          0.0015
    #> 3: 2024-01-03  99800.25     -200.25         -0.0020

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

    #>         id symbol   side   type status    qty filled_qty           created_at
    #>     <char> <char> <char> <char> <char> <char>     <char>               <char>
    #> 1: order-1   AAPL    buy  limit    new      1          0 2024-01-15T14:30:00Z
    #> 2: order-2   MSFT   sell market filled     10         10 2024-01-15T14:31:00Z
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
    #>                 <char> <char>       <char>          <char>
    #> 1: AAPL240621C00200000   call       200.00      2024-06-21
    #> 2: AAPL240621P00180000    put       180.00      2024-06-21

### Options Chain

``` r
chain <- opts$get_option_chain(underlying_symbol = "AAPL", type = "call")
chain[]
```

    #>                 symbol latest_trade_timestamp latest_trade_price
    #>                 <char>                 <char>              <num>
    #> 1: AAPL240621C00200000   2024-06-15T14:30:00Z                5.5
    #> 2: AAPL240621C00210000   2024-06-15T14:30:00Z                3.2
    #>    latest_trade_size latest_trade_conditions latest_quote_timestamp
    #>                <int>                  <char>                 <char>
    #> 1:                10                    <NA>   2024-06-15T14:30:00Z
    #> 2:                 5                    <NA>   2024-06-15T14:30:00Z
    #>    latest_quote_ask_price latest_quote_bid_price latest_quote_ask_size
    #>                     <num>                  <num>                 <int>
    #> 1:                    5.6                    5.4                    50
    #> 2:                    3.3                    3.1                    30
    #>    latest_quote_bid_size latest_quote_conditions
    #>                    <int>                  <char>
    #> 1:                    40                    <NA>
    #> 2:                    25                    <NA>

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
  start = "2020-01-01",
  path = "data/bars.csv"
)

# Resume an interrupted download -- already-completed combos are skipped
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT", "TSLA", "GOOGL"),
  timeframes = c("1Day", "1Hour"),
  start = "2020-01-01",
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

    #>              timestamp   open   high    low  close    volume trade_count   vwap
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

    #>              timestamp   open   high    low  close   volume trade_count    vwap
    #>                 <POSc>  <num>  <num>  <num>  <num>    <int>       <int>   <num>
    #> 1: 2024-01-02 05:00:00 187.15 188.44 183.89 185.64 82488700     1036517 185.831
    #> 2: 2024-01-03 05:00:00 184.22 185.88 183.43 184.25 58414500      729382 184.567
    #> Market open: TRUE

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
