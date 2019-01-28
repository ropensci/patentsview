# patentsview 0.2.2 (2019-01-23)

#### Misc

* Vignettes removed from package so that CRAN builds don't fail when API is down

# patentsview 0.2.1 (2018-03-05)

#### Misc

* Examples that hit the API were wrapped in `\dontrun{}` so CRAN doesn't request fixes to package when API is down

# patentsview 0.2.0 (2018-02-08)

#### New features

* `cast_pv_data()` function added to convert the data types of the data returned by `search_pv()`
* Additional fields added to the API (e.g., fields starting with `forprior_`, `examiner_`)

#### Misc

* Additional error handler added for the locations endpoint (@mustberuss, #11)
* `error_browser` option has been deprecated

# patentsview 0.1.0 (2017-05-01)

#### New functions

* `search_pv` added to send requests to the PatentsView API
* `qry_funs` list added with functions to help users write queries
* `get_fields` and `get_endpoints` added to quickly get possible field names and endpoints, respectively
* `unnest_pv_data` added to unnest the data frames in the returned data
