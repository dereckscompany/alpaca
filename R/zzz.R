# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":=",
  "symbol",
  "timeframe",
  "timestamp",
  # data.table NSE inside parsers (assigned via `dt[, col := ...]`)
  "leg_index",
  "parent_order_id",
  "asset_id",
  "asset_name",
  "asset_symbol",
  "image_sizes",
  "image_urls"
))
