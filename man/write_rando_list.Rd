\name{write_rando_list}
\alias{write_rando_list}
\title{Write a randomisation list with SOP-compliant file names}
\description{
Writes each stratum to a CSV file named
\code{<study>_<dummy|final>_<MonYYYY>_R<version>[_<code>-<stratum>].csv}
(SOP 4.1.b) and a log file with the generation settings, MD5 sums and session
information. It refuses to write a final list into a Biostatistics folder and
checks that the arm names agree with the dummy flag.
}
\usage{
write_rando_list(x, dir, study, dummy, date = Sys.Date(),
  forbidden_dirs = "BIOSTAT", overwrite = FALSE)
}
\arguments{
\item{x}{Result of \code{\link{createRandoList}}.}
\item{dir}{Existing output directory.}
\item{study}{Study number or name.}
\item{dummy}{The dummy flag: \code{TRUE} for the statistician's dummy list,
\code{FALSE} for the pharmacist's final list.}
\item{date}{Date used for the MonthYear in the file name.}
\item{forbidden_dirs}{Regular expressions; a final list is not written to a
directory whose path matches any of them (case-insensitive).}
\item{overwrite}{Replace existing files?}
}
\details{
For a dummy list all arm names must contain "Dummy"; for a final list none may.
The log contains the seed, so for the final list it must be stored with the
final code in the secure Pharmacy folder.
}
\value{Invisibly, a data frame of written files and their MD5 sums.}
\examples{
x <- createRandoList(nPat = 20, arm_names = dummy_arm_names(c("Dex", "Pla"), TRUE),
                     seed = 1)
out <- write_rando_list(x, dir = tempdir(), study = "24XX", dummy = TRUE,
                        overwrite = TRUE)
basename(out$file)
}
