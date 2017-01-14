validate_args <- function(query, fields, endpoint, method, subent_cnts,
                          mtchd_subent_only, page, per_page, sort) {

  c("patents", "inventors", "assignees", "locations",
    "cpc_subsections", "uspc_mainclasses", "nber_subcategories") -> ok_ends
  c("GET", "POST") -> ok_meth

  asrt(all(endpoint %in% ok_ends, length(endpoint) == 1),
       "endpoint must be a length 1 vector and be one of: ",
              paste(ok_ends, collapse = ", "))
  asrt(all(method %in% ok_meth, length(method) == 1),
       "method must be a length 1 vector and be one of: ",
              paste(ok_meth, collapse = ", "))

  asrt(all(is.logical(subent_cnts), length(subent_cnts) == 1),
       "subent_cnts must be either TRUE or FALSE")
  asrt(all(is.logical(mtchd_subent_only), length(mtchd_subent_only) == 1),
       "mtchd_subent_only must be either TRUE or FALSE")

  asrt(all(is.numeric(page), length(page) == 1, page >= 1, page <= 10000),
       "page must be a length 1 numeric vector between 1 and 10,000")
  asrt(all(is.numeric(per_page), length(per_page) == 1),
       "per_page must be a length 1 numeric vector")

  if (!is.null(sort))
    asrt(all(all(names(sort) %in% fields), all(sort %in% c("asc", "desc")), !is.list(sort)),
         "sort has to be a named character vector and each name has to be ",
         "specified in the field argument. See examples")

  asrt(jsonlite::validate(query), "query is not valid json.")
}