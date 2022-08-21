#' @noRd
stop2 <- function(...) stop(..., call. = FALSE)

#' @noRd
asrt <- function(expr, ...) if (!expr) stop2(...)

#' @noRd
parse_resp <- function(resp) {
  j <- httr::content(resp, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(
    j,
    simplifyVector = TRUE, simplifyDataFrame = TRUE, simplifyMatrix = TRUE
  )
}

#' @noRd
format_num <- function(x) {
  format(
    x,
    big.mark = ",", scientific = FALSE, trim = TRUE
  )
}

#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()

  asrt(
    all(endpoint %in% ok_ends, length(endpoint) == 1),
    "endpoint must be one of the following: ", paste(ok_ends, collapse = ", ")
  )
}

#' @noRd
validate_groups <- function(groups) {
  ok_grps <- unique(fieldsdf$group)
  asrt(
    all(groups %in% ok_grps),
    "group must be one of the following: ", paste(ok_grps, collapse = ", ")
  )
}

#' @noRd
validate_pv_data <- function(data) {
  asrt(
    "pv_data_result" %in% class(data),
    "Wrong input type for data...See example for correct input type"
  )
}

#' @noRd
to_singular <- function(plural) {
  # assignees is an exception, singular isn't assigne

  if (endsWith(plural, "ies")) {
    singular <- sub("ies$", "y", plural)
  } else if (endsWith(plural, "es") && !endsWith(plural, "ees")) {
    singular <- sub("es$", "", plural)
  } else {
    singular <- sub("s$", "", plural)
  }
}


#' @noRd
to_plural <- function(singular) {
  if (endsWith(singular, "y")) {
    plural <- sub("y$", "ies", singular)
  } else if (endsWith(singular, "s")) {
    plural <- paste0(singular, "es")
  } else {
    plural <- paste0(singular, "s")
  }
}
