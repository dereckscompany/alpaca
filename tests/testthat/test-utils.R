test_that("get_base_url returns default paper trading URL", {
  withr::with_envvar(c(ALPACA_API_ENDPOINT = ""), {
    expect_equal(get_base_url(), "https://paper-api.alpaca.markets")
  })
})

test_that("get_base_url uses env var when set", {
  withr::with_envvar(c(ALPACA_API_ENDPOINT = "https://api.alpaca.markets"), {
    expect_equal(get_base_url(), "https://api.alpaca.markets")
  })
})

test_that("get_base_url uses explicit parameter over env var", {
  withr::with_envvar(c(ALPACA_API_ENDPOINT = "https://api.alpaca.markets"), {
    expect_equal(get_base_url("https://custom.url"), "https://custom.url")
  })
})

test_that("get_data_base_url returns default data URL", {
  withr::with_envvar(c(ALPACA_DATA_ENDPOINT = ""), {
    expect_equal(get_data_base_url(), "https://data.alpaca.markets")
  })
})

test_that("get_data_base_url uses env var when set", {
  withr::with_envvar(c(ALPACA_DATA_ENDPOINT = "https://custom-data.url"), {
    expect_equal(get_data_base_url(), "https://custom-data.url")
  })
})

test_that("get_api_keys returns list with api_key and api_secret", {
  keys <- get_api_keys(api_key = "test-key", api_secret = "test-secret")
  expect_type(keys, "list")
  expect_equal(keys$api_key, "test-key")
  expect_equal(keys$api_secret, "test-secret")
})

test_that("get_api_keys reads from env vars", {
  withr::with_envvar(c(ALPACA_API_KEY = "env-key", ALPACA_API_SECRET = "env-secret"), {
    keys <- get_api_keys()
    expect_equal(keys$api_key, "env-key")
    expect_equal(keys$api_secret, "env-secret")
  })
})
