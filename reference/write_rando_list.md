# Write a randomisation list with SOP-compliant file names

Writes each stratum to a CSV file named
`<study>_<dummy|final>_<MonYYYY>_R<version>[_<code>-<stratum>].csv` (SOP
4.1.b) and a log file with the generation settings, MD5 sums and session
information. It refuses to write a final list into a Biostatistics
folder and checks that the arm names agree with the dummy flag.

## Usage

``` r
write_rando_list(x, dir, study, dummy, date = Sys.Date(),
  forbidden_dirs = "BIOSTAT", overwrite = FALSE)
```

## Arguments

- x:

  Result of
  [`createRandoList`](https://tranhung93.github.io/randomization_list/reference/createRandoList.md).

- dir:

  Existing output directory.

- study:

  Study number or name.

- dummy:

  The dummy flag: `TRUE` for the statistician's dummy list, `FALSE` for
  the pharmacist's final list.

- date:

  Date used for the MonthYear in the file name.

- forbidden_dirs:

  Regular expressions; a final list is not written to a directory whose
  path matches any of them (case-insensitive).

- overwrite:

  Replace existing files?

## Details

For a dummy list all arm names must contain "Dummy"; for a final list
none may. The log contains the seed, so for the final list it must be
stored with the final code in the secure Pharmacy folder.

## Value

Invisibly, a data frame of written files and their MD5 sums.

## Examples

``` r
x <- createRandoList(nPat = 20, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE),
                     seed = 1)
out <- write_rando_list(x, dir = tempdir(), study = "24XX", dummy = TRUE,
                        overwrite = TRUE)
basename(out$file)
#> [1] "24XX_dummy_Nov2026_R4.6.2.csv"     "24XX_dummy_Nov2026_R4.6.2_log.txt"
```
