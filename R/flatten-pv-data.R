#' Flatten PatentsView Data
#'
#' This function converts a single data frame that has subentity-level list columns in it into multiple data frames, one for each entity/subentity type. The multiple data frames can be merged together using the primary key variable specified by the user.
#'
#' @param data The data returned \code{\link{search_pv}}. This is the first element of the three-element result object you got back from \code{search_pv}. It should be a list of length 1, with one data frame inside it. See examples.
#' @param pk_var The column/field name that will link the data frames together. This should be the unique identifier for the primary entity. For example, if you used the patents endpoint in your call to \code{search_pv}, you could specify \code{pk_var = "patent_id"}. This identifier has to be included in your \code{fields} vector when you called \code{search_pv}.
#'
#' @return A list with multiple data frames, one for each entity/subentity type. Each data frame will have the column specified by \code{pk_var} in it, so you can link the tables back together.
#'
#' @examples
#'
#' fields <- c("patent_id", "patent_title", "inventor_city", "inventor_country")
#' res <- search_pv(query = '{"_gte":{"patent_year":2015}}', fields = fields)
#' data2 <- flatten_pv_data(data = res$data, pk_var = "patent_id")
#'
#' @export
flatten_pv_data <- function(data, pk_var) {

  asrt("pv_data_result" %in% class(data),
       " Wrong input type for data...See example for correct input type")

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

  out_sub_ent_reord <- lapply(out_sub_ent, FUN = function(x) {
    coln <- colnames(x)
    x[,c(pk_var, coln[!(pk_var == coln)])]
  })

  structure(
    out_sub_ent_reord,
    class = c("list", "pv_relay_db")
  )
}