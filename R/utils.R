paste0_stop <- function(...) stop(paste0(...), call. = FALSE)

paste0_msg <- function(...) message(paste0(...))

asrt <- function (expr, ...) if (!expr) paste0_stop(...)

parse_resp <- function(resp) {
  httr::content(resp, as = "text", encoding = "UTF-8") -> j
  jsonlite::fromJSON(j, simplifyVector = TRUE, simplifyDataFrame = TRUE,
                     simplifyMatrix = TRUE)
}

format_num <- function(x) format(x, big.mark = ",", scientific = FALSE,
                                 trim = TRUE)

validate_endpoint <- function(endpoint) {
  c("patents", "inventors", "assignees", "locations",
    "cpc_subsections", "uspc_mainclasses", "nber_subcategories") -> ok_ends

  asrt(all(endpoint %in% ok_ends, length(endpoint) == 1),
       "endpoint must be a length 1 vector and be one of: ",
       paste(ok_ends, collapse = ", "))
}

validate_group <- function(group) {
  c("applications", "assignees", "cpcs", "gov_interests", "inventors",
    "ipcs", "locations", "nbers", "patents", "rawinventors", "uspcs",
    "wipos", "years", "cpc_subsections", "cpc_subgroups", "coinventors",
    "coinvetnros", "application_citations", "cited_patents", "citedby_patents",
    "nber_subcategories", "uspc_mainclasses", "uspc_subclasses") -> ok_grps

  asrt(group %in% ok_grps,
       "group must be one of: ",
       paste(ok_grps, collapse = ", "))
}