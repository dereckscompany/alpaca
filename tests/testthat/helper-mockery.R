# Mock response builders for alpaca unit tests.
# Sourced automatically by testthat via helper prefix convention.

# ---- Core Response Builder ----

#' Build a mock httr2 response with Alpaca JSON body
#'
#' @param data List to encode as JSON body.
#' @param status_code Integer; HTTP status code.
#' @return An httr2 response object.
mock_alpaca_response <- function(data, status_code = 200L) {
  body <- jsonlite::toJSON(data, auto_unbox = TRUE, null = "null")
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

mock_bars_response <- function() {
  list(
    bars = list(
      list(
        t = "2024-01-02T05:00:00Z",
        o = 187.15,
        h = 188.44,
        l = 183.89,
        c = 185.64,
        v = 82488700L,
        n = 1036517L,
        vw = 185.831
      ),
      list(
        t = "2024-01-03T05:00:00Z",
        o = 184.22,
        h = 185.88,
        l = 183.43,
        c = 184.25,
        v = 58414500L,
        n = 729382L,
        vw = 184.567
      )
    ),
    symbol = "AAPL",
    next_page_token = NULL
  )
}

mock_multi_bars_response <- function() {
  list(
    bars = list(
      AAPL = list(
        list(
          t = "2024-01-02T05:00:00Z",
          o = 187.15,
          h = 188.44,
          l = 183.89,
          c = 185.64,
          v = 82488700L,
          n = 1036517L,
          vw = 185.831
        )
      ),
      MSFT = list(
        list(
          t = "2024-01-02T05:00:00Z",
          o = 373.00,
          h = 375.50,
          l = 371.20,
          c = 374.30,
          v = 25100000L,
          n = 425000L,
          vw = 373.890
        )
      )
    ),
    next_page_token = NULL
  )
}

mock_trade_response <- function() {
  list(
    trade = list(
      t = "2024-01-15T14:30:00.123Z",
      p = 185.50,
      s = 100L,
      x = "V",
      c = list("@"),
      z = "C",
      i = 12345L
    )
  )
}

mock_quote_response <- function() {
  list(
    quote = list(
      t = "2024-01-15T14:30:00.456Z",
      ax = "V",
      ap = 185.55,
      "as" = 200L,
      bx = "Q",
      bp = 185.50,
      bs = 300L,
      c = list("R"),
      z = "C"
    )
  )
}

mock_snapshot_response <- function() {
  list(
    # latestTrade.c is the multi-condition path (collapse to "@;T").
    # latestQuote.c is the single-condition path (collapse to "R").
    # The bar sections also have a `c` field but it's the close price
    # (scalar number) — must NOT be touched by the conditions-collapse path.
    latestTrade = list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L, c = list("@", "T")),
    latestQuote = list(t = "2024-01-15T14:30:00Z", ap = 185.55, bp = 185.50, "as" = 200L, bs = 300L, c = list("R")),
    minuteBar = list(
      t = "2024-01-15T14:30:00Z",
      o = 185.40,
      h = 185.60,
      l = 185.30,
      c = 185.50,
      v = 5000L,
      n = 50L,
      vw = 185.45
    ),
    dailyBar = list(
      t = "2024-01-15T05:00:00Z",
      o = 184.00,
      h = 186.00,
      l = 183.50,
      c = 185.50,
      v = 50000000L,
      n = 500000L,
      vw = 185.00
    ),
    prevDailyBar = list(
      t = "2024-01-14T05:00:00Z",
      o = 183.00,
      h = 185.00,
      l = 182.50,
      c = 184.00,
      v = 45000000L,
      n = 450000L,
      vw = 183.80
    )
  )
}

mock_assets_response <- function() {
  list(
    list(
      id = "uuid-1",
      class = "us_equity",
      exchange = "NASDAQ",
      symbol = "AAPL",
      name = "Apple Inc.",
      status = "active",
      tradable = TRUE,
      marginable = TRUE,
      shortable = TRUE,
      fractionable = TRUE,
      attributes = list("fractional_eh_enabled", "has_options", "overnight_tradable")
    ),
    list(
      id = "uuid-2",
      class = "us_equity",
      exchange = "NASDAQ",
      symbol = "MSFT",
      name = "Microsoft Corporation",
      status = "active",
      tradable = TRUE,
      marginable = TRUE,
      shortable = TRUE,
      fractionable = TRUE,
      attributes = list()
    )
  )
}

mock_clock_response <- function() {
  list(
    timestamp = "2024-01-15T14:30:00.000-05:00",
    is_open = TRUE,
    next_open = "2024-01-16T09:30:00-05:00",
    next_close = "2024-01-15T16:00:00-05:00"
  )
}

mock_calendar_response <- function() {
  list(
    list(date = "2024-01-02", open = "09:30", close = "16:00"),
    list(date = "2024-01-03", open = "09:30", close = "16:00")
  )
}

# ---- Trading Fixtures ----

mock_order_response <- function() {
  list(
    id = "order-uuid-123",
    client_order_id = "client-123",
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    status = "accepted",
    qty = "1",
    filled_qty = "0",
    filled_avg_price = NULL,
    limit_price = "150.00",
    stop_price = NULL,
    created_at = "2024-01-15T14:30:00Z",
    submitted_at = "2024-01-15T14:30:00Z"
  )
}

# Bracket-order response: parent order with two child legs (take-profit
# limit + stop-loss). Shape mirrors the live `/v2/orders` POST response
# captured during PR verification — each leg is itself a full order
# object with its own id, side ("sell"), limit/stop prices, and status.
mock_bracket_order_response <- function() {
  list(
    id = "bracket-parent",
    client_order_id = "client-bracket-parent",
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "gtc",
    order_class = "bracket",
    status = "accepted",
    qty = "1",
    filled_qty = "0",
    limit_price = "1.00",
    stop_price = NULL,
    created_at = "2024-01-15T14:30:00Z",
    submitted_at = "2024-01-15T14:30:00Z",
    legs = list(
      list(
        id = "leg-tp",
        client_order_id = "client-leg-tp",
        symbol = "AAPL",
        side = "sell",
        type = "limit",
        time_in_force = "gtc",
        order_class = "bracket",
        status = "held",
        qty = "1",
        filled_qty = "0",
        limit_price = "500.00",
        stop_price = NULL,
        created_at = "2024-01-15T14:30:00Z",
        submitted_at = "2024-01-15T14:30:00Z",
        legs = NULL
      ),
      list(
        id = "leg-sl",
        client_order_id = "client-leg-sl",
        symbol = "AAPL",
        side = "sell",
        type = "stop_limit",
        time_in_force = "gtc",
        order_class = "bracket",
        status = "held",
        qty = "1",
        filled_qty = "0",
        limit_price = "0.40",
        stop_price = "0.50",
        created_at = "2024-01-15T14:30:00Z",
        submitted_at = "2024-01-15T14:30:00Z",
        legs = NULL
      )
    )
  )
}

mock_orders_list_response <- function() {
  list(
    list(
      id = "order-1",
      symbol = "AAPL",
      side = "buy",
      type = "limit",
      status = "new",
      qty = "1",
      filled_qty = "0",
      created_at = "2024-01-15T14:30:00Z"
    ),
    list(
      id = "order-2",
      symbol = "MSFT",
      side = "sell",
      type = "market",
      status = "filled",
      qty = "10",
      filled_qty = "10",
      created_at = "2024-01-15T14:31:00Z"
    )
  )
}

# ---- Account Fixtures ----

mock_account_response <- function() {
  list(
    id = "acct-uuid-123",
    account_number = "PA1234567",
    status = "ACTIVE",
    currency = "USD",
    cash = "100000",
    portfolio_value = "100000",
    equity = "100000",
    last_equity = "99500",
    buying_power = "400000",
    initial_margin = "0",
    maintenance_margin = "0",
    long_market_value = "0",
    short_market_value = "0",
    pattern_day_trader = FALSE,
    trading_blocked = FALSE,
    transfers_blocked = FALSE,
    account_blocked = FALSE,
    daytrade_count = 0L,
    daytrading_buying_power = "0",
    regt_buying_power = "200000",
    multiplier = "4",
    sma = "0",
    created_at = "2024-01-01T00:00:00Z"
  )
}

mock_positions_response <- function() {
  list(
    list(
      asset_id = "uuid-aapl",
      symbol = "AAPL",
      exchange = "NASDAQ",
      asset_class = "us_equity",
      avg_entry_price = "185.50",
      qty = "10",
      side = "long",
      market_value = "1870.00",
      cost_basis = "1855.00",
      unrealized_pl = "15.00",
      unrealized_plpc = "0.008",
      current_price = "187.00",
      lastday_price = "186.00",
      change_today = "0.005"
    )
  )
}

mock_portfolio_history_response <- function() {
  list(
    timestamp = list(1704067200L, 1704153600L, 1704240000L),
    equity = list(100000.0, 100150.5, 99800.25),
    profit_loss = list(0.0, 150.5, -200.25),
    profit_loss_pct = list(0.0, 0.001505, -0.002),
    base_value = 100000.0,
    timeframe = "1D"
  )
}

mock_activities_response <- function() {
  list(
    list(
      id = "act-1",
      activity_type = "FILL",
      symbol = "AAPL",
      side = "buy",
      qty = "10",
      price = "185.50",
      transaction_time = "2024-01-15T14:30:00Z"
    ),
    list(
      id = "act-2",
      activity_type = "FILL",
      symbol = "MSFT",
      side = "sell",
      qty = "5",
      price = "374.00",
      transaction_time = "2024-01-15T14:31:00Z"
    )
  )
}

# ---- Options Fixtures ----

mock_option_contracts_response <- function() {
  list(
    option_contracts = list(
      list(
        id = "opt-uuid-1",
        symbol = "AAPL240621C00200000",
        name = "AAPL Jun 21 2024 200.00 Call",
        status = "active",
        tradable = TRUE,
        type = "call",
        strike_price = "200.00",
        expiration_date = "2024-06-21",
        underlying_symbol = "AAPL",
        underlying_asset_id = "uuid-aapl",
        style = "american",
        root_symbol = "AAPL",
        size = "100",
        open_interest = "1234",
        close_price = "5.50"
      ),
      list(
        id = "opt-uuid-2",
        symbol = "AAPL240621P00180000",
        name = "AAPL Jun 21 2024 180.00 Put",
        status = "active",
        tradable = TRUE,
        type = "put",
        strike_price = "180.00",
        expiration_date = "2024-06-21",
        underlying_symbol = "AAPL",
        underlying_asset_id = "uuid-aapl",
        style = "american",
        root_symbol = "AAPL",
        size = "100",
        open_interest = "567",
        close_price = "3.20"
      )
    ),
    next_page_token = NULL
  )
}

mock_option_contracts_with_deliverables_response <- function() {
  # Exercises `show_deliverables = TRUE`: one contract with a single
  # deliverable (typical equity option), one contract with two
  # deliverables (e.g. a post-corporate-action contract).
  list(
    option_contracts = list(
      list(
        id = "opt-uuid-1",
        symbol = "AAPL240621C00200000",
        name = "AAPL Jun 21 2024 200.00 Call",
        status = "active",
        tradable = TRUE,
        type = "call",
        strike_price = "200.00",
        expiration_date = "2024-06-21",
        underlying_symbol = "AAPL",
        underlying_asset_id = "uuid-aapl",
        style = "american",
        root_symbol = "AAPL",
        size = "100",
        open_interest = "1234",
        close_price = "5.50",
        deliverables = list(
          list(
            type = "equity",
            symbol = "AAPL",
            asset_id = "uuid-aapl",
            amount = "100",
            allocation_percentage = "100",
            settlement_type = "T+1",
            settlement_method = "BTOB",
            delayed_settlement = FALSE
          )
        )
      ),
      list(
        id = "opt-uuid-spinoff",
        symbol = "OLDCOSPINOFF000",
        name = "Post-spinoff combined contract",
        status = "active",
        tradable = TRUE,
        type = "call",
        strike_price = "50.00",
        expiration_date = "2026-01-16",
        underlying_symbol = "OLDCO",
        underlying_asset_id = "uuid-oldco",
        style = "american",
        root_symbol = "OLDCO",
        size = "100",
        open_interest = "12",
        close_price = "1.20",
        deliverables = list(
          list(
            type = "equity",
            symbol = "NEWCO",
            asset_id = "uuid-newco",
            amount = "100",
            allocation_percentage = "60",
            settlement_type = "T+1",
            settlement_method = "BTOB",
            delayed_settlement = FALSE
          ),
          list(
            type = "cash",
            symbol = "USD",
            asset_id = NULL,
            amount = "250.00",
            allocation_percentage = "40",
            settlement_type = "T+1",
            settlement_method = "BTOB",
            delayed_settlement = FALSE
          )
        )
      )
    ),
    next_page_token = NULL
  )
}

mock_option_contract_response <- function() {
  list(
    id = "opt-uuid-1",
    symbol = "AAPL240621C00200000",
    name = "AAPL Jun 21 2024 200.00 Call",
    status = "active",
    tradable = TRUE,
    type = "call",
    strike_price = "200.00",
    expiration_date = "2024-06-21",
    underlying_symbol = "AAPL",
    style = "american",
    root_symbol = "AAPL",
    size = "100",
    open_interest = "1234",
    close_price = "5.50"
  )
}

# ---- Watchlist Fixtures ----

mock_watchlists_response <- function() {
  list(
    list(
      id = "wl-uuid-1",
      account_id = "acct-uuid-123",
      name = "Tech Stocks",
      created_at = "2024-01-10T10:00:00Z",
      updated_at = "2024-01-15T14:30:00Z"
    ),
    list(
      id = "wl-uuid-2",
      account_id = "acct-uuid-123",
      name = "Value Plays",
      created_at = "2024-01-12T08:00:00Z",
      updated_at = "2024-01-14T09:00:00Z"
    )
  )
}

mock_watchlist_response <- function() {
  # Asset 1 has a populated `attributes` array; asset 2 has none. This
  # mirrors the live response shape and exercises the empty-vs-populated
  # branch in `parse_watchlist()` so the collapse keeps a character column
  # instead of falling back to a list column.
  list(
    id = "wl-uuid-1",
    account_id = "acct-uuid-123",
    name = "Tech Stocks",
    created_at = "2024-01-10T10:00:00Z",
    updated_at = "2024-01-15T14:30:00Z",
    assets = list(
      list(
        id = "uuid-1",
        symbol = "AAPL",
        name = "Apple Inc.",
        attributes = list("fractional_eh_enabled", "has_options")
      ),
      list(
        id = "uuid-2",
        symbol = "MSFT",
        name = "Microsoft Corporation",
        attributes = list()
      )
    )
  )
}

# ---- Corporate Actions Fixtures ----

mock_corporate_actions_response <- function() {
  list(
    list(
      id = "ca-uuid-1",
      corporate_action_id = "CA123",
      ca_type = "dividend",
      ca_sub_type = "cash",
      initiating_symbol = "AAPL",
      target_symbol = "AAPL",
      declaration_date = "2024-01-25",
      ex_date = "2024-02-09",
      record_date = "2024-02-12",
      payable_date = "2024-02-15",
      cash = "0.24",
      old_rate = NULL,
      new_rate = NULL
    ),
    list(
      id = "ca-uuid-2",
      corporate_action_id = "CA456",
      ca_type = "split",
      ca_sub_type = "forward",
      initiating_symbol = "NVDA",
      target_symbol = "NVDA",
      declaration_date = "2024-05-22",
      ex_date = "2024-06-10",
      record_date = "2024-06-07",
      payable_date = "2024-06-10",
      cash = NULL,
      old_rate = "1",
      new_rate = "10"
    )
  )
}

# ---- News Fixtures ----

mock_news_response <- function() {
  list(
    news = list(
      # Article 1: 1 symbol, 1 image (regular case)
      list(
        id = 12345L,
        headline = "Apple Reports Record Q1 Earnings",
        author = "Jane Doe",
        source = "benzinga",
        summary = "Apple Inc. reported record first quarter earnings...",
        url = "https://example.com/article/12345",
        symbols = list("AAPL"),
        created_at = "2024-01-25T18:30:00Z",
        updated_at = "2024-01-25T18:30:00Z",
        images = list(
          list(size = "large", url = "https://cdn.example.com/12345-large.jpg")
        )
      ),
      # Article 2: 3 symbols, 2 images (would have been 3x2=6 rows under the
      # old cartesian bug; should be exactly 1 row now)
      list(
        id = 12346L,
        headline = "Tech Sector Rallies on AI Optimism",
        author = "John Smith",
        source = "reuters",
        summary = "Technology stocks rallied broadly...",
        url = "https://example.com/article/12346",
        symbols = list("AAPL", "MSFT", "NVDA"),
        created_at = "2024-01-25T16:00:00Z",
        updated_at = "2024-01-25T16:00:00Z",
        images = list(
          list(size = "large", url = "https://cdn.example.com/12346-large.jpg"),
          list(size = "thumb", url = "https://cdn.example.com/12346-thumb.jpg")
        )
      ),
      # Article 3: no symbols, no images (empty-array edge case)
      list(
        id = 12347L,
        headline = "Some Generic Markets Headline",
        author = "Anon",
        source = "wire",
        summary = "A market-wide story without specific tickers.",
        url = "https://example.com/article/12347",
        symbols = list(),
        created_at = "2024-01-25T15:00:00Z",
        updated_at = "2024-01-25T15:00:00Z",
        images = list()
      ),
      # Article 4: URL with a literal `;` to exercise the percent-encode path
      list(
        id = 12348L,
        headline = "URL with semicolons",
        author = "Edge",
        source = "test",
        summary = "Article whose image URL contains a `;` query separator.",
        url = "https://example.com/article/12348",
        symbols = list("TSLA"),
        created_at = "2024-01-25T14:00:00Z",
        updated_at = "2024-01-25T14:00:00Z",
        images = list(
          list(size = "large", url = "https://cdn.example.com/12348.jpg?w=2048;h=1536")
        )
      ),
      # Article 5: URL whose source already contains a pre-existing `%3B`
      # (literal percent-three-bee, e.g. a signed query string). Exercises
      # the `%` -> `%25` step that makes URLdecode() truly lossless.
      list(
        id = 12349L,
        headline = "URL with a pre-existing %3B in the source",
        author = "Edge",
        source = "test",
        summary = "Article whose image URL already contains a percent-encoded `;`.",
        url = "https://example.com/article/12349",
        symbols = list("AMZN"),
        created_at = "2024-01-25T13:00:00Z",
        updated_at = "2024-01-25T13:00:00Z",
        images = list(
          list(size = "large", url = "https://cdn.example.com/12349.jpg?token=abc%3Bdef")
        )
      ),
      # Article 6: two images where only ONE has a size field. Exercises the
      # partial-missing path — must produce empty token (""), not literal
      # "NA" string.
      list(
        id = 12350L,
        headline = "Article with partially-missing image sizes",
        author = "Edge",
        source = "test",
        summary = "Article where one image is missing its size field.",
        url = "https://example.com/article/12350",
        symbols = list("GOOG"),
        created_at = "2024-01-25T12:00:00Z",
        updated_at = "2024-01-25T12:00:00Z",
        images = list(
          list(size = "large", url = "https://cdn.example.com/12350-a.jpg"),
          list(url = "https://cdn.example.com/12350-b.jpg")  # no size
        )
      )
    ),
    next_page_token = NULL
  )
}

# ---- Pagination Fixtures ----

mock_bars_page1_response <- function() {
  list(
    bars = list(
      list(
        t = "2024-01-02T05:00:00Z",
        o = 187.15,
        h = 188.44,
        l = 183.89,
        c = 185.64,
        v = 82488700L,
        n = 1036517L,
        vw = 185.831
      )
    ),
    symbol = "AAPL",
    next_page_token = "token-page-2"
  )
}

mock_bars_page2_response <- function() {
  list(
    bars = list(
      list(
        t = "2024-01-03T05:00:00Z",
        o = 184.22,
        h = 185.88,
        l = 183.43,
        c = 184.25,
        v = 58414500L,
        n = 729382L,
        vw = 184.567
      )
    ),
    symbol = "AAPL",
    next_page_token = NULL
  )
}

# ---- Account Config Fixtures ----

mock_account_config_response <- function() {
  list(
    dtbp_check = "both",
    no_shorting = FALSE,
    suspend_trade = FALSE,
    trade_confirm_email = "all",
    fractional_trading = TRUE,
    max_margin_multiplier = "4",
    pdt_check = "both",
    max_options_trading_level = 2L
  )
}

# ---- Multi-Symbol Latest Fixtures ----

mock_latest_bars_multi_response <- function() {
  list(
    bars = list(
      AAPL = list(
        t = "2024-01-15T14:30:00Z",
        o = 185.00,
        h = 186.00,
        l = 184.50,
        c = 185.50,
        v = 1000000L,
        n = 10000L,
        vw = 185.25
      ),
      MSFT = list(
        t = "2024-01-15T14:30:00Z",
        o = 373.00,
        h = 374.00,
        l = 372.50,
        c = 373.50,
        v = 500000L,
        n = 5000L,
        vw = 373.25
      )
    )
  )
}

mock_latest_trades_multi_response <- function() {
  list(
    trades = list(
      AAPL = list(
        t = "2024-01-15T14:30:00.123Z",
        p = 185.50,
        s = 100L,
        x = "V",
        c = list("@"),
        z = "C",
        i = 12345L
      ),
      MSFT = list(
        t = "2024-01-15T14:30:00.456Z",
        p = 373.50,
        s = 50L,
        x = "Q",
        c = list("@"),
        z = "C",
        i = 12346L
      )
    )
  )
}

mock_latest_quotes_multi_response <- function() {
  list(
    quotes = list(
      AAPL = list(
        t = "2024-01-15T14:30:00.456Z",
        ax = "V",
        ap = 185.55,
        "as" = 200L,
        bx = "Q",
        bp = 185.50,
        bs = 300L,
        c = list("R"),
        z = "C"
      ),
      MSFT = list(
        t = "2024-01-15T14:30:00.789Z",
        ax = "Q",
        ap = 373.55,
        "as" = 100L,
        bx = "V",
        bp = 373.50,
        bs = 150L,
        c = list("R"),
        z = "C"
      )
    )
  )
}

mock_snapshots_multi_response <- function() {
  list(
    AAPL = list(
      latestTrade = list(t = "2024-01-15T14:30:00Z", p = 185.50, s = 100L),
      latestQuote = list(t = "2024-01-15T14:30:00Z", ap = 185.55, bp = 185.50, "as" = 200L, bs = 300L),
      minuteBar = list(
        t = "2024-01-15T14:30:00Z",
        o = 185.40,
        h = 185.60,
        l = 185.30,
        c = 185.50,
        v = 5000L,
        n = 50L,
        vw = 185.45
      ),
      dailyBar = list(
        t = "2024-01-15T05:00:00Z",
        o = 184.00,
        h = 186.00,
        l = 183.50,
        c = 185.50,
        v = 50000000L,
        n = 500000L,
        vw = 185.00
      ),
      prevDailyBar = list(
        t = "2024-01-14T05:00:00Z",
        o = 183.00,
        h = 185.00,
        l = 182.50,
        c = 184.00,
        v = 45000000L,
        n = 450000L,
        vw = 183.80
      )
    ),
    MSFT = list(
      latestTrade = list(t = "2024-01-15T14:30:00Z", p = 373.50, s = 50L),
      latestQuote = list(t = "2024-01-15T14:30:00Z", ap = 373.55, bp = 373.50, "as" = 100L, bs = 150L),
      minuteBar = list(
        t = "2024-01-15T14:30:00Z",
        o = 373.00,
        h = 374.00,
        l = 372.50,
        c = 373.50,
        v = 3000L,
        n = 30L,
        vw = 373.25
      ),
      dailyBar = list(
        t = "2024-01-15T05:00:00Z",
        o = 372.00,
        h = 375.00,
        l = 371.00,
        c = 373.50,
        v = 25000000L,
        n = 250000L,
        vw = 373.00
      ),
      prevDailyBar = list(
        t = "2024-01-14T05:00:00Z",
        o = 371.00,
        h = 373.00,
        l = 370.00,
        c = 372.00,
        v = 22000000L,
        n = 220000L,
        vw = 371.50
      )
    )
  )
}

# ---- Screener Fixtures ----

mock_most_actives_response <- function() {
  list(
    most_actives = list(
      list(symbol = "TSLA", volume = 150000000, trade_count = 2000000),
      list(symbol = "AAPL", volume = 80000000, trade_count = 1000000),
      list(symbol = "NVDA", volume = 70000000, trade_count = 900000)
    )
  )
}

mock_movers_response <- function() {
  list(
    gainers = list(
      list(symbol = "XYZ", percent_change = 15.5, change = 3.20, price = 23.85),
      list(symbol = "ABC", percent_change = 12.3, change = 5.10, price = 46.55)
    ),
    losers = list(
      list(symbol = "DEF", percent_change = -10.2, change = -4.50, price = 39.60),
      list(symbol = "GHI", percent_change = -8.5, change = -2.10, price = 22.60)
    )
  )
}

# ---- Crypto Orderbook Fixtures ----

mock_crypto_orderbook_response <- function() {
  list(
    orderbooks = list(
      "BTC/USD" = list(
        t = "2024-01-15T20:00:00.123456Z",
        b = list(
          list(p = 42950.50, s = 0.5),
          list(p = 42949.00, s = 1.2)
        ),
        a = list(
          list(p = 42951.00, s = 0.3),
          list(p = 42952.50, s = 0.8)
        )
      )
    )
  )
}

# ---- Option Latest Trades / Chain Fixtures ----

mock_option_latest_trades_response <- function() {
  list(
    trades = list(
      AAPL240621C00200000 = list(
        t = "2024-06-15T14:30:00.123Z",
        p = 5.50,
        s = 10L,
        x = "C",
        c = list("@"),
        i = 99999L
      )
    )
  )
}

mock_option_chain_response <- function() {
  list(
    snapshots = list(
      AAPL240621C00200000 = list(
        latestTrade = list(t = "2024-06-15T14:30:00Z", p = 5.50, s = 10L),
        latestQuote = list(t = "2024-06-15T14:30:00Z", ap = 5.60, bp = 5.40, "as" = 50L, bs = 40L)
      ),
      AAPL240621C00210000 = list(
        latestTrade = list(t = "2024-06-15T14:30:00Z", p = 3.20, s = 5L),
        latestQuote = list(t = "2024-06-15T14:30:00Z", ap = 3.30, bp = 3.10, "as" = 30L, bs = 25L)
      )
    )
  )
}

mock_option_chain_with_greeks_response <- function() {
  # Includes the top-level `impliedVolatility` scalar and nested
  # `greeks` object that Alpaca returns for options snapshots — both
  # were being silently dropped before the parser fix.
  list(
    snapshots = list(
      AAPL240621C00200000 = list(
        latestTrade = list(t = "2024-06-15T14:30:00Z", p = 5.50, s = 10L, c = list("a")),
        latestQuote = list(t = "2024-06-15T14:30:00Z", ap = 5.60, bp = 5.40, "as" = 50L, bs = 40L, c = list("R")),
        impliedVolatility = 0.2712,
        greeks = list(
          delta = -0.4577,
          gamma = 0.0187,
          theta = -0.0756,
          vega = 0.3215,
          rho = -0.1289
        )
      )
    )
  )
}
