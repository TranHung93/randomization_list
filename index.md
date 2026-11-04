# randolist

Reproducible, blinded block randomisation lists for clinical trials,
following the OUCRU SOP **PR-BST-DM-001 Creating Randomisation Lists**
(v008).

`randolist` is a revision of the legacy `createRandoListNew.R`. For the
same seed and settings it produces **the same list**, but it

- fixes two bugs when patient numbers are permuted (`n.block_permute`):
  one could duplicate patient numbers, the other made the function fail,
- restores your random number settings and refuses to run without a
  seed,
- validates its inputs and refuses non-unique randomisation numbers,
- adds helpers that enforce the SOP’s dummy/final switch, file naming
  and verification of the list.

Articles:

- **[Creating a reproducible, blinded randomisation
  list](https://tranhung93.github.io/randomization_list/articles/randolist.html)**:
  the SOP workflow step by step.
- **[Where the legacy code goes wrong, and how randolist fixes
  it](https://tranhung93.github.io/randomization_list/articles/legacy-bugs.html)**:
  the old and new code run side by side.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("TranHung93/randomization_list", build_vignettes = TRUE)
```

## Example

``` r

library(randolist)

DUMMY      <- TRUE         # pharmacist: FALSE
DUMMY_SEED <- 20261104
SEED       <- DUMMY_SEED   # pharmacist: generate_seed()
check_final_setup(DUMMY, SEED, DUMMY_SEED)

rl <- createRandoList(
  nPat = 200, arm_names = dummy_arm_names(c("Dex", "Pla"), DUMMY),
  blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25), seed = SEED
)
check_rando_list(rl)
write_rando_list(rl, dir = "<study folder>", study = "24EI", dummy = DUMMY)
```

A full study script template:
`system.file("templates", "rando_list_template.R", package = "randolist")`.

## Repository layout

| Path | Content |
|----|----|
| `R/` | Package code |
| `inst/legacy/createRandoListNew.R` | The original function, unchanged; reference for the tests |
| `tests/testthat/` | Tests, including side-by-side comparison with the legacy code |
| `vignettes/` | The guide |
| `sop/` | SOP PR-BST-DM-001, workshop slides, original folder README |

## Validation

GitHub Actions runs `R CMD check` on Windows, macOS and Linux (R
release, previous release and devel). The tests generate lists with the
legacy and the new code from the same seeds and require them to be
identical, apart from the documented bug fixes.
