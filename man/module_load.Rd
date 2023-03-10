% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/high_level.R
\name{module_load}
\alias{module_load}
\title{Loads one or more environment modules}
\usage{
module_load(...)
}
\arguments{
\item{...}{Any number of modules to load as character vectors, which will
all be concatenated together.}
}
\value{
An invisible value whose value may be changed in the future.
}
\description{
Loads one or more environment modules
}
\examples{
module_load("python")
}
\keyword{high_level}
