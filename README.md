
# alpaca

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R API wrapper for the [Alpaca](https://alpaca.markets/) trading
platform. Provides R6 classes for market data, stock trading, options,
account management, and positions. Supports both synchronous and
asynchronous (promise-based) operation via httr2.

## Disclaimer

This software is provided “as is”, without warranty of any kind. **This
package interacts with live brokerage accounts and can execute real
trades involving real money.** By using this package you accept full
responsibility for any financial losses, erroneous transactions, or
other damages that may result. Always test with paper trading first, use
API key permissions to restrict access to only what you need, and never
share your API credentials. The author(s) and contributor(s) are not
liable for any financial loss or damage arising from the use of this
software.

We invite you to read the source code and make contributions if you find
a bug or wish to make an improvement.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("dereckmezquita/alpaca")
```

## Setup

Set your API credentials as environment variables in `.Renviron`:

``` bash
ALPACA_API_KEY = your-api-key
ALPACA_API_SECRET = your-api-secret
ALPACA_API_ENDPOINT = https://paper-api.alpaca.markets
```

If you don’t have a key, visit the [Alpaca
dashboard](https://app.alpaca.markets/).

## Quick Start

*Examples will be added as API classes are implemented.*

## Citation

If you use this package in your work, please cite it:

``` r
citation("alpaca")
```

> Mezquita, D. (2026). alpaca: R API Wrapper to Alpaca Trading Platform.
> R package version 0.1.0.

## Licence

MIT © [Dereck Mezquita](https://github.com/dereckmezquita)
[![ORCID](https://img.shields.io/badge/ORCID-0000--0002--9307--6762-green)](https://orcid.org/0000-0002-9307-6762).
See [LICENSE.md](LICENSE.md) for the full text, including the citation
clause.
