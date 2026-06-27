# ---- then_or_now ----

test_that("then_or_now applies function synchronously", {
  result <- then_or_now(5, function(x) x * 2, is_async = FALSE)
  expect_equal(result, 10)
})

# ---- parse_alpaca_response ----

test_that("parse_alpaca_response handles 204 No Content", {
  resp <- mock_no_content_response()
  result <- parse_alpaca_response(resp)
  expect_type(result, "list")
  expect_length(result, 0L)
})

test_that("parse_alpaca_response parses JSON body", {
  resp <- mock_alpaca_response(list(foo = "bar", baz = 42))
  result <- parse_alpaca_response(resp)
  expect_equal(result$foo, "bar")
  expect_equal(result$baz, 42)
})

test_that("parse_alpaca_response throws on error status", {
  resp <- mock_alpaca_error("Order not found", status_code = 404L)
  expect_error(parse_alpaca_response(resp), "404.*Order not found")
})

test_that("parse_alpaca_response throws on 422 with message", {
  resp <- mock_alpaca_error("qty is required", status_code = 422L)
  expect_error(parse_alpaca_response(resp), "422.*qty is required")
})

# ---- alpaca_build_request ----

test_that("alpaca_build_request adds auth headers", {
  captured_req <- NULL
  resp <- mock_alpaca_response(list(status = "ok"))
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  alpaca_build_request(
    base_url = "https://paper-api.alpaca.markets",
    endpoint = "/v2/account",
    keys = keys
  )

  expect_equal(captured_req$headers[["APCA-API-KEY-ID"]], "test-key")
  expect_equal(captured_req$headers[["APCA-API-SECRET-KEY"]], "test-secret")
})

test_that("alpaca_build_request applies .parser", {
  resp <- mock_alpaca_response(list(value = 42))
  httr2::local_mocked_responses(function(req) resp)

  result <- alpaca_build_request(
    base_url = "https://paper-api.alpaca.markets",
    endpoint = "/v2/test",
    .parser = function(data) data$value * 2
  )

  expect_equal(result, 84)
})

test_that("alpaca_build_request sends JSON body for POST", {
  captured_req <- NULL
  resp <- mock_alpaca_response(list(id = "order-123"))
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  keys <- get_api_keys(api_key = "k", api_secret = "s")
  alpaca_build_request(
    base_url = "https://paper-api.alpaca.markets",
    endpoint = "/v2/orders",
    method = "POST",
    body = list(symbol = "AAPL", qty = "1"),
    keys = keys
  )

  expect_equal(captured_req$method, "POST")
})

# ---- alpaca_serialize_body (body-byte pinning) ----
#
# The connectcore migration moved bodies onto the shared funnel. To stay
# wire-identical to the pre-migration transport, AlpacaBase pre-serialises every
# body with `alpaca_serialize_body()` and sends the result verbatim via
# connectcore's `body_format = "raw"` path. These tests pin the exact bytes so a
# future serialisation change (e.g. an `auto_unbox` flip that silently turns a
# single-symbol watchlist into a scalar) can never pass unnoticed again.

# The exact bytes the pre-migration funnel emitted, computed directly with no
# httr2-internal reach-in: drop NULLs, then serialise with the same
# `jsonlite::toJSON()` options `httr2::req_body_json()` used (auto_unbox = TRUE,
# digits = 22, null = "null"). This mirrors the production serializer
# (`alpaca_serialize_body()`) byte-for-byte, including its single-symbol
# watchlist array handling, so it pins the real wire contract.
master_body_bytes <- function(body) {
  body <- body[!vapply(body, is.null, logical(1))]
  if (!is.null(body$symbols)) {
    body$symbols <- as.list(body$symbols)
  }
  return(as.character(jsonlite::toJSON(
    body,
    auto_unbox = TRUE,
    digits = 22,
    null = "null"
  )))
}

test_that("alpaca_serialize_body is byte-identical to the pre-migration funnel for an order", {
  order <- list(
    symbol = "AAPL",
    side = "buy",
    type = "limit",
    time_in_force = "day",
    qty = "10",
    limit_price = "150.5",
    take_profit = list(limit_price = 200),
    stop_loss = list(stop_price = 140, limit_price = 139)
  )

  expect_identical(alpaca_serialize_body(order), master_body_bytes(order))
})

test_that("alpaca_serialize_body keeps a single-symbol watchlist a JSON array", {
  # The regression this guards against: auto_unbox would collapse a length-1
  # character vector to a bare scalar ("ONESYM"), which Alpaca's watchlist
  # endpoints reject. The body MUST carry a JSON array.
  expect_identical(
    alpaca_serialize_body(list(name = "My", symbols = "ONESYM")),
    "{\"name\":\"My\",\"symbols\":[\"ONESYM\"]}"
  )
})

test_that("alpaca_serialize_body leaves a multi-symbol watchlist unchanged vs the funnel", {
  body <- list(name = "My", symbols = c("AAPL", "MSFT"))
  expect_identical(
    alpaca_serialize_body(body),
    "{\"name\":\"My\",\"symbols\":[\"AAPL\",\"MSFT\"]}"
  )
  # And a multi-element array was already an array pre-migration, so the bytes match.
  expect_identical(alpaca_serialize_body(body), master_body_bytes(body))
})

test_that("alpaca_serialize_body returns NULL when the body prunes to nothing", {
  # The pre-migration funnel sent no body in this case (its length > 0 guard);
  # NULL signals AlpacaBase to take the bodyless funnel path.
  expect_null(alpaca_serialize_body(list(a = NULL, b = NULL)))
  expect_null(alpaca_serialize_body(list()))
})

# ---- AlpacaBase request body (wire bytes through the client) ----

# Capture the fully-applied request body bytes for a client method call.
capture_request_body <- function(client, call) {
  captured <- new.env()
  client$.__enclos_env__$private$.perform <- function(req) {
    applied <- httr2:::req_body_apply(req)
    captured$bytes <- if (is.null(applied$body)) {
      NA_character_
    } else if (is.raw(applied$body$data)) {
      rawToChar(applied$body$data)
    } else {
      as.character(applied$body$data)
    }
    return(httr2::response(
      status_code = 200L,
      headers = list(`Content-Type` = "application/json"),
      body = charToRaw("{}")
    ))
  }
  try(call(client), silent = TRUE)
  return(captured$bytes)
}

test_that("add_watchlist sends a single symbol as a JSON array", {
  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  bytes <- capture_request_body(acct, function(c) c$add_watchlist("My", symbols = "ONESYM"))
  expect_identical(bytes, "{\"name\":\"My\",\"symbols\":[\"ONESYM\"]}")
})

test_that("modify_watchlist sends a single symbol as a JSON array", {
  acct <- AlpacaAccount$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  bytes <- capture_request_body(acct, function(c) {
    c$modify_watchlist("wl-uuid-1", name = "My", symbols = "ONESYM")
  })
  expect_identical(bytes, "{\"name\":\"My\",\"symbols\":[\"ONESYM\"]}")
})

test_that("add_order body is byte-identical to the pre-migration funnel", {
  trd <- AlpacaTrading$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets"
  )
  bytes <- capture_request_body(trd, function(c) {
    c$add_order(symbol = "AAPL", side = "buy", type = "market", time_in_force = "day", qty = 10)
  })
  params <- validate_order_params(
    symbol = "AAPL",
    side = "buy",
    type = "market",
    time_in_force = "day",
    qty = 10
  )
  expect_identical(bytes, master_body_bytes(params))
})

test_that("alpaca_build_request drops NULL query params", {
  captured_req <- NULL
  resp <- mock_alpaca_response(list())
  httr2::local_mocked_responses(function(req) {
    captured_req <<- req
    return(resp)
  })

  alpaca_build_request(
    base_url = "https://paper-api.alpaca.markets",
    endpoint = "/v2/test",
    query = list(a = "1", b = NULL, c = "3")
  )

  # URL should contain a=1 and c=3 but not b
  url <- captured_req$url
  expect_true(grepl("a=1", url))
  expect_true(grepl("c=3", url))
  expect_false(grepl("b=", url))
})
