#' @noRd
paste0_stop <- function(...) stop(paste0(...), call. = FALSE)

#' @noRd
paste0_msg <- function(...) message(paste0(...))

#' @noRd
asrt <- function (expr, ...) if (!expr) paste0_stop(...)

#' @noRd
parse_resp <- function(resp) {
  j <- httr::content(resp, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(j, simplifyVector = TRUE, simplifyDataFrame = TRUE,
                     simplifyMatrix = TRUE)
}

#' @noRd
format_num <- function(x) format(x, big.mark = ",", scientific = FALSE,
                                 trim = TRUE)

#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()

  asrt(all(endpoint %in% ok_ends, length(endpoint) == 1),
       "endpoint must be one of the following: ",
       paste(ok_ends, collapse = ", "))
}

#' @noRd
validate_groups <- function(groups) {
  ok_grps <- c("applications", "assignees", "cpcs", "gov_interests",
               "inventors", "ipcs", "locations", "nbers", "patents",
               "rawinventors", "uspcs", "wipos", "years", "cpc_subsections",
               "cpc_subgroups", "coinventors", "coinvetnros",
               "application_citations", "cited_patents", "citedby_patents",
               "nber_subcategories", "uspc_mainclasses", "uspc_subclasses")

  asrt(all(groups %in% ok_grps),
       "group must be one of the following: ", paste(ok_grps, collapse = ", "))
}