# Convert RFC-3339 Timestamp to POSIXct

Parses an RFC-3339 timestamp string (e.g., `"2024-01-15T14:30:00Z"`)
into a `POSIXct` object in UTC. Returns `NA` for `NULL` or `NA` input.

## Usage

``` r
time_convert_from_alpaca(x)
```

## Arguments

- x:

  Character vector; RFC-3339 timestamp string(s).

## Value

POSIXct vector in UTC, or `NA` if input is `NULL`/`NA`.

## Examples

``` r
time_convert_from_alpaca("2024-01-15T14:30:00Z")
#> [1] "2024-01-15 14:30:00 UTC"
time_convert_from_alpaca("2024-01-15T14:30:00.123-05:00")
#> [1] "2024-01-15 19:30:00 UTC"
```
