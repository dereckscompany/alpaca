# Getting Started with alpaca

This vignette demonstrates how to use `alpaca` in **synchronous** mode
to interact with the Alpaca Trading API.

## Setup

Set your API credentials as environment variables in `.Renviron`:

``` bash
ALPACA_API_KEY = your-api-key
ALPACA_API_SECRET = your-api-secret
ALPACA_API_ENDPOINT = https://paper-api.alpaca.markets
```

If you don’t have a key, visit the [Alpaca
dashboard](https://app.alpaca.markets/).

> **Paper trading**: Always start with
> `https://paper-api.alpaca.markets` to test without risking real money.

``` r

library(alpaca)

keys <- get_api_keys(
  api_key = "your-api-key",
  api_secret = "your-api-secret"
)
```

## Market Data

The `AlpacaMarketData` class provides access to historical and real-time
stock market data.

``` r

md <- AlpacaMarketData$new()
```

    #> Warning: Alpaca API credentials are empty. Set ALPACA_API_KEY and
    #> ALPACA_API_SECRET environment variables or pass them explicitly.

### Historical Bars

``` r

bars <- md$get_bars(
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

trade <- md$get_latest_trade(symbol = "AAPL")
trade[]
```

    #>              timestamp price  size exchange   tape    id conditions
    #>                 <POSc> <num> <int>   <char> <char> <num>     <char>
    #> 1: 2024-01-15 14:30:00 185.5   100        V      C 12345          @

### Latest Quote

``` r

quote <- md$get_latest_quote(symbol = "AAPL")
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

clock <- md$get_clock()
clock[]
```

    #>              timestamp is_open           next_open          next_close
    #>                 <POSc>  <lgcl>              <POSc>              <POSc>
    #> 1: 2024-01-15 14:30:00    TRUE 2024-01-16 09:30:00 2024-01-15 16:00:00

### Available Assets

``` r

assets <- md$get_assets(status = "active", asset_class = "us_equity")
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

### Market Calendar

``` r

cal <- md$get_calendar(start = "2024-01-01", end = "2024-01-31")
cal[]
```

    #>          date                open               close        session_open
    #>        <Date>              <POSc>              <POSc>              <POSc>
    #> 1: 2024-01-02 2024-01-02 09:30:00 2024-01-02 16:00:00 2024-01-02 04:00:00
    #> 2: 2024-01-03 2024-01-03 09:30:00 2024-01-03 16:00:00 2024-01-03 04:00:00
    #>          session_close settlement_date
    #>                 <POSc>          <Date>
    #> 1: 2024-01-02 20:00:00      2024-01-04
    #> 2: 2024-01-03 20:00:00      2024-01-05

### Market News

``` r

news <- md$get_news(symbols = "AAPL", limit = 5)
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

------------------------------------------------------------------------

## Account Information

The `AlpacaAccount` class gives you access to account details,
positions, and portfolio history.

``` r

acct <- AlpacaAccount$new()
```

    #> Warning: Alpaca API credentials are empty. Set ALPACA_API_KEY and
    #> ALPACA_API_SECRET environment variables or pass them explicitly.

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

positions <- acct$get_positions()
positions[]
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

history <- acct$get_portfolio_history(period = "1M", timeframe = "1D")
history[]
```

    #>     timestamp    equity profit_loss profit_loss_pct
    #>        <POSc>     <num>       <num>           <num>
    #> 1: 2024-01-01 100000.00        0.00        0.000000
    #> 2: 2024-01-02 100150.50      150.50        0.001505
    #> 3: 2024-01-03  99800.25     -200.25       -0.002000

### Account Activities

``` r

activities <- acct$get_activities(activity_types = "FILL")
activities[]
```

    #>        id activity_type    transaction_time   type  price    qty   side symbol
    #>    <char>        <char>              <POSc> <char> <char> <char> <char> <char>
    #> 1:  act-1          FILL 2024-01-15 14:30:00   fill 185.50     10    buy   AAPL
    #> 2:  act-2          FILL 2024-01-15 14:31:00   fill 374.00      5   sell   MSFT
    #>    leaves_qty       order_id cum_qty order_status swap_rate
    #>        <char>         <char>  <char>       <char>    <char>
    #> 1:          0 order-uuid-001      10       filled         1
    #> 2:          0 order-uuid-002       5       filled         1

------------------------------------------------------------------------

## Trading

The `AlpacaTrading` class handles order management.

``` r

trading <- AlpacaTrading$new()
```

    #> Warning: Alpaca API credentials are empty. Set ALPACA_API_KEY and
    #> ALPACA_API_SECRET environment variables or pass them explicitly.

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
order[, .(id, symbol, side, type, status)]
```

    #>                id symbol   side   type   status
    #>            <char> <char> <char> <char>   <char>
    #> 1: order-uuid-123   AAPL    buy  limit accepted

### Check Open Orders

``` r

open_orders <- trading$get_orders(status = "open")
open_orders[]
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

### Cancel a Specific Order

``` r

trading$cancel_order(order_id = "order-uuid-123")
```

    #>          order_id    status
    #>            <char>    <char>
    #> 1: order-uuid-123 cancelled

### Cancel All Open Orders

``` r

# Dangerous: cancels ALL open orders
trading$cancel_all_orders()
```

------------------------------------------------------------------------

## Options

The `AlpacaOptions` class provides access to options contracts and data.

``` r

opts <- AlpacaOptions$new()
```

    #> Warning: Alpaca API credentials are empty. Set ALPACA_API_KEY and
    #> ALPACA_API_SECRET environment variables or pass them explicitly.

### Search Contracts

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

------------------------------------------------------------------------

## Position Management

``` r

# Close 50% of a position
acct$close_position(symbol_or_id = "AAPL", percentage = 50)

# Close entire position
acct$close_position(symbol_or_id = "AAPL")

# Close all positions (dangerous!)
acct$close_all_positions(cancel_orders = TRUE)
```

## Next Steps

- See
  [`vignette("async-usage")`](https://dereckscompany.github.io/alpaca/articles/async-usage.md)
  for promise-based async workflows.
- See
  [`vignette("margin-short-selling")`](https://dereckscompany.github.io/alpaca/articles/margin-short-selling.md)
  for margin and short selling.
- Explore the [Alpaca API documentation](https://docs.alpaca.markets/)
  for full endpoint details.
