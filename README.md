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

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}',
          fields = c("patent_number", "patent_title"), endpoint = "patents")
#> $data_results
#> #### A data frame on the patent data level, containing the following columns: patent_number (character), patent_title (character)
#>   patent_number
#> 1       7155746
#> 2       7155747
#> 3       7155748
#> 4       7155749
#>                                                            patent_title
#> 1 Anti-wicking protective workwear and methods of making and using same
#> 2                                               Head stabilizing system
#> 3                                       Releasable toilet seat assembly
#> 4                                    Toilet seat cover dispenser system
#> 
#> 
#> $query_results
#> #### Distinct entity counts across all pages of output:
#> 
#> total_patent_count = 100,000
```

This call to `search_pv` issues our query to the "patents" endpoint. The PatentsView API has 7 different endpoints, corresponding to 7 different entity types.<sup>[1](#enttypes)</sup> Each endpoint has a slightly different set of fields that you can include in your query (e.g., `"patent_date"` in the above query) as well as a different set of fields whose data you can receive from the server (e.g., `"patent_number"` and `"patent_title"`). You can see a list of the acceptable fields for a given endpoint at that endpoint's API documentation page (e.g., the [inventor field list](http://www.patentsview.org/api/inventor.html#field_list)). Also see `?get_fields` for a quick way to put your field list together.

Writing queries
---------------

The PatentsView query syntax is documented on their [API query language page](http://www.patentsview.org/api/query-language.html#query_string_format)<sup>[2](#qrylink)</sup>. With that being said, it can be a bit difficult to get your query right if you're writing it by hand (i.e., just writing the query in a string like `'{"_gte":{"patent_date":"2007-01-01"}}'`). The `patentsview` package comes with a domain specific language to help users write queries. I strongly recommend using this DSL for all but the most basic queries, especially if you're getting errors back from the server and don't understand why. Check out the vignette on [writing queries](vignettes/writing-queries.Rmd) for more details...We can re-write our query using this DSL as:

``` r
qry_funs$gte(patent_date = "2007-01-01")
#> {"_gte":{"patent_date":"2007-01-01"}}
```

More complex queries are also possible:

``` r
with_qfuns(
  and(
    gte(patent_date = "2007-01-01"),
    text_phrase(patent_abstract = c("computer program", "dog leash"))
  )
)
#> {"_and":[{"_gte":{"patent_date":"2007-01-01"}},{"_or":[{"_text_phrase":{"patent_abstract":"computer program"}},{"_text_phrase":{"patent_abstract":"dog leash"}}]}]}
```

Paginated responses
-------------------

By default `search_pv` returns 25 records per page and only the first page of results. I suggest using these defaults while you're in the process of figuring out the details of your request, such as the query syntax you want to use and the fields you want returned. Once you have that finalized, you can then download up to 10,000 records per page using the `per_page` parameter. You can also pick which page of results you want with `page`:

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

If your result set has more than 10,000 records, you can download all pages in one call by setting `all_pages = TRUE`:

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

Entity counts
-------------

Note that we got the `total_patent_count` for the last two calls to `search_pv`, even though we got a lot more data from the second call. This is because the entity counts refer to the number of distinct entities (patents, assignees, inventors, etc.) across all **downloadable pages of output**, not just the one that was returned (e.g., page 2 above). **Downloadable pages of output** is the operative phrase here, as the API limits us to 100,000 records per query. For example, we got `total_patent_count = 100,000` for our first call to `search_pv`, even though there are many more than 100,000 patents that were published after 2007. See the FAQs below for details on how to overcome the 100,000 record restriction.

7 entities for 7 endpoints
--------------------------

what does it mean to search endpoint note list structure of subents note groups value of fields df

FAQ
---

#### I'm sure my query is well formatted and correct but I keep getting an error. What's the deal?

#### Does the API have any rate limiting/throttling controls?

#### How do I download more than 100,000 records?

#### How do I access the data inside of the subentity lists?

Examples
--------

------------------------------------------------------------------------

<a name="enttypes">1</a>: The 7 entity types include assignees, CPC subsections, inventors, locations, NBER subcategories, patents, and USPC main classes. <br> <a name="qrylink">2</a>: Note, this particular webpage includes some details that are not relevant to the `query` argument, such as the field list and sort parameter.
