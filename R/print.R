#' @export
print.pv_request <- function(x) {
  cat(
    "#### An HTTP request where:\n\n",
    "Method: ", x$method, "\n",
    "URL: ", x$url,
    ifelse("body" %in% names(x), paste0("\nBody: ", x$body), ""), sep = ""
  )
}

#' @export
print.pv_data <- function(x) {
  x[[1]] -> df
  sapply(names(df), function(y) {
    class(df[,y])
  }) -> k
  print(df[1:4,])
  lst <- if ("list" %in% k) " (with nested list(s) inside)" else ""
  cat(
    "\n\n#### A data frame", lst, " on the ", names(x)[1],
    " data level, containing the following columns: ",
    paste0(names(k), " (", k, ")", collapse = ", "),
    sep = ""
  )
}

#' @export
print.pv_query_results <- function(x) {
  unlist(x) -> res_vec
  cat(
    "#### Distinct entity counts across all pages of output:\n\n",
    paste0(names(res_vec), " = ", format_num(res_vec), collapse = ", "),
    sep = ""
  )
}

print.pv_query <- function(x) cat(jsonlite::toJSON(x, auto_unbox = TRUE))