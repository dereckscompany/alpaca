# Suppress R CMD check notes for data.table non-standard evaluation
utils::globalVariables(c(
  ".",
  ".N",
  ".SD",
  ":="
))
