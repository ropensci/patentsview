#' @noRd
as_is <- function(x) x

#' @noRd
get_cast_fun <- function(data_type) {
  switch(
    data_type,
    "string" = as_is,
    "date" = as.Date,
    "float" = as.numeric,
    "integer" = as.integer,
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
  cast_fun <- lookup_cast_fun(name = name, typesdf = typesdf)
  cast_fun(one)
}

#' @noRd
cast_one.default <- function(one, name, typesdf) NA

#' @noRd
cast_one.list <- function(one, name, typesdf) {
  first_df <- one[[1]]
  cols <- colnames(first_df)
  fun_list <- lapply(cols, function(x) lookup_cast_fun(x, typesdf = typesdf))
  lapply(one, function(df) {
    casted_lst <- mapply(
       function(df, fun_list) fun_list(df),
        fun_list = fun_list, df = df,
       SIMPLIFY = FALSE
    )
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
#' fields <- c("patent_date", "patent_title", "patent_year")
#' res <- search_pv(query = "{\"patent_number\":\"5116621\"}", fields = fields)
#' cast_pv_data(data = res$data)
#' @export
cast_pv_data <- function(data) {
  validate_pv_data(data = data)

  endpoint <- names(data)

  typesdf <- fieldsdf[fieldsdf$endpoint == endpoint, c("field", "data_type")]

  df <- data[[1]]

  list_out <- lapply2(colnames(df), function(x) {
    one <- df[, x]
    cast_one(one = one, name = x, typesdf = typesdf)
  })

  df[] <- list_out
  out_data <- list(x = df)
  names(out_data) <- endpoint

  structure(
    out_data,
    class = c("list", "pv_data_result")
  )
}
