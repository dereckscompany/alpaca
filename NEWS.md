# alpaca 0.1.0.9000

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

## NEW FEATURES

* Initial package scaffold. No endpoints implemented yet.
