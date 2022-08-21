
# I tried having this filename as helper-queries.R but the ubuntu-20.04 job failed
# while the other three jobs worked.  Serveral tests use get_test_query()
# Feels a bit awkward...

query_for_endpoint <- c(
  "application_citations" = '{"patent_number": "10966293"}', # still searchable by pn
  "assignees" = '{"_text_phrase":{"name_last": "Clinton"}}',
  "cpc_groups" = '{"cpc_group_id": "A01B"}',
  "cpc_subgroups" = '{"cpc_subgroup_id": "A01B1/00"}',
  "cpc_subsections" = '{"cpc_subsection_id": "A01"}',
  "inventors" = '{"_text_phrase":{"name_last":"Clinton"}}',
  "locations" = NA,
  "nber_categories" = '{"nber_category_id": "1"}',
  "nber_subcategories" = '{"nber_subcategory_id": "11"}',
  "patents" = '{"patent_number":"5116621"}', # still searchable by pn
  "patent_citations" = '{"patent_number":"5116621"}', # still searchable by pn
  "uspc_mainclasses" = '{"uspc_mainclass_id":"30"}',
  "uspc_subclasses" = '{"uspc_subclass_id": "100/1"}'
)

#' Get Test Query
#'
#' In the new version of the api, only three of the endpoints are searchable
#' by patent number. This function provides a sample query for each
#' endpoint, except for locations, which isn't on the test server yet
#'
#' @param endpoint The web service resource you want a test query for. \code{endpoint}
#'  must be one of the following: "patents", "inventors", "assignees",
#'  "locations", "cpc_groups", "cpc_subgroups", "cpc_subsections", "uspc_mainclasses",
#'  "uspc_subclasses","nber_categories", "nber_subcategories", "application_citations",
#'  or "patent_citations"
#'
#' @return a test query for the specified endpoint.
#'
#' @examples
#' \dontrun{
#'
#' get_test_query("patents")
#' }
#'
#' @export
get_test_query <- function(endpoint) {
  ifelse(endpoint %in% names(query_for_endpoint), query_for_endpoint[[endpoint]], NA)
}
