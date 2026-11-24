test_that("DSL-based query works", {
  skip_on_cran()

  vcr::local_cassette("dsl-query")
  query <- with_qfuns(
    and(
      gte(patent_date = "2014-01-01"),
      text_phrase(patent_abstract = "computer program")
    )
  )
  out <- search_pv(query)
  expect_gt(out$query_results$total_hits, 100)
})

test_that("can retrieve all fields for patent endpoint", {
  skip_on_cran()

  vcr::local_cassette("patent-all-fields")
  out <- search_pv(
    query = '{"patent_id":"5116621"}',
    endpoint = "patent",
    fields = get_fields("patent")
  )
  expect_equal(out$query_results$total_hits, 1)
})

test_that("sort works", {
  skip_on_cran()

  vcr::local_cassette("sort")
  out <- search_pv(
    qry_funs$neq(assignee_id = ""),
    fields = get_fields("assignee", groups = "assignees"),
    endpoint = "assignee",
    sort = c("assignee_lastknown_latitude" = "desc"),
    size = 100
  )
  lat <- as.numeric(out$data$assignees$assignee_lastknown_latitude)
  expect_true(lat[1] >= lat[100])
})

test_that("URL encoding works", {
  skip_on_cran()

  vcr::local_cassette("url-encoding")
  organization <- "Johnson & Johnson International"
  query <- with_qfuns(text_phrase(assignee_organization = organization))
  out <- search_pv(query, endpoint = "assignee")
  expect_equal(out$query_results$total_hits, 1)
})

test_that("can retrieve HATEOAS links", {
  skip_on_cran()

  vcr::local_cassette("hateoas")
  out <- retrieve_linked_data(
    paste0(get_base("cpc_group"), "G01S7:4811/")
  )
  expect_equal(out$query_results$total_hits, 1)
})

test_that("after parameter works for manual paging", {
  skip_on_cran()

  vcr::local_cassette("after-paging")
  query <- qry_funs$eq(patent_date = "2000-01-04")
  sort <- c("patent_id" = "asc")

  first_page <- search_pv(query, sort = sort, size = 100)
  expect_gt(first_page$query_results$total_hits, 100)

  last_id <- first_page$data$patents$patent_id[100]
  second_page <- search_pv(query, after = last_id, sort = sort, size = 100)
  expect_equal(nrow(second_page$data$patents), 100)

  # No overlap
  expect_false(any(
    second_page$data$patents$patent_id %in% first_page$data$patents$patent_id
  ))
})

test_that("all_pages works", {
  skip_on_cran()

  vcr::local_cassette("all-pages")
  # Query that returns ~1500 results to test paging (2 pages)
  query <- with_qfuns(
    and(
      gte(patent_date = "2021-01-05"),
      lte(patent_date = "2021-01-05"),
      eq(patent_type = "utility")
    )
  )
  out <- search_pv(query, all_pages = TRUE)
  expect_equal(nrow(out$data$patents), out$query_results$total_hits)
  expect_gt(out$query_results$total_hits, 1000) # Ensure we actually paged
})

test_that("field shorthand returns all requested fields", {
  skip_on_cran()

  vcr::local_cassette("field-shorthand")
  query <- '{"patent_id":"5116621"}'
  all_assignee_fields <- get_fields("patent", groups = "assignees")
  out <- search_pv(query, fields = all_assignee_fields, method = "POST")

  # Verify we got back all the assignee fields we asked for
  returned_fields <- names(out$data$patents$assignees[[1]])
  requested_fields <- sub("assignees\\.", "", all_assignee_fields)
  expect_true(all(requested_fields %in% returned_fields))
})

# Keep one live test for basic connectivity/sanity check
test_that("can connect to API", {
  skip_on_cran()
  skip_if_offline()
  skip_if(Sys.getenv("PATENTSVIEW_API_KEY") == "", "No API key")
  skip_if(Sys.getenv("PATENTSVIEW_API_KEY") == "test-api-key", "Using fake API key")

  out <- search_pv('{"patent_id":"5116621"}', fields = "patent_id")
  expect_equal(out$query_results$total_hits, 1)
})

test_that("the base URL can be set with an option or the environment", {
  old_opt <- options(patentsview.base_url = NULL)
  old_env <- Sys.getenv("PATENTSVIEW_BASE_URL", NA)
  on.exit({
    options(old_opt)
    if (is.na(old_env)) Sys.unsetenv("PATENTSVIEW_BASE_URL") else Sys.setenv(PATENTSVIEW_BASE_URL = old_env)
  })
  Sys.unsetenv("PATENTSVIEW_BASE_URL")
  expect_equal(get_base("patent"), "https://search.patentsview.org/api/v1/patent/")
  Sys.setenv(PATENTSVIEW_BASE_URL = "https://example.org/")
  expect_equal(get_base("patent"), "https://example.org/api/v1/patent/")
  options(patentsview.base_url = "https://example.net")
  expect_equal(get_base("inventor"), "https://example.net/api/v1/inventor/")
})
