# alpaca 0.2.0

## Pure-date fields are now `Date` (breaking)

Fields that carry calendar dates without a time component are now
parsed to `Date` instead of left as `"YYYY-MM-DD"` strings:

- **Corporate actions** (`AlpacaMarketData$get_corporate_actions()`):
  `declaration_date`, `ex_date`, `record_date`, `payable_date`.
- **Options contracts** (`AlpacaOptions$get_contracts()`,
  `$get_contract()`): `expiration_date`, `open_interest_date`,
  `close_price_date`.

`get_corporate_actions()`: the `date_type` argument is now
validated client-side. The accepted values are the suffixed forms
Alpaca's docs and SDKs use — `"declaration_date"`, `"ex_date"`,
`"record_date"`, `"payable_date"` — not the short forms the
roxygen previously documented (`"declaration"`, `"ex"`, ...). The
short forms were not accepted by the server, so any caller relying
on them was already sending an invalid request.

Adds a small shared `parse_date_cols(dt, cols)` helper that walks
candidate column names and parses `"YYYY-MM-DD"` strings to `Date`
in place; columns absent from `dt` are silently skipped.

## Timestamp fields are now POSIXct (breaking)

All RFC-3339 timestamp fields returned by the API are now parsed to
`POSIXct` (UTC) instead of character. Previously some endpoints (bars,
trades, quotes) already did this; the remaining ones did not. Now
covered:

- **Orders** (`AlpacaTrading$get_orders()`, `$get_order()`,
  `$submit_order()`, etc.): `created_at`, `updated_at`,
  `submitted_at`, `filled_at`, `expired_at`, `canceled_at`,
  `failed_at`, `replaced_at`.
- **Account** (`AlpacaAccount$get_account()`): `created_at`.
- **Watchlists** (`$get_watchlists()`, `$get_watchlist()`, etc.):
  `created_at`, `updated_at`.
- **Activities** (`$get_activities()`, `$get_activities_by_type()`):
  `transaction_time`.
- **News** (`AlpacaMarketData$get_news()`): `created_at`,
  `updated_at`.
- **Snapshots** (`$get_snapshot()`, `$get_snapshots_multi()`): all
  five nested `*_timestamp` fields. Previously renamed but left as
  character — now parsed consistently with the standalone
  bar/trade/quote endpoints.

Use `lubridate::with_tz()` to view in any other timezone; the
underlying instant is preserved.

## Calendar and clock return parsed datetimes (breaking)

`AlpacaMarketData$get_calendar()` and `$get_clock()` no longer return
character columns for dates and times. Instead:

- `get_calendar()` returns `date`/`settlement_date` as `Date` and
  `open`/`close`/`session_open`/`session_close` as `POSIXct` localised
  to `America/New_York` (Alpaca's documented exchange timezone, with
  DST handled automatically by the named tz).
- `get_clock()` returns `timestamp`/`next_open`/`next_close` as
  `POSIXct` in `America/New_York`. The wall-clock instant is preserved
  exactly — only the display tz is normalised. Use
  `lubridate::with_tz()` to view elsewhere.

The previous `@return` documentation also omitted `session_open`,
`session_close`, and `settlement_date`; those are now enumerated.

The class-level `AlpacaMarketData` docs now carry a "Timezones"
section spelling out the ET-by-inference assumption for calendar
times (Alpaca does not state it explicitly on the reference page) and
flagging that `/v3` multi-market endpoints will need per-market
timezone lookup. A `TODO(v3)` marker sits next to the
`ALPACA_EXCHANGE_TZ` constant in `R/helpers_parse.R` so a future
migration is hard to miss.

## Data-shape convention: one entity = one row

Every method that returns nested API data now follows a single guiding
policy: **identify the entity for the endpoint, and return one row per
entity**. The supporting rules:

1. **Variable-length array of plain strings on a single entity**
   (`conditions`, `attributes`, `permissions`, `symbols`, `image_urls`,
   ...) → collapsed into a single character column joined by `;`. Filter
   with `dt[grepl("X", col)]`. Recover the original vector with
   `strsplit(col[1], ";", fixed = TRUE)[[1]]`.
2. **Variable-length array of objects** (orderbook levels, watchlist
   assets, multi-leg orders, ...) → exploded to long format with
   parent fields replicated and a position-index column added where
   order matters (`level`, `leg_index`, ...).
3. **Fixed-schema nested object** (snapshot bars, account
   configurations, ...) → flattened to wide `parent_child` columns.
4. **Empty / null arrays** → `NA_character_` (not list cells). Empty
   responses → empty `data.table`, not stub rows.

The separator is `;` rather than `,` because semicolons are far less
likely to appear inside any of the values themselves. For fields where a
value could legally contain `;` (URLs in news image fields), the value
is percent-encoded before joining; recover with `URLdecode()` per
element after `strsplit()`.

## REVERSALS (from earlier branch state, not from a released version)

* **Trades** — `get_latest_trade()`, `get_latest_trades_multi()`, and
  `get_trades()` previously exploded the trade-conditions array to long
  format (one row per condition code). They now return **one row per
  trade** with a `;`-joined `conditions` character column. The column
  name moved from `condition` (singular, long-form) to `conditions`
  (plural, collapsed).
* **News** — `get_news()` previously cross-joined `symbols` × `images`
  on each article, producing a cartesian (3 symbols × 6 images = 18
  rows per article). It now returns **one row per article** with
  `symbols`, `image_sizes`, and `image_urls` as `;`-joined character
  columns. The column name moved from `symbol` (singular, long-form)
  to `symbols` (plural, collapsed).

## NEW LIST-COLUMN FIXES

* `get_assets()` / `get_asset()` — `attributes` was a list column; now
  a `;`-joined character (`"fractional_eh_enabled;has_options;..."`).
* `get_latest_quote()` / `get_latest_quotes_multi()` / `get_quotes()` —
  `conditions` was a list column; now `;`-joined character. One quote =
  one row regardless of how many condition codes it carries.
* `get_snapshot()` / `get_snapshots_multi()` — the inner
  `latest_trade_conditions` and `latest_quote_conditions` arrays were
  list columns; now `;`-joined character. Bar `c` close prices stay
  numeric.
* `get_news()` — additionally URL-encodes any literal `;` characters
  inside image URLs before joining (recover via `URLdecode()` per
  element).

## NEW FEATURES

* `get_crypto_orderbook()` (`AlpacaMarketData`) — wraps the
  `/v1beta3/crypto/{loc}/latest/orderbooks` endpoint. Returns a
  long-format `data.table` with `side` (`"bid"` / `"ask"`), `level`,
  `price`, `size`, `timestamp` columns.
* `get_account()` (`AlpacaAccount`) — the nested
  `admin_configurations` and `user_configurations` objects are now
  flattened to wide `parent_child` columns (e.g.
  `admin_configurations_max_options_trading_level`) instead of being
  carried as list columns.

## ORDERS: parent + leg row pattern

`add_order()`, `get_order()`, `get_orders()`, `get_order_by_client_id()`,
`modify_order()` — multi-leg orders (`bracket` / `oco` / `oto`) now
return a flat `data.table` with one row per order, parent and legs
equally:

* `leg_index` (integer) — `NA` on the parent row, `1, 2, ...` on each
  leg in submission order.
* `parent_order_id` (character) — `NA` on the parent row, the parent's
  `id` on each leg row.

Useful filters: `dt[is.na(parent_order_id)]` for "just the parent
orders", `dt[parent_order_id == "<id>"]` for "all legs of one specific
bracket". Simple orders return one row with both helper columns `NA`.

## DOCUMENTATION

* `Verified:` markers bumped to 2026-05-22 on every method affected by
  this PR. Doc-link slugs updated to the post-`/us/` reorg paths where
  they had drifted (`stocksnapshotsingle`, `stocklatesttradesingle-1`,
  `getallorders-1`, etc.).
* `helpers_parse.R` carries a worked round-trip example in the
  `collapse_string_array_fields` docstring for both plain-string and
  URL-encoded fields (`strsplit()` and `URLdecode()` respectively).

## BUG FIXES

* `parse_news` cartesian inflation (3 symbols × 6 images = 18 rows per
  article) is fixed by collapsing both arrays instead of exploding
  both.
* `collapse_string_array_fields()` writes `NA_character_` for empty
  arrays so downstream `rbindlist()` builds a clean character column
  instead of falling back to list when some records have arrays and
  others don't.
* Removed usage of `%||%` operator which was not defined or imported;
  replaced with explicit `if (is.null(...))` checks in
  `helpers_request.R` and `test-bug-hunt.R`.

## TESTS

* 510/510 PASS across mocked unit tests + live integration tests
  against paper trading. New test coverage for: attribute collapse,
  news cartesian fix, percent-encode round trip, snapshot inner
  conditions collapse with bar close-price preservation, bracket-order
  parent/leg shape, no-list-columns assertions on every affected
  method.

## INTERNAL

* `collapse_string_array_fields(x, fields)` — shared helper used by
  `parse_asset`, `parse_news`, `parse_trades`, `parse_quotes`, and
  `parse_snapshot`. Emits a once-per-session `rlang::warn()` if any
  value being collapsed contains a literal `;` (so a future API change
  that admits the separator is loud rather than silent).

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
