context("search_pv")

# TODO: add a test to see if all the requested fields come back

endpoints <- get_endpoints()

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()

  df_names <- vapply(endpoints, function(x) {
    out <- search_pv(query = TEST_QUERIES[[x]], endpoint = x)
    names(out[[1]])
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(endpoints, df_names)
})

test_that("DSL-based query returns expected results", {
  skip_on_cran()

  query <- with_qfuns(
    and(
      or(
        gte(patent_date = "2014-01-01"),
        lte(patent_date = "1978-01-01")
      ),
      text_phrase(patent_abstract = c("computer program", "dog leash"))
    )
  )
  out <- search_pv(query)
  expect_gt(out$query_results$total_hits, 1000)
})

test_that("You can download up to 9,000+ records", {
  skip_on_cran()

  # Should return 9,000+ rows
  query <- with_qfuns(
    and(
        gte(patent_date = "2021-12-13"),
        lte(patent_date = "2021-12-24")
    )
  )
  out <- search_pv(query, per_page = 1000, all_pages = TRUE)
  expect_gt(out$query_results$total_hits, 9000)
})

test_that("search_pv can pull all fields for all endpoints", {
  skip_on_cran()

  dev_null <- lapply(endpoints, function(x) {
    search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
  })
  expect_true(TRUE)
})

test_that("Sort option works as expected", {
  skip_on_cran()

  out <- search_pv(
    qry_funs$neq(assignee_id = 1),
    fields = get_fields("assignees"),
    endpoint = "assignees",
    sort = c("lastknown_latitude" = "desc"),
    per_page = 100
  )
  lat <- as.numeric(out$data$assignees$lastknown_latitude)
  expect_true(lat[1] >= lat[100])
})

test_that("search_pv properly URL encodes queries", {
  skip_on_cran()

  # Covers https://github.com/ropensci/patentsview/issues/24
  # need to use the assignee endpoint now and the field is full_text
  ampersand_query <- with_qfuns(text_phrase(organization = "Johnson & Johnson"))
  dev_null <- search_pv(ampersand_query, endpoint = "assignees")
  expect_true(TRUE)
})

# Below we request the same data in built_singly and result_all, with the only
# difference being that we intentionally get throttled in built_singly by
# sending one request per patent number (instead of all requests at once). If
# the two responses match, then we've correctly handled throttling errors.
test_that("Throttled requests are automatically retried", {
  skip_on_cran()

  res <- search_pv('{"_gte":{"patent_date":"2007-01-04"}}', per_page = 50)
  patent_numbers <- res$data$patents$patent_number

  built_singly <- lapply(patent_numbers, function(patent_number) {
    search_pv(
      query = qry_funs$eq(patent_number = patent_number),
      endpoint = "patent_citations",
      fields = c("patent_number", "cited_patent_number"),
      sort = c("cited_patent_number" = "asc")
    )[["data"]][["patent_citations"]]
  })
  built_singly <- do.call(rbind, built_singly)

  result_all <- search_pv(
    query = qry_funs$eq(patent_number = patent_numbers),
    endpoint = "patent_citations",
    fields = c("patent_number", "cited_patent_number"),
    sort = c("patent_number" = "asc", "cited_patent_number" = "asc"),
    per_page = 1000,
    all_pages = TRUE
  )
  result_all <- result_all$data$patent_citations

  expect_identical(built_singly, result_all)
})
