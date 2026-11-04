# Generate a random seed for the final list

Returns a random 9-digit integer for the pharmacist to use as the seed
of the final list, instead of a memorable number. The current random
number stream of the session is not changed.

## Usage

``` r
generate_seed()
```

## Details

The number is drawn after re-initialising R's generator from the clock
and process ID. Run it once, paste the number into the final code and do
not share it. A physical source (e.g. dice) or random.org is equally
fine.

## Value

An integer between 100000000 and 999999999.

## Examples

``` r
generate_seed()
#> [1] 926679662
```
