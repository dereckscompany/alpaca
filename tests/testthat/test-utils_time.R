test_that("time_convert_from_alpaca parses RFC-3339 timestamps", {
  result <- time_convert_from_alpaca("2024-01-15T14:30:00Z")
  expect_s3_class(result, "POSIXct")
})

test_that("time_convert_from_alpaca handles timezone offsets", {
  result <- time_convert_from_alpaca("2024-01-15T14:30:00-05:00")
  expect_s3_class(result, "POSIXct")
})

test_that("time_convert_from_alpaca returns NA for NULL", {
  expect_true(is.na(time_convert_from_alpaca(NULL)))
})

test_that("time_convert_from_alpaca returns NA for NA", {
  expect_true(is.na(time_convert_from_alpaca(NA)))
})

test_that("time_convert_to_alpaca formats POSIXct to RFC-3339", {
  dt <- as.POSIXct("2024-01-15 14:30:00", tz = "UTC")
  result <- time_convert_to_alpaca(dt)
  expect_equal(result, "2024-01-15T14:30:00Z")
})

test_that("time_convert_to_alpaca accepts character input", {
  result <- time_convert_to_alpaca("2024-01-15 14:30:00")
  expect_type(result, "character")
  expect_match(result, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$")
})

test_that("time_convert_to_alpaca returns NA for NULL", {
  expect_true(is.na(time_convert_to_alpaca(NULL)))
})
