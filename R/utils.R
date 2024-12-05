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
to_plural <- function(singular) {
  # wipo endpoint returns singular wipo as the entity

  # remove the patent/ and publication/ from nested endpoints when present
  singular <- sub("^(patent|publication)/", "", singular)

  if (singular == "ipc") {
    plural <- "ipcr"
  } else if (singular == "wipo") {
    plural <- singular
  } else if (endsWith(singular, "s")) {
    plural <- paste0(singular, "es")
  } else {
    plural <- paste0(singular, "s")
  }
  plural
}
