# Verify a randomisation list

Checks a list made by
[`createRandoList`](https://tranhung93.github.io/randomization_list/reference/createRandoList.md):
unique randomisation numbers and patient IDs, and balance of arms within
every complete block. It supports the pharmacist's verification of the
final list (SOP 4.1.g).

## Usage

``` r
check_rando_list(x)

# S3 method for class 'rando_check'
print(x, ...)
```

## Arguments

- x:

  A data frame or list of data frames from
  [`createRandoList()`](https://tranhung93.github.io/randomization_list/reference/createRandoList.md);
  for `print`, the result of `check_rando_list()`.

- ...:

  Ignored.

## Details

The last block of each stratum is reported separately because the list
is cut at `nPat` and that block may be incomplete. The summary shows the
block sizes, so it should only be shown to people allowed to see the
list.

## Value

An object of class `"rando_check"`: a list with `ok` (logical),
`summary` (one row per stratum) and `problems` (character).

## Examples

``` r
x <- createRandoList(nPat = 30, seed = 1)
chk <- check_rando_list(x)
chk$ok
#> [1] TRUE
chk
#> Randomisation list check: OK
#> 
#>  stratum  n       arms n_blocks block_sizes complete_blocks_balanced
#>      HTD 30 A=14; B=16        7    4x4; 6x2                     TRUE
#>  last_block_balanced
#>                FALSE
#> 
#> Note: an unbalanced last block is expected when the list was cut at nPat.
```
