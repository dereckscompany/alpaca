# Tests for AlpacaMarketData news method
#
# Policy: one article = one row. `symbols`, `image_sizes` and `image_urls` are
# semicolon-collapsed character columns. The four fixture articles in
# `mock_news_response()` exercise:
#   1. one symbol + one image (regular)
#   2. three symbols + two images (used to cartesian to 6 rows)
#   3. empty symbols + empty images (NA columns)
#   4. a single image whose URL contains a literal ";" (percent-encode path)

test_that("get_news returns one row per article (no cartesian inflation)", {
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
  # Four articles in -> four rows out. Not 1 + 3 + 1 + 1 = 6, and definitely
  # not the prior 1 + (3 x 2) + 1 + 1 = 9 cartesian.
  expect_equal(nrow(result), 4)

  # Layout: original `symbols` column is gone-then-renamed to one column.
  expect_true(all(c("headline", "source", "author", "created_at", "symbols",
                    "image_sizes", "image_urls") %in% names(result)))

  # Article 1: single symbol, single image
  expect_equal(result[id == 12345L]$symbols, "AAPL")
  expect_equal(result[id == 12345L]$image_sizes, "large")
  expect_equal(result[id == 12345L]$image_urls,
               "https://cdn.example.com/12345-large.jpg")
})

test_that("get_news joins multiple symbols with `;` on a single row", {
  mock_perform <- function(req) mock_alpaca_response(mock_news_response())
  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_news()
  row <- result[id == 12346L]
  expect_equal(nrow(row), 1L)
  expect_equal(row$symbols, "AAPL;MSFT;NVDA")
  expect_equal(row$image_sizes, "large;thumb")
  expect_equal(row$image_urls,
               paste("https://cdn.example.com/12346-large.jpg",
                     "https://cdn.example.com/12346-thumb.jpg",
                     sep = ";"))
})

test_that("get_news represents empty arrays as NA on the article row", {
  mock_perform <- function(req) mock_alpaca_response(mock_news_response())
  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_news()
  row <- result[id == 12347L]
  expect_equal(nrow(row), 1L)
  expect_true(is.na(row$symbols))
  expect_true(is.na(row$image_sizes))
  expect_true(is.na(row$image_urls))
})

test_that("get_news percent-encodes literal `;` inside image URLs", {
  mock_perform <- function(req) mock_alpaca_response(mock_news_response())
  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_news()
  row <- result[id == 12348L]
  expect_equal(nrow(row), 1L)
  # Original URL contained `;`; collapsed value should contain `%3B` for that
  # one character only.
  expect_equal(row$image_urls,
               "https://cdn.example.com/12348.jpg?w=2048%3Bh=1536")
  # Round-trip: split on `;`, URLdecode each piece, get back the original URL.
  pieces <- strsplit(row$image_urls, ";", fixed = TRUE)[[1]]
  decoded <- vapply(pieces, URLdecode, character(1))
  expect_equal(unname(decoded[1]),
               "https://cdn.example.com/12348.jpg?w=2048;h=1536")
})

test_that("get_news returns no list columns", {
  mock_perform <- function(req) mock_alpaca_response(mock_news_response())
  market <- AlpacaMarketData$new(
    keys = list(api_key = "k", api_secret = "s"),
    base_url = "https://paper-api.alpaca.markets",
    data_base_url = "https://data.alpaca.markets"
  )
  market$.__enclos_env__$private$.perform <- mock_perform

  result <- market$get_news()
  list_cols <- names(result)[vapply(result, is.list, logical(1))]
  expect_equal(length(list_cols), 0L)
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
