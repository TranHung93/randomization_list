\name{check_rando_list}
\alias{check_rando_list}
\alias{print.rando_check}
\title{Verify a randomisation list}
\description{
Checks a list made by \code{\link{createRandoList}}: unique randomisation
numbers and patient IDs, and balance of arms within every complete block. It
supports the pharmacist's verification of the final list (SOP 4.1.g).
}
\usage{
check_rando_list(x)

\method{print}{rando_check}(x, ...)
}
\arguments{
\item{x}{A data frame or list of data frames from \code{createRandoList()}; for
\code{print}, the result of \code{check_rando_list()}.}
\item{...}{Ignored.}
}
\details{
The last block of each stratum is reported separately because the list is cut
at \code{nPat} and that block may be incomplete. The summary shows the block
sizes, so it should only be shown to people allowed to see the list.
}
\value{
An object of class \code{"rando_check"}: a list with \code{ok} (logical),
\code{summary} (one row per stratum) and \code{problems} (character).
}
\examples{
x <- createRandoList(nPat = 30, seed = 1)
chk <- check_rando_list(x)
chk$ok
chk
}
