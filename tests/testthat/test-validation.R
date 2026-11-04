test_that("invalid inputs give clear errors", {
  expect_error(createRandoList(20, blocklength = 5, seed = 1), "not compatible")
  expect_error(createRandoList(20, arm_names = c("A", "B", "C"), seed = 1), "arm_names")
  expect_error(createRandoList(20, arm_names = c("A", "A"), seed = 1), "unique")
  expect_error(createRandoList(20, blocklength = c(4, 6), blocklength_prob = 1, seed = 1),
               "blocklength_prob")
  expect_error(createRandoList(c(10, 20), strata = c(A = "1"), seed = 1), "nPat")
  expect_error(createRandoList(2, seed = 1), "larger than")
  expect_error(createRandoList(10.5, seed = 1), "whole")
  expect_error(createRandoList(20, strata = c("1", "2"), seed = 1), "named")
  expect_error(createRandoList(20, n.block_permute = -1, seed = 1), "n.block_permute")
  expect_error(createRandoList(20, seed = 1.5), "seed")
  expect_error(createRandoList(20, seed_per_stratum = TRUE), "requires")
  expect_error(createRandoList(20, RanNo_pattern = "{stratum-{pat_id}", seed = 1), "Ill-formed")
  expect_error(createRandoList(20, RanNo_pattern = "{site}-{pat_id}", seed = 1), "not found")
})

test_that("duplicate randomisation numbers across strata are refused", {
  expect_error(createRandoList(20, strata = c(A = "1", B = "2"),
                               RanNo_pattern = "{pat_id}", seed = 1),
               "not unique")
})

test_that("small and empty strata are allowed (legacy stopped)", {
  x <- createRandoList(c(2, 0, 30), strata = c(A = "1", B = "2", C = "3"), seed = 1)
  expect_identical(nrow(x$A), 2L)
  expect_null(x$B)
  expect_identical(nrow(x$C), 30L)
  set.seed(1)
  expect_error(suppressMessages(legacy$createRandoList(c(2, 30), strata = c(A = "1", C = "3"))))
})
