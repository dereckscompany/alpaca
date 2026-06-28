#!/usr/bin/env Rscript
# File: dev/capture-alpaca.R
#
# READ-ONLY capture harness for the `alpaca` package.
#
# Purpose: hit the REAL Alpaca API (the user's own paper account + the market
# data API) with GET-only read requests and dump each raw response body verbatim
# to local/raw-data/alpaca/<name>.json. Those captures are then compared by hand
# (or by a sibling validation script) against the SYNTHETIC fixtures committed in
# tests/testthat/fixtures/ to prove the fixtures faithfully mirror the live wire
# shapes.
#
# SAFETY: this script issues ONLY HTTP GET requests against read endpoints. It
# never POSTs/PUTs/PATCHes/DELETEs, never places/cancels orders, never moves
# funds. Credentials are read from the package .Renviron via Sys.getenv() and are
# never printed. Raw bodies (which contain the user's real account data) are
# written ONLY under local/raw-data/alpaca/ which is git-ignored.
#
# Run from the package root:
#   Rscript dev/capture-alpaca.R

suppressWarnings(suppressMessages({
  library(httr2)
  library(jsonlite)
}))

# ---------------------------------------------------------------------------
# Credentials + hosts (from .Renviron, read via Sys.getenv) -- never printed.
# ---------------------------------------------------------------------------
if (file.exists(".Renviron")) {
  readRenviron(".Renviron")
}

api_key <- Sys.getenv("ALPACA_API_KEY")
api_secret <- Sys.getenv("ALPACA_API_SECRET")
if (!nzchar(api_key) || !nzchar(api_secret)) {
  stop(
    "ALPACA_API_KEY / ALPACA_API_SECRET are empty. ",
    "Set them in .Renviron before running this capture."
  )
}

# Trading host: derive scheme+host from ALPACA_API_URL (which may carry a /v2
# suffix), then ALPACA_API_ENDPOINT, then the package's paper default. The
# endpoint paths below already include the /v2 (or /v1beta1) prefix, so we strip
# any path component here and keep only `scheme://host`.
trading_raw <- Sys.getenv("ALPACA_API_URL")
if (!nzchar(trading_raw)) trading_raw <- Sys.getenv("ALPACA_API_ENDPOINT")
if (!nzchar(trading_raw)) trading_raw <- "https://paper-api.alpaca.markets"
.tu <- httr2::url_parse(trading_raw)
TRADING_HOST <- paste0(.tu$scheme, "://", .tu$hostname)

# Market data host: env override, else the package default.
DATA_HOST <- Sys.getenv("ALPACA_DATA_ENDPOINT")
if (!nzchar(DATA_HOST)) DATA_HOST <- "https://data.alpaca.markets"

OUT_DIR <- file.path("local", "raw-data", "alpaca")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Defensive: refuse to write anywhere git would track. local/ is git-ignored.
if (Sys.which("git") != "") {
  probe <- file.path(OUT_DIR, "ignore-probe.json")
  ignored <- suppressWarnings(system2(
    "git", c("check-ignore", probe),
    stdout = TRUE, stderr = FALSE
  ))
  if (length(ignored) == 0L) {
    stop(
      "Refusing to write: ", OUT_DIR,
      " is NOT git-ignored. Aborting to avoid committing real account data."
    )
  }
}

cat("Trading host:", TRADING_HOST, "\n")
cat("Data host   :", DATA_HOST, "\n")
cat("Output dir  :", normalizePath(OUT_DIR), "\n\n")

# Recent date window helpers (relative to today, so the script ages well).
today <- Sys.Date()
win_start <- as.character(today - 25)
win_end <- as.character(today)
bars_start <- as.character(today - 10)

# ---------------------------------------------------------------------------
# One GET: perform, write raw body verbatim, log a one-line status. Wrapped so a
# single failure (network, 4xx, parse) never aborts the batch.
# ---------------------------------------------------------------------------
log_rows <- list()

is_empty_body <- function(parsed) {
  # Empty if the decoded body has no elements, or every top-level element is
  # itself an empty array/object (the user's paper account is largely empty).
  if (is.null(parsed)) return(TRUE)
  if (length(parsed) == 0L) return(TRUE)
  if (is.list(parsed) && !is.null(names(parsed))) {
    data_keys <- setdiff(names(parsed), c("next_page_token", "symbol", "currency"))
    if (length(data_keys) > 0L) {
      all_empty <- all(vapply(
        parsed[data_keys],
        function(x) length(x) == 0L,
        logical(1)
      ))
      if (all_empty) return(TRUE)
    }
  }
  return(FALSE)
}

capture <- function(name, host, path, query = list()) {
  url <- paste0(host, path)
  result <- tryCatch(
    {
      req <- httr2::request(url) |>
        httr2::req_method("GET") |>
        httr2::req_headers(
          `APCA-API-KEY-ID` = api_key,
          `APCA-API-SECRET-KEY` = api_secret
        ) |>
        httr2::req_timeout(30) |>
        # Do NOT throw on 4xx/5xx -- we want to capture the error body too.
        httr2::req_error(is_error = function(resp) FALSE) |>
        httr2::req_user_agent("alpaca-capture-readonly/1.0")
      if (length(query) > 0L) {
        req <- httr2::req_url_query(req, !!!query)
      }
      resp <- httr2::req_perform(req)

      status <- httr2::resp_status(resp)
      body_raw <- httr2::resp_body_raw(resp)
      out_path <- file.path(OUT_DIR, paste0(name, ".json"))
      writeBin(body_raw, out_path)

      parsed <- tryCatch(
        jsonlite::fromJSON(rawToChar(body_raw), simplifyVector = FALSE),
        error = function(e) NULL
      )
      empty <- is_empty_body(parsed)
      list(
        name = name, status = status, bytes = length(body_raw),
        empty = empty, ok = status >= 200 && status < 300,
        parsed = parsed
      )
    },
    error = function(e) {
      list(
        name = name, status = NA_integer_, bytes = 0L,
        empty = NA, ok = FALSE, parsed = NULL, err = conditionMessage(e)
      )
    }
  )

  state <- if (!isTRUE(result$ok)) {
    "FAIL"
  } else if (isTRUE(result$empty)) {
    "EMPTY"
  } else {
    "POPULATED"
  }
  cat(sprintf(
    "%-26s GET %-44s status=%-4s bytes=%-7s %s%s\n",
    name, path,
    ifelse(is.na(result$status), "ERR", result$status),
    result$bytes, state,
    if (!is.null(result$err)) paste0("  <", result$err, ">") else ""
  ))
  log_rows[[name]] <<- result
  return(invisible(result))
}

# ---------------------------------------------------------------------------
# TRADING API (account, orders, positions, assets, etc.) -- read endpoints only.
# ---------------------------------------------------------------------------
cat("== Trading API ==\n")
capture("account", TRADING_HOST, "/v2/account")
capture("account_config", TRADING_HOST, "/v2/account/configurations")
capture("activities", TRADING_HOST, "/v2/account/activities", list(page_size = 10))
capture("portfolio_history", TRADING_HOST, "/v2/account/portfolio/history",
        list(period = "1M", timeframe = "1D"))
capture("positions", TRADING_HOST, "/v2/positions")
orders_res <- capture("orders_list", TRADING_HOST, "/v2/orders",
                      list(status = "all", limit = 50, direction = "desc"))
capture("assets", TRADING_HOST, "/v2/assets",
        list(status = "active", asset_class = "us_equity"))
capture("asset", TRADING_HOST, "/v2/assets/AAPL")
wl_res <- capture("watchlists", TRADING_HOST, "/v2/watchlists")
capture("calendar", TRADING_HOST, "/v2/calendar",
        list(start = win_start, end = win_end))
capture("clock", TRADING_HOST, "/v2/clock")
capture("corporate_actions", TRADING_HOST, "/v2/corporate_actions/announcements",
        list(ca_types = "dividend", since = win_start, until = win_end))
oc_res <- capture("option_contracts", TRADING_HOST, "/v2/options/contracts",
                  list(underlying_symbols = "AAPL", limit = 10))

# Dynamic single-resource follow-ups (only if the list returned something).
first_field <- function(res, field, container = NULL) {
  p <- res$parsed
  if (is.null(p)) return(NULL)
  if (!is.null(container)) p <- p[[container]]
  if (is.null(p) || length(p) == 0L) return(NULL)
  return(p[[1]][[field]])
}

oc_symbol <- first_field(oc_res, "symbol", container = "option_contracts")
if (!is.null(oc_symbol)) {
  capture("option_contract", TRADING_HOST,
          paste0("/v2/options/contracts/", oc_symbol))
}

order_id <- first_field(orders_res, "id")
if (!is.null(order_id)) {
  capture("order", TRADING_HOST, paste0("/v2/orders/", order_id))
}

wl_id <- first_field(wl_res, "id")
if (!is.null(wl_id)) {
  capture("watchlist", TRADING_HOST, paste0("/v2/watchlists/", wl_id))
}

# ---------------------------------------------------------------------------
# MARKET DATA API (stocks, screener, news, options data).
# Stocks use feed=iex (the free tier); options use feed=indicative.
# ---------------------------------------------------------------------------
cat("\n== Market Data API ==\n")

# Stock bars (single-symbol historical + multi-symbol + latest variants)
capture("bars", DATA_HOST, "/v2/stocks/AAPL/bars",
        list(timeframe = "1Day", start = bars_start, limit = 5, feed = "iex"))
capture("multi_bars", DATA_HOST, "/v2/stocks/bars",
        list(symbols = "AAPL,MSFT", timeframe = "1Day", start = bars_start,
             limit = 2, feed = "iex"))
capture("latest_bar", DATA_HOST, "/v2/stocks/AAPL/bars/latest", list(feed = "iex"))
capture("latest_bars_multi", DATA_HOST, "/v2/stocks/bars/latest",
        list(symbols = "AAPL,MSFT", feed = "iex"))
capture("trade", DATA_HOST, "/v2/stocks/AAPL/trades/latest", list(feed = "iex"))
capture("latest_trades_multi", DATA_HOST, "/v2/stocks/trades/latest",
        list(symbols = "AAPL,MSFT", feed = "iex"))
capture("quote", DATA_HOST, "/v2/stocks/AAPL/quotes/latest", list(feed = "iex"))
capture("latest_quotes_multi", DATA_HOST, "/v2/stocks/quotes/latest",
        list(symbols = "AAPL,MSFT", feed = "iex"))
capture("snapshot", DATA_HOST, "/v2/stocks/AAPL/snapshot", list(feed = "iex"))
capture("snapshots_multi", DATA_HOST, "/v2/stocks/snapshots",
        list(symbols = "AAPL,MSFT", feed = "iex"))

# Screener
capture("most_actives", DATA_HOST, "/v1beta1/screener/stocks/most-actives",
        list(top = 5))
capture("movers", DATA_HOST, "/v1beta1/screener/stocks/movers", list(top = 5))

# News
capture("news", DATA_HOST, "/v1beta1/news", list(symbols = "AAPL", limit = 5))

# Crypto orderbook
capture("crypto_orderbook", DATA_HOST, "/v1beta3/crypto/us/latest/orderbooks",
        list(symbols = "BTC/USD"))

# Options market data: chain snapshot by underlying, plus latest trades for a
# concrete contract symbol (derived from the contracts list above).
capture("option_chain", DATA_HOST, "/v1beta1/options/snapshots/AAPL",
        list(feed = "indicative", limit = 10))
if (!is.null(oc_symbol)) {
  capture("option_latest_trades", DATA_HOST, "/v1beta1/options/trades/latest",
          list(symbols = oc_symbol, feed = "indicative"))
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
cat("\n== Summary ==\n")
states <- vapply(log_rows, function(r) {
  if (!isTRUE(r$ok)) "FAIL" else if (isTRUE(r$empty)) "EMPTY" else "POPULATED"
}, character(1))
cat("POPULATED:", sum(states == "POPULATED"), "\n")
cat("EMPTY    :", sum(states == "EMPTY"), "\n")
cat("FAIL     :", sum(states == "FAIL"), "\n")
cat("Total    :", length(states), "\n")
cat("\nCaptures written to", OUT_DIR, "\n")
