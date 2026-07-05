# Auto-Paginate an Alpaca API Endpoint

Follows Alpaca's cursor-based pagination (`page_token` /
`next_page_token`) automatically, accumulating results across all pages.
Works with any paginated endpoint (orders, activities, bars, trades,
quotes, etc.).

## Usage

``` r
alpaca_paginate(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  items_field = NULL,
  max_pages = Inf,
  sleep = 0,
  timeout = 10
)
```

## Arguments

- base_url:

  (scalar\<character\>) the API base URL.

- endpoint:

  (scalar\<character\>) the API path (e.g., `"/v2/orders"`).

- method:

  (scalar\<character\>) HTTP method. Default `"GET"`.

- query:

  (list) query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- keys:

  (list \| NULL) API credentials.

- .perform:

  (function) the httr2 perform function.

- .parser:

  (function) applied to the accumulated list of page items. Receives a
  single flat list of all items across pages.

- is_async:

  (scalar\<logical\>) whether `.perform` returns promises.

- items_field:

  (scalar\<character\> \| NULL) the JSON field containing the array of
  items (e.g., `"bars"`, `"trades"`, `"quotes"`). If `NULL`, the entire
  response list is accumulated (for endpoints returning top-level
  arrays).

- max_pages:

  (scalar\<numeric in \[1, Inf\]\> \| scalar\<integer in \[1, Inf\[\>)
  maximum number of pages to fetch. Default `Inf`.

- sleep:

  (scalar\<numeric in \[0, Inf\[\>) seconds to pause between page
  requests, to respect rate limits (Alpaca's free/Basic data tier caps
  at 200 req/min). Applied in synchronous mode only. Default `0`.

- timeout:

  (scalar\<numeric in \]0, Inf\[\>) request timeout in seconds. Default
  `10`.

## Value

(any \| promise\<any\>) parsed and post-processed API response data, or
a promise thereof.

## Details

Alpaca endpoints return a `next_page_token` field when more results are
available. This function loops through pages until no more tokens remain
or `max_pages` is reached, then applies `.parser` to the combined result
list.

If `max_pages` is hit while the server still reports more data
(`next_page_token` present), the accumulated pages are returned anyway —
fetched work is never thrown away — but an
[`rlang::warn()`](https://rlang.r-lib.org/reference/abort.html) fires so
the truncation can never pass silently. Resume by re-requesting with a
later `start` (bars/trades/quotes are time-ordered) or by raising
`max_pages`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch ALL historical bars across pages
all_bars <- alpaca_paginate(
  base_url = "https://data.alpaca.markets",
  endpoint = "/v2/stocks/AAPL/bars",
  query = list(timeframe = "1Day", start = "2020-01-01"),
  keys = get_api_keys(),
  items_field = "bars",
  .parser = parse_bars
)
} # }
```
