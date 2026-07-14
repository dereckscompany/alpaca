# Shared mock HTTP router for the alpaca README, vignettes, and tests.
#
# This is the THIN alpaca-specific layer over connectcore's shared mock harness
# (connectcore::mock_router / with_mock_api / local_mock_api / load_fixtures /
# mock_response). connectcore owns the response builder, the dispatch loop, and
# the scoped-activation helpers; this file only declares the route table -- URL
# pattern + HTTP method -> the fixture for that endpoint -- and loads the
# fixtures from disk.
#
# Each route's fixture is the JSON for that endpoint, loaded verbatim from
# tests/testthat/fixtures/*.json by connectcore::load_fixtures() (a named list
# keyed by file basename; each value is the raw JSON string).
# connectcore::mock_response() serves a string body verbatim, so the parsers and
# column contracts are exercised against the exact wire bytes.
#
# The fixtures are SYNTHETIC: deterministic, PII-free bodies hand-built to
# exercise every parser branch -- empty-vs-populated arrays, multi-condition
# collapse, option deliverables/greeks, partially-missing image sizes. They were
# validated against the live Alpaca paper API (the captured READ responses match
# these shapes), but the synthetic bodies are kept because the live test account
# is empty/degenerate (no positions, no watchlist assets, no dividends) and would
# not exercise the populated-column contracts the tests assert.
#
# httr2 exposes a native global mock hook: connectcore::with_mock_api(.mock_routes,
# { ... }) (or local_mock_api(.mock_routes)) installs the dispatcher as the
# httr2_mock option, intercepting every req_perform / req_perform_promise call,
# so docs render and tests run against canned, deterministic data with no
# network and no real credentials. The mock ignores the Authorization header
# entirely (a throwaway key still satisfies the client's required-keys guard).
#
# Usage (in a hidden knitr setup chunk or a test):
#   box::use(./tests/testthat/mock_router[.mock_routes])
#   connectcore::with_mock_api(.mock_routes, { ...code... })  # scoped to a block
#   connectcore::local_mock_api(.mock_routes)                 # scoped to a frame

box::use(
  connectcore[load_fixtures]
)

# Load every fixture as its raw JSON string, keyed by file basename
# (account.json -> "account"). Resolved relative to THIS module file so it works
# from the package root (README), vignettes/, and tests/testthat alike.
.fixtures <- load_fixtures(box::file("fixtures"))

# DELETE / cancel endpoints return 204 No Content (empty body). An empty string
# would fail JSON parsing, so serve a real no-content response.
.no_content <- function() {
  return(httr2::response(
    status_code = 204L,
    headers = list(),
    body = raw(0)
  ))
}

#' Route table: URL pattern (+ optional method) -> fixture JSON string.
#'
#' Order matters -- more specific patterns first. Routes handle both Alpaca
#' hosts:
#'   Trading: https://paper-api.alpaca.markets
#'   Data:    https://data.alpaca.markets
#' Each `fixture` is the raw JSON string for that endpoint (served verbatim by
#' connectcore::mock_response); the no-content routes are a thunk returning a
#' built 204 response.
#' @export
.mock_routes <- list(
  # ---- Market Data (data.alpaca.markets) ----

  # Screener (before generic stocks patterns)
  list(pattern = "v1beta1/screener/stocks/most-actives", fixture = .fixtures$most_actives),
  list(pattern = "v1beta1/screener/", fixture = .fixtures$movers),

  # News
  list(pattern = "v1beta1/news", fixture = .fixtures$news),

  # Corporate actions (market-data archive; data host)
  list(pattern = "v1/corporate-actions", fixture = .fixtures$corporate_actions_history),

  # Options data (v1beta1 -- before stock patterns)
  list(pattern = "v1beta1/options/bars", fixture = .fixtures$multi_bars),
  list(pattern = "v1beta1/options/trades/latest", fixture = .fixtures$option_latest_trades),
  list(pattern = "v1beta1/options/trades", fixture = .fixtures$option_latest_trades),
  list(pattern = "v1beta1/options/quotes/latest", fixture = .fixtures$latest_quotes_multi),
  list(pattern = "v1beta1/options/snapshots/AAPL240621", fixture = .fixtures$option_chain),
  list(pattern = "v1beta1/options/snapshots/AAPL", fixture = .fixtures$option_chain),
  list(pattern = "v1beta1/options/snapshots", fixture = .fixtures$option_chain),

  # Multi-symbol latest endpoints (before single-symbol patterns)
  list(pattern = "v2/stocks/bars/latest", fixture = .fixtures$latest_bars_multi),
  list(pattern = "v2/stocks/trades/latest", fixture = .fixtures$latest_trades_multi),
  list(pattern = "v2/stocks/quotes/latest", fixture = .fixtures$latest_quotes_multi),
  list(pattern = "v2/stocks/snapshots", fixture = .fixtures$snapshots_multi),

  # Multi-symbol bars (no symbol in URL path)
  list(pattern = "v2/stocks/bars", fixture = .fixtures$multi_bars),

  # Single-symbol latest endpoints (symbol in URL path)
  list(pattern = "/bars/latest", fixture = .fixtures$latest_bar),
  list(pattern = "/trades/latest", fixture = .fixtures$trade),
  list(pattern = "/quotes/latest", fixture = .fixtures$quote),
  list(pattern = "/snapshot", fixture = .fixtures$snapshot),

  # Single-symbol historical bars/trades/quotes
  list(pattern = "v2/stocks/", fixture = .fixtures$bars),

  # ---- Trading API (paper-api.alpaca.markets) ----

  # Account config (before generic /v2/account)
  list(pattern = "v2/account/configurations", fixture = .fixtures$account_config, method = "GET"),
  list(pattern = "v2/account/configurations", fixture = .fixtures$account_config, method = "PATCH"),

  # Portfolio history (before generic /v2/account)
  list(pattern = "v2/account/portfolio/history", fixture = .fixtures$portfolio_history),

  # Activities (before generic /v2/account)
  list(pattern = "v2/account/activities", fixture = .fixtures$activities),

  # Account
  list(pattern = "v2/account", fixture = .fixtures$account),

  # Orders (order matters: specific before generic)
  list(pattern = "v2/orders:by_client_order_id", fixture = .fixtures$order, method = "GET"),
  list(pattern = "v2/orders/", fixture = .fixtures$order, method = "GET"),
  list(pattern = "v2/orders/", fixture = .fixtures$order, method = "PATCH"),
  list(pattern = "v2/orders/", fixture = .no_content, method = "DELETE"),
  list(pattern = "v2/orders", fixture = .fixtures$order, method = "POST"),
  list(pattern = "v2/orders", fixture = .fixtures$orders_list, method = "GET"),
  list(pattern = "v2/orders", fixture = .fixtures$orders_list, method = "DELETE"),

  # Positions (specific before generic)
  list(pattern = "/exercise", fixture = .no_content, method = "POST"),
  list(pattern = "v2/positions/", fixture = .fixtures$position, method = "GET"),
  list(pattern = "v2/positions/", fixture = .fixtures$order, method = "DELETE"),
  list(pattern = "v2/positions", fixture = .fixtures$positions, method = "GET"),
  list(pattern = "v2/positions", fixture = .fixtures$orders_list, method = "DELETE"),

  # Watchlists (specific before generic)
  list(pattern = "v2/watchlists/", fixture = .fixtures$watchlist, method = "GET"),
  list(pattern = "v2/watchlists/", fixture = .fixtures$watchlist, method = "PUT"),
  list(pattern = "v2/watchlists/", fixture = .fixtures$watchlist, method = "POST"),
  list(pattern = "v2/watchlists/", fixture = .no_content, method = "DELETE"),
  list(pattern = "v2/watchlists", fixture = .fixtures$watchlists, method = "GET"),
  list(pattern = "v2/watchlists", fixture = .fixtures$watchlist, method = "POST"),

  # Options contracts (trading base URL)
  list(pattern = "v2/options/contracts/", fixture = .fixtures$option_contract),
  list(pattern = "v2/options/contracts", fixture = .fixtures$option_contracts),

  # Corporate actions
  list(pattern = "v2/corporate_actions/announcements", fixture = .fixtures$corporate_actions),

  # Assets (specific before generic)
  list(pattern = "v2/assets/", fixture = .fixtures$asset, method = "GET"),
  list(pattern = "v2/assets", fixture = .fixtures$assets, method = "GET"),

  # Calendar and Clock
  list(pattern = "v2/calendar", fixture = .fixtures$calendar),
  list(pattern = "v2/clock", fixture = .fixtures$clock)
)

#' Mock HTTP router for the alpaca README and vignettes (back-compat shim)
#'
#' A `function(req)` suitable for `options(httr2_mock = mock_router)`, built from
#' [.mock_routes] via [connectcore::mock_router()]. Prefer
#' [connectcore::with_mock_api()] / [connectcore::local_mock_api()] with
#' `.mock_routes` directly; this is kept so existing setup chunks that set the
#' option by hand keep working.
#'
#' @param req An `httr2_request` object.
#' @return An `httr2_response` object.
#' @export
mock_router <- connectcore::mock_router(.mock_routes)
