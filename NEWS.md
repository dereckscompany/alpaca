# alpaca 0.4.3

## Documented the bar-backfill return shape with typed columns

* **`alpaca_fetch_bars()` now documents its `data.table` return as the typed `Bars` shape rather than a bare `data.table` with a prose column list.** The helper combines `parse_bars()` segments (and the empty path is `empty_dt_bars()`), so it always emits the canonical OHLCV columns; pointing its `@return` at the shared `Bars` `@type` makes the contract roclet generate the per-column `assert_has_columns` / type checks (`timestamp` POSIXct, the OHLC and `vwap` doubles, the `volume` / `trade_count` counts) that every other bar-returning method already carries. The three genuinely variable-shape endpoints (`cancel_all_orders`, `close_all_positions`, `cancel_watchlist_symbol`) keep their bare `data.table` return because their column set differs by response path.

# alpaca 0.4.2

## Test harness migrated onto the connectcore mock framework

* **Tests and docs now run against the shared `connectcore` mock harness.** The bespoke mock router and its inline R-list fixtures are replaced by JSON fixtures under `tests/testthat/fixtures/` — the single source of truth — loaded via `connectcore::load_fixtures()` and dispatched through `connectcore::mock_router()`; the README and vignettes install the mock with `connectcore::local_mock_api()`. The fixtures are now derived from real read-only Alpaca API captures with every account id, balance, and order id scrubbed to synthetic placeholders, so they mirror the real response shapes faithfully.
* **`DESCRIPTION`.** `connectcore (>= 0.2.0)`; `promises` moved from `Suggests` to `Imports` (used by the async bars path).

## Bug fixes surfaced by real data (enriched fixtures + live integration tests)

* **`parse_order()` no longer errors on an order with null timestamps.** A JSON `null` field (e.g. an unfilled order's `filled_at`) arrives as an all-`NA` *logical* column, which the datetime/number coercers reject — so any real order carrying a null timestamp would crash. `coerce_cols()` now normalises an all-`NA` logical column to `NA_character_` before coercion, yielding a correctly typed all-`NA` column. The previous synthetic fixtures omitted those null fields and hid the bug.
* **`get_account_config()` no longer rejects a real response.** The `AccountConfig` return contract required `max_options_trading_level`, which the live `/v2/account/configurations` endpoint does not return, so the contract would have rejected the real API response. The field is dropped from the `AccountConfig` return type (the modify parameter is unchanged), and the fields the endpoint actually returns (`closing_transactions_only`, `disable_overnight_trading`, `ptp_no_exception_entry`) are now in the fixture.
* **Several more return contracts no longer reject legitimately-missing fields**, found by running the live integration tests against the real API: the activity `symbol` / `side` / `qty` / `price` / `transaction_time` (a non-trade row — a fee, journal, or dividend — carries none of the trade columns), the option snapshot/chain `latest_trade_timestamp` / `latest_trade_price` / `latest_trade_size` (an illiquid option has no last trade), and the option-contract `open_interest` / `close_price`. Each is now typed `| NA` so the method returns the row instead of crashing.

# alpaca 0.4.1

## Contract hardening (coinbase gold-standard sweep)

* **64-bit identifiers and counters are typed `numeric` and coerced in the parser.** The trade `id`, the news article `id`, and the bar `volume` / `trade_count` can each exceed the 32-bit `integer` ceiling on a liquid name. `jsonlite` already realises any JSON integer `>= 2^31` as a double, and `assert_integer` rejects a double — so an `integer` contract would reject the parser's own output on a real response. Each is now typed `numeric`, coerced with `as.numeric()` in its parser (matching the existing `MostActives` treatment), and its `empty_dt_*()` constructor emits `numeric(0)`.
* **Parser-emitted `NA`s are now reflected in the contract.** `PortfolioHistory` `equity` / `profit_loss` / `profit_loss_pct` are `numeric | NA` (the parser's `nums()` maps a JSON `null` no-data point to `NA`), and the quote / snapshot `ask_price` / `bid_price` (`latest_quote_ask_price` / `latest_quote_bid_price`) are `numeric | NA` (an illiquid, one-sided book omits a side, which the parser coerces to `NA`). Previously these strict-`numeric` contracts would reject a genuine response.
* **Non-empty-string guards on every required URL-path identifier.** Each method that interpolates a required id into the request path — `order_id`, `client_order_id`, `symbol`, `symbol_or_id`, `watchlist_id`, `underlying_symbol`, `activity_type`, and the watchlist `name` — now asserts `assert::assert_nonempty_strings()` at entry, so an empty string fails fast at the boundary rather than building a malformed URL.
* **Typed return shapes for the confirmation / single-order methods.** `cancel_order`, `exercise_option`, and `cancel_watchlist` now declare the fixed `CancelOrderAck` / `ExerciseAck` / `CancelWatchlistAck` shapes (instead of a bare `data.table`), and `close_position` declares the `OrderCore` shape, so `assert_return_*` checks the actual columns and their types.
* **Concrete argument types for the time helpers.** `time_convert_from_alpaca()` / `time_convert_to_alpaca()` replace the lazy `any?` parameter type with concrete unions (`character | logical | NA | NULL` and `POSIXct | character | logical | NA | NULL`).
* **Documentation / packaging hygiene.** Closed `[1, N]` page/limit intervals are written half-open (`[1, N+1[`) so they no longer resolve as broken roxygen links at `document()` time (the validation is unchanged — the upper bound stays inclusive). `.lintr` restores `object_name_linter` (snake_case / SNAKE_CASE / CamelCase) with a targeted `# nolint` for the two `simplifyVector` arguments that mirror `httr2::resp_body_json()`. `DESCRIPTION` strips the `@ref` pins from `Remotes` (source-only) and carries the version constraints on `Imports` / `Suggests` instead. `NEWS.md` is de-wrapped to one continuous line per bullet.

# alpaca 0.4.0

## New features

* **Runtime contract enforcement via [roxyassert](https://github.com/dereckscompany/roxyassert).** Every `@param` and `@return` across the package is now typed in roxyassert's annotation grammar (no prose types remain), and the generated guards are wired in: each function and R6 method validates its inputs with `assert_args_<fn>()` at entry and its result with `assert_return_<fn>()` (the R6 forms `assert_args_<Class>__<method>()` / `assert_return_<Class>__<method>()`). Documented contracts and runtime validation now come from one source — `R/contracts-generated.R`, regenerated on `document()` like `NAMESPACE`. The change adds validation only: no public signature or behaviour changes for any valid input. For the sync-or-async methods the return validator is applied to the resolved value through `connectcore::then_or_now()`, so it runs in both modes (per roxyassert's promise model). `assert` is now an `Imports` dependency; `roxyassert` is used at `document()` time only.
* **Typed return shapes for every table-returning method.** The return contract of each endpoint method now references a reusable `@type` shape declared in `R/types_alpaca.R` (`Bars`, `BarsMulti`, `Trade`/`TradesMulti`, `Quote`/`QuotesMulti`, `Snapshot`/`SnapshotMulti`, `Asset`, `Calendar`, `Clock`, `CorporateAction`, `News`, `CryptoOrderbook`, `MostActives`, `Movers`, `Contract`, `Account`, `AccountConfig`, `Position`, `Activity`, `PortfolioHistory`, `Watchlists`/`Watchlist`, `OrderCore`/`Order`, and the options `OptionTradesMulti`/`OptionQuotesMulti`), so `assert_return_*` now checks the actual columns and their types — not merely "is a `data.table`". The list-returning endpoints route their empty branch through typed `empty_dt_*()` constructors, so an empty Alpaca response still carries the shape's columns. Two shape refinements match Alpaca's wire encoding: the bar OHLC / vwap and the trade/quote price columns are coerced to a clean `numeric` double in the parser (Alpaca drops the decimal point on a whole-number price, so the raw JSON realises it as `integer`; coercing keeps the column type stable so the contract can stay strict `numeric`), and the `Watchlist` `asset_*` columns are nullable (an empty watchlist returns one all-`NA` asset row). Public behaviour for any valid response is unchanged.
* **Strict numeric contracts and leaf-connector hygiene.** The price columns (`open`/`high`/`low`/`close`/`vwap`, the trade/quote `price`, the snapshot `latest_*_price` columns) are now typed strict `numeric` rather than `integer | numeric`: the parsers coerce them with `as.numeric()` so the column is always a double. The `MostActives` `volume` / `trade_count` are typed `count` and coerced to `numeric`, so a large volume cannot overflow `integer`. The two mis-named typed-empty-vector helpers (`empty_dt_empty_posixct()` / `empty_dt_empty_date()`) are dropped in favour of inline length-0 `lubridate::as_datetime()` / `as_date()` inside the `empty_dt_*` builders. As a leaf connector with no downstream consumer, the shapes no longer export `assert_type_*` validators (`@genassert` / `@exportassert` removed); the `@type` shapes still expand inline into each method's `assert_return_*` contract.

## Internal

* **Transport migrated onto [connectcore](https://github.com/dereckscompany/connectcore).** The Alpaca clients now build on connectcore's shared transport base instead of a private copy. `AlpacaBase` inherits `connectcore::RestClient` and customises only the two venue-specific seams: `.sign()` adds Alpaca's `APCA-API-KEY-ID` / `APCA-API-SECRET-KEY` headers (Alpaca authenticates with plain API-key headers — no request signing), and `.parse_envelope()` reads Alpaca's error shape (204 No Content, `message` / `msg` body fields). Every endpoint method still routes through the inherited `private$.request()` funnel, so retry, throttle, timeout, and the sync/async branch now come from one shared place.
* **Duplicated transport and generic helpers deleted.** The package's own `then_or_now()` and the request-funnel internals are gone, replaced by `connectcore::build_request()` / `connectcore::then_or_now()`. The generic JSON->data.table helpers (`to_snake_case()`, `as_dt_row()`, `as_dt_list()`, `collapse_string_array_fields()`) are now imported from connectcore; the Alpaca-specific parsers and time coercions are unchanged.
* **Public API, return shapes, and behaviour are unchanged.** `alpaca_build_request()` and `alpaca_paginate()` keep their signatures (now thin wrappers over the shared funnel), and every existing test continues to pass. The one endpoint that relied on `simplifyVector = TRUE` (portfolio history) now coerces the parallel arrays itself, preserving `null -> NA` alignment.
* **Request bodies are byte-identical to the pre-migration transport.** Bodies are pre-serialised by `alpaca_serialize_body()` (the exact options the old `httr2::req_body_json()` funnel used — `auto_unbox = TRUE`, `digits = 22`, `null = "null"`) and sent verbatim through connectcore's `body_format = "raw"` path, so the wire bytes for orders and every other POST/PUT/PATCH match the previous release exactly. The single deliberate departure also fixes a long-standing bug: a one-symbol watchlist now serialises `symbols` as a JSON array (`["AAPL"]`) instead of a bare scalar (`"AAPL"`), which Alpaca's watchlist endpoints require. New tests pin these body bytes.

# alpaca 0.3.0

## Bug fixes

* **`get_bars()` and `get_bars_multi()` now auto-paginate**, returning the full `start`..`end` range instead of a single truncated page. Previously both issued one request and dropped Alpaca's `next_page_token`, so any request whose result exceeded the page size was silently cut off. For `get_bars_multi()` this was especially damaging: Alpaca applies the page `limit` as a **total row budget across all requested symbols** (filling symbols alphabetically), so a single call for 9 symbols × `1Day` × 365 days came back as exactly 1,000 rows covering only the first 4 symbols alphabetically — the other 5 returned **no data at all**. Surfaced by a `tradebot-mini` production cycle that requested a full-year multi-symbol book "for 200-period MAs" and unknowingly made decisions on symbols it had zero bars for. Both methods now route through `alpaca_paginate()`, following the cursor to completion; per-symbol bars split across a page boundary are merged back together.

## Features

* **`alpaca_paginate()` gains a `sleep` argument** — seconds to pause between page requests (synchronous mode only), to stay under Alpaca's free/Basic data-tier rate limit of 200 requests/min. `get_bars()` / `get_bars_multi()` expose it (default `0.3`) alongside `max_pages` (default `1000`, a runaway guard; pass `Inf` for unbounded).

* **`alpaca_paginate()` warns on truncation rather than silently stopping.** If `max_pages` is reached while the server still reports `next_page_token`, the pages already fetched are returned (no work discarded) and an `rlang::warn()` fires telling the caller to resume from a later `start` or raise `max_pages`. This is the deliberate convention over erroring (which would throw away the data) or stopping silently (the original bug class).

## Documentation

* **Corrected the `get_bars_multi()` `limit` documentation.** It previously claimed `limit` was "max bars per symbol"; it is in fact a per-page total across all requested symbols. The new text spells this out and notes that auto-pagination returns every symbol's full range regardless of `limit`.

# alpaca 0.2.3

## Bug fixes

* **`AlpacaAccount$get_activities()` and `$get_activities_by_type()` now reject `page_size > 100` at the boundary** with a clear R error instead of letting Alpaca's `HTTP 422: "tried to set the page size to N, but the maximum is 100"` leak through. Surfaced by a downstream production cycle (`tradebot-mini`) that had been silently passing `page_size = 500L` until Alpaca enforced the cap, at which point the obscure vendor 422 was only debuggable by reading server logs. The validation also rejects `NA`, non-scalar, and non-numeric `page_size` with the same clean `rlang::abort()` — otherwise a bare `if (page_size > 100L)` would error with `"missing value where TRUE/FALSE needed"` on `NA` input, undermining the boundary-check itself. Closes [#7](https://github.com/dereckscompany/alpaca/issues/7).

## Documentation

* **`get_activities()` and `get_activities_by_type()` now document Alpaca's id-cursor pagination model.** A new `@section Pagination` block on `get_activities()` walks through the recipe — pass the previous page's last `id` back in as `page_token`, stop when a returned page is shorter than `page_size` — with a worked example. `get_activities_by_type()` cross-references the same section. Automated pagination (replacing `page_size` with `n` / `max_total`) is planned for a follow-up release; the public API will remain backward-compatible.

# alpaca 0.2.2

## Bug fixes

* **`coerce_cols(dt, cols, fn)` deduplicates `cols`**. Previously passing the same column name twice — e.g. `coerce_cols(dt, c("created_at", "created_at"), rfc3339_to_datetime)` — would re-feed the already-coerced POSIXct vector back through `lubridate::as_datetime()`, silently producing year-56,000+ values (POSIXct numerics reinterpreted as RFC-3339 strings). Now uses `for (col in unique(cols))`, so each column is coerced at most once regardless of how callers spell their input. Mirrors the kucoin and binance fixes.

* **`rfc3339_to_datetime()` was returning a length-1 `NA_POSIXct_` on all-NA input.** When that result flowed through `parse_timestamp_cols()` /`coerce_cols()` -> `data.table::set()`, the length-1 POSIXct got coerced into the existing column's type (character / numeric / logical) rather than replacing the column with a POSIXct one. Endpoints whose `@return` blocks documented `POSIXct` could therefore quietly return character columns when every upstream row had a missing timestamp. Dropped the `all(is.na(x))` short-circuit — `lubridate::as_datetime()` already returns a full-length POSIXct vector on all-NA input. Mirrors the binance `ms_to_datetime` fix caught in binance PR #9 review.

## Refactor

* **New internal `coerce_cols(dt, cols, fn)` helper** in `R/helpers_parse.R`. Generalises the existing `parse_timestamp_cols` and `parse_date_cols` to any per-column coercion function. Both specialised helpers now delegate to `coerce_cols` so there's a single core implementation. Same shape and contract as the binance package's `coerce_cols`. Internal `@noRd`.

## Tooling

* **`DESCRIPTION` License field** changed from `License: MIT + file LICENSE` to `License: MIT`. The previous form required `LICENSE` to be a 2-line DCF stub (`YEAR:` / `COPYRIGHT HOLDER:`), but the file carries the full MIT text — which is what GitHub's licensee detector wants for the MIT badge. The two requirements conflict; dropping `+ file LICENSE` lets R CMD check skip the DCF parse of the LICENSE file while leaving the GitHub-visible MIT detection intact. Non-CRAN form.

# alpaca 0.2.1

## Bug fixes

* **`collapse_string_array_fields` is now NA-safe.** A scalar `NA_character_` input would crash the helper — `grepl(";", NA_character_, fixed = TRUE)` returns `NA`, which propagates through `any(NA)` and then crashes `if (NA)`. Mixed vectors like `c("real", NA)` were also wrong: `paste(c("real", NA), collapse = ";")` produced the literal string `"real;NA"`, indistinguishable from a genuine `"NA"` value. The helper now filters NAs before joining, returns `NA_character_` when every element is NA, and uses `na.rm = TRUE` defensively on the separator-collision check. Ported from the binance package.

* **`alpaca_backfill_bars()` no longer hides failures on a return attribute.** Per-`(symbol, timeframe)` errors are now surfaced as `rlang::warn()` warnings during the run, and a final summary warning lists the failure count plus affected pairs at the end. The previous `attr(combined, "failures")` was easy to miss; the return value is now just the data.table with no hidden state. Code that read `attr(result, "failures")` should capture warnings with `withCallingHandlers()` or `tryCatch()` instead.

# alpaca 0.2.0

## Pure-date fields are now `Date` (breaking)

Fields that carry calendar dates without a time component are now parsed to `Date` instead of left as `"YYYY-MM-DD"` strings:

- **Corporate actions** (`AlpacaMarketData$get_corporate_actions()`): `declaration_date`, `ex_date`, `record_date`, `payable_date`.
- **Options contracts** (`AlpacaOptions$get_contracts()`, `$get_contract()`): `expiration_date`, `open_interest_date`, `close_price_date`.

`get_corporate_actions()`: the `date_type` argument is now validated client-side. The accepted values are the suffixed forms Alpaca's docs and SDKs use — `"declaration_date"`, `"ex_date"`, `"record_date"`, `"payable_date"` — not the short forms the roxygen previously documented (`"declaration"`, `"ex"`, ...). The short forms were not accepted by the server, so any caller relying on them was already sending an invalid request.

Adds a small shared `parse_date_cols(dt, cols)` helper that walks candidate column names and parses `"YYYY-MM-DD"` strings to `Date` in place; columns absent from `dt` are silently skipped.

## Timestamp fields are now POSIXct (breaking)

All RFC-3339 timestamp fields returned by the API are now parsed to `POSIXct` (UTC) instead of character. Previously some endpoints (bars, trades, quotes) already did this; the remaining ones did not. Now covered:

- **Orders** (`AlpacaTrading$get_orders()`, `$get_order()`, `$submit_order()`, etc.): `created_at`, `updated_at`, `submitted_at`, `filled_at`, `expired_at`, `canceled_at`, `failed_at`, `replaced_at`.
- **Account** (`AlpacaAccount$get_account()`): `created_at`.
- **Watchlists** (`$get_watchlists()`, `$get_watchlist()`, etc.): `created_at`, `updated_at`.
- **Activities** (`$get_activities()`, `$get_activities_by_type()`): `transaction_time`.
- **News** (`AlpacaMarketData$get_news()`): `created_at`, `updated_at`.
- **Snapshots** (`$get_snapshot()`, `$get_snapshots_multi()`): all five nested `*_timestamp` fields. Previously renamed but left as character — now parsed consistently with the standalone bar/trade/quote endpoints.

Use `lubridate::with_tz()` to view in any other timezone; the underlying instant is preserved.

## Calendar and clock return parsed datetimes (breaking)

`AlpacaMarketData$get_calendar()` and `$get_clock()` no longer return character columns for dates and times. Instead:

- `get_calendar()` returns `date`/`settlement_date` as `Date` and `open`/`close`/`session_open`/`session_close` as `POSIXct` localised to `America/New_York`. Alpaca's `/v2/calendar` reference page does not state a timezone explicitly; ET is inferred from `/v2` being US-only, the market-data FAQ using NY tz as canonical for bar aggregation, and `09:30` only making sense as ET wall-clock. The named tz handles DST automatically (a fixed `-05:00` would be wrong half the year). See the `AlpacaMarketData` class docs for the full reasoning.
- `get_clock()` returns `timestamp`/`next_open`/`next_close` as `POSIXct` in `America/New_York`. The wall-clock instant is preserved exactly — only the display tz is normalised. Use `lubridate::with_tz()` to view elsewhere.

The previous `@return` documentation also omitted `session_open`, `session_close`, and `settlement_date`; those are now enumerated.

The class-level `AlpacaMarketData` docs now carry a "Timezones" section spelling out the ET-by-inference assumption for calendar times (Alpaca does not state it explicitly on the reference page) and flagging that `/v3` multi-market endpoints will need per-market timezone lookup. A `TODO(v3)` marker sits next to the `ALPACA_EXCHANGE_TZ` constant in `R/helpers_parse.R` so a future migration is hard to miss.

## Internal: date / time helpers chokepoint (developer note)

`R/helpers_parse.R` now carries a top-of-file banner listing the five date / time helpers (`rfc3339_to_datetime`, `parse_timestamp_cols`, `parse_date_cols`, `combine_et_datetime`, `hhmm_to_hh_mm`) with a when-to-use-which guide. The `rfc3339_to_datetime()` roxygen also explains why it exists as a thin wrapper around `lubridate::as_datetime` (NULL / all-NA short-circuit, single chokepoint for any future change of parser). Future contributors should route all RFC-3339 / pure-date parsing through these helpers rather than calling `lubridate` directly.

## Data-shape convention: one entity = one row

Every method that returns nested API data now follows a single guiding policy: **identify the entity for the endpoint, and return one row per entity**. The supporting rules:

1. **Variable-length array of plain strings on a single entity** (`conditions`, `attributes`, `permissions`, `symbols`, `image_urls`, ...) → collapsed into a single character column joined by `;`. Filter with `dt[grepl("X", col)]`. Recover the original vector with `strsplit(col[1], ";", fixed = TRUE)[[1]]`.
2. **Variable-length array of objects** (orderbook levels, watchlist assets, multi-leg orders, ...) → exploded to long format with parent fields replicated and a position-index column added where order matters (`level`, `leg_index`, ...).
3. **Fixed-schema nested object** (snapshot bars, account configurations, ...) → flattened to wide `parent_child` columns.
4. **Empty / null arrays** → `NA_character_` (not list cells). Empty responses → empty `data.table`, not stub rows.

The separator is `;` rather than `,` because semicolons are far less likely to appear inside any of the values themselves. For fields where a value could legally contain `;` (URLs in news image fields), the value is percent-encoded before joining; recover with `URLdecode()` per element after `strsplit()`.

## REVERSALS (from earlier branch state, not from a released version)

* **Trades** — `get_latest_trade()`, `get_latest_trades_multi()`, and `get_trades()` previously exploded the trade-conditions array to long format (one row per condition code). They now return **one row per trade** with a `;`-joined `conditions` character column. The column name moved from `condition` (singular, long-form) to `conditions` (plural, collapsed).
* **News** — `get_news()` previously cross-joined `symbols` × `images` on each article, producing a cartesian (3 symbols × 6 images = 18 rows per article). It now returns **one row per article** with `symbols`, `image_sizes`, and `image_urls` as `;`-joined character columns. The column name moved from `symbol` (singular, long-form) to `symbols` (plural, collapsed).

## NEW LIST-COLUMN FIXES

* `get_assets()` / `get_asset()` — `attributes` was a list column; now a `;`-joined character (`"fractional_eh_enabled;has_options;..."`).
* `get_latest_quote()` / `get_latest_quotes_multi()` / `get_quotes()` — `conditions` was a list column; now `;`-joined character. One quote = one row regardless of how many condition codes it carries.
* `get_snapshot()` / `get_snapshots_multi()` — the inner `latest_trade_conditions` and `latest_quote_conditions` arrays were list columns; now `;`-joined character. Bar `c` close prices stay numeric.
* `get_news()` — additionally URL-encodes any literal `;` characters inside image URLs before joining (recover via `URLdecode()` per element).

## NEW FEATURES

* `get_crypto_orderbook()` (`AlpacaMarketData`) — wraps the `/v1beta3/crypto/{loc}/latest/orderbooks` endpoint. Returns a long-format `data.table` with `side` (`"bid"` / `"ask"`), `level`, `price`, `size`, `timestamp` columns.
* `get_account()` (`AlpacaAccount`) — the nested `admin_configurations` and `user_configurations` objects are now flattened to wide `parent_child` columns (e.g. `admin_configurations_max_options_trading_level`) instead of being carried as list columns.

## ORDERS: parent + leg row pattern

`add_order()`, `get_order()`, `get_orders()`, `get_order_by_client_id()`, `modify_order()` — multi-leg orders (`bracket` / `oco` / `oto`) now return a flat `data.table` with one row per order, parent and legs equally:

* `leg_index` (integer) — `NA` on the parent row, `1, 2, ...` on each leg in submission order.
* `parent_order_id` (character) — `NA` on the parent row, the parent's `id` on each leg row.

Useful filters: `dt[is.na(parent_order_id)]` for "just the parent orders", `dt[parent_order_id == "<id>"]` for "all legs of one specific bracket". Simple orders return one row with both helper columns `NA`.

## DOCUMENTATION

* `Verified:` markers bumped to 2026-05-22 on every method affected by this PR. Doc-link slugs updated to the post-`/us/` reorg paths where they had drifted (`stocksnapshotsingle`, `stocklatesttradesingle-1`, `getallorders-1`, etc.).
* `helpers_parse.R` carries a worked round-trip example in the `collapse_string_array_fields` docstring for both plain-string and URL-encoded fields (`strsplit()` and `URLdecode()` respectively).

## BUG FIXES

* `parse_news` cartesian inflation (3 symbols × 6 images = 18 rows per article) is fixed by collapsing both arrays instead of exploding both.
* `collapse_string_array_fields()` writes `NA_character_` for empty arrays so downstream `rbindlist()` builds a clean character column instead of falling back to list when some records have arrays and others don't.
* Removed usage of `%||%` operator which was not defined or imported; replaced with explicit `if (is.null(...))` checks in `helpers_request.R` and `test-bug-hunt.R`.

## TESTS

* 510/510 PASS across mocked unit tests + live integration tests against paper trading. New test coverage for: attribute collapse, news cartesian fix, percent-encode round trip, snapshot inner conditions collapse with bar close-price preservation, bracket-order parent/leg shape, no-list-columns assertions on every affected method.

## INTERNAL

* `collapse_string_array_fields(x, fields)` — shared helper used by `parse_asset`, `parse_news`, `parse_trades`, `parse_quotes`, and `parse_snapshot`. Emits a once-per-session `rlang::warn()` if any value being collapsed contains a literal `;` (so a future API change that admits the separator is loud rather than silent).

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
