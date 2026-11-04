# Create a (stratified) permuted block randomisation list

Creates a block randomisation list with random block lengths, optionally
stratified and with permuted patient identifiers. This is a revision of
the legacy `createRandoListNew.R` function: for the same seed and
arguments it returns the same list (the random numbers are drawn in the
same order), but it fixes a bug in the permutation of patient IDs,
restores the caller's random number generator settings, validates its
inputs and records how the list was made.

## Usage

``` r
createRandoList(nPat, arms = 2, arm_names = LETTERS[seq_len(arms)],
  strata = c(HTD = "001"), blocklength = arms * (2:3),
  blocklength_prob = rep(1/length(blocklength), length(blocklength)),
  first_patid = 1,
  patid_format = list(flag = "0", width = nchar(max(nPat + first_patid - 1))),
  n.block_permute = 0, RanNo_pattern = "{stratum}-{pat_id}", seed = NULL,
  sample_kind = c("Rounding", "Rejection"), seed_per_stratum = FALSE)
```

## Arguments

- nPat:

  Number of patients per stratum: a single number used for every
  stratum, or one number per stratum. The SOP asks for at least twice
  the maximum anticipated stratum size. Strata with 0 patients return
  `NULL`.

- arms:

  Number of arms (at least 2).

- arm_names:

  Arm labels, one per arm. For a dummy list use
  [`dummy_arm_names`](https://tranhung93.github.io/randomization_list/reference/check_final_setup.md).
  If `NULL`, arms are called `Arm1`, `Arm2`, ...

- strata:

  Named vector of strata: names are the stratum names, values the
  stratum codes used in the randomisation number. See
  [`composite_strata`](https://tranhung93.github.io/randomization_list/reference/composite_strata.md).

- blocklength:

  Possible block lengths; each must be a multiple of `arms`.

- blocklength_prob:

  Probability of each block length. The default (equal probabilities) is
  kept for compatibility with the legacy function; the SOP default is
  `c(0.75, 0.25)`, so pass it explicitly.

- first_patid:

  Patient number of the first patient in each stratum.

- patid_format:

  List of [`formatC`](https://rdrr.io/r/base/formatc.html) arguments
  used to format patient numbers, or `NULL` to keep them unformatted.

- n.block_permute:

  Permute patient numbers within every `n.block_permute` consecutive
  blocks; 0 (default) means no permutation and `Inf` one permutation of
  the whole stratum. See Details.

- RanNo_pattern:

  Pattern of the randomisation number using columns of the output in
  braces, e.g. `"\{stratum\}-\{pat_id\}"`. `NULL` for none.

- seed:

  Optional seed. If given, the generator is set with
  `set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = sample_kind)`,
  which gives the same list as calling `set.seed(seed)` before the
  function. If `NULL`, a seed must already have been set.

- sample_kind:

  `"Rounding"` (default, as in the legacy function and in R \< 3.6.0) or
  `"Rejection"` (R's current default). Both are reproducible; use the
  same value for the dummy and the final list.

- seed_per_stratum:

  If `TRUE`, stratum `i` is generated with seed `seed + i - 1`, so that
  changing the size of one stratum does not change the others. Requires
  `seed`. Lists differ from the legacy function in this mode.

## Details

Within each block, every arm occurs equally often (permuted block
design); the block length is drawn from `blocklength` with
`blocklength_prob`. The list is cut at `nPat`, so the last block of a
stratum may be incomplete.

With `n.block_permute > 0` the patient numbers are shuffled within
groups of blocks while the order of arms stays the same. Balance at the
end of each block then holds in the order of the rows, not in the order
of the patient numbers. If patients are enrolled in increasing
randomisation number, balance is only guaranteed at the end of each
group of `n.block_permute` blocks.

The caller's `sample.kind` is restored on exit, also after an error.

## Value

For one stratum a data frame with columns `pat_id`, `stratum_name`,
`stratum`, `block_number`, `arm`, `permute.block` (only when IDs are
permuted) and `RanNo`; for several strata a named list of such data
frames, where the first column is called `pat_id.stratum`. The attribute
`"rando_info"` records the seed, RNG settings, R and package versions
and the design arguments.

## See also

[`check_rando_list`](https://tranhung93.github.io/randomization_list/reference/check_rando_list.md),
[`write_rando_list`](https://tranhung93.github.io/randomization_list/reference/write_rando_list.md),
[`check_final_setup`](https://tranhung93.github.io/randomization_list/reference/check_final_setup.md)

## Examples

``` r
x <- createRandoList(nPat = 40, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE),
                     blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25),
                     seed = 20261104)
head(x)
#>   pat_id stratum_name stratum block_number       arm  RanNo
#> 1     01          HTD     001            1 Dex_Dummy 001-01
#> 2     02          HTD     001            1 Pla_Dummy 001-02
#> 3     03          HTD     001            1 Pla_Dummy 001-03
#> 4     04          HTD     001            1 Pla_Dummy 001-04
#> 5     05          HTD     001            1 Dex_Dummy 001-05
#> 6     06          HTD     001            1 Dex_Dummy 001-06
check_rando_list(x)
#> Randomisation list check: OK
#> 
#>  stratum  n                       arms n_blocks block_sizes
#>      HTD 40 Dex_Dummy=20; Pla_Dummy=20        8    4x4; 6x3
#>  complete_blocks_balanced last_block_balanced
#>                      TRUE                TRUE

# stratified
s <- composite_strata(site = c(HCMC = "1", HN = "2"), age = c(Child = "C", Adult = "A"))
y <- createRandoList(nPat = 20, strata = s, blocklength = c(4, 6),
                     blocklength_prob = c(0.75, 0.25), seed = 1)
names(y)
#> [1] "HCMC.Child" "HN.Child"   "HCMC.Adult" "HN.Adult"  
```
