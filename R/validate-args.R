validate_args <- function(query, fields, endpoint, method, subent_cnts,
                          mtchd_subent_only, page, per_page, sort) {

  c("GET", "POST") -> ok_meth

  validate_endpoint(endpoint = endpoint)
  asrt(all(method %in% ok_meth, length(method) == 1),
       "method must be either 'GET' or 'POST'")

  asrt(all(is.logical(subent_cnts), length(subent_cnts) == 1),
       "subent_cnts must be either TRUE or FALSE")
  asrt(all(is.logical(mtchd_subent_only), length(mtchd_subent_only) == 1),
       "mtchd_subent_only must be either TRUE or FALSE")

  asrt(all(is.numeric(page), length(page) == 1, page >= 1),
       "page must be a length 1 numeric vector greater than 1")
  asrt(all(is.numeric(per_page), length(per_page) == 1, per_page <= 10000),
       "per_page must be a length 1 numeric vector less than or equal to 10,000")

  if (!is.null(sort))
    asrt(all(all(names(sort) %in% fields), all(sort %in% c("asc", "desc")), !is.list(sort)),
         "sort has to be a named character vector and each name has to be ",
         "specified in the field argument. See examples")

  asrt(jsonlite::validate(query), "query is not valid json.")

  fieldsdf -> flds
  flds[flds$endpoint == endpoint, "field"] -> flds_flt
  asrt(all(fields %in% flds_flt),
       "Bad field(s): ",
       paste(fields[!(fields %in% flds_flt)], collapse = ", "))
}