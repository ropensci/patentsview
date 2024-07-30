#' @noRd
get_base <- function(endpoint) {
  sprintf("https://search.patentsview.org/api/v1/%s/", to_singular(endpoint))
}

#' @noRd
tojson_2 <- function(x, ...) {
  json <- jsonlite::toJSON(x, ...)
  if (!grepl("[[:alnum:]]", json, ignore.case = TRUE)) json <- ""
  json
}

#' @noRd
to_arglist <- function(fields, page, per_page, sort) {
  list(
    fields = fields,
    sort = list(as.list(sort)),
    opts = list(
      size = per_page
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
one_request <- function(method, query, base_url, arg_list, api_key, ...) {
  ua <- httr::user_agent("https://github.com/ropensci/patentsview")

  if (method == "GET") {
    get_url <- get_get_url(query, base_url, arg_list)
    resp <- httr::GET(
      get_url,
      httr::add_headers("X-Api-Key" = api_key),
      ua, ...
    )
  } else {
    body <- get_post_body(query, arg_list)
    resp <- httr::POST(
      base_url,
      httr::add_headers(
        "X-Api-Key" = api_key,
        "Content-Type" = "application/json"
      ),
      body = body,
      ua, ...
    )
  }

  # Sleep and retry on a 429 (too many requests). The Retry-After header is the
  # seconds to sleep
  if (httr::status_code(resp) == 429) {
    num_seconds <- httr::headers(resp)[["Retry-After"]]
    maybe_an_s <- if (num_seconds == "1") "" else "s"
    message(paste0(
      "The API's requests per minute limit has been reached. ",
      "Pausing for ", num_seconds, " second", maybe_an_s,
      " before continuing."
    ))
    Sys.sleep(num_seconds)

    one_request(method, query, base_url, arg_list, api_key, ...)
  } else {
    resp
  }
}

#' @noRd
request_apply <- function(ex_res, method, query, base_url, arg_list, api_key, ...) {
  matched_records <- ex_res$query_results[[1]]
  req_pages <- ceiling(matched_records / arg_list$opts$size)
  if (req_pages < 1) {
    stop2("No records matched your query...Can't download multiple pages")
  }

  tmp <- lapply(seq_len(req_pages), function(i) {
    x <- one_request(method, query, base_url, arg_list, api_key, ...)
    x <- process_resp(x)

    # now to page we need set the "after" attribute to where we left off
    # we want the value of the primary sort field
    s <- names(arg_list$sort[[1]])[[1]]
    if (arg_list$sort[[1]][[1]] == "asc") {
      index <- nrow(x$data[[1]])
    } else {
      index <- 1
    }

    arg_list$opts$after <<- x$data[[1]][[s]][[index]]

    x$data[[1]]
  })

  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' @noRd
get_default_sort <- function(endpoint) {
  default <- c("asc")
  names(default) <- get_ok_pk(endpoint)
  default
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
#' @param endpoint The web service resource you wish to search. Use
#'  \code{get_endpoints()} to list the available endpoints.
#' @param subent_cnts `r lifecycle::badge("deprecated")` Non-matched subentities
#' will always be returned under the new version of the API
#' @param mtchd_subent_only `r lifecycle::badge("deprecated")` This is always
#' FALSE in the new version of the API.
#' @param page `r lifecycle::badge("deprecated")` The page number of the results that should be returned.
#' @param per_page The number of records that should be returned per page. This
#'  value can be as high as 1,000 (e.g., \code{per_page = 1000}).
#' @param all_pages Do you want to download all possible pages of output? If
#'  \code{all_pages = TRUE}, the values of \code{page} and \code{per_page} are
#'  ignored.
#' @param sort A named character vector where the name indicates the field to
#'  sort by and the value indicates the direction of sorting (direction should
#'  be either "asc" or "desc"). For example, \code{sort = c("patent_id" =
#'  "asc")} or \cr\code{sort = c("patent_id" = "asc", "patent_date" =
#'  "desc")}. \code{sort = NULL} (the default) means do not sort the results.
#'  You must include any fields that you wish to sort by in \code{fields}.
#' @param method The HTTP method that you want to use to send the request.
#'  Possible values include "GET" or "POST". Use the POST method when
#'  your query is very long (say, over 2,000 characters in length).
#' @param error_browser `r lifecycle::badge("deprecated")`
#' @param api_key API key. See \href{https://patentsview.org/apis/keyrequest}{
#'  Here} for info on creating a key.
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
#'    the page returned to you).}
#'
#'    \item{request}{Details of the HTTP request that was sent to the server.
#'    When you set \code{all_pages = TRUE}, you will only get a sample request.
#'    In other words, you will not be given multiple requests for the multiple
#'    calls that were made to the server (one for each page of results).}
#'  }
#'
#' @examples
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
#'   fields = "patent_id",
#'   sort = c("patent_id" = "asc")
#' )
#'
#' search_pv(
#'   query = qry_funs$eq(inventor_name_last = "Crew"),
#'   endpoint = "inventors",
#'   all_pages = TRUE
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(assignee_individual_name_last = "Smith"),
#'   endpoint = "assignees"
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(inventors.inventor_name_last = "Smith"),
#'   endpoint = "patents",
#'   config = httr::timeout(40)
#' )
#' }
#'
#' @export
search_pv <- function(query,
                      fields = NULL,
                      endpoint = "patents",
                      subent_cnts = FALSE,
                      mtchd_subent_only = lifecycle::deprecated(),
                      page = lifecycle::deprecated(),
                      per_page = 1000,
                      all_pages = FALSE,
                      sort = NULL,
                      method = "GET",
                      error_browser = NULL,
                      api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                      ...) {

  validate_args(api_key, fields, endpoint, method, page, per_page, sort)
  deprecate_warn_all(error_browser, subent_cnts, mtchd_subent_only)

  if (is.list(query)) {
    check_query(query, endpoint)
    query <- jsonlite::toJSON(query, auto_unbox = TRUE)
  }

  # now for paging to work there needs to be a sort field
  if (all_pages && is.null(sort)) {
    sort <- get_default_sort(endpoint)
    # insure we'll have the value of the sort field
    if (!names(sort) %in% fields) fields <- c(fields, names(sort))
  }

  arg_list <- to_arglist(fields, page, per_page, sort)
  base_url <- get_base(endpoint)

  result <- one_request(method, query, base_url, arg_list, api_key, ...)
  result <- process_resp(result)
  if (!all_pages) return(result)

  full_data <- request_apply(result, method, query, base_url, arg_list, api_key, ...)
  result$data[[1]] <- full_data

  result
}

#' Get Linked Data
#'
#' Some of the endpoints now return HATEOAS style links to get more data. E.g.,
#' the inventors endpoint may return a link such as:
#' "https://search.patentsview.org/api/v1/inventor/252373/"
#'
#' @param url The link that was returned by the API on a previous call.
#'
#' @inherit search_pv return
#' @inheritParams search_pv
#'
#' @examples
#' \dontrun{
#'
#' retrieve_linked_data(
#'   "https://search.patentsview.org/api/v1/cpc_group/G01S7:4811/"
#'  )
#' }
#'
#' @export
retrieve_linked_data <- function(url,
                                 api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                                 ...
                                ) {

  # Don't sent the API key to any domain other than patentsview.org
  if (!grepl("^https://[^/]*\\.patentsview.org/", url)) {
    stop2("retrieve_linked_data is only for patentsview.org urls")
  }

  # Go through one_request, which handles resend on throttle errors
  # The API doesn't seem to mind ?q=&f=&o=&s= appended to the URL
  res <- one_request("GET", "", url, list(), api_key, ...)
  process_resp(res)
}
