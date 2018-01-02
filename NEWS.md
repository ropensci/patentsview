# patentsview 0.2.0 (2018-01-01)

#### New features

* `cast_pv_data()` function added to convert the data types of the data returned by `search_pv()`
* Additional fields were added to the API (e.g., fields starting with `forprior_`, `examiner_`)

#### Misc

* Additional error handler added for the locations endpoint (@mustberuss, #11)
* `error_browser` option has been deprecated

# patentsview 0.1.0 (2017-05-01)

#### New functions

* `search_pv` added to send requests to the PatentsView API
* `qry_funs` list added with functions to help users write queries
* `get_fields` and `get_endpoints` added to quickly get possible field names and endpoints, respectively
* `unnest_pv_data` added to unnest the data frames in the returned data