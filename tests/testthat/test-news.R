# Tests for AlpacaMarketData news method

test_that("get_news returns long-format data.table with symbol column", {
  mock_perform <- function(req) {
    mock_alpaca_response(mock_news_response())
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_news(symbols = "AAPL", limit = 10)

  expect_s3_class(result, "data.table")
  # Article 1 has 1 symbol ("AAPL"), article 2 has 3 symbols ("AAPL", "MSFT", "NVDA")
  # Total rows = 1 + 3 = 4
  expect_equal(nrow(result), 4)
  expect_true(all(c("headline", "source", "author", "created_at", "symbol") %in% names(result)))
  expect_false("symbols" %in% names(result))
  expect_equal(result$source[1], "benzinga")
  # First article's single row
  expect_equal(result$symbol[1], "AAPL")
  # Second article expanded to 3 rows
  expect_setequal(result[id == 12346L]$symbol, c("AAPL", "MSFT", "NVDA"))
})

test_that("get_news uses data base URL", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_news_response())
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  market$get_news(symbols = "AAPL")

  expect_true(grepl("data.alpaca.markets", captured_req$url))
  expect_true(grepl("v1beta1/news", captured_req$url))
})

test_that("get_news passes query parameters", {
  captured_req <- NULL
  mock_perform <- function(req) {
    captured_req <<- req
    mock_alpaca_response(mock_news_response())
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  market$get_news(symbols = "AAPL,TSLA", limit = 5, sort = "asc")

  expect_true(grepl("limit=5", captured_req$url))
  expect_true(grepl("sort=asc", captured_req$url))
})

test_that("get_news handles empty response", {
  mock_perform <- function(req) {
    mock_alpaca_response(list(news = list(), next_page_token = NULL))
  }

  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_news()

  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 0)
})
