context("unnest_pv_data")

eps <- get_endpoints()

test_that("", {
  skip_on_cran()

  # TODO(any): add back fields = get_fields(x)
  # API throws 500s if some nested fields are included

  # locations endpoint is back but it fails this test
  # Error: Invalid field: location_num_assignees
  # Error: Invalid field: attorney_first_seen_date
  bad_eps <- c("locations", "patent/attorneys")

  good_eps <- eps[!eps %in% bad_eps]

  z <- lapply(good_eps, function(x) {
    Sys.sleep(1)
    print(x)
    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x, group = (x)) # requesting non-nested attributes
    )
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)

  # This test will fail when the API is fixed
  z <- lapply(bad_eps, function(x) {
    Sys.sleep(1)
    expect_error(
      pv_out <- search_pv(
        query = TEST_QUERIES[[x]],
        endpoint = x,
        fields = get_fields(x, group = (x)) # requesting non-nested attributes
      )
    )
  })
})
