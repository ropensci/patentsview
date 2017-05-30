context("http_error_handling")

test_that("Bad query arguments get informative error messages", {
  skip_on_cran()

  bad_qr <- patentsview:::tojson_2(list(patent_datee = "1976-01-01"))
  expect_error(search_pv(query = bad_qr, error_browser = "false"),
               "patent_datee")

  b_list <- list(`_neq` = list(patent_date = c("1976-01-01", "1976-01-01")))
  bad_qr <- patentsview:::tojson_2(b_list)
  expect_error(search_pv(query = bad_qr, error_browser = "false"), "array")
})