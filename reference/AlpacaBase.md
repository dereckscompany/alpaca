# AlpacaBase: Abstract Base Class for Alpaca API Clients

AlpacaBase: Abstract Base Class for Alpaca API Clients

AlpacaBase: Abstract Base Class for Alpaca API Clients

## Details

Provides shared infrastructure for all Alpaca R6 classes, including API
credential management, sync/async execution mode, and a standardised
request funnel.

Inherits the transport from
[connectcore::RestClient](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
and customises the two venue-specific seams: `.sign()` adds Alpaca's
API-key headers, and `.parse_envelope()` reads Alpaca's error shape.
Every endpoint method on a subclass delegates to the inherited
`private$.request()`.

### Sync vs Async

The `async` parameter controls execution mode for all API methods:

- `async = FALSE` (default): methods return results directly
  (`data.table`, etc.).

- `async = TRUE`: methods return
  [promises::promise](https://rstudio.github.io/promises/reference/promise.html)
  objects that resolve to the same types.

When async, use
[`coro::async()`](https://coro.r-lib.org/reference/async.html) and
`await()` or
[`promises::then()`](https://rstudio.github.io/promises/reference/then.html)
to consume results. The `promises` package must be installed for async
mode (`Suggests` dependency).

### Authentication

Alpaca uses header-based authentication with two headers:

- `APCA-API-KEY-ID`: Your API key ID

- `APCA-API-SECRET-KEY`: Your API secret key

No HMAC signing is required — credentials are sent directly in headers,
which is exactly what the `.sign()` override does.

### Retries

`max_tries > 1` opts every GET this client makes — single requests and
auto-paginated reads (e.g. historical bars) alike — into automatic retry
on a transient failure (HTTP 408/429/5xx or a dropped connection) with
jittered backoff, delegated to
[`connectcore::build_request()`](https://dereckscompany.github.io/connectcore/reference/build_request.html).
Retry is a hard **GET-only** carve-out: a non-idempotent verb (an order
`POST`, a cancel `DELETE`) is never auto-retried, so a resend can never
double-submit an order. Leave it at the default `1` for live trading —
there the trader layer is the single retry authority (it routes by typed
error class and manages cooldowns); raise it only for research and
backfill reads.

### Design

This class is not meant to be instantiated directly. Subclasses (e.g.,
[AlpacaMarketData](https://dereckscompany.github.io/alpaca/reference/AlpacaMarketData.md),
[AlpacaTrading](https://dereckscompany.github.io/alpaca/reference/AlpacaTrading.md))
inherit from it and define their own public methods that delegate to
`private$.request()`.

## Super class

[`connectcore::RestClient`](https://dereckscompany.github.io/connectcore/reference/RestClient.html)
-\> `AlpacaBase`

## Methods

### Public methods

- [`AlpacaBase$new()`](#method-AlpacaBase-new)

- [`AlpacaBase$clone()`](#method-AlpacaBase-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise an AlpacaBase Object

#### Usage

    AlpacaBase$new(
      keys = get_api_keys(),
      base_url = get_base_url(),
      async = FALSE,
      max_tries = 1L
    )

#### Arguments

- `keys`:

  (list) API credentials from
  [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckscompany.github.io/alpaca/reference/get_api_keys.md).

- `base_url`:

  (scalar\<character\>) API base URL. Defaults to
  [`get_base_url()`](https://dereckscompany.github.io/alpaca/reference/get_base_url.md).

- `async`:

  (scalar\<logical\>) if `TRUE`, methods return promises. Default
  `FALSE`.

- `max_tries`:

  (scalar\<integer in \[1, 10\]\>) for idempotent GET requests only,
  retry up to this many times on a transient failure. Default `1` (no
  retry). See the class **Retries** section for the write-safety
  carve-out and why live trading should leave this at `1`.

#### Returns

(class\<AlpacaBase\>) invisibly, self.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AlpacaBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Not instantiated directly; use subclasses:
market <- AlpacaMarketData$new()                 # sync
market_async <- AlpacaMarketData$new(async = TRUE)  # async
} # }
```
