#' @noRd
validate_endpoint <- function(endpoint) {
  ok_ends <- get_endpoints()
  asrt(
    all(endpoint %in% ok_ends, length(endpoint) == 1),
    "endpoint must be one of the following: ", paste(ok_ends, collapse = ", ")
  )
}

#' @noRd
validate_args <- function(api_key, fields, endpoint, method, page, per_page,
                          sort) {
  asrt(
    !identical(api_key, ""),
    "The new version of the API requires an API key"
  )

  flds_flt <- fieldsdf[fieldsdf$endpoint == endpoint, "field"]
  asrt(
    all(fields %in% flds_flt),
    "Bad field(s): ", paste(fields[!(fields %in% flds_flt)], collapse = ", ")
  )

  validate_endpoint(endpoint)

  asrt(
    all(method %in% c("GET", "POST"), length(method) == 1),
    "method must be either 'GET' or 'POST'"
  )
  asrt(
    all(is.numeric(page), length(page) == 1, page >= 1),
    "page must be a numeric value greater than 1"
  )
  asrt(
    all(is.numeric(per_page), length(per_page) == 1, per_page <= 1000),
    "per_page must be a numeric value less than or equal to 1,000"
  )
  if (!is.null(sort))
    asrt(
      all(
        all(names(sort) %in% fields), all(sort %in% c("asc", "desc")),
          !is.list(sort)),
      "sort has to be a named character vector and each name has to be ",
      "specified in the field argument. See examples"
    )
}

#' @noRd
validate_groups <- function(groups) {
  ok_grps <- unique(fieldsdf$group)
  asrt(
    all(groups %in% ok_grps),
    "group must be one of the following: ", paste(ok_grps, collapse = ", ")
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
deprecate_warn_all <- function(error_browser, subent_cnts, mtchd_subent_only) {
  if (!is.null(error_browser)) {
    lifecycle::deprecate_warn(when = "0.2.0", what = "search_pv(error_browser)")
  }
  # Was previously defaulting to FALSE and we're still defaulting to FALSE to
  # mirror the fact that the API doesn't support subent_cnts. Warn only if user
  # tries to set subent_cnts to TRUE.
  if (isTRUE(subent_cnts)) {
    lifecycle::deprecate_warn(
      when = "1.0.0",
      what = "search_pv(subent_cnts)",
      details = "The new version of the API does not support subentity counts."
    )
  }
  # Was previously defaulting to TRUE and now we're defaulting to FALSE, hence
  # we're being more chatty here than with subent_cnts.
  if (lifecycle::is_present(mtchd_subent_only)) {
    lifecycle::deprecate_warn(
      when = "1.0.0",
      what = "search_pv(mtchd_subent_only)",
      details = "Non-matched subentities will always be returned under the new
      version of the API"
    )
  }
}