# Retrieve Alpaca API Base URL

Returns the base URL for the Alpaca Trading API in the following
priority:

1.  The explicitly provided `url` parameter.

2.  The `ALPACA_API_ENDPOINT` environment variable.

3.  The default `"https://paper-api.alpaca.markets"` (paper trading).

## Usage

``` r
get_base_url(url = Sys.getenv("ALPACA_API_ENDPOINT"))
```

## Arguments

- url:

  Character string; explicit base URL. Defaults to
  `Sys.getenv("ALPACA_API_ENDPOINT")`.

## Value

Character string; the API base URL.

## Examples

``` r
if (FALSE) { # \dontrun{
get_base_url()
get_base_url("https://api.alpaca.markets")
} # }
```
