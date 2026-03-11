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
