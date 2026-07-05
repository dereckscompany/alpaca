# tests/testthat/test-backfill.R
# Tests for alpaca_backfill_bars. We stub alpaca_fetch_bars so the test
# stays independent of HTTP mocks.

test_that("alpaca_backfill_bars warns per failure and emits a final summary warning", {
  outfile <- tempfile(fileext = ".csv")
  on.exit(unlink(outfile), add = TRUE)

  warnings_seen <- character(0)
  result <- testthat::with_mocked_bindings(
    {
      withCallingHandlers(
        suppressMessages(alpaca_backfill_bars(
          symbols = "AAPL",
          timeframes = "1Day",
          from = "2024-01-01",
          to = "2024-01-31",
          path = outfile,
          sleep = 0,
          keys = list(api_key = "x", api_secret = "y"),
          data_base_url = "https://example.invalid"
        )),
        warning = function(w) {
          warnings_seen <<- c(warnings_seen, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      )
    },
    alpaca_fetch_bars = function(...) stop("simulated network error")
  )

  # Per-combo warning fires inside the tryCatch error handler.
  expect_true(any(grepl("AAPL", warnings_seen) & grepl("FAILED", warnings_seen)))
  # Final summary warning lists the failure count + identifier.
  expect_true(any(
    grepl("1 of 1", warnings_seen) &
      grepl("AAPL|1Day", warnings_seen)
  ))

  # No hidden state on the return value.
  expect_s3_class(result, "data.table")
  expect_null(attr(result, "failures"))
})
