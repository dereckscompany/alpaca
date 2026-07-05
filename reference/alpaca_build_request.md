# Build and Execute an Alpaca API Request

Constructs an
[httr2::request](https://httr2.r-lib.org/reference/request.html), adds
authentication headers, performs it via the supplied `.perform`
function, and parses the JSON response. This is the single point through
which the bulk-bar and market-data paths flow; it delegates the
transport to
[`connectcore::build_request()`](https://rdrr.io/pkg/connectcore/man/build_request.html)
and supplies the Alpaca header signer and error-envelope parser.

## Usage

``` r
alpaca_build_request(
  base_url,
  endpoint,
  method = "GET",
  query = list(),
  body = NULL,
  keys = NULL,
  .perform = httr2::req_perform,
  .parser = identity,
  is_async = FALSE,
  timeout = 10,
  simplifyVector = FALSE
)
```

## Arguments

- base_url:

  (scalar\<character\>) the API base URL.

- endpoint:

  (scalar\<character\>) the API path (e.g., `"/v2/account"`).

- method:

  (scalar\<character\>) HTTP method. Default `"GET"`.

- query:

  (list) query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  (list \| NULL) JSON request body (for POST/PATCH). Default `NULL`.

- keys:

  (list \| NULL) API credentials with `api_key` and `api_secret`.
  Default `NULL` (no auth).

- .perform:

  (function) the httr2 perform function. Default
  [`httr2::req_perform`](https://httr2.r-lib.org/reference/req_perform.html).

- .parser:

  (function) post-processing function applied to parsed response.
  Default `identity`.

- is_async:

  (scalar\<logical\>) whether `.perform` returns promises. Default
  `FALSE`.

- timeout:

  (scalar\<numeric in \]0, Inf\[\>) request timeout in seconds. Default
  `10`.

- simplifyVector:

  (scalar\<logical\>) passed to
  [httr2::resp_body_json](https://httr2.r-lib.org/reference/resp_body_raw.html).
  Default `FALSE`. Set to `TRUE` for endpoints returning parallel arrays
  so JSON nulls become NA in atomic vectors.

## Value

(any \| promise\<any\>) parsed and post-processed API response data, or
a promise thereof.

## Details

### Authentication

Alpaca uses header-based authentication with two headers:

- `APCA-API-KEY-ID`: Your API key ID

- `APCA-API-SECRET-KEY`: Your API secret key
