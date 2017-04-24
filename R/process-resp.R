#' @noRd
get_request <- function(resp) {
  gp <- structure(
    list(
      method = resp$req$method,
      url = resp$req$url
    ),
    class = c("list", "pv_request")
  )

  if (gp$method == "POST")
    gp$body <- rawToChar(resp$req$options$postfields)

  gp
}

#' @noRd
get_data <- function(prsd_resp) {
  structure(
    list(prsd_resp[[1]]),
    names = names(prsd_resp[1]),
    class = c("list", "pv_data_result")
  )
}

#' @noRd
get_query_results <- function(prsd_resp) {
  structure(
    prsd_resp[grepl("_count", names(prsd_resp))],
    class = c("list", "pv_query_result")
  )
}

#' @noRd
process_resp <- function(resp) {
  prsd_resp <- parse_resp(resp = resp)

  request <- get_request(resp = resp)
  data <- get_data(prsd_resp = prsd_resp)
  query_results <- get_query_results(prsd_resp = prsd_resp)

  structure(
    list(
      data = data,
      query_results = query_results,
      request = request
    ),
    class = c("list", "pv_result")
  )
}