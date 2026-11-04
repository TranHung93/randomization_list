# Helpers that put the SOP PR-BST-DM-001 rules into code ----------------------

# Arm labels that follow the dummy flag (SOP 4.1.b: dummy arms are named
# "<abbreviated treatment>_Dummy").
dummy_arm_names <- function(arm_names, dummy) {
  if (!is.logical(dummy) || length(dummy) != 1L || is.na(dummy))
    stop("`dummy` must be TRUE or FALSE.", call. = FALSE)
  if (dummy) paste0(arm_names, "_Dummy") else arm_names
}

# Stop before a final list is generated with the statistician's (dummy) seed.
check_final_setup <- function(dummy, seed, dummy_seed) {
  if (!is.logical(dummy) || length(dummy) != 1L || is.na(dummy))
    stop("`dummy` must be TRUE or FALSE.", call. = FALSE)
  if (missing(seed) || is.null(seed) || length(seed) != 1L || is.na(seed) || !.is_whole(seed))
    stop("`seed` must be a single whole number.", call. = FALSE)
  if (dummy) {
    message("DUMMY list: arm names get the suffix '_Dummy'. ",
            "The pharmacist must set DUMMY <- FALSE and replace the seed for the final list.")
    return(invisible(TRUE))
  }
  if (!missing(dummy_seed) && !is.null(dummy_seed) && isTRUE(seed == dummy_seed))
    stop("FINAL list requested but the seed is still the dummy seed. ",
         "Replace it with a new random seed (see generate_seed()).", call. = FALSE)
  if (abs(seed) < 1e6 || grepl("^(19|20)[0-9]{6}$", format(seed, scientific = FALSE)))
    warning("The final seed looks easy to guess (small number or a date). ",
            "Use a randomly generated seed, e.g. generate_seed().", call. = FALSE)
  invisible(TRUE)
}

# A 9-digit seed drawn from a fresh, time- and process-based RNG state. The
# caller's random number stream is left untouched.
generate_seed <- function() {
  genv <- globalenv()
  had_seed <- exists(".Random.seed", envir = genv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = genv, inherits = FALSE)
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = genv)
    else if (exists(".Random.seed", envir = genv, inherits = FALSE))
      rm(".Random.seed", envir = genv)
  }, add = TRUE)
  set.seed(NULL)
  as.integer(sample.int(900000000L, 1L) + 99999999L)
}

# Verify a list: unique IDs, balance within every complete block (SOP 4.1.g).
check_rando_list <- function(x) {
  dfs <- .as_df_list(x)
  problems <- character()

  all_ranno <- unlist(lapply(dfs, function(d) d$RanNo), use.names = FALSE)
  if (length(all_ranno) && anyDuplicated(all_ranno))
    problems <- c(problems, "Duplicated randomisation numbers (RanNo).")

  rows <- lapply(names(dfs), function(nm) {
    d <- dfs[[nm]]
    id <- d[[1L]]
    if (anyDuplicated(id))
      problems <<- c(problems, paste0("[", nm, "] duplicated patient IDs."))
    arm_levels <- sort(unique(d$arm))
    k <- length(arm_levels)
    blocks <- split(d$arm, d$block_number)
    balanced <- vapply(blocks, function(a) {
      tab <- table(factor(a, levels = arm_levels))
      length(a) %% k == 0 && all(tab == length(a) / k)
    }, logical(1))
    n_blocks <- length(blocks)
    if (n_blocks > 1L && !all(balanced[-n_blocks]))
      problems <<- c(problems, paste0("[", nm, "] unbalanced complete block(s): ",
                                     paste(names(blocks)[-n_blocks][!balanced[-n_blocks]],
                                           collapse = ", ")))
    arm_tab <- table(d$arm)
    data.frame(
      stratum = nm,
      n = nrow(d),
      arms = paste0(names(arm_tab), "=", as.integer(arm_tab), collapse = "; "),
      n_blocks = n_blocks,
      block_sizes = paste0(names(table(lengths(blocks)[-n_blocks])), "x",
                           as.integer(table(lengths(blocks)[-n_blocks])), collapse = "; "),
      complete_blocks_balanced = all(balanced[-n_blocks]),
      last_block_balanced = unname(balanced[n_blocks]),
      stringsAsFactors = FALSE
    )
  })
  summary <- do.call(rbind, rows)
  rownames(summary) <- NULL
  structure(list(ok = length(problems) == 0L, summary = summary, problems = problems),
            class = "rando_check")
}

print.rando_check <- function(x, ...) {
  cat(if (x$ok) "Randomisation list check: OK\n" else "Randomisation list check: PROBLEMS FOUND\n")
  for (p in x$problems) cat(" -", p, "\n")
  cat("\n")
  print(x$summary, row.names = FALSE)
  if (any(!x$summary$last_block_balanced))
    cat("\nNote: an unbalanced last block is expected when the list was cut at nPat.\n")
  invisible(x)
}

# Write the list as CSV with SOP-compliant file names, plus a log with MD5 sums.
write_rando_list <- function(x, dir, study, dummy, date = Sys.Date(),
                             forbidden_dirs = "BIOSTAT", overwrite = FALSE) {
  if (!is.logical(dummy) || length(dummy) != 1L || is.na(dummy))
    stop("`dummy` must be TRUE or FALSE.", call. = FALSE)
  if (!is.character(study) || length(study) != 1L || !nzchar(study))
    stop("`study` must be a study number or name.", call. = FALSE)
  if (!dir.exists(dir)) stop("Directory does not exist: ", dir, call. = FALSE)
  full_dir <- normalizePath(dir, winslash = "/", mustWork = TRUE)
  if (!dummy && length(forbidden_dirs) &&
      any(vapply(forbidden_dirs, grepl, logical(1), x = full_dir, ignore.case = TRUE, fixed = FALSE)))
    stop("A FINAL list must not be written to '", full_dir, "' (matches forbidden_dirs). ",
         "Write it to the secure Pharmacy folder.", call. = FALSE)

  dfs <- .as_df_list(x)
  arms <- unique(unlist(lapply(dfs, `[[`, "arm"), use.names = FALSE))
  is_dummy_arm <- grepl("dummy", arms, ignore.case = TRUE)
  if (dummy && !all(is_dummy_arm))
    stop("dummy = TRUE but some arm names do not contain 'Dummy': ",
         paste(arms[!is_dummy_arm], collapse = ", "),
         ". Use dummy_arm_names().", call. = FALSE)
  if (!dummy && any(is_dummy_arm))
    stop("dummy = FALSE but arm names contain 'Dummy'. Set the dummy flag consistently.",
         call. = FALSE)

  clean <- function(s) gsub("[^A-Za-z0-9.-]+", "-", s)
  date <- as.Date(date)
  stamp <- paste0(month.abb[as.integer(format(date, "%m"))], format(date, "%Y"))
  rver <- paste0("R", R.version$major, ".", R.version$minor)
  base <- paste(clean(study), if (dummy) "dummy" else "final", stamp, rver, sep = "_")

  files <- if (length(dfs) == 1L) paste0(base, ".csv") else
    paste0(base, "_", clean(vapply(dfs, function(d) d$stratum[1L], "")), "-",
           clean(names(dfs)), ".csv")
  paths <- file.path(full_dir, files)
  log_path <- file.path(full_dir, paste0(base, "_log.txt"))
  existing <- c(paths, log_path)[file.exists(c(paths, log_path))]
  if (length(existing) && !overwrite)
    stop("File(s) already exist: ", paste(basename(existing), collapse = ", "),
         ". Use overwrite = TRUE to replace.", call. = FALSE)

  for (i in seq_along(dfs)) utils::write.csv(dfs[[i]], paths[i], row.names = FALSE)
  md5 <- unname(tools::md5sum(paths))

  info <- attr(x, "rando_info")
  fmt <- function(v) if (is.null(v)) "NULL" else paste(format(v, scientific = FALSE), collapse = ", ")
  log <- c(
    paste("Randomisation list:", if (dummy) "DUMMY" else "FINAL"),
    paste("Study:", study),
    paste("Written:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste("R version:", R.version.string),
    paste("randolist version:", fmt(info$package_version)),
    paste("Created:", fmt(info$created)),
    paste("Seed:", fmt(info$seed), if (isTRUE(info$seed_per_stratum)) "(+ stratum index - 1)" else ""),
    paste("RNGkind:", fmt(info$rng_kind)),
    paste("Arms:", fmt(info$arm_names)),
    paste("Block lengths:", fmt(info$blocklength), "| probabilities:", fmt(info$blocklength_prob)),
    paste("n.block_permute:", fmt(info$n.block_permute)),
    "",
    "Files (MD5):",
    paste0("  ", files, "  ", md5, "  (", vapply(dfs, nrow, 1L), " rows)"),
    "",
    "Session info:",
    utils::capture.output(print(utils::sessionInfo()))
  )
  writeLines(log, log_path)
  invisible(data.frame(file = c(paths, log_path), md5 = c(md5, unname(tools::md5sum(log_path))),
                       stringsAsFactors = FALSE))
}
