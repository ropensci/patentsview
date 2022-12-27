context("unnest_pv_data")

eps <- get_endpoints()

test_that("", {
  skip_on_cran()
  # TODO(any): Remove:
  skip("Temp skip for API redesign PR")

  eps_no_loc <- eps[eps != "locations"]

  z <- lapply(eps_no_loc, function(x) {
    Sys.sleep(1)
    pv_out <- search_pv(
      "{\"patent_number\":\"5116621\"}",
      endpoint = x,
      fields = get_fields(x)
    )
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)
})
