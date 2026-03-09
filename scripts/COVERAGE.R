#!/usr/bin/env Rscript
# Coverage Analysis Script

# Parse arguments first (before loading packages)
args <- commandArgs(trailingOnly = TRUE)

# Help text
show_help <- function() {
  cat(
    "
COVERAGE.R - Code coverage analysis for R package

USAGE:
  ./scripts/COVERAGE.R [OPTIONS]
  Rscript scripts/COVERAGE.R [OPTIONS]

OPTIONS:
  (none)      Show coverage summary grouped by level
  detail      Show summary + list uncovered functions
  report      Show summary + open interactive HTML report
  -h, --help  Show this help message

EXAMPLES:
  ./scripts/COVERAGE.R              # Quick summary

  ./scripts/COVERAGE.R detail       # See which functions need tests
  ./scripts/COVERAGE.R report       # Interactive browser report

COVERAGE LEVELS:
  Zero    =  0%       Files with no test coverage
  Low     <  50%      Files needing more tests
  Medium  >= 50-80%   Files with decent coverage
  High    >= 80%      Well-tested files

"
  )
  quit(status = 0)
}

# Check for help flag
if (length(args) > 0 && args[1] %in% c("-h", "--help", "help")) {
  show_help()
}

mode <- if (length(args) > 0) args[1] else "summary"

# Validate mode
valid_modes <- c("summary", "detail", "report")
if (!mode %in% valid_modes) {
  cat(sprintf("Error: Unknown option '%s'\n", mode))
  cat("Run with --help for usage information.\n")
  quit(status = 1)
}

# Now load packages and run analysis
library(covr)

cat("Running coverage analysis for package...\n\n")

# Run coverage
cov <- package_coverage()

# Overall summary
cat("=============================================================================\n")
cat("                        COVERAGE SUMMARY\n")
cat("=============================================================================\n\n")
cat(sprintf("Overall Coverage: %.2f%%\n\n", percent_coverage(cov)))

# File-by-file coverage
df <- as.data.frame(cov)

# Calculate per-file coverage
file_coverage <- aggregate(
  value ~ filename,
  data = df,
  FUN = function(x) round(100 * sum(x > 0) / length(x), 2)
)
names(file_coverage) <- c("file", "coverage")
file_coverage <- file_coverage[order(file_coverage$coverage), ]

# Separate by coverage level
zero_coverage <- file_coverage[file_coverage$coverage == 0, ]
low_coverage <- file_coverage[file_coverage$coverage > 0 & file_coverage$coverage < 50, ]
medium_coverage <- file_coverage[file_coverage$coverage >= 50 & file_coverage$coverage < 80, ]
high_coverage <- file_coverage[file_coverage$coverage >= 80, ]

cat("Files with ZERO coverage (need tests):\n")
cat("---------------------------------------\n")
if (nrow(zero_coverage) > 0) {
  for (i in seq_len(nrow(zero_coverage))) {
    cat(sprintf("  %s\n", zero_coverage$file[i]))
  }
} else {
  cat("  None!\n")
}

cat("\nFiles with LOW coverage (<50%):\n")
cat("-------------------------------\n")
if (nrow(low_coverage) > 0) {
  for (i in seq_len(nrow(low_coverage))) {
    cat(sprintf("  %6.2f%%  %s\n", low_coverage$coverage[i], low_coverage$file[i]))
  }
} else {
  cat("  None!\n")
}

cat("\nFiles with MEDIUM coverage (50-80%):\n")
cat("------------------------------------\n")
if (nrow(medium_coverage) > 0) {
  for (i in seq_len(nrow(medium_coverage))) {
    cat(sprintf("  %6.2f%%  %s\n", medium_coverage$coverage[i], medium_coverage$file[i]))
  }
} else {
  cat("  None!\n")
}

cat("\nFiles with HIGH coverage (>=80%):\n")
cat("---------------------------------\n")
if (nrow(high_coverage) > 0) {
  for (i in seq_len(nrow(high_coverage))) {
    cat(sprintf("  %6.2f%%  %s\n", high_coverage$coverage[i], high_coverage$file[i]))
  }
} else {
  cat("  None!\n")
}

cat("\n=============================================================================\n")
cat(sprintf(
  "Total: %d files | Zero: %d | Low: %d | Medium: %d | High: %d\n",
  nrow(file_coverage),
  nrow(zero_coverage),
  nrow(low_coverage),
  nrow(medium_coverage),
  nrow(high_coverage)
))
cat("=============================================================================\n")

# Detailed mode: show uncovered functions
if (mode == "detail") {
  cat("\n\n=== UNCOVERED FUNCTIONS ===\n\n")

  # Get unique function names that have no coverage
  uncovered_funcs <- unique(df[df$value == 0, c("filename", "functions")])
  uncovered_funcs <- uncovered_funcs[order(uncovered_funcs$filename), ]

  current_file <- ""
  for (i in seq_len(nrow(uncovered_funcs))) {
    if (uncovered_funcs$filename[i] != current_file) {
      current_file <- uncovered_funcs$filename[i]
      cat(sprintf("\n%s:\n", current_file))
    }
    cat(sprintf("  - %s\n", uncovered_funcs$functions[i]))
  }
}

# Interactive report mode
if (mode == "report") {
  cat("\nOpening interactive coverage report...\n")
  report(cov)
}

cat("\nDone.\n")
