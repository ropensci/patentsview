#' Fields data frame
#'
#' A data frame containing the names of retrievable and queryable fields for
#' each of the 13 API endpoints. A yes/no flag (\code{can_query}) indicates
#' which fields can be included in the user's query. You can also find this
#' data on the API's online documentation for each endpoint as well (e.g.,
#' the \href{https://patentsview.org/apis/api-endpoints/patents}{patents
#' endpoint field list table})
#'
#' @format A data frame with 130 rows and 8 variables:
#' \describe{
#'   \item{endpoint}{The endpoint that this field record is for}
#'   \item{field}{The name of the field}
#'   \item{data_type}{The field's input data type (string, date, float, integer,
#'     fulltext)}
#'   \item{can_query}{An indicator for whether the field can be included in
#'     the user query for the given endpoint}
#'   \item{group}{The group the field belongs to}
#'   \item{description}{A description of the field}
#'   \item{plain_name}{field without dot parent structure}
#'   \item{cast_as}{data type we want the return to be cast as}
#' }
"fieldsdf"
