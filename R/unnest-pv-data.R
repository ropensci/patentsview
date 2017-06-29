#' Get OK primary key
#'
#' This function suggests a value that you could use for the \code{pk} argument
#' in \code{\link{unnest_pv_data}}, based on the endpoint you searched.
#' It will return a potential unique identifier for a given entity (i.e., a
#' given endpoint). For example, it will return "patent_id" when
#' \code{endpoint = "patents"}.
#'
#' @param endpoint The endpoint which you would like to know a potential primary
#'   key for.
#'
#' @return The name of a primary key (\code{pk}) that you could pass to
#'   \code{\link{unnest_pv_data}}.
#'
#' @examples
#' get_ok_pk(endpoint = "inventors") # Returns "inventor_id"
#' get_ok_pk(endpoint = "cpc_subsections") # Returns "cpc_subsection_id"
#' @export
get_ok_pk <- function(endpoint) {
  es_eps <- c("uspc_mainclasses" = "uspc_mainclass_id",
              "nber_subcategories" = "nber_subcategory_id")
  ifelse(
    endpoint %in% names(es_eps),
    es_eps[[endpoint]],
    gsub("s$", "_id", endpoint)
  )
}

#' Unnest PatentsView Data
#'
#' This function converts a single data frame that has subentity-level list
#' columns in it into multiple data frames, one for each entity/subentity.
#' The multiple data frames can be merged together using the primary key
#' variable specified by the user (see the
#' \href{http://r4ds.had.co.nz/relational-data.html}{relational data} chapter
#' in "R for Data Science" for an in-depth introduction to joining tabular data).
#'
#' @param data The data returned by \code{\link{search_pv}}. This is the first
#'   element of the three-element result object you got back from
#'   \code{search_pv}. It should be a list of length 1, with one data frame
#'   inside it. See examples.
#' @param pk The column/field name that will link the data frames together. This
#'   should be the unique identifier for the primary entity. For example, if you
#'   used the patents endpoint in your call to \code{search_pv}, you could
#'   specify \code{pk = "patent_id"} or \code{pk = "patent_number"}.
#'   \strong{This identifier has to have been included in your \code{fields}
#'   vector when you called \code{search_pv}}. You can use
#'   \code{\link{get_ok_pk}} to suggest a potential primary key for your data.
#'
#' @return A list with multiple data frames, one for each entity/subentity.
#'   Each data frame will have the \code{pk} column in it, so you can link the
#'   tables together as needed.
#'
#' @examples
#' fields <- c("patent_id", "patent_title", "inventor_city", "inventor_country")
#' res <- search_pv(query = '{"_gte":{"patent_year":2015}}', fields = fields)
#' unnest_pv_data(data = res$data, pk = "patent_id")
#' @export
unnest_pv_data <- function(data, pk = get_ok_pk(names(data))) {

  asrt("pv_data_result" %in% class(data),
       "Wrong input type for data...See example for correct input type")

  df <- data[[1]]

  asrt(pk %in% colnames(df),
       pk, " not in primary entity data frame...Did you include it in your ",
       "fields list?")

  prim_ent_var <- !vapply(df, is.list, logical(1))

  sub_ent_df <- df[, !prim_ent_var, drop = FALSE]
  sub_ents <- colnames(sub_ent_df)

  ok_pk <- get_ok_pk(endpoint = names(data))

  out_sub_ent <- sapply(sub_ents, function(x) {
    temp <- sub_ent_df[[x]]
    asrt(length(unique(df[, pk])) == length(temp),
         pk, " cannot act as a primary key because it is not a ",
         "unique identifier.\n\nTry using ", ok_pk, " instead.")
    names(temp) <- df[, pk]
    xn <- do.call("rbind", temp)
    xn[, pk] <- gsub("\\.[0-9]*$", "", rownames(xn))
    rownames(xn) <- NULL
    xn
  }, USE.NAMES = TRUE, simplify = FALSE)

  prim_ent <- names(data)
  out_sub_ent[[prim_ent]] <- df[, prim_ent_var, drop = FALSE]

  out_sub_ent_reord <- lapply(out_sub_ent, function(x) {
    coln <- colnames(x)
    x[, c(pk, coln[!(pk == coln)]), drop = FALSE]
  })

  structure(
    out_sub_ent_reord,
    class = c("list", "pv_relay_db")
  )
}