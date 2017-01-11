asrt <- function (expr, error, fun = stop) {
  if (!expr) fun(error, call. = FALSE)
}

toJSON2 <- function(x, ...) {
  jsonlite::toJSON(x, ...) -> json
  if (!grepl("[:alnum:]", json, ignore.case = TRUE))
    "" -> json
  json
}