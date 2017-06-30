#' @noRd
swap_null_nms <- function(obj) {
  names(obj) <- ifelse(is.null(names(obj)), NA, names(obj))
  obj
}

#' @noRd
is_int <- function(x)
  if (is.numeric(x)) abs(x - round(x)) < .Machine$double.eps^0.5 else FALSE

#' @noRd
is_date <- function(x)
  grepl("[12][[:digit:]]{3}-[01][[:digit:]]-[0-3][[:digit:]]", x)

#' @noRd
one_check <- function(operator, field, value, f1) {

  if (nrow(f1) == 0)
    paste0_stop(field, " is not a valid field to query for your endpoint")
  if (f1$data_type == "date" && !is_date(value))
    paste0_stop("Bad date: ", value,
                ". Date must be in the format of yyyy-mm-dd")
  if (f1$data_type %in% c("string", "fulltext") && !is.character(value))
    paste0_stop(value, " must be of type character")
  if (f1$data_type == "integer" && !is_int(value))
    paste0_stop(value, " must be an integer")

  if (
      (
        operator %in% c("_begins", "_contains") && !(f1$data_type == "string")
      ) ||
      (
        operator %in% c("_text_all", "_text_any", "_text_phrase") &&
        !(f1$data_type == "fulltext")
      ) ||
      (
        f1$data_type %in% c("string", "fulltext") &&
        operator %in% c("_gt", "_gte", "_lt", "_lte")
      )
    ) paste0_stop("You cannot use the operator ", operator,
                  " with the field ", field)
}

#' @noRd
check_query <- function(query, endpoint) {
  simp_opr <- c("_eq", "_neq")
  num_opr <- c("_gt", "_gte", "_lt", "_lte")
  str_opr <- c("_begins", "_contains")
  fltxt_opr <- c("_text_all", "_text_any", "_text_phrase")
  all_opr <- c(simp_opr, num_opr, str_opr, fltxt_opr)

  flds <- patentsview::fieldsdf
  flds_flt <- flds[flds$endpoint == endpoint & flds$can_query == "y", ]

  apply_checks <- function(x, endpoint) {
    x <- swap_null_nms(x)
    if (names(x) %in% c("_not", "_and", "_or") || is.na(names(x))) {
      lapply(x, FUN = apply_checks)
    } else if (names(x) %in% all_opr) {
      f1 <- flds_flt[flds_flt$field == names(x[[1]]), ]
      one_check(operator = names(x), field = names(x[[1]]),
                value = unlist(x[[1]]), f1 = f1)
    } else if (names(x) %in% flds_flt$field) {
      paste0_msg("The _eq operator is a safer alternative to using ",
                 "field:value pairs or value arrays in your query")
    } else {
      paste0_stop(names(x), " is either not a valid operator or not a ",
                  "queryable field for this endpoint")
    }
  }

  apply_checks(x = query, endpoint = endpoint)
  invisible()
}