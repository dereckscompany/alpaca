#!/usr/bin/env Rscript
# Pre-compile vignettes that depend on external data (local/ohlcv.rda)
#
# Usage: Rscript scripts/VIGNETTES.R        (all vignettes)
#        Rscript scripts/VIGNETTES.R intro   (only matching vignettes)
#
# Run from package root directory.
#
# This follows the rOpenSci/R-hub recommended pattern for vignettes that
# require data or resources unavailable during R CMD check.
# Source vignettes are .Rmd.orig files; knitr::knit() produces .Rmd with
# static output that R CMD build can process without re-evaluation.

# --- pre-flight ---------------------------------------------------------

if (!file.exists("DESCRIPTION")) {
  stop("Run this script from the package root directory")
}

if (!file.exists("local/ohlcv.rda")) {
  warning("local/ohlcv.rda not found — vignettes using real data will fail")
}

# Attach namespaces so data() finds datasets and data.table's [.data.table
# dispatches `:=` correctly inside the knitr::knit() environment.
# Vignette code uses box::use() for the user-facing API; attachNamespace()
# simply ensures the search path is set up for the pre-compilation step.
for (pkg in c("alpaca")) {
  attachNamespace(loadNamespace(pkg))
}

# --- discover files -----------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
orig_files <- list.files("vignettes", pattern = "\\.Rmd\\.orig$", full.names = TRUE)

if (length(args) > 0) {
  pattern <- args[1]
  orig_files <- orig_files[grepl(pattern, basename(orig_files), ignore.case = TRUE)]
}

if (length(orig_files) == 0) {
  message("No .Rmd.orig files found")
  quit(status = 0)
}

# --- knit ---------------------------------------------------------------

message(sprintf("Pre-compiling %d vignette(s)...\n", length(orig_files)))

failed <- character()

for (orig in orig_files) {
  output <- sub("\\.orig$", "", orig)
  message(sprintf("  %s -> %s", basename(orig), basename(output)))

  t0 <- proc.time()
  # Change to vignettes/ directory so fig.path and data paths
  # resolve relative to the .Rmd file (not the package root)
  old_wd <- setwd(dirname(orig))
  ok <- tryCatch(
    {
      knitr::knit(basename(orig), basename(output), quiet = TRUE, envir = new.env(parent = globalenv()))
      TRUE
    },
    error = function(e) {
      message(sprintf("    ERROR: %s", conditionMessage(e)))
      FALSE
    }
  )
  setwd(old_wd)
  elapsed <- (proc.time() - t0)[["elapsed"]]

  if (ok) {
    message(sprintf("    done (%.1fs)", elapsed))
  } else {
    failed <- c(failed, basename(orig))
  }
  message("")
}

# --- summary ------------------------------------------------------------

if (length(failed) > 0) {
  message(sprintf("FAILED (%d): %s", length(failed), paste(failed, collapse = ", ")))
  quit(status = 1)
} else {
  message(sprintf("All %d vignettes pre-compiled successfully.", length(orig_files)))
}
