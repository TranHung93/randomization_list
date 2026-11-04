# Guard the switch from dummy to final list

`check_final_setup()` stops if a final list (`dummy = FALSE`) would be
generated with the statistician's dummy seed, and warns if the final
seed looks easy to guess. `dummy_arm_names()` appends `"_Dummy"` to the
arm names when the dummy flag is set (SOP 4.1.b), so names and flag
cannot disagree.

## Usage

``` r
check_final_setup(dummy, seed, dummy_seed)

dummy_arm_names(arm_names, dummy)
```

## Arguments

- dummy:

  The dummy flag (`TRUE`/`FALSE`).

- seed:

  The seed that will be used.

- dummy_seed:

  The seed of the dummy list.

- arm_names:

  Abbreviated treatment names, e.g. `c("Dex", "Pla")`.

## Value

`check_final_setup()` returns `TRUE` invisibly; `dummy_arm_names()`
returns the arm names.

## Examples

``` r
dummy_arm_names(c("Dex", "Pla"), dummy = TRUE)
#> [1] "Dex_Dummy" "Pla_Dummy"
check_final_setup(dummy = TRUE, seed = 20261104, dummy_seed = 20261104)
#> DUMMY list: arm names get the suffix '_Dummy'. The pharmacist must set DUMMY <- FALSE and replace the seed for the final list.
try(check_final_setup(dummy = FALSE, seed = 20261104, dummy_seed = 20261104))
#> Error : FINAL list requested but the seed is still the dummy seed. Replace it with a new random seed (see generate_seed()).
```
