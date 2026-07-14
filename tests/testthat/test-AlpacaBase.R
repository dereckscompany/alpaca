KEYS <- get_api_keys(api_key = "k", api_secret = "s")
BASE <- "https://paper-api.alpaca.markets"

test_that("AlpacaBase initializes in sync mode by default", {
  base <- AlpacaBase$new(keys = KEYS, base_url = BASE)
  expect_false(base$is_async)
})

test_that("AlpacaBase initializes in async mode", {
  skip_if_not_installed("promises")
  base <- AlpacaBase$new(keys = KEYS, base_url = BASE, async = TRUE)
  expect_true(base$is_async)
})

test_that("AlpacaBase is_async is read-only", {
  base <- AlpacaBase$new(keys = KEYS, base_url = BASE)
  expect_error(base$is_async <- TRUE)
})

test_that("AlpacaBase returns invisible self from initialize", {
  result <- AlpacaBase$new(keys = KEYS, base_url = BASE)
  expect_s3_class(result, "AlpacaBase")
})

test_that("AlpacaBase rejects max_tries outside [1, 10]", {
  expect_error(AlpacaBase$new(keys = KEYS, base_url = BASE, max_tries = 0L))
  expect_error(AlpacaBase$new(keys = KEYS, base_url = BASE, max_tries = 11L))
})

# -- max_tries: the hard GET-only retry carve-out --
#
# `httr2::req_perform()` short-circuits its retry loop whenever the `httr2_mock`
# option is set, so `local_mocked_responses()` cannot exercise retry. We mock the
# per-attempt fetch (`httr2:::req_perform1`) instead, letting `req_perform()`
# re-drive it against the policy the constructor's `max_tries` threaded into
# `connectcore::build_request()`; `sys_sleep` is stubbed so backoff is instant.

test_that("a non-idempotent POST is performed exactly once even with max_tries = 5", {
  base <- AlpacaBase$new(keys = KEYS, base_url = BASE, max_tries = 5L)
  n <- 0L
  testthat::local_mocked_bindings(
    sys_sleep = function(seconds, ...) invisible(),
    req_perform1 = function(req, req_prep, path, handle, resend_count) {
      n <<- n + 1L
      return(mock_alpaca_error("Internal Server Error", status_code = 500L))
    },
    .package = "httr2"
  )
  priv <- base$.__enclos_env__$private
  expect_error(priv$.request(endpoint = "/v2/orders", method = "POST", auth = FALSE))
  expect_identical(n, 1L) # never a silent resend of an order
})

test_that("a transient 500 on a GET is retried and then succeeds (max_tries = 3)", {
  base <- AlpacaBase$new(keys = KEYS, base_url = BASE, max_tries = 3L)
  n <- 0L
  testthat::local_mocked_bindings(
    sys_sleep = function(seconds, ...) invisible(),
    req_perform1 = function(req, req_prep, path, handle, resend_count) {
      n <<- n + 1L
      if (n == 1L) {
        return(mock_alpaca_error("Internal Server Error", status_code = 500L))
      }
      return(mock_alpaca_response(list(ok = TRUE)))
    },
    .package = "httr2"
  )
  priv <- base$.__enclos_env__$private
  out <- priv$.request(endpoint = "/v2/account", method = "GET", auth = FALSE)
  expect_true(out$ok)
  expect_identical(n, 2L) # retried once on the 500, then succeeded
})
