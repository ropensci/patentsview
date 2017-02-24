#' @export
print.pv_request <- function(x, ...) {
  cat(
    "#### An HTTP request where:\n\n",
    "Method: ", x$method, "\n",
    "URL: ", x$url,
    ifelse("body" %in% names(x), paste0("\nBody: ", x$body), ""), sep = ""
  )
}

#' @export
print.pv_data_result <- function(x, ...) {

  x[[1]] -> df
  sapply(names(df), function(y) {
    class(df[,y])
  }) -> k

  c("patents" = "patent", "inventors" = "inventor", "assignees" = "assignee",
    "locations" = "location", "cpc_subsections" = "CPC subsection",
    "uspc_mainclasses" = "USPC main class",
    "nber_subcategories" = "NBER subcategory") -> dat_level
  lst <- ifelse("list" %in% k, " (with nested list(s) inside)", "")

  cat(
    "#### A data frame", lst, " on the ", dat_level[[names(x)[1]]],
    " data level, containing the following columns: ",
    paste0(names(k), " (", k, ")", collapse = ", "),
    "\n", sep = ""
  )

  print(df[1:4,])
}

#' @export
print.pv_query_result <- function(x, ...) {
  unlist(x) -> res_vec
  cat(
    "#### Distinct entity counts across all pages of output:\n\n",
    paste0(names(res_vec), " = ", format_num(res_vec), collapse = ", "),
    sep = ""
  )
}

#' @export
print.pv_result <- function(x, ...) {
  print(x[1])
  cat("\n")
  print(x[2])
}

#' @export
print.pv_query <- function(x, ...) cat(jsonlite::toJSON(x, auto_unbox = TRUE))