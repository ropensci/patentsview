# Adapted from Hadley's httr and dplyr zzz.R files.

#' @noRd
.onLoad <- function(libname, pkgname) {
  op <- options()
  op.patentsview <- list(pv_browser = "false")
  toset <- !(names(op.patentsview) %in% names(op))
  if (any(toset)) options(op.patentsview[toset])
  invisible()
}
