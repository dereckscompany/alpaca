#!/bin/bash

# R Package Lint Script
# Runs lintr on the package WITH the package loaded first, so that
# object_usage_linter honours utils::globalVariables() declarations
# in R/zzz.R (data.table NSE columns etc.).
#
# Why this matters: `lintr::lint_package()` does NOT auto-load the
# package, so without devtools::load_all() it emits false-positive
# "no visible binding for global variable" warnings for every
# data.table column reference like `dt[, col := value]`.

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

Rscript -e '
suppressMessages(devtools::load_all(quiet = TRUE))
l <- lintr::lint_package()
if (length(l) == 0L) {
  cat("\n[OK] lintr: 0 warnings.\n")
  quit(status = 0)
}
cat("\n[WARN] lintr:", length(l), "warning(s).\n\n")
print(l)
quit(status = 1)
'
