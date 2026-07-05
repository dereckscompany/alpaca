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
  from,
  to = lubridate::now(tzone = "UTC"),
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

  (character) ticker symbols (e.g., `c("AAPL", "MSFT")`).

- timeframes:

  (character) bar timeframes (e.g., `c("1Day", "1Hour")`). See
  `alpaca_timeframe_map` for valid values.

- from:

  (POSIXct \| character) start date/time.

- to:

  (POSIXct \| character) end date/time. Defaults to the current UTC time
  ([`lubridate::now()`](https://lubridate.tidyverse.org/reference/now.html)).

- path:

  (scalar\<character\>) file path for CSV output. Default
  `"alpaca_bars.csv"`.

- adjustment:

  (scalar\<character\>) price adjustment type. Default `"raw"`.

- feed:

  (scalar\<character\> \| NULL) data feed (`"iex"` or `"sip"`).

- sleep:

  (scalar\<numeric in \[0, Inf\[\>) seconds to pause between requests
  (rate limiting). Default `0.25`.

- keys:

  (list) API credentials. Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md).

- data_base_url:

  (scalar\<character\>) market data base URL. Defaults to
  [`get_data_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_data_base_url.md).

## Value

(class\<data.table\>) all downloaded data (invisibly). Also writes to
CSV.

Per-combo failures are surfaced as warnings during the run (one
[`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) per
failed `(symbol, timeframe)` pair, with the underlying error message).
After the loop, if any combinations failed, a final summary warning
lists the count and the affected pairs. No failure data is hidden on the
return value.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download daily bars for AAPL and MSFT
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT"),
  timeframes = "1Day",
  from = "2020-01-01",
  path = "data/bars.csv"
)

# Resume an interrupted download
dt <- alpaca_backfill_bars(
  symbols = c("AAPL", "MSFT", "TSLA"),
  timeframes = c("1Day", "1Hour"),
  from = "2020-01-01",
  path = "data/bars.csv"
)
} # }
```
