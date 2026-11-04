# Internal helpers ------------------------------------------------------------

# TRUE if x is a numeric vector of finite whole numbers without NAs
.is_whole <- function(x) {
  is.numeric(x) && length(x) > 0L && !anyNA(x) && all(is.finite(x)) &&
    all(x == round(x))
}

# Fill a "{var}" pattern with columns of `data`.
#
# Replaces the hand-written bracket parser of the legacy code. For every
# well-formed pattern it produces exactly the same strings: literal text is
# kept as is and each {var} is replaced by data[[var]] (converted by paste0).
.fill_pattern <- function(pattern, data, what = "pattern") {
  if (!is.character(pattern) || length(pattern) != 1L || is.na(pattern))
    stop(what, " must be a single character string.", call. = FALSE)
  m <- gregexpr("\\{[^{}]*\\}", pattern)
  vars <- regmatches(pattern, m)[[1L]]
  literals <- regmatches(pattern, m, invert = TRUE)[[1L]]
  vars <- substr(vars, 2L, nchar(vars) - 1L)
  if (any(grepl("[{}]", literals)) || any(vars == ""))
    stop("Ill-formed ", what, ": \"", pattern, "\"", call. = FALSE)
  missing_vars <- setdiff(vars, names(data))
  if (length(missing_vars))
    stop(paste(missing_vars, collapse = ", "), " not found in ", what,
         " data! Available: ", paste(names(data), collapse = ", "),
         call. = FALSE)
  n <- if (is.data.frame(data)) nrow(data) else length(data[[1L]])
  out <- rep(literals[1L], n)
  for (k in seq_along(vars))
    out <- paste0(out, data[[vars[k]]], literals[k + 1L])
  out
}

# Data frames of a list result (single data frame or list of strata), NULLs dropped
.as_df_list <- function(x) {
  if (is.data.frame(x)) {
    out <- list(x)
    names(out) <- if (!is.null(x$stratum_name)) x$stratum_name[1L] else "stratum"
    return(out)
  }
  if (!is.list(x)) stop("Expected a data frame or a list of data frames.", call. = FALSE)
  Filter(Negate(is.null), x)
}
