# Changelog

## randolist 1.0.0

First package version.
[`createRandoList()`](https://tranhung93.github.io/randomization_list/reference/createRandoList.md)
and
[`composite_strata()`](https://tranhung93.github.io/randomization_list/reference/composite_strata.md)
are revisions of the legacy `createRandoListNew.R` (last changed June
2024), which is kept unchanged in `inst/legacy/` and used as the
reference in the tests.

### Same results as the legacy code

- Same seed and arguments give the same list (random numbers are drawn
  in the same order). Verified by tests over many seeds and settings.

### Bug fixes (both only affect `n.block_permute > 0`)

- A permutation group holding a single patient (possible in the last,
  truncated block) got a random number from `1:id` instead of its own
  ID, which could duplicate patient numbers. Fixed; other rows and the
  following strata are unchanged.
- When all permutation groups had the same number of patients
  (e.g. fixed block length 4, `nPat = 16`, `n.block_permute = 2`),
  [`sapply()`](https://rdrr.io/r/base/lapply.html) returned a matrix
  that [`unlist()`](https://rdrr.io/r/base/unlist.html) left as a
  matrix, and the legacy function stopped with “pat_id not found”.
  Fixed.

### Changes

- The caller’s `sample.kind` is restored on exit, also after an error
  (legacy reset it to `"default"`).
- New `seed`, `sample_kind` and `seed_per_stratum` arguments; the
  function stops if no seed has been set.
- Input validation with clear messages; strata with `nPat <= arms` or 0
  are allowed (legacy stopped).
- Randomisation numbers that are not unique are refused.
- Generation metadata in `attr(x, "rando_info")`.

### Documentation

- New article “Where the legacy code goes wrong, and how randolist fixes
  it”, which runs the legacy and new code side by side for every case.
- The new function also refuses arm names that do not match `arms`
  (legacy silently produced `NA` arms).

### New helpers for the SOP

- [`dummy_arm_names()`](https://tranhung93.github.io/randomization_list/reference/check_final_setup.md),
  [`check_final_setup()`](https://tranhung93.github.io/randomization_list/reference/check_final_setup.md)
  and
  [`generate_seed()`](https://tranhung93.github.io/randomization_list/reference/generate_seed.md)
  for the dummy/final switch.
- [`check_rando_list()`](https://tranhung93.github.io/randomization_list/reference/check_rando_list.md)
  to verify balance within blocks and unique IDs.
- [`write_rando_list()`](https://tranhung93.github.io/randomization_list/reference/write_rando_list.md)
  writes SOP-compliant file names and a log with MD5 sums.
- A study script template in `inst/templates/`.
