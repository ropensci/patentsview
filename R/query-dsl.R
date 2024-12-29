# Design adapted from http://adv-r.had.co.nz/dsl.html

#' @noRd
lapply2 <- function(...) sapply(..., USE.NAMES = TRUE, simplify = FALSE)

#' @noRd
create_one_fun <- function(field, value, fun) {
  k <- list(value)
  names(k) <- field
  z <- list(k)
  names(z) <- paste0("_", fun)
  z
}

#' @noRd
create_key_fun <- function(fun) {
  force(fun)
  function(...) {
    value_p <- list(...)
    field <- names(value_p)
    value <- unlist(value_p)
    names(value) <- NULL
    if (length(value) > 1) {
      z <- lapply(
        value, function(value)
          create_one_fun(field = field, value = value, fun = fun)
      )
      z <- list(`_or` = z)
    } else {
      z <- create_one_fun(field = field, value = value, fun = fun)
    }
    structure(z, class = c(class(z), "pv_query"))
  }
}

#' @noRd
create_array_fun <- function(fun) {
  force(fun)
  function(...) {
    k <- list(...)
    z <- list(k)
    names(z) <- paste0("_", fun)
    structure(z, class = c(class(z), "pv_query"))
  }
}

#' @noRd
create_not_fun <- function(fun) {
  force(fun)
  function(...) {
    k <- list(...)
    names(k) <- paste0("_", fun)
    structure(k, class = c(class(k), "pv_query"))
  }
}

#' @noRd
create_in_range_fun <- function(fun) {
  force(fun)
  function(...) {
    value_p <- list(...)
    field <- names(value_p)
    value <- unlist(value_p)
    names(value) <- NULL

    # throw an error if the length isn't two
    asrt(length(value) == 2, fun, " expects a range of exactly two arguments")

    low <- create_one_fun(field = field, value = value[1], fun = "gte")
    high <- create_one_fun(field = field, value = value[2], fun = "lte")
    z <- list(`_and` = list(low, high))

    structure(z, class = c(class(z), "pv_query"))
  }
}

#' List of query functions
#'
#' A list of functions that make it easy to write PatentsView queries. See the
#' details section below for a list of the 15 functions, as well as the
#' \href{../articles/writing-queries.html}{writing queries vignette} for further details.
#'
#' @details
#'
#' \strong{1. Comparison operator functions} \cr
#'
#' There are 6 comparison operator functions that work with fields of type
#' integer, float, date, or string:
#' \itemize{
#'    \item \code{eq} - Equal to
#'    \item \code{neq} - Not equal to
#'    \item \code{gt} - Greater than
#'    \item \code{gte} - Greater than or equal to
#'    \item \code{lt} - Less than
#'    \item \code{lte} - Less than or equal to
#'  }
#'
#' There are 2 comparison operator functions that only work with fields of type
#' string:
#' \itemize{
#'    \item \code{begins} - The string begins with the value string
#'    \item \code{contains} - The string contains the value string
#'  }
#'
#' There are 3 comparison operator functions that only work with fields of type
#' fulltext:
#' \itemize{
#'    \item \code{text_all} - The text contains all the words in the value
#'    string
#'    \item \code{text_any} - The text contains any of the words in the value
#'    string
#'    \item \code{text_phrase} - The text contains the exact phrase of the value
#'    string
#'  }
#'
#' \strong{2. Array functions} \cr
#'
#' There are 2 array functions:
#' \itemize{
#'    \item \code{and} - Both members of the array must be true
#'    \item \code{or} - Only one member of the array must be true
#'  }
#'
#' \strong{3. Negation function} \cr
#'
#' There is 1 negation function:
#' \itemize{
#'    \item \code{not} - The comparison is not true
#'  }
#'
#' \strong{4. Convenience function} \cr
#'
#' There is 1 convenience function:
#' \itemize{
#'    \item \code{in_range} - Builds a <= x <= b query
#'  }
#'
#' @return An object of class \code{pv_query}. This is basically just a simple
#'   list with a print method attached to it.
#'
#' @examples
#' qry_funs$eq(patent_date = "2001-01-01")
#'
#' qry_funs$not(qry_funs$eq(patent_date = "2001-01-01"))
#'
#' qry_funs$in_range(patent_year = c(2010, 2021))
#'
#' qry_funs$in_range(patent_date = c("1976-01-01", "1983-02-28"))

#' @export
qry_funs <- c(
  lapply2(
    c(
      "eq", "neq", "gt", "gte", "lt", "lte", "begins", "contains", "text_all",
      "text_any", "text_phrase"
    ), create_key_fun
  ),
  lapply2(c("and", "or"), create_array_fun),
  lapply2("not", create_not_fun),
  lapply2("in_range", create_in_range_fun)
)

#' With qry_funs
#'
#' This function evaluates whatever code you pass to it in the environment of
#' the \code{\link{qry_funs}} list. This allows you to cut down on typing when
#' writing your queries. If you want to cut down on typing even more, you can
#' try assigning the \code{\link{qry_funs}} list into your global environment
#' with: \code{list2env(qry_funs, envir = globalenv())}.
#'
#' @param code Code to evaluate. See example.
#' @param envir Where should R look for objects present in \code{code} that
#' aren't present in \code{\link{qry_funs}}.
#'
#' @return The result of \code{code} - i.e., your query.
#'
#' @examples
#' qry_funs$and(
#'   qry_funs$gte(patent_date = "2007-01-01"),
#'   qry_funs$text_phrase(patent_abstract = c("computer program")),
#'   qry_funs$or(
#'     qry_funs$eq(inventors.inventor_name_last = "Ihaka"),
#'     qry_funs$eq(inventors.inventor_name_last = "Chris")
#'   )
#' )
#'
#' # ...With it, this becomes:
#' with_qfuns(
#'   and(
#'     gte(patent_date = "2007-01-01"),
#'     text_phrase(patent_abstract = c("computer program")),
#'     or(
#'       eq(inventors.inventor_name_last = "Ihaka"),
#'       eq(inventors.inventor_name_last = "Chris")
#'     )
#'   )
#' )
#'
#' @export
with_qfuns <- function(code, envir = parent.frame()) {
  eval(substitute(code), qry_funs, envir)
}
