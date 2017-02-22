patentsview
===========

> An R client to the PatentsView API

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![Linux Build Status](https://travis-ci.org/crew102/patentsview.svg?branch=master)](https://travis-ci.org/crew102/patentsview) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/crew102/patentsview?branch=master&svg=true)](https://ci.appveyor.com/project/crew102/patentsview) [![](http://www.r-pkg.org/badges/version/patentsview)](http://www.r-pkg.org/pkg/patentsview)

Installation
------------

``` r
devtools::install_github("crew102/patentsview")
```

Basic usage
-----------

The [PatentsView API](http://www.patentsview.org/api/doc.html) provides an interface to a disambiguated version of USPTO patent data. The `patentsview` R package provides one function, `search_pv`, to make it easy to interact with that API. Let's take a look:

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

This call to `search_pv` issues our query to the "patents" endpoint. The PatentsView API has 7 different endpoints, corresponding to 7 different entity types.<sup>[1](#enttypes)</sup> Each endpoint has a slightly different set of fields that you can include in your query (e.g., `"patent_date"` in the above query) as well as a different set of fields whose data you can receive from the server (e.g., `"patent_number"` and `"patent_title"`). You can see a list of the acceptable field for the 7 endpoints at the PatentsView webpage. For example, the field list for the inventors endpoint is listed [here](herehttp://www.patentsview.org/api/inventor.html#field_list).

Writing queries
---------------

The PatentsView query syntax is documented on their [site](http://www.patentsview.org/api/query-language.html#query_string_format)<sup>[2](#qrylink)</sup>. With that being said, it can be a bit difficult to get your query right if you're writing it by hand (i.e., just writing the query in a string like `'{"_gte":{"patent_date":"2007-01-04"}}'`). The `patentsview` package comes with a domain specific language to help users write queries. I strongly recommend using this DSL for all but the most basic queries, especially if you're getting errors back and don't understand why. Check out the vignette on [writing queries](vignettes/writing-queries.Rmd) for more details...We can re-write our query using this DSL as:

``` r
qry_funs$gte(patent_date = "2007-01-04")
#> {"_gte":{"patent_date":"2007-01-04"}}
```

...More complex queries are also possible:

``` r
with_qfuns(
  and(
    gte(patent_date = "2007-01-04"),
    text_any(patent_abstract = c("dog", "cat"))
  )
)
#> {"_and":[{"_gte":{"patent_date":"2007-01-04"}},{"_or":[{"_text_any":{"patent_abstract":"dog"}},{"_text_any":{"patent_abstract":"cat"}}]}]}
```

Paginated responses
-------------------

By default `search_pv` returns 25 records per page and only the first page. I suggest using these defaults while you're in the process of figuring out the details of your request, such as the query syntax you want to use and the fields you want returned. Once you ahve that finalized, you can then download up to 10,000 records per page using the `per_page` parameter. You can also pick which page of results you want with `page`:

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

If your result set has more than 10,000 records, you can download all pages of data in one call by setting `all_pages = TRUE`:

``` r
search_pv(query = qry_funs$eq(inventor_last_name = "chambers"),
          all_pages = TRUE) # all_pages = TRUE sets per_page = 10,000 and downloads all pages of output
#> $data_results
#> #### A data frame on the patent data level, containing the following columns: patent_id (character), patent_number (character), patent_title (character)
#>   patent_id patent_number
#> 1   3931611       3931611
#> 2   3934732       3934732
#> 3   3934883       3934883
#> 4   3934997       3934997
#>                                        patent_title
#> 1 Program event recorder and data processing system
#> 2                           Object transfer machine
#> 3                                Disk record player
#> 4 Production of one-piece stemware from glass, etc.
#> 
#> 
#> $query_results
#> #### Distinct entity counts across all pages of output:
#> 
#> total_patent_count = 1,812
```

Note that `total_patent_count` is equal in the two last calls to `search_pv`, even though we got a lot more data from the second call. This is becuase the entity counts found the in `query_results` element correspond to counts across all possible pages of output, not just the one you downloaded.

7 entities for 7 endpoints
--------------------------

note list structure of subents note groups value of fields df

FAQ
---

#### I'm sure my query is well formatted and correct but I keep getting an error. What's the deal?

#### Does the API have any rate limiting/throttling controls?

#### Some of my queries have result sets of 100,000 records, but I'm sure there are more out there. What's going on?

Examples
--------

------------------------------------------------------------------------

<a name="enttypes">1</a>: The 7 entity types include assignees, CPC subsections, inventors, locations, NBER subcategories, patents, and USPC main classes. <br> <a name="qrylink">2</a>: Note, this particular webpage includes details that are not relevant to the `query` argument, such as the field list and sort parameter.
