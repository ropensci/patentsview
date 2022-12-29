context("validate_args")

test_that("validate_args throws errors for all bad args", {
  skip_on_cran()
  # TODO(any): Remove:
  skip("Temp skip for API redesign PR")

  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', endpoint = "patent"),
    "endpoint"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', method = "Post"),
    "method"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = NULL),
    "subent_cnts"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', mtchd_subent_only = NULL),
    "mtchd_subent_only"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', per_page = "50"),
    "per_page"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', page = NA),
    "page"
  )
  expect_error(
    search_pv(
      '{"patent_date":["1976-01-06"]}',
      fields = "patent_date",
      sort = c("patent_id" = "asc")
    ),
    "sort"
  )
})
