context("search_pv")

test_that("API returns expected df names", {

  eps <- c("assignees", "cpc_subsections", "inventors", "locations",
           "nber_subcategories", "patents", "uspc_mainclasses")

  z <- sapply(eps, FUN = function(x) {
    j <- search_pv("{\"patent_number\":\"5116621\"}", endpoint = x)
    names(j[[1]])
  }, USE.NAMES = FALSE)

  expect_equal(eps, z)
})

test_that("A larger set of fields can be returned", {

  eps <- c("assignees", "cpc_subsections", "inventors", "locations",
           "nber_subcategories", "patents", "uspc_mainclasses")

  z <- sapply(eps, FUN = function(x) {
    y <- get_fields(x, "patents")
    search_pv("{\"patent_number\":\"5116621\"}", endpoint = x, fields = y)
  })

  expect_true(TRUE)
})

test_that("DSL language-based query returns expected results", {

  query <- with_qfuns(
    and(
      or(
        gte(patent_date = '2014-01-01'),
        lte(patent_date = '1978-01-01')
      ),
      text_phrase(patent_abstract = c("computer program", "dog leash"))
    )
  )

  out <- search_pv(query = query, endpoint = "patents")

  expect_gt(out$query_results$total_patent_count, 1000)
})