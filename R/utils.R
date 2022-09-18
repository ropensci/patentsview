#' @noRd
stop2 <- function(...) stop(..., call. = FALSE)

#' @noRd
asrt <- function(expr, ...) if (!expr) stop2(...)

#' @noRd
format_num <- function(x) {
  format(
    x,
    big.mark = ",", scientific = FALSE, trim = TRUE
  )
}

#' @noRd
to_singular <- function(plural) {
  if (endsWith(plural, "ees")) {
    sub("ees$", "ee", plural)
  } else if (endsWith(plural, "ies")) {
    sub("ies$", "y", plural)
  } else if (endsWith(plural, "es")) {
    sub("es$", "", plural)
  } else if (endsWith(plural, "s")) {
    sub("s$", "", plural)
  } else {
    plural
  }
}

#' @noRd
to_plural <- function(singular) {
  if (endsWith(singular, "y")) {
    sub("y$", "ies", singular)
  } else if (endsWith(singular, "s")) {
    paste0(singular, "es")
  } else {
    paste0(singular, "s")
  }
}
