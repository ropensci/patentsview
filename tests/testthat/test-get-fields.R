test_that("get_fields works as expected", {
  skip_on_cran()

  expect_error(
    get_fields("bogus endpoint"),
    "endpoint must be",
    fixed = TRUE
  )

  expect_error(
    get_fields("patent", groups = "bogus"),
    "for the patent endpoint",
    fixed = TRUE
  )

  patent_pk <- get_ok_pk("patent")
  fields <- get_fields(endpoint = "patent", groups = c("inventors"))
  expect_false(patent_pk %in% fields)

  fields <- get_fields(endpoint = "patent", groups = c("inventors"), include_pk = TRUE)
  expect_true(patent_pk %in% fields)
})

test_that("the endpoints are stable", {
  skip_on_cran()

  # quick check of the endpoints - useful after an api update.  We run fieldsdf.R
  # and do a build.  This test would fail if an endpoint was added, moved or deleted
  found <- unique(fieldsdf$endpoint)
  expecting <- get_endpoints()
  expect_equal(expecting, found)
})
