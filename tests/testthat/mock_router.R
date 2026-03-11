# Shared mock HTTP router for README and vignettes.
#
# Dispatches httr2 requests to fixture data based on URL pattern matching.
# Fixtures come from helper-mockery.R; this file only handles routing logic.
#
# Usage (in a hidden knitr setup chunk):
#   box::use(./tests/testthat/mock_router[mock_router])
#   options(httr2_mock = mock_router)

# Load all fixtures from helper-mockery.R (sibling file)
box::use(./`helper-mockery`[
  mock_alpaca_response, mock_no_content_response,
  # Market Data
  mock_bars_response, mock_multi_bars_response,
  mock_trade_response, mock_quote_response,
  mock_snapshot_response, mock_snapshots_multi_response,
  mock_assets_response, mock_clock_response, mock_calendar_response,
  mock_latest_bars_multi_response, mock_latest_trades_multi_response,
  mock_latest_quotes_multi_response,
  mock_most_actives_response, mock_movers_response,
  # Trading
  mock_order_response, mock_orders_list_response,
  # Account
  mock_account_response, mock_positions_response,
  mock_portfolio_history_response, mock_activities_response,
  mock_account_config_response,
  # Options
  mock_option_contracts_response, mock_option_contract_response,
  mock_option_chain_response, mock_option_latest_trades_response,
  # Watchlists
  mock_watchlists_response, mock_watchlist_response,
  # Corporate Actions
  mock_corporate_actions_response,
  # News
  mock_news_response
])

#' Route table: URL pattern -> fixture thunk
#' Order matters — more specific patterns first.
#' Routes handle both base URLs:
#'   Trading: https://paper-api.alpaca.markets
#'   Data:    https://data.alpaca.markets
#' @keywords internal
.mock_routes <- list(
  # ---- Market Data (data.alpaca.markets) ----

  # Screener (before generic stocks patterns)
  list(pattern = "v1beta1/screener/stocks/most-actives", fixture = function() return(mock_most_actives_response())),
  list(pattern = "v1beta1/screener/", fixture = function() return(mock_movers_response())),

  # News
  list(pattern = "v1beta1/news", fixture = function() return(mock_news_response())),

  # Options data (v1beta1 — before stock patterns)
  list(pattern = "v1beta1/options/bars", fixture = function() return(mock_multi_bars_response())),
  list(pattern = "v1beta1/options/trades/latest", fixture = function() return(mock_option_latest_trades_response())),
  list(pattern = "v1beta1/options/trades", fixture = function() return(mock_option_latest_trades_response())),
  list(pattern = "v1beta1/options/quotes/latest", fixture = function() return(mock_latest_quotes_multi_response())),
  list(pattern = "v1beta1/options/snapshots/AAPL240621", fixture = function() return(mock_option_chain_response())),
  list(pattern = "v1beta1/options/snapshots/AAPL", fixture = function() return(mock_option_chain_response())),
  list(pattern = "v1beta1/options/snapshots", fixture = function() return(mock_option_chain_response())),

  # Multi-symbol latest endpoints (before single-symbol patterns)
  list(pattern = "v2/stocks/bars/latest", fixture = function() return(mock_latest_bars_multi_response())),
  list(pattern = "v2/stocks/trades/latest", fixture = function() return(mock_latest_trades_multi_response())),
  list(pattern = "v2/stocks/quotes/latest", fixture = function() return(mock_latest_quotes_multi_response())),
  list(pattern = "v2/stocks/snapshots", fixture = function() return(mock_snapshots_multi_response())),

  # Multi-symbol bars (no symbol in URL path)
  list(pattern = "v2/stocks/bars", fixture = function() return(mock_multi_bars_response())),

  # Single-symbol latest endpoints (symbol in URL path)
  list(pattern = "/bars/latest", fixture = function() return(list(bar = mock_bars_response()$bars[[1]]))),
  list(pattern = "/trades/latest", fixture = function() return(mock_trade_response())),
  list(pattern = "/quotes/latest", fixture = function() return(mock_quote_response())),
  list(pattern = "/snapshot", fixture = function() return(mock_snapshot_response())),

  # Single-symbol historical bars/trades/quotes
  list(pattern = "v2/stocks/", fixture = function() return(mock_bars_response())),

  # ---- Trading API (paper-api.alpaca.markets) ----

  # Account config (before generic /v2/account)
  list(pattern = "v2/account/configurations", fixture = function() return(mock_account_config_response()), method = "GET"),
  list(pattern = "v2/account/configurations", fixture = function() return(mock_account_config_response()), method = "PATCH"),

  # Portfolio history (before generic /v2/account)
  list(pattern = "v2/account/portfolio/history", fixture = function() return(mock_portfolio_history_response())),

  # Activities (before generic /v2/account)
  list(pattern = "v2/account/activities", fixture = function() return(mock_activities_response())),

  # Account
  list(pattern = "v2/account", fixture = function() return(mock_account_response())),

  # Orders (order matters: specific before generic)
  list(pattern = "v2/orders:by_client_order_id", fixture = function() return(mock_order_response()), method = "GET"),
  list(pattern = "v2/orders/", fixture = function() return(mock_order_response()), method = "GET"),
  list(pattern = "v2/orders/", fixture = function() return(mock_order_response()), method = "PATCH"),
  list(pattern = "v2/orders/", fixture = function() return(mock_no_content_response()), method = "DELETE"),
  list(pattern = "v2/orders", fixture = function() return(mock_order_response()), method = "POST"),
  list(pattern = "v2/orders", fixture = function() return(mock_orders_list_response()), method = "GET"),
  list(pattern = "v2/orders", fixture = function() return(mock_orders_list_response()), method = "DELETE"),

  # Positions (specific before generic)
  list(pattern = "/exercise", fixture = function() return(mock_no_content_response()), method = "POST"),
  list(pattern = "v2/positions/", fixture = function() return(mock_positions_response()[[1]]), method = "GET"),
  list(pattern = "v2/positions/", fixture = function() return(mock_order_response()), method = "DELETE"),
  list(pattern = "v2/positions", fixture = function() return(mock_positions_response()), method = "GET"),
  list(pattern = "v2/positions", fixture = function() return(mock_orders_list_response()), method = "DELETE"),

  # Watchlists (specific before generic)
  list(pattern = "v2/watchlists/", fixture = function() return(mock_watchlist_response()), method = "GET"),
  list(pattern = "v2/watchlists/", fixture = function() return(mock_watchlist_response()), method = "PUT"),
  list(pattern = "v2/watchlists/", fixture = function() return(mock_watchlist_response()), method = "POST"),
  list(pattern = "v2/watchlists/", fixture = function() return(mock_no_content_response()), method = "DELETE"),
  list(pattern = "v2/watchlists", fixture = function() return(mock_watchlists_response()), method = "GET"),
  list(pattern = "v2/watchlists", fixture = function() return(mock_watchlist_response()), method = "POST"),

  # Options contracts (trading base URL)
  list(pattern = "v2/options/contracts/", fixture = function() return(mock_option_contract_response())),
  list(pattern = "v2/options/contracts", fixture = function() return(mock_option_contracts_response())),

  # Corporate actions
  list(pattern = "v2/corporate_actions/announcements", fixture = function() return(mock_corporate_actions_response())),

  # Assets (specific before generic)
  list(pattern = "v2/assets/", fixture = function() return(mock_assets_response()[[1]])),
  list(pattern = "v2/assets", fixture = function() return(mock_assets_response())),

  # Calendar and Clock
  list(pattern = "v2/calendar", fixture = function() return(mock_calendar_response())),
  list(pattern = "v2/clock", fixture = function() return(mock_clock_response()))
)

#' Mock HTTP router for README and vignettes
#'
#' Dispatches `httr2` requests to fixture data based on URL pattern matching.
#' Set via `options(httr2_mock = mock_router)` in a hidden knitr setup chunk.
#'
#' Handles both Alpaca base URLs:
#' - Trading: `https://paper-api.alpaca.markets`
#' - Data:    `https://data.alpaca.markets`
#'
#' @param req An `httr2_request` object.
#' @return An `httr2_response` object.
#' @export
mock_router <- function(req) {
  url <- req$url
  method <- req$method

  # Route table lookup
  for (route in .mock_routes) {
    if (grepl(route$pattern, url, fixed = TRUE)) {
      if (!is.null(route$method) && method != route$method) {
        next
      }
      fixture_data <- route$fixture()
      # mock_no_content_response returns an httr2_response directly
      if (inherits(fixture_data, "httr2_response")) {
        return(fixture_data)
      }
      return(mock_alpaca_response(fixture_data))
    }
  }

  stop("Unmocked request: ", method, " ", url)
}
