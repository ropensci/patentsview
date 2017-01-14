haveViewer <- function() {
  tryCatch(
    rstudioapi::hasFun("viewer"),
    error = function(m) FALSE
  )
}

view_pv_error <- function(full_er) {
  tempDir <- tempfile()
  dir.create(tempDir)
  fi <- file.path(tempDir, "pv_error.html")
  writeLines(full_er, fi)
  rstudioapi::viewer(fi)
}

parse_er <- function(full_er) {
  gsub(".*<strong>Message:</strong>(.*)</.*File:", "\\1", full_er) -> er_prsd
  strsplit(er_prsd, "</[[:alpha:]]")[[1]][1] -> er_prsd_fin
  er_prsd_fin
}

display_er <- function(resp) {
  httr::content(resp, as = "text", encoding = "UTF-8") -> full_er
  parse_er(full_er = full_er) -> er_prsd
  paste0("Your query returned the following error:", er_prsd) -> gen_er
  paste0(gen_er, ".\nTurn on options(pvErrorViewer = TRUE) to see the full ",
         "error details in your rstudio viewer pane.") -> er_cnsol

  getOption("pvErrorViewer") -> view_op_ys
  haveViewer() -> hv_viewer

  if (nchar(er_prsd) < 5) httr::stop_for_status(resp)
  if (view_op_ys && hv_viewer) view_pv_error(full_er = full_er)
  if (view_op_ys && !hv_viewer)
    paste0Stop(er_cnsol, "\n\n", "Note: You need to install the rstudioapi ",
               "package to view patentsview api errors in your viewer pane.")
  if (!view_op_ys && hv_viewer)
    paste0Stop(er_cnsol, "\n\n", "Turn on options(pvErrorViewer = TRUE) to ",
               "see the full error details in your rstudio viewer pane.")
  paste0Stop(gen_er)
}

process_pv_error <- function(resp) {
  httr::http_type(resp) -> typ
  grepl("text|html|xml", typ, ignore.case = TRUE) -> is_txt_html
  if (is_txt_html) display_er(resp) else httr::stop_for_status(resp)
}