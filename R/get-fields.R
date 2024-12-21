#' @noRd
get_top_level_attributes <- function(endpoint) {
  fieldsdf[fieldsdf$endpoint == endpoint & !grepl("\\.", fieldsdf$field), "field"]
}


#' Get list of retrievable fields
#'
#' This function returns a vector of fields that you can retrieve from a given
#' API endpoint (i.e., the fields you can pass to the \code{fields} argument in
#' \code{\link{search_pv}}). You can limit these fields to only cover certain
#' entity group(s) as well (which is recommended, given the large number of
#' possible fields for each endpoint).
#'
#' @param endpoint The API endpoint whose field list you want to get. See
#'   \code{\link{get_endpoints}} for a list of the 27 endpoints.
#' @param groups A character vector giving the group(s) whose fields you want
#'   returned. A value of \code{NULL} indicates that you want all of the
#'   endpoint's fields (i.e., do not filter the field list based on group
#'   membership). See the field tables located online to see which groups you
#'   can specify for a given endpoint (e.g., the
#'   \href{https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/#patent}{patents
#'   endpoint table}), or use the \code{fieldsdf} table
#'   (e.g., \code{unique(fieldsdf[fieldsdf$endpoint == "patent", "group"])}).
#' @param include_pk Boolean on whether to include the endpoint's primary key,
#'    defaults to FALSE.  The primary key is needed if you plan on calling
#'    \code{\link{unnest_pv_data}} on the results of \code{\link{search_pv}}
#'
#' @return A character vector with field names.
#'
#' @examples
#' # Get all assignee-level fields for the patent endpoint:
#' fields <- get_fields(endpoint = "patent", groups = "assignees")
#'
#' # ...Then pass to search_pv:
#' \dontrun{
#'
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#' # Get all patent and assignee-level fields for the patent endpoint:
#' fields <- get_fields(endpoint = "patent", groups = c("assignees", "patents"))
#'
#' \dontrun{
#' # ...Then pass to search_pv:
#' search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' }
#' # Get the nested inventors fields and the primary key in order to call unnest_pv_data
#' # on the returned data.  unnest_pv_data would throw an error if the primary key was
#' # not present in the results.
#' fields <- get_fields(endpoint = "patent", groups = c("inventors"), include_pk = TRUE)
#'
#' \dontrun{
#' # ...Then pass to search_pv and unnest the results
#' results <- search_pv(
#'   query = '{"_gte":{"patent_date":"2007-01-04"}}',
#'   fields = fields
#' )
#' unnest_pv_data(results$data)
#' }
#'
#' @export
get_fields <- function(endpoint, groups = NULL, include_pk = FALSE) {
  validate_endpoint(endpoint)

  # using API's shorthand notation, group names can be requested as fields instead of
  # fully qualifying each nested field.  Fully qualified, all patent endpoint's attributes
  # is over 4K, too big to be sent on a GET with a modest query

  pk <- get_ok_pk(endpoint)
  plural_entity <- fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$field == pk, "group"]
  top_level_attributes <- get_top_level_attributes(endpoint)

  if (is.null(groups)) {
    c(
      top_level_attributes,
      unique(fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$group != plural_entity, "group"])
    )
  } else {
    validate_groups(endpoint, groups = groups)

    # don't include pk if plural_entity group is requested (pk would be a member)
    extra_field <- if (include_pk && !plural_entity %in% groups) pk else NULL
    extra_fields <- if (plural_entity %in% groups) top_level_attributes else NULL

    c(
      extra_field,
      extra_fields,
      groups[!groups == plural_entity]
    )
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
  unique(fieldsdf$endpoint)
}
