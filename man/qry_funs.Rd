% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/query-dsl.R
\docType{data}
\name{qry_funs}
\alias{qry_funs}
\title{List of query functions}
\format{
An object of class \code{list} of length 14.
}
\usage{
qry_funs
}
\value{
An object of class \code{pv_query}. This is basically just a simple
list with a print method attached to it.
}
\description{
A list of functions that make it easy to write PatentsView queries. See the
details section below for a list of the 14 functions, as well as the
\href{https://docs.ropensci.org/patentsview/articles/writing-queries.html}{writing
queries vignette} for further details.
}
\details{
\strong{1. Comparison operator functions} \cr

There are 6 comparison operator functions that work with fields of type
integer, float, date, or string:
\itemize{
\item \code{eq} - Equal to
\item \code{neq} - Not equal to
\item \code{gt} - Greater than
\item \code{gte} - Greater than or equal to
\item \code{lt} - Less than
\item \code{lte} - Less than or equal to
}

There are 2 comparison operator functions that only work with fields of type
string:
\itemize{
\item \code{begins} - The string begins with the value string
\item \code{contains} - The string contains the value string
}

There are 3 comparison operator functions that only work with fields of type
fulltext:
\itemize{
\item \code{text_all} - The text contains all the words in the value
string
\item \code{text_any} - The text contains any of the words in the value
string
\item \code{text_phrase} - The text contains the exact phrase of the value
string
}

\strong{2. Array functions} \cr

There are 2 array functions:
\itemize{
\item \code{and} - Both members of the array must be true
\item \code{or} - Only one member of the array must be true
}

\strong{3. Negation function} \cr

There is 1 negation function:
\itemize{
\item \code{not} - The comparison is not true
}
}
\examples{
qry_funs$eq(patent_date = "2001-01-01")

qry_funs$not(qry_funs$eq(patent_date = "2001-01-01"))

}
\keyword{datasets}
