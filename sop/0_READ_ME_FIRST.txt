This folder contains dummy randomization lists for all RCTs done at OUCRU since 2010. This is for biostatistics record keeping only.

Importantly, this folder does NOT contain the final list (as the statistician should be blinded to
the final list in a blinded trial) but rather a dummy list with a "wrong" random seed.

Update September 2020: https://www.rdatagen.net/post/permuted-block-randomization-using-simstudy/
refers to the package blockrand, which may be useful (it allows to print out stickers)

Update March 2021: [trinhdhk]
- In future studies, there might be request to mix up the order of randomisation numbers.
- Hence a new function for create Randomisation List allowing pat.id permutation within several blocks 
  and an extra helper function to combine different strata are now included in CreateRandolistNew.R.
  See inline documentation for more details.
- Remnants of the past are moved to .bak to avoid confusion.

