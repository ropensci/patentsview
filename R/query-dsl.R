# Design adapated from http://adv-r.had.co.nz/dsl.html

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
      z <- lapply(value, function(value)
        create_one_fun(field = field, value = value, fun = fun))
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

#' Query function list
#'
#' A list of functions that make it easy to write PatentsView queries. See the \href{https://github.com/crew102/patentsview/blob/master/vignettes/writing-queries.Rmd}{writing queries} vignette and examples below for details.
#'
#' @return An object of class \code{pv_query}. This is basically just a simple list with a print method attached to it.
#'
#' @examples
#' qry_funs$eq(patent_date = "2001-01-01")
#'
#' qry_funs$not(qry_funs$eq(patent_date = "2001-01-01"))
#' @export
qry_funs <- c(
  sapply(c("eq", "neq", "gt", "gte", "lt", "lte",
           "begins", "contains", "text_all", "text_any", "text_phrase"),
         create_key_fun, USE.NAMES = TRUE),
  sapply(c("and", "or"), create_array_fun, USE.NAMES = TRUE),
  sapply("not", create_not_fun, USE.NAMES = TRUE)
)

#' With Query Functions
#'
#' This function evaluates whatever code you pass to it in the environment of the \code{\link{qry_funs}} list. This allows you to cut down on typing when writing your queries.
#'
#' @param code Code to evaluate. See example.
#'
#' @return The result of \code{code} - i.e., your query.
#'
#' @examples
#' # Without with_qfuns, we have to do:
#' qry_funs$and(
#'   qry_funs$gte(patent_date = "2007-01-01"),
#'   qry_funs$text_phrase(patent_abstract = c("computer program")),
#'   qry_funs$or(
#'     qry_funs$eq(inventor_last_name = "ihaka"),
#'     qry_funs$eq(inventor_first_name = "chris")
#'   )
#' )
#'
#' #...With it, this becomes:
#' with_qfuns(
#'  and(
#'    gte(patent_date = "2007-01-01"),
#'    text_phrase(patent_abstract = c("computer program")),
#'    or(
#'      eq(inventor_last_name = "ihaka"),
#'      eq(inventor_first_name = "chris")
#'    )
#'  )
#' )
#' @export
with_qfuns <- function(code) eval(substitute(code), qry_funs)