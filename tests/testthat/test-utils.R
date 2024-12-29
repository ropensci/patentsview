test_that("we can cast the endpoints that return the same entity", {
  skip_on_cran()

  endpoints <- c("patent/rel_app_text", "publication/rel_app_text")

  nul <- lapply(endpoints, function(endpoint) {
    results <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint)
    cast <- cast_pv_data(results$data)
  })

  expect_true(TRUE)
})
