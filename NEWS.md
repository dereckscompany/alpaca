# alpaca 0.1.0

## DEPRECATIONS

* `AlpacaAccount$get_portfolio_history()`: the date-range parameters `date_start` / `date_end` are deprecated in favour of `start` / `end`. The old names were silently ignored by the Alpaca API (so any code that "worked" with them was already returning data from the wrong date range). The old argument names are kept as deprecated aliases that forward to `start` / `end` and emit a deprecation warning. They will be removed in a future release.

## COMPATIBILITY NOTES

* This release adds many new optional parameters to existing methods. They are NULL-defaulted, so **named-argument calls are unaffected**.
* For four methods (`get_bars`, `get_bars_multi`, `get_trades`, `get_quotes`) the new params (`asof`, `currency`) are appended at the end of the signature to preserve positional ordering. The same care was taken for `get_option_chain` (`updated_since` now last), `modify_order` (`notional` moved last), and `get_activities` (`category` moved last) so that callers using positional arguments don't break.
* As a general rule, named arguments are the safer idiom in R — code that calls these wrapper methods positionally is fragile against any future addition.

## DOCUMENTATION FIXES

* Repointed every reference link in roxygen comments to the new `https://docs.alpaca.markets/us/…` namespace. 41 of 60 links were 404'ing after Alpaca's docs reorg. All 60 now resolve to HTTP 200.
* Fixed two cases where the new docs slug looked right but pointed at the wrong endpoint:
    - `get_calendar` / `get_clock`: `calendar-2` / `clock-1` now document the new `/v3/` multi-market endpoints; the R wrapper calls `/v2/`. Repointed to `legacycalendar` / `legacyclock` (the US-only `/v2/` docs).
    - `get_assets`-style swaps where Alpaca flipped single-symbol vs multi-symbol slug conventions (e.g. `stockbars` is now the multi endpoint, `stockbarsingle-1` is the single).
* Fixed `Verifieid: → Verified:` typo (62 occurrences across `AlpacaMarketData.R` and `AlpacaOptions.R`).
* Walked every R6 method against its current docs page and bumped `Verified:` markers from `2026-03-10` to `2026-05-21` after diffing params end-to-end.

## NEW FEATURES — API surface expansion

Added support for new optional parameters Alpaca has introduced upstream. All additions are NULL-defaulted, so existing calls are unaffected.

* **Stock historical data** (`get_bars`, `get_bars_multi`, `get_trades`, `get_quotes`): `asof` (symbol-rename handling, e.g. FB → META) and `currency` (ISO 4217). Also documented the expanded `adjustment` enum (`spin-off`, comma-combinable) and `feed` enum (`sip`, `iex`, `otc`, `boats`).
* **Stock latest data** (`get_latest_bar`, `get_latest_trade`, `get_latest_quote`, `get_snapshot`, and their `_multi` variants): `currency`. Expanded `feed` enum to include `delayed_sip` and `overnight`.
* **Market calendar** (`get_calendar`): `date_type` (`"TRADING"` | `"SETTLEMENT"`).
* **Assets** (`get_assets`): `attributes` filter (`ptp_no_exception`, `ptp_with_exception`, `ipo`, `has_options`, `options_late_close`, `fractional_eh_enabled`, `overnight_tradable`, `overnight_halted`).
* **Options contracts** (`get_contracts`): `show_deliverables`, `ppind` (Penny Program Indicator).
* **Options historical data** (`get_option_bars`, `get_option_trades`): `sort`.
* **Options snapshots** (`get_option_snapshots`): `updated_since`, `limit`, `page_token`. (`get_option_chain` also gains `updated_since`.)
* **Orders** (`AlpacaTrading$add_order`): `legs` and `advanced_instructions`. `order_class` enum now accepts `"mleg"` for multi-leg option strategies. `symbol` and `side` are optional when `order_class = "mleg"` (the legs carry that info).
* **Order replace** (`modify_order`): `notional` (for IPO orders) and `advanced_instructions`.
* **List orders** (`get_orders`): `asset_class`, `before_order_id`, `after_order_id`.
* **Account configuration** (`modify_account_config`): `ptp_no_exception_entry`, `disable_overnight_trading`. The `max_options_trading_level` doc now lists the full enum 0–3.
* **Account activities** (`get_activities`): `category` (`"trade_activity"` | `"non_trade_activity"`, mutually exclusive with `activity_types`).

## KNOWN ISSUES / FOLLOW-UPS

* **Corporate actions endpoint deprecated upstream**: `/v2/corporate_actions/announcements` is still functional but Alpaca has flagged it DEPRECATED in favour of `/v1beta1/corporate-actions`. The wrapper still calls the working v2 endpoint. Migration to be tracked separately.
* **`get_option_snapshot` (singular)**: the URL `/v1beta1/options/snapshots/{symbol}` is now the underlying-chain endpoint (see `get_option_chain`), not a per-contract snapshot. Use `get_option_snapshots(symbols = "<OCC-SYMBOL>")` for a single contract. The method is left in place but a docstring note now warns about the mismatch.

## INTERNAL

* `validate_order_params()` updated to accept `legs` / `advanced_instructions` and to allow `order_class = "mleg"` (which also makes `symbol` and `side` optional, since the legs carry that info).

## ENUM ADDITIONS

* `AlpacaAccount$get_portfolio_history()` `intraday_reporting` now lists `"continuous"` as a valid value (for 24/7 crypto charts). `pnl_reset` is documented with its `"per_day"` (default) / `"no_reset"` values. Both are now client-side enum-validated.
* Selected new enum params are validated client-side and abort with a clear message on a typo: `date_type` on `get_calendar()`, `category` and `direction` on `get_activities()`, `status` / `direction` / `side` on `get_orders()`, `intraday_reporting` / `pnl_reset` on `get_portfolio_history()`. (The `feed` and `adjustment` enums are left permissive because Alpaca expands those upstream from time to time.)

## RUNTIME DEPRECATION WARNINGS

* `AlpacaOptions$get_option_snapshot()` now emits a deprecation warning on call. Its URL (`/v1beta1/options/snapshots/{symbol}`) is the underlying-chain endpoint upstream — not a per-contract snapshot. Prefer `get_option_snapshots(symbols = "<OCC>")` for a single contract.
* `AlpacaMarketData$get_corporate_actions()` now emits a deprecation warning on call. `/v2/corporate_actions/announcements` is still functional but Alpaca has flagged it DEPRECATED in favour of `/v1beta1/corporate-actions`.
* Both warnings are rate-limited (`rlang::warn(..., .frequency = "regularly")`), so a tight loop won't spam stderr.

## TESTING

Live integration tests run against the Alpaca paper-trading API; combined with mocked unit tests this release ships with **>560 PASS / 0 FAIL**. The handful of warnings during the run are benign `data.table::rbindlist` notices for empty list columns and predate this release.

The "57 verified" count above refers to the package's 57 R6 methods (a few share an endpoint upstream, e.g. `get_option_snapshot` and `get_option_chain` both call `/v1beta1/options/snapshots/{symbol}`), not 57 distinct upstream endpoints.

# alpaca 0.0.1

## NEW FEATURES

* Initial package scaffold. No endpoints implemented yet.
