# The legacy permutation bug ----------------------------------------------------
# With blocklength = 4 and nPat = 41, the 41st patient starts a new block on its
# own. With n.block_permute = 1 that block is its own permutation group of one
# ID, and legacy sample(41, 1) returns a random number in 1:41.

test_that("legacy code duplicates IDs; new code does not", {
  legacy_dup <- logical(0)
  for (s in 1:20) {
    r <- run_both(s, nPat = 41, blocklength = 4, n.block_permute = 1)
    legacy_dup <- c(legacy_dup, anyDuplicated(r$old$pat_id) > 0)
    expect_setequal(r$new$pat_id, formatC(1:41, flag = "0", width = 2))
    expect_false(anyDuplicated(r$new$RanNo) > 0)
    # everything else is unchanged
    expect_identical(r$new[-41, ], r$old[-41, ])
    expect_identical(r$new$pat_id[41], "41")
  }
  expect_true(any(legacy_dup))
})

test_that("the fix does not shift the random stream for later strata", {
  for (s in 1:10) {
    r <- run_both(s, nPat = c(41, 30), strata = c(A = "1", B = "2"),
                  blocklength = 4, n.block_permute = 1)
    expect_identical(r$new$B, r$old$B)
  }
})
