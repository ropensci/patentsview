# patentsview (development version)

### New features

* The base URL of the API can be set with `options(patentsview.base_url = )` or the
  environment variable `PATENTSVIEW_BASE_URL` (scheme and host, for example
  `https://search.patentsview.org`, the default), so the package can query any
  service that answers the PatentSearch API. The option wins over the variable.

# patentsview 1.0.0

### Breaking changes

* **API key required**: The new API requires authentication. Request a key at <https://patentsview-support.atlassian.net/servicedesk/customer/portals> and set `PATENTSVIEW_API_KEY` environment variable.

* **Endpoint changes**: Now 27 endpoints (up from 7). Endpoints are singular (e.g., `patent` not `patents`). The `nber_subcategory` endpoint was removed; `cpc_subsection` is now `cpc_group`.

* **Field changes**: `patent_number` is now `patent_id`. Raw inventor name fields (`rawinventor_first_name`, `rawinventor_last_name`) were removed. Some fields are now nested and require full qualification in queries (e.g., `cpc_current.cpc_group_id`).

* **Paging parameters changed**: `per_page`/`page` replaced by `size`/`after`. Maximum `size` is 1,000 (was 10,000). Result sets are now unbounded (was capped at 100,000).

* **httr to httr2 migration**: If you passed `config = httr::timeout(40)`, now use `timeout = 40` directly.

* **`cast_pv_data()` removed**: The API now returns proper types (boolean, numeric, etc.) instead of strings.

### New features

* `retrieve_linked_data()` fetches data from HATEOAS links returned by the API
* All fields are now queryable (previously some fields could only be returned, not queried)
* Group name shorthand for fields: `fields = "assignees"` returns all assignee fields
* API throttling handled automatically (45 requests/minute limit)

### New vignettes

* "API Changes" - comprehensive guide to migrating from the old API
* "Converting an Existing Script" - practical migration examples
* "Result Set Paging" - explains new paging mechanism
* "Understanding the API" - converted from PatentsView's Jupyter notebook

### Internal

* Tests now use vcr for HTTP mocking, improving speed and reliability
* `unnest_pv_data()` handles empty API results without crashing
* Paging structure mismatch now throws an error instead of warning (prevents confusing `rbind` failures)
* Live API tests skip by default; enable with `PATENTSVIEW_LIVE_TESTS=true`

# patentsview 0.3.0 (2021-09-03)

#### Misc

* The package is now using the new HTTPS endpoints (#17)
* The list of queryable fields was updated
* `with_qfuns()` now find objects in the calling environment (@jcheng5, #20)
* Vignettes are being pre-computed (#23)
* An issue was fixed where query strings weren't being properly URL-encoded (#24)
* Adhoc logic was added to handle API throttling

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
