# alpaca

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

All API responses are returned as `data.table` objects with two
transformations applied:

1.  **snake_case column names** – camelCase keys from the JSON response
    (e.g. `latestTrade`, `nextClose`) are converted to snake_case
    (`latest_trade`, `next_close`) via a mechanical transformation. No
    columns are renamed beyond this.

2.  **Timestamps to POSIXct** – Columns containing RFC-3339 timestamps
    or epoch seconds are converted to `POSIXct` in-place under their
    snake_case name.

That’s it. **No fields are dropped and no columns are renamed** beyond
the camelCase-to-snake_case conversion. If a column exists in the Alpaca
API response, it will exist in the returned `data.table`. If you don’t
need a column, drop it yourself.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckmezquita/alpaca")
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
bars <- market$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01", end = "2024-01-31")
bars[]
```

``` R
#>              timestamp   open   high    low  close   volume trade_count    vwap
#>                 <POSc>  <num>  <num>  <num>  <num>    <int>       <int>   <num>
#> 1: 2024-01-02 05:00:00 187.15 188.44 183.89 185.64 82488700     1036517 185.831
#> 2: 2024-01-03 05:00:00 184.22 185.88 183.43 184.25 58414500      729382 184.567
```

### Latest Trade

``` r
trade <- market$get_latest_trade("AAPL")
trade[]
```

``` R
#>              timestamp price  size exchange   tape    id condition
#>                 <POSc> <num> <int>   <char> <char> <int>    <char>
#> 1: 2024-01-15 14:30:00 185.5   100        V      C 12345         @
```

### Latest Quote (NBBO)

``` r
quote <- market$get_latest_quote("AAPL")
quote[]
```

``` R
#>              timestamp ask_exchange ask_price ask_size bid_exchange bid_price
#>                 <POSc>       <char>     <num>    <int>       <char>     <num>
#> 1: 2024-01-15 14:30:00            V    185.55      200            Q     185.5
#>    bid_size conditions   tape
#>       <int>     <list> <char>
#> 1:      300  <list[1]>      C
```

### Market Clock

``` r
market$get_clock()
```

``` R
#>                        timestamp is_open                 next_open
#>                           <char>  <lgcl>                    <char>
#> 1: 2024-01-15T14:30:00.000-05:00    TRUE 2024-01-16T09:30:00-05:00
#>                   next_close
#>                       <char>
#> 1: 2024-01-15T16:00:00-05:00
```

### Available Assets

``` r
assets <- market$get_assets(status = "active", asset_class = "us_equity")
assets[]
```

``` R
#>        id     class exchange symbol                  name status tradable
#>    <char>    <char>   <char> <char>                <char> <char>   <lgcl>
#> 1: uuid-1 us_equity   NASDAQ   AAPL            Apple Inc. active     TRUE
#> 2: uuid-2 us_equity   NASDAQ   MSFT Microsoft Corporation active     TRUE
#>    marginable shortable fractionable
#>        <lgcl>    <lgcl>       <lgcl>
#> 1:       TRUE      TRUE         TRUE
#> 2:       TRUE      TRUE         TRUE
```

### Market News

``` r
news <- market$get_news(symbols = "AAPL", limit = 5)
news[, .(headline, source, created_at)]
```

``` R
#>                              headline   source           created_at
#>                                <char>   <char>               <char>
#> 1:   Apple Reports Record Q1 Earnings benzinga 2024-01-25T18:30:00Z
#> 2: Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z
#> 3: Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z
#> 4: Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z
```

## Account

``` r
acct <- AlpacaAccount$new(keys = KEYS, base_url = TBASE)
```

### Account Info

``` r
info <- acct$get_account()
info[, .(status, equity, buying_power, cash)]
```

``` R
#>    status equity buying_power   cash
#>    <char> <char>       <char> <char>
#> 1: ACTIVE 100000       400000 100000
```

### Open Positions

``` r
acct$get_positions()
```

``` R
#>     asset_id symbol exchange asset_class avg_entry_price    qty   side
#>       <char> <char>   <char>      <char>          <char> <char> <char>
#> 1: uuid-aapl   AAPL   NASDAQ   us_equity          185.50     10   long
#>    market_value cost_basis unrealized_pl unrealized_plpc current_price
#>          <char>     <char>        <char>          <char>        <char>
#> 1:      1870.00    1855.00         15.00           0.008        187.00
#>    lastday_price change_today
#>           <char>       <char>
#> 1:        186.00        0.005
```

### Portfolio History

``` r
acct$get_portfolio_history(period = "1M", timeframe = "1D")
```

``` R
#>     timestamp    equity profit_loss profit_loss_pct
#>        <POSc>     <num>       <num>           <num>
#> 1: 2024-01-01 100000.00        0.00          0.0000
#> 2: 2024-01-02 100150.50      150.50          0.0015
#> 3: 2024-01-03  99800.25     -200.25         -0.0020
```

## Trading

``` r
trading <- AlpacaTrading$new(keys = KEYS, base_url = TBASE)
```

### Place a Limit Order

``` r
order <- trading$add_order(
  symbol = "AAPL", side = "buy", type = "limit",
  time_in_force = "day", qty = 1, limit_price = 150
)
order[, .(id, symbol, side, type, status, limit_price)]
```

``` R
#>                id symbol   side   type   status limit_price
#>            <char> <char> <char> <char>   <char>      <char>
#> 1: order-uuid-123   AAPL    buy  limit accepted      150.00
```

### List Open Orders

``` r
trading$get_orders(status = "open")
```

``` R
#>         id symbol   side   type status    qty filled_qty           created_at
#>     <char> <char> <char> <char> <char> <char>     <char>               <char>
#> 1: order-1   AAPL    buy  limit    new      1          0 2024-01-15T14:30:00Z
#> 2: order-2   MSFT   sell market filled     10         10 2024-01-15T14:31:00Z
```

### Cancel an Order

``` r
trading$cancel_order("order-uuid-123")
```

``` R
#>          order_id    status
#>            <char>    <char>
#> 1: order-uuid-123 cancelled
```

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

``` R
#>                 symbol   type strike_price expiration_date
#>                 <char> <char>       <char>          <char>
#> 1: AAPL240621C00200000   call       200.00      2024-06-21
#> 2: AAPL240621P00180000    put       180.00      2024-06-21
```

### Options Chain

``` r
chain <- opts$get_option_chain("AAPL", type = "call")
chain[]
```

``` R
#>                 symbol latest_trade_timestamp latest_trade_price
#>                 <char>                 <char>              <num>
#> 1: AAPL240621C00200000   2024-06-15T14:30:00Z                5.5
#> 2: AAPL240621C00210000   2024-06-15T14:30:00Z                3.2
#>    latest_trade_size latest_quote_timestamp latest_quote_ask_price
#>                <int>                 <char>                  <num>
#> 1:                10   2024-06-15T14:30:00Z                    5.6
#> 2:                 5   2024-06-15T14:30:00Z                    3.3
#>    latest_quote_bid_price latest_quote_ask_size latest_quote_bid_size
#>                     <num>                 <int>                 <int>
#> 1:                    5.4                    50                    40
#> 2:                    3.1                    30                    25
```

## Short Selling

Alpaca integrates margin and short selling directly into the standard
trading API – no special classes needed. To short a stock, simply place
a sell order for a symbol you don’t own:

``` r
# Short 100 shares of AAPL at market
trading$add_order(
  symbol = "AAPL", side = "sell", type = "market",
  time_in_force = "day", qty = 100
)

# Close the short (buy to cover)
acct$close_position("AAPL")
```

## Bulk Historical Data

The
[`alpaca_backfill_bars()`](https://dereckmezquita.github.io/alpaca/reference/alpaca_backfill_bars.md)
function downloads historical bar data for multiple symbols and
timeframes with CSV-based resume support:

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

``` R
#>              timestamp   open   high    low  close    volume trade_count   vwap
#>                 <POSc>  <num>  <num>  <num>  <num>     <int>       <int>  <num>
#> 1: 2024-01-02 05:00:00 188.28 190.81 188.28 188.90 119197246      746404 188.60
#> 2: 2024-01-03 05:00:00 187.42 189.19 186.50 187.39  75079489      523028 187.32
#> 3: 2024-01-04 05:00:00 187.83 189.45 187.83 188.51  95992257      784214 188.84
#> 4: 2024-01-05 05:00:00 190.50 191.47 189.27 190.39 111126156     1312892 190.31
#> 5: 2024-01-08 05:00:00 192.39 192.39 190.41 191.64 106732757     1218918 191.42
#> 6: 2024-01-09 05:00:00 190.84 192.20 190.19 191.43  98753716     1029576 191.44
```

## Async Usage

All classes accept `async = TRUE`, causing methods to return promises.
Use [`coro::async()`](https://coro.r-lib.org/reference/async.html) to
write sequential-looking async code:

``` r
market_async <- AlpacaMarketData$new(async = TRUE)

main <- coro::async(function() {
  bars <- await(market_async$get_bars("AAPL", "1Day",
                                       start = "2024-01-01", end = "2024-01-31"))
  clock <- await(market_async$get_clock())

  print(bars)
  cat("Market open:", clock$is_open, "\n")
})

main()
while (!later::loop_empty()) later::run_now()
```

## Available Classes

| Class              | Purpose                                                                                                      |
|--------------------|--------------------------------------------------------------------------------------------------------------|
| `AlpacaMarketData` | Historical bars, latest trades/quotes, snapshots, assets, calendar, clock, news, screener, corporate actions |
| `AlpacaTrading`    | Place, modify, cancel, and query orders                                                                      |
| `AlpacaAccount`    | Account info, positions, portfolio history, activities, watchlists                                           |
| `AlpacaOptions`    | Options contracts, bars, trades, quotes, snapshots, chain                                                    |

Standalone function:
[`alpaca_backfill_bars()`](https://dereckmezquita.github.io/alpaca/reference/alpaca_backfill_bars.md)
– bulk historical bar download with CSV resume.

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
See [LICENSE.md](https://dereckmezquita.github.io/alpaca/LICENSE.md) for
the full text, including the citation clause.
