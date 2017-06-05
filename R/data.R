#' Fields data
#'
#' A data frame containing the names of retrievable fields for each of the 7
#' API endpoints. A yes/no flag (\code{can_query}) indicates which fields can
#' be included in the user's query.
#'
#' @format A data frame with 992 rows and 7 variables:
#' \describe{
#'   \item{endpoint}{The endpoint that this field record is for}
#'   \item{field}{The name of the field}
#'   \item{data_type}{The field's data type (string, date, float, integer,
#'     fulltext)}
#'   \item{can_query}{An indicator for whether the field can be included in
#'     the user query for the endpoint shown in \code{endpoint}}
#'   \item{group}{The group the field belongs to}
#'   \item{common_name}{The field's common name}
#'   \item{description}{A description of the field}
#' }
"fieldsdf"