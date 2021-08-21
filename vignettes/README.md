Notes about these vignettes:

* They aren't included in the R package by nature of the fact that the vignettes directory is included in .Rbuildignore. Instead, I just point to the site in the R documentation.
* They mostly follow the pattern described here: https://ropensci.org/blog/2019/12/08/precompute-vignettes/
  - Files ending in .Rmd.orig are the original, totally unrendered RMarkdown files
  - Files ending in .Rmd are the half-rendered RMarkdown files. Basically we pre-compute the vignettes by rendering the .Rmd.orig files to .Rmd files (see the half_render_vignettes() for details on how this happens). This creates .Rmd docs where the R outputs are already computed and embedded in the .Rmd files. These .Rmd files get further rendered during ROpenSci's automated site builds.
  - The exception to following the pattern described in the ROpenSci post is that, when the pkgdown site is built locally (and all of the artifacts from that build placed in docs/), we don't rely on the rendered vignettes that end in .Rmd. If we did, we wouldn't be able to include HTML artifacts/dependencies easily in the site. Instead, we rename files at build time so that pkgdown ends up using the Rmd.orig files instead of the .Rmd files when it builds the site. See build_site_locally() for details on how this happens.
