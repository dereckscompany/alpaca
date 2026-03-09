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

- [ ] `AlpacaBase` R6 class (auth, request helpers, async support)
- [ ] `helpers_request.R` (request building, `then_or_now()`, response parsing)
- [ ] `helpers_validate.R` (input validation)
- [ ] `helpers_parse.R` (response parsing utilities)
- [ ] `get_api_keys()` and `get_base_url()` configuration helpers

### 2. Market Data — `AlpacaMarketData` class

- [ ] Bars (historical OHLCV)
- [ ] Latest bars / quotes / trades
- [ ] Snapshots
- [ ] Assets
- [ ] Calendar
- [ ] Clock

### 3. Trading — `AlpacaTrading` class

- [ ] Place order (market, limit, stop, stop-limit, trailing stop)
- [ ] Cancel order
- [ ] Get order by ID
- [ ] List orders
- [ ] Modify order (replace)

### 4. Account — `AlpacaAccount` class

- [ ] Account info
- [ ] Portfolio history
- [ ] Positions
- [ ] Close position
- [ ] Activities

### 5. Options — `AlpacaOptions` class

- [ ] Options contracts
- [ ] Options orders
- [ ] Options positions

---

## Won't do (for now)

- **WebSocket**: real-time streaming — significant separate architecture
- **OAuth**: broker-dealer OAuth flow — only relevant for multi-tenant apps
- **Crypto**: Alpaca crypto endpoints — may add later
