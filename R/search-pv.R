#' @noRd
sub_grp_names_for_fields <- function(endpoint, fields) {
  ep_fields <- fieldsdf[fieldsdf$endpoint == endpoint, ]
  grps <- unique(ep_fields$group)
  pk <- get_ok_pk(endpoint)
  primary_grp <- fieldsdf[
    fieldsdf$endpoint == endpoint & fieldsdf$field %in% pk,
    "group"
  ][1]

  abbreviated_fields <- lapply(grps, function(grp) {
    is_this_grp <- ep_fields$group == grp
    all_grp_fields <- ep_fields[is_this_grp, "field"]
    all_chosen_fields <- all_grp_fields %in% fields
    grp_in_fields <- grp %in% fields
    abbreviation_is_possible <- all(all_chosen_fields) && !(grp ==  primary_grp)
    if (abbreviation_is_possible || grp_in_fields) {
      grp
    } else {
      all_grp_fields[all_grp_fields %in% fields]
    }
  })
  unlist(abbreviated_fields)
}

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
to_arglist <- function(fields, size, sort, after, exclude_withdrawn) {
  opts <- list(size = size)
  if (!is.null(after)) {
    opts$after <- after
  }
  if (!is.null(exclude_withdrawn)) {
    opts$exclude_withdrawn <- exclude_withdrawn
  }
  out <- list(
    fields = fields,
    opts = opts
  )
  out$sort <- sort
  out
}

#' @noRd
set_sort_param <- function(sort_vec) {
  # the API now throws a 500 on &s=[]
  ifelse(is.null(sort_vec),'',
    jsonlite::toJSON(
      lapply(names(sort_vec), function(name) {
        stats::setNames(list(sort_vec[[name]]), name)
      }),
      auto_unbox = TRUE
    )
  )
}

#' @noRd
get_get_url <- function(query, base_url, arg_list) {
  paste0(
    base_url,
    "?q=", utils::URLencode(query, reserved = TRUE),
    utils::URLencode(
      paste0(
        "&f=", tojson_2(arg_list$fields),
        "&s=", set_sort_param(arg_list$sort),
        "&o=", tojson_2(arg_list$opts, auto_unbox = TRUE)
      )
    )
  )
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
  # TODO(0): check this out
  # The API can now act weirdly if we pass f:{},s:{} as we did in the past
  # (weirdly in that the POST results may not equal the GET results, or POSTs
  # error out)
  gsub('("[fs]":,)', "", body)
}

#' @noRd
patentsview_error_body <- function(resp) {
  if (httr2::resp_status(resp) == 400)
    httr2::resp_header(resp, "X-Status-Reason")
  else
    NULL
}

#' @noRd
one_request <- function(method, query, base_url, arg_list, api_key, ...) {

  if (method == "GET") {
    if(query == "") {
       get_url <- base_url
    } else {
       get_url <- get_get_url(query, base_url, arg_list)
    }
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

#' @noRd
request_apply <- function(result, method, query, base_url, arg_list, api_key, ...) {
  matched_records <- result$query_results[[1]]
  req_pages <- ceiling(matched_records / arg_list$opts$size)
  col_names <- NULL

  tmp <- lapply(seq_len(req_pages), function(i) {
    x <- one_request(method, query, base_url, arg_list, api_key, ...)
    x <- process_resp(x)

    # now the API can freak out while paging
    # it doesn't always return the same columns
    # and disregards the requested fields
    # rbind can handle the possible column order difference
    # but not when fewer or more columns are returned
    x$data <- repair_resp(x$data, arg_list$fields)

    if (is.null(col_names)) {
      col_names <<- names(x$data[[1]])
    } else if (!setequal(col_names, names(x$data[[1]]))) {
      stop2(
        "API returned paged data with different structure.\n",
        "Initial columns: ", paste(sort(col_names), collapse = ", "), "\n",
        "After '", arg_list$opts$after[1], "': ",
        paste(sort(names(x$data[[1]])), collapse = ", "), "\n",
        "This is an API bug - results cannot be combined."
      )
    }

    sort_cols <- names(arg_list$sort)
    last_row <- nrow(x$data[[1]])
    if (is.null(last_row)) return(NULL)

    last_values <- x$data[[1]][last_row, sort_cols, drop = FALSE]
    last_values <- unlist(last_values[1, ], use.names = FALSE)

    arg_list$opts$after <<- last_values
    x$data[[1]]
  })

  do.call("rbind", c(tmp, make.row.names = FALSE))
}

#' Search PatentsView
#'
#' This makes an HTTP request to the PatentsView API for data matching the
#' user's query.
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
#'  A value of \code{NULL} indicates to the API that it should return the default fields
#'  for that endpoint. Acceptable fields for a given endpoint can be found in
#'  the \code{fieldsdf} data frame (\code{View(fieldsdf)}) or by using
#'  \code{\link{get_fields}}. Nested fields can be fully qualified, e.g.,
#'  "application.filing_date" or you can use the group name that the field
#'  belongs to if you want all of the nested fields for that group.
#'
#'  Note: The primary key columns for a given endpoint will be appended to your
#'  list of fields within \code{search_pv}. You can see the \code{\link{get_ok_pk}}
#'  to determine what those columns will be for a given endpoint.
#'
#'  Note: If you specify all fields in a given group using their full qualified
#'  names, the group name will be substituted in the HTTTP request. This helps
#'  make HTTP requests shorter. This substitution will not happen when you specify
#'  all of the primary-entity fields (e.g., passing
#'  \code{get_fields("patent", "patents")} into \code{search_pv} would not
#'  substitute use the group name "patents" in place of all of the fields).
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
#' for users automatically. See \href{https://docs.ropensci.org/patentsview/articles/result-set-paging.html}{result set paging}
#' @param all_pages Do you want to download all possible pages of output? If
#'  \code{all_pages = TRUE}, the value of \code{size} is ignored.
#' @param sort A named character vector where the name indicates the field to
#'  sort by and the value indicates the direction of sorting (direction should
#'  be either "asc" or "desc"). For example, \code{sort = c("patent_id" =
#'  "asc")} or \cr\code{sort = c("patent_id" = "asc", "patent_date" =
#'  "desc")}. \code{sort = NULL} (the default) means the API will use the default
#'  sort column for your given endpoint.
#'  You must include any fields that you wish to sort by in \code{fields}.
#' @param method The HTTP method that you want to use to send the request.
#'  Possible values include "GET" or "POST". Use the POST method when
#'  your query is very long (say, over 2,000 characters in length).
#' @param error_browser `r lifecycle::badge("deprecated"
#' @param exclude_withdrawn only used by the patent endpoint, if FALSE withdrawn patents
#'  in the database can be returned by a query.  The API defaults this to TRUE, not
#'  returning withdrawn patents in the database that met the query parameter.
#' @param api_key API key, it defaults to Sys.getenv("PATENTSVIEW_API_KEY"). Request a key
#' \href{https://patentsview-support.atlassian.net/servicedesk/customer/portals}{here}.
#' @param ... Curl options passed along to httr2's \code{\link[httr2]{req_options}}
#'  when we do GETs or POSTs.
#'
#' @return A list with the following three elements:
#'  \describe{
#'    \item{data}{A list with one element - a named data frame containing the
#'    data returned by the server. Each row in the data frame corresponds to a
#'    single value for the primary entity, as defined by the endpoint's primary key.
#'    For example, if you search the assignee endpoint, then the data frame
#'    will be on the assignee-level, where each row corresponds to a single
#'    assignee (primary key would be \code{assignee_id}). Fields that are not on
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
#'
#' search_pv(
#'   query = qry_funs$eq(patent_id = "9494444"),  # a withdrawn patent in the pview dbs
#'   fields = c("patent_id", "patent_date", "withdrawn"),
#'   exclude_withdrawn = FALSE
#' )
#'
#' search_pv(
#'   query = qry_funs$eq(withdrawn = TRUE),
#'   fields = c("patent_id", "patent_date", "withdrawn"),
#'   exclude_withdrawn = FALSE
#' )
#' }
#'
#' @export
search_pv <- function(query,
                      fields = NULL,
                      endpoint = "patent",
                      subent_cnts = lifecycle::deprecated(),
                      mtchd_subent_only = lifecycle::deprecated(),
                      page = lifecycle::deprecated(),
                      per_page = lifecycle::deprecated(),
                      size = 1000,
                      after = NULL,
                      all_pages = FALSE,
                      sort = NULL,
                      method = "GET",
                      error_browser = lifecycle::deprecated(),
                      exclude_withdrawn = NULL,
                      api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                      ...) {
  validate_args(api_key, fields, endpoint, method, sort, after, size, all_pages, exclude_withdrawn)
  deprecate_warn_all(error_browser, subent_cnts, mtchd_subent_only, page, per_page)

  if (is.list(query)) {
    check_query(query, endpoint)
    query <- jsonlite::toJSON(query, auto_unbox = TRUE)
  }

  requested_fields <- fields  # before we mess with them

  pk <- get_ok_pk(endpoint)
  # We need pk to be in the result for all_pages to work with ease, hence adding
  # it below
  fields <- unique(c(pk, fields))
  abbreviated_fields <- sub_grp_names_for_fields(endpoint, fields)

  arg_list <- to_arglist(abbreviated_fields, size, sort, after, exclude_withdrawn)

  base_url <- get_base(endpoint)

  first_req <- one_request(method, query, base_url, arg_list, api_key, ...)
  first_res <- process_resp(first_req)
  first_res$data <- repair_resp(first_res$data, fields)

  zero_hits <- first_res$query_result$total_hits == 0
  hits_equal_rows <- first_res$query_result$total_hits == nrow(first_res$data[[1]])
  if (!all_pages || zero_hits || hits_equal_rows) {
    return(first_res) # else we iterate through pages below
  }

  unique_sort_keys <- rep("asc", length(pk))
  names(unique_sort_keys) <- pk
  arg_list$sort <- unique_sort_keys

  paged_data <- request_apply(
    first_res, method, query, base_url, arg_list, api_key, ...
  )

  # we can't remove any pk fields we added or unnest_pv_data could fail

  first_res$data[[1]] <- paged_data
  first_res
}

#' Retrieve Linked Data
#'
#' Some of the endpoints now return HATEOAS style links to get more data. E.g.,
#' the patent endpoint may return a link such as:
#' "https://search.patentsview.org/api/v1/inventor/fl:th_ln:jefferson-1/". Use
#' this function to fetch details from those links.
#'
#' @param url A link that was returned by the API on a previous call.
#' @inheritParams search_pv
#'
#' @examples
#' \dontrun{
#'
#' retrieve_linked_data(
#'   "https://search.patentsview.org/api/v1/cpc_group/G01S7:4811/"
#' )
#' }
#'
#' @export
retrieve_linked_data <- function(url,
                                 api_key = Sys.getenv("PATENTSVIEW_API_KEY"),
                                 ...
                                ) {
  if (is.null(url)) {
    stop2("URL must be a valid URL")
  }

  # API bug (fixed Dec 2025): :80 was added to https links. Keep workaround for safety.
  url <- sub(':80', '', url)

  res <- one_request("GET", "", url, list(), api_key, ...)
  process_resp(res)  # here there are no fields so we don't call repair_resp
}
