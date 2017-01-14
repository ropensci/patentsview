# Adapted from Hadley's httr and dplyr zzz.R files.

.onLoad <- function(libname, pkgname) {
  op <- options()
  op.patentsview <- list(
    pvErrorViewer = FALSE
  )
  toset <- !(names(op.patentsview) %in% names(op))
  if(any(toset)) options(op.patentsview[toset])

  invisible()
}