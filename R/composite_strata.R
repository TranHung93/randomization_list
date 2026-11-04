# Combine vectors of strata into composite strata.
# Behaviour is unchanged from the legacy createRandoListNew.R (April 2021);
# only the pattern parser is replaced by the shared .fill_pattern().
composite_strata <- function(..., compartments = list(), code_sep = "-",
                             code_pattern = NULL, name_sep = ".") {
  compartment_strata <- append(list(...), compartments)
  if (length(compartment_strata) < 2L)
    stop("At least two vectors of strata are needed.", call. = FALSE)
  for (s in compartment_strata)
    if (is.null(names(s)) || any(names(s) == ""))
      stop("Every vector of strata must be named, e.g. c(HTD = \"1\", NHTD = \"2\").",
           call. = FALSE)

  composite_stratum_names <- apply(expand.grid(lapply(compartment_strata, names)), 1,
                                   function(x) paste(x, collapse = name_sep))
  if (!length(code_pattern))
    return(structure(apply(expand.grid(compartment_strata), 1,
                           function(x) paste(x, collapse = code_sep)),
                     names = composite_stratum_names))

  composite_grid <- as.data.frame(expand.grid(compartment_strata))
  colnames(composite_grid) <- seq_len(ncol(composite_grid))

  m <- regmatches(code_pattern, gregexpr("\\{[^{}]*\\}", code_pattern))[[1L]]
  vars <- substr(m, 2L, nchar(m) - 1L)
  if (length(vars) != length(compartment_strata) ||
      anyNA(suppressWarnings(as.numeric(vars))))
    stop("Ill-formed pattern!", call. = FALSE)

  stratum_text <- .fill_pattern(code_pattern, composite_grid, what = "code_pattern")
  names(stratum_text) <- composite_stratum_names
  stratum_text
}

CS <- composite_strata
