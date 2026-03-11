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
