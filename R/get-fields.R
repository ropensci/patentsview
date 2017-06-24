#' Get field list
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
#'   membership). \code{groups} can be one or more of the following, depending
#'   on the value of \code{endpoint}: "applications", "assignees", "cpcs",
#'   "gov_interests", "inventors", "ipcs", "locations", "nbers", "patents",
#'   "rawinventors", "uspcs", "wipos", "years", "cpc_subsections",
#'   "cpc_subgroups", "coinventors", "application_citations",
#'   "cited_patents", "citedby_patents", "nber_subcategories",
#'   "uspc_mainclasses", and "uspc_subclasses". See the field tables located
#'   online to see which fields correspond to which groups (e.g., the
#'   \href{http://www.patentsview.org/api/patent.html#field_list}{patents
#'   endpoint field list table}).
#'
#' @return A character vector with field names.
#'
#' @examples
#' # Get all assignee-level fields for the patents endpoint:
#' fields <- get_fields(endpoint = "patents", groups = "assignees")
#'
#' #...Then pass to search_pv:
#' search_pv(query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'           fields = fields, endpoint = "patents")
#'
#' # Get all patent and assignee-level fields for the patents endpoint:
#' fields <- get_fields(endpoint = "patents",
#'                      groups = c("assignees", "patents"))
#'
#' #...Then pass to search_pv:
#' search_pv(query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'           fields = fields, endpoint = "patents")
#' @export
get_fields <- function(endpoint, groups = NULL) {
  validate_endpoint(endpoint = endpoint)
  flds <- patentsview::fieldsdf
  if (is.null(groups)) {
    flds[flds$endpoint == endpoint, "field"]
  } else {
    validate_groups(groups = groups)
    flds[flds$endpoint == endpoint & flds$group %in% groups, "field"]
  }
}

#' Get endpoints
#'
#' This function reminds the user what the 7 possible PatentsView API endpoints
#' are.
#'
#' @return A character vector with the names of the 7 endpoints. Those endpoints are:
#'
#' \itemize{
#'    \item assignees
#'    \item cpc_subsections
#'    \item inventors
#'    \item locations
#'    \item nber_subcategories
#'    \item patents
#'    \item uspc_mainclasses
#'  }
#'
#' @examples
#' get_endpoints()
#' @export
get_endpoints <- function() {
  c("assignees", "cpc_subsections", "inventors", "locations",
    "nber_subcategories", "patents", "uspc_mainclasses")
}