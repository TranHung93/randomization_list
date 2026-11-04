\name{generate_seed}
\alias{generate_seed}
\title{Generate a random seed for the final list}
\description{
Returns a random 9-digit integer for the pharmacist to use as the seed of the
final list, instead of a memorable number. The current random number stream of
the session is not changed.
}
\usage{
generate_seed()
}
\details{
The number is drawn after re-initialising R's generator from the clock and
process ID. Run it once, paste the number into the final code and do not share
it. A physical source (e.g. dice) or random.org is equally fine.
}
\value{An integer between 100000000 and 999999999.}
\examples{
generate_seed()
}
