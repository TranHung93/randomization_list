# New createRandoList() must give the same lists as the legacy code -----------

seeds <- c(1, 42, 2026, 123456, 987654321)

test_that("single stratum, default arguments: identical to legacy", {
  for (s in seeds) for (n in c(5, 57, 200)) {
    r <- run_both(s, nPat = n)
    expect_identical(r$new, r$old)
  }
})

test_that("SOP block lengths (4/6 with 0.75/0.25): identical to legacy", {
  for (s in seeds) {
    r <- run_both(s, nPat = 150, arm_names = c("Dex_Dummy", "Pla_Dummy"),
                  blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25))
    expect_identical(r$new, r$old)
  }
})

test_that("three arms, custom IDs and RanNo pattern: identical to legacy", {
  for (s in seeds) {
    r <- run_both(s, nPat = 120, arms = 3, arm_names = c("X", "Y", "Z"),
                  strata = c(Site1 = "S1"), blocklength = c(6, 9),
                  blocklength_prob = c(0.75, 0.25), first_patid = 101,
                  RanNo_pattern = "{stratum}{pat_id}/{block_number}")
    expect_identical(r$new, r$old)
  }
})

test_that("fixed block length and unformatted IDs: identical to legacy", {
  for (s in seeds) {
    r <- run_both(s, nPat = 33, blocklength = 4, patid_format = NULL)
    expect_identical(r$new, r$old)
    r <- run_both(s, nPat = 33, blocklength = 4, arm_names = NULL, RanNo_pattern = NULL)
    expect_identical(r$new, r$old)
  }
})

test_that("stratified lists (composite strata): identical to legacy", {
  strata <- composite_strata(site = c(HTD = "1", NHTD = "2"),
                             sev = c(Mild = "A", Severe = "B"))
  for (s in seeds) {
    r <- run_both(s, nPat = c(20, 35, 12, 50), strata = strata,
                  blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25))
    expect_identical(names(r$new), names(r$old))
    for (k in names(r$old)) expect_identical(r$new[[k]], r$old[[k]])

    r <- run_both(s, nPat = 40, strata = strata)
    for (k in names(r$old)) expect_identical(r$new[[k]], r$old[[k]])
  }
})

test_that("permuted patient IDs: identical to legacy (apart from the legacy bug)", {
  for (s in seeds) for (nb in c(1, 2, 3, Inf)) for (n in c(50, 97)) {
    r <- run_both(s, nPat = n, blocklength = c(4, 6),
                  blocklength_prob = c(0.75, 0.25), n.block_permute = nb)
    if (equal_size_groups(r$new)) {
      expect_s3_class(r$old, "error")   # second legacy bug, see test-bugfix-permutation.R
    } else {
      expect_same_as_legacy(r$new, r$old)
    }
  }
})

test_that("permuted IDs with strata: identical to legacy", {
  strata <- c(Kids = "K", Adults = "A", Elderly = "E")
  for (s in seeds) {
    r <- run_both(s, nPat = c(30, 61, 45), strata = strata, n.block_permute = 2)
    if (any(vapply(r$new, equal_size_groups, logical(1)))) {
      expect_s3_class(r$old, "error")   # second legacy bug
    } else {
      for (k in names(r$old)) expect_same_as_legacy(r$new[[k]], r$old[[k]])
    }
  }
})

test_that("seed argument gives the same list as set.seed() + legacy", {
  for (s in seeds) {
    set.seed(s)
    old <- suppressMessages(legacy$createRandoList(80, blocklength = c(4, 6),
                                                   blocklength_prob = c(.75, .25)))
    new <- createRandoList(80, blocklength = c(4, 6), blocklength_prob = c(.75, .25),
                           seed = s)
    expect_identical(strip_info(new), old)
  }
})

test_that("composite_strata(): identical to legacy", {
  a <- c(HTD = "1", NHTD = "2", Other = "3")
  b <- c(Mild = "A", Severe = "B")
  expect_identical(composite_strata(a, b), legacy$composite_strata(a, b))
  expect_identical(composite_strata(a, b, code_sep = ""), legacy$composite_strata(a, b, code_sep = ""))
  expect_identical(composite_strata(a, b, code_pattern = "{2}{1}"),
                   legacy$composite_strata(a, b, code_pattern = "{2}{1}"))
  expect_identical(composite_strata(a, b, code_pattern = "S{1}_{2}x"),
                   legacy$composite_strata(a, b, code_pattern = "S{1}_{2}x"))
  expect_identical(CS(compartments = list(a, b), name_sep = "/"),
                   legacy$CS(compartments = list(a, b), name_sep = "/"))
})
