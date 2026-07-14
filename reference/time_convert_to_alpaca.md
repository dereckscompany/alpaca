# Convert POSIXct to RFC-3339 Timestamp String

Formats a `POSIXct` object as an RFC-3339 timestamp string suitable for
the Alpaca API. Output is always in UTC with `Z` suffix.

## Usage

``` r
time_convert_to_alpaca(x)
```

## Arguments

- x:

  (POSIXct \| character \| logical \| NULL) a date-time (or character
  coercible to POSIXct), or a bare `NA` (`logical`), or `NULL`.

## Value

(character \| NA) RFC-3339 strings (e.g., `"2024-01-15T14:30:00Z"`), or
`NA` if input is `NULL`/`NA`.

## Examples

``` r
time_convert_to_alpaca(Sys.time())
#> [1] "2026-07-14T04:16:57Z"
time_convert_to_alpaca(as.POSIXct("2024-01-15 14:30:00", tz = "UTC"))
#> [1] "2024-01-15T14:30:00Z"
```
