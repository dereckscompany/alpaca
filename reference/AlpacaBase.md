# AlpacaBase: Abstract Base Class for Alpaca API Clients

AlpacaBase: Abstract Base Class for Alpaca API Clients

AlpacaBase: Abstract Base Class for Alpaca API Clients

## Details

Provides shared infrastructure for all Alpaca R6 classes, including API
credential management, sync/async execution mode, and a standardised
method for calling implementation functions.

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

No HMAC signing is required — credentials are sent directly in headers.

### Design

This class is not meant to be instantiated directly. Subclasses (e.g.,
[AlpacaMarketData](https://dereckmezquita.github.io/alpaca/reference/AlpacaMarketData.md),
[AlpacaTrading](https://dereckmezquita.github.io/alpaca/reference/AlpacaTrading.md))
inherit from it and define their own public methods that delegate to
`private$.request()`.

## Fields

All fields are private:

- `.keys`: List; API credentials from
  [`get_api_keys()`](https://dereckmezquita.github.io/alpaca/reference/get_api_keys.md).

- `.base_url`: Character; API base URL from
  [`get_base_url()`](https://dereckmezquita.github.io/alpaca/reference/get_base_url.md).

- `.perform`: Function; either
  [httr2::req_perform](https://httr2.r-lib.org/reference/req_perform.html)
  or
  [httr2::req_perform_promise](https://httr2.r-lib.org/reference/req_perform_promise.html).

- `.is_async`: Logical; whether the instance is in async mode.

## Active bindings

- `is_async`:

  Logical; read-only flag indicating whether this instance operates in
  async mode.

## Methods

### Public methods

- [`AlpacaBase$new()`](#method-AlpacaBase-new)

- [`AlpacaBase$clone()`](#method-AlpacaBase-clone)

------------------------------------------------------------------------

### Method `new()`

Initialise an AlpacaBase Object

#### Usage

    AlpacaBase$new(keys = get_api_keys(), base_url = get_base_url(), async = FALSE)

#### Arguments

- `keys`:

  List; API credentials from
  [`get_api_keys()`](https://dereckmezquita.github.io/alpaca/reference/get_api_keys.md).
  Defaults to
  [`get_api_keys()`](https://dereckmezquita.github.io/alpaca/reference/get_api_keys.md).

- `base_url`:

  Character; API base URL. Defaults to
  [`get_base_url()`](https://dereckmezquita.github.io/alpaca/reference/get_base_url.md).

- `async`:

  Logical; if `TRUE`, methods return promises. Default `FALSE`.

#### Returns

Invisible self.

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
