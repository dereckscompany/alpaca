# Retrieve Alpaca Market Data API Base URL

Returns the base URL for the Alpaca Market Data API in the following
priority:

1.  The explicitly provided `url` parameter.

2.  The `ALPACA_DATA_ENDPOINT` environment variable.

3.  The default `"https://data.alpaca.markets"`.

## Usage

``` r
get_data_base_url(url = Sys.getenv("ALPACA_DATA_ENDPOINT"))
```

## Arguments

- url:

  Character string; explicit base URL. Defaults to
  `Sys.getenv("ALPACA_DATA_ENDPOINT")`.

## Value

Character string; the Market Data API base URL.

## Examples

``` r
if (FALSE) { # \dontrun{
get_data_base_url()
get_data_base_url("https://data.sandbox.alpaca.markets")
} # }
```
