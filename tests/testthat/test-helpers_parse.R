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

test_that("parse_date_cols converts present columns to Date", {
  dt <- data.table::data.table(
    id = c("a", "b"),
    ex_date = c("2024-02-09", "2024-06-10"),
    other = c(1, 2)
  )
  parse_date_cols(dt, c("ex_date", "record_date"))
  expect_s3_class(dt$ex_date, "Date")
  expect_equal(format(dt$ex_date), c("2024-02-09", "2024-06-10"))
  expect_true(is.numeric(dt$other))
  # Missing column silently skipped.
  expect_false("record_date" %in% names(dt))
})

test_that("parse_date_cols is a no-op on a 0-row data.table", {
  dt <- data.table::data.table(ex_date = character())
  parse_date_cols(dt, "ex_date")
  expect_equal(nrow(dt), 0L)
  expect_true("ex_date" %in% names(dt))
})

test_that("parse_date_cols preserves NA values inside a real column", {
  dt <- data.table::data.table(
    payable_date = c("2024-02-15", NA_character_)
  )
  parse_date_cols(dt, "payable_date")
  expect_s3_class(dt$payable_date, "Date")
  expect_false(is.na(dt$payable_date[1]))
  expect_true(is.na(dt$payable_date[2]))
})
