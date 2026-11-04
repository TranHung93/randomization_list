# Creating a reproducible, blinded randomisation list

This guide shows how to make a randomisation list with **randolist**,
following the OUCRU SOP *PR-BST-DM-001 Creating Randomisation Lists*
(v008). The package is a revision of the legacy `createRandoListNew.R`:
for the same seed and settings it gives **the same list**, so existing
studies can switch without their lists changing.

``` r

library(randolist)
```

## Who does what

The SOP keeps the trial statistician blinded by splitting the work:

| Step | Who | What |
|----|----|----|
| 4.1.b | Statistician (RA) | Writes the code and makes a **dummy** list (seed known, arms named `*_Dummy`). |
| 4.1.c | Head of Biostatistics | Reviews and approves the code. |
| 4.1.e–f | Pharmacist | Sets the dummy flag to `FALSE`, replaces the seed with a new random seed, runs the code. |
| 4.1.g | Pharmacist | Checks the final list (e.g. balance within blocks) and stores it in the secure Pharmacy folder. |

Only the seed and the dummy flag differ between the dummy and the final
code. Everything below is designed so that this switch cannot go wrong
silently.

## 1. The statistician’s dummy code

Put these settings at the very top of the study script. `DUMMY` controls
the arm names and the output file names;
[`check_final_setup()`](https://tranhung93.github.io/randomization_list/reference/check_final_setup.md)
stops the final run if the seed was not changed.

``` r

DUMMY      <- TRUE        # pharmacist: set to FALSE
DUMMY_SEED <- 20261104    # seed of the dummy list (known to the statistician)
SEED       <- DUMMY_SEED  # pharmacist: replace with generate_seed() output

check_final_setup(dummy = DUMMY, seed = SEED, dummy_seed = DUMMY_SEED)
#> DUMMY list: arm names get the suffix '_Dummy'. The pharmacist must set DUMMY <- FALSE and replace the seed for the final list.
arm_names <- dummy_arm_names(c("Dex", "Pla"), dummy = DUMMY)
arm_names
#> [1] "Dex_Dummy" "Pla_Dummy"
```

Now generate the list. Use the SOP block lengths explicitly (4 and 6
with probabilities 0.75 and 0.25 for two arms) and make the list at
least twice as long as the largest anticipated stratum.

``` r

rl <- createRandoList(
  nPat             = 200,          # 100 anticipated patients x 2
  arms             = 2,
  arm_names        = arm_names,
  strata           = c(HTD = "001"),
  blocklength      = c(4, 6),
  blocklength_prob = c(0.75, 0.25),
  seed             = SEED
)
head(rl, 8)
#>   pat_id stratum_name stratum block_number       arm   RanNo
#> 1    001          HTD     001            1 Dex_Dummy 001-001
#> 2    002          HTD     001            1 Pla_Dummy 001-002
#> 3    003          HTD     001            1 Pla_Dummy 001-003
#> 4    004          HTD     001            1 Pla_Dummy 001-004
#> 5    005          HTD     001            1 Dex_Dummy 001-005
#> 6    006          HTD     001            1 Dex_Dummy 001-006
#> 7    007          HTD     001            2 Dex_Dummy 001-007
#> 8    008          HTD     001            2 Pla_Dummy 001-008
```

Passing `seed` inside the call is the same as calling `set.seed(SEED)`
just before it, but makes it impossible to forget. The function also
remembers how the list was made:

``` r

str(attr(rl, "rando_info")[c("seed", "rng_kind", "R_version", "blocklength_prob")])
#> List of 4
#>  $ seed            : num 20261104
#>  $ rng_kind        : chr [1:3] "Mersenne-Twister" "Inversion" "Rounding"
#>  $ R_version       : chr "R version 4.6.2 (2026-10-29)"
#>  $ blocklength_prob: num [1:2] 0.75 0.25
```

## 2. Check the list

[`check_rando_list()`](https://tranhung93.github.io/randomization_list/reference/check_rando_list.md)
confirms that randomisation numbers are unique and that every complete
block is balanced. The last block may be incomplete because the list is
cut at `nPat`.

``` r

check_rando_list(rl)
#> Randomisation list check: OK
#> 
#>  stratum   n                         arms n_blocks block_sizes
#>      HTD 200 Dex_Dummy=100; Pla_Dummy=100       44  4x32; 6x11
#>  complete_blocks_balanced last_block_balanced
#>                      TRUE                TRUE
```

## 3. Write it with SOP file names

[`write_rando_list()`](https://tranhung93.github.io/randomization_list/reference/write_rando_list.md)
builds the file name from the study, the dummy flag, the MonthYear and
the R version (SOP 4.1.b), and writes a log with the MD5 sum of each
file and the session information.

``` r

out_dir <- file.path(tempdir(), "24EI_Nov2026")   # in practice: the study subfolder
dir.create(out_dir, showWarnings = FALSE)
files <- write_rando_list(rl, dir = out_dir, study = "24EI", dummy = DUMMY,
                          overwrite = TRUE)
basename(files$file)
#> [1] "24EI_dummy_Nov2026_R4.6.2.csv"     "24EI_dummy_Nov2026_R4.6.2_log.txt"
```

It refuses combinations that would break blinding:

``` r

# arm names say "Dummy" but the flag says final
write_rando_list(rl, dir = out_dir, study = "24EI", dummy = FALSE)
#> Error:
#> ! dummy = FALSE but arm names contain 'Dummy'. Set the dummy flag consistently.

# a final list may not go to a Biostatistics folder
biostat <- file.path(tempdir(), "BIOSTATISTICS")
dir.create(biostat, showWarnings = FALSE)
final_like <- createRandoList(20, arm_names = c("Dex", "Pla"), seed = 583920175)
write_rando_list(final_like, dir = biostat, study = "24EI", dummy = FALSE)
#> Error:
#> ! A FINAL list must not be written to '/tmp/RtmpiLSr5f/BIOSTATISTICS' (matches forbidden_dirs). Write it to the secure Pharmacy folder.
```

## 4. What the pharmacist changes

The pharmacist receives the approved script and changes **only** the
three lines at the top (and the output folder):

``` r

DUMMY      <- FALSE
DUMMY_SEED <- 20261104          # leave as is
SEED       <- 583920175         # from generate_seed(), not a memorable number
out_dir    <- "<secure Pharmacy folder>"
```

Get the new seed once with:

``` r

generate_seed()
#> [1] 721151189
```

Then run the script in a clean session so no copy of the list is left in
a workspace file: `Rscript --vanilla 24EI_randolist.R`. If the seed was
not changed, the script stops:

``` r

check_final_setup(dummy = FALSE, seed = 20261104, dummy_seed = 20261104)
#> Error:
#> ! FINAL list requested but the seed is still the dummy seed. Replace it with a new random seed (see generate_seed()).
```

Keep the final code, CSV, log and PDF together in the Pharmacy folder.
The log contains the seed, so it must not be copied to the Biostatistics
folder. When making the PDF for pharmacy procedures, leave out the
`block_number` and `permute.block` columns: they reveal the block
structure.

A template script with all of this is installed with the package:

``` r

file.copy(system.file("templates", "rando_list_template.R", package = "randolist"),
          "24EI_randolist.R")
```

## Stratified randomisation

Combine strata with
[`composite_strata()`](https://tranhung93.github.io/randomization_list/reference/composite_strata.md).
Each stratum gets its own blocks; the stratum code is part of the
randomisation number.

``` r

strata <- composite_strata(site = c(HCMC = "1", HN = "2"),
                           age  = c(Child = "C", Adult = "A"))
strata
#> HCMC.Child   HN.Child HCMC.Adult   HN.Adult 
#>      "1-C"      "2-C"      "1-A"      "2-A"

srl <- createRandoList(nPat = c(60, 40, 80, 40), strata = strata,
                       arm_names = arm_names, blocklength = c(4, 6),
                       blocklength_prob = c(0.75, 0.25), seed = SEED)
names(srl)
#> [1] "HCMC.Child" "HN.Child"   "HCMC.Adult" "HN.Adult"
head(srl$HCMC.Child, 4)
#>   pat_id.stratum stratum_name stratum block_number       arm  RanNo
#> 1             01   HCMC.Child     1-C            1 Dex_Dummy 1-C-01
#> 2             02   HCMC.Child     1-C            1 Pla_Dummy 1-C-02
#> 3             03   HCMC.Child     1-C            1 Pla_Dummy 1-C-03
#> 4             04   HCMC.Child     1-C            1 Pla_Dummy 1-C-04
```

By default the strata are generated one after another from a single
random stream (as in the legacy code), so changing the size of one
stratum changes the strata after it. If a stratum may need to be
extended later, use `seed_per_stratum = TRUE`: stratum *i* then uses
seed `SEED + i - 1` and the strata no longer depend on each other.

``` r

a <- createRandoList(c(20, 30), strata = c(A = "1", B = "2"), seed = SEED,
                     seed_per_stratum = TRUE, patid_format = list(width = 3, flag = "0"))
b <- createRandoList(c(50, 30), strata = c(A = "1", B = "2"), seed = SEED,
                     seed_per_stratum = TRUE, patid_format = list(width = 3, flag = "0"))
identical(a$B, b$B)
#> [1] TRUE
```

## Permuting patient numbers

`n.block_permute` shuffles the patient numbers within every *n* blocks,
so the numbers on the packs do not follow the allocation order. Be clear
about which order patients are enrolled in:

- if patients receive the **next row** of the list, balance holds at the
  end of every block, as usual;
- if patients receive the **next randomisation number**, the shuffled
  numbers define the sequence and balance is only guaranteed at the end
  of each group of `n.block_permute` blocks (with `Inf`, only at the end
  of the stratum).

``` r

p <- createRandoList(24, arm_names = arm_names, blocklength = 4,
                     n.block_permute = 2, seed = SEED)
p[, c("pat_id", "block_number", "permute.block", "arm", "RanNo")]
#>    pat_id block_number permute.block       arm  RanNo
#> 1      07            1             1 Pla_Dummy 001-07
#> 2      06            1             1 Pla_Dummy 001-06
#> 3      03            1             1 Dex_Dummy 001-03
#> 4      04            1             1 Dex_Dummy 001-04
#> 5      02            2             1 Pla_Dummy 001-02
#> 6      01            2             1 Dex_Dummy 001-01
#> 7      05            2             1 Pla_Dummy 001-05
#> 8      08            2             1 Dex_Dummy 001-08
#> 9      16            3             2 Dex_Dummy 001-16
#> 10     11            3             2 Pla_Dummy 001-11
#> 11     12            3             2 Dex_Dummy 001-12
#> 12     14            3             2 Pla_Dummy 001-14
#> 13     10            4             2 Pla_Dummy 001-10
#> 14     15            4             2 Pla_Dummy 001-15
#> 15     13            4             2 Dex_Dummy 001-13
#> 16     09            4             2 Dex_Dummy 001-09
#> 17     17            5             3 Dex_Dummy 001-17
#> 18     23            5             3 Pla_Dummy 001-23
#> 19     24            5             3 Dex_Dummy 001-24
#> 20     20            5             3 Pla_Dummy 001-20
#> 21     22            6             3 Pla_Dummy 001-22
#> 22     21            6             3 Dex_Dummy 001-21
#> 23     18            6             3 Pla_Dummy 001-18
#> 24     19            6             3 Dex_Dummy 001-19
```

## Reproducibility checklist

- Copy the package version (or the function file) used into the study
  folder; the log records `randolist` and R versions.
- Set the seed in the call (`seed =`) and keep `sample_kind` the same
  for the dummy and the final list. The default `"Rounding"` matches the
  legacy code; `"Rejection"` is R’s current default and equally
  reproducible.
- Re-running the final code must give the same MD5 sum as in the log.
- The function restores your random number settings when it finishes, so
  code that runs after it is not affected.

## Differences from the legacy `createRandoListNew.R`

Same seed + same arguments give the same list, with these exceptions,
which are all deliberate:

- **Two bug fixes**, both only when patient numbers are permuted
  (`n.block_permute > 0`):
  - the legacy code could give a wrong or duplicated patient number when
    the last permutation group held a single patient (`sample(41, 1)`
    samples from `1:41`). The new code keeps the correct number; all
    other rows and the following strata are unchanged;
  - when all permutation groups had the same size, the legacy code
    stopped with “pat_id not found”. The new code works.
- Lists whose randomisation numbers would not be unique are refused.
- Strata with fewer patients than arms (or none) are allowed.
- The caller’s `sample.kind` is restored instead of being reset to
  `"default"`.

The package tests run the legacy file side by side with the new code
over many seeds and settings to confirm this.
