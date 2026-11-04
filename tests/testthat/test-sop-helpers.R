test_that("dummy_arm_names() follows the flag", {
  expect_identical(dummy_arm_names(c("Dex", "Pla"), TRUE), c("Dex_Dummy", "Pla_Dummy"))
  expect_identical(dummy_arm_names(c("Dex", "Pla"), FALSE), c("Dex", "Pla"))
  expect_error(dummy_arm_names("Dex", NA))
})

test_that("check_final_setup() blocks the dummy seed and warns on guessable seeds", {
  expect_message(check_final_setup(TRUE, 20261104, 20261104), "DUMMY")
  expect_error(check_final_setup(FALSE, 20261104, 20261104), "dummy seed")
  expect_warning(check_final_setup(FALSE, 1234, 20261104), "easy to guess")
  expect_warning(check_final_setup(FALSE, 20250101, 20261104), "easy to guess")
  expect_silent(check_final_setup(FALSE, 583920175, 20261104))
})

test_that("generate_seed() gives a 9-digit integer and leaves the RNG stream alone", {
  s <- generate_seed()
  expect_type(s, "integer")
  expect_true(s >= 100000000 && s <= 999999999)
  set.seed(1); a <- runif(3)
  set.seed(1); generate_seed(); b <- runif(3)
  expect_identical(a, b)
})

test_that("check_rando_list() passes valid lists and catches problems", {
  x <- createRandoList(97, blocklength = c(4, 6), blocklength_prob = c(.75, .25), seed = 2)
  chk <- check_rando_list(x)
  expect_true(chk$ok)
  expect_true(chk$summary$complete_blocks_balanced)
  expect_output(print(chk), "OK")

  bad <- x
  first_block <- which(bad$block_number == 1)
  bad$arm[first_block] <- "A"
  expect_false(check_rando_list(bad)$ok)

  dup <- x
  dup$RanNo[2] <- dup$RanNo[1]
  dup$pat_id[2] <- dup$pat_id[1]
  expect_false(check_rando_list(dup)$ok)

  s <- createRandoList(c(30, 40), strata = c(A = "1", B = "2"), seed = 3)
  expect_true(check_rando_list(s)$ok)
  expect_identical(nrow(check_rando_list(s)$summary), 2L)
})

test_that("write_rando_list() uses SOP file names and writes a log", {
  dir <- file.path(tempdir(), "rl-test-dummy")
  dir.create(dir, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  x <- createRandoList(20, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE), seed = 1)
  out <- write_rando_list(x, dir, study = "24EI", dummy = TRUE, date = as.Date("2026-11-04"))
  rver <- paste0("R", R.version$major, ".", R.version$minor)
  expect_identical(basename(out$file),
                   c(paste0("24EI_dummy_Nov2026_", rver, ".csv"),
                     paste0("24EI_dummy_Nov2026_", rver, "_log.txt")))
  back <- utils::read.csv(out$file[1], colClasses = "character")
  expect_identical(back$RanNo, x$RanNo)
  log <- readLines(out$file[2])
  expect_true(any(grepl(out$md5[1], log, fixed = TRUE)))
  expect_true(any(grepl("Seed: 1", log, fixed = TRUE)))

  expect_error(write_rando_list(x, dir, "24EI", TRUE, date = as.Date("2026-11-04")), "already exist")
  expect_silent(write_rando_list(x, dir, "24EI", TRUE, date = as.Date("2026-11-04"), overwrite = TRUE))
})

test_that("write_rando_list() enforces dummy/final consistency and folders", {
  base <- file.path(tempdir(), "rl-test-guard")
  biostat <- file.path(base, "BIOSTATISTICS")
  pharm <- file.path(base, "Pharmacy")
  dir.create(biostat, recursive = TRUE, showWarnings = FALSE)
  dir.create(pharm, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(base, recursive = TRUE), add = TRUE)

  dummy <- createRandoList(20, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE), seed = 1)
  final <- createRandoList(20, arm_names = c("Dex", "Pla"), seed = 583920175)

  expect_error(write_rando_list(final, biostat, "24EI", dummy = FALSE), "must not be written")
  expect_error(write_rando_list(final, pharm, "24EI", dummy = TRUE), "do not contain 'Dummy'")
  expect_error(write_rando_list(dummy, pharm, "24EI", dummy = FALSE), "contain 'Dummy'")
  out <- write_rando_list(final, pharm, "24EI", dummy = FALSE)
  expect_true(all(file.exists(out$file)))
  expect_true(all(grepl("_final_", basename(out$file))))
})

test_that("write_rando_list() writes one file per stratum", {
  dir <- file.path(tempdir(), "rl-test-strata")
  dir.create(dir, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  st <- composite_strata(site = c(HTD = "1", NHTD = "2"), sev = c(Mild = "A", Severe = "B"))
  x <- createRandoList(16, strata = st, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE),
                       seed = 1)
  out <- write_rando_list(x, dir, "24EI", dummy = TRUE, date = as.Date("2026-11-04"))
  csv <- basename(out$file[grepl("csv$", out$file)])
  expect_length(csv, 4L)
  expect_true(all(grepl("^24EI_dummy_Nov2026_R.*_1-A-HTD\\.Mild\\.csv$|_2-A-NHTD\\.Mild\\.csv$|_1-B-HTD\\.Severe\\.csv$|_2-B-NHTD\\.Severe\\.csv$", csv)))
})
