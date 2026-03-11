# Test: async closure capture in impl_bars.R
#
# R closures capture variables by reference (lazy evaluation). In a for-loop,
# the loop variable `seg` is shared across all iterations, so by the time the
# promises resolve, every closure sees the LAST value of `seg`.
#
# The fix uses Reduce() instead of a for-loop. Reduce() passes each element as
# a function argument, which forces eager evaluation per iteration.

test_that("async bar fetch captures each segment independently (Reduce fix)", {
  segments <- list(
    list(start = as.POSIXct("2024-01-01", tz = "UTC"), end = as.POSIXct("2024-01-09", tz = "UTC")),
    list(start = as.POSIXct("2024-01-10", tz = "UTC"), end = as.POSIXct("2024-01-19", tz = "UTC")),
    list(start = as.POSIXct("2024-01-20", tz = "UTC"), end = as.POSIXct("2024-01-29", tz = "UTC"))
  )

  fetch_segment <- function(seg) {
    promises::promise(function(resolve, reject) {
      resolve(data.table::data.table(
        start = format(seg$start, "%Y-%m-%d"),
        end = format(seg$end, "%Y-%m-%d")
      ))
    })
  }

  combine_results <- function(results) {
    data.table::rbindlist(results)
  }

  # NOTE: Reduce() is used instead of a for-loop to avoid the closure capture
  # bug. Reduce() passes `seg` as a function argument, forcing eager evaluation
  # per iteration. A for-loop closure over `seg` would resolve every promise
  # using the LAST segment's value. This mirrors the pattern in impl_bars.R.
  seed <- promises::promise_resolve(list())
  chain <- Reduce(
    function(acc_promise, seg) {
      promises::then(acc_promise, function(acc) {
        promises::then(fetch_segment(seg), function(result) {
          c(acc, list(result))
        })
      })
    },
    segments,
    accumulate = FALSE,
    init = seed
  )
  final_promise <- promises::then(chain, combine_results)

  # Force resolution
  result <- NULL
  promises::then(final_promise, function(val) {
    result <<- val
  })
  for (i in 1:20) {
    later::run_now(0.1)
  }

  expect_false(is.null(result), info = "Promise should have resolved")
  expect_equal(nrow(result), 3L)

  # Each row must have its own start date — not all the last one
  expect_equal(result$start[1], "2024-01-01")
  expect_equal(result$start[2], "2024-01-10")
  expect_equal(result$start[3], "2024-01-20")
  expect_equal(length(unique(result$start)), 3L)
})
