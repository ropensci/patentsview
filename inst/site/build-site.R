fix_fun_index <- function() {
  file <- "docs/reference/index.html"
  raw_html <- paste(readLines(file), collapse = "")
  html2 <- gsub(
    "<p></p> *(</td> *<td><p>Fields data)",
    '<p><code><a href="fieldsdf.html">fieldsdf</a></code> </p>\\1',
    raw_html
  )
  html3 <- gsub(
    "<p></p> *(</td> *<td><p>List of query functions)",
    '<p><code><a href="qry_funs.html">qry_funs</a></code> </p>\\1',
    html2
  )
  writeLines(html3, file)
}

remove_cran_href <- function() {
  file <- "docs/index.html"
  raw_html <- readLines(file)
  dl_line <- grepl("Download from CRAN", raw_html)
  raw_html[dl_line] <- "<li>Download from CRAN at <br><a href=\"https://cran.r-project.org/package=patentsview\">https://cran.r-project.org/package=patentsview</a>"
  writeLines(raw_html, file)
}

build_site <- function() {
  extra_vigs <- list.files("inst/site/vignettes", full.names = TRUE, pattern = "\\.Rmd")
  to <- gsub("inst/site/vignettes", "vignettes/", extra_vigs)
  on.exit(try(unlink(x = to, force = TRUE)))
  file.copy(extra_vigs, to = to)
  pkgdown::build_site()
  fix_fun_index()
  remove_cran_href()
}