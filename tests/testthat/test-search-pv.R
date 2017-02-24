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

test_that("A larger set of fields can be returned", {

  c("assignees", "cpc_subsections", "inventors", "locations",
    "nber_subcategories", "patents", "uspc_mainclasses") -> eps

  sapply(eps,
         FUN = function(x) {
           get_fields(x, "patents") -> y
           search_pv('{"patent_number":"5116621"}', endpoint = x, fields = y)
         }) -> z

  expect_true(TRUE)

})

test_that("DSL language-based query returns expected results", {

  with_qfuns(
    and(
      or(
        gte(patent_date = '2014-01-01'),
        lte(patent_date = '1978-01-01')
      ),
      text_phrase(patent_abstract = c("computer program", "dog leash"))
    )
  ) -> query

  search_pv(query = query, endpoint = "patents") -> out

  expect_gt(out$query_results$total_patent_count, 1000)

})