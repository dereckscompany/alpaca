# Alpaca return shapes

Reusable roxyassert `@type` shapes for the `data.table`s returned by the
Alpaca R6 client methods
([AlpacaMarketData](https://dereckscompany.github.io/alpaca/reference/AlpacaMarketData.md),
[AlpacaTrading](https://dereckscompany.github.io/alpaca/reference/AlpacaTrading.md),
[AlpacaAccount](https://dereckscompany.github.io/alpaca/reference/AlpacaAccount.md),
[AlpacaOptions](https://dereckscompany.github.io/alpaca/reference/AlpacaOptions.md)).
Each public method documents its return as `Shape | promise<Shape>`; the
contract roclet expands the shape into the generated `assert_return_*`
helper, which checks that every listed column is present and of its
column type. `assert_has_columns` requires the listed columns but
tolerates EXTRA ones, so each shape names only the columns Alpaca
guarantees on every response that flows to that contract; venue-optional
columns (e.g. the flattened `admin_configurations_*` account fields, the
options `greeks_*` / `implied_volatility` columns, the richer
single-order price fields) ride along as un-asserted extras.

Column-type conventions, matched to what the parsers actually emit
(verified against the `tests/testthat` mock fixtures): `character` for
the string-typed price/quantity fields Alpaca returns as JSON strings
(the API never narrows these to numbers, so neither do we); `integer`
for the bar `volume` / `trade_count` and the trade/quote `size` fields;
`numeric` (strict double) for true floating-point prices; `POSIXct` for
parsed timestamps and `Date` for calendar dates. A column is marked
`| NA` only where a value can legitimately be missing on a present row.
Alpaca encodes a whole-number price without a decimal point, so the raw
JSON parser realises such a bar/trade/ quote price as `integer`; the
parsers coerce every price/vwap column to a clean `numeric` double with
[`as.numeric()`](https://rdrr.io/r/base/numeric.html), so each such
column is a stable `numeric` type (nullability is set separately, per
the API's optional-field contract: measurement / venue-optional columns
are `| NA`, structural columns stay strict, following
dereckscompany/.github discussion \#2).

`@genassert` is omitted: no generated `assert_type_<Shape>()` is called
internally, and as a leaf connector nothing downstream consumes them, so
the shapes expand inline into the methods' `assert_return_*` contracts
only.
