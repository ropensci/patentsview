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
  URLencode(j)
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

warn_for_get <- function(query)
  if (nchar(query) > 2000) paste0_msg("Your query is over 2,000 characters long, ",
                                      "I suggest using the POST method instead of GET.")

one_request <- function(method, query, base_url, arg_list, browser, ...) {
  httr::user_agent("https://github.com/crew102/patentsview") -> ua
  if (method == "GET") {
    get_get_url(query = query, base_url = base_url, arg_list = arg_list) -> get_url
    httr::GET(url = get_url, ua, ...) -> resp
  } else {
    get_post_body(query = query, arg_list = arg_list) -> body
    httr::POST(url = base_url, body = body, ua, ...) -> resp
  }

  if (httr::http_error(resp)) throw_er(resp = resp, browser = browser)

  process_resp(resp = resp)
}

request_apply <- function(ex_res, method, query, base_url, arg_list, browser, ...) {
  ceiling(ex_res$query_results[[1]] / 10000) -> req_pages
  if (req_pages < 1)
    stop("No records matched your query...Can't download multiple pages",
         .call = FALSE)
  sapply(1:req_pages, FUN = function(i) {
    arg_list$opts$per_page <- 10000
    arg_list$opts$page <- i
    one_request(method = method, query = query, base_url = base_url,
                arg_list = arg_list, browser = browser, ...) -> x
    x$data_results
  }) -> tmp
  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' Search PatentsView data
#'
#' @param query Either a character or JSON vector of length 1 with valid JSON query syntax or a list to be converted to JSON. See examples and/or query vignette.
#' @param fields Character vector of data fields that you want returned from the server. A value of \code{NULL} indicates that the default fields should be returned, as per the PatentsView API. See \url{http://www.patentsview.org/api/patent.html#field_list} for a list of acceptable fields from the "patents" endpoint. Field lists for the six other endpoints are available on the PatentsView website as well.
#' @param endpoint Character vector of length 1, consisting of one of the following values: \code{"patents", "inventors", "assignees", "locations", "cpc_subsections", "uspc_mainclasses", "nber_subcategories"}
#' @param subent_cnts Do you want the total counts of unique subentities to be returned to you? This is equivlient to the \code{include_subentity_total_counts} parameter found here: \url{http://www.patentsview.org/api/query-language.html#options_parameter}. See details for an explanation of subentities.
#' @param mtchd_subent_only Do you want all the subentities returned to you, even if they would be filtered by your query? This is the \code{matched_subentities_only} parameter found here: \url{http://www.patentsview.org/api/query-language.html#options_parameter}. See details for an explanation of subentities.
#' @param page The page number of the results that you want returned.
#' @param per_page The number of records that should be returned per page. This value can be as high as 10,000 (e.g., \code{per_page = 10000}).
#' @param all_pages Do you want to download all possible pages of output? If \code{all_pages = TRUE}, the values of \code{page} and \code{per_page} are ignored.
#' @param sort A named character vector where the name indicatea the field that is to be sorted by and the value indicates the direction of sorting ("asc" or "desc"). For example, \code{sort = c("patent_number" = "asc")} would be an acceptable value, as would \code{sort = c("patent_number" = "asc", "patent_date" = "desc")}. \code{sort = NULL} (the default) means do not sort the results.
#' @param method A character vector of length 1 indicating the HTTP method that you want to use to send the request. Options include \code{method = "GET"} or \code{method = "POST"}.
#' @param browser The program to be used as the HTML browser to view error messages sent by the API. This should be either a character vector of length 1 giving the name of the program (assuming it is in your PATH...e.g., \code{browser = "chrome"}) or the full path to the program (e.g., \code{browser = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"}). Alternatively, you can provide an R function to be called to invoke the browser (e.g., \code{browser = rstudioapi::viewer}). Under Windows \code{NULL} is also allowed (and is the default), and implies that the file association mechanism will be used. To turn the browser off when using Windows, set \code{browser = "false"}.
#' @param ... Arguments passed along to \code{\link[httr]{GET}} or \code{\link[httr]{POST}}.
#'
#' @return
#' @export
#'
#' @examples
search_pv <- function(query,
                      fields = NULL,
                      endpoint = "patents",
                      subent_cnts = FALSE,
                      mtchd_subent_only = FALSE,
                      page = 1,
                      per_page = 25,
                      all_pages = FALSE,
                      sort = NULL,
                      method = "GET",
                      browser = getOption("browser"),
                      ...) {

  if (is.list(query) && !is.data.frame(query))
    jsonlite::toJSON(query, auto_unbox = TRUE) -> query

  validate_args(query = query, fields = fields, endpoint = endpoint,
                method = method, subent_cnts = subent_cnts,
                mtchd_subent_only = mtchd_subent_only, page = page,
                per_page = per_page, sort = sort)

  to_arglist(fields = fields, subent_cnts = subent_cnts,
             mtchd_subent_only = mtchd_subent_only,
             page = page, per_page = per_page, sort = sort) -> arg_list

  get_base(endpoint = endpoint) -> base_url

  one_request(method = method, query = query, base_url = base_url,
              arg_list = arg_list, browser = browser, ...) -> res

  if (!all_pages) return(res)

  request_apply(ex_res = res, method = method, query = query,
                base_url = base_url, arg_list = arg_list, ...) -> full_data
  res$data_results[[1]] <- full_data

  res
}