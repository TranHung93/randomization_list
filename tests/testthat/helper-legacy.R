# Load the frozen legacy implementation (inst/legacy/createRandoListNew.R)
# into its own environment so it can be run side by side with the new code.
load_legacy <- function() {
  path <- system.file("legacy", "createRandoListNew.R", package = "randolist")
  if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "legacy", "createRandoListNew.R")
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}
legacy <- load_legacy()

strip_info <- function(x) {
  attr(x, "rando_info") <- NULL
  x
}

# Run legacy and new code from the same seed
run_both <- function(seed, ...) {
  set.seed(seed)
  old <- suppressMessages(suppressWarnings(legacy$createRandoList(...)))
  set.seed(seed)
  new <- createRandoList(...)
  list(old = old, new = strip_info(new))
}

# Did the legacy bug apply? (last permutation group holds a single patient)
last_group_singleton <- function(d) {
  if (is.null(d$permute.block)) return(FALSE)
  g <- d$permute.block
  sum(g == g[length(g)]) == 1L
}

# Compare one stratum: identical, except the patient ID / RanNo of the last row
# when the legacy bug applied.
expect_same_as_legacy <- function(new, old) {
  if (is.null(old)) return(testthat::expect_null(new))
  if (!last_group_singleton(old)) return(testthat::expect_identical(new, old))
  n <- nrow(old)
  id_cols <- c(names(old)[1L], "RanNo")
  testthat::expect_identical(new[-n, ], old[-n, ])
  other <- setdiff(names(old), id_cols)
  testthat::expect_identical(new[n, other], old[n, other])
  # the fixed ID is the one missing from the other rows
  testthat::expect_false(anyDuplicated(new[[1L]]) > 0)
}
