\name{check_final_setup}
\alias{check_final_setup}
\alias{dummy_arm_names}
\title{Guard the switch from dummy to final list}
\description{
\code{check_final_setup()} stops if a final list (\code{dummy = FALSE}) would be
generated with the statistician's dummy seed, and warns if the final seed looks
easy to guess. \code{dummy_arm_names()} appends \code{"_Dummy"} to the arm
names when the dummy flag is set (SOP 4.1.b), so names and flag cannot disagree.
}
\usage{
check_final_setup(dummy, seed, dummy_seed)

dummy_arm_names(arm_names, dummy)
}
\arguments{
\item{dummy}{The dummy flag (\code{TRUE}/\code{FALSE}).}
\item{seed}{The seed that will be used.}
\item{dummy_seed}{The seed of the dummy list.}
\item{arm_names}{Abbreviated treatment names, e.g. \code{c("Dex", "Pla")}.}
}
\value{\code{check_final_setup()} returns \code{TRUE} invisibly;
\code{dummy_arm_names()} returns the arm names.}
\examples{
dummy_arm_names(c("Dex", "Pla"), dummy = TRUE)
check_final_setup(dummy = TRUE, seed = 20261104, dummy_seed = 20261104)
try(check_final_setup(dummy = FALSE, seed = 20261104, dummy_seed = 20261104))
}
