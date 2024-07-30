context("throttle")

# Below we request the same data in built_singly and result_all, with the only
# difference being that we intentionally get throttled in built_singly by
# sending one request per patent number (instead of all requests at once). If
# the two responses match, then we've correctly handled throttling errors.
test_that("Throttled requests are automatically retried", {
  skip_on_cran()

  res <- search_pv('{"_gte":{"patent_date":"2008-01-04"}}', per_page = 50)
  patent_ids <- res$data$patents$patent_id

  expect_message(
    built_singly <- lapply(patent_ids, function(patent_id) {
      search_pv(
        query = qry_funs$eq(patent_id = patent_id),
        endpoint = "patent/us_patent_citations",
        fields = c("patent_id", "citation_patent_id"),
        sort = c("citation_patent_id" = "asc")
      )[["data"]][["us_patent_citations"]]
    }),
    "The API's requests per minute limit has been reached. "
  )

  built_singly <- do.call(rbind, built_singly)

  result_all <- search_pv(
    query = qry_funs$eq(patent_id = patent_ids),
    endpoint = "patent/us_patent_citations",
    fields = c("patent_id", "citation_patent_id"),
    sort = c("patent_id" = "asc", "citation_patent_id" = "asc"),
    per_page = 1000,
    all_pages = TRUE
  )
  result_all <- result_all$data$us_patent_citations

  expect_identical(built_singly, result_all)
})
