# alpaca — Roadmap

> Version 0.1.0 · Last updated 2026-03-11

## Naming convention

| Verb       | Meaning         | Suffixes |
|------------|-----------------|----------|
| `get_*`    | Query           | `_by_id` |
| `add_*`    | Create (POST)   |          |
| `cancel_*` | Cancel (DELETE) | `_by_id` |
| `modify_*` | Amend in place  |          |
| `set_*`    | Configure       |          |

snake_case throughout. No API version numbers in method names.

------------------------------------------------------------------------

## TODO

### 1. Core infrastructure

`AlpacaBase` R6 class (auth, request helpers, async support)

`helpers_request.R` (request building, `then_or_now()`, response
parsing)

`helpers_validate.R` (input validation)

`helpers_parse.R` (response parsing utilities)

[`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md)
and
[`get_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_base_url.md)
configuration helpers

### 2. Market Data — `AlpacaMarketData` class

Bars (historical OHLCV)

Latest bars / quotes / trades

Snapshots

Assets

Calendar

Clock

Corporate Actions — `GET /v2/corporate_actions/announcements`

News — `GET /v1beta1/news`

### 3. Trading — `AlpacaTrading` class

Place order (market, limit, stop, stop-limit, trailing stop)

Cancel order

Get order by ID

List orders

Modify order (replace)

### 4. Account — `AlpacaAccount` class

Account info

Portfolio history

Positions

Close position

Activities

Watchlists — `GET/POST/PUT/DELETE /v2/watchlists`

### 5. Options — `AlpacaOptions` class

Options contracts

Options market data (bars, trades, quotes, snapshots)

Options orders (via AlpacaTrading with `position_intent`)

### 6. Utilities and infrastructure

`utils_time.R` —
[`time_convert_from_alpaca()`](https://dereckscompany.github.io/alpaca/reference/time_convert_from_alpaca.md)
/
[`time_convert_to_alpaca()`](https://dereckscompany.github.io/alpaca/reference/time_convert_to_alpaca.md)

`impl_bars.R` — time-range segmented bar fetching

`backfill.R` —
[`alpaca_backfill_bars()`](https://dereckscompany.github.io/alpaca/reference/alpaca_backfill_bars.md)
with CSV-based resume

Tests — mocked unit tests for all R6 classes and helpers

Sample dataset — bundled AAPL daily bars
(`data/alpaca_aapl_1day_bars.rda`)

[`alpaca_paginate()`](https://dereckscompany.github.io/alpaca/reference/alpaca_paginate.md)
— auto-pagination for cursor-based endpoints

Margin/short-selling vignette

------------------------------------------------------------------------

## Won’t do (for now)

- **WebSocket**: real-time streaming — significant separate architecture
- **OAuth**: broker-dealer OAuth flow — only relevant for multi-tenant
  apps
- **Crypto**: Alpaca crypto endpoints — may add later
