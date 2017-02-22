parse_er_msg <- function(er_html) {
  if (is.na(er_html)) return("")
  gsub(".*<strong>Message:</strong>(.*)</.*File:", "\\1", er_html) -> er_prsd
  strsplit(er_prsd, "</[[:alpha:]]")[[1]][1] -> er_maybe
  ifelse(is.na(er_maybe), "", er_maybe)
}

custom_er <- function(resp, error_browser) {
  httr::content(resp, as = "text", encoding = "UTF-8") -> er_html
  parse_er_msg(er_html = er_html) -> er_prsd

  paste0("Your query returned the following error:", er_prsd) -> gen_er

  if (nchar(er_prsd) < 5) {
    httr::stop_for_status(resp)
  } else {
    tempDir <- tempfile()
    dir.create(tempDir)
    fi <- file.path(tempDir, "pv_error.html")
    writeLines(er_html, fi)
    utils::browseURL(url = fi, browser = error_browser)
  }

  paste0_stop(gen_er)
}

throw_er <- function(resp, error_browser) {
  httr::http_type(resp) -> typ
  grepl("text|html|xml", typ, ignore.case = TRUE) -> is_txt_html
  ifelse(
    is_txt_html,
    custom_er(resp = resp, error_browser = error_browser),
    httr::stop_for_status(resp)
  )
}