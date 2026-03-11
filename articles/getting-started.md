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
bars <- md$get_bars("AAPL", timeframe = "1Day", start = "2024-01-01",
                    end = "2024-01-31")
bars[]
```

    #>              timestamp   open   high    low  close   volume trade_count    vwap
    #>                 <POSc>  <num>  <num>  <num>  <num>    <int>       <int>   <num>
    #> 1: 2024-01-02 05:00:00 187.15 188.44 183.89 185.64 82488700     1036517 185.831
    #> 2: 2024-01-03 05:00:00 184.22 185.88 183.43 184.25 58414500      729382 184.567

### Latest Trade

``` r
trade <- md$get_latest_trade("AAPL")
trade[]
```

    #>              timestamp price  size exchange   tape    id condition
    #>                 <POSc> <num> <int>   <char> <char> <int>    <char>
    #> 1: 2024-01-15 14:30:00 185.5   100        V      C 12345         @

### Latest Quote

``` r
quote <- md$get_latest_quote("AAPL")
quote[]
```

    #>              timestamp ask_exchange ask_price ask_size bid_exchange bid_price
    #>                 <POSc>       <char>     <num>    <int>       <char>     <num>
    #> 1: 2024-01-15 14:30:00            V    185.55      200            Q     185.5
    #>    bid_size conditions   tape
    #>       <int>     <list> <char>
    #> 1:      300  <list[1]>      C

### Market Clock

``` r
clock <- md$get_clock()
clock[]
```

    #>                        timestamp is_open                 next_open
    #>                           <char>  <lgcl>                    <char>
    #> 1: 2024-01-15T14:30:00.000-05:00    TRUE 2024-01-16T09:30:00-05:00
    #>                   next_close
    #>                       <char>
    #> 1: 2024-01-15T16:00:00-05:00

### Available Assets

``` r
assets <- md$get_assets(status = "active", asset_class = "us_equity")
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

### Market Calendar

``` r
cal <- md$get_calendar(start = "2024-01-01", end = "2024-01-31")
cal[]
```

    #>          date   open  close
    #>        <char> <char> <char>
    #> 1: 2024-01-02  09:30  16:00
    #> 2: 2024-01-03  09:30  16:00

### Market News

``` r
news <- md$get_news(symbols = "AAPL", limit = 5)
news[, .(headline, source, created_at)]
```

    #>                              headline   source           created_at
    #>                                <char>   <char>               <char>
    #> 1:   Apple Reports Record Q1 Earnings benzinga 2024-01-25T18:30:00Z
    #> 2: Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z
    #> 3: Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z
    #> 4: Tech Sector Rallies on AI Optimism  reuters 2024-01-25T16:00:00Z

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
    #> 1: 2024-01-01 100000.00        0.00          0.0000
    #> 2: 2024-01-02 100150.50      150.50          0.0015
    #> 3: 2024-01-03  99800.25     -200.25         -0.0020

### Account Activities

``` r
activities <- acct$get_activities(activity_types = "FILL")
activities[]
```

    #>        id activity_type symbol   side    qty  price     transaction_time
    #>    <char>        <char> <char> <char> <char> <char>               <char>
    #> 1:  act-1          FILL   AAPL    buy     10 185.50 2024-01-15T14:30:00Z
    #> 2:  act-2          FILL   MSFT   sell      5 374.00 2024-01-15T14:31:00Z

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

    #>         id symbol   side   type status    qty filled_qty           created_at
    #>     <char> <char> <char> <char> <char> <char>     <char>               <char>
    #> 1: order-1   AAPL    buy  limit    new      1          0 2024-01-15T14:30:00Z
    #> 2: order-2   MSFT   sell market filled     10         10 2024-01-15T14:31:00Z

### Cancel a Specific Order

``` r
trading$cancel_order("order-uuid-123")
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
    #>                 <char> <char>       <char>          <char>
    #> 1: AAPL240621C00200000   call       200.00      2024-06-21
    #> 2: AAPL240621P00180000    put       180.00      2024-06-21

### Options Chain

``` r
chain <- opts$get_option_chain("AAPL", type = "call")
chain[]
```

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

------------------------------------------------------------------------

## Position Management

``` r
# Close 50% of a position
acct$close_position("AAPL", percentage = 50)

# Close entire position
acct$close_position("AAPL")

# Close all positions (dangerous!)
acct$close_all_positions(cancel_orders = TRUE)
```

## Next Steps

- See
  [`vignette("async-usage")`](https://dereckmezquita.github.io/alpaca/articles/async-usage.md)
  for promise-based async workflows.
- See
  [`vignette("margin-short-selling")`](https://dereckmezquita.github.io/alpaca/articles/margin-short-selling.md)
  for margin and short selling.
- Explore the [Alpaca API documentation](https://docs.alpaca.markets/)
  for full endpoint details.
