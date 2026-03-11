# Convert POSIXct to RFC-3339 Timestamp String

Formats a `POSIXct` object as an RFC-3339 timestamp string suitable for
the Alpaca API. Output is always in UTC with `Z` suffix.

## Usage

``` r
time_convert_to_alpaca(x)
```

## Arguments

- x:

  POSIXct; a datetime object (or character coercible to POSIXct).

## Value

Character string in RFC-3339 format (e.g., `"2024-01-15T14:30:00Z"`).

## Examples

``` r
time_convert_to_alpaca(Sys.time())
#> [1] "2026-03-11T21:57:01Z"
time_convert_to_alpaca(as.POSIXct("2024-01-15 14:30:00", tz = "UTC"))
#> [1] "2024-01-15T14:30:00Z"
```
