\name{composite_strata}
\alias{composite_strata}
\alias{CS}
\title{Combine vectors of strata into composite strata}
\description{
Crosses several named vectors of strata into one named vector of composite
strata, for use as the \code{strata} argument of \code{\link{createRandoList}}.
Unchanged from the legacy function.
}
\usage{
composite_strata(..., compartments = list(), code_sep = "-",
  code_pattern = NULL, name_sep = ".")

CS(..., compartments = list(), code_sep = "-", code_pattern = NULL,
  name_sep = ".")
}
\arguments{
\item{...}{Named vectors of strata, \code{c("name" = "code")}, e.g.
\code{c(HTD = "001", NHTD = "010")}.}
\item{compartments}{A list of further vectors of strata.}
\item{code_sep}{Separator between stratum codes (ignored if \code{code_pattern} is given).}
\item{code_pattern}{Pattern of the composite code, where \code{\{1\}},
\code{\{2\}}, ... refer to the vectors in the order given, e.g. \code{"\{2\}\{1\}"}.}
\item{name_sep}{Separator between stratum names.}
}
\value{A named character vector of composite stratum codes.}
\examples{
composite_strata(site = c(HTD = "1", NHTD = "2"), sev = c(Mild = "A", Severe = "B"))
composite_strata(c(HTD = "1", NHTD = "2"), c(Mild = "A", Severe = "B"),
                 code_pattern = "{2}{1}")
}
