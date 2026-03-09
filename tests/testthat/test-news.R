# Tests for AlpacaMarketData news method

test_that("get_news returns data.table of articles", {
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
  expect_equal(nrow(result), 2)
  expect_true(all(c("headline", "source", "author", "created_at") %in% names(result)))
  expect_equal(result$source[1], "benzinga")
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
