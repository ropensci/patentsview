patentsview
================

> An R Client to the PatentsView API

[![Linux Build Status](https://travis-ci.org/ropensci/patentsview.svg?branch=master)](https://travis-ci.org/ropensci/patentsview) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/ropensci/patentsview?branch=master&svg=true)](https://ci.appveyor.com/project/ropensci/patentsview)

Installation
------------

``` r
devtools::install_github("ropensci/patentsview")
```

Basic usage
-----------

The [PatentsView API](http://www.patentsview.org/api/doc.html) provides an interface to a disambiguated version of USPTO. The `patentsview` R package provides one main function, `search_pv()`, to make it easy to interact with that API:

``` r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}',
          endpoint = "patents")
#> $data
#> #### A list with a single data frame on the patent data level:
#> 
#> List of 1
#>  $ patents:'data.frame': 25 obs. of  3 variables:
#>   ..$ patent_id    : chr [1:25] "7155746" ...
#>   ..$ patent_number: chr [1:25] "7155746" ...
#>   ..$ patent_title : chr [1:25] "Anti-wicking protective workwear and methods of making and using same" ...
#> 
#> $query_results
#> #### Distinct entity counts across all downloadable pages of output:
#> 
#> total_patent_count = 100,000
```

Learning more
-------------

Head over to the package's [webpage](https://ropensci.github.io/patentsview/index.html) for more info, including:

-   A [getting started vignette](http://ropensci.github.io/patentsview/articles/getting-started.html) for first-time users
-   An in-depth tutorial on [writing queries](http://ropensci.github.io/patentsview/articles/writing-queries.html)
-   A list of [examples](http://ropensci.github.io/patentsview/articles/examples.html)
-   WIP: Data applications (e.g., discovering the [top assignees](http://ropensci.github.io/patentsview/articles/assignees.html) in the field of databases)