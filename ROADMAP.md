# alpaca — Roadmap

> Version 0.1.0 (unreleased) · Last updated 2026-03-09

## Naming convention

| Verb | Meaning | Suffixes |
|------|---------|----------|
| `get_*` | Query | `_by_id` |
| `add_*` | Create (POST) | |
| `cancel_*` | Cancel (DELETE) | `_by_id` |
| `modify_*` | Amend in place | |
| `set_*` | Configure | |

snake_case throughout. No API version numbers in method names.

---

## TODO

### 1. Core infrastructure

- [x] `AlpacaBase` R6 class (auth, request helpers, async support)
- [x] `helpers_request.R` (request building, `then_or_now()`, response parsing)
- [x] `helpers_validate.R` (input validation)
- [x] `helpers_parse.R` (response parsing utilities)
- [x] `get_api_keys()` and `get_base_url()` configuration helpers

### 2. Market Data — `AlpacaMarketData` class

- [x] Bars (historical OHLCV)
- [x] Latest bars / quotes / trades
- [x] Snapshots
- [x] Assets
- [x] Calendar
- [x] Clock

### 3. Trading — `AlpacaTrading` class

- [x] Place order (market, limit, stop, stop-limit, trailing stop)
- [x] Cancel order
- [x] Get order by ID
- [x] List orders
- [x] Modify order (replace)

### 4. Account — `AlpacaAccount` class

- [x] Account info
- [x] Portfolio history
- [x] Positions
- [x] Close position
- [x] Activities

### 5. Options — `AlpacaOptions` class

- [x] Options contracts
- [x] Options market data (bars, trades, quotes, snapshots)
- [ ] Options orders (via AlpacaTrading with position_intent)

### 6. Utilities and infrastructure

- [x] `utils_time.R` — `time_convert_from_alpaca()` / `time_convert_to_alpaca()`
- [x] `impl_bars.R` — time-range segmented bar fetching
- [x] `backfill.R` — `alpaca_backfill_bars()` with CSV-based resume
- [x] Tests — mocked unit tests for all R6 classes and helpers (172 tests)
- [ ] Sample dataset — bundled AAPL daily bars for examples
- [ ] Watchlists — `GET/POST/PUT/DELETE /v2/watchlists`
- [ ] Corporate Actions — `GET /v2/corporate_actions/announcements`
- [ ] News — `GET /v1beta1/news`

---

## Won't do (for now)

- **WebSocket**: real-time streaming — significant separate architecture
- **OAuth**: broker-dealer OAuth flow — only relevant for multi-tenant apps
- **Crypto**: Alpaca crypto endpoints — may add later
