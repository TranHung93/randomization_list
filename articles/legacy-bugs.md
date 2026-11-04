# Where the legacy code goes wrong, and how randolist fixes it

This article runs the legacy `createRandoListNew.R` (kept unchanged in
the package) next to the new
[`createRandoList()`](https://tranhung93.github.io/randomization_list/reference/createRandoList.md)
and shows, case by case, where the old code gives a wrong list, stops,
or quietly leaves something behind, and what the new code does instead.
All output on this page is produced by running the code.

In every case without a bug, both functions give **identical** lists for
the same seed; see the main guide and the package tests.

``` r

library(randolist)

# Load the legacy function into its own environment
legacy <- new.env()
sys.source(system.file("legacy", "createRandoListNew.R", package = "randolist"),
           envir = legacy)
old_createRandoList <- function(...) suppressMessages(legacy$createRandoList(...))
```

## Summary

| \# | Situation | Legacy code | New code |
|----|----|----|----|
| 1 | Permuted IDs, last group has one patient | Wrong ID, often **duplicated** | Correct ID |
| 2 | Permuted IDs, all groups the same size | **Stops** (“pat_id not found”) | Works |
| 3 | More arms than arm names | **Silent `NA` arms** | Error |
| 4 | Randomisation number without the stratum code | **Silent duplicate numbers** | Error |
| 5 | A stratum with few (or no) patients | Stops | Works |
| 6 | No seed set | Runs; list cannot be reproduced | Error |
| 7 | You had set `sample.kind` yourself | **Reset** to `"default"` afterwards | Restored |
| 8 | Error during generation | `sample.kind` left at `"Rounding"` | Restored |

Cases 1 and 2 only matter when patient numbers are permuted
(`n.block_permute > 0`); lists made without permutation are not
affected.

## 1. Duplicated patient IDs when permuting

With `n.block_permute = 1` the patient numbers are shuffled within each
block. If the list is cut at `nPat` so that the last block holds a
single patient, that patient forms a permutation group of one. The
legacy code shuffles it with `sample(x)`, and for a single number `x`
R’s `sample(x)` draws from `1:x`:

``` r

set.seed(1)
sample(41)[1:5]   # not "41": a permutation of 1:41
#> [1]  4 39  1 34 23
```

With block length 4 and 41 patients, patient 41 is alone in the last
block:

``` r

# first seed for which the legacy list has a duplicated ID
has_dup <- function(s) {
  set.seed(s)
  anyDuplicated(old_createRandoList(41, blocklength = 4, n.block_permute = 1)$pat_id) > 0
}
seed <- Filter(has_dup, 1:50)[1]
seed
#> [1] 1

set.seed(seed)
old <- old_createRandoList(41, blocklength = 4, n.block_permute = 1)
new <- createRandoList(41, blocklength = 4, n.block_permute = 1, seed = seed)
attr(new, "rando_info") <- NULL   # drop the generation record for the comparison

tail(old[, c("pat_id", "block_number", "permute.block", "arm", "RanNo")], 3)
#>    pat_id block_number permute.block arm  RanNo
#> 39     37           10            10   B 001-37
#> 40     40           10            10   A 001-40
#> 41     32           11            11   B 001-32
old$pat_id[duplicated(old$pat_id)]                            # used twice
#> [1] "32"
setdiff(formatC(1:41, flag = "0", width = 2), old$pat_id)    # never used
#> [1] "41"
```

Two patients would receive the same randomisation number, and one number
is missing from the list. The new code keeps the correct ID; every other
row is the same as the legacy list:

``` r

tail(new[, c("pat_id", "block_number", "permute.block", "arm", "RanNo")], 3)
#>    pat_id block_number permute.block arm  RanNo
#> 39     37           10            10   B 001-37
#> 40     40           10            10   A 001-40
#> 41     41           11            11   B 001-41
anyDuplicated(new$pat_id)
#> [1] 0
identical(new[-41, ], old[-41, ])
#> [1] TRUE
```

### When does this happen in practice?

A single patient ends up alone in the last block only if the earlier
blocks add up to exactly `nPat - 1`. With two arms and the SOP block
lengths 4 and 6, every block is even, so this can only happen when
`nPat` is **odd**. With three arms (blocks of 6 and 9) it can happen
whenever `nPat - 1` is a multiple of 3, which includes the round number
100. Whether it happens for a given list then depends on the seed.

Below, each design is run with 300 seeds and the outcome counted:

``` r

outcome <- function(f, seed, nPat, ...) {
  set.seed(seed)
  res <- tryCatch(f(nPat = nPat, ...), error = function(e) e)
  if (inherits(res, "error")) return("stops with error")
  if (anyDuplicated(res$pat_id)) return("duplicated IDs")
  if (!setequal(res$pat_id, formatC(1:nPat, flag = "0", width = nchar(nPat))))
    return("wrong ID")
  "correct"
}

designs <- list(
  "2 arms, blocks 4/6, nPat 100" = list(nPat = 100, arms = 2, blocklength = c(4, 6)),
  "2 arms, blocks 4/6, nPat 101" = list(nPat = 101, arms = 2, blocklength = c(4, 6)),
  "3 arms, blocks 6/9, nPat 100" = list(nPat = 100, arms = 3, blocklength = c(6, 9))
)

run_design <- function(f, d, nb) {
  vapply(1:300, function(s)
    outcome(f, s, nPat = d$nPat, arms = d$arms, blocklength = d$blocklength,
            blocklength_prob = c(0.75, 0.25), n.block_permute = nb),
    character(1))
}

levels_out <- c("correct", "wrong ID", "duplicated IDs", "stops with error")
tab <- function(f) {
  rows <- list()
  for (nm in names(designs)) for (nb in c(1, 2)) {
    res <- factor(run_design(f, designs[[nm]], nb), levels = levels_out)
    rows[[paste0(nm, ", n.block_permute = ", nb)]] <- table(res)
  }
  do.call(rbind, rows)
}

knitr::kable(tab(old_createRandoList), caption = "Legacy code (out of 300 seeds per row)")
```

|  | correct | wrong ID | duplicated IDs | stops with error |
|:---|---:|---:|---:|---:|
| 2 arms, blocks 4/6, nPat 100, n.block_permute = 1 | 300 | 0 | 0 | 0 |
| 2 arms, blocks 4/6, nPat 100, n.block_permute = 2 | 300 | 0 | 0 | 0 |
| 2 arms, blocks 4/6, nPat 101, n.block_permute = 1 | 168 | 0 | 132 | 0 |
| 2 arms, blocks 4/6, nPat 101, n.block_permute = 2 | 229 | 0 | 71 | 0 |
| 3 arms, blocks 6/9, nPat 100, n.block_permute = 1 | 169 | 0 | 131 | 0 |
| 3 arms, blocks 6/9, nPat 100, n.block_permute = 2 | 245 | 0 | 55 | 0 |

Legacy code (out of 300 seeds per row) {.table}

``` r

knitr::kable(tab(createRandoList), caption = "New code (out of 300 seeds per row)")
```

|  | correct | wrong ID | duplicated IDs | stops with error |
|:---|---:|---:|---:|---:|
| 2 arms, blocks 4/6, nPat 100, n.block_permute = 1 | 300 | 0 | 0 | 0 |
| 2 arms, blocks 4/6, nPat 100, n.block_permute = 2 | 300 | 0 | 0 | 0 |
| 2 arms, blocks 4/6, nPat 101, n.block_permute = 1 | 300 | 0 | 0 | 0 |
| 2 arms, blocks 4/6, nPat 101, n.block_permute = 2 | 300 | 0 | 0 | 0 |
| 3 arms, blocks 6/9, nPat 100, n.block_permute = 1 | 300 | 0 | 0 | 0 |
| 3 arms, blocks 6/9, nPat 100, n.block_permute = 2 | 300 | 0 | 0 | 0 |

New code (out of 300 seeds per row) {.table}

Lists made without permutation (`n.block_permute = 0`, the default) are
never affected.

## 2. The legacy code stops when all permutation groups have the same size

The legacy code collects the shuffled IDs with `unlist(sapply(...))`.
When every group has the same number of IDs,
[`sapply()`](https://rdrr.io/r/base/lapply.html) returns a matrix
instead of a list, and [`unlist()`](https://rdrr.io/r/base/unlist.html)
leaves a matrix unchanged:

``` r

groups <- list(1:4, 5:8)
x <- unlist(sapply(groups, function(g) g))
dim(x)    # still a 4 x 2 matrix
#> [1] 4 2
```

The ID column then becomes a matrix and the function fails. A fixed
block length of 4 with 16 patients and permutation within every 2 blocks
gives two groups of 8:

``` r

set.seed(1)
old_createRandoList(16, blocklength = 4, n.block_permute = 2)
#> Error in `legacy$createRandoList()`:
#> ! pat_id not found in randomisation data!
```

The new code uses [`lapply()`](https://rdrr.io/r/base/lapply.html),
which always returns a list:

``` r

new <- createRandoList(16, blocklength = 4, n.block_permute = 2, seed = 1)
new[, c("pat_id", "block_number", "permute.block", "arm", "RanNo")]
#>    pat_id block_number permute.block arm  RanNo
#> 1      06            1             1   B 001-06
#> 2      07            1             1   A 001-07
#> 3      03            1             1   B 001-03
#> 4      04            1             1   A 001-04
#> 5      05            2             1   A 001-05
#> 6      01            2             1   B 001-01
#> 7      02            2             1   A 001-02
#> 8      08            2             1   B 001-08
#> 9      11            3             2   A 001-11
#> 10     16            3             2   B 001-16
#> 11     09            3             2   A 001-09
#> 12     10            3             2   B 001-10
#> 13     12            4             2   B 001-12
#> 14     13            4             2   A 001-13
#> 15     14            4             2   A 001-14
#> 16     15            4             2   B 001-15
```

## 3. Silent `NA` arms when there are fewer names than arms

If `arms = 3` but only two names are given, the legacy code labels the
third arm `NA` without any warning:

``` r

set.seed(1)
old <- old_createRandoList(30, arms = 3, arm_names = c("Dex", "Pla"),
                           blocklength = c(6, 9), blocklength_prob = c(0.75, 0.25))
table(old$arm, useNA = "ifany")
#> 
#>  Dex  Pla <NA> 
#>   11    9   10
```

The new code checks the names first:

``` r

createRandoList(30, arms = 3, arm_names = c("Dex", "Pla"),
                blocklength = c(6, 9), blocklength_prob = c(0.75, 0.25), seed = 1)
#> Error:
#> ! `arm_names` must have length `arms` (3).
```

## 4. Duplicate randomisation numbers across strata

Patient numbers restart at 1 in every stratum. If the randomisation
number pattern leaves out `{stratum}`, the legacy code gives the same
number to patients in different strata:

``` r

set.seed(1)
old <- old_createRandoList(10, strata = c(Children = "1", Adults = "2"),
                           RanNo_pattern = "{pat_id}")
head(old$Children$RanNo, 3)
#> [1] "01" "02" "03"
head(old$Adults$RanNo, 3)
#> [1] "01" "02" "03"
```

The new code refuses to make such a list:

``` r

createRandoList(10, strata = c(Children = "1", Adults = "2"),
                RanNo_pattern = "{pat_id}", seed = 1)
#> Error:
#> ! Randomisation numbers are not unique (e.g. "01"). With several strata, include {stratum} in RanNo_pattern.
```

## 5. Strata with few or no patients

The legacy code checks `nPat > arms` again inside each stratum, so a
stratum with two patients (or none) stops the whole list:

``` r

set.seed(1)
old_createRandoList(c(2, 40), strata = c(Rare = "1", Common = "2"))
#> Error in `createRandoList()`:
#> ! sum(nPat) > arms & sum(nPat) > 0 is not TRUE
```

The new code checks the total only; an empty stratum gives `NULL`:

``` r

new <- createRandoList(c(2, 0, 40), strata = c(Rare = "1", None = "2", Common = "3"),
                       seed = 1)
new$Rare
#>   pat_id.stratum stratum_name stratum block_number arm RanNo
#> 1             01         Rare       1            1   B  1-01
#> 2             02         Rare       1            1   B  1-02
new$None
#> NULL
```

## 6. No seed: the legacy list cannot be reproduced

If no seed has been set in the session, R starts from the clock. The
legacy code runs without complaint, so the list exists but can never be
made again:

``` r

fresh <- function() if (exists(".Random.seed", envir = globalenv()))
  rm(".Random.seed", envir = globalenv())

fresh(); a <- old_createRandoList(40)
Sys.sleep(0.2)
fresh(); b <- old_createRandoList(40)
identical(a$arm, b$arm)
#> [1] FALSE
```

The new code stops instead (or takes the seed directly through
`seed =`):

``` r

fresh()
createRandoList(40)
#> Error:
#> ! No random seed has been set. Supply `seed` or call set.seed() first, otherwise the list cannot be reproduced.
```

## 7. Your random number settings are changed

The legacy code switches to the `"Rounding"` sampler and, when it
finishes, resets the sampler to `"default"`, whatever you had before.
Someone who set `RNGversion("3.5.0")` to reproduce an older analysis
silently loses that setting:

``` r

suppressWarnings(RNGversion("3.5.0"))
RNGkind()[3]
#> [1] "Rounding"
set.seed(1); invisible(old_createRandoList(20))
RNGkind()[3]          # changed behind your back
#> [1] "Rejection"
```

The new code puts back what it found:

``` r

suppressWarnings(RNGversion("3.5.0"))
invisible(createRandoList(20, seed = 1))
RNGkind()[3]
#> [1] "Rounding"
```

## 8. After an error, the sampler is left changed

If the legacy function stops part-way, the line that resets the sampler
is never reached, so `"Rounding"` stays on for the rest of the session:

``` r

suppressWarnings(RNGkind(sample.kind = "Rejection"))
set.seed(1)
old_createRandoList(20, RanNo_pattern = "{site}-{pat_id}")   # typo in the pattern
#> Error in `legacy$createRandoList()`:
#> ! site not found in randomisation data!
RNGkind()[3]
#> [1] "Rounding"
```

The new code restores the setting with
[`on.exit()`](https://rdrr.io/r/base/on.exit.html), which also runs
after an error:

``` r

suppressWarnings(RNGkind(sample.kind = "Rejection"))
createRandoList(20, RanNo_pattern = "{site}-{pat_id}", seed = 1)
#> Error:
#> ! site not found in RanNo_pattern data! Available: pat_id, stratum_name, stratum, block_number, arm
RNGkind()[3]
#> [1] "Rejection"
```

## What did not change

Apart from these cases, the new function draws the random numbers in
exactly the same order as the legacy function, so existing study scripts
give the same lists:

``` r

set.seed(2026)
old <- old_createRandoList(200, arm_names = c("Dex_Dummy", "Pla_Dummy"),
                           blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25))
new <- createRandoList(200, arm_names = c("Dex_Dummy", "Pla_Dummy"),
                       blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25),
                       seed = 2026)
attr(new, "rando_info") <- NULL
identical(new, old)
#> [1] TRUE
```
