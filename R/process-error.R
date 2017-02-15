have_viewer <- function() {
  tryCatch(
    rstudioapi::hasFun("viewer"),
    error = function(m) FALSE
  )
}

view_er_html <- function(er_html) {
  tempDir <- tempfile()
  dir.create(tempDir)
  fi <- file.path(tempDir, "pv_error.html")
  writeLines(er_html, fi)
  rstudioapi::viewer(fi)
}

parse_er_msg <- function(er_html) {
  if (is.na(er_html)) return("")
  gsub(".*<strong>Message:</strong>(.*)</.*File:", "\\1", er_html) -> er_prsd
  strsplit(er_prsd, "</[[:alpha:]]")[[1]][1] -> er_maybe
  ifelse(is.na(er_maybe), "", er_maybe)
}

custom_er <- function(resp) {
  httr::content(resp, as = "text", encoding = "UTF-8") -> er_html
  parse_er_msg(er_html = er_html) -> er_prsd

  paste0("Your query returned the following error:", er_prsd) -> gen_er

  getOption("pv_error_viewer") -> view_op_ys
  have_viewer() -> hv_viewer

  if (nchar(er_prsd) < 5) httr::stop_for_status(resp)
  if (view_op_ys && hv_viewer) view_er_html(er_html = er_html)
  if (view_op_ys && !hv_viewer)
    paste0_stop(gen_er, "\n\n", "Note: You need to install the rstudioapi ",
                "package to view patentsview api errors in your viewer pane.")
  paste0_stop(gen_er)
}

throw_er <- function(resp) {
  httr::http_type(resp) -> typ
  grepl("text|html|xml", typ, ignore.case = TRUE) -> is_txt_html
  ifelse(is_txt_html, custom_er(resp), httr::stop_for_status(resp))
}