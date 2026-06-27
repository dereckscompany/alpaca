#' @import assert
#' @import data.table
#' @import promises
NULL

# Generic transport + JSON->data.table helpers come from connectcore. Importing
# them into the package namespace lets internal code (and tests) call them by
# their bare names, exactly as when they lived in this package.
#' @importFrom connectcore then_or_now to_snake_case as_dt_row as_dt_list collapse_string_array_fields
NULL
