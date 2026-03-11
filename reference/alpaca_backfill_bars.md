# Backfill Historical Bar Data

Downloads historical OHLCV bar data for one or more symbols and
timeframes, saving results to a CSV file. Supports resuming interrupted
downloads by reading existing data and skipping completed
symbol-timeframe combinations.

## Usage

``` r
alpaca_backfill_bars(
  symbols,
  timeframes = "1Day",
  start,
  end = Sys.time(),
  path = "alpaca_bars.csv",
  adjustment = "raw",
  feed = NULL,
  sleep = 0.25,
  keys = get_api_keys(),
  data_base_url = get_data_base_url()
)
```

## Arguments

- symbols:

  Character vector; ticker symbols (e.g., `c("AAPL", "MSFT")`).

- timeframes:

  Character vector; bar timeframes (e.g., `c("1Day", "1Hour")`). See
  `alpaca_timeframe_map` for valid values.

- start:

  Character or POSIXct; start date/time.

- end:

  Character or POSIXct; end date/time. Defaults to
  [`Sys.time()`](https://rdrr.io/r/base/Sys.time.html).

- path:

  Character; file path for CSV output. Default `"alpaca_bars.csv"`.

- adjustment:

  Character; price adjustment type. Default `"raw"`.

- feed:

  Character or NULL; data feed (`"iex"` or `"sip"`).

- sleep:

  Numeric; seconds to pause between requests (rate limiting). Default
  `0.25`.

- keys:

  List; API credentials. Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md).

- data_base_url:

  Character; market data base URL. Defaults to
  [`get_data_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_data_base_url.md).

## Value

`data.table` with all downloaded data (invisibly). Also writes to CSV.
Has a `"failures"` attribute listing any symbol-timeframe combos that
failed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download daily bars for AAPL and MSFT
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT"),
  timeframes = "1Day",
  start = "2020-01-01",
  path = "data/bars.csv"
)

# Resume an interrupted download
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT", "TSLA"),
  timeframes = c("1Day", "1Hour"),
  start = "2020-01-01",
  path = "data/bars.csv"
)
} # }
```
