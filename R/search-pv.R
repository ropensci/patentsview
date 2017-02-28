get_base <- function(endpoint)
  sprintf("http://www.patentsview.org/api/%s/query", endpoint)

tojson_2 <- function(x, ...) {
  jsonlite::toJSON(x, ...) -> json
  if (!grepl("[:alnum:]", json, ignore.case = TRUE)) "" -> json
  json
}

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

get_get_url <- function(query, base_url, arg_list) {
  paste0(
    base_url,
    "?q=", query,
    "&f=", tojson_2(arg_list$fields),
    "&o=", tojson_2(arg_list$opts, auto_unbox = TRUE),
    "&s=", tojson_2(arg_list$sort, auto_unbox = TRUE)
  ) -> j
  utils::URLencode(j)
}

get_post_body <- function(query, arg_list) {
  paste0(
    '{',
    '"q":', query, ",",
    '"f":', tojson_2(arg_list$fields), ",",
    '"o":', tojson_2(arg_list$opts, auto_unbox = TRUE), ",",
    '"s":', tojson_2(arg_list$sort, auto_unbox = TRUE),
    '}'
  ) -> body
  gsub('(,"[fs]":)([,}])', paste0('\\1', "{}", '\\2'), body)
}

one_request <- function(method, query, base_url, arg_list, error_browser, ...) {
  httr::user_agent("https://github.com/crew102/patentsview") -> ua
  if (method == "GET") {
    get_get_url(query = query, base_url = base_url, arg_list = arg_list) -> get_url
    httr::GET(url = get_url, ua, ...) -> resp
  } else {
    get_post_body(query = query, arg_list = arg_list) -> body
    httr::POST(url = base_url, body = body, ua, ...) -> resp
  }

  if (httr::http_error(resp)) throw_er(resp = resp, error_browser = error_browser)

  process_resp(resp = resp)
}

request_apply <- function(ex_res, method, query, base_url, arg_list, error_browser, ...) {
  ceiling(ex_res$query_results[[1]] / 10000) -> req_pages
  if (req_pages < 1)
    stop("No records matched your query...Can't download multiple pages",
         .call = FALSE)
  sapply(1:req_pages, FUN = function(i) {
    arg_list$opts$per_page <- 10000
    arg_list$opts$page <- i
    one_request(method = method, query = query, base_url = base_url,
                arg_list = arg_list, error_browser = error_browser, ...) -> x
    x$data
  }) -> tmp
  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' Search PatentsView data
#'
#' @param query The query you wish to send to the API endpoint. This paramater can be any one of the following:
#'  \itemize{
#'   \item A character or JSON vector of length 1 with valid JSON syntax (e.g., \code{'{"_gte":{"patent_date":"2007-01-04"}}'}).
#'   \item A list which will be converted to JSON (e.g., \code{list("_gte" = list("patent_date" = "2007-01-04"))}).
#'   \item An object of class \code{pv_query}, which you create by calling one of the functions found in the \code{\link{qry_funs}} list (e.g., \code{qry_funs$gte(patent_date = "2007-01-04")}). See the \href{https://github.com/crew102/patentsview/blob/master/vignettes/writing-queries.Rmd}{writing queries vignette} for details.
#'  }
#' @param fields A character vector of fields that you want returned from the server. A value of \code{NULL} indicates that the default fields should be returned. Acceptable field values for a given endpoint can be found in the API's online documentation (for example, the field list for \href{http://www.patentsview.org/api/patent.html#field_list}{patents endpoint})...Note, you can use \code{\link{get_fields}} to quickly get field names for a given endpoint.
#' @param endpoint A character vector of length 1 indicating which web service resource you wish to search. \code{endpoint} must be one of the following: \code{"patents", "inventors", "assignees", "locations", "cpc_subsections", "uspc_mainclasses", "nber_subcategories"}.
#' @param subent_cnts Do you want the total counts of unique subentities to be returned to you? This is equivlient to the \code{include_subentity_total_counts} parameter found \href{http://www.patentsview.org/api/query-language.html#options_parameter}{here}.
#' @param mtchd_subent_only Do you want only the subentities that match your query to be returned to you? A value of \code{TRUE} means the subentity has to meet the query criterion in order for it to be returned, while a value of \code{FALSE} indicates that all subentity data will be returned, even those records that don't meet the query criterion. This is the \code{matched_subentities_only} parameter found \href{http://www.patentsview.org/api/query-language.html#options_parameter}{here}.
#' @param page The page number of the results that you want returned.
#' @param per_page The number of records that should be returned per page. This value can be as high as 10,000 (e.g., \code{per_page = 10000}).
#' @param all_pages Do you want to download all possible pages of output? If \code{all_pages = TRUE}, the values of \code{page} and \code{per_page} are ignored.
#' @param sort A named character vector where the name indicates the field to sort by and the value indicates the direction of sorting ("asc" or "desc"). For example, \code{sort = c("patent_number" = "asc")} or \code{sort = c("patent_number" = "asc", "patent_date" = "desc")}. \code{sort = NULL} (the default) means do not sort the results.
#' @param method A character vector of length 1 indicating the HTTP method that you want to use to send the request. Possible values include \code{"GET"} or \code{"POST"}. \strong{Use the POST method when your query is very long (say, over 2,000 characters in length)}.
#' @param error_browser The program used to view any HTML error messages sent by the API. This should be either a character vector of length 1 giving the name of the program (e.g., \code{error_browser = "chrome"}) assuming it is on your PATH, or the full path to the program (e.g., \code{error_browser = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"}) if it is not on your PATH. Alternatively, you can provide an R function to be called to invoke the error browser (e.g., \code{error_browser = rstudioapi::viewer}). Under Windows, \code{NULL} is also an allowed value for \code{error_browser} (and is the default), and implies that the file association mechanism will be used to determine which browser is used. To turn error browsing off when using Windows, set \code{error_browser = "false"}.
#' @param ... Arguments passed along to httr's \code{\link[httr]{GET}} or \code{\link[httr]{POST}} function.
#'
#' @return A list with the following three elements:
#' \describe{
#'   \item{data}{A list with one element - a data frame containing the data returned by the server. Each row in the data frame corresponds to a single primary entity. For example, if you search the assignee endpoint (assignee = primary entity), then the data frame will be on the assignee-level, where each row corresponds to a single assignee. Fields that are not on the assignee-level for this result set will be returned in a list column.}
#'   \item{query_results}{Entity counts across all pages of output (not just the page returned to you). If you set \code{subent_cnts = TRUE}, you will be returned both the counts of the primary entities as well as any subentities that would be returned by your search.}
#'   \item{request}{Details of the HTTP request that was sent to the server. When you set \code{all_pages = TRUE}, you will only get a sample request. In other words, you will not be given multiple requests for the multiple calls made to the server (one for each page of results).}
#'  }
#'
#' @examples
#'
#' search_pv(query = qry_funs$gt(patent_year = 2010))
#'
#' search_pv(query = '{"_gt":{"patent_year":2010}}',
#'           method = "POST", fields = "patent_number",
#'           sort = c("patent_number" = "asc"))
#'
#' search_pv(qry_funs$contains(inventor_last_name = "smith"),
#'           endpoint = "assignees",
#'           fields = get_fields("assignees", c("assignees", "patents")))
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
                      error_browser = getOption("browser"),
                      ...) {

  if (is.list(query)) {
    check_query(query = query, endpoint = endpoint)
    jsonlite::toJSON(query, auto_unbox = TRUE) -> query
  }

  validate_args(query = query, fields = fields, endpoint = endpoint,
                method = method, subent_cnts = subent_cnts,
                mtchd_subent_only = mtchd_subent_only, page = page,
                per_page = per_page, sort = sort)

  to_arglist(fields = fields, subent_cnts = subent_cnts,
             mtchd_subent_only = mtchd_subent_only,
             page = page, per_page = per_page, sort = sort) -> arg_list

  get_base(endpoint = endpoint) -> base_url

  one_request(method = method, query = query, base_url = base_url,
              arg_list = arg_list, error_browser = error_browser, ...) -> res

  if (!all_pages) return(res)

  request_apply(ex_res = res, method = method, query = query,
                base_url = base_url, arg_list = arg_list, ...) -> full_data
  res$data[[1]] <- full_data

  res
}