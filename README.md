<!-- Formatting of this README was inspired by gaborcsardi's httrmock README -->



# patentsview

> An R client to the PatentsView API

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
<!-- [![Linux Build Status](https://travis-ci.org/crew102/patentsview.svg?branch=master)](https://travis-ci.org/crew102/patentsview) -->
<!-- [![Windows Build status](https://ci.appveyor.com/api/projects/status/github/crew102/patentsview?svg=true)](https://ci.appveyor.com/project/crew102/patentsview) -->
<!-- [![](http://www.r-pkg.org/badges/version/patentsview)](http://www.r-pkg.org/pkg/patentsview) -->

## Installation


```r
devtools::install_github("crew102/patentsview")
```

## Usage 

The [PatentsView API](http://www.patentsview.org/api/doc.html) provides 7 endpoints that users can download patent-related data from. The `patentsview` R package provides one function, `search_pv` to make it easy to interact with those endpoints. Let's take a look:


```r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-04"}}')
#> $data_results
#> #### A data frame on the patent data level, containing the following columns: patent_id (character), patent_number (character), patent_title (character)
#>   patent_id patent_number
#> 1   7159246       7159246
#> 2   7159247       7159247
#> 3   7159248       7159248
#> 4   7159249       7159249
#>                                         patent_title
#> 1                    Glove with high tactile portion
#> 2                     Cap having a flexible headband
#> 3                Head covering with attached whistle
#> 4 Self-balancing, load-distributing helmet structure
#> 
#> 
#> $query_results
#> #### Distinct entity counts across all pages of output:
#> 
#> total_patent_count = 100,000
```
