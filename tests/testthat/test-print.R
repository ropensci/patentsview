test_that("We can print the returns from all endpoints ", {
  skip_on_cran()

  eps <- get_endpoints()
  bad_eps <- c("cpc_subclass", "uspc_subclass", "uspc_mainclass", "wipo")
  good_eps <- eps[!eps %in% bad_eps]

  lapply(good_eps, function(x) {
    print(x)
    j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x)
    print(j)
    j
  })

  expect_true(TRUE)

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed
})

test_that("we can print a query, its request, and unnested data", {
  skip_on_cran()

  x <- "patent"
  q <- qry_funs$eq(patent_id = "11530080")
  print(q)

  fields <- c("patent_id", get_fields(x, groups = "ipcr"))
  j <- search_pv(query = TEST_QUERIES[[x]], endpoint = x, fields = fields)
  print(j$request)

  k <- unnest_pv_data(j$data)
  print(k)

  expect_true(TRUE)
})
