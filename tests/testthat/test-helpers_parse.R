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

test_that("parse_timestamp_cols converts present columns to POSIXct (UTC)", {
  dt <- data.table::data.table(
    id = c("a", "b"),
    created_at = c("2024-01-15T14:30:00Z", "2024-01-16T09:30:00Z"),
    other = c(1, 2)
  )
  parse_timestamp_cols(dt, c("created_at", "updated_at"))
  expect_s3_class(dt$created_at, "POSIXct")
  expect_equal(attr(dt$created_at, "tzone"), "UTC")
  expect_true(is.numeric(dt$other))
  expect_false("updated_at" %in% names(dt))
})

test_that("parse_timestamp_cols is a no-op on a 0-row data.table", {
  dt <- data.table::data.table(created_at = character())
  parse_timestamp_cols(dt, "created_at")
  expect_equal(nrow(dt), 0L)
  expect_true("created_at" %in% names(dt))
})

test_that("parse_timestamp_cols preserves NA values inside a real column", {
  dt <- data.table::data.table(
    submitted_at = c("2024-01-15T14:30:00Z", NA_character_)
  )
  parse_timestamp_cols(dt, "submitted_at")
  expect_s3_class(dt$submitted_at, "POSIXct")
  expect_false(is.na(dt$submitted_at[1]))
  expect_true(is.na(dt$submitted_at[2]))
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

# -- collapse_string_array_fields NA-safety --

test_that("collapse_string_array_fields handles scalar NA_character_ input without crashing", {
  # Regression: previously crashed on scalar NA. `grepl(";", NA_character_)`
  # returns NA, propagates through `any(NA)`, and crashes `if (NA)`.
  result <- collapse_string_array_fields(list(x = NA_character_), "x")
  expect_true(is.na(result$x))
  expect_type(result$x, "character")
})

test_that("collapse_string_array_fields filters NA elements before joining", {
  # `paste(c("real", NA), collapse = ";")` would produce the literal
  # `"real;NA"`, indistinguishable from a real "NA" value. NAs must
  # be filtered out first.
  result <- collapse_string_array_fields(
    list(x = c("a", NA_character_, "b")),
    "x"
  )
  expect_equal(result$x, "a;b")
})

test_that("collapse_string_array_fields returns NA_character_ for all-NA vectors", {
  # When every element is NA, the joined string would be empty; round
  # this back to NA_character_ so all-missing arrays match the
  # null / empty-array case.
  result <- collapse_string_array_fields(
    list(x = c(NA_character_, NA_character_)),
    "x"
  )
  expect_true(is.na(result$x))
})

test_that("collapse_string_array_fields preserves the existing null/empty/normal behaviour", {
  expect_true(is.na(collapse_string_array_fields(list(x = NULL), "x")$x))
  expect_true(is.na(collapse_string_array_fields(list(x = character(0)), "x")$x))
  expect_equal(
    collapse_string_array_fields(list(x = c("a", "b", "c")), "x")$x,
    "a;b;c"
  )
})

# -- coerce_cols --

test_that("coerce_cols applies fn to each column present, in place", {
  dt <- data.table::data.table(
    a = c("2024-01-15T14:30:00Z", "2024-01-16T09:30:00Z"),
    b = c("x", "y"),
    c = c("2024-02-01T00:00:00Z", "2024-02-02T00:00:00Z")
  )
  invisible(coerce_cols(dt, c("a", "c"), rfc3339_to_datetime))
  expect_s3_class(dt$a, "POSIXct")
  expect_s3_class(dt$c, "POSIXct")
  expect_equal(dt$b, c("x", "y"))
})

test_that("coerce_cols silently skips columns not in the data.table", {
  dt <- data.table::data.table(a = "2024-01-15T14:30:00Z")
  invisible(coerce_cols(dt, c("a", "missing"), rfc3339_to_datetime))
  expect_s3_class(dt$a, "POSIXct")
  expect_false("missing" %in% names(dt))
})

test_that("coerce_cols is a no-op on an empty data.table", {
  dt <- data.table::data.table(a = character())
  invisible(coerce_cols(dt, "a", rfc3339_to_datetime))
  expect_equal(nrow(dt), 0L)
  expect_type(dt$a, "character")
})

test_that("coerce_cols works with arbitrary functions, not just timestamp parsers", {
  dt <- data.table::data.table(price = c("100.5", "200.5"), qty = c("1", "2"))
  invisible(coerce_cols(dt, c("price", "qty"), as.numeric))
  expect_type(dt$price, "double")
  expect_type(dt$qty, "double")
  expect_equal(dt$price, c(100.5, 200.5))
})

# -- rfc3339_to_datetime all-NA shape regression --

test_that("rfc3339_to_datetime returns full-length POSIXct vector for all-NA input", {
  # Pre-fix: returned length-1 NA_POSIXct_ on all-NA input. Piped back
  # through `coerce_cols()` -> `data.table::set()` that scalar got
  # coerced into the existing column's type, leaving documented-POSIXct
  # columns as numeric / character. Now returns a length-matching
  # POSIXct vector.
  result <- rfc3339_to_datetime(c(NA_character_, NA_character_))
  expect_s3_class(result, "POSIXct")
  expect_length(result, 2L)
  expect_true(all(is.na(result)))
})

test_that("coerce_cols + rfc3339_to_datetime converts an all-NA column to POSIXct (regression)", {
  dt <- data.table::data.table(filled_at = c(NA_character_, NA_character_))
  invisible(coerce_cols(dt, "filled_at", rfc3339_to_datetime))
  expect_s3_class(dt$filled_at, "POSIXct")
  expect_length(dt$filled_at, 2L)
  expect_true(all(is.na(dt$filled_at)))
})
