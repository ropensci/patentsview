context("http_error_handling")

test_that("Bad query arguments get informative error messages", {
  toJSON2(list("patent_datee" = "1976-01-01")) -> bad_qr
  expect_error(search_pv(query = bad_qr), "patent_datee")

  toJSON2(list(
    "_neq" = list("patent_date" = c("1976-01-01", "1976-01-01"))
  )) -> bad_qr
  expect_error(search_pv(query = bad_qr), "array")


  toJSON2(list(
    "_contains" = list("assignee_state" = c("new"))
  )) -> bad_qr
  search_pv(query = bad_qr)

})