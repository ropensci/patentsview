#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()
  asrt(
    all(endpoint %in% ok_ends, length(endpoint) == 1),
    "endpoint must be one of the following: ", paste(ok_ends, collapse = ", ")
  )
}

#' @noRd
validate_args <- function(api_key, fields, endpoint, method,
                          sort, after, size, all_pages, exclude_withdrawn) {
  asrt(
    !identical(api_key, ""),
    "The new version of the API requires an API key"
  )

  validate_endpoint(endpoint)

  flds_flt <- fieldsdf[fieldsdf$endpoint == endpoint, "field"]

  # Now the API allows the group name to be requested as in fields to get all of
  # the group's nested fields.  ex.: "assignees" on the patent endpoint gets you all
  # of the assignee fields. Note that "patents" can't be requested
  groups <- unique(fieldsdf[fieldsdf$endpoint == endpoint, c("group")])
  first_pk <- get_ok_pk(endpoint)[[1]]
  plural_entity <- fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$field == first_pk, "group"]
  flds_flt <- append(flds_flt, groups[!groups == plural_entity])

  asrt(
    all(fields %in% flds_flt),
    "Bad field(s): ", paste(fields[!(fields %in% flds_flt)], collapse = ", ")
  )

  asrt(
    all(method %in% c("GET", "POST"), length(method) == 1),
    "method must be either 'GET' or 'POST'"
  )

  asrt(
    all(is.numeric(size), length(size) == 1, size <= 1000),
    "size must be a numeric value less than or equal to 1,000"
  )

  # Removed all(names(sort) %in% fields) Was it our requirement or the API's?
  # It does seem to work when we don't request fields and rely on the API to sort
  # using them.
  if (!is.null(sort)) {
    asrt(
      all(
        all(sort %in% c("asc", "desc")),
        !is.list(sort)
      ),
      "sort has to be a named character vector.  See examples"
    )
  }

  asrt(
    any(is.null(after), !all_pages),
    "'after' cannot be set when all_pages = TRUE"
  )

  asrt(
    !all(!is.null(exclude_withdrawn), !is.logical(exclude_withdrawn)),
    "'exclude_withdrawn' must be NULL or a boolean"
  )
}

#' @noRd
validate_groups <- function(endpoint, groups) {
  ok_grps <- unique(fieldsdf[fieldsdf$endpoint == endpoint, "group"])

  asrt(
    all(groups %in% ok_grps),
    "for the ", endpoint, " endpoint, group must be one of the following: ",
    paste(ok_grps, collapse = ", ")
  )
}

#' @noRd
validate_pv_data <- function(data) {
  asrt(
    "pv_data_result" %in% class(data),
    "Wrong input type for data...See example for correct input type"
  )
}

#' @noRd
deprecate_warn_all <- function(error_browser, subent_cnts, mtchd_subent_only,
                               page, per_page) {
  if (lifecycle::is_present(error_browser)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "search_pv(error_browser)",
      details = "The error_browser is no longer supported"
    )
  }
  if (lifecycle::is_present(subent_cnts)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "search_pv(subent_cnts)",
      details = "The new version of the API does not support subentity counts."
    )
  }
  if (lifecycle::is_present(mtchd_subent_only)) {
    lifecycle::deprecate_warn(
      when = "0.3.0",
      what = "search_pv(mtchd_subent_only)",
      # TODO(0): is this true?
      details = "Non-matched subentities will always be returned under the new
      version of the API"
    )
  }
  if (lifecycle::is_present(per_page)) {
    lifecycle::deprecate_warn(
      when = "1.0.0",
      what = "search_pv(per_page)",
      details = "The new version of the API uses 'size' instead of 'per_page'",
      with = "search_pv(size)"
    )
  }
  if (lifecycle::is_present(page)) {
    lifecycle::deprecate_warn(
      when = "1.0.0",
      what = "search_pv(page)",
      details = "The new version of the API does not support the page parameter"
    )
  }
}
