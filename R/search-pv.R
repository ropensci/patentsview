#' @noRd
get_base <- function(endpoint)
  sprintf("https://api.patentsview.org/%s/query", endpoint)

#' @noRd
tojson_2 <- function(x, ...) {
  json <- jsonlite::toJSON(x, ...)
  if (!grepl("[[:alnum:]]", json, ignore.case = TRUE)) json <- ""
  json
}

#' @noRd
to_arglist <- function(fields, subent_cnts, mtchd_subent_only,
                       page, per_page, sort) {
  list(
    fields = fields,
    sort = list(as.list(sort)),
    opts = list(
      include_subentity_total_counts = subent_cnts,
      matched_subentities_only = mtchd_subent_only,
      page = page,
      per_page = per_page
    )
  )
}

#' @noRd
get_get_url <- function(query, base_url, arg_list) {
  j <- paste0(
    base_url,
    "?q=", utils::URLencode(query, reserved = TRUE),
    "&f=", tojson_2(arg_list$fields),
    "&o=", tojson_2(arg_list$opts, auto_unbox = TRUE),
    "&s=", tojson_2(arg_list$sort, auto_unbox = TRUE)
  )
  utils::URLencode(j)
}

#' @noRd
get_post_body <- function(query, arg_list) {
  body <- paste0(
    "{",
    '"q":', query, ",",
    '"f":', tojson_2(arg_list$fields), ",",
    '"o":', tojson_2(arg_list$opts, auto_unbox = TRUE), ",",
    '"s":', tojson_2(arg_list$sort, auto_unbox = TRUE),
    "}"
  )
  gsub('(,"[fs]":)([,}])', paste0("\\1", "{}", "\\2"), body)
}

#' @noRd
one_request <- function(method, query, base_url, arg_list, ...) {
  ua <- httr::user_agent("https://github.com/ropensci/patentsview")

  if (method == "GET") {
    get_url <- get_get_url(query, base_url, arg_list)
    resp <- httr::GET(get_url, ua, ...)
  } else {
    body <- get_post_body(query, arg_list)
    resp <- httr::POST(base_url, body = body, ua, ...)
  }

  if (httr::http_error(resp)) throw_er(resp)

  process_resp(resp)
}

#' @noRd
request_apply <- function(ex_res, method, query, base_url, arg_list, ...) {

  req_pages <- ceiling(ex_res$query_results[[1]] / 10000)
  if (req_pages < 1) {
    stop(
      "No records matched your query...Can't download multiple pages",
      .call = FALSE
    )
  }

  tmp <- lapply(1:req_pages, function(i) {
    Sys.sleep(3)
    arg_list$opts$per_page <- 10000
    arg_list$opts$page <- i
    x <- one_request(method, query, base_url, arg_list, ...)
    x$data[[1]]
  })

  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' Search PatentsView
#'
#' This function makes an HTTP request to the PatentsView API for data matching
#' the user's query.
#'
#' @param query The query that the API will use to filter records. \code{query}
#'  can come in any one of the following forms:
#'  \itemize{
#'    \item A character string with valid JSON. \cr
#'    E.g., \code{'{"_gte":{"patent_date":"2007-01-04"}}'}
#'
#'    \item A list which will be converted to JSON by \code{search_pv}. \cr
#'    E.g., \code{list("_gte" = list("patent_date" = "2007-01-04"))}
#'
#'    \item An object of class \code{pv_query}, which you create by calling one
#'    of the functions found in the \code{\link{qry_funs}} list...See the
#'    \href{https://docs.ropensci.org/patentsview/articles/writing-queries.html}{writing
#'    queries vignette} for details.\cr
#'    E.g., \code{qry_funs$gte(patent_date = "2007-01-04")}
#'  }
#' @param fields A character vector of the fields that you want returned to you.
#'  A value of \code{NULL} indicates that the default fields should be
#'  returned. Acceptable fields for a given endpoint can be found at the API's
#'  online documentation (e.g., check out the field list for the
#'  \href{https://patentsview.org/apis/api-endpoints/patents}{patents
#'  endpoint}) or by viewing the \code{fieldsdf} data frame
#'  (\code{View(fieldsdf)}). You can also use \code{\link{get_fields}} to list
#'  out the fields available for a given endpoint.
#' @param endpoint The web service resource you wish to search. \code{endpoint}
#'  must be one of the following: "patents", "inventors", "assignees",
#'  "locations", "cpc_subsections", "uspc_mainclasses", or "nber_subcategories".
#' @param subent_cnts Do you want the total counts of unique subentities to be
#'  returned? This is equivalent to the \code{include_subentity_total_counts}
#'  parameter found \href{https://patentsview.org/apis/api-query-language}{here}.
#' @param mtchd_subent_only Do you want only the subentities that match your
#'  query to be returned? A value of \code{TRUE} indicates that the subentity
#'  has to meet your query's requirements in order for it to be returned, while
#'  a value of \code{FALSE} indicates that all subentity data will be returned,
#'  even those records that don't meet your query's requirements. This is
#'  equivalent to the \code{matched_subentities_only} parameter found
#'  \href{https://patentsview.org/apis/api-query-language}{here}.
#' @param page The page number of the results that should be returned.
#' @param per_page The number of records that should be returned per page. This
#'  value can be as high as 10,000 (e.g., \code{per_page = 10000}).
#' @param all_pages Do you want to download all possible pages of output? If
#'  \code{all_pages = TRUE}, the values of \code{page} and \code{per_page} are
#'  ignored.
#' @param sort A named character vector where the name indicates the field to
#'  sort by and the value indicates the direction of sorting (direction should
#'  be either "asc" or "desc"). For example, \code{sort = c("patent_number" =
#'  "asc")} or \cr\code{sort = c("patent_number" = "asc", "patent_date" =
#'  "desc")}. \code{sort = NULL} (the default) means do not sort the results.
#'  You must include any fields that you wish to sort by in \code{fields}.
#' @param method The HTTP method that you want to use to send the request.
#'  Possible values include "GET" or "POST". Use the POST method when
#'  your query is very long (say, over 2,000 characters in length).
#' @param error_browser Deprecated
#' @param ... Arguments passed along to httr's \code{\link[httr]{GET}} or
#'  \code{\link[httr]{POST}} function.
#'
#' @return A list with the following three elements:
#'  \describe{
#'    \item{data}{A list with one element - a named data frame containing the
#'    data returned by the server. Each row in the data frame corresponds to a
#'    single value for the primary entity. For example, if you search the
#'    assignees endpoint, then the data frame will be on the assignee-level,
#'    where each row corresponds to a single assignee. Fields that are not on
#'    the assignee-level would be returned in list columns.}
#'
#'    \item{query_results}{Entity counts across all pages of output (not just
#'    the page returned to you). If you set \code{subent_cnts = TRUE}, you will
#'    be returned both the counts of the primary entities and the subentities.}
#'
#'    \item{request}{Details of the HTTP request that was sent to the server.
#'    When you set \code{all_pages = TRUE}, you will only get a sample request.
#'    In other words, you will not be given multiple requests for the multiple
#'    calls that were made to the server (one for each page of results).}
#'  }
#'
#' @examples
#'
#' \dontrun{
#'
#' search_pv(query = '{"_gt":{"patent_year":2010}}')
#'
#' search_pv(
#'   query = qry_funs$gt(patent_year = 2010),
#'   fields = get_fields("patents", c("patents", "assignees"))
#' )
#'
#' search_pv(
#'   query = qry_funs$gt(patent_year = 2010),
#'   method = "POST",
#'   fields = "patent_number",
#'   sort = c("patent_number" = "asc")
#' )
#'
#' search_pv(
#'   query = qry_funs$eq(inventor_last_name = "crew"),
#'   all_pages = TRUE
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(inventor_last_name = "smith"),
#'   endpoint = "assignees"
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(inventor_last_name = "smith"),
#'   config = httr::timeout(40)
#' )
#' }
#'
#' @export
search_pv <- function(query,
                      fields = NULL,
                      endpoint = "patents",
                      subent_cnts = FALSE,
                      mtchd_subent_only = TRUE,
                      page = 1,
                      per_page = 25,
                      all_pages = FALSE,
                      sort = NULL,
                      method = "GET",
                      error_browser = NULL,
                      ...) {

  if (!is.null(error_browser))
    warning("error_browser parameter has been deprecated")

  validate_endpoint(endpoint)

  if (is.list(query)) {
    check_query(query, endpoint)
    query <- jsonlite::toJSON(query, auto_unbox = TRUE)
  }

  validate_misc_args(
    query, fields, endpoint, method, subent_cnts, mtchd_subent_only, page,
    per_page, sort
  )

  arg_list <- to_arglist(
    fields, subent_cnts, mtchd_subent_only, page, per_page, sort
  )

  base_url <- get_base(endpoint)

  res <- one_request(method, query, base_url, arg_list, ...)

  if (!all_pages) return(res)

  full_data <- request_apply(res, method, query, base_url, arg_list, ...)
  res$data[[1]] <- full_data

  res
}
