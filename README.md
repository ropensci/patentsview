patentsview
================

> An R client to the PatentsView API

[![](http://badges.ropensci.org/112_status.svg)](https://github.com/ropensci/software-review/issues/112)
[![R-CMD-check](https://github.com/ropensci/patentsview/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/patentsview/actions)
[![CRAN
version](http://www.r-pkg.org/badges/version/patentsview)](https://cran.r-project.org/package=patentsview)
[![runiverse-package](https://ropensci.r-universe.dev/badges/patentsview)](https://ropensci.r-universe.dev/patentsview)

## Installation

You can get the stable version from CRAN:

``` r
install.packages("patentsview")
```

### Development version

To get a bug fix or to use a feature from the development version, you
can install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("ropensci/patentsview")
```

## Basic usage

The [PatentsView
API](https://search.patentsview.org/docs/docs/Search%20API/SearchAPIReference/)
provides an interface to a disambiguated version of USPTO. The
`patentsview` R package provides one main function, `search_pv()`, to
make it easy to interact with the API:

``` r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}')
#> $data
#> #### A list with a single data frame on patents level:
#> 
#> List of 1
#>  $ patents:'data.frame': 1000 obs. of  1 variable:
#>   ..$ patent_id: chr [1:1000] "10000000" ...
#> 
#> $query_results
#> #### Distinct entity counts across all downloadable pages of output:
#> 
#> total_hits = 5,815,634
```

## Learning more

Head over to the package’s
[webpage](https://docs.ropensci.org/patentsview/index.html) for more
info, including:

-   A [getting started
    vignette](https://docs.ropensci.org/patentsview/articles/getting-started.html)
    for first-time users. The package was also introduced in an
    [rOpenSci blog
    post](https://docs.ropensci.org/patentsview/articles/ropensci-blog-post.html),
    rewritten for the new version of the API.
-   An in-depth tutorial on [writing
    queries](https://docs.ropensci.org/patentsview/articles/writing-queries.html)
-   A list of [basic
    examples](https://docs.ropensci.org/patentsview/articles/examples.html)
-   Two examples of data applications (e.g., a brief analysis of the
    [top
    assignees](https://docs.ropensci.org/patentsview/articles/top-assignees.html)
    in the field of databases)
