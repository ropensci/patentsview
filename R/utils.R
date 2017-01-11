asrt <- function (expr, error, fun = stop) {
  if (!expr) fun(error, call. = FALSE)
}

