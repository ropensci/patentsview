#' @noRd
as_is <- function(x) x

#' @noRd
get_cast_fun <- function(data_type) {
  # Some fields aren't documented, so we don't know what their data type is. Use
  # string type for these.
  if (length(data_type) != 1) data_type <- "string"
  switch(
    data_type,
    "string" = as_is,
    "date" = as.Date,
    "float" = as.numeric,
    "integer" = as.integer,
    "int" = as.integer,
    "fulltext" = as_is
  )
}

#' @noRd
lookup_cast_fun <- function(name, typesdf) {
  data_type <- typesdf[typesdf$field == name, "data_type"]
  get_cast_fun(data_type = data_type)
}

#' @noRd
cast_one.character <- function(one, name, typesdf) {
  cast_fun <- lookup_cast_fun(name, typesdf)
  cast_fun(one)
}

#' @noRd
cast_one.default <- function(one, name, typesdf) NA

#' @noRd
cast_one.list <- function(one, name, typesdf) {
  first_df <- one[[1]]
  cols <- colnames(first_df)
  fun_list <- sapply(
    cols, function(x) lookup_cast_fun(x, typesdf = typesdf),
    USE.NAMES = TRUE, simplify = FALSE
  )
  # Iterate over all dataframes in the list of dataframes
  lapply(one, function(df) {
    # Kinda funky way to go about this, but I'm iterating over the columns in
    # the dataframe, looking up the appropriate cast function for that column
    # and casting it the vector as such, then binding these columns all back
    # together with the call to as.data.frame shown below.
    casted_lst <- lapply(cols, function(one_col_name) {
      fun_list[[one_col_name]](df[[one_col_name]])
    })
    as.data.frame(casted_lst, stringsAsFactors = FALSE, col.names = cols)
  })
}

#' @noRd
cast_one <- function(one, name, typesdf) UseMethod("cast_one")

#' Cast PatentsView data
#'
#' This will cast the data fields returned by \code{\link{search_pv}} so that
#' they have their most appropriate data types (e.g., date, numeric, etc.).
#'
#' @inheritParams unnest_pv_data
#'
#' @return The same type of object that you passed into \code{cast_pv_data}.
#'
#' @examples
#' \dontrun{
#'
#' fields <- c("patent_date", "patent_title", "patent_year")
#' res <- search_pv(query = "{\"patent_number\":\"5116621\"}", fields = fields)
#' cast_pv_data(data = res$data)
#' }
#'
#' @export
cast_pv_data <- function(data) {
  validate_pv_data(data)

  endpoint <- names(data)

  typesdf <- fieldsdf[fieldsdf$endpoint == endpoint, c("field", "data_type")]

  df <- data[[1]]

  list_out <- lapply2(colnames(df), function(x) {
    cast_one(df[, x], name = x, typesdf = typesdf)
  })

  df[] <- list_out
  out_data <- list(x = df)
  names(out_data) <- endpoint

  structure(
    out_data,
    class = c("list", "pv_data_result")
  )
}
