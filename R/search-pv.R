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

search_pv <- function(query,
                      fields = NULL, # "patent_number",
                      endpoint = "patents",
                      subent_cnts = FALSE,
                      mtchd_subent_only = FALSE,
                      page = 1,
                      per_page = 25,
                      sort = NULL, # c("patent_number" = "asc")
                      method = "GET",
                      ...) {

  validate_args(query = query, fields = fields, endpoint = endpoint,
                method = method, subent_cnts = subent_cnts,
                mtchd_subent_only = mtchd_subent_only, page = page,
                per_page = per_page, sort = sort)

  to_arglist(fields = fields, subent_cnts = subent_cnts,
             mtchd_subent_only = mtchd_subent_only,
             page = page, per_page = per_page, sort = sort) -> arg_list

  get_base(endpoint = endpoint) -> base_url

  if (method == "GET") {
    get_get_url(query = query, base_url = base_url, arg_list = arg_list) -> url_to_get
    httr::GET(url = url_to_get, ...) -> out
  } else {
    get_post_body(query = query, arg_list = arg_list) -> body_to_post
    gsub('(,"[fs]":)([,}])', paste0('\\1', "{}", '\\2'),
         body_to_post) -> body_trans
  }

  httr::content(out, "text") -> j
  jsonlite::fromJSON(j) -> j
  j
}