#' Get OK primary key
#'
#' This function suggests a value that you could use for the \code{pk} argument
#' in \code{\link{unnest_pv_data}}, based on the endpoint you searched.
#' It will return a potential unique identifier for a given entity (i.e., a
#' given endpoint). For example, it will return "patent_id" when
#' \code{endpoint_or_entity = "patent"}.  It would return the same value if
#' the entity name "patents" was passed via \code{get_ok_pk(names(pv_return$data))}
#' where pv_return was returned from \code{\link{search_pv}}.
#'
#' @param endpoint_or_entity The endpoint or entity name for which you
#' would like to know a potential primary key for.
#'
#' @return The name of a primary key (\code{pk}) that you could pass to
#'   \code{\link{unnest_pv_data}}.
#'
#' @examples
#' get_ok_pk(endpoint_or_entity = "inventor") # Returns "inventor_id"
#' get_ok_pk(endpoint_or_entity = "cpc_group") # Returns "cpc_group_id"
#'
#' @export
get_ok_pk <- function(endpoint_or_entity) {
  endpoint_df <- fieldsdf[fieldsdf$endpoint == endpoint_or_entity, ]
  if (nrow(endpoint_df) > 0) {
    endpoint <- endpoint_or_entity
  } else {
    endpoint_df <- fieldsdf[fieldsdf$group == endpoint_or_entity, ]
    endpoint <- unique(endpoint_df$endpoint)

    # watch out here- several endpoints return entities that are groups returned
    # by the patent and publication endpoints (attourneys, inventors, assignees)
    if(length(endpoint) > 1) {
      endpoint <- endpoint[!endpoint %in% c("patent", "publication")]
      endpoint_df <- fieldsdf[fieldsdf$endpoint == endpoint, ]
    }
  }

  unnested_endpoint <- sub("^(patent|publication)/", "", endpoint)
  possible_pks <- c("patent_id", "document_number", paste0(unnested_endpoint, "_id"))
  pk <- endpoint_df[endpoint_df$field %in% possible_pks, "field"]

  # we're unable to determine the pk if an entity name of rel_app_texts was passed
  asrt(
    length(pk) == 1,
    "The primary key cannot be determined for ", endpoint_or_entity,
    ". Try using the endpoint's name instead ",
    paste(unique(fieldsdf[fieldsdf$group == endpoint_or_entity, "endpoint"]), collapse = ", ")
  )

  pk
}

#' Unnest PatentsView data
#'
#' This function converts a single data frame that has subentity-level list
#' columns in it into multiple data frames, one for each entity/subentity.
#' The multiple data frames can be merged together using the primary key
#' variable specified by the user (see the
#' \href{https://r4ds.had.co.nz/relational-data.html}{relational data} chapter
#' in "R for Data Science" for an in-depth introduction to joining tabular data).
#'
#' @param data The data returned by \code{\link{search_pv}}. This is the first
#'   element of the three-element result object you got back from
#'   \code{search_pv}. It should be a list of length 1, with one data frame
#'   inside it. See examples.
#' @param pk The column/field name that will link the data frames together. This
#'   should be the unique identifier for the primary entity. For example, if you
#'   used the patent endpoint in your call to \code{search_pv}, you could
#'   specify \code{pk = "patent_id"}. \strong{This identifier has to have
#'   been included in your \code{fields} vector when you called
#'   \code{search_pv}}. You can use \code{\link{get_ok_pk}} to suggest a
#'   potential primary key for your data.
#'
#' @return A list with multiple data frames, one for each entity/subentity.
#'   Each data frame will have the \code{pk} column in it, so you can link the
#'   tables together as needed.
#'
#' @examples
#' \dontrun{
#'
#' fields <- c("patent_id", "patent_title", "inventors.inventor_city", "inventors.inventor_country")
#' res <- search_pv(query = '{"_gte":{"patent_year":2015}}', fields = fields)
#' unnest_pv_data(data = res$data, pk = "patent_id")
#' }
#'
#' @export
unnest_pv_data <- function(data, pk = NULL) {
  validate_pv_data(data)

  df <- data[[1]]

  if (is.null(pk)) {
    # now there are two endpoints that return rel_app_texts entities with different pks
    if (names(data) == "rel_app_texts") {
      pk <- if ("document_number" %in% names(df)) "document_number" else "patent_id"
    } else {
      pk = get_ok_pk(names(data))
    }
  }

  asrt(
    pk %in% colnames(df),
    pk, " not in primary entity data frame...Did you include it in your ",
    "fields list?"
  )

  prim_ent_var <- !vapply(df, is.list, logical(1))

  sub_ent_df <- df[, !prim_ent_var, drop = FALSE]
  sub_ents <- colnames(sub_ent_df)

  out_sub_ent <- lapply2(sub_ents, function(x) {
    temp <- sub_ent_df[[x]]
    asrt(
      length(unique(df[, pk])) == length(temp), pk,
      " cannot act as a primary key because it is not a unique identifier.\n\n",
      "Try using ", pk, " instead."
    )
    names(temp) <- df[, pk]
    xn <- do.call("rbind", temp)
    xn[, pk] <- gsub("\\.[0-9]*$", "", rownames(xn))
    rownames(xn) <- NULL
    xn
  })

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
