patentsview
===========

> An R client to the PatentsView API

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![Linux Build Status](https://travis-ci.org/crew102/patentsview.svg?branch=master)](https://travis-ci.org/crew102/patentsview) <!-- [![Windows Build status](https://ci.appveyor.com/api/projects/status/github/crew102/patentsview?svg=true)](https://ci.appveyor.com/project/crew102/patentsview) --> [![](http://www.r-pkg.org/badges/version/patentsview)](http://www.r-pkg.org/pkg/patentsview)

Installation
------------

``` r
devtools::install_github("crew102/patentsview")
```

Basic usage
-----------

The [PatentsView API](http://www.patentsview.org/api/doc.html) provides an interface to a disambiguated version of USPTO patent data. The `patentsview` R package provides one function, `search_pv` to make it easy to interact with that API. Let's take a look:

``` r
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-04"}}',
          fields = c("patent_number", "patent_title"), endpoint = "patents")
#> $data_results
#> #### A data frame on the patent data level, containing the following columns: patent_number (character), patent_title (character)
#>   patent_number                                       patent_title
#> 1       7159246                    Glove with high tactile portion
#> 2       7159247                     Cap having a flexible headband
#> 3       7159248                Head covering with attached whistle
#> 4       7159249 Self-balancing, load-distributing helmet structure
#> 
#> 
#> $query_results
#> #### Distinct entity counts across all pages of output:
#> 
#> total_patent_count = 100,000
```

This call to `search_pv` issues our query to the "patents" endpoint. The PatentsView API has 7 different endpoints, corresponding to 7 different entity types.[1] Each endpoint has a slightly different set of fields that you can include in your query (e.g., `"patent_date"` in the above query) as well as a different set of fields whose data you can receive from the server (e.g., `"patent_number"` and `"patent_title"`). You can see a list of the acceptable field for the 7 endpoints at the PatentsView webpage. For example, the field list for the inventors endpoint is listed [here](herehttp://www.patentsview.org/api/inventor.html#field_list).

Writing queries
---------------

The PatentsView query syntax is documented on their [site](http://www.patentsview.org/api/query-language.html#query_string_format)[2]. With that being said, it can be a bit difficult to get your query right if you're writing it by hand (i.e., just writing the query in a string like `'{"_gte":{"patent_date":"2007-01-04"}}'`). The `patentsview` package comes with a domain specific language to help users write queries. I strongly recommend using this DSL for all but the most basic queries, especially if you're getting errors from the API. Check out the vignette ![Writing queries](vignettes/writing-queries.Rmd) for more details. We can re-write our query using this DSL as:

``` r
qry_funs$gte(patent_date = "2007-01-04")
#> {"_gte":{"patent_date":"2007-01-04"}}
```

Paginated responses
-------------------

By default `search_pv` returns only the first page of results and gives you 25 records per page. I suggest calling the function once with this setting to make sure you are getting the data you want before increasing the number of records per page. When you are confident that you are getting the data that you want, you can download up to 10,000 records per page using the `per_page` parameter. You can also pick which page of results you want with the `page` parameter: s

``` r
search_pv(query = qry_funs$eq(inventor_last_name = "chambers"),
          page = 2, per_page = 150) # gets records 150 - 300
#> $data_results
#> #### A data frame on the patent data level, containing the following columns: patent_id (character), patent_number (character), patent_title (character)
#>   patent_id patent_number                                  patent_title
#> 1   4408568       4408568            Furnace wall ash monitoring system
#> 2   4416662       4416662                     Roller infusion apparatus
#> 3   4425825       4425825 Geared input mechanism for a torque converter
#> 4   4431312       4431312                         Radio alarm converter
#> 
#> 
#> $query_results
#> #### Distinct entity counts across all pages of output:
#> 
#> total_patent_count = 1,812
```

We can also just set `all_pages = TRUE` to download all possible pages of output:

``` r
search_pv(query = qry_funs$gte(patent_date = "2007-01-04"), all_pages = TRUE)
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

7 entities for 7 endpoints
--------------------------

FAQ
---

<!-- * Note on 10,000 limit -->
<!-- * Note on API being unpred  -->
Examples
--------

[1] The 7 entity types include assignees, CPC subsections, inventors, locations, NBER subcategories, patents, and USPC main classes.

[2] Note, this page includes details that are not relevant to the `query` argument, such as the field list and sort parameter.
