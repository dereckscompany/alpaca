# Mock response helpers + JSON-fixture loaders for alpaca unit tests.
# Sourced automatically by testthat via the helper- prefix convention.
#
# The named response builders (mock_account_response, mock_bars_response, ...)
# return the SAME fixture bodies the README/vignette router serves, loaded from
# tests/testthat/fixtures/*.json -- the single source of truth. Each builder
# parses its fixture to a list (jsonlite::fromJSON, simplifyVector = FALSE), the
# shape tests wrap with mock_alpaca_response() or index into. This file keeps
# only the response-construction helpers that have no JSON equivalent: the
# JSON-encoding response builder, the error-injection builder, and the 204
# no-content builder.

# ---- Fixture loading ----

# Parse every fixture once into a named list (basename -> parsed body). Resolved
# relative to this helper so it works from tests/testthat.
.fixtures <- connectcore::load_fixtures(
  testthat::test_path("fixtures"),
  parse = TRUE
)

# Read a single fixture body by basename.
.fx <- function(name) {
  stopifnot(name %in% names(.fixtures))
  return(.fixtures[[name]])
}

# ---- Core Response Builders ----

#' Build a mock httr2 response with an Alpaca JSON body
#'
#' @param data List to encode as JSON body.
#' @param status_code Integer; HTTP status code.
#' @return An httr2 response object.
mock_alpaca_response <- function(data, status_code = 200L) {
  body <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null", digits = NA)
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

#' Build a mock Alpaca error response
#'
#' @param message Character; error message.
#' @param status_code Integer; HTTP status code. Default 422.
#' @return An httr2 response object.
mock_alpaca_error <- function(message = "Something went wrong", status_code = 422L) {
  body <- jsonlite::toJSON(list(message = message), auto_unbox = TRUE)
  return(httr2::response(
    status_code = status_code,
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(as.character(body))
  ))
}

#' Build a mock 204 No Content response
#'
#' @return An httr2 response object with no body.
mock_no_content_response <- function() {
  return(httr2::response(
    status_code = 204L,
    headers = list(),
    body = charToRaw("")
  ))
}

# ---- Market Data Fixtures ----

mock_bars_response <- function() return(.fx("bars"))
mock_multi_bars_response <- function() return(.fx("multi_bars"))
mock_trade_response <- function() return(.fx("trade"))
mock_quote_response <- function() return(.fx("quote"))
mock_snapshot_response <- function() return(.fx("snapshot"))
mock_assets_response <- function() return(.fx("assets"))
mock_clock_response <- function() return(.fx("clock"))
mock_calendar_response <- function() return(.fx("calendar"))

# ---- Trading Fixtures ----

mock_order_response <- function() return(.fx("order"))
mock_bracket_order_response <- function() return(.fx("bracket_order"))
mock_orders_list_response <- function() return(.fx("orders_list"))

# ---- Account Fixtures ----

mock_account_response <- function() return(.fx("account"))
mock_positions_response <- function() return(.fx("positions"))
mock_portfolio_history_response <- function() return(.fx("portfolio_history"))
mock_activities_response <- function() return(.fx("activities"))
mock_account_config_response <- function() return(.fx("account_config"))

# ---- Options Fixtures ----

mock_option_contracts_response <- function() return(.fx("option_contracts"))
mock_option_contracts_with_deliverables_response <- function() return(.fx("option_contracts_with_deliverables"))
mock_option_contract_response <- function() return(.fx("option_contract"))
mock_option_latest_trades_response <- function() return(.fx("option_latest_trades"))
mock_option_chain_response <- function() return(.fx("option_chain"))
mock_option_chain_with_greeks_response <- function() return(.fx("option_chain_with_greeks"))

# ---- Watchlist Fixtures ----

mock_watchlists_response <- function() return(.fx("watchlists"))
mock_watchlist_response <- function() return(.fx("watchlist"))

# ---- Corporate Actions Fixtures ----

mock_corporate_actions_response <- function() return(.fx("corporate_actions"))
mock_corporate_actions_history_response <- function() return(.fx("corporate_actions_history"))

# ---- News Fixtures ----

mock_news_response <- function() return(.fx("news"))

# ---- Pagination Fixtures ----

mock_bars_page1_response <- function() return(.fx("bars_page1"))
mock_bars_page2_response <- function() return(.fx("bars_page2"))

# ---- Multi-Symbol Latest Fixtures ----

mock_latest_bars_multi_response <- function() return(.fx("latest_bars_multi"))
mock_latest_trades_multi_response <- function() return(.fx("latest_trades_multi"))
mock_latest_quotes_multi_response <- function() return(.fx("latest_quotes_multi"))
mock_snapshots_multi_response <- function() return(.fx("snapshots_multi"))

# ---- Screener Fixtures ----

mock_most_actives_response <- function() return(.fx("most_actives"))
mock_movers_response <- function() return(.fx("movers"))

# ---- Crypto Orderbook Fixtures ----

mock_crypto_orderbook_response <- function() return(.fx("crypto_orderbook"))
