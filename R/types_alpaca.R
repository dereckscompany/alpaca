# File: R/types_alpaca.R
# Reusable roxyassert `@type` shapes for the data.tables the Alpaca R6 methods
# return. Modelled on tradebot-core's R/types_exchange.R.

#' @title Alpaca return shapes
#' @description Reusable roxyassert `@type` shapes for the `data.table`s returned
#' by the Alpaca R6 client methods ([AlpacaMarketData], [AlpacaTrading],
#' [AlpacaAccount], [AlpacaOptions]). Each public method documents its return as
#' `Shape | promise<Shape>`; the contract roclet expands the shape into the
#' generated `assert_return_*` helper, which checks that every listed column is
#' present and of its column type. `assert_has_columns` requires the listed
#' columns but tolerates EXTRA ones, so each shape names only the columns Alpaca
#' guarantees on every response that flows to that contract; venue-optional
#' columns (e.g. the flattened `admin_configurations_*` account fields, the
#' options `greeks_*` / `implied_volatility` columns, the richer single-order
#' price fields) ride along as un-asserted extras.
#'
#' Column-type conventions, matched to what the parsers actually emit (verified
#' against the `tests/testthat` mock fixtures): `character` for the
#' string-typed price/quantity fields Alpaca returns as JSON strings (the API
#' never narrows these to numbers, so neither do we); `integer` for the bar
#' `volume` / `trade_count` and the trade/quote `size` fields; `numeric` (strict
#' double) for true floating-point prices; `POSIXct` for parsed timestamps and
#' `Date` for calendar dates. A column is marked `| NA` only where a value can
#' legitimately be missing on a present row. Alpaca encodes a whole-number price
#' without a decimal point, so the raw JSON parser realises such a bar/trade/
#' quote price as `integer`; the parsers coerce every price/vwap column to a
#' clean `numeric` double with `as.numeric()`, so the contracts can stay strict.
#'
#' `@genassert` is omitted: no generated `assert_type_<Shape>()` is called
#' internally, and as a leaf connector nothing downstream consumes them, so the
#' shapes expand inline into the methods' `assert_return_*` contracts only.
#' @name alpaca_shapes
#'
#' @type Bars (data.table) one row per OHLCV bar. The parser coerces the OHLC and
#'   vwap price columns to `numeric` (a whole-number price Alpaca sends without a
#'   decimal would otherwise realise as `integer`):
#' - datetime (POSIXct) bar open time (UTC).
#' - open (numeric) open price.
#' - high (numeric) high price.
#' - low (numeric) low price.
#' - close (numeric) close price.
#' - volume (numeric) traded volume. A whole-number counter that can exceed the
#'   32-bit `integer` ceiling on a liquid name, so the parser coerces it to a
#'   `numeric` double (jsonlite already realises a value `>= 2^31` as a double).
#' - trade_count (numeric) number of trades in the bar, coerced to `numeric` for
#'   the same overflow reason as `volume`.
#' - vwap (numeric) volume-weighted average price.
#'
#' @type BarsMulti (extends Bars) one row per (symbol, bar), with the symbol key:
#' - symbol (character) the ticker (or OCC option) symbol.
#'
#' @type Trade (data.table) one row per equity trade (`parse_trades()` maps the
#'   short field names `t`/`p`/`s`/`x`/`z`/`i`/`c`):
#' - timestamp (POSIXct) trade time (UTC).
#' - price (numeric) trade price (the parser coerces it to a double, so a
#'   whole-number price Alpaca sends without a decimal lands as `numeric`).
#' - size (integer) trade size in shares.
#' - exchange (character) reporting exchange code.
#' - tape (character) the consolidated tape (e.g. `"C"`).
#' - id (numeric) exchange-assigned trade id. Can exceed the 32-bit `integer`
#'   ceiling, so the parser coerces it to a `numeric` double (jsonlite already
#'   realises a value `>= 2^31` as a double).
#' - conditions (character | NA) `;`-collapsed trade condition codes (e.g.
#'   `"@;T"`), or `NA` when the trade carries none.
#'
#' @type TradesMulti (extends Trade) one row per (symbol, trade), with the key:
#' - symbol (character) the ticker symbol.
#'
#' @type OptionTradesMulti (extends TradesMulti omit tape) one row per
#'   (symbol, trade) for the options trade endpoints. The options trade payload
#'   carries `t`/`p`/`s`/`x`/`i`/`c` but no `z`, so `tape` is dropped from the
#'   inherited equity shape (it never appears on an options trade row).
#'
#' @type Quote (data.table) one row per equity NBBO quote (`parse_quotes()` maps
#'   `t`/`ax`/`ap`/`as`/`bx`/`bp`/`bs`/`z`/`c`):
#' - timestamp (POSIXct) quote time (UTC).
#' - ask_exchange (character) the exchange posting the best ask.
#' - ask_price (numeric | NA) best ask price (the parser coerces it to a
#'   double). On an illiquid, one-sided book the ask side may be absent, which
#'   the parser coerces to `NA`, so the column is nullable.
#' - ask_size (integer) ask size.
#' - bid_exchange (character) the exchange posting the best bid.
#' - bid_price (numeric | NA) best bid price (the parser coerces it to a
#'   double). On an illiquid, one-sided book the bid side may be absent, which
#'   the parser coerces to `NA`, so the column is nullable.
#' - bid_size (integer) bid size.
#' - tape (character) the consolidated tape (e.g. `"C"`).
#' - conditions (character | NA) `;`-collapsed quote condition codes, or `NA`.
#'
#' @type QuotesMulti (extends Quote) one row per (symbol, quote), with the key:
#' - symbol (character) the ticker symbol.
#'
#' @type OptionQuotesMulti (extends QuotesMulti omit tape) one row per
#'   (symbol, quote) for the options latest-quotes endpoint. The options quote
#'   payload carries `ax`/`bx` (so both exchange columns survive) but no `z`, so
#'   `tape` is dropped from the inherited equity shape.
#'
#' @type Snapshot (data.table) one row per symbol; the flattened latest-trade and
#'   latest-quote sections (the `*_bar_*` OHLC blocks and the options
#'   `implied_volatility` / `greeks_*` columns ride along as un-asserted extras
#'   because the bar OHLC columns parse as `integer` or `numeric` depending on
#'   the value and the greeks appear only with an options data subscription):
#' - latest_trade_timestamp (POSIXct | NA) latest trade time (UTC); `NA` when an
#'   illiquid contract has had no last trade.
#' - latest_trade_price (numeric | NA) latest trade price (the parser coerces it
#'   to a double); `NA` when an illiquid contract has had no last trade.
#' - latest_trade_size (integer | NA) latest trade size; `NA` when an illiquid
#'   contract has had no last trade.
#' - latest_trade_conditions (character | NA) `;`-collapsed trade conditions, or `NA`.
#' - latest_quote_timestamp (POSIXct) latest quote time (UTC).
#' - latest_quote_ask_price (numeric | NA) latest ask price (coerced to a
#'   double); `NA` when an illiquid, one-sided book omits the ask.
#' - latest_quote_bid_price (numeric | NA) latest bid price (coerced to a
#'   double); `NA` when an illiquid, one-sided book omits the bid.
#' - latest_quote_ask_size (integer) latest ask size.
#' - latest_quote_bid_size (integer) latest bid size.
#' - latest_quote_conditions (character | NA) `;`-collapsed quote conditions, or `NA`.
#'
#' @type SnapshotMulti (extends Snapshot) one row per (symbol, snapshot), keyed:
#' - symbol (character) the ticker (or OCC option) symbol.
#'
#' @type Asset (data.table) one row per asset:
#' - id (character) asset UUID.
#' - class (character) asset class (e.g. `"us_equity"`).
#' - exchange (character) listing exchange.
#' - symbol (character) ticker symbol.
#' - name (character) human-readable name.
#' - status (character) `"active"` / `"inactive"`.
#' - tradable (logical) whether the asset is tradable.
#' - marginable (logical) whether the asset is marginable.
#' - shortable (logical) whether the asset is shortable.
#' - fractionable (logical) whether fractional trading is allowed.
#' - attributes (character | NA) `;`-collapsed attribute tags, or `NA` when none.
#'
#' @type CryptoOrderbook (data.table) one row per (symbol, side, level):
#' - symbol (character) the crypto pair (e.g. `"BTC/USD"`).
#' - side (character) `"bid"` or `"ask"`.
#' - level (integer) 1-based depth within the side (`1` is top of book).
#' - price (numeric) level price.
#' - size (numeric) level size.
#' - timestamp (POSIXct) orderbook snapshot time (UTC).
#'
#' @type Calendar (data.table) one row per trading day:
#' - date (Date) the trading date.
#' - open (POSIXct) regular-session open (America/New_York).
#' - close (POSIXct) regular-session close (America/New_York).
#' - session_open (POSIXct) extended-hours session open (America/New_York).
#' - session_close (POSIXct) extended-hours session close (America/New_York).
#' - settlement_date (Date) the settlement date.
#'
#' @type Clock (data.table) one row, the market clock:
#' - timestamp (POSIXct) current server time (America/New_York).
#' - is_open (logical) whether the market is currently open.
#' - next_open (POSIXct) next market open (America/New_York).
#' - next_close (POSIXct) next market close (America/New_York).
#'
#' @type CorporateAction (data.table) one row per announcement:
#' - id (character) announcement id.
#' - corporate_action_id (character) the corporate-action id.
#' - ca_type (character) action type (`"dividend"`, `"split"`, ...).
#' - ca_sub_type (character) action sub-type.
#' - initiating_symbol (character) the initiating ticker.
#' - target_symbol (character) the target ticker.
#' - declaration_date (Date) declaration date.
#' - ex_date (Date) ex-date.
#' - record_date (Date) record date.
#' - payable_date (Date) payable date.
#' - cash (character | NA) cash amount, or `NA` (e.g. for a split).
#' - old_rate (character | NA) pre-action rate, or `NA` (e.g. for a dividend).
#' - new_rate (character | NA) post-action rate, or `NA`.
#'
#' @type News (data.table) one row per article:
#' - id (numeric) article id. Can exceed the 32-bit `integer` ceiling, so the
#'   parser coerces it to a `numeric` double (jsonlite already realises a value
#'   `>= 2^31` as a double).
#' - headline (character) the headline.
#' - author (character) the author.
#' - source (character) the news source.
#' - summary (character) the summary text.
#' - url (character) the article URL.
#' - symbols (character | NA) `;`-collapsed related tickers, or `NA` when none.
#' - created_at (POSIXct) creation time (UTC).
#' - updated_at (POSIXct) last-updated time (UTC).
#' - image_sizes (character | NA) `;`-joined image size labels, or `NA` when none.
#' - image_urls (character | NA) `;`-joined, losslessly encoded image URLs, or `NA`.
#'
#' @type MostActives (data.table) one row per active symbol. `volume` and
#'   `trade_count` are genuine whole-number counters, typed `count`; the parser
#'   coerces both to `numeric` so a large volume cannot overflow `integer`:
#' - symbol (character) the ticker.
#' - volume (count) traded volume.
#' - trade_count (count) number of trades.
#'
#' @type Movers (data.table) one row per mover:
#' - symbol (character) the ticker.
#' - percent_change (numeric) percentage change.
#' - change (numeric) absolute price change.
#' - price (numeric) current price.
#' - direction (character) `"gainer"` or `"loser"`.
#'
#' @type Contract (data.table) one row per option contract (the canonical
#'   per-contract columns; `underlying_asset_id`, the `open_interest_date` /
#'   `close_price_date` dates, and the `deliverable_*` columns appear only on
#'   some responses and ride along as un-asserted extras):
#' - id (character) contract UUID.
#' - symbol (character) the OCC option symbol.
#' - name (character) human-readable name.
#' - status (character) contract status.
#' - tradable (logical) whether the contract is tradable.
#' - type (character) `"call"` or `"put"`.
#' - strike_price (character) strike price (Alpaca returns it as a string).
#' - expiration_date (Date) the expiration date.
#' - underlying_symbol (character) the underlying ticker.
#' - style (character) `"american"` / `"european"`.
#' - root_symbol (character) the options root symbol.
#' - size (character) contract size (string).
#' - open_interest (character | NA) open interest (string); `NA` when a real
#'   contract omits it.
#' - close_price (character | NA) last close price (string); `NA` when a real
#'   contract omits it.
#'
#' @type Account (data.table) one row, the account snapshot (the nested
#'   `admin_configurations_*` / `user_configurations_*` flattened columns appear
#'   only when the API returns them and ride along as un-asserted extras):
#' - id (character) account UUID.
#' - account_number (character) the account number.
#' - status (character) account status.
#' - currency (character) account currency.
#' - cash (character) cash balance (string).
#' - portfolio_value (character) total portfolio value (string).
#' - equity (character) account equity (string).
#' - last_equity (character) previous-close equity (string).
#' - buying_power (character) buying power (string).
#' - initial_margin (character) initial margin (string).
#' - maintenance_margin (character) maintenance margin (string).
#' - long_market_value (character) long market value (string).
#' - short_market_value (character) short market value (string).
#' - pattern_day_trader (logical) PDT flag.
#' - trading_blocked (logical) whether trading is blocked.
#' - transfers_blocked (logical) whether transfers are blocked.
#' - account_blocked (logical) whether the account is blocked.
#' - daytrade_count (integer) rolling day-trade count.
#' - daytrading_buying_power (character) day-trading buying power (string).
#' - regt_buying_power (character) Reg-T buying power (string).
#' - multiplier (character) margin multiplier (string).
#' - sma (character) special memorandum account value (string).
#' - created_at (POSIXct) account creation time (UTC).
#'
#' @type AccountConfig (data.table) one row, the account configuration:
#' - dtbp_check (character) day-trade buying-power check mode.
#' - no_shorting (logical) whether shorting is disabled.
#' - suspend_trade (logical) whether trading is suspended.
#' - trade_confirm_email (character) trade-confirmation email setting.
#' - fractional_trading (logical) whether fractional trading is enabled.
#' - max_margin_multiplier (character) max margin multiplier (string).
#' - pdt_check (character) pattern-day-trader check mode.
#'
#' @type Position (data.table) one row per open position (all numeric fields are
#'   the JSON strings Alpaca returns, unparsed):
#' - asset_id (character) the asset UUID.
#' - symbol (character) the ticker.
#' - exchange (character) listing exchange.
#' - asset_class (character) asset class.
#' - avg_entry_price (character) average entry price (string).
#' - qty (character) position quantity (string).
#' - side (character) `"long"` or `"short"`.
#' - market_value (character) current market value (string).
#' - cost_basis (character) cost basis (string).
#' - unrealized_pl (character) unrealized P/L (string).
#' - unrealized_plpc (character) unrealized P/L percent (string).
#' - current_price (character) current price (string).
#' - lastday_price (character) previous-day close price (string).
#' - change_today (character) intraday change fraction (string).
#'
#' @type Activity (data.table) one row per account activity. Only `id` and
#'   `activity_type` are guaranteed across every activity type; the trade-shaped
#'   columns below are populated for `FILL`/`PARTIAL_FILL` rows and are `NA` on
#'   non-trade activities (fees `CFEE`, journals `JNLC`, dividends, ...), which
#'   instead carry their own fields (e.g. `date`, `net_amount`) as un-asserted
#'   extras:
#' - id (character) the activity id (also the pagination cursor).
#' - activity_type (character) the activity type (e.g. `"FILL"`).
#' - symbol (character | NA) the ticker; `NA` on non-trade activities.
#' - side (character | NA) order side; `NA` on non-trade activities.
#' - qty (character | NA) quantity (string); `NA` on non-trade activities.
#' - price (character | NA) price (string); `NA` on non-trade activities.
#' - transaction_time (POSIXct | NA) the transaction time (UTC); `NA` on
#'   non-trade activities (they carry a `date` instead).
#'
#' @type PortfolioHistory (data.table) one row per time-series point:
#' - timestamp (POSIXct) the snapshot time (UTC).
#' - equity (numeric | NA) account equity at that point. The parser's `nums()`
#'   maps a JSON `null` (a no-data point) to `NA`, so the column is nullable.
#' - profit_loss (numeric | NA) P/L versus the base value, `NA` on a no-data
#'   point (same `nums()` `null`-to-`NA` mapping as `equity`).
#' - profit_loss_pct (numeric | NA) P/L percent versus the base value, `NA` on a
#'   no-data point (same `nums()` `null`-to-`NA` mapping as `equity`).
#'
#' @type Watchlists (data.table) one row per watchlist (the list view):
#' - id (character) watchlist UUID.
#' - account_id (character) the owning account UUID.
#' - name (character) the watchlist name.
#' - created_at (POSIXct) creation time (UTC).
#' - updated_at (POSIXct) last-updated time (UTC).
#'
#' @type Watchlist (extends Watchlists) one row per asset in a single watchlist
#'   (long format; the watchlist metadata is replicated on each asset row). A
#'   watchlist with no assets still returns one row, with every `asset_*` column
#'   `NA` — hence each is nullable:
#' - asset_id (character | NA) the asset UUID, or `NA` on the empty-watchlist row.
#' - asset_symbol (character | NA) the asset ticker, or `NA`.
#' - asset_name (character | NA) the asset name, or `NA`.
#' - asset_attributes (character | NA) `;`-collapsed asset attribute tags, or `NA`.
#'
#' @type OrderCore (data.table) one row per order; the columns common to every
#'   order-bearing response (the list/single order responses and the
#'   close-position / cancel-all confirmations). The richer single-order fields
#'   (`client_order_id`, `time_in_force`, `limit_price`, ...) ride along as
#'   un-asserted extras where the venue returns them:
#' - id (character) the exchange order id.
#' - symbol (character) the ticker.
#' - side (character) order side.
#' - type (character) order type.
#' - status (character) order status.
#' - qty (character) requested quantity (string).
#' - filled_qty (character) filled quantity (string).
#' - created_at (POSIXct) creation time (UTC).
#'
#' @type Order (extends OrderCore) one row per order (parent and leg rows alike),
#'   adding the leg-bookkeeping columns `parse_order()` injects:
#' - leg_index (integer | NA) `NA` on the parent row, `1..N` on each leg row.
#' - parent_order_id (character | NA) `NA` on the parent row, the parent id on legs.
#'
#' @type CancelOrderAck (data.table) one row, the cancel-order confirmation
#'   (`DELETE /v2/orders/{id}` returns `204 No Content`; this method synthesises
#'   the row from the request):
#' - order_id (character) the cancelled order UUID.
#' - status (character) always `"cancelled"`.
#'
#' @type ExerciseAck (data.table) one row, the option-exercise confirmation
#'   (`POST /v2/positions/{symbol_or_id}/exercise` returns `204 No Content`;
#'   this method synthesises the row from the request):
#' - symbol (character) the exercised option symbol or asset UUID.
#' - status (character) always `"exercised"`.
#'
#' @type CancelWatchlistAck (data.table) one row, the delete-watchlist
#'   confirmation (`DELETE /v2/watchlists/{id}` returns `204 No Content`; this
#'   method synthesises the row from the request):
#' - watchlist_id (character) the deleted watchlist UUID.
#' - status (character) always `"deleted"`.
NULL
