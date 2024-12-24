#' @noRd
swap_null_nms <- function(obj) {
  names(obj) <- ifelse(is.null(names(obj)), NA, names(obj))
  obj
}

#' @noRd
is_int <- function(x)
  if (is.numeric(x)) abs(x - round(x)) < .Machine$double.eps^ 0.5 else FALSE

#' @noRd
is_date <- function(x)
  grepl("^[12][[:digit:]]{3}-[01][[:digit:]]-[0-3][[:digit:]]$", x)

#' @noRd
one_check <- function(operator, field, value, f1) {
  if (nrow(f1) == 0)
    stop2(field, " is not a valid field to query for your endpoint")
  if (f1$data_type == "date" && !is_date(value))
    stop2("Bad date: ", value, ". Date must be in the format of yyyy-mm-dd")
  if (f1$data_type %in% c("bool", "int", "string", "fulltext") && !is.character(value))
    stop2(value, " must be of type character")
  if (f1$data_type == "integer" && !is_int(value))
    stop2(value, " must be an integer")
  if (f1$data_type == "boolean" && !is.logical(value))
    stop2(value, " must be a boolean")
  if (f1$data_type == "number" && !is.numeric(value))
    stop2(value, " must be a number")

  if (
    # The new version of the API blurrs the distinction between string/fulltext fields.
    # It looks like the string/fulltext functions can be used interchangeably
    (operator %in% c("_begins", "_contains", "_text_all", "_text_any", "_text_phrase") &&
      !(f1$data_type == "fulltext" || f1$data_type == "string")) ||
      (f1$data_type %in% c("string", "fulltext") &&
        operator %in% c("_gt", "_gte", "_lt", "_lte"))) {
    stop2("You cannot use the operator ", operator, " with the field ", field)
  }
}

#' @noRd
check_query <- function(query, endpoint) {
  simp_opr <- c("_eq", "_neq")
  num_opr <- c("_gt", "_gte", "_lt", "_lte")
  str_opr <- c("_begins", "_contains")
  fltxt_opr <- c("_text_all", "_text_any", "_text_phrase")
  all_opr <- c(simp_opr, num_opr, str_opr, fltxt_opr, "_in_range")

  flds_flt <- fieldsdf[fieldsdf$endpoint == endpoint, ]

  apply_checks <- function(x, endpoint) {
    x <- swap_null_nms(x)

    # troublesome next line:  'length(x) = 2 > 1' in coercion to 'logical(1)'
    # if (names(x) %in% c("_not", "_and", "_or") || is.na(names(x))) {
    if (length(names(x)) > 1 || names(x) %in% c("_not", "_and", "_or") || is.na(names(x))) {
      lapply(x, FUN = apply_checks)
    } else if (names(x) %in% all_opr) {
      f1 <- flds_flt[flds_flt$field == names(x[[1]]), ]
      one_check(
        operator = names(x), field = names(x[[1]]),
        value = unlist(x[[1]]), f1 = f1
      )
    } else if (names(x) %in% flds_flt$field) {
      message(
        "The _eq operator is a safer alternative to using ",
        "field:value pairs or value arrays in your query"
      )
    } else {
      stop2(
        names(x), " is not a valid operator or not a ",
        "valid field for this endpoint"
      )
    }
  }

  apply_checks(query, endpoint = endpoint)
  invisible()
}
