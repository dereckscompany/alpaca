# AlpacaOptions: Options Contracts and Data

AlpacaOptions: Options Contracts and Data

AlpacaOptions: Options Contracts and Data

## Details

Provides methods for querying options contracts, retrieving options
market data (bars, trades, quotes, snapshots), and placing options
orders on Alpaca's API.

Inherits from
[AlpacaBase](https://dereckscompany.github.io/alpaca/reference/AlpacaBase.md).
All methods support both synchronous and asynchronous execution
depending on the `async` parameter at construction.

### Purpose and Scope

- **Contracts**: Search and filter available options contracts.

- **Market Data**: Retrieve historical and latest options market data.

- **Snapshots**: Get real-time snapshots of options contracts.

- **Options Chain**: Retrieve the full options chain for an underlying.

### Base URLs

Options market data endpoints use `https://data.alpaca.markets`.
Contract metadata endpoints use the trading base URL.

### Official Documentation

- [Options
  Contracts](https://docs.alpaca.markets/us/reference/get-options-contracts)

- [Options Market
  Data](https://docs.alpaca.markets/us/docs/historical-option-data)

### Endpoints Covered

|  |  |  |
|----|----|----|
| Method | Endpoint | Base |
| get_contracts | `GET /v2/options/contracts` | trading |
| get_contract | `GET /v2/options/contracts/\{symbol_or_id\}` | trading |
| get_option_bars | `GET /v1beta1/options/bars` | data |
| get_option_trades | `GET /v1beta1/options/trades` | data |
| get_option_latest_quotes | `GET /v1beta1/options/quotes/latest` | data |
| get_option_snapshots | `GET /v1beta1/options/snapshots` | data |
| get_option_snapshot | `GET /v1beta1/options/snapshots/\{symbol\}` | data |
| get_option_latest_trades | `GET /v1beta1/options/trades/latest` | data |
| get_option_chain | `GET /v1beta1/options/snapshots/\{underlying_symbol\}` | data |

## Super classes

[`connectcore::RestClient`](https://rdrr.io/pkg/connectcore/man/RestClient.html)
-\>
[`alpaca::AlpacaBase`](https://dereckscompany.github.io/alpaca/reference/AlpacaBase.md)
-\> `AlpacaOptions`

## Methods

### Public methods

- [`AlpacaOptions$new()`](#method-AlpacaOptions-new)

- [`AlpacaOptions$get_contracts()`](#method-AlpacaOptions-get_contracts)

- [`AlpacaOptions$get_contract()`](#method-AlpacaOptions-get_contract)

- [`AlpacaOptions$get_option_bars()`](#method-AlpacaOptions-get_option_bars)

- [`AlpacaOptions$get_option_trades()`](#method-AlpacaOptions-get_option_trades)

- [`AlpacaOptions$get_option_latest_quotes()`](#method-AlpacaOptions-get_option_latest_quotes)

- [`AlpacaOptions$get_option_latest_trades()`](#method-AlpacaOptions-get_option_latest_trades)

- [`AlpacaOptions$get_option_snapshots()`](#method-AlpacaOptions-get_option_snapshots)

- [`AlpacaOptions$get_option_snapshot()`](#method-AlpacaOptions-get_option_snapshot)

- [`AlpacaOptions$get_option_chain()`](#method-AlpacaOptions-get_option_chain)

- [`AlpacaOptions$clone()`](#method-AlpacaOptions-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise an AlpacaOptions Object

Creates a new AlpacaOptions instance for querying options contracts,
market data, and options chain information.

#### API Endpoint

Constructor only — no HTTP request is made.

#### Official Documentation

- [Options Trading
  Overview](https://docs.alpaca.markets/us/docs/options-trading)
  Verified: 2026-05-21

#### curl

    # No HTTP request — this is a constructor. Verify credentials with:
    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/options/contracts?limit=1'

#### JSON Response

    # N/A — constructor does not make an HTTP request.

#### Usage

    AlpacaOptions$new(
      keys = get_api_keys(),
      base_url = get_base_url(),
      data_base_url = get_data_base_url(),
      async = FALSE
    )

#### Arguments

- `keys`:

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) trading API base URL. Defaults to
  [`get_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_base_url.md).

- `data_base_url`:

  (scalar\<character\>) market data API base URL. Defaults to
  [`get_data_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_data_base_url.md).

- `async`:

  (scalar\<logical\>) if `TRUE`, methods return promises. Default
  `FALSE`.

#### Returns

(class\<AlpacaOptions\>) invisibly, self.

------------------------------------------------------------------------

### Method `get_contracts()`

Get Options Contracts

Searches for available options contracts with filtering by underlying
symbol, type, expiration date, strike price, and more.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/options/contracts`

#### Official Documentation

- [Get Options
  Contracts](https://docs.alpaca.markets/us/reference/get-options-contracts)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/options/contracts?underlying_symbols=AAPL&type=call&limit=5'

#### JSON Response

    {
      "option_contracts": [
        {
          "id": "uuid",
          "symbol": "AAPL240621C00200000",
          "name": "AAPL Jun 21 2024 200.00 Call",
          "status": "active",
          "tradable": true,
          "type": "call",
          "strike_price": "200.00",
          "expiration_date": "2024-06-21",
          "underlying_symbol": "AAPL",
          "underlying_asset_id": "uuid",
          "style": "american",
          "root_symbol": "AAPL",
          "size": "100",
          "open_interest": "1234",
          "close_price": "5.50"
        }
      ],
      "next_page_token": null
    }

#### Usage

    AlpacaOptions$get_contracts(
      underlying_symbols = NULL,
      status = NULL,
      type = NULL,
      expiration_date = NULL,
      expiration_date_gte = NULL,
      expiration_date_lte = NULL,
      strike_price_gte = NULL,
      strike_price_lte = NULL,
      root_symbol = NULL,
      style = NULL,
      limit = NULL,
      page_token = NULL,
      show_deliverables = NULL,
      ppind = NULL
    )

#### Arguments

- `underlying_symbols`:

  (scalar\<character\> \| NULL) comma-separated underlying symbols to
  filter (e.g., `"AAPL"` or `"AAPL,MSFT"`).

- `status`:

  (scalar\<character\> \| NULL) contract status (`"active"`,
  `"inactive"`).

- `type`:

  (scalar\<character\> \| NULL) option type (`"call"`, `"put"`).

- `expiration_date`:

  (scalar\<character\> \| NULL) exact expiration date (`"YYYY-MM-DD"`).

- `expiration_date_gte`:

  (scalar\<character\> \| NULL) expiration on or after this date.

- `expiration_date_lte`:

  (scalar\<character\> \| NULL) expiration on or before this date.

- `strike_price_gte`:

  (scalar\<numeric\> \| NULL) minimum strike price.

- `strike_price_lte`:

  (scalar\<numeric\> \| NULL) maximum strike price.

- `root_symbol`:

  (scalar\<character\> \| NULL) options root symbol.

- `style`:

  (scalar\<character\> \| NULL) option style (`"american"`,
  `"european"`).

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max contracts to return
  (default 100, max 10000).

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

- `show_deliverables`:

  (scalar\<logical\> \| NULL) if `TRUE`, include the `deliverables`
  array in the response.

- `ppind`:

  (scalar\<logical\> \| NULL) filter by Penny Program Indicator. `TRUE`
  returns only contracts eligible for penny price increments.

#### Returns

(Contract \| promise\<Contract\>) the contracts. With
`show_deliverables = NULL` (default) or `FALSE`, returns one row per
contract. With `show_deliverables = TRUE`, the nested `deliverables`
array is exploded to one row per `(contract, deliverable)`; contract
fields are replicated on each row, deliverable fields appear as
`deliverable_*` columns, and a 1-indexed `deliverable_index` is added.
Filter to canonical per-contract rows with
`dt[deliverable_index == 1L | is.na(deliverable_index)]`. Contract
columns: `id`, `symbol`, `name`, `status`, `type`, `strike_price`,
`underlying_symbol`, `style`, `root_symbol`, `size`, `open_interest`,
`close_price` (character); `tradable` (logical); `expiration_date`,
`open_interest_date`, `close_price_date` (Date). Deliverable columns
(only when `show_deliverables = TRUE`): `deliverable_index`,
`deliverable_type`, `deliverable_symbol`, `deliverable_asset_id`,
`deliverable_amount`, `deliverable_allocation_percentage`,
`deliverable_settlement_type`, `deliverable_settlement_method`,
`deliverable_delayed_settlement`.

#### Examples

    \dontrun{
    opts <- AlpacaOptions$new()

    # Find AAPL calls expiring after June 2024
    contracts <- opts$get_contracts(
      underlying_symbols = "AAPL",
      type = "call",
      expiration_date_gte = "2024-06-01",
      limit = 10
    )
    print(contracts)
    }

------------------------------------------------------------------------

### Method `get_contract()`

Get Option Contract by Symbol or ID

Retrieves a single options contract by its OCC symbol or UUID.

#### API Endpoint

`GET https://paper-api.alpaca.markets/v2/options/contracts/{symbol_or_id}`

#### Official Documentation

- [Get Option Contract by ID or
  Symbol](https://docs.alpaca.markets/us/reference/get-option-contract-symbol_or_id)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://paper-api.alpaca.markets/v2/options/contracts/AAPL250620C00200000'

#### JSON Response

    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "symbol": "AAPL250620C00200000",
      "name": "AAPL Jun 20 2025 200.00 Call",
      "status": "active",
      "tradable": true,
      "type": "call",
      "strike_price": "200",
      "expiration_date": "2025-06-20",
      "underlying_symbol": "AAPL",
      "underlying_asset_id": "b28f4066-5c6d-479b-a2af-85dc1a8f02fd",
      "style": "american",
      "root_symbol": "AAPL",
      "size": "100",
      "open_interest": "8523",
      "open_interest_date": "2025-03-07",
      "close_price": "12.35",
      "close_price_date": "2025-03-07"
    }

#### Usage

    AlpacaOptions$get_contract(symbol_or_id)

#### Arguments

- `symbol_or_id`:

  (scalar\<character\>) OCC option symbol or contract UUID.

#### Returns

(Contract \| promise\<Contract\>) the contract, with the same columns as
`get_contracts()`, single row.

#### Examples

    \dontrun{
    opts <- AlpacaOptions$new()
    contract <- opts$get_contract("AAPL240621C00200000")
    print(contract)
    }

------------------------------------------------------------------------

### Method `get_option_bars()`

Get Options Bars (OHLCV)

Retrieves historical bar data for options contracts.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/bars`

#### Official Documentation

- [Options Bars](https://docs.alpaca.markets/us/reference/optionbars)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/bars?symbols=AAPL250620C00200000&timeframe=1Day&start=2025-03-01&limit=5'

#### JSON Response

    {
      "bars": {
        "AAPL250620C00200000": [
          {
            "t": "2025-03-03T05:00:00Z",
            "o": 11.80,
            "h": 13.25,
            "l": 11.50,
            "c": 12.90,
            "v": 4523,
            "n": 312,
            "vw": 12.45
          },
          {
            "t": "2025-03-04T05:00:00Z",
            "o": 12.90,
            "h": 14.10,
            "l": 12.60,
            "c": 13.75,
            "v": 5891,
            "n": 428,
            "vw": 13.30
          }
        ]
      },
      "next_page_token": null
    }

#### Usage

    AlpacaOptions$get_option_bars(
      symbols,
      timeframe = "1Day",
      start = NULL,
      end = NULL,
      limit = NULL,
      page_token = NULL,
      sort = NULL
    )

#### Arguments

- `symbols`:

  (scalar\<character\>) comma-separated OCC option symbols.

- `timeframe`:

  (scalar\<character\>) bar timeframe (e.g., `"1Day"`, `"1Hour"`).

- `start`:

  (scalar\<character\> \| NULL) start date/time (RFC-3339 or
  `"YYYY-MM-DD"`).

- `end`:

  (scalar\<character\> \| NULL) end date/time.

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max bars (1-10000, default
  1000).

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

- `sort`:

  (scalar\<character\> \| NULL) `"asc"` (default) or `"desc"`.

#### Returns

(BarsMulti \| promise\<BarsMulti\>) **one row per bar** with a leading
`symbol` column. Bar columns mirror the equity `get_bars()` output:
`timestamp` (POSIXct), `open`, `high`, `low`, `close`, `vwap` (numeric),
`volume`, `trade_count` (integer).

#### Examples

    \dontrun{
    opts <- AlpacaOptions$new()
    bars <- opts$get_option_bars(
      "AAPL240621C00200000", timeframe = "1Day",
      start = "2024-06-01"
    )
    print(bars)
    }

------------------------------------------------------------------------

### Method `get_option_trades()`

Get Options Trades

Retrieves historical trade data for options contracts.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/trades`

#### Official Documentation

- [Options
  Trades](https://docs.alpaca.markets/us/reference/optiontrades)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/trades?symbols=AAPL250620C00200000&start=2025-03-01&limit=5'

#### JSON Response

    {
      "trades": {
        "AAPL250620C00200000": [
          {
            "t": "2025-03-03T14:30:02.123456Z",
            "p": 12.35,
            "s": 10,
            "x": "C",
            "c": ["a", "I"]
          },
          {
            "t": "2025-03-03T14:31:15.654321Z",
            "p": 12.40,
            "s": 5,
            "x": "P",
            "c": ["a"]
          }
        ]
      },
      "next_page_token": null
    }

#### Usage

    AlpacaOptions$get_option_trades(
      symbols,
      start = NULL,
      end = NULL,
      limit = NULL,
      page_token = NULL,
      sort = NULL
    )

#### Arguments

- `symbols`:

  (scalar\<character\>) comma-separated OCC option symbols.

- `start`:

  (scalar\<character\> \| NULL) start date/time.

- `end`:

  (scalar\<character\> \| NULL) end date/time.

- `limit`:

  (scalar\<count in \[1, 10001\[\> \| NULL) max trades (1-10000, default
  1000).

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

- `sort`:

  (scalar\<character\> \| NULL) `"asc"` (default) or `"desc"`.

#### Returns

(OptionTradesMulti \| promise\<OptionTradesMulti\>) **one row per
trade** with a leading `symbol` column. Columns: `timestamp` (POSIXct),
`price` (numeric), `size` (integer), `exchange` (character),
`conditions` (character, `;`-separated trade condition codes or a
single-character code; `NA` when none reported), `id` (integer). The
options trade payload carries no consolidated tape, so there is no
`tape` column (unlike the equity trade shape).

------------------------------------------------------------------------

### Method `get_option_latest_quotes()`

Get Latest Options Quotes

Retrieves the latest NBBO quotes for one or more options contracts.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/quotes/latest`

#### Official Documentation

- [Latest Options
  Quotes](https://docs.alpaca.markets/us/reference/optionlatestquotes)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/quotes/latest?symbols=AAPL250620C00200000'

#### JSON Response

    {
      "quotes": {
        "AAPL250620C00200000": {
          "t": "2025-03-07T20:59:58.123456Z",
          "ax": "C",
          "ap": 12.50,
          "as": 15,
          "bx": "P",
          "bp": 12.30,
          "bs": 22,
          "c": "A"
        }
      }
    }

#### Usage

    AlpacaOptions$get_option_latest_quotes(symbols, feed = NULL)

#### Arguments

- `symbols`:

  (scalar\<character\>) comma-separated OCC option symbols.

- `feed`:

  (scalar\<character\> \| NULL) `"opra"` (default, official OPRA feed)
  or `"indicative"` (free, delayed/modified).

#### Returns

(OptionQuotesMulti \| promise\<OptionQuotesMulti\>) **one row per
contract** with a leading `symbol` column. Columns: `timestamp`
(POSIXct); `ask_exchange`, `ask_price`, `ask_size`, `bid_exchange`,
`bid_price`, `bid_size`; and `conditions` (character, `;`-separated
quote condition codes or a single-character code; `NA` when none
reported).

------------------------------------------------------------------------

### Method `get_option_latest_trades()`

Get Latest Options Trades

Retrieves the latest trades for one or more options contracts.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/trades/latest`

#### Official Documentation

- [Latest Options
  Trades](https://docs.alpaca.markets/us/reference/optionlatesttrades)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/trades/latest?symbols=AAPL250620C00200000'

#### JSON Response

    {
      "trades": {
        "AAPL250620C00200000": {
          "t": "2025-03-07T20:58:45.987654Z",
          "p": 12.35,
          "s": 3,
          "x": "C",
          "c": ["a"]
        }
      }
    }

#### Usage

    AlpacaOptions$get_option_latest_trades(symbols, feed = NULL)

#### Arguments

- `symbols`:

  (scalar\<character\>) comma-separated OCC option symbols.

- `feed`:

  (scalar\<character\> \| NULL) data feed.

#### Returns

(OptionTradesMulti \| promise\<OptionTradesMulti\>) **one row per
contract** with a leading `symbol` column. Columns: `timestamp`
(POSIXct), `price` (numeric), `size` (integer), `exchange` (character),
`conditions` (character, `;`-separated trade condition codes or a
single-character code; `NA` when none reported), `id` (integer). The
options trade payload carries no consolidated tape, so there is no
`tape` column (unlike the equity trade shape).

------------------------------------------------------------------------

### Method `get_option_snapshots()`

Get Options Snapshots

Retrieves real-time snapshots for multiple options contracts, including
the latest trade, latest quote, and implied volatility.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/snapshots`

#### Official Documentation

- [Options
  Snapshots](https://docs.alpaca.markets/us/reference/optionsnapshots)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/snapshots?symbols=AAPL250620C00200000,AAPL250620P00200000'

#### JSON Response

    {
      "snapshots": {
        "AAPL250620C00200000": {
          "latestTrade": {
            "t": "2025-03-07T20:58:45.987654Z",
            "p": 12.35,
            "s": 3,
            "x": "C",
            "c": ["a"]
          },
          "latestQuote": {
            "t": "2025-03-07T20:59:58.123456Z",
            "ax": "C",
            "ap": 12.50,
            "as": 15,
            "bx": "P",
            "bp": 12.30,
            "bs": 22,
            "c": "A"
          },
          "impliedVolatility": 0.2856,
          "greeks": {
            "delta": 0.5423,
            "gamma": 0.0187,
            "theta": -0.0842,
            "vega": 0.3215,
            "rho": 0.1456
          }
        },
        "AAPL250620P00200000": {
          "latestTrade": {
            "t": "2025-03-07T20:57:30.456789Z",
            "p": 8.75,
            "s": 5,
            "x": "P",
            "c": ["a"]
          },
          "latestQuote": {
            "t": "2025-03-07T20:59:55.789012Z",
            "ax": "P",
            "ap": 8.90,
            "as": 10,
            "bx": "C",
            "bp": 8.60,
            "bs": 18,
            "c": "A"
          },
          "impliedVolatility": 0.2712,
          "greeks": {
            "delta": -0.4577,
            "gamma": 0.0187,
            "theta": -0.0756,
            "vega": 0.3215,
            "rho": -0.1289
          }
        }
      }
    }

#### Usage

    AlpacaOptions$get_option_snapshots(
      symbols,
      feed = NULL,
      updated_since = NULL,
      limit = NULL,
      page_token = NULL
    )

#### Arguments

- `symbols`:

  (scalar\<character\>) comma-separated OCC option symbols.

- `feed`:

  (scalar\<character\> \| NULL) `"opra"` (default) or `"indicative"`.

- `updated_since`:

  (scalar\<character\> \| NULL) only return snapshots updated at or
  after this timestamp (RFC-3339 or `"YYYY-MM-DD"`).

- `limit`:

  (scalar\<count in \[1, 1001\[\> \| NULL) max snapshots (1-1000,
  default 100).

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

#### Returns

(SnapshotMulti \| promise\<SnapshotMulti\>) **one row per contract**.
Columns: `symbol` (character, OCC option symbol); the flattened
`latest_trade_*` / `latest_quote_*` / `minute_bar_*` / `daily_bar_*` /
`prev_daily_bar_*` sections (see `get_snapshot()` for the per-field
listing — `latest_trade_t` etc. expand to `latest_trade_timestamp` etc.;
`latest_trade_conditions` / `latest_quote_conditions` are character
columns, `;`-collapsed when Alpaca returns multiple codes); and the
optional `implied_volatility` plus `greeks_delta` / `greeks_gamma` /
`greeks_theta` / `greeks_vega` / `greeks_rho` (numeric) — present only
when the account's options data subscription includes greeks/IV (absent
on the default paper-trading `indicative` feed). Guard with
`if ("implied_volatility" %in% names(dt)) ...` to handle both shapes.

------------------------------------------------------------------------

### Method `get_option_snapshot()`

Get Option Snapshot by Symbol

Retrieves a real-time snapshot for a single options contract.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/snapshots/{symbol}`

#### Official Documentation

- [Option
  Snapshot](https://docs.alpaca.markets/us/reference/optionsnapshots)
  Verified: 2026-05-21

Note: Alpaca no longer documents a per-symbol snapshot endpoint; the URL
`/v1beta1/options/snapshots/{symbol}` is the underlying-chain endpoint
(see `get_option_chain()`). For a true single-contract snapshot, prefer
`get_option_snapshots(symbols = "AAPL250620C00200000")`.

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/snapshots/AAPL250620C00200000'

#### JSON Response

    {
      "latestTrade": {
        "t": "2025-03-07T20:58:45.987654Z",
        "p": 12.35,
        "s": 3,
        "x": "C",
        "c": ["a"]
      },
      "latestQuote": {
        "t": "2025-03-07T20:59:58.123456Z",
        "ax": "C",
        "ap": 12.50,
        "as": 15,
        "bx": "P",
        "bp": 12.30,
        "bs": 22,
        "c": "A"
      },
      "impliedVolatility": 0.2856,
      "greeks": {
        "delta": 0.5423,
        "gamma": 0.0187,
        "theta": -0.0842,
        "vega": 0.3215,
        "rho": 0.1456
      }
    }

#### Usage

    AlpacaOptions$get_option_snapshot(symbol, feed = NULL)

#### Arguments

- `symbol`:

  (scalar\<character\>) OCC option symbol.

- `feed`:

  (scalar\<character\> \| NULL) data feed.

#### Returns

(SnapshotMulti \| promise\<SnapshotMulti\>) the same shape as
`get_option_chain()` — one row per contract in the chain rooted at
`symbol`. Despite the legacy name, this is **not** a single-contract
snapshot; for that, use `get_option_snapshots(symbols = "<OCC>")`.

#### Examples

    \dontrun{
    opts <- AlpacaOptions$new()
    snap <- opts$get_option_snapshot("AAPL240621C00200000")
    print(snap)
    }

------------------------------------------------------------------------

### Method `get_option_chain()`

Get Options Chain

Retrieves the full options chain for an underlying symbol. Returns all
available contracts with their latest market data.

#### API Endpoint

`GET https://data.alpaca.markets/v1beta1/options/snapshots/{underlying_symbol}`

#### Official Documentation

- [Options Chain / Snapshots by
  Underlying](https://docs.alpaca.markets/us/reference/optionchain)
  Verified: 2026-05-21

#### curl

    curl -H "APCA-API-KEY-ID: $KEY" -H "APCA-API-SECRET-KEY: $SECRET" \
      'https://data.alpaca.markets/v1beta1/options/snapshots/AAPL?type=call&expiration_date_gte=2025-06-01&strike_price_gte=190&strike_price_lte=210&limit=5'

#### JSON Response

    {
      "snapshots": {
        "AAPL250620C00195000": {
          "latestTrade": {
            "t": "2025-03-07T20:55:12.345678Z",
            "p": 15.20,
            "s": 2,
            "x": "C",
            "c": ["a"]
          },
          "latestQuote": {
            "t": "2025-03-07T20:59:50.123456Z",
            "ax": "P",
            "ap": 15.40,
            "as": 12,
            "bx": "C",
            "bp": 15.00,
            "bs": 20,
            "c": "A"
          },
          "impliedVolatility": 0.2734,
          "greeks": {
            "delta": 0.6012,
            "gamma": 0.0165,
            "theta": -0.0912,
            "vega": 0.3089,
            "rho": 0.1623
          }
        },
        "AAPL250620C00200000": {
          "latestTrade": {
            "t": "2025-03-07T20:58:45.987654Z",
            "p": 12.35,
            "s": 3,
            "x": "C",
            "c": ["a"]
          },
          "latestQuote": {
            "t": "2025-03-07T20:59:58.123456Z",
            "ax": "C",
            "ap": 12.50,
            "as": 15,
            "bx": "P",
            "bp": 12.30,
            "bs": 22,
            "c": "A"
          },
          "impliedVolatility": 0.2856,
          "greeks": {
            "delta": 0.5423,
            "gamma": 0.0187,
            "theta": -0.0842,
            "vega": 0.3215,
            "rho": 0.1456
          }
        }
      },
      "next_page_token": null
    }

#### Usage

    AlpacaOptions$get_option_chain(
      underlying_symbol,
      type = NULL,
      expiration_date = NULL,
      expiration_date_gte = NULL,
      expiration_date_lte = NULL,
      strike_price_gte = NULL,
      strike_price_lte = NULL,
      root_symbol = NULL,
      feed = NULL,
      limit = NULL,
      page_token = NULL,
      updated_since = NULL
    )

#### Arguments

- `underlying_symbol`:

  (scalar\<character\>) the underlying ticker symbol (e.g., `"AAPL"`).

- `type`:

  (scalar\<character\> \| NULL) `"call"`, `"put"`.

- `expiration_date`:

  (scalar\<character\> \| NULL) exact expiration date (`"YYYY-MM-DD"`).

- `expiration_date_gte`:

  (scalar\<character\> \| NULL) expiration on or after this date.

- `expiration_date_lte`:

  (scalar\<character\> \| NULL) expiration on or before this date.

- `strike_price_gte`:

  (scalar\<numeric\> \| NULL) minimum strike price.

- `strike_price_lte`:

  (scalar\<numeric\> \| NULL) maximum strike price.

- `root_symbol`:

  (scalar\<character\> \| NULL) options root symbol.

- `feed`:

  (scalar\<character\> \| NULL) `"opra"` (default) or `"indicative"`.

- `limit`:

  (scalar\<count in \[1, 1001\[\> \| NULL) max results (1-1000, default
  100).

- `page_token`:

  (scalar\<character\> \| NULL) cursor for pagination.

- `updated_since`:

  (scalar\<character\> \| NULL) only snapshots updated at or after this
  timestamp (RFC-3339 or `"YYYY-MM-DD"`).

#### Returns

(SnapshotMulti \| promise\<SnapshotMulti\>) **one row per contract in
the chain**. Columns mirror `get_option_snapshots()`: a `symbol` key,
the flattened `latest_trade_*` / `latest_quote_*` / `minute_bar_*` /
`daily_bar_*` / `prev_daily_bar_*` blocks (including
`latest_trade_conditions` / `latest_quote_conditions`), and — when the
account's options data subscription includes them — the optional
`implied_volatility` and `greeks_delta` / `greeks_gamma` /
`greeks_theta` / `greeks_vega` / `greeks_rho` columns. The greeks/IV
columns are absent for the default paper-trading `indicative` feed
without a subscription.

#### Examples

    \dontrun{
    opts <- AlpacaOptions$new()
    chain <- opts$get_option_chain("AAPL", type = "call",
                                    expiration_date_gte = "2024-06-01")
    print(chain)
    }

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AlpacaOptions$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
opts <- AlpacaOptions$new()

# Search for AAPL call options
contracts <- opts$get_contracts(
  underlying_symbols = "AAPL",
  type = "call",
  expiration_date_gte = "2024-06-01",
  limit = 10
)
print(contracts[, .(symbol, type, strike_price, expiration_date)])
} # }


## ------------------------------------------------
## Method `AlpacaOptions$get_contracts`
## ------------------------------------------------

if (FALSE) { # \dontrun{
opts <- AlpacaOptions$new()

# Find AAPL calls expiring after June 2024
contracts <- opts$get_contracts(
  underlying_symbols = "AAPL",
  type = "call",
  expiration_date_gte = "2024-06-01",
  limit = 10
)
print(contracts)
} # }

## ------------------------------------------------
## Method `AlpacaOptions$get_contract`
## ------------------------------------------------

if (FALSE) { # \dontrun{
opts <- AlpacaOptions$new()
contract <- opts$get_contract("AAPL240621C00200000")
print(contract)
} # }

## ------------------------------------------------
## Method `AlpacaOptions$get_option_bars`
## ------------------------------------------------

if (FALSE) { # \dontrun{
opts <- AlpacaOptions$new()
bars <- opts$get_option_bars(
  "AAPL240621C00200000", timeframe = "1Day",
  start = "2024-06-01"
)
print(bars)
} # }

## ------------------------------------------------
## Method `AlpacaOptions$get_option_snapshot`
## ------------------------------------------------

if (FALSE) { # \dontrun{
opts <- AlpacaOptions$new()
snap <- opts$get_option_snapshot("AAPL240621C00200000")
print(snap)
} # }

## ------------------------------------------------
## Method `AlpacaOptions$get_option_chain`
## ------------------------------------------------

if (FALSE) { # \dontrun{
opts <- AlpacaOptions$new()
chain <- opts$get_option_chain("AAPL", type = "call",
                                expiration_date_gte = "2024-06-01")
print(chain)
} # }
```
