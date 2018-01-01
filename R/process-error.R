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
xheader_er <- function(resp, error_browser, special_chk) {

  # look for the api's ultra-helpful X-Status-Reason header
  xhdr =  httr::headers(resp)$'X-Status-Reason'

  if(is.null(xhdr))
     httr::stop_for_status(resp)
  else {
     gen_er <- paste0("The api's X-Status-Reason header says: ", xhdr)
     paste0_stop(gen_er)
  }
}

#' @noRd
throw_er <- function(resp, error_browser) {
  throw_if_loc_error(resp)
  typ <- httr::http_type(resp)
  is_txt_html <- grepl("text|html|xml", typ, ignore.case = TRUE)
  ifelse(
    is_txt_html,
    custom_er(resp = resp, error_browser = error_browser),
    xheader_er(resp = resp, error_browser = error_browser)
  )
}

#' @noRd
throw_if_loc_error <- function(resp) {
  if (hit_locations_ep(resp$url) && resp$status_code == 500) {
    num_grps <- get_num_groups(resp$url)
    if (num_grps > 2) {
      paste0_stop(
        "Your request resulted in a 500 error, likely because you have ",
        "requested too many fields in your request (the locations endpoint ",
        "currently has restrictions on the number of fields/groups you can ",
        "request). Try slimming down your field list and trying again."
      )
    }
  }
}

#' @noRd
hit_locations_ep <- function(url) {
  grepl(
    "^http://www.patentsview.org/api/locations/",
    url,
    ignore.case = TRUE
  )
}

#' @noRd
get_num_groups <- function(url) {
  prsd_json_filds <- gsub(".*&f=([^&]*).*", "\\1", utils::URLdecode(url))
  fields <- jsonlite::fromJSON(prsd_json_filds)
  grps <- fieldsdf[fieldsdf$endpoint == "locations" &
                     fieldsdf$field %in% fields, "group"]
  length(unique(grps))
}
