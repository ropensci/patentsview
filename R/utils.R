paste0Stop <- function(...) stop(paste0(...), call. = FALSE)

paste0Mess <- function(...) message(paste0(...))

asrt <- function (expr, ...) if (!expr) paste0Stop(...)

toJSON2 <- function(x, ...) {
  jsonlite::toJSON(x, ...) -> json
  if (!grepl("[:alnum:]", json, ignore.case = TRUE))
    "" -> json
  json
}