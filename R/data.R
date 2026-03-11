#' AAPL Daily OHLCV Bars (Sample Data)
#'
#' Simulated daily bar data for AAPL (Apple Inc.) covering 250 trading days
#' in 2024. Generated with a random walk model for demonstration and testing
#' purposes. Column structure matches the output of
#' [AlpacaMarketData]`$get_bars()`.
#'
#' @format A [data.table::data.table] with 250 rows and 8 columns:
#' \describe{
#'   \item{timestamp}{POSIXct. Bar timestamp in UTC.}
#'   \item{open}{Numeric. Opening price.}
#'   \item{high}{Numeric. Highest price during the day.}
#'   \item{low}{Numeric. Lowest price during the day.}
#'   \item{close}{Numeric. Closing price.}
#'   \item{volume}{Integer. Volume traded.}
#'   \item{trade_count}{Integer. Number of trades.}
#'   \item{vwap}{Numeric. Volume-weighted average price.}
#' }
#'
#' @source Simulated data (random walk with parameters based on AAPL 2024).
#' @examples
#' data(alpaca_aapl_1day_bars)
#' head(alpaca_aapl_1day_bars)
"alpaca_aapl_1day_bars"
