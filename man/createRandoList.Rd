\name{createRandoList}
\alias{createRandoList}
\title{Create a (stratified) permuted block randomisation list}
\description{
Creates a block randomisation list with random block lengths, optionally
stratified and with permuted patient identifiers. This is a revision of the
legacy \code{createRandoListNew.R} function: for the same seed and arguments it
returns the same list (the random numbers are drawn in the same order), but it
fixes a bug in the permutation of patient IDs, restores the caller's random
number generator settings, validates its inputs and records how the list was
made.
}
\usage{
createRandoList(nPat, arms = 2, arm_names = LETTERS[seq_len(arms)],
  strata = c(HTD = "001"), blocklength = arms * (2:3),
  blocklength_prob = rep(1/length(blocklength), length(blocklength)),
  first_patid = 1,
  patid_format = list(flag = "0", width = nchar(max(nPat + first_patid - 1))),
  n.block_permute = 0, RanNo_pattern = "{stratum}-{pat_id}", seed = NULL,
  sample_kind = c("Rounding", "Rejection"), seed_per_stratum = FALSE)
}
\arguments{
\item{nPat}{Number of patients per stratum: a single number used for every
stratum, or one number per stratum. The SOP asks for at least twice the
maximum anticipated stratum size. Strata with 0 patients return \code{NULL}.}
\item{arms}{Number of arms (at least 2).}
\item{arm_names}{Arm labels, one per arm. For a dummy list use
\code{\link{dummy_arm_names}}. If \code{NULL}, arms are called \code{Arm1},
\code{Arm2}, ...}
\item{strata}{Named vector of strata: names are the stratum names, values the
stratum codes used in the randomisation number. See \code{\link{composite_strata}}.}
\item{blocklength}{Possible block lengths; each must be a multiple of \code{arms}.}
\item{blocklength_prob}{Probability of each block length. The default (equal
probabilities) is kept for compatibility with the legacy function; the SOP
default is \code{c(0.75, 0.25)}, so pass it explicitly.}
\item{first_patid}{Patient number of the first patient in each stratum.}
\item{patid_format}{List of \code{\link{formatC}} arguments used to format
patient numbers, or \code{NULL} to keep them unformatted.}
\item{n.block_permute}{Permute patient numbers within every
\code{n.block_permute} consecutive blocks; 0 (default) means no permutation and
\code{Inf} one permutation of the whole stratum. See Details.}
\item{RanNo_pattern}{Pattern of the randomisation number using columns of the
output in braces, e.g. \code{"\{stratum\}-\{pat_id\}"}. \code{NULL} for none.}
\item{seed}{Optional seed. If given, the generator is set with
\code{set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
sample.kind = sample_kind)}, which gives the same list as calling
\code{set.seed(seed)} before the function. If \code{NULL}, a seed must already
have been set.}
\item{sample_kind}{\code{"Rounding"} (default, as in the legacy function and in
R < 3.6.0) or \code{"Rejection"} (R's current default). Both are reproducible;
use the same value for the dummy and the final list.}
\item{seed_per_stratum}{If \code{TRUE}, stratum \code{i} is generated with seed
\code{seed + i - 1}, so that changing the size of one stratum does not change the
others. Requires \code{seed}. Lists differ from the legacy function in this mode.}
}
\details{
Within each block, every arm occurs equally often (permuted block design); the
block length is drawn from \code{blocklength} with \code{blocklength_prob}. The
list is cut at \code{nPat}, so the last block of a stratum may be incomplete.

With \code{n.block_permute > 0} the patient numbers are shuffled within groups of
blocks while the order of arms stays the same. Balance at the end of each block
then holds in the order of the rows, not in the order of the patient numbers.
If patients are enrolled in increasing randomisation number, balance is only
guaranteed at the end of each group of \code{n.block_permute} blocks.

The caller's \code{sample.kind} is restored on exit, also after an error.
}
\value{
For one stratum a data frame with columns \code{pat_id}, \code{stratum_name},
\code{stratum}, \code{block_number}, \code{arm}, \code{permute.block} (only when
IDs are permuted) and \code{RanNo}; for several strata a named list of such
data frames, where the first column is called \code{pat_id.stratum}. The
attribute \code{"rando_info"} records the seed, RNG settings, R and package
versions and the design arguments.
}
\seealso{\code{\link{check_rando_list}}, \code{\link{write_rando_list}},
\code{\link{check_final_setup}}}
\examples{
x <- createRandoList(nPat = 40, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE),
                     blocklength = c(4, 6), blocklength_prob = c(0.75, 0.25),
                     seed = 20261104)
head(x)
check_rando_list(x)

# stratified
s <- composite_strata(site = c(HCMC = "1", HN = "2"), age = c(Child = "C", Adult = "A"))
y <- createRandoList(nPat = 20, strata = s, blocklength = c(4, 6),
                     blocklength_prob = c(0.75, 0.25), seed = 1)
names(y)
}
