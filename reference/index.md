# Package index

## Configuration

API credential and endpoint helpers

- [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md)
  : Retrieve Alpaca API Credentials
- [`get_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_base_url.md)
  : Retrieve Alpaca API Base URL
- [`get_data_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_data_base_url.md)
  : Retrieve Alpaca Market Data API Base URL
- [`time_convert_from_alpaca()`](https://dereckscompany.github.io/alpaca/reference/time_convert_from_alpaca.md)
  : Convert RFC-3339 Timestamp to POSIXct
- [`time_convert_to_alpaca()`](https://dereckscompany.github.io/alpaca/reference/time_convert_to_alpaca.md)
  : Convert POSIXct to RFC-3339 Timestamp String

## Base Class

Abstract base class shared by all API clients

- [`AlpacaBase`](https://dereckscompany.github.io/alpaca/reference/AlpacaBase.md)
  : AlpacaBase: Abstract Base Class for Alpaca API Clients

## Market Data

Stock market data (bars, trades, quotes, snapshots, assets, calendar,
clock)

- [`AlpacaMarketData`](https://dereckscompany.github.io/alpaca/reference/AlpacaMarketData.md)
  : AlpacaMarketData: Market Data, Assets, Calendar, and Clock

## Trading

Order management (place, cancel, query, modify)

- [`AlpacaTrading`](https://dereckscompany.github.io/alpaca/reference/AlpacaTrading.md)
  : AlpacaTrading: Order Management

## Account

Account info, positions, portfolio history, activities, and watchlists

- [`AlpacaAccount`](https://dereckscompany.github.io/alpaca/reference/AlpacaAccount.md)
  : AlpacaAccount: Account, Positions, and Portfolio

## Options

Options contracts, bars, trades, and snapshots

- [`AlpacaOptions`](https://dereckscompany.github.io/alpaca/reference/AlpacaOptions.md)
  : AlpacaOptions: Options Contracts and Data

## Backfill and Data

Bulk data download and sample datasets

- [`alpaca_backfill_bars()`](https://dereckscompany.github.io/alpaca/reference/alpaca_backfill_bars.md)
  : Backfill Historical Bar Data
- [`alpaca_aapl_1day_bars`](https://dereckscompany.github.io/alpaca/reference/alpaca_aapl_1day_bars.md)
  : AAPL Daily OHLCV Bars (Sample Data)

## Request Infrastructure

Low-level request building, execution, and pagination

- [`alpaca_build_request()`](https://dereckscompany.github.io/alpaca/reference/alpaca_build_request.md)
  : Build and Execute an Alpaca API Request
- [`alpaca_paginate()`](https://dereckscompany.github.io/alpaca/reference/alpaca_paginate.md)
  : Auto-Paginate an Alpaca API Endpoint
