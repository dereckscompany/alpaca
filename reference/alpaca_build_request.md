# Build and Execute an Alpaca API Request

Constructs an
[httr2::request](https://httr2.r-lib.org/reference/request.html), adds
authentication headers, performs it via the supplied `.perform`
function, and parses the JSON response. This is the single point through
which all Alpaca API calls flow.

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

  Character; the API base URL.

- endpoint:

  Character; the API path (e.g., `"/v2/account"`).

- method:

  Character; HTTP method. Default `"GET"`.

- query:

  Named list; query parameters. Default
  [`list()`](https://rdrr.io/r/base/list.html).

- body:

  Named list or NULL; JSON request body (for POST/PATCH). Default
  `NULL`.

- keys:

  List or NULL; API credentials with `api_key` and `api_secret`. Default
  `NULL` (no auth).

- .perform:

  Function; the httr2 perform function. Default
  [`httr2::req_perform`](https://httr2.r-lib.org/reference/req_perform.html).

- .parser:

  Function; post-processing function applied to parsed response. Default
  `identity`.

- is_async:

  Logical; whether `.perform` returns promises. Default `FALSE`.

- timeout:

  Numeric; request timeout in seconds. Default `10`.

- simplifyVector:

  Logical; passed to
  [httr2::resp_body_json](https://httr2.r-lib.org/reference/resp_body_raw.html).
  Default `FALSE`. Set to `TRUE` for endpoints returning parallel arrays
  so JSON nulls become NA in atomic vectors.

## Value

Parsed and post-processed API response data, or a promise thereof.

## Details

### Authentication

Alpaca uses header-based authentication with two headers:

- `APCA-API-KEY-ID`: Your API key ID

- `APCA-API-SECRET-KEY`: Your API secret key
