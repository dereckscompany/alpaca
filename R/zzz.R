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
  "asset_attributes",
  "image_sizes",
  "image_urls",
  # Crypto orderbook NSE columns
  "level",
  "side",
  "price",
  "size",
  # Option contract deliverables NSE
  "deliverable_index",
  # Calendar parser NSE (date/time conversion in get_calendar)
  "date",
  "open",
  "close",
  "session_open",
  "session_close",
  "settlement_date"
))
