# AAPL Daily OHLCV Bars (Sample Data)

Simulated daily bar data for AAPL (Apple Inc.) covering 250 trading days
in 2024. Generated with a random walk model for demonstration and
testing purposes. Column structure matches the output of
[AlpacaMarketData](https://dereckmezquita.github.io/alpaca/reference/AlpacaMarketData.md)`$get_bars()`.

## Usage

``` r
alpaca_aapl_1day_bars
```

## Format

A
[data.table::data.table](https://rdrr.io/pkg/data.table/man/data.table.html)
with 250 rows and 8 columns:

- timestamp:

  POSIXct. Bar timestamp in UTC.

- open:

  Numeric. Opening price.

- high:

  Numeric. Highest price during the day.

- low:

  Numeric. Lowest price during the day.

- close:

  Numeric. Closing price.

- volume:

  Integer. Volume traded.

- trade_count:

  Integer. Number of trades.

- vwap:

  Numeric. Volume-weighted average price.

## Source

Simulated data (random walk with parameters based on AAPL 2024).

## Examples

``` r
data(alpaca_aapl_1day_bars)
head(alpaca_aapl_1day_bars)
#>              timestamp   open   high    low  close    volume trade_count   vwap
#>                 <POSc>  <num>  <num>  <num>  <num>     <int>       <int>  <num>
#> 1: 2024-01-02 05:00:00 188.28 190.81 188.28 188.90 119197246      746404 188.60
#> 2: 2024-01-03 05:00:00 187.42 189.19 186.50 187.39  75079489      523028 187.32
#> 3: 2024-01-04 05:00:00 187.83 189.45 187.83 188.51  95992257      784214 188.84
#> 4: 2024-01-05 05:00:00 190.50 191.47 189.27 190.39 111126156     1312892 190.31
#> 5: 2024-01-08 05:00:00 192.39 192.39 190.41 191.64 106732757     1218918 191.42
#> 6: 2024-01-09 05:00:00 190.84 192.20 190.19 191.43  98753716     1029576 191.44
```
