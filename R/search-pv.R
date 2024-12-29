#' @noRd
get_base <- function(endpoint) {
  sprintf("https://search.patentsview.org/api/v1/%s/", endpoint)
}

#' @noRd
tojson_2 <- function(x, ...) {
  json <- jsonlite::toJSON(x, ...)
  if (!grepl("[[:alnum:]]", json, ignore.case = TRUE)) json <- ""
  json
}

#' @noRd
to_arglist <- function(fields, size, sort, after) {
  opts <- list(size = size)
  if (!is.null(after)) {
    opts$after <- after
  }

  list(
    fields = fields,
    sort = list(as.list(sort)),
    opts = opts
  )
}

#' @noRd
set_sort_param <- function(before) {
  # Fixes former bug
  # for sort = c("patent_id" = "asc", "citation_patent_id" = "asc")
  #  we sent  [{"patent_id":"asc","citation_patent_id":"asc"}]
  # API wants [{"patent_id": "asc" },{"citation_patent_id": "asc" }]
  # TODO(any): brute meet force- there must be a better way...
  after <- tojson_2(before, auto_unbox = TRUE)
  after <- gsub('","', '"},{"', after)
  after
}

#' @noRd
get_get_url <- function(query, base_url, arg_list) {
  j <- paste0(
    base_url,
    "?q=", utils::URLencode(query, reserved = TRUE),
    "&f=", tojson_2(arg_list$fields),
    "&s=", set_sort_param(arg_list$sort),
    "&o=", tojson_2(arg_list$opts, auto_unbox = TRUE)
  )

  utils::URLencode(j)
}

#' @noRd
get_post_body <- function(query, arg_list) {
  body <- paste0(
    "{",
    '"q":', query, ",",
    '"f":', tojson_2(arg_list$fields), ",",
    '"s":', set_sort_param(arg_list$sort), ",",
    '"o":', tojson_2(arg_list$opts, auto_unbox = TRUE),
    "}"
  )
  # The API can now act weirdly if we pass f:{},s:{} as we did in the past.
  # (Weirdly in that the post results may not equal the get results or posts error out)
  # Now we'd remove "f":, and "s":,  We're guaranteed to have q: and at least "size":1000 as o:
  gsub('("[fs]":,)', "", body)
}

#' @noRd
patentsview_error_body <- function(resp) {
  if (httr2::resp_status(resp) == 400) c(httr2::resp_header(resp, "X-Status-Reason")) else NULL
}

#' @noRd
one_request <- function(method, query, base_url, arg_list, api_key, ...) {
  if (method == "GET") {
    get_url <- get_get_url(query, base_url, arg_list)
    req <- httr2::request(get_url) |>
      httr2::req_method("GET")
  } else {
    body <- get_post_body(query, arg_list)
    req <- httr2::request(base_url) |>
      httr2::req_body_raw(body) |>
      httr2::req_headers("Content-Type" = "application/json") |>
      httr2::req_method("POST")
  }

  resp <- req |>
    httr2::req_user_agent("https://github.com/ropensci/patentsview") |>
    httr2::req_options(...) |>
    httr2::req_retry(max_tries = 20) |> # automatic 429 Retry-After
    httr2::req_headers("X-Api-Key" = api_key, .redact = "X-Api-Key") |>
    httr2::req_error(body = patentsview_error_body) |>
    httr2::req_perform()

  resp
}

#' Pad patent_id
#'
#' This function strategically pads a patent_id with zeroes to 8 characters,
#' needed only for custom paging that uses sorts by patent_id.
#'
#' @param patent_id The patent_id that needs to be padded.  It can
#' be the patent_id for a utility, design, plant or reissue patent.
#'
#' @examples
#' \dontrun{
#' padded <- pad_patent_id("RE36479")
#'
#' padded2 <- pad_patent_id("3930306")
#' }
#'
#' @export
# zero pad patent_id to 8 characters.
pad_patent_id <- function(patent_id) {
  pad <- 8 - nchar(patent_id)
  if (pad > 0) {
    patent_id <- paste0(sprintf("%0*d", pad, 0), patent_id)
    patent_id <- sub("(0+)([[:alpha:]]+)([[:digit:]]+)", "\\2\\1\\3", patent_id)
  }
  patent_id
}

#' @noRd
request_apply <- function(ex_res, method, query, base_url, arg_list, api_key, ...) {
  matched_records <- ex_res$query_results[[1]]
  req_pages <- ceiling(matched_records / arg_list$opts$size)

  tmp <- lapply(seq_len(req_pages), function(i) {
    x <- one_request(method, query, base_url, arg_list, api_key, ...)
    x <- process_resp(x)

    # now to page we need to set the "after" attribute to where we left off
    # we want the last value of the primary sort field and possibly a secondary
    # sort field's value
    s <- names(arg_list$sort[[1]])[[1]]
    index <- nrow(x$data[[1]])
    last_value <- x$data[[1]][[s]][[index]]

    if (s == "patent_id") {
      last_value <- pad_patent_id(last_value)
    }

    if (length(arg_list$sort[[1]]) == 2) {
       sfield <- names(arg_list$sort[[1]])[[2]]
       secondary_value <- x$data[[1]][[sfield]][[index]]
       last_value <- c(last_value, secondary_value)
    }

    arg_list$opts$after <<- last_value
    x$data[[1]]
  })

  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' @noRd
get_unique_sort <- function(endpoint) {

  pk <- get_ok_pk(endpoint)
  # we add a secondary sort if there is a sequence field
  sequence <- fieldsdf[fieldsdf$endpoint == endpoint & grepl("^[^.]*sequence",fieldsdf$field), "field"]

  if (length(sequence) == 0) {
    default <- c("asc")
    names(default) <- pk
  } else {
    default <- c("asc", "asc")
    names(default) <- c(pk, sequence)
  }

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
#'    \href{../articles/writing-queries.html}{writing
#'    queries vignette} for details.\cr
#'    E.g., \code{qry_funs$gte(patent_date = "2007-01-04")}
#'  }
#' @param fields A character vector of the fields that you want returned to you.
#'  A value of \code{NULL} indicates to the API that it should return the default fields
#'  for that endpoint. Acceptable fields for a given endpoint can be found at the API's
#'  online documentation (e.g., check out the field list for the
#'  \href{https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/#patent}{patents
#'  endpoint}) or by viewing the \code{fieldsdf} data frame
#'  (\code{View(fieldsdf)}). You can also use \code{\link{get_fields}} to list
#'  out the fields available for a given endpoint.
#'
#'  Nested fields can be fully qualified, e.g., "application.filing_date" or the
#'  group name can be used to retrieve all of its nested fields, E.g. "application".
#'  The latter would be similar to passing \code{get_fields("patent", group = "application")}
#'  except it's the API that decides what fields to return.
#' @param endpoint The web service resource you wish to search. Use
#'  \code{get_endpoints()} to list the available endpoints.
#' @param subent_cnts `r lifecycle::badge("deprecated")` This is always FALSE in the
#' new version of the API as the total counts of unique subentities is no longer available.
#' @param mtchd_subent_only `r lifecycle::badge("deprecated")` This is always
#' FALSE in the new version of the API as non-matched subentities
#' will always be returned.
#' @param page `r lifecycle::badge("deprecated")` The new version of the API does not use
#' \code{page} as a parameter for paging, it uses \code{after}.
#' @param per_page `r lifecycle::badge("deprecated")` The API now uses \code{size}
#' @param size The number of records that should be returned per page. This
#'  value can be as high as 1,000 (e.g., \code{size = 1000}).
#' @param after A list of sort key values that defaults to NULL.  This
#' exposes the API's paging parameter for users who want to implement their own
#' paging. It cannot be set when \code{all_pages = TRUE} as the R package manipulates it
#' for users automatically. See \href{../articles/result-set-paging.html}{result set paging}
#' @param all_pages Do you want to download all possible pages of output? If
#'  \code{all_pages = TRUE}, the value of \code{size} is ignored.
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
#' @param api_key API key, it defaults to Sys.getenv("PATENTSVIEW_API_KEY"). Request a key
#' \href{https://patentsview-support.atlassian.net/servicedesk/customer/portals}{here}.
#' @param ... Curl options passed along to httr2's \code{\link[httr2]{req_options}}
#'  when we do GETs or POSTs.
#'
#' @return A list with the following three elements:
#'  \describe{
#'    \item{data}{A list with one element - a named data frame containing the
#'    data returned by the server. Each row in the data frame corresponds to a
#'    single value for the primary entity. For example, if you search the
#'    assignee endpoint, then the data frame will be on the assignee-level,
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
#'   fields = get_fields("patent", c("patents", "assignees"))
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
#'   endpoint = "inventor",
#'   all_pages = TRUE
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(assignee_individual_name_last = "Smith"),
#'   endpoint = "assignee"
#' )
#'
#' search_pv(
#'   query = qry_funs$contains(inventors.inventor_name_last = "Smith"),
#'   endpoint = "patent",
#'   timeout = 40
#' )
#'
#' search_pv(
#'   query = qry_funs$eq(patent_id = "11530080"),
#'   fields = "application"
#' )
#' }
#'
#' @export
search_pv <- function(query,
                      fields = NULL,
                      endpoint = "patent",
                      subent_cnts = FALSE,
                      mtchd_subent_only = lifecycle::deprecated(),
                      page = lifecycle::deprecated(),
                      per_page = lifecycle::deprecated(),
                      size = 1000,
                      after = NULL,
                      all_pages = FALSE,
                      sort = NULL,
                      method = "GET",
                      error_browser = NULL,
                      api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                      ...) {
  validate_args(api_key, fields, endpoint, method, sort, after, size, all_pages)
  deprecate_warn_all(error_browser, subent_cnts, mtchd_subent_only, page, per_page)
  if (lifecycle::is_present(per_page)) size <- per_page

  if (is.list(query)) {
    check_query(query, endpoint)
    query <- jsonlite::toJSON(query, auto_unbox = TRUE)
  }

  arg_list <- to_arglist(fields, size, sort, after)
  base_url <- get_base(endpoint)

  result <- one_request(method, query, base_url, arg_list, api_key, ...)
  result <- process_resp(result)

  if (all_pages && result$query_result$total_hits == 0) {
    stop2("No records matched your query...Can't download multiple pages")
  }

  # return if we don't need to make additional API requests
  if (!all_pages ||
    result$query_result$total_hits == 0 ||
    result$query_result$total_hits == nrow(result$data[[1]])) {
    return(result)
  }

  # Here we ignore the user's sort and instead have the API sort by the key(s)
  # needed for row uniqueness at the requested endpoint.  Otherwise paging breaks.
  unique_sort_keys <- get_unique_sort(endpoint)

  # We check what fields we got back from the first call. If the user didn't
  # specify fields, we'd get back the API's defaults.  We may need to request
  # additional fields from the API so we can apply the users sort and the keys
  # that quarantee uniqueness, later we'll remove the additional fields.
  returned_fields <- names(result$data[[1]])

  if (is.null(sort)) {
    sort_fields <- names(unique_sort_keys)
  } else {
    sort_fields <- c(names(sort), names(unique_sort_keys))
  }
  additional_fields <- sort_fields[!(sort_fields %in% returned_fields)]
  if (is.null(fields)) {
    fields <- returned_fields # the default fields
  } else {
    fields <- fields # user passed
  }
  fields <- append(fields, additional_fields)

  arg_list <- to_arglist(fields, size, unique_sort_keys, after)
  paged_data <- request_apply(result, method, query, base_url, arg_list, api_key, ...)

  # we apply the user's sort, if they supplied one, using order()
  # was data.table::setorderv(paged_data, names(sort), ifelse(as.vector(sort) == "asc", 1, -1))
  if (!is.null(sort)) {
    sort_order <- mapply(function(col, direction) {
      if (direction == "asc") {
        return(paged_data[[col]])
      } else {
        return(-rank(paged_data[[col]], ties.method = "min"))  # Invert for descending order
      }
    }, col = names(sort), direction = as.vector(sort), SIMPLIFY = FALSE)

    # Final sorting
    paged_data <- paged_data[do.call(order, sort_order), , drop = FALSE]
  }

  # remove the fields we added in order to do the user's and unique sorts
  paged_data <- paged_data[, !names(paged_data) %in% additional_fields]

  result$data[[1]] <- paged_data
  result
}

#' Retrieve Linked Data
#'
#' Some of the endpoints now return HATEOAS style links to get more data. E.g.,
#' the patent endpoint may return a link such as:
#' "https://search.patentsview.org/api/v1/inventor/fl:th_ln:jefferson-1/"
#'
#' @param url A link that was returned by the API on a previous call, an example
#'  in the documentation or a Request URL from the \href{https://search.patentsview.org/swagger-ui/}{API's Swagger UI page}.
#'
#' @param encoded_url boolean to indicate whether the url has been URL encoded, defaults to FALSE.
#'  Set to TRUE for Request URLs from Swagger UI.
#'
#' @param ... Curl options passed along to httr2's \code{\link[httr2]{req_options}} function.
#'
#' @return A list with the following three elements:
#'  \describe{
#'    \item{data}{A list with one element - a named data frame containing the
#'    data returned by the server. Each row in the data frame corresponds to a
#'    single value for the primary entity. For example, if you search the
#'    assignee endpoint, then the data frame will be on the assignee-level,
#'    where each row corresponds to a single assignee. Fields that are not on
#'    the assignee-level would be returned in list columns.}
#'
#'    \item{query_results}{Entity counts across all pages of output (not just
#'    the page returned to you).}
#'
#'    \item{request}{Details of the GET HTTP request that was sent to the server.}
#'  }
#'
#' @inheritParams search_pv
#'
#' @examples
#' \dontrun{
#'
#' retrieve_linked_data(
#'   "https://search.patentsview.org/api/v1/cpc_group/G01S7:4811/"
#' )
#'
#' endpoint_url <- "https://search.patentsview.org/api/v1/patent/"
#' q_param <- '?q={"_text_any":{"patent_title":"COBOL cotton gin"}}'
#' s_and_o_params <- '&s=[{"patent_id": "asc" }]&o={"size":50}'
#' f_param <- '&f=["inventors.inventor_name_last","patent_id","patent_date","patent_title"]'
#' # (URL broken up to avoid a long line warning in this Rd)
#'
#' retrieve_linked_data(
#'   paste0(endpoint_url, q_param, s_and_o_params, f_param)
#' )
#'
#' retrieve_linked_data(
#'   "https://search.patentsview.org/api/v1/patent/?q=%7B%22patent_date%22%3A%221976-01-06%22%7D",
#'   encoded_url = TRUE
#' )
#' }
#'
#' @export
retrieve_linked_data <- function(url,
                                 encoded_url = FALSE,
                                 api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                                 ...
                                ) {
  if (encoded_url) {
    url <- utils::URLdecode(url)
  }

  # There wouldn't be url parameters on a HATEOAS link but we'll also accept
  # example urls from the documentation, where there could be parameters
  url_peices <- httr2::url_parse(url)

  # Only send the API key to subdomains of patentsview.org
  if (!grepl("^.*\\.patentsview.org$", url_peices$hostname)) {
    stop2("retrieve_linked_data is only for patentsview.org urls")
  }

  params <- list()
  query <- ""

  if (!is.null(url_peices$query)) {
    # Need to change f to fields vector, s to sort vector and o to opts
    # There is probably a whizbangy better way to do this in R
    if (!is.null(url_peices$query$f)) {
      params$fields <- unlist(strsplit(gsub("[\\[\\]]", "", url_peices$query$f, perl = TRUE), ",\\s*"))
    }

    if (!is.null(url_peices$query$s)) {
      params$sort <- jsonlite::fromJSON(sub(".*s=([^&]*).*", "\\1", url))
    }

    if (!is.null(url_peices$query$o)) {
      params$opts <- jsonlite::fromJSON(sub(".*o=([^&]*).*", "\\1", url))
    }

    query <- if (!is.null(url_peices$query$q)) sub(".*q=([^&]*).*", "\\1", url) else ""
    url <- paste0(url_peices$scheme, "://", url_peices$hostname, url_peices$path)
  }

  # Go through one_request, which handles resend on throttle errors
  # The API doesn't seem to mind ?q=&f=&o=&s= appended to HATEOAS URLs
  res <- one_request("GET", query, url, params, api_key, ...)
  process_resp(res)
}
