swap_null_nms <- function(obj) {
  names(obj) <- ifelse(is.null(names(obj)), NA, names(obj))
  obj
}

is_int <- function(x)
  if (is.numeric(x)) abs(x - round(x)) < .Machine$double.eps^0.5 else FALSE

is_date <- function(x) grepl("[12][[:digit:]]{3}-[01][[:digit:]]-[0-3][[:digit:]]", x)

one_check <- function(operator, field, value, f1) {

  if (nrow(f1) == 0)
    paste0_msg(field, " is not a valid field to query")
  if (f1$data_type == "date" && !is_date(value))
    paste0_msg("Bad date: ", value, ". Date must be in the format of yyyy-mm-dd")
  if (f1$data_type %in% c("string", "fulltext") && !is.character(value))
    paste0_msg(value, " must be of type character")
  if (f1$data_type == "integer" && !is_int(value))
    paste0_msg(value, " must be an integer")

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
    ) paste0_msg("You cannot use the operator ", operator, " with field ", field)
}

check_query <- function(query, endpoint) {
  c("_eq", "_neq") -> simp_opr
  c("_gt", "_gte", "_lt", "_lte") -> num_opr
  c("_begins", "_contains") -> str_opr
  c("_text_all", "_text_any", "_text_phrase") -> fltxt_opr
  c(simp_opr, num_opr, str_opr, fltxt_opr) -> all_opr

  fieldsdf -> flds
  flds[flds$endpoint == endpoint & flds$can_query == "y",] -> flds_flt

  apply_checks <- function(x, endpoint) {
    swap_null_nms(x) -> x
    if (names(x) %in% c("_not", "_and", "_or") || is.na(names(x))) {
      lapply(x, FUN = apply_checks)
    } else if (names(x) %in% all_opr) {
      flds_flt[flds_flt$field == names(x[[1]]),] -> f1
      one_check(operator = names(x), field = names(x[[1]]), value = unlist(x[[1]]),
                f1 = f1)
    } else {
      paste0_msg("Bad opeartor: ", names(x))
    }
  }

  apply_checks(x = query, endpoint = endpoint)
  invisible()
}