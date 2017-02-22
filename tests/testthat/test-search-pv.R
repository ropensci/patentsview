context("search_pv")

test_that("API returns expected df names", {

  c("assignees", "cpc_subsections", "inventors", "locations",
    "nber_subcategories", "patents", "uspc_mainclasses") -> eps

  sapply(eps,
    FUN = function(x) {
      search_pv('{"patent_number":"5116621"}', endpoint = x) -> j
      names(j[[1]])
    }, USE.NAMES = FALSE) -> z
  expect_equal(eps, z)

})