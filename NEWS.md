# randolist 1.0.0

First package version. `createRandoList()` and `composite_strata()` are
revisions of the legacy `createRandoListNew.R` (last changed June 2024), which
is kept unchanged in `inst/legacy/` and used as the reference in the tests.

## Same results as the legacy code

* Same seed and arguments give the same list (random numbers are drawn in the
  same order). Verified by tests over many seeds and settings.

## Bug fixes (both only affect `n.block_permute > 0`)

* A permutation group holding a single patient (possible in the last,
  truncated block) got a random number from `1:id` instead of its own ID,
  which could duplicate patient numbers. Fixed; other rows and the following
  strata are unchanged.
* When all permutation groups had the same number of patients (e.g. fixed
  block length 4, `nPat = 16`, `n.block_permute = 2`), `sapply()` returned a
  matrix that `unlist()` left as a matrix, and the legacy function stopped with
  "pat_id not found". Fixed.

## Changes

* The caller's `sample.kind` is restored on exit, also after an error (legacy
  reset it to `"default"`).
* New `seed`, `sample_kind` and `seed_per_stratum` arguments; the function stops
  if no seed has been set.
* Input validation with clear messages; strata with `nPat <= arms` or 0 are
  allowed (legacy stopped).
* Randomisation numbers that are not unique are refused.
* Generation metadata in `attr(x, "rando_info")`.

## New helpers for the SOP

* `dummy_arm_names()`, `check_final_setup()` and `generate_seed()` for the
  dummy/final switch.
* `check_rando_list()` to verify balance within blocks and unique IDs.
* `write_rando_list()` writes SOP-compliant file names and a log with MD5 sums.
* A study script template in `inst/templates/`.
