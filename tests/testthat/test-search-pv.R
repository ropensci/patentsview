context("search_pv")

test_that("API returns expected df names", {

  c("assignees", "cpc_subsections", "inventors", "locations",
    "nber_subcategories", "patents", "uspc_mainclasses") -> eps

  sapply(
    eps,
    FUN = function(x) {
      search_pv(with_qfuns(eq(patent_number = "5116621")),
                endpoint = x) -> j
      names(j[[1]])
    }, USE.NAMES = FALSE) -> z
  expect_equal(eps, z)

})

test_that("All expected fields can be pulled", {

  c("assignees", "cpc_subsections", "inventors", "locations",
    "nber_subcategories", "patents", "uspc_mainclasses") -> eps

  patentsview:::fields -> flds

  sapply(
    eps,
    FUN = function(x) {
      expect_success({
        flds[flds$endpoint == x, "field"] -> fl
        search_pv('{"patent_date":["1976-01-06"]}',
                  endpoint = x, fields = fl, method = "POST")
      })
    }, USE.NAMES = FALSE) -> z

})