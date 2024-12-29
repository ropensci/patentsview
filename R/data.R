#' Fields data frame
#'
#' A data frame containing the names of retrievable fields for each of the
#' endpoints. You can find this data on the API's online documentation for each
#' endpoint as well (e.g., the
#' \href{https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/#patent}{patent endpoint
#' field list table}).
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{endpoint}{The endpoint that this field record is for}
#'   \item{field}{The complete name of the field, including the parent group if
#'   applicable}
#'   \item{data_type}{The field's input data type}
#'   \item{group}{The group the field belongs to}
#'   \item{common_name}{The field name without the parent group structure}
#' }
"fieldsdf"
