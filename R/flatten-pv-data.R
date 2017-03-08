#' Flatten PatentsView Data
#'
#' This function converts a single data frame with subentity-based list columns into multiple data frames, one for each entity type. The multiple data frames can be merged into a single data frame using the primary key variable.
#'
#' @param data The data returned \code{\link{search_pv}}. This is the first element of the three-element result object you got back. It should be a list of length 1, with one data frame inside it. See examples.
#' @param pk_var A length 1 character vector giving the name of the identifier that will link the data frames together. This should be the unique identifier for the primary entity. For example, if you used the patents endpoint in your call to \code{search_pv}, you should specify \code{pk_var = "patent_id"}. This identifier has to be included in the \code{fields} vector when you called \code{search_pv}.
#'
#' @return A list with a data frame for each distinct entity type included in your data object. Each data frame should have a column giving the pk_var, so you can link the tables back together.
#'
#' @examples
#'
#' res <- search_pv(query = qry_funs$gte(patent_date = "2016-01-01"),
#'                  fields = get_fields("patents", c("patents", "inventors"))) # patent_id is included
#'
#' data2 <- flatten_pv_data(data = res$data, pk_var = "patent_id")
#' @export
flatten_pv_data <- function(data, pk_var) {
  df <- data[[1]]

  asrt(pk_var %in% colnames(df),
       pk_var, " not in primary entity data frame")

  prim_ent_var <- !sapply(df, is.list)

  sub_ent_df <- df[, !prim_ent_var, drop = FALSE]
  sub_ents <- colnames(sub_ent_df)

  out_sub_ent <- sapply(sub_ents, FUN = function(x) {
    temp <- sub_ent_df[[x]]
    asrt(length(unique(df[, pk_var])) == length(temp),
         pk_var, " cannot act as a primary key")

    names(temp) <- df[, pk_var]
    xn <- do.call("rbind", temp)
    xn[, pk_var] <- gsub("\\.[0-9]*$", "", rownames(xn))
    rownames(xn) <- NULL
    xn
  }, USE.NAMES = TRUE, simplify = FALSE)

  prim_ent <- names(data)
  out_sub_ent[[prim_ent]] <- df[, prim_ent_var, drop = FALSE]

  structure(
    out_sub_ent,
    class = c("list", "pv_relay_db")
  )
}