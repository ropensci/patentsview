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