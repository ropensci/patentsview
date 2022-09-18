#' @noRd
parse_resp <- function(resp) {
  j <- httr::content(resp, as = "text", encoding = "UTF-8")
  jsonlite::fromJSON(
    j,
    simplifyVector = TRUE, simplifyDataFrame = TRUE, simplifyMatrix = TRUE
  )
}

#' @noRd
get_request <- function(resp) {
  gp <- structure(
    list(method = resp$req$method, url = resp$req$url),
    class = c("list", "pv_request")
  )

  if (gp$method == "POST") {
    gp$body <- rawToChar(resp$req$options$postfields)
  }

  gp
}

#' @noRd
get_data <- function(prsd_resp) {
  structure(
    list(prsd_resp[[4]]),
    names = names(prsd_resp[4]),
    class = c("list", "pv_data_result")
  )
}

#' @noRd
# There used to be an endpoint specific _count ex total_assignee_count
# Now all endpoints return a total_hits attribute
get_query_results <- function(prsd_resp) {
  structure(
    prsd_resp["total_hits"],
    class = c("list", "pv_query_result")
  )
}

#' @noRd
process_resp <- function(resp) {
  if (httr::http_error(resp)) throw_er(resp)

  prsd_resp <- parse_resp(resp)
  request <- get_request(resp)
  data <- get_data(prsd_resp)
  query_results <- get_query_results(prsd_resp)

  structure(
    list(
      data = data,
      query_results = query_results,
      request = request
    ),
    class = c("list", "pv_result")
  )
}
