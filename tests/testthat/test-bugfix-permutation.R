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

# Second legacy bug: when all permutation groups have the same size (here 2
# groups of 8 with blocklength = 4, nPat = 16, n.block_permute = 2), sapply()
# returns a matrix, unlist() keeps it a matrix and the legacy function fails.

test_that("legacy fails with equal-sized permutation groups; new code works", {
  for (s in 1:10) {
    r <- run_both(s, nPat = 16, blocklength = 4, n.block_permute = 2)
    expect_s3_class(r$old, "error")
    expect_setequal(r$new$pat_id, formatC(1:16, flag = "0", width = 2))
    expect_identical(r$new$permute.block, rep(c(1, 2), each = 8))
    # the arm sequence is drawn before the permutation, so it equals the
    # legacy list without permutation
    ref <- run_both(s, nPat = 16, blocklength = 4)
    expect_identical(r$new$arm, ref$old$arm)
    expect_identical(r$new$block_number, ref$old$block_number)
    # IDs are only shuffled within their own group
    expect_setequal(r$new$pat_id[1:8], formatC(1:8, flag = "0", width = 2))
  }
})
