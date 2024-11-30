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
  # ipcr and wipo are funky exceptions.  On assignees and other_references
  # we only want to remove the "s", not the "es"

  if (plural == "ipcr") {
    singular <- "ipc"
  } else if (plural == "wipo") {
    singular <- plural
  } else if (endsWith(plural, "classes")) {
    singular <- sub("es$", "", plural)
  } else {
    singular <- sub("s$", "", plural)
  }
  singular
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
