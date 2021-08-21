# Renders the .Rmd.orig files to .Rmd files. This is considered "half-rendering"
# because it creates .Rmd files that will get rendered by ROpenSci during the site
# builds that they run on Jenkins.
half_render_vignettes <- function() {
  # I want the figures directory that's created when knitr renders the docs to
  # be within the vignettes dir, hence the directory change below
  cur_dir <- getwd()
  on.exit(setwd(cur_dir))
  setwd("vignettes")

  source_files <- list.files(pattern = "\\.Rmd\\.orig$")
  for (file in source_files) {
    print(paste("Knitting", file))
    knitr::knit(file, gsub("\\.orig$", "", file))
  }
}

# Builds the pkgdown locally. This functions has to do some crazy working directory
# changes and file copy/moves so that pkgdown renders the intended raw Rmd files (those
# ending in .Rmd.orig) and not the half rendered files ending in .Rmd. The changes
# to the current working directory are needed get the file structure copied as
# desired.
build_site_locally <- function() {
  cur_dir <- getwd()
  on.exit(setwd(cur_dir))
  setwd("vignettes")

  vig_dir <- getwd()
  temp_dir <- tempfile()
  dir.create(temp_dir, recursive = TRUE)
  file.copy(".", temp_dir, recursive = TRUE)

  on.exit({
    setwd(temp_dir)
    file.copy(".", vig_dir, overwrite = TRUE, recursive = TRUE)
    setwd(vig_dir)
  })

  source_files <- list.files(pattern = "\\.Rmd\\.orig$")
  half_rendered <- gsub("\\.orig$", "", source_files)
  file.rename(source_files, half_rendered)
  pkgdown::build_site(cur_dir)

}
