context("search_pv")

eps <- get_endpoints()

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()

  z <- vapply(eps, function(x) {
    j <- search_pv("{\"patent_number\":\"5116621\"}", endpoint = x)
    names(j[[1]])
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(eps, z)
})

test_that("DSL-based query returns expected results", {
  skip_on_cran()

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

test_that("search_pv can pull all fields for all endpoints except locations", {
  skip_on_cran()

  eps_no_loc <- eps[eps != "locations"]

  z <- lapply(eps_no_loc, function(x) {
    search_pv("{\"patent_number\":\"5116621\"}", endpoint = x,
              fields = get_fields(x))
  })

  expect_true(TRUE)
})

# As per this issue: https://github.com/CSSIP-AIR/PatentsView-API/issues/24
test_that("Locations endpoint returns error when asked for all avail. fields", {
  skip_on_cran()

  expect_error(
    search_pv("{\"patent_number\":\"5116621\"}", endpoint = "locations",
              fields = get_fields("locations"))
  )
})

# Though note this issue:
# https://github.com/CSSIP-AIR/PatentsView-API/issues/26
test_that("search_pv can return subent_cnts", {
  skip_on_cran()

  fields <- get_fields("patents", c("patents", "inventors"))
  out_spv <- search_pv("{\"patent_number\":\"5116621\"}", fields = fields,
                       subent_cnts = TRUE)
  expect_true(length(out_spv$query_results) == 2)
})

test_that("Sort option works as expected", {
  skip_on_cran()

  fields <- get_fields("inventors", c("inventors"))
  query <- qry_funs$gt(patent_date = "2015-01-01")

  out_spv <- search_pv(query = query, fields = fields,
                       endpoint = "inventors",
                       sort = c("inventor_lastknown_latitude" = "desc"),
                       per_page = 100)

  lat <- as.numeric(out_spv$data$inventors$inventor_lastknown_latitude)

  expect_true(lat[1] >= lat[100])
})