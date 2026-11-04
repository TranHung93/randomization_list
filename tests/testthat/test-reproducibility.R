test_that("same seed, same list; different seed, different list", {
  a <- createRandoList(100, seed = 777)
  b <- createRandoList(100, seed = 777)
  c <- createRandoList(100, seed = 778)
  expect_identical(a, b)
  expect_false(identical(a$arm, c$arm))
})

test_that("a longer list starts with the shorter list (single stratum, no permutation)", {
  short <- createRandoList(50, blocklength = c(4, 6), blocklength_prob = c(.75, .25),
                           seed = 9, patid_format = list(width = 3, flag = "0"))
  long <- createRandoList(200, blocklength = c(4, 6), blocklength_prob = c(.75, .25),
                          seed = 9, patid_format = list(width = 3, flag = "0"))
  expect_identical(as.list(strip_info(long)[1:50, ]), as.list(strip_info(short)))
})

test_that("seed_per_stratum makes strata independent of each other's size", {
  st <- c(A = "1", B = "2")
  x <- createRandoList(c(20, 30), strata = st, seed = 5, seed_per_stratum = TRUE,
                       patid_format = list(width = 3, flag = "0"))
  y <- createRandoList(c(60, 30), strata = st, seed = 5, seed_per_stratum = TRUE,
                       patid_format = list(width = 3, flag = "0"))
  expect_identical(x$B, y$B)
  expect_identical(as.list(y$A[1:20, ]), as.list(x$A))
  expect_identical(x$A$arm, createRandoList(20, strata = c(A = "1"), seed = 5)$arm)
})

test_that("Rejection sampler is reproducible too", {
  a <- createRandoList(60, seed = 3, sample_kind = "Rejection")
  b <- createRandoList(60, seed = 3, sample_kind = "Rejection")
  expect_identical(a, b)
  expect_identical(attr(a, "rando_info")$rng_kind[3], "Rejection")
})

test_that("caller's sample.kind is restored (legacy reset it to default)", {
  on.exit(suppressWarnings(RNGkind(sample.kind = "default")), add = TRUE)
  suppressWarnings(RNGkind(sample.kind = "Rounding"))
  set.seed(1)
  createRandoList(20)
  expect_identical(RNGkind()[3], "Rounding")

  suppressWarnings(RNGkind(sample.kind = "Rejection"))
  createRandoList(20, seed = 1)
  expect_identical(RNGkind()[3], "Rejection")

  expect_error(createRandoList(20, blocklength = 5))
  expect_identical(RNGkind()[3], "Rejection")
})

test_that("stops when no seed has been set", {
  genv <- globalenv()
  old <- if (exists(".Random.seed", envir = genv)) get(".Random.seed", envir = genv)
  on.exit(if (!is.null(old)) assign(".Random.seed", old, envir = genv), add = TRUE)
  if (exists(".Random.seed", envir = genv)) rm(".Random.seed", envir = genv)
  expect_error(createRandoList(20), "No random seed")
})

test_that("metadata is attached", {
  x <- createRandoList(30, seed = 11, blocklength = c(4, 6), blocklength_prob = c(.75, .25))
  info <- attr(x, "rando_info")
  expect_identical(info$seed, 11)
  expect_identical(info$rng_kind[1:3], c("Mersenne-Twister", "Inversion", "Rounding"))
  expect_identical(info$blocklength_prob, c(.75, .25))
  expect_identical(info$R_version, R.version.string)
})
