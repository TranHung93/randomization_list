# Create a (stratified) permuted block randomisation list.
#
# Revision of createRandoList() from the legacy createRandoListNew.R
# (Marcel Wolbers, Trinh Dong Huu Khanh and the OUCRU Biostatistics Group).
# For the same seed and arguments it returns the same list as the legacy
# function: the random numbers are drawn in exactly the same order.
#
# Changes compared with the legacy version (see NEWS.md):
#  * BUG FIX: permuting patient IDs (n.block_permute > 0) could produce a wrong
#    or duplicated ID when the last permutation group held a single patient,
#    because sample(x) with a single number x samples from 1:x.
#  * BUG FIX: when all permutation groups had the same size, sapply() returned
#    a matrix (unlist() leaves it a matrix) and the function failed.
#  * The caller's sample.kind is restored on exit (also on error), instead of
#    being reset to "default".
#  * Optional `seed` (and `seed_per_stratum`) arguments; stops if no seed is set.
#  * `sample_kind` is an explicit argument (default "Rounding" = legacy).
#  * Input validation; strata with nPat <= arms (or 0) are allowed.
#  * Stops if randomisation numbers are not unique.
#  * Attaches generation metadata in attr(x, "rando_info").
createRandoList <- function(nPat,
                            arms = 2,
                            arm_names = LETTERS[seq_len(arms)],
                            strata = c(HTD = "001"),
                            blocklength = arms * (2:3),
                            blocklength_prob = rep(1 / length(blocklength), length(blocklength)),
                            first_patid = 1,
                            patid_format = list(flag = "0", width = nchar(max(nPat + first_patid - 1))),
                            n.block_permute = 0,
                            RanNo_pattern = "{stratum}-{pat_id}",
                            seed = NULL,
                            sample_kind = c("Rounding", "Rejection"),
                            seed_per_stratum = FALSE) {
  sample_kind <- match.arg(sample_kind)
  # Evaluate defaults that depend on other arguments before anything changes
  force(arm_names); force(blocklength); force(blocklength_prob); force(patid_format)

  .validate_rando_args(nPat, arms, arm_names, strata, blocklength, blocklength_prob,
                       first_patid, patid_format, n.block_permute, RanNo_pattern,
                       seed, seed_per_stratum)
  if (length(nPat) == 1L) nPat <- rep(nPat, length(strata))

  # Random number generator ---------------------------------------------------
  if (is.null(seed) && !exists(".Random.seed", envir = globalenv(), inherits = FALSE))
    stop("No random seed has been set. Supply `seed` or call set.seed() first, ",
         "otherwise the list cannot be reproduced.", call. = FALSE)
  old_sample_kind <- RNGkind()[3L]
  on.exit(suppressWarnings(RNGkind(sample.kind = old_sample_kind)), add = TRUE)
  set_rng <- function(s)
    suppressWarnings(set.seed(s, kind = "Mersenne-Twister", normal.kind = "Inversion",
                              sample.kind = sample_kind))
  if (!is.null(seed) && !seed_per_stratum) {
    set_rng(seed)
  } else {
    suppressWarnings(RNGkind(sample.kind = sample_kind))
  }
  rng_used <- RNGkind()

  # Generate each stratum in turn (same order of random draws as legacy) ------
  out <- vector("list", length(strata))
  names(out) <- names(strata)
  for (i in seq_along(strata)) {
    if (seed_per_stratum) set_rng(seed + i - 1)
    out[i] <- list(.rando_stratum(nPat[[i]], arms, arm_names, strata[i], blocklength,
                                  blocklength_prob, first_patid, patid_format,
                                  n.block_permute, RanNo_pattern))
  }

  # Uniqueness of randomisation numbers / patient IDs ---------------------------
  dfs <- Filter(Negate(is.null), out)
  if (length(RanNo_pattern)) {
    ranno <- unlist(lapply(dfs, `[[`, "RanNo"), use.names = FALSE)
    if (anyDuplicated(ranno))
      stop("Randomisation numbers are not unique (e.g. \"",
           ranno[anyDuplicated(ranno)], "\"). With several strata, include ",
           "{stratum} in RanNo_pattern.", call. = FALSE)
  } else {
    for (d in dfs) if (anyDuplicated(d$pat_id))
      stop("Patient IDs are not unique within a stratum.", call. = FALSE)
  }

  if (length(strata) == 1L) {
    res <- out[[1L]]
  } else {
    res <- lapply(out, function(d) {
      if (!is.null(d)) names(d)[1L] <- "pat_id.stratum"
      d
    })
  }

  attr(res, "rando_info") <- list(
    seed = seed,
    seed_per_stratum = seed_per_stratum,
    rng_kind = rng_used,
    R_version = R.version.string,
    package_version = tryCatch(as.character(utils::packageVersion("randolist")),
                               error = function(e) NA_character_),
    nPat = stats_setNames(nPat, names(strata)),
    strata = strata,
    arms = arms,
    arm_names = arm_names,
    blocklength = blocklength,
    blocklength_prob = blocklength_prob,
    n.block_permute = n.block_permute,
    created = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
  res
}

stats_setNames <- function(x, nm) {
  names(x) <- nm
  x
}

# One stratum. The body follows the legacy code line by line so that the random
# numbers are drawn in the same order; only the permutation step is fixed.
.rando_stratum <- function(nPat, arms, arm_names, strata, blocklength, blocklength_prob,
                           first_patid, patid_format, n.block_permute, RanNo_pattern) {
  if (nPat == 0) return(NULL)

  r.arm <- NULL # the randomized arm for each patient
  blocknumber <- NULL
  b.num <- 1

  while (length(r.arm) < nPat) {
    # current block length (randomly selected if more than one is provided)
    currBlocklength <- if (length(blocklength) > 1L)
      sample(blocklength, size = 1, prob = blocklength_prob) else blocklength
    # randomized arms for the current block
    r.block <- rep(NA, currBlocklength)
    r.blockorder <- sample(1:currBlocklength, currBlocklength)
    for (j in 1:arms) {
      elements.armj <- r.blockorder[(1 + (j - 1) * currBlocklength / arms):(j * currBlocklength / arms)]
      r.block[elements.armj] <- if (is.null(arm_names)) paste("Arm", j, sep = "") else arm_names[j]
    }
    r.arm <- c(r.arm, r.block)
    blocknumber <- c(blocknumber, rep(b.num, currBlocklength))
    b.num <- b.num + 1
  }
  r.arm <- r.arm[1:nPat]
  blocknumber <- blocknumber[1:nPat]
  pat.id <- first_patid + (0:(nPat - 1))

  # Block-wise permutation of patient IDs
  if (n.block_permute) {
    permut.block.number <- (blocknumber - 1) %/% n.block_permute + 1
    # FIX: index with sample.int() so that a group with a single ID keeps that ID.
    # For groups of 2+ IDs this is exactly what sample(x) does internally, so the
    # result (and the random number stream) is unchanged.
    pat.id <- unlist(lapply(split(pat.id, permut.block.number),
                            function(x) x[sample.int(length(x))]),
                     use.names = FALSE)
  }

  if (length(patid_format)) {
    pat.id <- do.call(formatC, append(patid_format, list(pat.id), after = 0))
  }

  dt <- data.frame(pat_id = pat.id,
                   stratum_name = names(strata),
                   stratum = unname(strata),
                   block_number = blocknumber,
                   arm = r.arm)
  if (n.block_permute) dt$permute.block <- permut.block.number
  if (length(RanNo_pattern)) dt$RanNo <- .fill_pattern(RanNo_pattern, dt, what = "RanNo_pattern")
  dt
}

.validate_rando_args <- function(nPat, arms, arm_names, strata, blocklength,
                                 blocklength_prob, first_patid, patid_format,
                                 n.block_permute, RanNo_pattern, seed,
                                 seed_per_stratum) {
  fail <- function(...) stop(..., call. = FALSE)

  if (!.is_whole(arms) || length(arms) != 1L || arms < 2)
    fail("`arms` must be a single whole number >= 2.")
  if (!is.null(arm_names)) {
    if (length(arm_names) != arms) fail("`arm_names` must have length `arms` (", arms, ").")
    if (anyNA(arm_names) || anyDuplicated(arm_names)) fail("`arm_names` must be unique and not NA.")
  }
  if (length(strata) < 1L || anyNA(strata)) fail("`strata` must be a non-empty vector without NAs.")
  if (is.null(names(strata)) || any(names(strata) == "") || anyNA(names(strata)))
    fail("`strata` must be named: c(\"stratum name\" = \"stratum code\").")
  if (anyDuplicated(names(strata)) || anyDuplicated(unname(strata)))
    fail("Stratum names and stratum codes must be unique.")
  if (!.is_whole(nPat) || any(nPat < 0))
    fail("`nPat` must contain whole numbers >= 0.")
  if (!(length(nPat) == 1L || length(nPat) == length(strata)))
    fail("`nPat` must have length 1 or length(strata) (", length(strata), ").")
  if (!(sum(nPat) > arms))
    fail("The total number of patients must be larger than `arms`.")
  if (!.is_whole(blocklength) || any(blocklength <= 0))
    fail("`blocklength` must contain positive whole numbers.")
  if (any(blocklength %% arms > 0)) fail("Block lengths and number of arms not compatible!")
  if (!is.numeric(blocklength_prob) || length(blocklength_prob) != length(blocklength) ||
      anyNA(blocklength_prob) || any(blocklength_prob < 0) || sum(blocklength_prob) <= 0)
    fail("`blocklength_prob` must be non-negative numbers, one per block length.")
  if (!.is_whole(first_patid) || length(first_patid) != 1L)
    fail("`first_patid` must be a single whole number.")
  if (!is.null(patid_format) && !is.list(patid_format))
    fail("`patid_format` must be NULL or a list of formatC() arguments.")
  if (length(n.block_permute) != 1L || !is.numeric(n.block_permute) || is.na(n.block_permute) ||
      n.block_permute < 0 || (is.finite(n.block_permute) && n.block_permute != round(n.block_permute)))
    fail("`n.block_permute` must be a single whole number >= 0, or Inf.")
  if (!is.null(RanNo_pattern) && (!is.character(RanNo_pattern) || length(RanNo_pattern) != 1L))
    fail("`RanNo_pattern` must be NULL or a single string.")
  if (!is.logical(seed_per_stratum) || length(seed_per_stratum) != 1L || is.na(seed_per_stratum))
    fail("`seed_per_stratum` must be TRUE or FALSE.")
  if (!is.null(seed)) {
    if (!.is_whole(seed) || length(seed) != 1L)
      fail("`seed` must be a single whole number.")
    upper <- seed + if (seed_per_stratum) length(strata) - 1 else 0
    if (abs(seed) > .Machine$integer.max || abs(upper) > .Machine$integer.max)
      fail("`seed` must be within +/- ", .Machine$integer.max, ".")
  } else if (seed_per_stratum) {
    fail("`seed_per_stratum = TRUE` requires `seed`.")
  }
  invisible(TRUE)
}
