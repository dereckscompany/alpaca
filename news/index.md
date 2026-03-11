# Changelog

## alpaca 0.1.0.9000

### IMPROVEMENTS

- **Long-format data.table returns**: Eliminated list-columns in favour
  of long (tidy) format. Nested arrays from the API are now expanded to
  one row per element with parent fields repeated:
  - `AlpacaMarketData$get_latest_trade()` / `get_trades()`: trade
    `conditions` expanded — one row per condition as `condition`
    (character) column.
  - `AlpacaMarketData$get_news()`: `symbols` expanded — one row per
    symbol as `symbol` (character) column.
  - `AlpacaAccount$get_watchlist()` and related methods: `assets`
    expanded to rows with `asset_`-prefixed columns.

### BUG FIXES

- Removed usage of `%||%` operator which was not defined or imported;
  replaced with explicit `if (is.null(...))` checks in
  `helpers_request.R` and `test-bug-hunt.R`.

### DOCUMENTATION

- Corrected `wrap_list_fields()` roxygen to say “length \>= 1” (was
  “length \> 1”) to match actual implementation.
- Fixed test “wrap_list_fields does not wrap length-1 lists” — renamed
  and updated assertions to match actual `>= 1` wrapping behavior.

## alpaca 0.1.0

### NEW FEATURES

- Initial package scaffold. No endpoints implemented yet.
