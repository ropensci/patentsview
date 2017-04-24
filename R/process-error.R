#' @noRd
parse_er_msg <- function(er_html) {
  if (is.na(er_html)) return("")
  er_prsd <- gsub(".*<strong>Message:</strong>(.*)</.*File:", "\\1", er_html)
  er_maybe <- strsplit(er_prsd, "</[[:alpha:]]")[[1]][1]
  ifelse(is.na(er_maybe), "", er_maybe)
}

#' @noRd
custom_er <- function(resp, error_browser) {

  er_html <- httr::content(resp, as = "text", encoding = "UTF-8")
  er_prsd <- parse_er_msg(er_html = er_html)

  gen_er <- paste0("Your query returned the following error:", er_prsd)

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

#' @noRd
throw_er <- function(resp, error_browser) {
  typ <- httr::http_type(resp)
  is_txt_html <- grepl("text|html|xml", typ, ignore.case = TRUE)
  ifelse(
    is_txt_html,
    custom_er(resp = resp, error_browser = error_browser),
    httr::stop_for_status(resp)
  )
}