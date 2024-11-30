#' Get list of retrievable fields
#'
#' This function returns a vector of fields that you can retrieve from a given
#' API endpoint (i.e., the fields you can pass to the \code{fields} argument in
#' \code{\link{search_pv}}). You can limit these fields to only cover certain
#' entity group(s) as well (which is recommended, given the large number of
#' possible fields for each endpoint).
#'
#' @param endpoint The API endpoint whose field list you want to get. See
#'   \code{\link{get_endpoints}} for a list of the 7 endpoints.
#' @param groups A character vector giving the group(s) whose fields you want
#'   returned. A value of \code{NULL} indicates that you want all of the
#'   endpoint's fields (i.e., do not filter the field list based on group
#'   membership). See the field tables located online to see which groups you
#'   can specify for a given endpoint (e.g., the
#'   \href{https://patentsview.org/apis/api-endpoints/patents}{patents
#'   endpoint table}), or use the \code{fieldsdf} table
#'   (e.g., \code{unique(fieldsdf[fieldsdf$endpoint == "patents", "group"])}).
#'
#' @return A character vector with field names.
#'
#' @examples
#' # Get all assignee-level fields for the patents endpoint:
#' fields <- get_fields(endpoint = "patents", groups = "assignees_at_grant")
#'
#' # ...Then pass to search_pv:
#' \dontrun{
#'
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#' # Get all patent and assignee-level fields for the patents endpoint:
#' fields <- get_fields(endpoint = "patents", groups = c("assignees_at_grant", "patents"))
#'
#' \dontrun{
#' # ...Then pass to search_pv:
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#'
#' @export
get_fields <- function(endpoint, groups = NULL) {
  validate_endpoint(endpoint)
  if (is.null(groups)) {
    fieldsdf[fieldsdf$endpoint == endpoint, "field"]
  } else {
    validate_groups(groups = groups)
    fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$group %in% groups, "field"]
  }
}

#' Get endpoints
#'
#' This function reminds the user what the possible PatentsView API endpoints
#' are.
#'
#' @return A character vector with the names of each endpoint.
#' @export
get_endpoints <- function() {
  # now the endpoints are singular
  # note that now there are two rel_app_texts, one under patents and one under publications
  c(
    "assignee",
    "cpc_class",
    "cpc_group",
    "cpc_subclass",
    "g_brf_sum_text",
    "g_claim",
    "g_detail_desc_text",
    "g_draw_desc_text",
    "inventor",
    "ipc",
    "location",
    "patent",
    "patent/attorney",
    "patent/foreign_citation",
    "patent/other_reference",
    "patent/rel_app_text",
    "patent/us_application_citation",
    "patent/us_patent_citation",
    "pg_brf_sum_text",
    "pg_claim",
    "pg_detail_desc_text",
    "pg_draw_desc_text",
    "publication",
    "publication/rel_app_text",
    "uspc_mainclass",
    "uspc_subclass",
    "wipo"
  )
}
