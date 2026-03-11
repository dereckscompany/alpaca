test_that("to_snake_case converts camelCase correctly", {
  expect_equal(to_snake_case("camelCase"), "camel_case")
  expect_equal(to_snake_case("alreadySnake"), "already_snake")
  expect_equal(to_snake_case("HTMLParser"), "html_parser")
  expect_equal(to_snake_case("simpleTest"), "simple_test")
})

test_that("as_dt_row handles NULL input", {
  expect_true(nrow(as_dt_row(NULL)) == 0L)
  expect_true(nrow(as_dt_row(list())) == 0L)
})

test_that("as_dt_row converts named list to single-row data.table", {
  result <- as_dt_row(list(fooBar = 1, bazQux = "a"))
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 1L)
  expect_true("foo_bar" %in% names(result))
  expect_true("baz_qux" %in% names(result))
})

test_that("as_dt_row converts NULL values to NA", {
  result <- as_dt_row(list(a = 1, b = NULL))
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$b))
})

test_that("as_dt_list handles NULL and empty input", {
  expect_true(nrow(as_dt_list(NULL)) == 0L)
  expect_true(nrow(as_dt_list(list())) == 0L)
})

test_that("as_dt_list row-binds list of lists", {
  items <- list(
    list(a = 1, b = "x"),
    list(a = 2, b = "y")
  )
  result <- as_dt_list(items)
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2L)
})

test_that("rfc3339_to_datetime parses ISO timestamps", {
  result <- rfc3339_to_datetime("2024-01-15T14:30:00Z")
  expect_s3_class(result, "POSIXct")
})

test_that("rfc3339_to_datetime returns NA for NULL input", {
  result <- rfc3339_to_datetime(NULL)
  expect_true(is.na(result))
})
