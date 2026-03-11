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
  timeout = 10
)
```

## Arguments

- base_url:

  Character; the API base URL.

- endpoint:

  Character; the API path (e.g., `"/v2/orders"`).

- method:

  Character; HTTP method. Default `"GET"`.

- query:

  Named list; query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- keys:

  List or NULL; API credentials.

- .perform:

  Function; the httr2 perform function.

- .parser:

  Function; applied to the accumulated list of page items. Receives a
  single flat list of all items across pages.

- is_async:

  Logical; whether `.perform` returns promises.

- items_field:

  Character or NULL; the JSON field containing the array of items (e.g.,
  `"bars"`, `"trades"`, `"quotes"`). If `NULL`, the entire response list
  is accumulated (for endpoints returning top-level arrays).

- max_pages:

  Integer; maximum number of pages to fetch. Default `Inf`.

- timeout:

  Numeric; request timeout in seconds. Default `10`.

## Value

Parsed and post-processed API response data, or a promise thereof.

## Details

Alpaca endpoints return a `next_page_token` field when more results are
available. This function loops through pages until no more tokens remain
or `max_pages` is reached, then applies `.parser` to the combined result
list.

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
