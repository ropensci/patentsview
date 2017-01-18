create_one_fun <- function(field, value, fun) {
  list(value) -> k
  names(k) <- field
  list(k) -> z
  names(z) <- paste0("_", fun)
  z
}

create_key_fun <- function(fun) {
  force(fun)
  function(field, value) {
    if (length(value) > 1) {
      lapply(value, function(value)
        create_one_fun(field = field, value = value, fun = fun)) -> z
      z <- list("_or" = z)
    } else {
      create_one_fun(field = field, value = value, fun = fun) -> z
    }
    structure(z, class = c(class(z), "pvquery"))
  }
}

create_array_fun <- function(fun) {
  force(fun)
  function(...) {
    list(...) -> k
    list(k) -> z
    names(z) <- paste0("_", fun)
    structure(z, class = c(class(z), "pvquery"))
  }
}

pv_funs <- c(
  sapply(c("eq", "neq", "gt", "gte", "lt", "lte",
           "begins", "contains", "text_all", "text_any", "text_phrase"),
         create_key_fun, USE.NAMES = TRUE),
  sapply(c("not", "and", "or"),
         create_array_fun, USE.NAMES = TRUE)
)

with_pv <- function(code) {
  eval(substitute(code), pv_funs)
}

print.pvquery <- function(x) cat(jsonlite::toJSON(x, auto_unbox = TRUE))