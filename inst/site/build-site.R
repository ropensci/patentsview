fix_fun_index <- function() {
  raw_html <- paste(readLines("docs/reference/index.html"), collapse = "")
  html2 <- gsub(
    "<p></p> *(</td> *<td><p>Fields data)",
    '<p><code><a href="fieldsdf.html">fieldsdf</a></code> </p>\\1',
    raw_html
  )
  html3 <- gsub(
    "<p></p> *(</td> *<td><p>Query function list)",
    '<p><code><a href="qry_funs.html">qry_funs</a></code> </p>\\1',
    html2
  )
  writeLines(html3, "docs/reference/index.html")
}

build_site <- function() {
  extra_vigs <- list.files("inst/site/vignettes", full.names = TRUE, pattern = "\\.Rmd")
  to <- gsub("inst/site/vignettes", "vignettes/", extra_vigs)
  on.exit(try(unlink(x = to, force = TRUE)))
  file.copy(extra_vigs, to = to)
  pkgdown::build_site()
  fix_fun_index()
}

# need to put fotter in: <p><a href="http://ropensci.org"><img src="http://ropensci.org/public_images/github_footer.png" alt="ropensci_footer"></a></p>