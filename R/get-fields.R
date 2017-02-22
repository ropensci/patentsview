#' Get field list
#'
#' @param endpoint A length 1 character vector giving the API endpoint you will be searching.
#' @param group A character vector giving the group(s) whose fields you want returned. This corresponds to the second column in the online field list tables (e.g., for the \href{http://www.patentsview.org/api/patent.html#field_list}{patents endpoint}). See examples.
#'
#' @return A character vector with field names...You can pass this vector to the \code{fields} argument in \code{\link{search_pv}}.
#'
#' @examples
#' # Get fields falling into the assignees group for the patents endpoint.
#' get_fields("patents", "assignees")
#'
#' # ...Also get patent-level fields too:
#' get_fields("patents", c("patents", "assignees"))
#'
#' @export
get_fields <- function(endpoint, group) {
  validate_endpoint(endpoint = endpoint)
  validate_group(group = group)
  fields -> flds
  flds[flds$endpoint == endpoint & flds$group %in% group, "field"]
}