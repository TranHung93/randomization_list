# Combine vectors of strata into composite strata

Crosses several named vectors of strata into one named vector of
composite strata, for use as the `strata` argument of
[`createRandoList`](https://tranhung93.github.io/randomization_list/reference/createRandoList.md).
Unchanged from the legacy function.

## Usage

``` r
composite_strata(..., compartments = list(), code_sep = "-",
  code_pattern = NULL, name_sep = ".")

CS(..., compartments = list(), code_sep = "-", code_pattern = NULL,
  name_sep = ".")
```

## Arguments

- ...:

  Named vectors of strata, `c("name" = "code")`, e.g.
  `c(HTD = "001", NHTD = "010")`.

- compartments:

  A list of further vectors of strata.

- code_sep:

  Separator between stratum codes (ignored if `code_pattern` is given).

- code_pattern:

  Pattern of the composite code, where `{1}`, `{2}`, ... refer to the
  vectors in the order given, e.g. `"\{2\}\{1\}"`.

- name_sep:

  Separator between stratum names.

## Value

A named character vector of composite stratum codes.

## Examples

``` r
composite_strata(site = c(HTD = "1", NHTD = "2"), sev = c(Mild = "A", Severe = "B"))
#>    HTD.Mild   NHTD.Mild  HTD.Severe NHTD.Severe 
#>       "1-A"       "2-A"       "1-B"       "2-B" 
composite_strata(c(HTD = "1", NHTD = "2"), c(Mild = "A", Severe = "B"),
                 code_pattern = "{2}{1}")
#>    HTD.Mild   NHTD.Mild  HTD.Severe NHTD.Severe 
#>        "A1"        "A2"        "B1"        "B2" 
```
